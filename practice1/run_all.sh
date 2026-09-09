#!/usr/bin/env bash
# Brings the stack up and walks through all five levels of the assignment.
#
# Usage: bash run_all.sh [number_of_users]

set -euo pipefail

cd "$(dirname "$0")"

USERS_TO_FETCH="${1:-25}"
COUNTRIES_URL="https://raw.githubusercontent.com/dr5hn/countries-states-cities-database/master/csv/countries.csv"
PGADMIN_PORT="${PGADMIN_PORT:-5050}"

step() { printf '\n\033[1m==> %s\033[0m\n' "$1"; }

psql_file() { docker compose exec -T db psql -v ON_ERROR_STOP=1 -q -f "$1"; }
psql_query() { docker compose exec -T db psql -tAX -c "$1"; }

step "Fetching the countries dataset if it is missing"
if [[ -s data/countries.csv ]]; then
  echo "data/countries.csv already present ($(wc -l < data/countries.csv | tr -d ' ') lines)"
else
  curl -fsSL "$COUNTRIES_URL" -o data/countries.csv
  echo "downloaded data/countries.csv"
fi

step "Level 1: starting db, py and pgadmin"
docker compose up -d --wait
docker compose ps

step "Level 2: connectivity"
# The py container installs its dependencies on start, so wait for them.
for _ in $(seq 1 60); do
  if docker compose exec -T py python -c "import sqlalchemy, requests" 2>/dev/null; then
    break
  fi
  sleep 2
done
docker compose exec -T py python check_connection.py
# pgAdmin needs a few seconds after the container reports healthy.
for _ in $(seq 1 30); do
  if curl -fsS -o /dev/null "http://localhost:${PGADMIN_PORT}/misc/ping" 2>/dev/null; then
    echo "pgadmin is serving on http://localhost:${PGADMIN_PORT}"
    break
  fi
  sleep 2
done

step "Level 3: creating tables and loading countries with COPY"
psql_file /sql/01_schema.sql
psql_file /sql/02_load_countries.sql
echo "countries rows: $(psql_query 'SELECT count(*) FROM countries;')"

step "Level 4: ingesting users from the API"
docker compose exec -T py python ingest_users.py --count "$USERS_TO_FETCH"

step "Level 5: creating the joined view"
psql_file /sql/03_analytics_view.sql
docker compose exec -T db psql -c "
SELECT name_first, name_last, reported_country,
       reported_latitude, reported_longitude,
       country_latitude, country_longitude
FROM user_country_coordinates
ORDER BY user_id
LIMIT 5;"
echo "rows matched to a country: $(psql_query 'SELECT count(*) FROM user_country_coordinates WHERE country_matched;')"

step "All five levels completed"
echo "pgAdmin: http://localhost:${PGADMIN_PORT}"

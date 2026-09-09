# Practice 1: Docker, Postgres and a first ingestion pipeline

Week 2 practice for LTAT.02.007.

Stand up a local Postgres database, pull user records from a public REST API
into it, and correct the unusable coordinates in those records against a static
countries dataset.

| Service   | Image                    | Purpose                          |
| --------- | ------------------------ | -------------------------------- |
| `db`      | `postgres:16.4`          | Target database                  |
| `py`      | `python:3.12.5-bookworm` | API client and ingestion scripts |
| `pgadmin` | `dpage/pgadmin4:8.10`    | Web UI on http://localhost:5050  |

## Running it

```bash
bash run_all.sh          # all five levels
bash run_all.sh 100      # same, ingesting 100 users
docker compose down -v   # tear down, including stored data
```

## Levels

**1. Services run.**

```bash
docker compose up -d --wait
```

`db` has a `pg_isready` healthcheck and the other two wait on
`condition: service_healthy`, so `--wait` returns once Postgres actually accepts
connections rather than once the container exists.

**2. Connectivity.**

```bash
docker compose exec py python check_connection.py
```

For pgAdmin, log in at http://localhost:5050 with the credentials from `.env`,
then Add New Server with host `db`, port `5432`, database `practice1`, user and
password `data_engineer`. The host is `db` and not `localhost` because pgAdmin
resolves it over the compose network from its own container.

**3. Load the countries data.**

```bash
docker compose exec -T db psql -v ON_ERROR_STOP=1 -f /sql/01_schema.sql
docker compose exec -T db psql -v ON_ERROR_STOP=1 -f /sql/02_load_countries.sql
```

`COPY` runs inside the server process, so `/data/countries.csv` is a path in the
`db` container, not on the host.

**4. Ingest users.**

```bash
docker compose exec py python ingest_users.py --count 25
docker compose exec py python ingest_users.py --count 25 --seed practice1
```

`--seed` makes the API return the same records again, which helps when checking
the pipeline.

**5. Join the two tables.**

```bash
docker compose exec -T db psql -v ON_ERROR_STOP=1 -f /sql/03_analytics_view.sql
docker compose exec -T db psql -c "SELECT * FROM user_country_coordinates LIMIT 5;"
```

`user_country_coordinates` keeps the reported coordinates next to the reference
centroid of the matched country and exposes a corrected pair.

## Layout

```
compose.yml              submitted to Moodle
.env                     throwaway local credentials
run_all.sh               runs all five levels
data/countries.csv       reference dataset
python/                  db.py, check_connection.py, ingest_users.py
sql/                     01_schema.sql, 02_load_countries.sql, 03_analytics_view.sql
```

## Notes on the choices

* Only `compose.yml` is submitted, so every variable carries an inline default
  and the Python dependencies are pinned in the service command instead of a
  mounted `requirements.txt`. The file brings all three services up on its own
  in an empty directory. The `.env` here only overrides those defaults.
* A named volume for the data directory rather than a bind mount. Binding
  `./pgdata` leaks Linux file ownership onto the host and puts hundreds of
  megabytes of database internals in the repository.
* Both tables are defined in SQL. Letting a dataframe library create `users` on
  first write infers types from one API response, which turns postcodes and
  street numbers into integers and drops leading zeros.
* The upstream countries CSV now has 28 columns and renamed `phone_code` to
  `phonecode`, so a loader written for the older 22 column layout fails.
  `01_schema.sql` matches the file `run_all.sh` downloads.
* `ingest_users.py` walks the nested JSON recursively instead of hardcoding key
  paths, and reports fields the API adds that the table has no column for.
* Inserts go in one transaction, so a failed run leaves `users` untouched.

## Submission

`compose.yml` only, to the Practice 1 assignment on Moodle.

The assignment text in the course repository says 18:00 on the day of the
practice. That was extended on the announcements forum to 9 September 2026 at
23:59, because many machines in the session could not run Docker. Moodle allows
up to 10 attempts.

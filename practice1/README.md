# Practice 1: Docker, Postgres and a first ingestion pipeline

Week 2 practice for LTAT.02.007 Data Engineering.

The task is to stand up a local Postgres database, pull user records from a
public REST API into it, and correct the unusable coordinates in those records
against a static reference dataset of countries.

## Stack

| Service   | Image                    | Purpose                                   |
| --------- | ------------------------ | ----------------------------------------- |
| `db`      | `postgres:16.4`          | Target database                           |
| `py`      | `python:3.12.5-bookworm` | API client and ingestion scripts          |
| `pgadmin` | `dpage/pgadmin4:8.10`    | Web UI on http://localhost:5050           |

## Quick start

```bash
bash run_all.sh          # runs every level end to end
bash run_all.sh 100      # same, but ingests 100 users
```

The script is idempotent for the reference data and additive for users, so it
can be run repeatedly.

To tear everything down including the stored data:

```bash
docker compose down -v
```

## The five levels

### Level 1: the services run

```bash
docker compose up -d --wait
docker compose ps
```

`db` declares a `pg_isready` healthcheck and the other two services wait on
`condition: service_healthy`, so `--wait` returns only once Postgres actually
accepts connections rather than once the container merely exists.

### Level 2: connectivity

From the Python container, over SQLAlchemy:

```bash
docker compose exec py python check_connection.py
```

From the pgAdmin UI at http://localhost:5050, log in with the credentials in
`.env`, then **Add New Server**:

| Field    | Value                          |
| -------- | ------------------------------ |
| Name     | anything, for example `local`  |
| Host     | `db`                           |
| Port     | `5432`                         |
| Database | `practice1`                    |
| Username | `data_engineer`                |
| Password | `data_engineer`                |

The host is `db` and not `localhost`, because pgAdmin resolves it over the
compose network from inside its own container.

### Level 3: load the countries reference data

```bash
docker compose exec -T db psql -v ON_ERROR_STOP=1 -f /sql/01_schema.sql
docker compose exec -T db psql -v ON_ERROR_STOP=1 -f /sql/02_load_countries.sql
```

`COPY` runs inside the server process, so it reads `/data/countries.csv`, the
path the CSV is mounted at in the `db` container, not a path on the host.

### Level 4: ingest users from the API

```bash
docker compose exec py python ingest_users.py --count 25
docker compose exec py python ingest_users.py --count 25 --seed practice1
```

`--seed` makes randomuser.me return the same records again, which is useful
when verifying the pipeline.

### Level 5: join users to countries

```bash
docker compose exec -T db psql -v ON_ERROR_STOP=1 -f /sql/03_analytics_view.sql
docker compose exec -T db psql -c "SELECT * FROM user_country_coordinates LIMIT 5;"
```

The `user_country_coordinates` view keeps the reported coordinates next to the
reference centroid of the matched country and exposes a corrected pair.

## Layout

```
practice1/
├── compose.yml              the file submitted to Moodle
├── .env                     throwaway local credentials
├── run_all.sh               walks through all five levels
├── data/countries.csv       static reference dataset
├── python/
│   ├── db.py                shared engine factory
│   ├── check_connection.py  level 2 check
│   ├── ingest_users.py      level 4 ingestion
│   └── requirements.txt
└── sql/
    ├── 01_schema.sql        countries and users tables
    ├── 02_load_countries.sql
    └── 03_analytics_view.sql
```

## Design notes

**`compose.yml` runs on its own.** Only the compose file is submitted, so every
variable carries an inline default (`${POSTGRES_USER:-data_engineer}`) and the
Python dependencies are pinned in the service command instead of being read
from a mounted `requirements.txt`. Dropping the file into an empty directory
and running `docker compose up` still brings all three services up. The `.env`
file in this repository only overrides those defaults.

**Named volumes rather than a bind mount for the data directory.** Binding
`./pgdata` into the container leaks Linux file ownership onto the host, breaks
on macOS and Windows filesystems, and puts several hundred megabytes of
database internals inside the repository.

**Tables are defined explicitly.** Letting a dataframe library create `users`
on first write infers the column types from a single API response, which turns
postcodes and street numbers into integers and silently drops leading zeros.
The DDL keeps identifiers as `TEXT` and coordinates as `NUMERIC`.

**The schema tracks the current upstream CSV.** The countries dataset now ships
28 columns and renamed `phone_code` to `phonecode`, so a loader written against
the older 22 column layout fails. `01_schema.sql` matches the file that
`run_all.sh` downloads.

**Flattening is generic.** `ingest_users.py` walks the nested JSON recursively
instead of hardcoding the key paths, and reports any field the API adds that
the table has no column for.

**Batch inserts are transactional.** A failed run leaves the `users` table
untouched instead of half populated.

## Submission

`compose.yml` only, uploaded to the Practice 1 assignment on Moodle.

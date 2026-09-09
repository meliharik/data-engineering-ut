"""Level 4: pull users from randomuser.me and load them into Postgres.

The API returns deeply nested JSON. Only the ``name`` and ``location``
objects are required, and they are flattened to a single level by joining
the key path with "_", so ``location.coordinates.latitude`` becomes
``location_coordinates_latitude``.

Run it with:
    docker compose exec py python ingest_users.py --count 25
"""

from __future__ import annotations

import argparse
import os
import sys
from typing import Any, Iterator

import requests
from sqlalchemy import text
from sqlalchemy.exc import SQLAlchemyError

from db import create_db_engine

FIELDS_OF_INTEREST = ("name", "location")

# The columns the users table actually has. Anything else the API starts
# returning is reported and skipped rather than silently dropped.
TARGET_COLUMNS = (
    "name_title",
    "name_first",
    "name_last",
    "location_street_number",
    "location_street_name",
    "location_city",
    "location_state",
    "location_country",
    "location_postcode",
    "location_coordinates_latitude",
    "location_coordinates_longitude",
    "location_timezone_offset",
    "location_timezone_description",
)

INSERT_SQL = text(
    "INSERT INTO users ({columns}) VALUES ({placeholders})".format(
        columns=", ".join(TARGET_COLUMNS),
        placeholders=", ".join(f":{column}" for column in TARGET_COLUMNS),
    )
)


def flatten(value: Any, prefix: str = "", separator: str = "_") -> Iterator[tuple[str, Any]]:
    """Yield (column_name, scalar) pairs for an arbitrarily nested mapping."""
    if isinstance(value, dict):
        for key, nested in value.items():
            child = f"{prefix}{separator}{key}" if prefix else str(key)
            yield from flatten(nested, child, separator)
    else:
        yield prefix, value


def fetch_users(api_url: str, count: int, seed: str | None = None) -> list[dict[str, Any]]:
    """Fetch ``count`` users in a single call and return the raw records."""
    params: dict[str, Any] = {"results": count}
    if seed:
        params["seed"] = seed
    response = requests.get(api_url, params=params, timeout=30)
    response.raise_for_status()
    return response.json()["results"]


def to_row(record: dict[str, Any]) -> dict[str, Any]:
    """Flatten one API record down to the columns of the users table."""
    wanted = {key: record[key] for key in FIELDS_OF_INTEREST if key in record}
    flat = dict(flatten(wanted))

    unexpected = sorted(set(flat) - set(TARGET_COLUMNS))
    if unexpected:
        print(f"note: ignoring new API fields {unexpected}", file=sys.stderr)

    return {column: flat.get(column) for column in TARGET_COLUMNS}


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--count", type=int, default=10, help="number of users to fetch (default: 10)"
    )
    parser.add_argument(
        "--seed", default=None, help="randomuser.me seed, for reproducible runs"
    )
    args = parser.parse_args()

    api_url = os.environ.get("API_URL", "https://randomuser.me/api/")

    try:
        records = fetch_users(api_url, args.count, args.seed)
    except requests.RequestException as exc:
        print(f"api request failed: {exc}", file=sys.stderr)
        return 1

    rows = [to_row(record) for record in records]

    engine = create_db_engine()
    try:
        # One transaction for the whole batch: either every user lands or none
        # does, so a failed run never leaves a half loaded table behind.
        with engine.begin() as conn:
            conn.execute(INSERT_SQL, rows)
            total = conn.execute(text("SELECT count(*) FROM users")).scalar_one()
    except SQLAlchemyError as exc:
        print(f"insert failed: {exc}", file=sys.stderr)
        return 1

    print(f"inserted {len(rows)} users from {api_url}, {total} rows in total")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

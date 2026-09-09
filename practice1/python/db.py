"""Shared database helper for the practice 1 scripts."""

from __future__ import annotations

import os

from sqlalchemy import Engine, create_engine


def build_url() -> str:
    """Build the Postgres URL from the environment set in compose.yml."""
    user = os.environ["POSTGRES_USER"]
    password = os.environ["POSTGRES_PASSWORD"]
    host = os.environ.get("POSTGRES_HOST", "db")
    port = os.environ.get("POSTGRES_PORT", "5432")
    database = os.environ["POSTGRES_DB"]
    return f"postgresql+psycopg2://{user}:{password}@{host}:{port}/{database}"


def create_db_engine() -> Engine:
    """Return an engine that checks connections before handing them out."""
    return create_engine(build_url(), pool_pre_ping=True, future=True)

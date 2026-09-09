import os

from sqlalchemy import Engine, create_engine


def build_url() -> str:
    user = os.environ["POSTGRES_USER"]
    password = os.environ["POSTGRES_PASSWORD"]
    host = os.environ.get("POSTGRES_HOST", "db")
    port = os.environ.get("POSTGRES_PORT", "5432")
    database = os.environ["POSTGRES_DB"]
    return f"postgresql+psycopg2://{user}:{password}@{host}:{port}/{database}"


def create_db_engine() -> Engine:
    return create_engine(build_url(), pool_pre_ping=True, future=True)

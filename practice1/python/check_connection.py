import sys

from sqlalchemy import text
from sqlalchemy.exc import SQLAlchemyError

from db import create_db_engine


def main() -> int:
    engine = create_db_engine()
    try:
        with engine.connect() as conn:
            version = conn.execute(text("SELECT version()")).scalar_one()
            database = conn.execute(text("SELECT current_database()")).scalar_one()
            tables = conn.execute(
                text(
                    "SELECT table_name FROM information_schema.tables "
                    "WHERE table_schema = 'public' ORDER BY table_name"
                )
            ).scalars().all()
    except SQLAlchemyError as exc:
        print(f"connection failed: {exc}", file=sys.stderr)
        return 1

    print(f"connected to {database}")
    print(version)
    print(f"public objects: {', '.join(tables) if tables else '(none yet)'}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

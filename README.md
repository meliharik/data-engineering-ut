# Data Engineering (LTAT.02.007)

Coursework for the Data Engineering course at the University of Tartu,
autumn semester 2026.

Each weekly practice lives in its own folder with a self contained Docker
setup, the scripts that produce the result, and a README explaining how to run
it and why it is built that way.

## Practices

| # | Topic                       | Folder                      | Status   |
| - | --------------------------- | --------------------------- | -------- |
| 1 | Docker, Postgres, first ingestion | [`practice1/`](practice1/) | Complete |
| 2 | ER diagrams                 | `practice2/`                | Upcoming |
| 3 | Star schema                 | `practice3/`                | Upcoming |
| 4 | Airflow                     | `practice4/`                | Upcoming |
| 5 | ClickHouse                  | `practice5/`                | Upcoming |
| 6 | dbt                         | `practice6/`                | Upcoming |
| 7 | MongoDB                     | `practice7/`                | Upcoming |
| 8 | Apache Superset             | `practice8/`                | Upcoming |

## Course reference

* [Course overview](docs/course-overview.md): logistics, grading, project,
  reading list
* [Weekly plan](docs/weekly-plan.md): lecture and practice schedule

## Running anything here

Every practice assumes Docker and Docker Compose v2. From the repository root:

```bash
cd practice1
bash run_all.sh
```

## Conventions

* One folder per practice, numbered in course order.
* Image versions are always pinned. Nothing depends on `latest`.
* `.env` files hold throwaway local credentials only and are committed so the
  stacks are reproducible. Real secrets never enter this repository.
* Course material is used as a reference, never copied. Where a published
  reference solution exists, the reasoning behind any difference is recorded in
  the design notes of that practice.

## License

[MIT](LICENSE)

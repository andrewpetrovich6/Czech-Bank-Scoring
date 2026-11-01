"""Пересобирает базу с нуля и сохраняет витрину признаков в data/processed/features.csv.

Порядок: 01_schema -> загрузка CSV -> 03_clean -> 04_target -> 05_features -> выгрузка.
Запуск из корня проекта: python -m src.run_sql
"""

import pandas as pd

from src.db import PROJECT_ROOT, get_engine
from src.load_data import load_all

SQL_DIR = PROJECT_ROOT / "sql"
OUT_PATH = PROJECT_ROOT / "data" / "processed" / "features.csv"


def run_sql_file(name: str) -> None:
    with get_engine().begin() as conn:
        conn.exec_driver_sql((SQL_DIR / name).read_text())
    print(f"выполнен {name}")


def main() -> None:
    # clean и mart построены поверх raw: без этого 01_schema не сможет пересоздать таблицы
    with get_engine().begin() as conn:
        conn.exec_driver_sql("DROP SCHEMA IF EXISTS mart CASCADE; DROP SCHEMA IF EXISTS clean CASCADE;")
    run_sql_file("01_schema.sql")
    load_all()
    for name in ["03_clean.sql", "04_target.sql", "05_features.sql"]:
        run_sql_file(name)

    features = pd.read_sql("SELECT * FROM mart.features ORDER BY loan_id", get_engine(), index_col="loan_id")
    OUT_PATH.parent.mkdir(parents=True, exist_ok=True)
    features.to_csv(OUT_PATH)
    print(f"сохранено {len(features)} строк, {features.shape[1]} колонок -> {OUT_PATH.relative_to(PROJECT_ROOT)}")


if __name__ == "__main__":
    main()

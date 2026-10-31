"""Загружает исходные CSV из data/raw/ в таблицы схемы raw (их создаёт sql/01_schema.sql).

Запуск из корня проекта: python -m src.load_data
"""

from src.db import PROJECT_ROOT, get_engine

RAW_DIR = PROJECT_ROOT / "data" / "raw"

# таблица в базе -> CSV-файл
TABLES = {
    "account": "account.csv",
    "client": "client.csv",
    "disp": "disp.csv",
    "district": "district.csv",
    "loan": "loan.csv",
    "card": "card.csv",
    "orders": "order.csv",
    "trans": "trans.csv",
}

CHUNK_SIZE = 1024 * 1024


def load_all() -> None:
    conn = get_engine().raw_connection()
    try:
        with conn.cursor() as cur:
            for table, filename in TABLES.items():
                cur.execute(f"TRUNCATE raw.{table}")
                copy_sql = f"COPY raw.{table} FROM STDIN WITH (FORMAT csv, DELIMITER ';', HEADER)"
                with open(RAW_DIR / filename, "rb") as f, cur.copy(copy_sql) as copy:
                    while chunk := f.read(CHUNK_SIZE):
                        copy.write(chunk)
                cur.execute(f"SELECT COUNT(*) FROM raw.{table}")
                print(f"raw.{table:<9} {cur.fetchone()[0]:>9,} строк")
        conn.commit()
    finally:
        conn.close()


if __name__ == "__main__":
    load_all()

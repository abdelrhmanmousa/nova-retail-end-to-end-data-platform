import os
import csv
import io
import random
from datetime import datetime, timezone

from dotenv import load_dotenv
from google.cloud import storage

load_dotenv()

GCS_BUCKET = os.getenv("RAW_ZONE_BUCKET")
NUM_PRODUCTS = 200
NUM_SUPPLIERS = 25

FIELDNAMES = ["product_id", "supplier_id", "stock_level", "unit_cost_usd", "updated_at"]


def generate_rows():
    now = datetime.now(timezone.utc).isoformat()
    rows = []
    for product_id in range(1, NUM_PRODUCTS + 1):
        rows.append(
            {
                "product_id": product_id,
                "supplier_id": random.randint(1, NUM_SUPPLIERS),
                "stock_level": random.randint(0, 500),
                "unit_cost_usd": round(random.uniform(2, 700), 2),
                "updated_at": now,
            }
        )
    return rows


def write_csv_to_gcs(rows):
    buffer = io.StringIO()
    writer = csv.DictWriter(buffer, fieldnames=FIELDNAMES)
    writer.writeheader()
    writer.writerows(rows)

    today = datetime.now(timezone.utc).strftime("%Y-%m-%d")
    blob_path = f"supplier_catalog/date={today}/supplier_catalog.csv"

    client = storage.Client()
    bucket = client.bucket(GCS_BUCKET)
    blob = bucket.blob(blob_path)
    blob.upload_from_string(buffer.getvalue(), content_type="text/csv")

    print(f"Uploaded {len(rows)} rows to gs://{GCS_BUCKET}/{blob_path}")


def main():
    if not GCS_BUCKET:
        raise RuntimeError("RAW_ZONE_BUCKET env var not set")

    rows = generate_rows()
    write_csv_to_gcs(rows)


if __name__ == "__main__":
    main()

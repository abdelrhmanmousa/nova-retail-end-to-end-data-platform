import os
import csv
import io
from datetime import datetime, timezone

import requests
from dotenv import load_dotenv
from google.cloud import storage

load_dotenv()

GCS_BUCKET = os.getenv("RAW_ZONE_BUCKET")
API_URL = "https://api.frankfurter.app/latest?from=USD"

FIELDNAMES = ["currency_code", "rate_to_usd", "fetched_at"]


def fetch_rates():
    response = requests.get(API_URL, timeout=10)
    response.raise_for_status()
    data = response.json()
    return data["rates"]


def write_csv_to_gcs(rates):
    now = datetime.now(timezone.utc).isoformat()

    buffer = io.StringIO()
    writer = csv.DictWriter(buffer, fieldnames=FIELDNAMES)
    writer.writeheader()
    for currency_code, rate in rates.items():
        writer.writerow(
            {"currency_code": currency_code, "rate_to_usd": rate, "fetched_at": now}
        )

    today = datetime.now(timezone.utc).strftime("%Y-%m-%d")
    blob_path = f"currency_rates/date={today}/currency_rates.csv"

    client = storage.Client()
    bucket = client.bucket(GCS_BUCKET)
    blob = bucket.blob(blob_path)
    blob.upload_from_string(buffer.getvalue(), content_type="text/csv")

    print(f"Uploaded {len(rates)} currency rates to gs://{GCS_BUCKET}/{blob_path}")


def main():
    if not GCS_BUCKET:
        raise RuntimeError("RAW_ZONE_BUCKET env var not set")

    rates = fetch_rates()
    write_csv_to_gcs(rates)


if __name__ == "__main__":
    main()

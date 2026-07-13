import pyarrow as pa

# Matches the clickstream_producer.py event shape, plus derived partition
# columns added during parsing. Keep this in sync with the BigQuery external
# table schema created in Terraform.
CLICKSTREAM_SCHEMA = pa.schema(
    [
        ("event_id", pa.string()),
        ("customer_id", pa.int64()),
        ("session_id", pa.string()),
        ("event_type", pa.string()),
        ("product_id", pa.int64()),
        ("device", pa.string()),
        ("timestamp", pa.string()),
        ("year", pa.string()),
        ("month", pa.string()),
        ("week", pa.string()),
        ("day", pa.string()),
        ("hour", pa.string()),
        ("ingestion_timestamp", pa.string()),
    ]
)

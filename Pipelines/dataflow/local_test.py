"""
Run this locally to test the parsing/validation/Parquet-write logic without
deploying to Dataflow. Uses DirectRunner (runs in-process) so errors show up
as a normal Python traceback in seconds, not buried in Cloud Logging after a
10-minute deploy.

Usage:
    pip install apache-beam pyarrow
    python local_test.py
"""

import json
import shutil

import apache_beam as beam
from apache_beam.io import fileio
from apache_beam.options.pipeline_options import PipelineOptions

from parsing import ParseClickstreamEvent
from validation import ValidateClickstreamEvent
from schema import CLICKSTREAM_SCHEMA
from parquet_sink import ParquetFileSink

OUTPUT_DIR = "./local_output"

SAMPLE_EVENTS = [
    json.dumps(
        {
            "event_id": "e1",
            "customer_id": 1,
            "session_id": "s1",
            "event_type": "page_view",
            "product_id": 10,
            "device": "mobile",
            "timestamp": "2026-07-12T10:00:00+00:00",
        }
    ).encode("utf-8"),
    json.dumps(
        {
            "event_id": "e2",
            "customer_id": 2,
            "session_id": "s2",
            "event_type": "add_to_cart",
            "product_id": 20,
            "device": "desktop",
            "timestamp": "2026-07-12T11:15:00+00:00",
        }
    ).encode("utf-8"),
    b"not-valid-json",  # should route to dead-letter, not crash the pipeline
]


def run():
    shutil.rmtree(OUTPUT_DIR, ignore_errors=True)

    with beam.Pipeline(options=PipelineOptions()) as p:
        raw = p | "Create" >> beam.Create(SAMPLE_EVENTS)

        parsed = raw | "ParseEvent" >> beam.ParDo(
            ParseClickstreamEvent()
        ).with_outputs(ParseClickstreamEvent.OUTPUT_TAG_DEAD_LETTER, main="ok")

        validated = parsed.ok | "ValidateEvent" >> beam.ParDo(
            ValidateClickstreamEvent()
        ).with_outputs(ValidateClickstreamEvent.OUTPUT_TAG_DEAD_LETTER, main="ok")

        validated.ok | "WriteParquet" >> fileio.WriteToFiles(
            path=f"{OUTPUT_DIR}/clickstream",
            destination=lambda r: (
                f"year={r['year']}/month={r['month']}/"
                f"week={r['week']}/day={r['day']}/hour={r['hour']}"
            ),
            sink=lambda dest: ParquetFileSink(CLICKSTREAM_SCHEMA),
            file_naming=fileio.destination_prefix_naming(suffix=".parquet"),
        )

    print(f"\nDone. Check {OUTPUT_DIR}/clickstream/ for output Parquet files.")


if __name__ == "__main__":
    run()

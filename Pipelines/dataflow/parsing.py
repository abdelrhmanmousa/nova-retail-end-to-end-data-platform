import json
import logging
from datetime import datetime, timezone

import apache_beam as beam


class ParseClickstreamEvent(beam.DoFn):
    """Parses a raw Pub/Sub message (JSON bytes) into a structured dict.

    Adds derived partition columns (event_date, event_hour) and an
    ingestion timestamp. Malformed records are routed to a dead-letter
    output instead of failing the pipeline.
    """

    OUTPUT_TAG_DEAD_LETTER = "dead_letter"

    def process(self, element):
        try:
            payload = json.loads(element.decode("utf-8"))
            event_ts = datetime.fromisoformat(payload["timestamp"])

            _, iso_week, _ = event_ts.isocalendar()

            payload["year"] = event_ts.strftime("%Y")
            payload["month"] = event_ts.strftime("%m")
            payload["week"] = f"{iso_week:02d}"
            payload["day"] = event_ts.strftime("%d")
            payload["hour"] = event_ts.strftime("%H")
            payload["ingestion_timestamp"] = datetime.now(timezone.utc).isoformat()

            yield payload

        except Exception as e:
            logging.warning("Failed to parse clickstream event: %s", e)
            yield beam.pvalue.TaggedOutput(
                self.OUTPUT_TAG_DEAD_LETTER,
                {
                    "raw_payload": element.decode("utf-8", errors="replace"),
                    "error": str(e),
                    "stage": "parse",
                    "ingestion_timestamp": datetime.now(timezone.utc).isoformat(),
                },
            )

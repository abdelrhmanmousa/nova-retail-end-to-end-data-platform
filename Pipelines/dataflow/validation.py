import apache_beam as beam

REQUIRED_FIELDS = [
    "event_id",
    "customer_id",
    "session_id",
    "event_type",
    "timestamp",
    "device",
]


class ValidateClickstreamEvent(beam.DoFn):
    """Ensures a parsed event has all required fields before it's allowed
    into the main path. Incomplete events go to dead-letter for later
    inspection instead of silently corrupting the curated data.
    """

    OUTPUT_TAG_DEAD_LETTER = "dead_letter"

    def process(self, element):
        missing = [f for f in REQUIRED_FIELDS if not element.get(f)]

        if missing:
            yield beam.pvalue.TaggedOutput(
                self.OUTPUT_TAG_DEAD_LETTER,
                {**element, "missing_fields": missing, "stage": "validate"},
            )
        else:
            yield element

from apache_beam.options.pipeline_options import PipelineOptions


class ClickstreamPipelineOptions(PipelineOptions):
    """Custom runtime arguments for the clickstream streaming pipeline."""

    @classmethod
    def _add_argparse_args(cls, parser):
        parser.add_argument(
            "--input_subscription",
            required=True,
            help="Full Pub/Sub subscription path, e.g. projects/PROJECT/subscriptions/clickstream-events-dataflow-sub",
        )
        parser.add_argument(
            "--output_path",
            required=True,
            help="GCS prefix for Parquet output, e.g. gs://BUCKET/clickstream",
        )
        parser.add_argument(
            "--dead_letter_path",
            required=True,
            help="GCS prefix for malformed/invalid records, e.g. gs://BUCKET/clickstream_dead_letter",
        )
        parser.add_argument(
            "--window_size_minutes",
            type=int,
            default=60,
            help="Size of the fixed window used to batch records into Parquet files",
        )

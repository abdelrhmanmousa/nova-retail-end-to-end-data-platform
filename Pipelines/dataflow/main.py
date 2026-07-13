import json

from apache_beam.io.fileio import TextSink

import apache_beam as beam
from apache_beam.io import fileio
from apache_beam.options.pipeline_options import PipelineOptions, StandardOptions, SetupOptions
from apache_beam.transforms.window import FixedWindows

from pipeline_options import ClickstreamPipelineOptions
from parsing import ParseClickstreamEvent
from validation import ValidateClickstreamEvent
from schema import CLICKSTREAM_SCHEMA
from parquet_sink import ParquetFileSink


def run():
    pipeline_options = PipelineOptions()
    pipeline_options.view_as(StandardOptions).streaming = True
    pipeline_options.view_as(SetupOptions).save_main_session = True
    custom_options = pipeline_options.view_as(ClickstreamPipelineOptions)

    with beam.Pipeline(options=pipeline_options) as p:

        raw = p | "ReadFromPubSub" >> beam.io.ReadFromPubSub(
            subscription=custom_options.input_subscription
        )

        parsed = raw | "ParseEvent" >> beam.ParDo(
            ParseClickstreamEvent()
        ).with_outputs(ParseClickstreamEvent.OUTPUT_TAG_DEAD_LETTER, main="ok")

        validated = parsed.ok | "ValidateEvent" >> beam.ParDo(
            ValidateClickstreamEvent()
        ).with_outputs(ValidateClickstreamEvent.OUTPUT_TAG_DEAD_LETTER, main="ok")

        windowed = validated.ok | "Window" >> beam.WindowInto(
            FixedWindows(custom_options.window_size_minutes * 60)
        )

        windowed | "WriteParquet" >> fileio.WriteToFiles(
            path=custom_options.output_path,
            destination=lambda record: (
                f"year={record['year']}/month={record['month']}/"
                f"week={record['week']}/day={record['day']}/hour={record['hour']}"
            ),
            sink=lambda dest: ParquetFileSink(CLICKSTREAM_SCHEMA),
            file_naming=fileio.destination_prefix_naming(suffix=".parquet"),
        )

        dead_letters = (
            parsed[ParseClickstreamEvent.OUTPUT_TAG_DEAD_LETTER],
            validated[ValidateClickstreamEvent.OUTPUT_TAG_DEAD_LETTER],
        ) | "MergeDeadLetters" >> beam.Flatten()

        windowed_dead_letters = dead_letters | "WindowDeadLetters" >> beam.WindowInto(
            FixedWindows(custom_options.window_size_minutes * 60)
        )

        windowed_dead_letters | "FormatDeadLetter" >> beam.Map(json.dumps) | "WriteDeadLetters" >> fileio.WriteToFiles(
            path=custom_options.dead_letter_path,
            sink=lambda dest: TextSink(),
            file_naming=fileio.default_file_naming(prefix="dead_letter", suffix=".jsonl"),
        )


if __name__ == "__main__":
    run()
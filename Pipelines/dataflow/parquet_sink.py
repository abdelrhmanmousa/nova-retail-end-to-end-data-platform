# import pyarrow as pa
# import pyarrow.parquet as pq
# from apache_beam.io.fileio import FileSink


# class ParquetFileSink(FileSink):
#     """Writes buffered dict records into one Parquet file matching a fixed schema.

#     Used with fileio.WriteToFiles, which handles bucketing records by
#     destination (Hive partition path) and calls open/write/flush per shard.
#     """

#     def __init__(self, schema):
#         self._schema = schema
#         self._writer = None

#     def open(self, file_handle):
#         self._writer = pq.ParquetWriter(file_handle, self._schema)

#     def write(self, record):
#         table = pa.Table.from_pylist([record], schema=self._schema)
#         self._writer.write_table(table)

#     def flush(self):
#         if self._writer is not None:
#             self._writer.close()
import io

import pyarrow as pa
import pyarrow.parquet as pq
from apache_beam.io.fileio import FileSink


class ParquetFileSink(FileSink):
    """Buffers a shard's records in memory and writes one complete Parquet
    file per flush, instead of streaming rows incrementally into the
    destination file handle.

    This matters specifically on Dataflow's distributed workers: pyarrow's
    ParquetWriter can need to seek backward to finalize the file footer,
    which isn't safe against every kind of destination stream. Writing to
    a local in-memory buffer first and flushing the finished bytes in one
    call avoids that entirely.
    """

    def __init__(self, schema):
        self._schema = schema
        self._file_handle = None
        self._records = []

    def open(self, file_handle):
        self._file_handle = file_handle
        self._records = []

    def write(self, record):
        self._records.append(record)

    def flush(self):
        if not self._records:
            return

        table = pa.Table.from_pylist(self._records, schema=self._schema)
        buffer = io.BytesIO()
        pq.write_table(table, buffer)

        self._file_handle.write(buffer.getvalue())
        self._records = []
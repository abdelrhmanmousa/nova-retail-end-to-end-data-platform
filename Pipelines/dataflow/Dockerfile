FROM gcr.io/dataflow-templates-base/python311-template-launcher-base AS template_launcher

FROM apache/beam_python3.11_sdk:2.57.0

COPY --from=template_launcher /opt/google/dataflow/python_template_launcher /opt/google/dataflow/python_template_launcher

ARG WORKDIR=/dataflow/template
RUN mkdir -p ${WORKDIR}
WORKDIR ${WORKDIR}

COPY . ${WORKDIR}

ENV FLEX_TEMPLATE_PYTHON_PY_FILE="${WORKDIR}/main.py"
ENV FLEX_TEMPLATE_PYTHON_REQUIREMENTS_FILE="${WORKDIR}/requirements.txt"

ENV PYTHONPATH="${WORKDIR}:${PYTHONPATH}"

RUN pip install --no-cache-dir --upgrade pip \
    && pip install --no-cache-dir -r ${WORKDIR}/requirements.txt
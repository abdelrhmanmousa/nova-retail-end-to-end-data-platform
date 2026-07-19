FROM python:3.11-slim

WORKDIR /dbt

COPY . /dbt

RUN pip install --no-cache-dir dbt-bigquery==1.8.2

# Baked-in profile targeting BigQuery. method: oauth uses Application
# Default Credentials, which inside a Composer/GKE pod resolves to the
# node's service account automatically - no key file needed.
RUN mkdir -p /root/.dbt && cp /dbt/profiles.yml /root/.dbt/profiles.yml

# Installs packages declared in packages.yml (e.g. dbt_utils) into
# dbt_packages/ - without this, dbt run/test fails at compile time since
# generate_surrogate_key() etc. come from dbt_utils, not dbt-core.
RUN dbt deps --profiles-dir /root/.dbt

# No ENTRYPOINT on purpose - Composer's KubernetesPodOperator passes the
# actual command (e.g. ["dbt", "run"]) at run time, so this one image
# serves dbt run, dbt test, dbt debug, etc.

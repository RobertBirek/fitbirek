# python:3.12-slim
FROM python:3.12-slim@sha256:78387bc3881b8273120a12ebe6c1ab22b018ccc2c9adf565ae1ac9b536e184ea AS runtime

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1

WORKDIR /app

COPY requirements.lock ./requirements.lock
RUN python -m pip install --no-deps --require-hashes --requirement requirements.lock \
    && addgroup --system app \
    && adduser --system --ingroup app app

COPY --chown=app:app app ./app

USER app

EXPOSE 8000

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
    CMD python -c "from urllib.request import urlopen; urlopen('http://127.0.0.1:8000/api/health', timeout=3)"

CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]

# Operational tooling is isolated from the serving image.
FROM runtime AS migration
USER root
COPY requirements-dev.lock ./requirements-dev.lock
RUN python -m pip install --no-deps --require-hashes -r requirements-dev.lock
COPY alembic.ini migrate.py ./
COPY migrations ./migrations
USER app
HEALTHCHECK NONE
CMD ["python", "migrate.py"]

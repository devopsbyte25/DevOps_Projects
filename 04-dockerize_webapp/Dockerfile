# syntax=docker/dockerfile:1

# ---------- Stage 1: build dependencies ----------
FROM python:3.12-slim AS builder

WORKDIR /app

# optimizing docker image size by disabling pip cache
ENV PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1

COPY requirements.txt .
RUN pip install --user -r requirements.txt

# ---------- Stage 2: minimal runtime image ----------
FROM python:3.12-slim

# Create a non-root user to run the app
RUN addgroup --system app && adduser --system --group app

WORKDIR /app

# Bring in the python packages installed in the builder stage
COPY --from=builder /root/.local /home/app/.local

# Copy application source
COPY app/ ./app/
COPY wsgi.py .

ENV PATH=/home/app/.local/bin:$PATH \
    PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PORT=8080 \
    APP_VERSION=dev

RUN chown -R app:app /app

USER app

EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:8080/health')" || exit 1

CMD ["gunicorn", "-b", "0.0.0.0:8080", "--workers=2", "--access-logfile=-", "wsgi:app"]

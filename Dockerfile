FROM python:3.11-slim

ENV PYTHONDONTWRITEBYCODE=1

ENV PYTHONUNBUFFERED=1

WORKDIR /app

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    libpq-dev \
    && rm -rf /var/lib/apt/lists/*

COPY requirements.txt /app/

RUN pip install --no-cache-dir -r requirements.txt

# Create a dedicated non-root user
RUN groupadd --system --gid 10001 appgroup && \
    useradd --system --uid 10001 --gid 10001 \
    --create-home --shell /usr/sbin/nologin appuser

# Copy application files with correct ownership
COPY --chown=10001:10001 . /app

# Prepare writable directories
RUN mkdir -p /app/static && \
    chown -R 10001:10001 /app

# Switch to non-root user
USER 10001:10001

RUN python manage.py collectstatic --noinput

EXPOSE 8000

CMD ["gunicorn", "--bind", "0.0.0.0:8000", "blog_app.wsgi:application"]

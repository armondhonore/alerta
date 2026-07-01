FROM mirror.gcr.io/library/python:3.10-slim

# Install system dependencies
# libpq-dev is required for building psycopg2
# build-essential provides the compiler and tools
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    libpq-dev \
    git \
    curl \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Upgrade pip to avoid metadata generation issues
RUN pip install --no-cache-dir --upgrade pip setuptools wheel

# Copy requirements first
COPY requirements.txt ./

# Force install psycopg2-binary instead of psycopg2 to avoid needing pg_config/libpq-dev during build
# This is a common fix for the 'pg_config executable not found' error
RUN sed -i 's/psycopg2==.*/psycopg2-binary==2.9.9/g' requirements.txt || true
RUN sed -i 's/psycopg2>=.*/psycopg2-binary>=2.9.9/g' requirements.txt || true
RUN sed -i 's/psycopg2 /psycopg2-binary /g' requirements.txt || true

RUN pip install --no-cache-dir -r requirements.txt

# Copy the rest of the application
COPY . ./

# Install the application
RUN pip install . 

# Create a minimal configuration file to prevent crash on startup
RUN mkdir -p /etc/alerta && echo "[mongod]\nuri = mongodb://mongodb:27017/alerta" > /etc/alerta/alerta.conf

EXPOSE 8080

CMD ["alerta-server"]
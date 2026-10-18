FROM python:3.11-slim

WORKDIR /app

# Install bash, curl, jq
RUN apt-get update && apt-get install -y --no-install-recommends \
    bash \
    curl \
    jq \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .
RUN chmod +x scripts/*.sh 2>/dev/null || true

ENTRYPOINT ["python3"]

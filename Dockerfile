# Use Python on Alpine 3.14
FROM python:3.14-alpine

# Set environment variables for Python to optimize runtime and set timezone
ARG TZ=Asia/Kolkata
ENV TZ=${TZ} \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    COMPOSE_BAKE=true

# Install system dependencies (Alpine)
RUN apk add --no-cache \
        tzdata \
        curl


# Copy the uv and uvx binaries from the official uv image
COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /bin/

# Set working directory
WORKDIR /app

# Copy only dependency files first for better Docker cache utilization
COPY ./pyproject.toml uv.lock ./
RUN UV_HTTP_TIMEOUT=90 uv sync --frozen --no-dev

# Copy the entire application code into the container
COPY . .

EXPOSE 5000

CMD ["uv","run","gunicorn", "--workers", "1", "--bind", "0.0.0.0:5000", "app:app"]

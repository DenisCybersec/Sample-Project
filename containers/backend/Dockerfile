# Use official Python slim image
FROM python:3.11-slim

# Set environment variables for Python
ENV PYTHONDONTWRITEBYTECODE 1
ENV PYTHONUNBUFFERED 1
ENV FLASK_ENV production

# Set working directory
WORKDIR /app

# Install system dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends gcc libpq-dev && \
    rm -rf /var/lib/apt/lists/*

# Copy all files and install python packages
COPY . .
RUN pip install --no-cache-dir -r requirements.txt

# Expose port and run application
EXPOSE 5000
CMD ["python", "backend.py"]

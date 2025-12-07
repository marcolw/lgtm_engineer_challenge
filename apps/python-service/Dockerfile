# Use slim variant for smaller footprint
FROM python:3.9-slim

WORKDIR /app

# Install dependencies
# We create a requirements.txt on the fly here for simplicity in the demo
# In a real repo, this file would exist in the source
RUN echo "flask==2.3.2" > requirements.txt && \
    echo "opentelemetry-distro" >> requirements.txt && \
    echo "opentelemetry-exporter-otlp" >> requirements.txt && \
    echo "requests" >> requirements.txt && \
    pip install --no-cache-dir -r requirements.txt

COPY app.py .

EXPOSE 5000

# Run with OTel auto-instrumentation as a backup/enhancement to manual code
CMD ["python", "app.py"]
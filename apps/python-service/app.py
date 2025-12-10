from flask import Flask, request
from opentelemetry import trace
from opentelemetry.instrumentation.flask import FlaskInstrumentor
from opentelemetry.instrumentation.requests import RequestsInstrumentor
# New critical import: WSGI middleware for robust context extraction
from opentelemetry.instrumentation.wsgi import OpenTelemetryMiddleware 
import time
import requests

# NOTE: ALL MANUAL OTLP SETUP IS REMOVED. 
# The trace provider will now be initialized by the opentelemetry-distro 
# package via the standard OTEL environment variables (set in docker-compose.yaml).

tracer = trace.get_tracer(__name__)
app = Flask(__name__)

# Use OpenTelemetryMiddleware for guaranteed trace context extraction 
# and span creation on incoming requests.
# It uses the trace provider initialized by environment variables.
app.wsgi_app = OpenTelemetryMiddleware(app.wsgi_app)

FlaskInstrumentor().instrument_app(app) # Auto-instrument Flask (redundant but safe)
RequestsInstrumentor().instrument() # Auto-instrument outgoing requests

@app.route("/api") # <--- FIX: Ensure this endpoint matches the Go call site!
def process():
    # ... rest of your code remains the same ...
    with tracer.start_as_current_span("heavy-calculation"):
        current_span = trace.get_current_span()
        current_span.set_attribute("calculation.complexity", "high")
        
        # Simulate Logic
        time.sleep(0.1)
        
        # Manual log event attached to trace
        current_span.add_event("Starting calculation...")
        try:
            # Simulate external call (Note: This external service does not exist in your demo)
            requests.get("http://java-service/data")
        except Exception as e:
            current_span.record_exception(e)
            
    return "Python Processed", 200

if __name__ == "__main__":
    app.run(host='0.0.0.0', port=5000)
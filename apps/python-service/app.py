from flask import Flask, request
from opentelemetry import trace
from opentelemetry.exporter.otlp.proto.grpc.trace_exporter import OTLPSpanExporter
from opentelemetry.sdk.resources import Resource
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import BatchSpanProcessor
from opentelemetry.instrumentation.flask import FlaskInstrumentor
from opentelemetry.instrumentation.requests import RequestsInstrumentor
import time
import requests

# Setup OTel
resource = Resource(attributes={"service.name": "python-service"})
trace.set_tracer_provider(TracerProvider(resource=resource))
tracer = trace.get_tracer(__name__)
otlp_exporter = OTLPSpanExporter(endpoint="otel-collector.observability.svc.cluster.local:4317", insecure=True)
trace.get_tracer_provider().add_span_processor(BatchSpanProcessor(otlp_exporter))

app = Flask(__name__)
FlaskInstrumentor().instrument_app(app) # Auto-instrument Flask
RequestsInstrumentor().instrument() # Auto-instrument outgoing requests

@app.route("/process")
def process():
    with tracer.start_as_current_span("heavy-calculation"):
        current_span = trace.get_current_span()
        current_span.set_attribute("calculation.complexity", "high")
        
        # Simulate Logic
        time.sleep(0.1)
        
        # Manual log event attached to trace
        current_span.add_event("Starting calculation...")
        try:
            # Simulate external call
            requests.get("http://java-service/data")
        except Exception as e:
            current_span.record_exception(e)
            
    return "Python Processed", 200

if __name__ == "__main__":
    app.run(host='0.0.0.0', port=5000)
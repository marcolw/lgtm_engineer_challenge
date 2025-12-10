# Go Demo Service (go-lgtm-service)

This is the middle-tier service in the LGTM demo chain, responsible for handling business logic and calling the downstream Python service.

## 🛠️ Telemetry Setup (Manual Instrumentation)

This service uses the OpenTelemetry Go SDK. The key setup steps are:
1.  **Instrumentation:** Spans are created manually around the main HTTP handler function.
2.  **Context Propagation:** The service extracts the incoming trace context from the HTTP header (passed by the Node service) to ensure the spans are correctly linked.
3.  **Exporter:** The OTLP gRPC Exporter is configured to send traces to the collector endpoint defined by the `OTEL_EXPORTER_OTLP_ENDPOINT` environment variable.

## 🐳 Docker Build

```bash
docker build -t marcoliew/lgtm-go-service:v0.1.0 .
docker push marcoliew/lgtm-go-service:v0.1.0
# Node.js Demo Service (node-lgtm-service)

This is the publicly exposed entry-point service, responsible for starting the trace chain and calling the Go service.

## 🛠️ Telemetry Setup (Manual Instrumentation)

This service uses the OpenTelemetry Node.js SDK.
1.  **Root Span:** It initializes the trace when an external request is received.
2.  **Propagation:** It injects the trace context into the outgoing HTTP call to the Go service, ensuring downstream services correctly link their spans.

## 🐳 Docker Build

```bash
docker build -t marcoliew/lgtm-node-service:v0.1.0 .
docker push marcoliew/lgtm-node-service:v0.1.0
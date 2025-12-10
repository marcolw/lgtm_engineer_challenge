const { NodeSDK } = require('@opentelemetry/sdk-node');
const { OTLPTraceExporter } = require('@opentelemetry/exporter-trace-otlp-grpc');
const { HttpInstrumentation } = require('@opentelemetry/instrumentation-http');
const opentelemetry = require('@opentelemetry/api');
const axios = require('axios'); // REQUIRED for making HTTP calls to the Go service

// Configuration variables (Pulled from environment, defaulting for safety)
const PORT = 3000;
const GO_SERVICE_URL = process.env.GO_SERVICE_URL || 'http://go-service:8080';

// 1. Initialize OpenTelemetry SDK (Uses OTEL_SERVICE_NAME environment variable)
const sdk = new NodeSDK({
  // Register the instrumentation here
  instrumentations: [
    new HttpInstrumentation(),
  ],
  traceExporter: new OTLPTraceExporter({
    // Uses the Docker Compose service name for local testing
    url: process.env.OTEL_EXPORTER_OTLP_ENDPOINT || 'http://otel-collector:4317', 
  }),
});
sdk.start();

const express = require('express');
const app = express();
const tracer = opentelemetry.trace.getTracer('nodejs-service');

// 2. ROOT ROUTE: Redirects or provides a welcome message (Prevents "Cannot GET /")
app.get('/', (req, res) => {
    res.json({ 
        service: 'NodeJS Entry Service',
        status: 'OK',
        next_step: 'Access /api to trigger the trace chain.'
    });
});

// 3. API ROUTE: Triggers the full trace chain (Node -> Go -> Python)
app.get('/api', async (req, res) => {
  const span = tracer.startSpan('entry-request: /api');
  span.setAttribute('http.target', '/api');

  try {
    // 1. Call the downstream Go service (Trace context propagates automatically)
    // NOTE: This uses the environment variable GO_SERVICE_URL set in docker-compose
    const goResponse = await axios.get(GO_SERVICE_URL + '/api', {
        timeout: 5000 // Timeout in 5 seconds
    });

    // 2. Log the event
    span.addEvent('called-go-service', { 'go.status': goResponse.status.toString() });
    
    // 3. Respond to the user
    res.json({
        status: 'success',
        trace_id: span.spanContext().traceId,
        message: 'Request processed through Node -> Go -> Python',
        details: goResponse.data
    });

  } catch (error) {
    span.setStatus({ code: opentelemetry.SpanStatusCode.ERROR, message: `Call to Go Service Failed: ${error.message}` });
    console.error('Trace chain error:', error.message);
    res.status(500).json({ error: 'Internal Server Error', message: `Failed to connect to Go service at ${GO_SERVICE_URL}` });
  } finally {
    span.end();
  }
});

// 4. Start the server
app.listen(PORT, () => {
  console.log(`Node Service listening on ${PORT}`);
});
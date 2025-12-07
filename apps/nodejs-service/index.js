const { NodeSDK } = require('@opentelemetry/sdk-node');
const { OTLPTraceExporter } = require('@opentelemetry/exporter-trace-otlp-grpc');
const { Resource } = require('@opentelemetry/resources');
const { SemanticResourceAttributes } = require('@opentelemetry/semantic-conventions');
const opentelemetry = require('@opentelemetry/api');

// 1. Initialize SDK
const sdk = new NodeSDK({
  resource: new Resource({
    [SemanticResourceAttributes.SERVICE_NAME]: 'nodejs-service',
  }),
  traceExporter: new OTLPTraceExporter({
    url: 'http://otel-collector.observability.svc.cluster.local:4317',
  }),
});

sdk.start();

const express = require('express');
const app = express();
const tracer = opentelemetry.trace.getTracer('nodejs-service');

app.get('/api', (req, res) => {
  // Manual Span
  const span = tracer.startSpan('database-query-sim');
  
  // Simulate Async DB Call
  setTimeout(() => {
    span.addEvent('query executed', { 'db.statement': 'SELECT * FROM users' });
    span.end();
    res.send('NodeJS Response');
  }, 100);
});

app.listen(3000, () => {
  console.log('Node Service listening on 3000');
});

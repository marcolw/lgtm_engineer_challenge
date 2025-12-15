package main

import (
	"context"
	"fmt"
	"log"
	"net/http"
	"os"
	"time"

	"go.opentelemetry.io/contrib/instrumentation/net/http/otelhttp"
	"go.opentelemetry.io/otel"
	"go.opentelemetry.io/otel/attribute"
	"go.opentelemetry.io/otel/exporters/otlp/otlptrace/otlptracegrpc"
	"go.opentelemetry.io/otel/propagation"
	"go.opentelemetry.io/otel/sdk/resource"
	sdktrace "go.opentelemetry.io/otel/sdk/trace"
	semconv "go.opentelemetry.io/otel/semconv/v1.17.0"
)

var tracer = otel.Tracer("go-service")

func initTracer() func(context.Context) error {
	ctx := context.Background()

	// Resolve Collector Endpoint from ENV
	collectorEndpoint := os.Getenv("OTEL_EXPORTER_OTLP_ENDPOINT")
	if collectorEndpoint == "" {
		// Fallback to the Docker internal name
		collectorEndpoint = "otel-collector:4317"
	}

	// Exporter Setup
	exporter, err := otlptracegrpc.New(ctx, otlptracegrpc.WithInsecure(), otlptracegrpc.WithEndpoint(collectorEndpoint))
	if err != nil {
		log.Fatalf("failed to create exporter: %v", err)
	}

	// Resolve Service Name from ENV
	serviceName := os.Getenv("OTEL_SERVICE_NAME")
	if serviceName == "" {
		serviceName = "go-lgtm-service"
	}

	res, err := resource.New(ctx,
		resource.WithAttributes(
			semconv.ServiceName(serviceName), // Use the dynamic name
			attribute.String("environment", "demo"),
		),
	)
	if err != nil {
		log.Fatalf("failed to create resource: %v", err)
	}

	tp := sdktrace.NewTracerProvider(
		sdktrace.WithBatcher(exporter),
		sdktrace.WithResource(res),
	)
	otel.SetTracerProvider(tp)
	otel.SetTextMapPropagator(propagation.NewCompositeTextMapPropagator(propagation.TraceContext{}, propagation.Baggage{})) // Propagator

	return tp.Shutdown
}

func handler(w http.ResponseWriter, r *http.Request) {
	// 1. Extract Context (if called from another service)
	ctx := r.Context() // Context Extraction, which now contains the active span created by otelhttp.NewHandler

	// 2. Start a Manual Span
	ctx, span := tracer.Start(ctx, "process-request")
	defer span.End()

	// 3. Add Custom Attributes (The "Observerability" gold)
	span.SetAttributes(attribute.String("http.method", r.Method))
	//Custom Metadata. Adds the valuable user.id attribute that can be used for querying and analysis in Jaeger.
	span.SetAttributes(attribute.String("user.id", "user-123"))

	// Simulate work
	time.Sleep(50 * time.Millisecond)

	// 4. Propagate to downstream (Python Service)
	callPythonService(ctx)

	fmt.Fprintf(w, "Go Service: Done")
}

func callPythonService(ctx context.Context) {
	// Get URL from Environment variable for robustness
	pythonURL := os.Getenv("PYTHON_SERVICE_URL")
	if pythonURL == "" {
		pythonURL = "http://python-service:5000" // Default for safety
	}

	ctx, span := tracer.Start(ctx, "call-python-service") // Start a manual span
	defer span.End()

	// Creates the HTTP request to python service using the active, traced context (ctx)
	req, _ := http.NewRequestWithContext(ctx, "GET", pythonURL+"/api", nil)

	// Inject headers for context Downstream Propagation
	otel.GetTextMapPropagator().Inject(ctx, propagation.HeaderCarrier(req.Header))

	client := &http.Client{}
	resp, err := client.Do(req)
	if err != nil {
		span.RecordError(err)
		return
	}
	defer resp.Body.Close()
}

func main() {
	shutdown := initTracer()
	defer shutdown(context.Background())
	// -------------------------------------------------------------------
	// Wrap the handler with otelhttp.NewHandler
	// This extracts the trace context from headers and starts the top span
	// for the Go service.
	// -------------------------------------------------------------------
	http.Handle("/", otelhttp.NewHandler(http.HandlerFunc(handler), "go-lgtm-service")) // Auto-Instrumentation of Inbound Traffic.

	log.Println("Go Service running on :8080")
	http.ListenAndServe(":8080", nil)
}

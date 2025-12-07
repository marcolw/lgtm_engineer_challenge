package main

import (
	"context"
	"fmt"
	"log"
	"net/http"
	"time"

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
	
    // Point to the OTel Collector (running in K8s)
	exporter, err := otlptracegrpc.New(ctx, otlptracegrpc.WithInsecure(), otlptracegrpc.WithEndpoint("otel-collector.observability.svc.cluster.local:4317"))
	if err != nil {
		log.Fatalf("failed to create exporter: %v", err)
	}

	res, err := resource.New(ctx,
		resource.WithAttributes(
			semconv.ServiceName("go-service"),
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
	otel.SetTextMapPropagator(propagation.NewCompositeTextMapPropagator(propagation.TraceContext{}, propagation.Baggage{}))

	return tp.Shutdown
}

func handler(w http.ResponseWriter, r *http.Request) {
    // 1. Extract Context (if called from another service)
	ctx := r.Context()
	
    // 2. Start a Manual Span
	ctx, span := tracer.Start(ctx, "process-request")
	defer span.End()

    // 3. Add Custom Attributes (The "Observerability" gold)
	span.SetAttributes(attribute.String("http.method", r.Method))
	span.SetAttributes(attribute.String("user.id", "user-123"))

	// Simulate work
	time.Sleep(50 * time.Millisecond)
	
    // 4. Propagate to downstream (NodeJS Service)
	callNodeService(ctx)

	fmt.Fprintf(w, "Go Service: Done")
}

func callNodeService(ctx context.Context) {
	ctx, span := tracer.Start(ctx, "call-node-service")
	defer span.End()

	req, _ := http.NewRequestWithContext(ctx, "GET", "http://nodejs-service/api", nil)
    
    // Inject headers for context propagation
	otel.GetTextMapPropagator().Inject(ctx, propagation.HeaderCarrier(req.Header))
	
	client := &http.Client{}
	resp, err := client.Do(req)
	if err != nil {
		span.RecordError(err) // Record error in trace
		return
	}
	defer resp.Body.Close()
}

func main() {
	shutdown := initTracer()
	defer shutdown(context.Background())

	http.HandleFunc("/", handler)
	log.Println("Go Service running on :8080")
	http.ListenAndServe(":8080", nil)
}
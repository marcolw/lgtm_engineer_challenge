# Stage 1: Build
FROM golang:1.25-alpine AS builder
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY *.go ./
RUN CGO_ENABLED=0 GOOS=linux go build -o /go-service

# Stage 2: Runtime (Distroless for security & tiny size)
FROM gcr.io/distroless/static-debian11
WORKDIR /
COPY --from=builder /go-service /go-service
EXPOSE 8080
USER nonroot:nonroot
ENTRYPOINT ["/go-service"]
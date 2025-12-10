# Stage 1: The Builder Stage
# CRITICAL FIX: Use a valid tag that gives the latest Go version.
FROM golang:latest AS builder 
WORKDIR /app

# 1. Copy and download dependencies
COPY go.mod .
COPY go.sum .
RUN go mod download

# 2. Copy the rest of the source code and build
COPY . .
# CRITICAL FIX 2: Ensures the binary is statically linked for Alpine runtime
RUN CGO_ENABLED=0 GOOS=linux go build -o go-service main.go 

# Stage 2: The Final Runtime Stage
# Use a minimal image (alpine) that is safe for CGO_ENABLED=0 binaries
FROM alpine:latest
WORKDIR /app

# Install necessary runtime dependencies (especially SSL certs)
RUN apk add --no-cache ca-certificates

# Copy the compiled binary from the builder stage
COPY --from=builder /app/go-service .

EXPOSE 8080

CMD ["./go-service"]
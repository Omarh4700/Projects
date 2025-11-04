# Stage 1: build the Go binary ans taged image as builder for multi-stage build for alpine image 
FROM golang:1.25 AS builder
WORKDIR /app

# Copy module files and download deps (cacheable layer)
COPY go.mod go.sum ./
RUN go mod download

# Copy source and build optimized static binary
COPY . .
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 \
    go build -ldflags="-s -w" -o /app/main .

# Stage 2: minimal runtime image
FROM alpine:3.22
RUN apk add --no-cache ca-certificates
WORKDIR /root/

# Copy binary from builder stage
COPY --from=builder /app/main .

EXPOSE 8080
CMD ["./main"]

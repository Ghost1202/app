### STAGE 1: BUILD ###
FROM golang:1.21-alpine AS builder

# Install required packages
RUN apk update && apk upgrade && \
    apk add --no-cache bash git openssh

# Set working directory
WORKDIR /app

# Copy all project files
COPY . /app

# Download dependencies
RUN go mod download

# Install swag CLI (fixed version)
RUN go install github.com/swaggo/swag/cmd/swag@v1.8.1

# Generate Swagger docs
RUN /go/bin/swag init -g ./cmd/api/main.go -o ./docs

# Install wire CLI
RUN go install github.com/google/wire/cmd/wire@latest

# Generate wire dependencies
RUN /go/bin/wire ./internal/wired/mongo.go

# Build the Go application
RUN go build -o /go/bin/todoapi ./cmd/api

### STAGE 2: RUN ###
FROM golang:1.21-alpine

# Install necessary runtime packages (if needed)
RUN apk add --no-cache bash

# Copy compiled binary
COPY --from=builder /go/bin/todoapi /go/bin/todoapi

# Expose port
EXPOSE 8080

# Run the application
CMD ["/go/bin/todoapi"]

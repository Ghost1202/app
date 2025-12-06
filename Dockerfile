### STAGE 1: BUILD ###
FROM golang:1.21-alpine AS builder

# Install required packages
RUN apk update && apk upgrade && \
    apk add --no-cache bash git openssh

# Set workdir
WORKDIR /app

# Copy all project files
ADD . /app

# Download dependencies
RUN go mod download

# Install swag CLI with version matching docs
RUN go install github.com/swaggo/swag/cmd/swag@v1.8.1

# Generate Swagger docs
RUN /go/bin/swag init -g ./cmd/api/main.go -o ./docs

# Install wire CLI
RUN go install github.com/google/wire/cmd/wire@latest

# Generate wire dependencies
RUN /go/bin/wire ./internal/wired/mongo.go

# Build the Go application
RUN go build -o ./todoapi ./cmd/api

### STAGE 2: RUN ###
FROM golang:1.21-alpine

# Copy compiled binary
COPY --from=builder /app/todoapi /go/bin/todoapi

# Expose port
EXPOSE 8080

# Run the application
CMD ["todoapi"]

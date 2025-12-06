# Dockerfile References: https://docs.docker.com/engine/reference/builder/

### STAGE 1: BUILD ###
FROM golang:1.21-alpine as builder

# Install required tools
RUN apk update && apk upgrade && \
    apk add --no-cache bash git openssh

# Set working directory
WORKDIR /app
ADD . /app

# Download dependencies
RUN go mod download

# Add Go bin to PATH
ENV PATH="$PATH:$(go env GOPATH)/bin"

# Install swag and generate Swagger documentation
RUN go install github.com/swaggo/swag/cmd/swag@latest && \
    swag init -g ./cmd/api/main.go -o ./docs

# Install wire and generate dependencies
RUN go install github.com/google/wire/cmd/wire@latest && \
    wire ./internal/wired/mongo.go

# Build the Go application
RUN go build -o ./todoapi ./cmd/api

### STAGE 2: RUN ###
FROM golang:1.21-alpine

# Copy the compiled application
COPY --from=builder /app/todoapi /go/bin/todoapi

# Expose port 8080
EXPOSE 8080

# Run the executable
CMD ["todoapi"]

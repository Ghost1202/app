### STAGE 1: BUILD ###
FROM golang:1.21-alpine as builder

RUN apk update && apk upgrade && \
    apk add --no-cache bash git openssh build-base curl

ENV GO111MODULE=on
ENV GOPROXY=https://proxy.golang.org,direct
ENV PATH="/go/bin:${PATH}"

WORKDIR /app

COPY . /app

RUN go mod download

RUN go install github.com/swaggo/swag/cmd/swag@v1.8.1

RUN mkdir -p ./docs

# Generate swagger documentation
RUN /go/bin/swag init -g ./cmd/api/main.go -o ./docs --parseInternal --parseDependency

RUN go install github.com/google/wire/cmd/wire@latest

RUN /go/bin/wire ./internal/wired/mongo.go

RUN go build -o ./todoapi ./cmd/api

### STAGE 2: RUN ###
FROM golang:1.21-alpine

ENV PATH="/go/bin:${PATH}"

COPY --from=builder /app/todoapi /go/bin/todoapi

EXPOSE 8080

CMD ["todoapi"]

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
RUN go install github.com/google/wire/cmd/wire@latest

RUN mkdir -p ./docs
RUN /go/bin/swag init -g ./cmd/api/main.go -o ./docs --parseInternal --parseDependency || true
RUN /go/bin/wire ./internal/wired/mongo.go || true

RUN go build -o /go/bin/todoapi ./cmd/api

FROM golang:1.21-alpine

ENV PATH="/go/bin:${PATH}"

WORKDIR /app

COPY --from=builder /go/bin/todoapi /go/bin/todoapi
COPY --from=builder /app/docs /app/docs

EXPOSE 8080

CMD ["todoapi"]

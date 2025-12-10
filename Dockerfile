FROM golang:1.21-alpine as builder

RUN apk update && apk upgrade && \
    apk add --no-cache bash git openssh build-base curl

ENV GO111MODULE=on
ENV GOPROXY=https://proxy.golang.org,direct
ENV PATH="/go/bin:${PATH}"

WORKDIR /src

COPY . /src

RUN go mod download

RUN go install github.com/swaggo/swag/cmd/swag@v1.8.1

RUN mkdir -p /src/docs

RUN /go/bin/swag init -g cmd/api/main.go -o docs --parseInternal --parseDependency

RUN go install github.com/google/wire/cmd/wire@latest

RUN /go/bin/wire ./internal/wired/mongo.go

RUN go build -o /src/todoapi cmd/api

FROM golang:1.21-alpine

ENV PATH="/go/bin:${PATH}"

COPY --from=builder /src/todoapi /go/bin/todoapi

EXPOSE 8080

CMD ["todoapi"]

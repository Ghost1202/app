### STAGE 1: BUILD ###
FROM golang:1.21-alpine as builder

RUN apk update && apk upgrade && \
    apk add --no-cache bash git openssh build-base curl

ENV GO111MODULE=on
ENV GOPROXY=https://proxy.golang.org,direct
ENV PATH="/go/bin:${PATH}"

# Рабочая папка
WORKDIR /app

# Копируем весь проект
COPY . /app

# Загружаем зависимости
RUN go mod download

# Устанавливаем swag
RUN go install github.com/swaggo/swag/cmd/swag@v1.8.1

# Создаём папку для документации
RUN mkdir -p ./docs

# Генерация swagger документации
# Путь указываем так, чтобы swag видел main.go и все internal пакеты
RUN /go/bin/swag init -g ./go-todo-app/cmd/api/main.go -o ./go-todo-app/docs --parseInternal --parseDependency

# Устанавливаем wire, если используется
RUN go install github.com/google/wire/cmd/wire@latest

# Генерация wire
RUN /go/bin/wire ./go-todo-app/internal/wired/mongo.go

# Собираем бинарник
RUN go build -o ./todoapi ./go-todo-app/cmd/api

### STAGE 2: RUN ###
FROM golang:1.21-alpine

ENV PATH="/go/bin:${PATH}"

# Копируем бинарник из билд-стадии
COPY --from=builder /app/todoapi /go/bin/todoapi

EXPOSE 8080

CMD ["todoapi"]

### STAGE 1: BUILD ###
FROM golang:1.21-alpine as builder

# Устанавливаем необходимые пакеты
RUN apk update && apk upgrade && \
    apk add --no-cache bash git openssh build-base curl

# Устанавливаем рабочую директорию
WORKDIR /app

# Копируем все файлы проекта
COPY . /app

# Загружаем зависимости
RUN go mod download

# Устанавливаем swag CLI фиксированной версии
RUN go install github.com/swaggo/swag/cmd/swag@v1.8.1

# Генерируем Swagger документацию (учитываем internal пакеты)
RUN /go/bin/swag init -g ./cmd/api/main.go -o ./docs --parseInternal

# Устанавливаем wire CLI
RUN go install github.com/google/wire/cmd/wire@latest

# Генерируем wire зависимости
RUN /go/bin/wire ./internal/wired/mongo.go

# Компилируем Go-приложение
RUN go build -o ./todoapi ./cmd/api

### STAGE 2: RUN ###
FROM golang:1.21-alpine

# Копируем бинарь из builder
COPY --from=builder /app/todoapi /go/bin/todoapi

# Открываем порт
EXPOSE 8080

# Запускаем приложение
CMD ["todoapi"]

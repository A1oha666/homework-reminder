FROM golang:1.21-alpine AS builder

WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download

COPY main.go ./
RUN CGO_ENABLED=0 GOOS=linux go build -o homework-server main.go

FROM alpine:latest

RUN apk --no-cache add ca-certificates tzdata && mkdir -p /data

WORKDIR /app
COPY --from=builder /app/homework-server .
COPY homework.json .
COPY templates/ ./templates/

EXPOSE 8080

CMD ["./homework-server"]

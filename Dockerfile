FROM golang:1.21-alpine AS builder

WORKDIR /app
COPY main.go go.mod ./
RUN go mod download
RUN CGO_ENABLED=0 GOOS=linux go build -o homework-server main.go

FROM alpine:latest

RUN apk --no-cache add ca-certificates tzdata

WORKDIR /app
COPY --from=builder /app/homework-server .
COPY homework.json .

EXPOSE 8080

CMD ["./homework-server"]

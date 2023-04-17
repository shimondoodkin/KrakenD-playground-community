# build stage
FROM golang:alpine AS build-env
# RUN apk --no-cache add build-base git bzr mercurial gcc

RUN mkdir /app
WORKDIR /app
COPY . .

RUN GOPROXY=https://goproxy.io go get -d -v ./...
RUN go build .  -o jwt-revoker


# final stage
FROM alpine
WORKDIR /app
EXPOSE 8080
COPY --from=build-env /app/jwt-revoker /app/
CMD ["/app/jwt-revoker", "-server", "krakend_ce:1234"]

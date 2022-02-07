# Copyright (c) 2022 Arduino.cc
#
# Based on https://github.com/bcmi-labs/cloudshell
#
# License: MIT

# Examples:
# docker build --tag "cloudshell:latest" .
# docker run -p 8000:8000 -it --rm --user "63" -it cloudshell:latest

FROM golang:1.16-alpine AS backend

LABEL maintainer="Massimo Pennazio <maxipenna@libero.it>"

WORKDIR /go/src/cloudshell
COPY ./cmd ./cmd
COPY ./internal ./internal
COPY ./pkg ./pkg
COPY ./go.mod .
COPY ./go.sum .
ENV CGO_ENABLED=0
RUN go mod vendor
ARG VERSION_INFO=dev-build
RUN go build -a -v \
  -ldflags " \
  -s -w \
  -extldflags 'static' \
  -X main.VersionInfo='${VERSION_INFO}' \
  " \
  -o ./bin/cloudshell \
  ./cmd/cloudshell

FROM node:16.0.0-alpine AS frontend
WORKDIR /app
COPY ./package.json .
COPY ./package-lock.json .
RUN npm install

FROM alpine:3.14.0
WORKDIR /app
RUN apk add --no-cache bash ncurses
COPY --from=backend /go/src/cloudshell/bin/cloudshell /app/cloudshell
COPY --from=frontend /app/node_modules /app/node_modules
COPY ./public /app/public
RUN ln -s /app/cloudshell /usr/bin/cloudshell
RUN adduser -D -u 1000 user
RUN mkdir -p /home/user
RUN chown user:user /app -R
WORKDIR /
ENV WORKDIR=/app
ENV LOG_LEVEL="trace"
ENV ALLOWED_HOSTNAMES="portenta-x8.local"
ENV SERVER_PORT="8000"
ENV SERVER_ADDRESS="192.168.7.1"
USER user
ENTRYPOINT ["/app/cloudshell"]

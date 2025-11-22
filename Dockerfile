FROM nginx:stable-alpine

RUN apk add --no-cache bash

COPY ./nginx.conf /etc/nginx/conf.d/default.conf
COPY ./public /usr/share/nginx/html

EXPOSE 80

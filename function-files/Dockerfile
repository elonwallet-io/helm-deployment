FROM golang:latest as build-env

ENV CGO_ENABLED=0

COPY . /app/
WORKDIR /app/

RUN mkdir /data && \
    go build -o backend -ldflags="-extldflags=-static -w" .

FROM busybox:1.35.0-uclibc as busybox


FROM gcr.io/distroless/static

COPY --from=build-env --chown=nonroot:nonroot \
    /app/backend \
    /app/

COPY --from=build-env --chown=nonroot:nonroot \
    /data \
    /data
    
COPY --from=busybox:1.35.0-uclibc /bin/sh /bin/sh
COPY --from=busybox:1.35.0-uclibc /bin/chown /bin/chown
COPY --from=busybox:1.35.0-uclibc /bin/su /bin/su
WORKDIR /app/
COPY entrypoint.sh /app/entrypoint.sh
ENTRYPOINT ["/bin/sh", "/app/entrypoint.sh"]
CMD [ "/app/backend" ]

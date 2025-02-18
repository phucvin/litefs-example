# Fetch the LiteFS binary using a multi-stage build.
FROM flyio/litefs:pr-109 AS litefs


# Build our application using a Go builder.
FROM golang:1.16 AS builder
WORKDIR /src/litefs-example
COPY . .
RUN go build -ldflags "-s -w -extldflags '-static'" -tags osusergo,netgo -o /usr/local/bin/litefs-example ./cmd/litefs-example


# Our final Docker image stage starts here.
FROM alpine

# Copy binaries from the previous build stages.
COPY --from=builder /usr/local/bin/litefs-example /usr/local/bin/litefs-example
COPY --from=litefs /usr/local/bin/litefs /usr/local/bin/litefs

# Copy our LiteFS configuration.
ADD etc/litefs.yml /etc/litefs.yml

# Setup our environment to include FUSE & SQLite.
RUN apk add bash curl fuse sqlite

# Ensure our mount & data directories exists before mounting with LiteFS.
RUN mkdir -p /data /mnt/data

# Run LiteFS as the entrypoint so it can execute "litefs-example" as a subprocess.
ENTRYPOINT "litefs"

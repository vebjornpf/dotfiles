FROM ubuntu:22.04

RUN apt-get update && \
    apt-get install -y --no-install-recommends curl ca-certificates && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /root/dotfiles
COPY . .

# Default to an interactive shell inside the repo.
CMD ["bash"]

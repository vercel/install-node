FROM ubuntu
RUN apt-get update && apt-get install -y curl
WORKDIR /node
COPY install.sh /node
CMD cat install.sh | sh -s -- -y && node -v

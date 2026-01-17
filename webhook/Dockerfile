FROM node:20-bookworm-slim

WORKDIR /app

RUN apt-get update \
    && apt-get install -y --no-install-recommends bash ca-certificates curl jq \
    && rm -rf /var/lib/apt/lists/*

RUN curl -sSL https://get.livekit.io/cli | bash

COPY webhook/package.json /app/package.json
RUN npm install --omit=dev

COPY egress/bin/start.sh /app/start.sh
RUN chmod +x /app/start.sh

COPY webhook/server.js /app/server.js

EXPOSE 8080

CMD ["node", "/app/server.js"]

FROM node:18-alpine

WORKDIR /app

# Initialize package.json on the fly if it doesn't exist
# In production, you would COPY package.json .
RUN npm init -y && \
    npm install express @opentelemetry/sdk-node @opentelemetry/auto-instrumentations-node @opentelemetry/exporter-trace-otlp-grpc

COPY index.js .

EXPOSE 3000

CMD ["node", "index.js"]
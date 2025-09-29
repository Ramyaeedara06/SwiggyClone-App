FROM node:18 AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build || true

FROM node:18-slim
WORKDIR /app
COPY --from=builder /app ./
EXPOSE 3000
CMD ["node", "src/index.js"]


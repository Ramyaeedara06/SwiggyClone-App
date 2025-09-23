# ---- Builder ----
FROM node:18-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci --production=false
COPY . .
RUN npm run build || true

# ---- Production image ----
FROM node:18-alpine
WORKDIR /app
ENV NODE_ENV=production
# create non-root user
RUN addgroup -S appgroup && adduser -S appuser -G appgroup
COPY --from=builder /app/package*.json ./
COPY --from=builder /app/src ./src
RUN npm ci --production
USER appuser
EXPOSE 3000
CMD [ "node", "src/index.js" ]

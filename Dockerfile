FROM node:18-alpine AS builder
WORKDIR /app
COPY package*.json ./
# Esto para que no se instalen las dependencias de desarrollo y reducir más el tamaño de la imagen
RUN npm install --only=production
FROM node:18-alpine
RUN addgroup -S appgroup && adduser -S appuser -G appgroup
WORKDIR /app
COPY --from=builder /app/node_modules ./node_modules
COPY app.js ./
RUN chown -R appuser:appgroup /app
USER appuser
ENTRYPOINT ["node", "app.js"]
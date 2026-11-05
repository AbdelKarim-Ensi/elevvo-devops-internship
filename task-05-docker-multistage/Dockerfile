# ---- Stage 1: build (dependencies) ----
FROM node:20-alpine AS build
WORKDIR /app
COPY app/package*.json ./
RUN npm install --omit=dev && npm cache clean --force
COPY app/ .

# ---- Stage 2: minimal runtime ----
FROM node:20-alpine
ENV NODE_ENV=production
WORKDIR /app
COPY --from=build --chown=node:node /app ./
USER node
EXPOSE 3000
HEALTHCHECK --interval=15s --timeout=3s --retries=3 \
  CMD wget -qO- http://127.0.0.1:3000/health || exit 1
CMD ["node", "server.js"]

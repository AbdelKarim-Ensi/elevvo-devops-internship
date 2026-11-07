# ---- Stage 1: build (dependencies prepared on host) ----
FROM node:22-alpine AS build
WORKDIR /app
COPY app/package.json app/package-lock.json ./
COPY app/node_modules ./node_modules
COPY app/server.js ./

# ---- Stage 2: minimal hardened runtime ----
FROM node:22-alpine AS runtime
ENV NODE_ENV=production
# Patch OS packages, then remove build-time tooling not needed at runtime
RUN apk upgrade --no-cache \
 && rm -rf /usr/local/lib/node_modules/npm \
           /usr/local/lib/node_modules/corepack \
           /usr/local/bin/npm /usr/local/bin/npx /usr/local/bin/corepack \
           /opt/yarn-* /usr/local/bin/yarn /usr/local/bin/yarnpkg
WORKDIR /app
COPY --from=build --chown=node:node /app ./
USER node
EXPOSE 3000
HEALTHCHECK --interval=15s --timeout=3s --start-period=10s \
  CMD wget -qO- http://127.0.0.1:3000/health || exit 1
CMD ["node", "server.js"]

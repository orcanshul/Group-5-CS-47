FROM node:18-slim

# Install Java (needed to run MARS)
RUN apt-get update && \
    apt-get install -y default-jre-headless curl && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Download MARS 4.5 JAR
RUN mkdir -p backend/mars && \
    curl -fL -o backend/mars/Mars4_5.jar \
    "https://github.com/dpetersanderson/MARS/releases/download/v.4.5.1/Mars4_5.jar" && \
    echo "MARS JAR downloaded successfully"

# ── backend ──────────────────────────────────────────────────────────────────
COPY backend/package.json backend/
RUN cd backend && npm install --omit=dev

COPY backend/server.js backend/

# ── frontend ──────────────────────────────────────────────────────────────────
COPY frontend/package.json frontend/
RUN cd frontend && npm install

COPY frontend/ frontend/
RUN cd frontend && npm run build

# Move built frontend where the backend can serve it
RUN cp -r frontend/dist backend/public

# ── MIPS files ────────────────────────────────────────────────────────────────
COPY *.asm ./

EXPOSE 3001
ENV PORT=3001
ENV NODE_ENV=production

CMD ["node", "backend/server.js"]

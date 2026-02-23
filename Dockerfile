FROM node:18

WORKDIR /app/backend

COPY backend/package*.json ./

RUN npm install

COPY backend/ .

WORKDIR /app/backend/src

CMD ["node", "server.js"]
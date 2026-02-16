FROM node:18

WORKDIR /app/backend

COPY backend/package*.json ./

RUN npm install

COPY backend/ .

ARG SERVICE_PATH
ENV SERVICE_PATH=${SERVICE_PATH}

WORKDIR /app/backend/${SERVICE_PATH}

CMD ["node", "server.js"]
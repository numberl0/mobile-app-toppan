FROM node:18-alpine

WORKDIR /app

COPY service ./service/
COPY shared ./shared/

WORKDIR /app/shared
RUN npm install

WORKDIR /app/service/gateway
RUN npm install

EXPOSE 5000

CMD ["node", "server.js"]
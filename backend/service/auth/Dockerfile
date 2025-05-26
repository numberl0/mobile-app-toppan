FROM node:18-alpine

WORKDIR /app

COPY service ./service/
COPY shared ./shared/

WORKDIR /app/shared
RUN npm install

WORKDIR /app/service/auth
RUN npm install

EXPOSE 3000

CMD ["node", "server.js"]
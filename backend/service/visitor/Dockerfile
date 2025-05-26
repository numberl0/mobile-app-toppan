FROM node:18-alpine

WORKDIR /app

COPY service ./service/
COPY shared ./shared/

WORKDIR /app/shared
RUN npm install

WORKDIR /app/service/visitor
RUN npm install

EXPOSE 3306

CMD ["node", "server.js"]
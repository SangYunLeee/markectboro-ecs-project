FROM node:16-alpine

WORKDIR /app

COPY package.json .
COPY package-lock.json .

RUN npm ci

COPY . .

RUN npm run build

ENV PORT=80

EXPOSE 80

CMD ["npm", "run", "builded-start"]
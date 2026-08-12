FROM node:20-alpine

RUN apk add --no-cache openssl

WORKDIR /app

COPY package*.json ./
RUN npm install --omit=dev

COPY . .

RUN npx prisma generate

EXPOSE 4000

# Applies pending migrations then starts the API. For the very first run
# use `docker compose exec api npx prisma migrate deploy` if this needs a
# DB that isn't ready yet on first boot.
CMD sh -c "npx prisma migrate deploy && node src/index.js"

# Dockerfile
FROM node:18-alpine

WORKDIR /app

# copy only package files first to leverage layer cache
COPY package*.json ./
RUN npm ci --only=production

# copy rest of app
COPY . .

# build step (if any)
# RUN npm run build

ENV PORT=3000
EXPOSE 3000

CMD ["node", "index.js"]  

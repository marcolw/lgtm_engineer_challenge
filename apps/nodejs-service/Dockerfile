FROM node:18-alpine

WORKDIR /app

# 1. Copy package files first
COPY package*.json ./ 

# 2. Install dependencies (This should now work with the updated versions)
RUN npm install

# 3. Copy application code (index.js)
COPY index.js .

EXPOSE 3000

CMD [ "npm", "start" ]
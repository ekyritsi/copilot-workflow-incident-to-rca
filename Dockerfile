FROM node:22-alpine

WORKDIR /app
ENV NODE_ENV=production
ENV PORT=8080

COPY package*.json ./
RUN npm ci --omit=dev

COPY src ./src
COPY public ./public

EXPOSE 8080
USER node
CMD ["npm", "start"]

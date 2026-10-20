FROM node:20-alpine AS builder
ENV NODE_ENV="production"
COPY ./restapi /app
WORKDIR /app
RUN npm install --include=dev
RUN npm run build

FROM node:20-alpine
ENV NODE_ENV="production"
WORKDIR /app
COPY --from=builder /app/package*.json /app/
COPY --from=builder /app/dist /app/dist
RUN npm ci --omit=dev
ENV PORT=80
EXPOSE 80

CMD ["npm", "start"]
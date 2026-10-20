FROM node:20-alpine AS builder
ENV NODE_ENV="production"
COPY ./restapi /app
WORKDIR /app
RUN npm install

FROM node:20-alpine
ENV NODE_ENV="production"
COPY --from=builder /app /app
WORKDIR /app
ENV PORT=80
EXPOSE 80

CMD ["npm", "start"]
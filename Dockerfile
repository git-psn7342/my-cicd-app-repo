FROM node:18-slim
WORKDIR /app
COPY . .
EXPOSE 8080
CMD ["node", "app.js"]

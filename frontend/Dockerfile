FROM node:20-alpine AS builder
WORKDIR /app
COPY package.json package-lock.json* ./

# 1. ADD THESE LINES: Define the arguments passed from GitHub Actions
ARG VITE_API_BASE
ARG VITE_ML_BASE
# 2. Map them to environment variables so Vite can bake them into the HTML/JS
ENV VITE_API_BASE=$VITE_API_BASE
ENV VITE_ML_BASE=$VITE_ML_BASE

RUN npm install
COPY . .
RUN npm run build

FROM nginx:alpine
COPY --from=builder /app/dist /usr/share/nginx/html
RUN echo 'server { listen 80; root /usr/share/nginx/html; index index.html; location / { try_files $uri /index.html; } }' > /etc/nginx/conf.d/default.conf
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
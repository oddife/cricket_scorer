# Build Flutter Web, then serve the generated PWA with Nginx.
# Pin Flutter because pubspec.yaml requires Dart >= 3.13.3.
FROM ghcr.io/cirruslabs/flutter:3.47.4 AS builder

WORKDIR /app

COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get

COPY . .
RUN flutter build web --release

FROM nginx:alpine AS runtime

COPY docker/nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=builder /app/build/web /usr/share/nginx/html

EXPOSE 3112

CMD ["nginx", "-g", "daemon off;"]

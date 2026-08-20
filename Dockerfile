# Flutter web client for PropertyDilaDo mobile UI.
# From monorepo root:
#   docker build -f apps/mobile/Dockerfile -t realestate-mobile \
#     --build-arg API_BASE_URL=http://localhost:3000 apps/mobile

FROM ghcr.io/cirruslabs/flutter:stable AS build
WORKDIR /app

COPY pubspec.yaml pubspec.lock* ./
RUN flutter pub get

COPY . .

ARG API_BASE_URL=http://localhost:3000
ARG FLAVOR=dev

RUN flutter config --enable-web \
  && flutter build web --release \
    --dart-define=FLAVOR=${FLAVOR} \
    --dart-define=API_BASE_URL=${API_BASE_URL}

FROM nginx:1.27-alpine AS runner
COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=build /app/build/web /usr/share/nginx/html
EXPOSE 80
HEALTHCHECK --interval=20s --timeout=5s --retries=5 \
  CMD wget -qO- http://127.0.0.1/ || exit 1
CMD ["nginx", "-g", "daemon off;"]

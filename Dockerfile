FROM ghcr.io/cirruslabs/flutter:stable AS build

WORKDIR /app

COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get

COPY lib ./lib
COPY web ./web
COPY images ./images
COPY analysis_options.yaml ./analysis_options.yaml

ARG SUPABASE_URL
ARG SUPABASE_ANON_KEY

RUN test -n "$SUPABASE_URL" \
    && test -n "$SUPABASE_ANON_KEY" \
    && flutter build web --release --no-web-resources-cdn \
      --dart-define=SUPABASE_URL="$SUPABASE_URL" \
      --dart-define=SUPABASE_ANON_KEY="$SUPABASE_ANON_KEY"

FROM nginx:stable-alpine

COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=build /app/build/web /usr/share/nginx/html

EXPOSE 80

HEALTHCHECK --interval=30s --timeout=3s --start-period=10s --retries=3 \
  CMD wget -q --spider http://127.0.0.1/health || exit 1

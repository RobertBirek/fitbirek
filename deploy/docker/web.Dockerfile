FROM ghcr.io/cirruslabs/flutter:3.35.4@sha256:4ce1a8455a84d39b51a6e013ad9825fab651f881d02d966928aa624695b61022 AS builder
WORKDIR /app
COPY pubspec.yaml pubspec.lock ./
RUN flutter config --no-analytics && flutter pub get --enforce-lockfile
COPY . .
RUN dart tools/generate_app_version.dart --check \
    && dart tools/generate_app_version.dart
RUN dart run build_runner build --delete-conflicting-outputs

FROM builder AS verification
RUN dart tools/generate_app_version.dart --check \
    && flutter analyze && flutter test --reporter expanded

FROM verification AS release
RUN dart tools/generate_app_version.dart --check \
    && flutter build web --release --no-web-resources-cdn \
    && test -s build/web/sqlite3.wasm \
    && test -s build/web/drift_worker.dart.js

FROM nginx:alpine@sha256:2f07d83bf561b506400dc183b1b2003803e39efbd22451f848adaba14d28c7c7 AS runtime
COPY deploy/docker/web-nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=release /app/build/web /usr/share/nginx/html
HEALTHCHECK --interval=30s --timeout=5s --retries=3 CMD wget -q -O /dev/null http://127.0.0.1/healthz || exit 1

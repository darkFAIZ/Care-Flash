FROM dart:stable AS build

WORKDIR /workspace
COPY packages/care_domain/pubspec.yaml packages/care_domain/pubspec.yaml
COPY packages/care_domain/lib packages/care_domain/lib
COPY packages/care_backend/pubspec.yaml packages/care_backend/pubspec.yaml
COPY packages/care_backend/lib packages/care_backend/lib
COPY packages/care_backend/bin packages/care_backend/bin

# Build the backend and its pure-Dart domain package without the Flutter app
# workspace packages in the container image.
RUN sed -i '/^resolution: workspace$/d' \
      packages/care_domain/pubspec.yaml \
      packages/care_backend/pubspec.yaml \
    && cd packages/care_backend \
    && dart pub get \
    && dart compile exe bin/server.dart -o /server

FROM dart:stable AS runtime

RUN mkdir -p /data \
    && chown 65532:65532 /data
COPY --from=build /server /usr/local/bin/care-backend

ENV PORT=8080 \
    HOST=0.0.0.0 \
    CARE_DATA_FILE=/data/care_backend.json
EXPOSE 8080
USER 65532:65532
ENTRYPOINT ["/usr/local/bin/care-backend"]

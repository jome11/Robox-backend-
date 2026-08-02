# Root Dockerfile for Render. Render builds this image directly from
# your GitHub repo (Dashboard > New > Web Service > pick this repo,
# Environment = Docker).
#
# It installs the Dart Frog CLI, runs `dart_frog build` to generate the
# production server entrypoint (build/bin/server.dart), AOT-compiles
# it, then ships a minimal runtime image that just runs the compiled
# binary. Turso is reached over plain HTTPS (see lib/db.dart), so no
# native database libraries are needed here.

FROM dart:stable AS build

WORKDIR /app

# Resolve dependencies first (better Docker layer caching).
COPY pubspec.* ./
RUN dart pub get

# Copy the rest of the source and generate + compile the server.
COPY . .
RUN dart pub get --offline
RUN dart pub global activate dart_frog_cli
ENV PATH="$PATH:/root/.pub-cache/bin"
RUN dart_frog build
RUN dart compile exe build/bin/server.dart -o bin/server

# Minimal runtime image.
FROM scratch
COPY --from=build /runtime/ /
COPY --from=build /app/bin/server /app/bin/

CMD ["/app/bin/server"]

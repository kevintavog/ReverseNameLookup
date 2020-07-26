# ================================
# Build image
# ================================
FROM swift:5.2-bionic as build
WORKDIR /build

COPY ./Package.* ./
RUN swift package resolve

COPY . /code
RUN cd /code && swift build -c release

# ================================
# Run image
# ================================
FROM swift:5.2-bionic-slim
RUN useradd --user-group --create-home --system --skel /dev/null --home-dir /app vapor
WORKDIR /app
COPY --from=build --chown=vapor:vapor /code/.build/release/ReverseNameLookup /app
USER vapor:vapor
EXPOSE 8888
ENTRYPOINT ["/app/ReverseNameLookup"]

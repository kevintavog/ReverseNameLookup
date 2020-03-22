FROM swift:5.1.3 as build

RUN apt-get update; \
    apt-get install -y uuid-dev libcurl4-openssl-dev openssl libssl-dev

COPY . /code

RUN cd /code && swift build -c release
# RUN cd /code && swift build -c release && cp /code/.build/release/ReverseNameLookup /ReverseNameLookup && cd / && rm -Rf /code

FROM swift:5.1.3-slim
COPY --from=build /code/.build/release/ReverseNameLookup /ReverseNameLookup
EXPOSE 8888
ENTRYPOINT ["/ReverseNameLookup"]

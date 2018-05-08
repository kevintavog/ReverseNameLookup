FROM swift:4

RUN apt-get update; \
    apt-get install -y uuid-dev libcurl4-openssl-dev

COPY . /code

RUN cd /code && swift build

EXPOSE 8888
ENTRYPOINT ["/code/.build/debug/ReverseNameLookup"]

FROM swift:4.2.1

RUN apt-get update; \
    apt-get install -y uuid-dev libcurl4-openssl-dev

COPY . /code

RUN cd /code && swift build -c release && cp /code/.build/release/ReverseNameLookup /ReverseNameLookup && cd / && rm -Rf /code

EXPOSE 8888
ENTRYPOINT ["/ReverseNameLookup"]

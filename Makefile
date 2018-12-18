BUILD_ID:=$(shell date +%s)

build:
	swift build

release-build:
	swift build -c release -Xswiftc -static-stdlib

update:
	swift package update

tojupiter: image push

image:
	docker build  . -t docker.rangic:6000/reversenamelookup:${BUILD_ID}

push:
	docker push docker.rangic:6000/reversenamelookup:${BUILD_ID}

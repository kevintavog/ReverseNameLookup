build:
	swift build

release-build:
	swift build -c release -Xswiftc -static-stdlib

update:
	swift package update

image:
	docker build -t reversenamelookup .

push:
	docker save reversenamelookup | bzip2 > reversenamelookup-prod.bz2
	scp reversenamelookup-prod.bz2 docker-compose.yml darkman@jupiter.local:docker/reversenamelookup/
	ssh darkman@jupiter.local "cd docker/reversenamelookup; bzcat reversenamelookup-prod.bz2 | docker load"

deploy:
	ssh darkman@jupiter.local "cd docker/reversenamelookup; docker-compose down; nohup docker-compose up &"

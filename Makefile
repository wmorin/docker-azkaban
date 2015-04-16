.PHONY: all build run

all: build

build:
	docker build -t ${USER}/azkaban .

run:
	docker run -d -p 49443:8443 -i -t ${USER}/azkaban

shell:
	docker run -p 49443:8443 -i -t ${USER}/azkaban /bin/bash
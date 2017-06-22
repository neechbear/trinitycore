
build: /usr/bin/docker /usr/bin/jq
	./build.sh

/usr/bin/docker:
	curl -sSL https://get.docker.com/ | sh

/usr/bin/jq:
	sudo yum install jq || sudo apt-get install jq

clean:
	rm -Rf build artifacts

.PHONY: build clean


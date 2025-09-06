TAG ?= latest  # Use "latest" if no tag is provided
build:
	sudo docker buildx build --push --tag uberchuckie/ollama-intel-gpu:${TAG} .
.PHONY: build

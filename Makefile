SHELL := bash
SRC_DIR=$(shell pwd)
BUILD_DIR=$(SRC_DIR)/build

CONTAINER_DIR=$(BUILD_DIR)/container
IMAGE_MARKER=$(CONTAINER_DIR)/image-built
IMAGE_TAG ?= platform9/support:latest

$(BUILD_DIR):
	mkdir -p $@
	 
$(CONTAINER_DIR):
	mkdir -p $@
	cp Dockerfile $(CONTAINER_DIR)
	cp -a scripts $(CONTAINER_DIR)

cdir: | $(CONTAINER_DIR)

clean:
	rm -rf $(BUILD_DIR)

$(IMAGE_MARKER): | $(CONTAINER_DIR)
	docker build --tag $(IMAGE_TAG) $(CONTAINER_DIR)
	touch $@

image: $(IMAGE_MARKER)

image-clean:
	docker images|tail -n +2|grep platform9/support|awk '{print $$3}' | xargs docker rmi -f || true
	rm -f $(IMAGE_MARKER)

push: $(IMAGE_MARKER)
	docker push $(IMAGE_TAG)

push-then-clean: $(IMAGE_MARKER)
	docker push $(IMAGE_TAG) && \
	docker images|tail -n +2|grep platform9/support|awk '{print $$3}' | xargs docker rmi -f || true && \
	rm -f $(IMAGE_MARKER)


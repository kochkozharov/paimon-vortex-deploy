# Build paimon jars for linux/amd64 using docker.
#
# Vortex .so cross-compiled with cargo-zigbuild (target
# x86_64-unknown-linux-gnu.2.28), Maven-сборка идёт нативно — без qemu.
# Собирать под другие glibc-версии/таргеты можно через build-args:
#   make jars GLIBC_VERSION=2.31
#
# Usage:
#   make jars
#   make clean

GLIBC_VERSION ?= 2.28
RUST_TARGET   ?= x86_64-unknown-linux-gnu
NATIVE_DIR    ?= linux-amd64
OUT_DIR       ?= out/$(NATIVE_DIR)
IMAGE         ?= paimon-builder:$(NATIVE_DIR)-glibc$(GLIBC_VERSION)

.PHONY: help jars clean

help:
	@echo "Targets:"
	@echo "  jars   Build paimon jars (vortex .so cross-compiled for"
	@echo "         $(RUST_TARGET).$(GLIBC_VERSION), resources/native/$(NATIVE_DIR)/)"
	@echo "  clean  Remove out/ directory"
	@echo ""
	@echo "Output layout ($(OUT_DIR)/):"
	@echo "  paimon-flink.jar   shaded paimon-flink-2.2-1.4.0.jar"
	@echo "  vortex-libs/       paimon-vortex-* + paimon-arrow + runtime deps"
	@echo "  hadoop/            flink-shaded-hadoop-2-uber"

jars:
	docker buildx build \
		--target=paimon-builder \
		--load \
		--build-arg GLIBC_VERSION=$(GLIBC_VERSION) \
		--build-arg RUST_TARGET=$(RUST_TARGET) \
		--build-arg NATIVE_DIR=$(NATIVE_DIR) \
		-t $(IMAGE) \
		-f Dockerfile.flink \
		.
	@rm -rf $(OUT_DIR)
	@mkdir -p $(OUT_DIR)
	@cid=$$(docker create $(IMAGE)) && \
		docker cp $$cid:/paimon-flink.jar $(OUT_DIR)/ && \
		docker cp $$cid:/vortex-libs/. $(OUT_DIR)/vortex-libs/ && \
		docker cp $$cid:/hadoop/. $(OUT_DIR)/hadoop/ && \
		docker rm $$cid > /dev/null
	@echo ""
	@echo "Jars exported to $(OUT_DIR)/:"
	@ls -lh $(OUT_DIR)/paimon-flink.jar $(OUT_DIR)/vortex-libs/ $(OUT_DIR)/hadoop/

clean:
	rm -rf out/

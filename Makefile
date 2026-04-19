# Build paimon jars for a target linux platform using docker.
#
# Reuses the paimon-builder stage from Dockerfile.flink, which compiles the
# vortex native library and builds the paimon/vortex/flink jars. The resulting
# artifacts are copied out of the image to $(OUT_DIR).
#
# Usage:
#   make jars                        # linux/amd64 (default)
#   make jars PLATFORM=linux/arm64   # linux/arm64
#   make clean
#
# On macOS, cross-platform builds require buildx + binfmt (bundled with Docker
# Desktop). First-run may install emulators automatically.

PLATFORM     ?= linux/amd64
PLATFORM_TAG := $(subst /,-,$(PLATFORM))
OUT_DIR      ?= out/$(PLATFORM_TAG)
IMAGE        ?= paimon-builder:$(PLATFORM_TAG)

.PHONY: help jars clean

help:
	@echo "Targets:"
	@echo "  jars [PLATFORM=linux/amd64]   Build paimon jars for the given platform"
	@echo "  clean                         Remove out/ directory"
	@echo ""
	@echo "Output layout ($(OUT_DIR)/):"
	@echo "  paimon-flink.jar              shaded paimon-flink-2.2-1.4.0.jar"
	@echo "  vortex-libs/                  paimon-vortex-* + paimon-arrow + runtime deps"
	@echo "  hadoop/                       flink-shaded-hadoop-2-uber"

jars:
	docker buildx build \
		--platform=$(PLATFORM) \
		--target=paimon-builder \
		--load \
		-t $(IMAGE) \
		-f Dockerfile.flink \
		.
	@rm -rf $(OUT_DIR)
	@mkdir -p $(OUT_DIR)
	@cid=$$(docker create --platform=$(PLATFORM) $(IMAGE)) && \
		docker cp $$cid:/paimon-flink.jar $(OUT_DIR)/ && \
		docker cp $$cid:/vortex-libs/. $(OUT_DIR)/vortex-libs/ && \
		docker cp $$cid:/hadoop/. $(OUT_DIR)/hadoop/ && \
		docker rm $$cid > /dev/null
	@echo ""
	@echo "Jars exported to $(OUT_DIR)/:"
	@ls -lh $(OUT_DIR)/paimon-flink.jar $(OUT_DIR)/vortex-libs/ $(OUT_DIR)/hadoop/

clean:
	rm -rf out/

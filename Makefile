# Build paimon jars via docker. Two workflows:
#
# 1. `make jars` — build for Linux amd64 (кластер). Vortex .so
#    кросс-компилится через cargo-zigbuild на хосте any arch.
#
# 2. `docker compose up` — локальная разработка. Использует
#    native host arch (на ARM mac = linux/arm64), flink-образ
#    тоже подтянется arm64.
#
# Кастомизация (только для jars-таргета):
#   make jars PLATFORM=linux/arm64    # собрать jar-ы под arm64
#   make jars GLIBC_VERSION=2.31

PLATFORM      ?= linux/amd64
GLIBC_VERSION ?= 2.28
PLATFORM_TAG   = $(subst /,-,$(PLATFORM))
NATIVE_DIR     = $(if $(findstring amd64,$(PLATFORM)),linux-amd64,linux-aarch64)
OUT_DIR       ?= out/$(NATIVE_DIR)
IMAGE         ?= paimon-builder:$(PLATFORM_TAG)-glibc$(GLIBC_VERSION)

.PHONY: help jars clean compose-up compose-down

help:
	@echo "Targets:"
	@echo "  jars [PLATFORM=linux/amd64]  Build paimon jars (default platform linux/amd64)."
	@echo "  compose-up                   docker compose up для локального flink-кластера (host arch)."
	@echo "  compose-down                 Сносит docker-compose стек."
	@echo "  clean                        Remove out/ directory."
	@echo ""
	@echo "Current settings:"
	@echo "  PLATFORM       $(PLATFORM)"
	@echo "  NATIVE_DIR     $(NATIVE_DIR)"
	@echo "  GLIBC_VERSION  $(GLIBC_VERSION)"
	@echo ""
	@echo "Output layout ($(OUT_DIR)/):"
	@echo "  paimon-flink.jar   shaded paimon-flink-2.2-1.4.0.jar"
	@echo "  vortex-libs/       paimon-vortex-* + paimon-arrow + runtime deps"
	@echo "  hadoop/            flink-shaded-hadoop-2-uber"

jars:
	docker buildx build \
		--platform=$(PLATFORM) \
		--target=paimon-builder \
		--load \
		--build-arg GLIBC_VERSION=$(GLIBC_VERSION) \
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

compose-up:
	docker compose up -d --build

compose-down:
	docker compose down -v

clean:
	rm -rf out/

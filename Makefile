# Short name: Short name, following [a-zA-Z_], used all over the place.
# Some uses for short name:
# - Container image name
# - Kubernetes service, rc, pod, secret, volume names
SHORT_NAME := valkey
DRYCC_REGISTRY ?= ${DEV_REGISTRY}
IMAGE_PREFIX ?= drycc
PLATFORM ?= linux/amd64,linux/arm64

include versioning.mk

SHELL_SCRIPTS = $(wildcard _scripts/*.sh) rootfs/bin/boot

# The following variables describe the containerized development environment
# and other build options
DEV_ENV_IMAGE := ${DEV_REGISTRY}/drycc/go-dev
DEV_ENV_WORK_DIR := /opt/drycc/go/src/${REPO_PATH}
DEV_ENV_CMD := podman run --rm -v ${CURDIR}:${DEV_ENV_WORK_DIR} -w ${DEV_ENV_WORK_DIR} ${DEV_ENV_IMAGE}
DEV_ENV_CMD_INT := podman run -it --rm -v ${CURDIR}:${DEV_ENV_WORK_DIR} -w ${DEV_ENV_WORK_DIR} ${DEV_ENV_IMAGE}

all: podman-build podman-push

dev:
	${DEV_ENV_CMD_INT} bash

# For cases where we're building from local
# We also alter the RC file to set the image name.
podman-build:
	podman build --build-arg CODENAME=${CODENAME} -t ${IMAGE} rootfs
	podman tag ${IMAGE} ${MUTABLE_IMAGE}

test: podman-build test-style
	./_test/test.sh ${VERSION}

test-style:
	${DEV_ENV_CMD} shellcheck $(SHELL_SCRIPTS)

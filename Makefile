COMPOSE ?= docker compose
GO_IMAGE := golang:1.27.3-bookworm
GOLANGCI_IMAGE := golangci/golangci-lint:v2.15.0
PKG ?= ./...

GO_RUN = docker run --rm \
	--volume "$(CURDIR):/workspace" \
	--workdir /workspace \
	--volume dtp-go-build-cache:/root/.cache/go-build \
	--volume dtp-go-mod-cache:/go/pkg/mod \
	--env CGO_ENABLED=0 \
	--env GOTOOLCHAIN=local \
	$(GO_IMAGE)

GOLANGCI_RUN = docker run --rm \
	--volume "$(CURDIR):/workspace" \
	--workdir /workspace \
	--volume dtp-go-build-cache:/root/.cache/go-build \
	--volume dtp-go-mod-cache:/go/pkg/mod \
	--volume dtp-golangci-cache:/root/.cache/golangci-lint \
	--env CGO_ENABLED=0 \
	$(GOLANGCI_IMAGE)

.PHONY: up down logs ps build fmt lint test reset

up:
	$(COMPOSE) up --detach --wait postgres redis

down:
	$(COMPOSE) down --remove-orphans

logs:
	$(COMPOSE) logs --follow postgres redis

ps:
	$(COMPOSE) ps

build:
	$(GO_RUN) go build -trimpath -ldflags="-s -w" ./cmd/...

fmt:
	$(GOLANGCI_RUN) golangci-lint fmt

lint:
	$(GOLANGCI_RUN) golangci-lint run ./...

test:
	$(GO_RUN) go test $(PKG)

reset:
	$(COMPOSE) down --volumes --remove-orphans
	rm -rf data/storage

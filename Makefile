# Variables
REGISTRY = harbor.hahomelabs.com
REPO = mycritters/convex-backend
TAG = $(shell if [ -f image-tag ]; then cat image-tag; else date +%Y%m%d | tee image-tag; fi)
IMAGE_NAME = $(REGISTRY)/$(REPO):$(TAG)
PLATFORM = linux/amd64

# Cargo profiles
CARGO_FLAGS = --release
DEV_FLAGS = 
TEST_FLAGS = --workspace

# Default target
.DEFAULT_GOAL := help

.PHONY: help build test lint check fmt clean run-local run-dashboard reset new-tag \
		push dev login docker-build docker-push docker-run convex rush install \
		clippy bench doc update

help: ## Show this help message
	@echo "Available targets:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  \\033[36m%-15s\\033[0m %s\\n", $$1, $$2}'

# Development targets
build: ## Build all crates in release mode
	cargo build $(CARGO_FLAGS)

dev-build: ## Build all crates in dev mode
	cargo build $(DEV_FLAGS)

test: ## Run all tests
	cargo test $(TEST_FLAGS)

test-dev: ## Run tests in dev mode
	cargo test $(TEST_FLAGS) $(DEV_FLAGS)

lint: clippy fmt-check ## Run all linting (clippy + format check)

clippy: ## Run clippy linter
	cargo clippy --workspace --all-targets --all-features -- -D warnings

fmt: ## Format code
	cargo fmt --all

fmt-check: ## Check code formatting
	cargo fmt --all -- --check

check: ## Run cargo check
	cargo check --workspace --all-targets --all-features

bench: ## Run benchmarks
	cargo bench

doc: ## Generate documentation
	cargo doc --no-deps --workspace

clean: ## Clean build artifacts
	cargo clean
	rm -f image-tag

# Local development
run-local: ## Run local backend server
	just run-local-backend

run-dashboard: ## Run dashboard (requires URL argument)
	just run-dashboard

reset: ## Reset local backend data
	just reset-local-backend

# JavaScript/Rush targets  
rush: ## Run rush command (e.g., make rush ARGS="build")
	just rush $(ARGS)

install: ## Install JavaScript dependencies
	just rush install

update: ## Update JavaScript dependencies  
	just rush update

# Docker targets
docker-build: ## Build Docker image
	docker build -t $(IMAGE_NAME) . --platform=$(PLATFORM)

docker-push: docker-build ## Build and push Docker image
	docker push $(IMAGE_NAME)

docker-run: ## Run Docker container locally
	docker run -it --rm \
		--name convex-backend-test \
		-p 3210:3210 \
		-v $(PWD):/workspace \
		$(IMAGE_NAME) /bin/bash

login: ## Login to Harbor registry
	@echo "Logging into Harbor registry..."
	@docker login $(REGISTRY)

# Utility targets
new-tag: ## Generate new timestamp tag
	rm -f image-tag
	@date +%Y%m%d | tee image-tag
	@echo "New tag: $$(cat image-tag)"

dev: dev-build test-dev ## Quick development cycle (build + test in dev mode)

all: build test lint ## Build, test, and lint everything

# Alternative Docker tags
docker-build-dev: ## Build Docker image with dev tag
	docker build -t $(REGISTRY)/$(REPO):dev . --platform=$(PLATFORM)

docker-push-dev: docker-build-dev ## Build and push dev tag
	docker push $(REGISTRY)/$(REPO):dev

# Convex CLI wrapper (for local development)
convex: ## Run convex CLI against local backend (usage: make convex ARGS="dev")
	just convex $(ARGS)
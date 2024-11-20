export GO111MODULE=on
export PATH:=/usr/local/go/bin:$(PATH)
exec_path := /usr/local/bin/
exec_name := docker-machine-driver-otccce

VERSION := 0.0.12


default: test build
test: vet acceptance

fmt:
	@echo Running go fmt
	@go fmt

lint:
	@echo Running go lint
	@golangci-lint run

vet:
	@echo "go vet ."
	@go vet $$(go list ./... | grep -v vendor/) ; if [ $$? -eq 1 ]; then \
		echo ""; \
		echo "Vet found suspicious constructs. Please check the reported constructs"; \
		echo "and fix them if necessary before submitting the code for review."; \
		exit 1; \
	fi

acceptance:
	@echo "Starting acceptance tests..."
	@go test -race -timeout 40m -v github.com/wolfslicht/rancher-node-engine-driver-sotc/opentelekomcloud

build: build-linux

build-linux:
	@echo "Build driver for Linux"
	@go build --trimpath -o bin/$(exec_name)

build-windows:
	@echo "Build driver for Windows"
	@GOOS=windows go build --trimpath -o bin/$(exec_name).exe

build-all: build-linux

install:
	@cp ./bin/$(exec_name) $(exec_path)
	@echo "Driver installed to $(exec_path)$(exec_name)"

release: build-all
	@tar -czf "./bin/$(exec_name)-$(VERSION)-linux-amd64.tgz" "./bin/$(exec_name)" && rm "./bin/$(exec_name)"
	@echo "Release versions are built"

goreleaser-release:
	@if [ -z "$(GITHUB_TOKEN)" ]; then echo "GITHUB_TOKEN is not set"; exit 1; fi
	@if [ -z "$(GPG_FINGERPRINT)" ]; then echo "GPG_FINGERPRINT is not set"; exit 1; fi
	goreleaser release --rm-dist

goreleaser-snapshot:
	goreleaser release --snapshot --rm-dist --skip-publish
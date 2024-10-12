.PHONY:v1
v1: ## 推送v1标签
	@if [ "$$(git rev-parse --abbrev-ref HEAD)" != "main" ]; then \
		echo "Error: You can only run this target on the main branch."; \
		exit 1; \
	fi
	git tag -d v1 || true
	git push origin :refs/tags/v1 || true
	git tag	v1
	git push origin v1

.PHONY:dev
dev: ## 推送dev标签
	git tag -d dev || true
	git tag	dev -m "developer testing"
	git push origin dev --force

.PHONY:help
.DEFAULT_GOAL:=help
help:
	@grep -E '^[a-zA-Z0-9_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'
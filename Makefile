# <PROJECT_NAME> — helper targets.
#
# 본 Makefile 은 하네스 템플릿이 제공하는 최소 타겟만 둔다.
# 프로젝트별 빌드/테스트 타겟 (build, test, e2e 등) 은 채택 시 추가한다.

.PHONY: help setup-githooks

help:  ## 사용 가능한 타겟 목록
	@grep -E "^[a-zA-Z_-]+:.*?## " $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  %-20s %s\n", $$1, $$2}'

setup-githooks:  ## .githooks/ 를 git core.hooksPath 로 등록 (clone 후 1회 실행)
	@bash scripts/setup-githooks.sh

# === 채택 시 추가 ===
# build:
# 	cd codebase/backend && npm run build
# 	cd codebase/frontend && npm run build
#
# lint:
# 	cd codebase/backend && npm run lint
# 	cd codebase/frontend && npm run lint
#
# test:
# 	cd codebase/backend && npm test
# 	cd codebase/frontend && npm test
#
# e2e-test:
# 	docker compose -f docker-compose.e2e.yml up --build --abort-on-container-exit

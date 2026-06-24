# PROJECT.md — `<PROJECT_NAME>` 프로젝트별 매핑·명령

> **본 파일은 채택 시점에 프로젝트에 맞춰 채워야 합니다.** placeholder (`<...>`) 를 모두 실제 값으로 치환하세요.
>
> 본 저장소의 프로젝트-특이 매핑·명령. `.claude/` 하네스는 generic 화되어 있으므로, 이 저장소에서의 코드베이스 구조, 빌드·테스트 명령, 문서 컨벤션은 본 문서에서 한 곳에 모은다.
>
> 다른 저장소에서 본 하네스를 채택할 때는 본 파일만 자기 프로젝트에 맞게 작성하면 된다. 하네스의 generic skeleton (`developer/SKILL.md`, `ai-review.md`, `code-review-agents/SKILL.md`, push/stop review·plan 가드) 은 본 파일을 참조해 동작한다.

---

## 코드베이스 구조

> 어떤 폴더에 어떤 스택이 들어가는지. `.claude.project.json` 의 `code_areas` 와 정합해야 한다.

| 영역 | 위치 | 스택 |
|------|------|------|
| 클라이언트 | `<path/to/frontend>` | `<Next.js / React / Vue / ...>` |
| 서버 | `<path/to/backend>` | `<NestJS / Express / Django / ...>` |
| 공유 패키지 | `<path/to/packages/...>` | `<TypeScript / ...>` |
| 인프라 매니페스트 | `<k8s/ 또는 terraform/ 등>` | `<Kubernetes / Terraform / ...>` |
| 빌드 helper | `<예: scripts/>` | `<예: Python 검증 스크립트, setup-githooks.sh>` |

패키지 매니저: `<npm / yarn / pnpm — 하나만 선택>`.
인프라: `<PostgreSQL / Redis / S3 / ... — 사용하는 외부 의존>`.

---

## 빌드·린트·테스트 명령

> TEST WORKFLOW 의 lint → unit → build → e2e 4단계 **각 단계의 즉시 실행 가능한 명령**. 추상화 (`<your-test-command>`) 가 아니라 그대로 복붙해서 돌아가는 형태로. 실제 실행은 `.claude/test-stages.sh` 의 `cmd_lint`/`cmd_unit`/`cmd_build`/`cmd_e2e` 함수가 담당하며, 본 표와 1:1 일치해야 한다.

| 단계 | wrapper 한 줄 호출 | 내부에서 실행되는 명령 (멀티-stack 이면 **양쪽 의무**) |
|------|--------------------|------------------------------------------------------|
| lint | `.claude/tools/run-test.sh lint` | `<예: cd codebase/backend && npm run lint>` **그리고** `<예: cd codebase/frontend && npm run lint>` |
| unit test (in-process) | `.claude/tools/run-test.sh unit` | `<예: cd codebase/backend && npm test>` **그리고** `<예: cd codebase/frontend && npm test>` |
| build | `.claude/tools/run-test.sh build` | `<예: cd codebase/backend && npm run build>` **그리고** `<예: cd codebase/frontend && npm run build>` |
| e2e (실 인프라) | `.claude/tools/run-test.sh e2e` | `<예: make e2e-test>` |
| e2e (확장 시나리오, 선택) | — | `<예: make e2e-test-full>` |
| e2e 인프라 정리 (중간 종료 시) | — | `<예: make e2e-down>` |
| e2e stale project 일괄 정리 (worktree 삭제 후) | — | `<예: make e2e-prune>` |
| git hook 등록 (clone 후 1회) | — | `make setup-githooks` |

**순서 근거**: lint(수 초) → unit(수십 초) → build(분) → e2e(분 이상). 비싼 단계 앞에 싼 단계를 두어 docker 빌드 비용 낭비를 회피.

**Cross-stack 의무 — 한쪽 누락 금지**: 멀티-stack 프로젝트 (예: backend + frontend) 에서는 lint / unit / build 단계의 wrapper 호출이 `.claude/test-stages.sh` 안에서 양쪽 stack 을 **순차 AND** 로 실행한다 (한쪽 실패 시 즉시 단계 실패). **반드시 wrapper 를 통해 호출** — `<예: cd codebase/backend && npm run build>` 같은 단일 stack 직호출로 단계를 "통과" 처리하면 다른 한쪽 회귀가 검출되지 않는다. wrapper 가 한 단계 = 양쪽 stack 묶음이라는 invariant 의 유일한 enforcer.

**Worktree 별 e2e 자동 격리** (선택 사항 — 권장): `<예: make e2e-*>` 가 현재 worktree dir basename 으로 compose project name 을 도출하면 컨테이너·볼륨·network 가 worktree 별로 자동 분리된다. 여러 worktree 에서 e2e 를 **동시에** 돌려도 충돌 없음. image 자체는 worktree 간 공유되도록 (각 빌드 서비스에 `image:` 명시) 두 번째 worktree 의 첫 e2e 가 image rebuild 비용을 다시 치르지 않게 한다. `<예: COMPOSE_PROJECT=foo make e2e-test>` 로 사용자 override 허용. 운영 정책은 [`CLAUDE.md` §0 작업 시작 전](CLAUDE.md) 참고.

---

## 버전·도구 정책

> (선택 — 멀티 스택·멀티 패키지 프로젝트일 때 채택) 테스트 프레임워크·버전 핀·런타임 floor 같은 도구 정책을 한 곳에 모은다. sub-agent (dependency-reviewer 등) 와 developer 가 참조.

- **테스트 프레임워크 정책**: `<예: backend·내부 packages = jest / frontend = vitest. 신규 패키지는 소속 스택의 기본값을 따른다 — run-test.sh wrapper 가 양쪽을 한 단계로 운용>`
- **버전 핀 정책**: `<예: 기본 caret(^) — lock 파일이 재현성 SoT. exact·tilde 핀은 사유 주석 필수>`
- **런타임 floor**: `<예: 내부 앱 engines.node >=NN (운영·CI 와 정렬), 외부 배포 SDK 는 호환폭 보존 위해 별도 floor>`

---

## e2e 실행 원칙

코드가 한 줄이라도 바뀌었으면 **e2e 수행이 default**. 면제는 §e2e 면제 화이트리스트 의 부분집합 조건만 인정한다. 자가 판단·후속 단계 떠넘기기·"변경이 작아서" 는 모두 면제 사유가 아니다.

본 절은 자주 발생한 회피 패턴과 실행 사전 점검을 명시한다. 면제 대상 식별 규칙은 §e2e 면제 화이트리스트, 실제 명령은 §빌드·린트·테스트 명령, 작성 패턴은 §e2e 테스트 작성 가이드 참고.

### 회피 안티패턴

다음 사유는 자동(`resolution-applier`) · 수동 흐름 모두에서 회피로 분류된다. RESOLUTION.md 의 `e2e` 줄에 적어도 그 자체가 차단 신호가 된다:

- **"단위·integration 으로 충분"** — e2e 는 docker compose 의 실 인프라 (`<예: Postgres·Redis·오브젝트 스토리지·마이그레이션·큐>`) 회귀 안전망이다. unit 으로 절대 검출 못 함
- **"변경이 frontend 만 / backend 만"** — cross-stack 회귀 검출 자체가 e2e 의 본 목적
- **"사용자 가시 동작에 영향 없어 보임"** — 자가 영향 추정은 면제 사유 아님. 영향 추정은 변경자가 아닌 실 인프라가 결정
- **"lint·unit·build 통과했으니 후속 단계(`/ai-review` 등) 가 처리할 것"** — 후속 단계도 동일 wrapper 를 호출한다. 떠넘긴다고 사라지지 않으며, push 가드(`guard_review_before_push.py`)가 미리뷰 branch 의 push 를 차단한다
- **"review 반영 직후 fix 가 1~2 줄"** — 코드 변경이면 변경량 무관 재수행. 마지막 코드 commit 다음에 e2e 통과 줄이 없으면 회피로 본다
- **"docker 가 느려서 다음 turn 에"** — 가용성을 실제 확인하지 않은 보류 금지. 미루기 전에 `docker info` 로 daemon 가용성 먼저 확인

> `[skip-e2e]` 자체 발급 절대 금지. 자동 흐름은 `resolution-applier` sub-agent 가 wrapper 호출을 강제하며, 수동 흐름이라도 `.claude/skills/developer/SKILL.md §RESOLUTION.md schema` 의 e2e 줄 4형식 (통과 / 면제 (화이트리스트 인용) / 보류 (사용자 응답 인용) / 자동 흐름 환경 차단) 외 어떤 표현도 차단된다.

### 실행 사전 체크리스트

매 turn TEST WORKFLOW 진입 시 순서대로 자가 점검:

1. `git status --short` 로 **변경 set 확인** — `.md` · `spec/` · `plan/` 만으로 보였어도 코드 파일 (`<예: codebase/>`) 이 한 줄이라도 끼었는지 재확인
2. 변경 set 이 §e2e 면제 화이트리스트 의 **부분집합** 인가? 화이트리스트 밖이 한 줄이라도 있으면 실행
3. `docker info` 로 daemon 가용성 확인 — 없으면 자동 흐름은 "자동 흐름 환경 차단", 수동 흐름은 사용자 보고 후 응답 인용
4. 이전 turn 의 stale 컨테이너가 있다면 `<예: make e2e-down>` (worktree 격리되어 있으나 충돌 시 명시 정리)
5. `.claude/tools/run-test.sh e2e` 호출 — raw `<예: make e2e-test>` 직호출 금지 (main ctx 폭주)
6. 실패 시 wrapper stdout 의 마지막 30 줄로 원인 분석 → fix → TEST WORKFLOW **1단계부터** 재실행

> "이미 통과했으니 다시 안 돌려도 된다" 는 검증 시점과 commit 시점의 불일치를 만들 뿐. **마지막 코드 commit 다음에 e2e 통과 줄이 있어야 한다.**

### 자주 누락되는 turn 패턴

- 한 줄짜리 핫픽스 ("typo", "변수명 한 글자") — 짧은 변경이 곧 짧은 e2e 가 아님. 실 인프라 회귀 가능성은 변경량 무관
- "spec·plan 만 손댔다" 인데 실은 코드 파일 한 줄이 같이 간 경우 — 1번 체크 누락
- review 이슈 fix 완료 직후 — review 가 코드 수정을 동반했으면 다시 e2e
- 이미 e2e 가 통과한 직후의 추가 작은 fix — fix 도 코드면 다시 e2e
- merge·rebase 후 본인 변경이 아닌 줄이 섞여 들어왔을 때 — 변경 set 의 *전체* 가 화이트리스트 부분집합인지 재판정

---

## e2e 면제 화이트리스트

> 코드 변경이 한 줄이라도 있으면 e2e 는 default 로 수행. **변경 set 이 다음 목록의 부분집합** 일 때에 한해 e2e 면제. **임의 확대 금지** — 추가가 필요하면 본 문서를 PR 로 갱신.

- `*.md` · `*.mdx` 본문 (frontmatter 포함)
- `spec/**` · `plan/**` · `review/**` · `CLAUDE.md` · `README.md` · `PROJECT.md`
- `.claude/**` (skills, hooks, agents 정의)
- `<path/to/docs/사용자 가이드>` (변경 후 e2e 가 검출하지 못하는 영역)
- `<path/to/i18n/dict>` (사전 키만; 호출 코드 변경 없음)
- 주석 전용 변경 (코드 라인 0줄, 주석/공백/포맷만)
- `.github/**` (CI 정의는 e2e 가 검증 대상 아님)
- 이미지·로고·폰트 등 정적 자산

위 목록 밖이 한 항목이라도 포함되면 면제 불가. 회색 지대(예: `*.test.ts` 만 변경, configuration JSON, helper 한 줄) 도 화이트리스트가 아니므로 e2e 수행.

### 화이트리스트 밖인데 보류가 정당한 경우 — 사용자 명시 승인 필수

- 사전 결함이 e2e 를 막고 있고 본 변경과 무관함이 명확 (commit hash 로 입증 가능)
- 외부 third-party API stub 인프라 부재 등 구조적 한계
- 환경상 docker 실행 불가 (디스크/메모리/daemon)

이 경우에도 **`[skip-e2e]` 자체 발급 금지**. 멈추고 사용자 보고 → 명시 응답 받은 뒤에만 보류. `RESOLUTION.md` `## TEST 결과` 에 사유 + 응답 시점 인용 기록.

---

## 변경 유형 → 갱신 위치 매핑

> 코드 변경 후 함께 갱신해야 할 문서·번역·schema 자산. 누락 시 사후 보정 PR 패턴을 차단하기 위한 white list. 검증 명령을 함께 명시.
>
> **본 표는 [`.claude/config/doc-sync-matrix.json`](.claude/config/doc-sync-matrix.json) 의 사람이 읽는 짝이다.** 두 표현은 **행 수가 1:1** 이어야 하며 ([`test_doc_sync_matrix.py`](.claude/tests/test_doc_sync_matrix.py) 가 검증), 행 추가·삭제 시 둘을 **같은 PR 안에서** 갱신한다. 아래는 placeholder 8행 — 프로젝트 실 변경 유형으로 교체하되 JSON 과 같은 행 수를 유지한다.

| 변경 유형 | 필수 갱신 위치 | 검증 명령 |
| --- | --- | --- |
| `<예: 신규 UI 문자열>` | `<예: src/i18n/{ko,en}.ts 양쪽 — parity 가드 fail>` | `<예: npm test -- i18n>` |
| `<예: DB 스키마 변경>` | `<예: migration + entity + repository + e2e>` | `<예: make e2e-test>` |
| `<예: API 추가·변경>` | `<예: controller + DTO + swagger jsdoc + 관련 user-guide>` | `<예: npm run test:swagger>` |
| `<예: 신규 backend 에러/경고 코드 발행>` | `<예: frontend 의 에러 코드 → 사용자 가시 메시지 매핑 테이블>` | `<예: npm test -- backend-labels>` |
| `<예: 신규 cross-cutting enum 값 추가>` | `<예: (a) registry 컨벤션 매트릭스 행 추가 (b) 모든 분기 위치 동시 갱신 (assertNever) (c) AST exhaustiveness 가드 통과>` | `<예: npm test -- enum-exhaustiveness>` |
| `<예: spec 신규/대규모 변경>` | `<예: frontmatter (status/code:/pending_plans:) 정합 갱신, status=partial 이면 후속 plan 신설>` | `<예: npm test -- spec-frontmatter>` |
| `<예: 환경 변수·기동 방법 변경>` | `README.md` | 수동 |
| spec 자체에 누락·오류가 있다고 판단됨 | `plan/in-progress/spec-update-<name>.md` 에 제안 노트 작성 후 `project-planner` 위임 | — |

### 사후 보정 PR 패턴 금지 — 같은 turn 원칙

문서·번역·schema 갱신은 코드 변경과 **같은 PR · 같은 turn · 같은 단계 commit** 안에서 끝낸다. 별 commit/PR 로 분리되는 `fix(i18n):` · `fix(docs):` · `docs(<area>):` 패턴은 다음 이유로 금지:

- 코드 머지와 가이드 머지 사이에 *사용자 가시 동작은 바뀌었는데 가이드는 안 바뀐 기간* 이 생긴다
- 코드 PR 의 reviewer 가 사용자 가시 영향까지 보지 못한 채 머지된다
- 사후 보정 commit 이 plan·spec 추적에서 단절된다
- git history 상 사용자 가시 변경의 정확한 commit 이 흩어진다

> developer workflow 의 **§4 DOCUMENTATION** 단계는 §5–7 (테스트 선작성·구현) **직전** 에 끝낸다. 단계 종료 후의 `fix(i18n):` · `fix(docs):` 별 commit 은 *그 시점 발견 누락의 신호* 이지 정상 워크플로가 아니다. 같은 변경 set 의 동반 갱신 누락은 `user-guide-sync-reviewer` 가 `/ai-review` 에서 매트릭스 기반으로 검출한다.

#### 자주 누락되는 항목 (git history 기반 — 채택 시 실측 사례로 보강)

`<프로젝트별로 사후 보정 commit 으로 반복해 잡힌 패턴을 채택 시 채운다. 대표적 카테고리:>`

- **i18n key parity** — dict 신규 키 `ko` / `en` 한쪽 누락. build-time 가드가 잡지만 *추가하는 같은 commit 안* 양쪽 동시 추가가 default
- **backend warning/error code → 로케일 매핑** — 백엔드가 새 코드를 발행하면 frontend 매핑을 같은 commit 에. 누락 시 사용자에게 영문(또는 raw code) 그대로 노출
- **schema 변경 vs 가이드 본문** — dict 키만 갱신하고 가이드 본문 (필드 표·예시) 미갱신
- **cross-cutting enum 값 추가 vs N개 분기 위치** — 새 enum 값을 한 곳에 추가하고 N개 처리 분기 중 일부를 빠뜨림. `assertNever` exhaustive switch + AST 가드가 동시 동작해야 차단됨
- **API 추가 vs swagger jsdoc 누락** — controller·DTO 의 swagger jsdoc 동반 필수
- **spec frontmatter `code:` 글로브 stale** — 영역 일부 경로만 명시하고 cross-stack 경로 누락. `partial`/`implemented` 시점 가드 fail
- **`status: partial` 의 `pending_plans:` 미작성** — 미구현 surface 가 어떤 plan 에도 책임지지 않은 채 영구 누락. 본 PR 머지 전 후속 plan 신설 의무

#### DOCUMENTATION 단계 종료 사전 체크리스트

developer workflow §4 종료 직전, 5단계로 진행하기 전 자가 점검:

- [ ] 변경 set 의 각 파일에 대해 위 표의 "변경 유형" 매칭이 모두 식별됐는가? 회색 지대는 보수적으로 "갱신 필요" 로 분류
- [ ] 표가 가리키는 모든 위치를 **동일 turn 안에** 갱신했는가? 한 위치라도 별 turn 으로 미루지 않았는가
- [ ] 표의 "검증 명령" 을 실제로 실행했는가?
- [ ] 사용자 가시면 (UI 라벨·에러 메시지·가이드 본문) 이 코드 변경의 의미를 정확히 반영하는가? 단순 동기화가 아닌 *의미 갱신*
- [ ] 본 turn 안에서 spec 자체에 변경이 필요한 것을 발견했으면 `plan/in-progress/spec-update-<name>.md` 작성 후 `project-planner` 위임 (developer 가 spec 직접 수정 금지)
- [ ] **partial-implementation 분리** — 본 PR 이 구현하는 spec 섹션의 *나머지 surface* 가 있다면 `plan/in-progress/<spec-name>-followup-<surface>.md` 가 신설/갱신됐는가? 본 spec 의 frontmatter `pending_plans:` 가 해당 plan 을 가리키는가? spec `status:` 가 `partial` 로 정확히 설정됐는가?

> 한 항목이라도 미충족이면 §5 (테스트 선작성) 로 진행하지 말고 §4 안에서 마무리. `fix(i18n):` · `fix(docs):` commit 빈도가 워크플로 건강 지표 — 본 PR/turn 안에서 0건이 default.

### 유저 가이드 파일 컨벤션 (선택 — 프로젝트가 in-repo 사용자 가이드를 유지할 때)

> 사용자 가이드/문서를 저장소 안에 가지고 있고, `user-guide-writer` sub-agent 로 작성·갱신을 위임한다면 본 절을 프로젝트에 맞게 채운다. 위임 전 `.claude.project.json` 의 `agents.writers.user_guide` 가 enabled 여야 한다.

#### SoT 문서 인덱스 (user-guide-writer 가 매 호출 적재)

`<path/to/user-guide/**>` 의 신규 작성·기존 갱신은 [`user-guide-writer`](.claude/agents/user-guide-writer.md) sub-agent 가 담당한다. 본 sub-agent 의 **첫 행동** 은 아래 SoT 문서들을 Read 하여 컨벤션을 컨텍스트에 적재하는 것이다.

| 문서 | 역할 |
|---|---|
| `PROJECT.md` (본 절) | SoT 문서 인덱스 + 자주 누락 패턴 + 동반 갱신 매트릭스 |
| `<예: spec/<area>/user-guide.md>` | IA · 라우트 · 프론트매터 스키마 · 섹션 순서 · 딥링크 규약 · 공용 MDX 컴포넌트 · 품질 체크 |
| `<예: spec/conventions/i18n-userguide.md>` | i18n 원칙 (TSX 하드코딩 금지·로케일 parity·backend-labels 매핑·sibling 규약·글로서리) |
| `<예: spec/conventions/spec-impl-evidence.md>` | spec frontmatter (`status` 값·`code:` 글로브·`pending_plans:`) 와 build-time 가드 SoT |
| `<예: spec/conventions/user-guide-evidence.md>` | 가이드 본문 ↔ 실제 UI 진입점 매핑 컴포넌트 + reverse-coverage 가드 SoT |

#### 파일 구조 요약

- canonical 로케일: `<slug>.mdx` — frontmatter 는 여기에만
- 번역 sibling: `<slug>.<locale>.mdx` — frontmatter 없이 본문만. 없으면 해당 로케일은 canonical + 안내 배너로 폴백 (의도된 동작)

#### user-guide-writer 자가 검증 체크리스트 (배포 전)

`<프로젝트별 SoT 문서의 N항목 + 자주 누락 패턴을 합한 체크리스트로 확장. 일반 항목 예시:>`

- [ ] 프론트매터의 `spec:` / `code:` 경로가 실제로 존재하는가 (Glob)
- [ ] 글로서리 금지어가 본문에 등장하지 않는가
- [ ] 내부 docs 링크의 slug 가 실존하는가
- [ ] in-app 라우트가 코드스팬 대신 링크로 작성됐는가 (의도된 코드스팬 예외 처리됨)
- [ ] 로케일 sibling 변경 set 의 파일 쌍 대응이 맞는가
- [ ] **GUI 흐름 절** 에 실 UI 진입점 매핑 컴포넌트가 동반 작성됐는가? `file`/`symbol` 이 코드에 실존하는가?

### i18n dict 파일 컨벤션 (선택 — i18n dict 를 섹션별로 split 할 때)

`<프로젝트가 i18n dict 를 단일 거대 파일이 아닌 섹션별 split 으로 유지한다면 채택 시 채운다. 일반적으로 다음을 명시:>`

- N 개 top-level 섹션은 각각 `dict/<locale>/<section>.ts` 의 쌍 (예: `dict/ko/editor.ts`, `dict/en/editor.ts`). 단일 거대 파일이 아닌 섹션 단위 split 으로 병렬 PR 충돌을 최소화
- 신규 키 추가 시 모든 로케일의 같은 섹션 파일만 손댄다. 다른 섹션 파일과는 무관
- `dict/<locale>/index.ts` 는 composite export — 신규 섹션 추가가 아닌 한 일반적으로 손대지 않음

### 자동 가드 (build-time 차단)

> 위 표의 검증 명령은 가능한 한 결정적 단위 테스트로 받아두는 것을 권장. 채택 시 본 절에 실제 테스트 파일 경로를 등록. (이 경로들이 위 매트릭스의 `guard_tests` 및 `doc-sync-matrix.json` 과 정합해야 한다.)

`<프로젝트별로 실제로 두고 있는 build-time 가드 목록을 명시. 카테고리 예시:>`

- `<예: i18n parity test — ko ↔ en leaf key 강제>`
- `<예: backend-labels 매핑 가드 — 새 warning/error code 매핑 누락 fail>`
- `<예: spec frontmatter 의무 가드 — id/status 등 필드 강제>`
- `<예: spec code: 글로브 ≥1 매치 가드 — partial/implemented 상태에서>`
- `<예: spec pending_plans: 실존 가드 — spec → plan 역방향 링크>`
- `<예: enum exhaustiveness AST 가드 — 새 enum 값의 모든 분기 처리 강제>`
- `<예: migration version monotonic check>`

이들은 코드 리뷰가 검출하지 못한 누락도 빌드 단계에서 차단한다. 위반의 invariant 자체는 `spec/conventions/<name>.md` 에 정식 등록되어 `convention-compliance-checker` 가 sub-agent 단에서도 점검한다.

---

## e2e 테스트 작성 가이드

> e2e 는 **인프라 의존성과 multi-actor 흐름** 을 보장하는 회귀 안전망. unit · integration 으로 이미 보호되는 단일 핸들러 로직은 침범하지 않는다.

### 언제 e2e 를 작성하는가

- 멀티 액터 · 동시성 · 트랜잭션 일관성 (race condition, 트랜잭션 격리)
- 권한 경계 (RBAC, workspace 격리, 토큰 만료)
- 실 인프라 의존 (`<DB / 캐시 / 큐 / 오브젝트 스토리지 / 마이그레이션 등>`)
- 다단계 흐름 (가입 → 인증 → 로그인 → … cross-endpoint 시나리오)
- 외부 인입 (webhook 수신, OAuth callback)

### 파일 위치·명명

- backend: `<예: codebase/backend/test/<scope>.e2e-spec.ts>` — `<예: jest-e2e.json 의 .e2e-spec.ts$ regex 자동 discovery>`
- frontend: `<예: codebase/frontend/e2e/<area>/<name>.spec.ts>` — `<예: playwright.config.ts 의 testMatch>`
- 신규 헬퍼: `<예: codebase/backend/test/helpers/<name>.ts>`

### Backend e2e 패턴 (선택 — supertest 등)

`<프로젝트별 backend e2e 패턴 — DB 클라이언트, 인증 helper, 응답 shape 규칙, cookie 추출 등을 채택 시 채운다. 일반적 항목:>`

- DB 직접 접근 헬퍼 (`<예: helpers/db.ts 의 createDbClient()>`)
- 인증 setup 헬퍼 (`<예: helpers/auth.ts 의 registerAndLogin·createTeamWorkspace>`)
- 응답 shape 규칙 (`<예: 인터셉터가 객체를 body.data.<field> 로 감싸고, 페이지네이션 DTO 는 passthrough>`)
- 워크스페이스/테넌트 컨텍스트 헤더 명시 규약

### Frontend e2e 패턴 (선택 — playwright 등)

`<프로젝트별 frontend e2e 패턴을 채택 시 채운다. 일반적 항목:>`

- backend 와 분리 — `<예: page.route('**/api/...', ...) 로 mock>`. 실 backend 호출은 backend e2e 가 책임
- 인증 진입 페이지가 호출하는 endpoint 를 함께 mock
- 다국어 i18n 매칭 패턴

### 알려진 우회 (백엔드/프론트 quirk)

`<프로젝트별 알려진 quirk·우회 패턴을 채택 시 채운다. 예시:>`

- `<예: 초대 가입 사용자의 JWT 가 personal workspace 부재로 401 → 헬퍼가 DB INSERT 로 fast-track>`
- `<예: invite 엔드포인트 throttle (60s 당 N건) → backoff 재시도 후 DB 직접 추가 fallback>`

### 금지·주의

- `<예: LLM 호출 흐름 — e2e 대상 아님. unit 위임>`
- `<예: 단일 거대 e2e-spec 무한 누적 금지 — 영역별 파일로 분할>`
- `<예: jest maxWorkers: 1 유지 — 병렬 suite 가 throttle·DB 격리에 지장>`
- `<예: e2e 에서 DB row 강제 생성 시 unique 식별자 사용 — 정리는 ephemeral schema 가 자동 처리>`

---

## 보조 스크립트 (검증·운영)

> (선택) 하네스의 TEST WORKFLOW 밖에 있지만 프로젝트가 자주 돌리는 검증·운영 스크립트를 한 곳에 모은다. sub-agent 가 짧은 prompt 만 받아도 존재를 알도록.

### 문서 링크 검증 (예시)

`<예: spec/ 내부 링크와 docs frontmatter spec: 정합성 확인>`

```bash
<예: python3 scripts/check-doc-links.py>
```

- 종료 코드: 깨진 항목이 있으면 `1`, 모두 정상이면 `0`
- `<의존성·검사 항목·실행 시점을 채택 시 기술>`

### 운영 스크립트 (예시)

`<예: 앱을 부팅하지 않고 단발성 도구만 실행하는 스크립트들 (큐 정리·백필 등). 실행 명령·dry-run/apply 절차를 채택 시 채운다.>`

---

## 도메인 어휘

> sub-agent 가 짧은 prompt 만 받아도 맥락을 잃지 않도록, 프로젝트 핵심 어휘·규약을 한 곳에 모은다.

- **`<핵심 도메인 개념 1>`**: `<설명>`
- **`<핵심 도메인 개념 2>`**: `<설명>`
- **`<핵심 도메인 개념 3>`**: `<설명>`
- **인프라 의존**: `<DB / 캐시 / 큐 / ... — 실제 사용하는 외부 의존>`
- **`spec/conventions/`**: 정식 규약 모음 — `<프로젝트별 규약 파일 목록>`

---

## 작성 체크리스트 (placeholder 모두 채웠는지)

- [ ] 코드베이스 구조 표의 모든 `<...>` 치환
- [ ] 빌드·린트·테스트 명령 4단계 실제 명령 명시 (멀티-stack 이면 양쪽 의무 행 채움) + `.claude/test-stages.sh` 의 4개 함수와 1:1 일치
- [ ] (해당 시) 버전·도구 정책 § 작성
- [ ] e2e 실행 원칙의 회피 안티패턴·사전 체크리스트가 프로젝트 실 인프라명으로 구체화
- [ ] e2e 면제 화이트리스트 프로젝트별로 좁게 검토
- [ ] 변경 유형 매핑 표를 프로젝트 실 변경 유형으로 교체하고 **`.claude/config/doc-sync-matrix.json` 과 행 수 1:1** 정합 (`test_doc_sync_matrix.py` 통과)
- [ ] 사후 보정 PR 패턴 §의 "자주 누락되는 항목" 을 git history 실측 사례로 보강
- [ ] (해당 시) 유저 가이드 파일 컨벤션 §의 SoT 문서 인덱스 작성 + `.claude.project.json` 의 `agents.writers.user_guide` 토글 확인
- [ ] (해당 시) i18n dict 컨벤션 § 작성
- [ ] 자동 가드 § 에 실제 테스트 파일 경로 등록 (매트릭스 `guard_tests` 와 정합)
- [ ] e2e 작성 가이드의 파일 위치·헬퍼·금지사항 채움
- [ ] (해당 시) 보조 스크립트 § 작성
- [ ] 도메인 어휘 핵심 개념 3-5개 등록
- [ ] 본 체크리스트와 상단 안내 문구 삭제 (placeholder 모두 채운 뒤)

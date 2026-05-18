# PROJECT.md — `<PROJECT_NAME>` 프로젝트별 매핑·명령

> **본 파일은 채택 시점에 프로젝트에 맞춰 채워야 합니다.** placeholder (`<...>`) 를 모두 실제 값으로 치환하세요.
>
> 본 저장소의 프로젝트-특이 매핑·명령. `.claude/` 하네스는 generic 화되어 있으므로, 이 저장소에서의 코드베이스 구조, 빌드·테스트 명령, 문서 컨벤션은 본 문서에서 한 곳에 모은다.
>
> 다른 저장소에서 본 하네스를 채택할 때는 본 파일만 자기 프로젝트에 맞게 작성하면 된다. 하네스의 generic skeleton (`developer/SKILL.md`, `ai-review.md`, `code-review-agents/SKILL.md`) 은 본 파일을 참조해 동작한다.

---

## 코드베이스 구조

> 어떤 폴더에 어떤 스택이 들어가는지. `.claude.project.json` 의 `code_areas` 와 정합해야 한다.

| 영역 | 위치 | 스택 |
|------|------|------|
| 클라이언트 | `<path/to/frontend>` | `<Next.js / React / Vue / ...>` |
| 서버 | `<path/to/backend>` | `<NestJS / Express / Django / ...>` |
| 공유 패키지 | `<path/to/packages/...>` | `<TypeScript / ...>` |
| 인프라 매니페스트 | `<k8s/ 또는 terraform/ 등>` | `<Kubernetes / Terraform / ...>` |

패키지 매니저: `<npm / yarn / pnpm — 하나만 선택>`.
인프라: `<PostgreSQL / Redis / S3 / ... — 사용하는 외부 의존>`.

---

## 빌드·린트·테스트 명령

> TEST WORKFLOW 의 lint → unit → build → e2e 4단계 **각 단계의 즉시 실행 가능한 명령**. 추상화 (`<your-test-command>`) 가 아니라 그대로 복붙해서 돌아가는 형태로.

| 단계 | 명령 |
|------|------|
| lint | `<예: cd codebase/backend && npm run lint>` |
| unit test (in-process) | `<예: cd codebase/backend && npm test>` |
| build | `<예: cd codebase/backend && npm run build>` |
| e2e (실 인프라) | `<예: make e2e-test>` |
| e2e 인프라 정리 (중간 종료 시) | `<예: make e2e-down>` |
| git hook 등록 (clone 후 1회) | `make setup-githooks` |

**순서 근거**: lint(수 초) → unit(수십 초) → build(분) → e2e(분 이상). 비싼 단계 앞에 싼 단계를 두어 docker 빌드 비용 낭비를 회피.

**Worktree 별 e2e 자동 격리** (선택 사항 — 권장): `make e2e-*` 가 현재 worktree dir basename 으로 compose project name 을 도출하면 컨테이너·볼륨·network 가 worktree 별로 자동 분리된다. 여러 worktree 에서 e2e 를 **동시에** 돌려도 충돌 없음.

---

## e2e 면제 화이트리스트

> 코드 변경이 한 줄이라도 있으면 e2e 는 default 로 수행. **변경 set 이 다음 목록의 부분집합** 일 때에 한해 e2e 면제. **임의 확대 금지** — 추가가 필요하면 본 문서를 PR 로 갱신.

- `*.md` · `*.mdx` 본문 (frontmatter 포함)
- `spec/**` · `plan/**` · `review/**` · `CLAUDE.md` · `README.md` · `PROJECT.md`
- `.claude/**` (skills, hooks, agents 정의)
- `<path/to/docs/사용자 가이드>` (변경 후 e2e 가 검출하지 못하는 영역)
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

| 변경 유형 | 필수 갱신 위치 | 검증 명령 |
| --- | --- | --- |
| `<예: 새 API endpoint 추가>` | `<예: controller + DTO + swagger jsdoc + e2e>` | `<예: npm run test:swagger>` |
| `<예: 신규 UI 문자열>` | `<예: src/i18n/{ko,en}.ts 양쪽 — parity 가드 fail>` | `<예: npm test -- i18n>` |
| `<예: DB 스키마 변경>` | `<예: migration + entity + repository + e2e>` | `<예: make e2e-test>` |
| `<예: 인증/권한 흐름 변경>` | `<예: 가이드 문서 + e2e>` | `<예: make e2e-test>` |
| `<예: 환경 변수·기동 방법 변경>` | `<README.md>` | 수동 |
| spec 자체에 누락·오류가 있다고 판단됨 | `plan/in-progress/spec-update-<name>.md` 에 제안 노트 작성 후 `project-planner` 위임 | — |

### 자동 가드 (build-time 차단)

위 표의 검증 명령은 가능한 한 결정적 단위 테스트로 받아두는 것을 권장:

- `<예: i18n parity test — ko ↔ en leaf key 강제>`
- `<예: migration version monotonic check>`
- `<예: swagger schema validation>`

이들은 코드 리뷰가 검출하지 못한 누락도 빌드 단계에서 차단한다.

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

- backend: `<예: codebase/backend/test/<scope>.e2e-spec.ts>`
- frontend: `<예: codebase/frontend/e2e/<area>/<name>.spec.ts>`
- 신규 헬퍼: `<예: codebase/backend/test/helpers/<name>.ts>`

### 패턴 / 헬퍼 / 알려진 우회

`<프로젝트별 e2e 패턴 — DB 클라이언트, 인증 helper, 응답 shape 규칙, cookie 추출, route mock, 알려진 backend quirk 등을 채택 시 채운다.>`

### 금지·주의

- `<예: LLM 호출 흐름 — e2e 대상 아님. unit 위임>`
- `<예: 단일 거대 e2e-spec 무한 누적 금지 — 영역별 파일로 분할>`
- `<예: jest maxWorkers: 1 유지 — 병렬 suite 가 throttle·DB 격리에 지장>`

---

## 도메인 어휘

> sub-agent 가 짧은 prompt 만 받아도 맥락을 잃지 않도록, 프로젝트 핵심 어휘·규약을 한 곳에 모은다.

- **`<핵심 도메인 개념 1>`**: `<설명>`
- **`<핵심 도메인 개념 2>`**: `<설명>`
- **인프라 의존**: `<DB / 캐시 / 큐 / ... — 실제 사용하는 외부 의존>`
- **`spec/conventions/`**: 정식 규약 모음 — `<프로젝트별 규약 파일 목록>`

---

## 작성 체크리스트 (placeholder 모두 채웠는지)

- [ ] 코드베이스 구조 표의 모든 `<...>` 치환
- [ ] 빌드·린트·테스트 명령 4단계 실제 명령 명시
- [ ] e2e 면제 화이트리스트 프로젝트별로 좁게 검토
- [ ] 변경 유형 매핑 최소 3-5개 추가 (i18n, schema, swagger 등)
- [ ] e2e 작성 가이드의 파일 위치·헬퍼·금지사항 채움
- [ ] 도메인 어휘 핵심 개념 3-5개 등록
- [ ] 본 체크리스트와 상단 안내 문구 삭제 (placeholder 모두 채운 뒤)

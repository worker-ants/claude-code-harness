# Claude Code Harness — 증류 저장소

`clemvion` 프로젝트에서 검증된 **Claude Code 하네스**(SDD + TDD + AI 코드 리뷰 자동화 + 다중 PR 통합)를, 어느 저장소에서나 복사·채택할 수 있는 **프로젝트-중립 스켈레톤**으로 증류해 보관하는 저장소입니다.

증류본은 두 가지입니다 — **`v2/` (현재 권장본)** 와 **`v1/` (레거시)**. 채택하려면 한쪽 디렉토리를 통째로 대상 저장소에 복사한 뒤, 프로젝트별 파일(`PROJECT.md` · `.claude/test-stages.sh` 등)만 채우면 됩니다. 하네스의 상세 구조·채택 절차는 각 버전 하위 문서가 단일 진실(SSOT)이며, 본 문서는 **둘의 비교와 선택 안내**만 다룹니다.

---

## 어떤 하네스인가 — 사용 모델

> 이 절은 **v1·v2 모든 버전에 공통**입니다 — 어떤 증류본을 쓰든 작업 방식은 같습니다.

이 하네스는 "이 버그 고쳐줘" · "X API 추가해줘" 같은 **직접 task 지시형이 아닙니다.** 기획 → 개발 → QA 에 이르는 **전체 개발 파이프라인**을 자동화하며, 대화하는 유저는 **고객(클라이언트)** 의 컨셉에 가깝습니다.

고객은 원하는 것을 **모호하게** 알고 있을 뿐, 정확한 그림을 들고 오지 않습니다. 어시스턴트와 대화하며 점점 구체화하고, 만족할 만큼 구체화되어 **고객이 spec 을 승인하면, 그 이후는 어시스턴트가 끝까지 책임지고 완주**합니다. **spec 승인이 "함께 다듬기 → 위임" 의 분기점**입니다.

### 전형적인 대화 흐름 (예: 주문 프로세스에 쿠폰 기능 추가)

1. **모호한 요구 제기**
   > "주문 프로세스에 쿠폰 기능을 추가하고 싶어. 주로 사용되는 방식과 추천하는 방안을 제안해줘."

   어시스턴트는 가능한 방식·권장안·근거를 정리해 제시하고, 목적·제약을 되물으며 요구사항을 구체화합니다. *(아직 코드도 spec 도 건드리지 않습니다.)*

2. **여러 턴의 대화로 방향성 합의** — 정률/정액·중복 사용·만료·재고 연동 같은 결정을 주고받으며 윤곽이 잡힙니다.

3. **spec 초안 작성** — 유저가 *"이 방향으로 spec 작성해줘"* 라고 하거나, 어시스턴트가 *"이 정도면 spec 초안을 써도 될까요?"* 라고 제안합니다.

4. **검토 · 승인** — 어시스턴트가 *"검토하시고, 이대로 진행할지 / 바꿀 점이 있는지 알려주세요"* 라고 묻고, 추가 대화로 spec 을 다듬습니다.

5. **plan 생성 · 구현 착수** — spec 이 승인되면 plan 을 만들고 구현에 들어갑니다. 이때부터 worktree·TDD·TEST·리뷰는 **유저가 신경 쓰지 않아도** 하네스가 자동으로 굴립니다.

6. **(선택) 백로그 운영** — plan 에 티켓이 쌓이면 유저가 특정 티켓을 지정하거나, *"다음에 처리할 티켓을 추천해줘"* 라고 맡깁니다.

### 핵심 — 직접 지시가 아니라 위임

- 유저가 의식적으로 하는 것은 ① (모호해도) 원하는 바 말하기 ② 질문에 답하며 구체화 ③ **spec 승인** ④ 결과(PR) 검토 정도입니다. worktree·`--impl-prep`·TDD 같은 내부 단계 이름은 외울 필요가 없습니다 — 잊으면 hook 이 안내·차단합니다.
- 방향이 이미 명확하면 *"바로 spec 작성해줘"* 로 건너뛰거나, 단순 질의(*"이 함수 어떻게 동작해?"*)는 worktree 없이 바로 답변받을 수도 있습니다.

> 승인 이후 내부에서 무엇이 도는지(worktree·TDD·리뷰·e2e·다중 통합)는 각 버전의 OVERVIEW(예: [`v2/OVERVIEW.md`](v2/OVERVIEW.md))와 README 의 "내부 동작 흐름" 절을 참고하세요.

---

## 저장소 구성

```text
./
├── v2/          # 현재 권장본 — clemvion 현재 하네스의 증류 (README.md · OVERVIEW.md 포함)
├── v1/          # 레거시 — 초기 증류본 (더 단순, 일부 기능 미포함)
└── LICENSE.md   # MIT
```

> `temp/` · `.claude/` · `.idea/` 는 작업용이라 형상관리(git) 대상이 아닙니다.

---

## v1 vs v2 한눈에

| 항목 | v1 (레거시) | v2 (현재 권장) |
| --- | --- | --- |
| 성격 | 초기 증류본 | clemvion **현재** 하네스의 증류 |
| Worktree enforcement | 4-layer (편집 차단 · prompt/bash 안내 · git pre-commit) | 동일 + 아래 강화 |
| **review/plan push·stop 가드** | ✗ | ✓ — 미리뷰·plan 미갱신 시 `git push` 차단 + turn-종료 nudge |
| **네이티브 `Workflow` tool 경로** | ✗ (Agent fan-out 만) | ✓ — `.claude/workflows/*.js` 3종 |
| **하네스 self-test** | ✗ | ✓ — `.claude/tests/` 13종 (표준 라이브러리만) |
| **변경-유형 매트릭스** | prose (`PROJECT.md` 표) | + machine-readable SSOT (`doc-sync-matrix.json`) + 바인딩 test |
| **SessionStart 부트스트랩** | ✗ (수동 `make setup-githooks`) | ✓ — hooksPath·deps·state GC·머지 worktree 회수 자동 |
| 브랜치 정규화 · mermaid 린트 | ✗ | ✓ (`worktree-*`→`claude/*`, md mermaid 검사) |
| hooks / tools 수 | 3 / 4 | 7 / 7 |
| sub-agent 세트 | 동일 (31 파일) | 동일 — v2 는 user-guide-sync reviewer 의 매트릭스 연동까지 반영 |
| 상대 복잡도 · 토큰비용 | 낮음 | 높음 |
| 권장 용도 | 가벼운 채택 · 단순 레퍼런스 | 규모·장기 프로젝트 · 강한 보장 |

---

## v1 → v2 무엇이 추가됐나

- **review/plan push·stop 가드** — "리뷰/fix 를 다음 턴·PR 로 미루기" 를 hook 으로 차단 (`git push` 직전 hard gate + turn-종료 soft nudge).
- **네이티브 `Workflow` tool 경로** — 아래 단락 참고.
- **하네스 self-test 스위트** — 가드·브랜치 정규화·orchestrator 상태기계·매트릭스 정합을 `python3 -m unittest` 로 회귀 보호.
- **변경-유형 매트릭스의 machine-readable SSOT** — `doc-sync-matrix.json` + `PROJECT.md` 표를 self-test 가 1:1 로 묶어 silent drift 차단.
- **SessionStart 부트스트랩** — `core.hooksPath`·mermaid deps·state GC·머지된 worktree 회수를 세션 시작 시 자동 (채택·운영 마찰 감소).
- **브랜치 정규화 · mermaid 린트 · worktree 자동 회수** — 운영 편의 가드 추가.

### v2 와 Claude Code의 `Workflow` 기능

v2 의 두드러진 특징은 Claude Code 의 네이티브 **`Workflow` tool** 을 활용한다는 점입니다. `.claude/workflows/{ai-review, consistency-check, merge-coordinate}.js` 스크립트가 *router → 병렬 reviewer fan-out → summary 수렴* 을 **결정적(deterministic) 으로 오케스트레이션**해, v1 에서 main Claude 가 직접 굴리던 **수작업 STATUS 파싱·재시도 상태기계를 대체**합니다.

핵심은 요금 정책 호환입니다 — Workflow 의 `agent()` 호출은 `claude -p`·Anthropic SDK 직접 호출과 달리 **플랜 토큰에 포함(plan-metered)** 되므로, "외부 LLM 호출 금지" 규약을 어기지 않으면서 fan-out/pipeline 을 스크립트로 제어할 수 있습니다. 다만 코드를 편집·커밋하는 side-effecting 자동 후속(`resolution-applier`)과 `/loop` 한도 재시도는 여전히 bespoke 경로로 남습니다.

> 한 줄 요약: **v1 = `Agent` tool 평문 fan-out / v2 = `Agent` + `Workflow` 두 경로** (둘 다 plan-metered).

---

## 트레이드오프 · 어느 것을 쓸까

| 버전 | 장점 | 단점 | 적합한 상황 |
| --- | --- | --- | --- |
| **v1 (레거시)** | 가볍고 이해·채택이 쉬움 · 무버 파츠 적음 · 토큰비용 낮음 | 리뷰/fix 를 미뤄도 막지 못함 · 자가검증·매트릭스 바인딩 없음 · 수동 셋업 · 구버전 머신러리 | 가벼운 채택 · 단순 레퍼런스 · 가드 오버헤드를 줄이고 싶은 소규모 작업 |
| **v2 (권장)** | push 게이트로 리뷰·plan 강제 · 하네스 자가검증 · Workflow 경로 · 매트릭스 1:1 바인딩 · 최신 | 무겁고 학습곡선 가파름 · 토큰비용↑ · 설정할 게 더 많음 · 일부 기능(유저가이드·spec-coverage)은 도메인 맞춤 필요 | 규모 있는·장기 프로젝트 · 잘못된 구현 반복을 막는 강한 보장이 필요할 때 |

**선택 가이드**: 특별한 이유가 없으면 **v2** 를 권장합니다 — "한 번의 비용은 높지만 반복을 줄여 최종 비용이 낮다" 는 하네스의 설계 철학에 맞습니다. v1 은 가드 오버헤드가 부담스럽거나, 더 단순한 형태를 레퍼런스로 보고 싶을 때 선택합니다. (v1 의 핵심 가드는 v2 에 모두 포함되므로 나중에 v2 로 옮겨가기 쉽습니다.)

---

## 시작하기

| 목적 | v2 (권장) | v1 (레거시) |
| --- | --- | --- |
| 채택 단계·트러블슈팅 | [`v2/README.md`](v2/README.md) | [`v1/README.md`](v1/README.md) |
| 전체 구조·강점/약점·라이프사이클 | [`v2/OVERVIEW.md`](v2/OVERVIEW.md) | [`v1/OVERVIEW.md`](v1/OVERVIEW.md) |

대상 저장소에 `v2/.claude` · `v2/.githooks` · `v2/scripts` · `v2/CLAUDE.md` · `v2/PROJECT.md` 등을 복사한 뒤, `v2/README.md` 의 초기 세팅 단계를 따라가면 됩니다.

---

## 라이선스

MIT — [`LICENSE.md`](LICENSE.md). 본 하네스는 Clemvion 프로젝트에서 추출한 generic skeleton 이며, 자유롭게 수정·재배포할 수 있습니다.

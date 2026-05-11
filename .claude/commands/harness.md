# Command: harness

큰 작업을 Mithm task harness 형식으로 분해하거나, 기존 `phases/` 작업을 이어서 수행할 때 사용한다.

## 읽을 문서

1. `CLAUDE.md`
2. `docs/agent/task-harness.md`
3. `docs/agent/working-rules.md`
4. 작업 내용에 따라 `docs/agent/architecture.md`, `docs/agent/critical-flows.md`, `docs/agent/product-context.md`
5. 수정 대상 영역의 `CLAUDE.md`

## 원칙

- 작은 작업은 `phases/`를 만들지 않는다.
- 큰 작업만 `phases/<task-name>/`로 나눈다.
- 각 step은 독립 실행 가능해야 한다.
- 각 step은 구현 전 테스트 또는 검증 기준을 반드시 포함한다.
- 실기기 의존 흐름은 자동 테스트 대신 구체적인 수동 체크리스트를 먼저 작성할 수 있다.
- 병렬 가능 여부는 `docs/agent/task-harness.md`의 기준을 따른다.

## 완료 조건

- step 상태가 최신이다.
- Red/Green/Refactor/Verify 기록이 남아 있다.
- 루트와 영역별 `AGENTS.md` / `CLAUDE.md` 동일성이 유지된다.

# Mithm Task Harness

이 문서는 큰 작업을 작게 나누는 방법을 정한다. 작은 작업은 `phases/` 없이 바로 처리한다.

## 언제 사용하나

다음에 해당하면 harness step으로 쪼갠다.

- 여러 계층을 동시에 바꾸는 작업
- HealthKit/EventKit/refresh/예측 흐름을 건드리는 작업
- 테스트 추가와 구현이 여러 파일에 걸치는 작업
- 병렬 가능 여부를 명확히 판단해야 하는 작업
- 한 세션에서 끝내기 어려운 작업

## 디렉터리 구조

```text
phases/
  index.json
  <task-name>/
    index.json
    step0.md
    step1.md
```

`phases/index.json` 예시:

```json
{
  "phases": [
    { "dir": "example-task", "status": "pending" }
  ]
}
```

`phases/<task-name>/index.json` 예시:

```json
{
  "project": "Mithm",
  "phase": "example-task",
  "steps": [
    { "step": 0, "name": "domain-contract", "status": "pending" },
    { "step": 1, "name": "presentation-flow", "status": "pending" }
  ]
}
```

상태는 `pending`, `completed`, `error`, `blocked`만 사용한다.

## Step 작성 원칙

- 각 step은 독립 세션에서도 실행 가능해야 한다.
- "이전 대화 참고" 같은 표현을 쓰지 않는다.
- 읽어야 할 문서와 수정 범위를 명시한다.
- 먼저 작성할 테스트 또는 검증 기준이 없는 step은 유효하지 않다.
- Acceptance Criteria는 실행 가능해야 한다.
- 구현 지시는 의도와 계약 중심으로 쓰고, 불필요한 세부 구현을 과하게 고정하지 않는다.

## Step 템플릿

```markdown
# Step N: <name>

## 읽어야 할 문서
- `AGENTS.md`
- `docs/agent/<필요 문서>.md`
- `<수정 영역>/AGENTS.md`

## 작업 목표
이 step 하나가 달성해야 할 결과를 적는다.

## 수정 범위
- 허용 파일 또는 디렉터리
- 건드리지 않을 파일 또는 디렉터리

## 먼저 작성할 테스트 또는 검증 기준
- 테스트 파일과 추가할 케이스
- 또는 실기기/화면 검증 체크리스트

## Red 확인 방법
구현 전 실패를 확인하는 명령이나 절차를 적는다.

## 구현 지시
변경할 동작, 인터페이스, 데이터 흐름을 적는다.

## 금지사항
이 step에서 하면 안 되는 일을 적는다.

## Green 확인 방법
구현 후 통과해야 하는 명령이나 절차를 적는다.

## Refactor 기준
동작 유지 상태에서 정리 가능한 범위를 적는다.

## 완료 시 상태 업데이트
`phases/<task-name>/index.json`의 step status를 `completed`로 바꾸고, 실패하면 `error` 또는 `blocked`로 바꾼다.
```

## 병렬 가능 조건

모두 만족할 때만 병렬 작업을 허용한다.

- 서로 다른 파일을 수정한다.
- 서로 다른 상태 흐름을 건드린다.
- 같은 DI 그래프 연결을 동시에 바꾸지 않는다.
- 같은 HealthKit/EventKit 흐름을 동시에 바꾸지 않는다.
- 같은 테스트 파일을 동시에 수정하지 않는다.

## 병렬 금지 영역

아래 파일이나 흐름은 직렬로 처리한다.

- `AppState`
- `AppDIContainer`
- `MenstrualPredictionEngine`
- `CurrentMenstrualStatusResolver`
- `OpenPeriodAutoCloser`
- `HealthKitRepositoryImpl`
- HealthKit/EventKit DataStore
- `.xcodeproj`, entitlement, `Info.plist`

## 완료 기준

- 모든 step의 테스트 또는 검증 기준이 먼저 작성됐다.
- 각 step이 Green 확인을 통과했다.
- 필요한 refactor가 끝났다.
- `phases/<task-name>/index.json` 상태가 최신이다.
- 루트와 영역별 `AGENTS.md` / `CLAUDE.md` 동일성이 유지된다.

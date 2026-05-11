# Mithm Working Rules

이 문서는 작업 절차와 검증 원칙을 정한다. 코드 변경 전에는 관련 영역 가이드와 함께 읽는다.

## 시작 순서

1. 루트 `AGENTS.md` 또는 `CLAUDE.md`를 읽는다.
2. 작업 유형에 맞는 `docs/agent/` 문서를 읽는다.
3. 수정 대상 영역의 `AGENTS.md` 또는 `CLAUDE.md`를 읽는다.
4. 관련 코드와 테스트를 먼저 탐색한다.
5. 테스트 또는 검증 기준을 먼저 작성한다.
6. 최소 구현 후 검증한다.

## TDD 원칙

코드 변경은 TDD-first로 진행한다.

- Red: 실패하는 테스트 또는 검증 기준을 먼저 작성한다.
- Green: 테스트/검증을 통과하는 최소 구현을 한다.
- Refactor: 동작을 유지하며 구조를 정리한다.
- Verify: 실행한 테스트, 빌드, 수동 체크 결과를 기록한다.

테스트 가능한 로직은 반드시 Swift Testing 테스트를 먼저 작성한다. 실기기 의존 흐름은 테스트 코드 대신 검증 가능한 절차와 기대 결과를 먼저 문서화할 수 있다.

## 변경 유형별 기준

- Domain 로직 변경: 단위 테스트를 먼저 추가하거나 수정한다.
- Data Mapper/Repository 계약 변경: 가능한 범위에서 단위 테스트를 먼저 작성한다.
- Core HealthKit/EventKit 호출 변경: 자동화 가능한 계약은 테스트하고, 권한/실제 시스템 반영은 수동 체크리스트를 먼저 작성한다.
- Presentation 상태/ViewModel 변경: 상태 변환 로직은 테스트 우선, 순수 UI 스타일 변경은 화면 검증 기준 우선.
- 문서 전용 변경: 문서 동일성, 링크, 금지 키워드, 경로 존재 여부를 검증한다.

## 실기기 검증 예외

다음은 자동 테스트 필수 대신 검증 프로세스 선작성을 허용한다.

- HealthKit 권한 요청
- Apple Health 앱에 실제 월경 기록 반영
- Apple Health에서 기록 수정/삭제 후 앱 refresh 확인
- EventKit 권한 요청
- 실제 캘린더 이벤트 생성/수정/삭제

실기기 체크리스트에는 기기 조건, 사전 데이터 상태, 실행 순서, 기대 결과, 실패 시 확인할 화면이나 로그를 포함한다.

## 빌드와 테스트

시뮬레이터 이름을 가정하지 않는다. 실행 전에 설치된 iPhone 시뮬레이터를 확인한다.

```bash
xcrun simctl list devices available | rg "iPhone"
```

빌드:

```bash
xcodebuild build \
  -project Mithm/Mithm.xcodeproj -scheme Mithm \
  -destination 'platform=iOS Simulator,name=<설치된 iPhone 시뮬레이터 이름>'
```

전체 테스트:

```bash
xcodebuild test \
  -project Mithm/Mithm.xcodeproj -scheme Mithm \
  -destination 'platform=iOS Simulator,name=<설치된 iPhone 시뮬레이터 이름>'
```

Xcode MCP가 사용 가능하면 셸 명령보다 우선 사용한다.

1. Xcode에서 `Mithm/Mithm.xcodeproj`가 열린 상태인지 확인한다.
2. 활성 scheme이 `Mithm`이고 destination이 설치된 iPhone 시뮬레이터인지 확인한다.
3. 빌드는 `BuildProject`를 실행한다.
4. 전체 테스트는 `RunAllTests`를 실행한다.
5. 일부 테스트는 `GetTestList`로 테스트 식별자를 확인한 뒤 `RunSomeTests`를 실행한다.
6. 실패 원인은 `GetBuildLog`로 확인한다.
7. SwiftUI Preview 확인이 필요한 Presentation 변경은 `RenderPreview`를 사용할 수 있다.

Xcode MCP를 사용할 수 없거나 Xcode 탭, scheme, destination 상태를 확신할 수 없으면 위의 `xcodebuild` 명령으로 검증한다.

## 위험 작업

아래 영역은 작은 변경이어도 관련 문서를 더 읽고 직렬로 처리한다.

- `AppState`
- `AppDIContainer`
- `MenstrualPredictionEngine`
- `CurrentMenstrualStatusResolver`
- `OpenPeriodAutoCloser`
- `HealthKitRepositoryImpl`
- HealthKit/EventKit DataStore
- `.xcodeproj`, entitlement, `Info.plist`

## 완료 전 확인

- `AGENTS.md`와 `CLAUDE.md`가 동일한지 확인한다.
- 영역별 `AGENTS.md`와 `CLAUDE.md`가 동일한지 확인한다.
- TDD 또는 검증 기준이 먼저 있었는지 확인한다.
- 실행한 테스트/빌드/수동 체크를 결과와 함께 남긴다.

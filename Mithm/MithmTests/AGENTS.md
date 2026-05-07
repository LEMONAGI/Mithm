# MithmTests 작업 가이드

> 이 가이드는 에이전트가 이 영역에서 코드를 건드리기 전에 반드시 알아야 할 컨텍스트를 담는다.
> 코드만 읽어선 알 수 없는 의도/함정/배경이 핵심이다.

## 1. WHAT — 이 모듈은 무엇을 하는가

Swift Testing(`@Test` 매크로) 기반 단위 테스트 타겟이다. 비즈니스 로직(예측 엔진, Phase 판정, UseCase 오케스트레이션)의 정확성을 자동 검증한다. UI 테스트는 없으며 수동 시뮬레이터 검증으로 대체한다. 계산 회귀가 사용자에게 직접 영향을 주기 때문에 비즈니스 로직 변경 시 반드시 이 계층을 통과해야 한다.

## 2. CONTENTS — 파일/디렉토리와 기술 스택

- `MithmTests.swift` — 예측 엔진 80+케이스 (record 필터링/검증, 표본화, 이상치 가중치, variability 분류, EWMA, blend 로직, 신뢰도 산정)
- `HomePhaseUseCaseTests.swift` — Phase window 계산 (진행 중 월경, 예측 record 제외, 배란기 포함, gap 기반 follicular/luteal, fallback)
- `MaintainabilityRefactorTests.swift` — 월경 시작/종료 UseCase, refresh 오케스트레이션, stale `CurrentMenstrualEpisode` 정리, 자동 종료 흐름

기술 스택: Swift Testing (`@Test`, `#expect`), Swift

## 3. HOW — 일반적인 수정은 어떻게 하는가

- **새 테스트 추가**: `@Test` 매크로 사용. 파일은 테스트 대상 UseCase/Helper와 대응되게 이름 지정
- **날짜 조작**: `TestCalendar` / `HomePhaseTestCalendar` 헬퍼로 결정론적 날짜 생성. `Date()` 직접 사용 금지 (테스트 날짜에 따라 결과가 달라짐)
- **record 생성**: `makeRecord(...)` 팩토리 함수 사용. 직접 `MenstrualRecord(...)` 생성자를 쓰면 필수 필드 누락 위험
- **단일 테스트 실행**: 
  ```bash
  xcodebuild test -project Mithm/Mithm.xcodeproj -scheme Mithm \
    -destination 'platform=iOS Simulator,name=iPhone 16' \
    -only-testing:MithmTests/MithmTests/<테스트함수명>
  ```

## 4. ⛔ HOW NOT — 시스템을 깨뜨리는 비명백한 함정

- **`Date()` 직접 사용 금지** — 테스트 실행 시각에 따라 결과가 달라진다. 반드시 `TestCalendar`/`HomePhaseTestCalendar`로 결정론적 날짜를 사용할 것
- **XCTest(`XCTestCase`) 혼용 금지** — 이 프로젝트는 Swift Testing(`@Test` 매크로) 전용이다. `XCTestCase`를 상속하면 test runner 통합 방식이 달라져 누락 케이스가 생길 수 있다
- **외부 Mock/DB/Stub 도입 금지** — Domain 비즈니스 로직은 순수 Swift이므로 mock이 필요 없다. 테스트 헬퍼(`makeRecord`, `TestCalendar`)만으로 충분하다
- **UI 흐름을 단위 테스트로 커버 시도 금지** — View/ViewModel 계층의 UI 흐름은 시뮬레이터 수동 검증으로만 확인한다. XCUITest 등을 추가하면 유지 비용 대비 효과가 없다

## 5. WHERE — 다른 모듈과의 의존성

- **의존**: `Domain/`(UseCase, Helper, Model), `Data/`(Repository 구현체, Mapper — 일부 통합 테스트용)
- **피의존**: 없음 (테스트 타겟은 다른 모듈에서 import하지 않음)
- **경계**: Xcode 타겟 `MithmTests`. 앱 타겟 `Mithm`과 별개로 빌드됨

## 6. WHY — 코드에 안 적힌 배경 지식

- **`TestCalendar` / `HomePhaseTestCalendar` 헬퍼 존재 이유** — 예측 엔진과 Phase 판정은 "오늘 날짜"에 민감하다. 헬퍼 없이 테스트를 짜면 어제 통과한 테스트가 오늘 깨지는 flaky test가 된다
- **`makeRecord(...)` 팩토리 사용 이유** — `MenstrualRecord`는 필드가 많고 기본값이 비직관적인 부분이 있다. 팩토리를 통해 테스트에서 필요한 필드만 명시하고 나머지는 안전한 기본값으로 채운다
- **UI 자동화 테스트가 없는 이유** — 앱이 단일 타겟·단일 팀으로 빠르게 변화하는 상황에서 XCUITest 유지 비용이 크다고 판단. 비즈니스 로직 정확성에 집중하고 UI 회귀는 수동으로 빠르게 확인하는 전략을 택했다

_(이 영역의 비명백한 함정·배경 지식이 더 있다면 자유롭게 추가하세요. `learn` 스킬(`/learn` 또는 `$learn`)로도 누적 가능합니다.)_

## 7. ⚠️ LEARNED CAUTIONS — 학습된 주의사항
> `learn` 스킬(`/learn` 또는 Codex의 `$learn`)로 누적되는 영역.

_(아직 없음)_

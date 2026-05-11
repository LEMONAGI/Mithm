# Mithm Decisions

이 문서는 코드만 보면 놓치기 쉬운 설계 결정을 짧게 기록한다. 새 결정을 추가할 때는 기존 형식을 유지하고, 루트 문서를 길게 늘리지 않는다.

## ADR-001 HealthKit이 월경 기록의 단일 진실 공급원이다

- 월경 기록은 Apple Health에 저장한다.
- 앱은 HealthKit에서 읽은 기록을 바탕으로 예측과 상태를 계산한다.
- UserDefaults는 월경 기록 저장소가 아니다.
- SwiftData/CoreData를 새로 도입하지 않는다.

## ADR-002 `CurrentMenstrualEpisode`는 보조 플래그다

- `CurrentMenstrualEpisode`는 "사용자가 같은 시작일의 월경을 종료했는지" 또는 "자동 종료됐는지"를 보조로 기억한다.
- HealthKit 기록이 없어지면 로컬 episode만으로 월경 중이라고 판단하지 않는다.
- stale episode는 refresh 흐름에서 정리한다.

## ADR-003 예측과 Phase 판정은 Domain의 책임이다

- 예측 파라미터는 `MenstrualPredictionEngine.Config.default`에 모은다.
- Home Phase 판정 순서는 비즈니스 우선순위이므로 임의로 바꾸지 않는다.
- 예측/판정 변경은 먼저 Swift Testing 테스트로 고정한다.

## ADR-004 HealthKit/EventKit API는 Core에서 감싼다

- Core는 Apple 시스템 프레임워크 호출만 담당한다.
- 날짜 계산, 기록 의미 해석, 도메인 판정은 Core에서 하지 않는다.
- Data는 Core의 DataStore를 호출하고 Domain 모델로 변환한다.

## ADR-005 의존성 주입은 수동 팩토리로 유지한다

- `AppDIContainer`가 앱 전체 의존성 그래프를 조립한다.
- DI 프레임워크는 도입하지 않는다.
- 새 UseCase나 Repository 구현체를 추가할 때는 DI 그래프 연결을 함께 확인한다.

## ADR-006 사용자에게 보이는 언어는 한국어다

- UI 문자열, 사용자 문구, 문서는 한국어를 기본으로 한다.
- 식별자는 영어를 사용한다.
- 사용자에게 보이는 문자열은 로컬라이징 리소스에 둔다.

## ADR-007 테스트는 Swift Testing을 사용한다

- 단위 테스트는 `@Test`와 `#expect` 기반 Swift Testing으로 작성한다.
- XCTestCase를 새로 섞지 않는다.
- 날짜 의존 로직은 `Date()` 직접 호출 대신 테스트 헬퍼로 결정론적으로 만든다.

## ADR-008 UI 자동화 테스트는 기본 전략이 아니다

- 현재는 비즈니스 로직 단위 테스트와 시뮬레이터/실기기 수동 검증을 조합한다.
- XCUITest는 유지 비용이 큰 변경이므로 별도 결정 없이 도입하지 않는다.

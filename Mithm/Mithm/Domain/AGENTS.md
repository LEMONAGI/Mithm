# Domain 작업 가이드

> 이 가이드는 에이전트가 이 영역에서 코드를 건드리기 전에 반드시 알아야 할 컨텍스트를 담는다.
> 코드만 읽어선 알 수 없는 의도/함정/배경이 핵심이다.

## 1. WHAT — 이 모듈은 무엇을 하는가

앱의 비즈니스 규칙과 도메인 타입을 담당하는 순수 Swift 계층이다. Model(도메인 타입), State(도메인 상태 스냅샷), Repository 프로토콜(Data 계층 인터페이스), 예측/판정 Helper가 여기 있다. 외부 프레임워크(HealthKit/EventKit)를 직접 알지 않으며, Data 계층이 Domain의 Repository 프로토콜을 구현하는 방식으로 의존성이 역전된다.

**UseCase와 `AppState`는 이 영역에 없다.** 둘 다 `Presentation/App/`에 있다. UseCase 구현체가 Domain의 Repository 프로토콜에만 의존하므로 의존성 방향은 그대로 유지된다.

## 2. CONTENTS — 파일/디렉토리와 기술 스택

- `Model/` — `PhaseType`, `PhaseWindow`(Home), `CycleCalendarMonth`(Calendar), `MenstrualUserInput`, `UserInputMode`(Setting), `AlertPresentable`(Share)
- `Health/` — `MenstrualRecord`, `MenstrualRecordType`, `HealthDataType`, `WristTemperatureRecord`, `HealthKitError`
- `Event/` — `EventKitError`
- `State/` — `MenstrualOverview`, `MenstrualCycleSnapshot`, `UserSettingState`(`CurrentMenstrualEpisode` 포함)
- `Repository/` — `HealthKitRepository`, `EventKitRepository`, `UserSettingRepository`, `CurrentMenstrualEpisodeStore` 프로토콜 정의(Domain ↔ Data 계약은 전부 여기 모은다)
- `Helper/` — `MenstrualPredictionEngine`, `OpenPeriodAutoCloser`(`CurrentMenstrualStatusResolver` 포함), `OvulationRecordGenerator`

기술 스택: 순수 Swift (Foundation만 허용)

## 3. HOW — 일반적인 수정은 어떻게 하는가

- **새 기능 추가**: Domain에는 필요한 Model/Repository 프로토콜만 추가한다. UseCase 인터페이스와 구현체는 `Presentation/App/UseCase/`에 만들고 `Presentation/App/AppDIContainer.swift`에 등록한다
- **예측 알고리즘 튜닝**: `Helper/MenstrualPredictionEngine.swift`의 `Config.default`만 수정 — 로직이 아닌 파라미터 조정은 이 한 곳에서만
- **도메인 상태 추가**: `State/`에 값 타입을 추가한다. 앱 전역 `@Published` 상태가 필요하면 `Presentation/App/AppState.swift`를 수정한다
- **비즈니스 로직 수정**: 반드시 `MithmTests/`에 단위 테스트 추가 후 검증

## 4. ⛔ HOW NOT — 시스템을 깨뜨리는 비명백한 함정

- **Domain이 Data 또는 Core를 import 금지** — 의존성 방향은 반드시 `Presentation → Domain ← Data ← Core`. Domain이 구현 계층을 알면 테스트 격리가 불가능해지고 아키텍처 전체가 무너진다
- **SwiftData / CoreData 사용 금지** — HealthKit이 단일 진실 공급원이다. Domain은 Foundation만 import한다(초기 Xcode 템플릿 잔재였던 `Model/SwiftData/Item.swift`는 삭제했다). 새 영속 저장소를 만들지 말 것
- **HealthKit 샘플 날짜를 Domain에서 임의 조작 금지** — Mapper(Data 계층)가 샘플 날짜 범위를 그대로 닫힌 record로 변환한다. Domain에서 `endDate`를 nil로 바꾸거나 재해석하면 `CurrentMenstrualStatusResolver` 로직이 깨진다
- **`Config.default` 외부에서 예측 파라미터 하드코딩 금지** — 알고리즘 파라미터는 모두 `MenstrualPredictionEngine.Config.default`에 집중. 분산되면 동작 예측이 불가능해진다
- **`HomePhaseUseCaseImpl.execute()` 판정 순서 임의 변경 금지** — 파일 위치는 `Presentation/App/UseCase/HomePhaseUseCase/`이지만 내용은 도메인 비즈니스 규칙이다. 핵심 우선순위(진행 중 월경 → 배란기 → 난포기 → 황체기 → fallback)를 이유 없이 바꾸면 기존 테스트가 한꺼번에 깨진다

## 5. WHERE — 다른 모듈과의 의존성

- **의존**: 없음 (순수 Swift, Foundation만)
- **피의존**: `Data/`(Repository 프로토콜 구현), `Presentation/`(UseCase가 Model/Helper 사용, State 관찰)
- **경계**: Repository 프로토콜이 Domain ↔ Data 계약 지점. Domain Model/Helper가 Domain ↔ Presentation(UseCase) 계약 지점

## 6. WHY — 코드에 안 적힌 배경 지식

- **`MenstrualRecordType` 6종 분류** — 실제 HealthKit 기록(`.menstrualRecord`)과 미래 예측(`.menstrualPrediction`)만 HealthKit에 저장된다. 배란 추정/예측 3종은 앱 내부 표시 전용이며 HealthKit에 절대 기록하지 않는다. 이를 혼동하면 HealthKit에 잘못된 데이터가 쌓인다
- **`CurrentMenstrualEpisode`(UserDefaults)의 역할** — HealthKit 기록의 대체 저장소가 아니라, "같은 시작일의 월경을 사용자가 종료했는지/자동 종료됐는지"만 보조로 기억하는 플래그다. HealthKit 기록이 없어지면 로컬 open episode가 있어도 월경 중으로 보지 않는다
- **`CurrentMenstrualStatusResolver` 판정 우선순위**: (1) 오늘이 HealthKit 최신 월경 record 범위 안 → 월경 중 (2) 오늘 기록 없어도 예상 종료일 + 유예 2일 이내 → 월경 중 (3) 같은 시작일 로컬 episode가 `.userEnded` / `.autoClosed` → 월경 중 아님 (4) HealthKit 기록 없음 → 로컬 무시
- **예측 엔진 `makePredictionSourceRecords`** — 현재 월경 중일 때 해당 시작일의 실제 record를 제외하고 `endDate == nil` open record를 임시 주입한다. 이는 예측 anchor용이며 HealthKit 원본이 open record라는 뜻이 아니다
- **`UserInputMode` 3종** — `onlyUserInput`(모델 무시), `blendUserInput`(기본값, 혼합), `notBlendUserInput`(사용자 입력 무시)

_(이 영역의 비명백한 함정·배경 지식이 더 있다면 자유롭게 추가하세요. `learn` 스킬(`/learn` 또는 `$learn`)로도 누적 가능합니다.)_

## 7. ⚠️ LEARNED CAUTIONS — 학습된 주의사항
> `learn` 스킬(`/learn` 또는 Codex의 `$learn`)로 누적되는 영역.

_(아직 없음)_

# AGENTS.md

This file provides guidance to Codex (Codex.ai/code) when working with code in this repository.

## 프로젝트

**Mithm(미듬)** — 월경 주기를 기록하는 것을 넘어, 주기에 따른 몸의 변화(월경기·난포기·배란기·황체기)를 인식하고 일정을 조율할 수 있도록 돕는 iOS 앱. 외부 의존성 없이 SwiftUI + HealthKit + EventKit으로 구현된 단일 타겟 앱.

- Xcode 프로젝트 경로: `Mithm/Mithm.xcodeproj`
- 타겟: `Mithm` (앱), `MithmTests` (단위 테스트)
- 외부 패키지/CocoaPods/SPM 의존성 없음 — `xcodebuild`만으로 빌드 가능

## 빌드 / 테스트

```bash
# 빌드
xcodebuild build \
  -project Mithm/Mithm.xcodeproj -scheme Mithm \
  -destination 'platform=iOS Simulator,name=iPhone 16'

# 전체 테스트
xcodebuild test \
  -project Mithm/Mithm.xcodeproj -scheme Mithm \
  -destination 'platform=iOS Simulator,name=iPhone 16'

# 단일 테스트 케이스 실행 (Swift Testing — `@Test` 매크로 기반)
xcodebuild test \
  -project Mithm/Mithm.xcodeproj -scheme Mithm \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -only-testing:MithmTests/MithmTests/<테스트함수명>
```

XcodeBuildMCP 툴이 사용 가능하면 셸 명령보다 우선해서 사용 (`session_show_defaults` → `build_run_sim` / `test_sim`).

린터/포매터 설정 없음. 별도 빌드 스크립트나 Makefile도 없음.

## 아키텍처 핵심

Clean Architecture + MVVM. 의존성 방향: **Presentation → Domain ← Data ← Core**.

```
Presentation/   SwiftUI View + ViewModel + AppDIContainer
Domain/         UseCase, State, Model, Helper(예측 엔진 등), Repository 프로토콜 — 순수 Swift
Data/           Repository 구현체 + Mapper — 도메인 모델 ↔ HealthKit/EventKit 변환
Core/           HealthKit/EventKit 네이티브 API 래퍼 (DataStore)
Resource/       FontSystem, 색상 팔레트, Assets
Utility/        FormatterUtility 등
```

### 의존성 주입 — `AppDIContainer`

수동 팩토리 방식. DI 프레임워크 없음. `MithmApp` → `AppDIContainer.makeAppState()` / `makeHomeViewModel(appState:)` 형태로 그래프를 손수 조립한다. 새 UseCase/Repository 추가 시 이 컨테이너를 직접 수정.

### 상태 관리

- **`AppState`** (`@MainActor`, `ObservableObject`) — 앱 전역 단일 상태. `menstrualOverview`, `userSetting`, `menstrualRecordError`를 `@Published`로 노출.
- 라이프사이클 진입점:
  - `performInitialLoad()` — 앱 첫 실행. HealthKit 권한 요청 후 데이터 갱신.
  - `refreshOnForeground()` — `scenePhase == .active` 전환 시 호출.
  - `refreshMenstrualData()` — 사용자 액션(생리 시작/종료) 후 재조회 + 캘린더 동기화.
- `HomeViewModel` 등 화면별 ViewModel은 `AppState`를 주입받아 관찰.

### 데이터 단일 진실 공급원: HealthKit

자체 영속 저장소(SwiftData/CoreData)는 **사용하지 않는다**. (`Domain/Model/SwiftData/Item.swift`은 템플릿 잔재로 판단되며 실사용 X.) 모든 월경 기록은 Apple Health에 저장되며, 앱은 매번 HealthKit에서 읽어 예측을 실시간 계산한다. `UserDefaults`는 사용자 설정(주기 길이 입력, 캘린더 export 토글, `UserInputMode`)에만 쓴다.

### 옵셔널: EventKit 캘린더 동기화

`UserSettingState.calendarExportEnabled`가 켜져 있으면 `SyncMenstrualCalendarUseCase`가 `MenstrualOverview.allRecords`(실제+예측)를 시스템 캘린더에 반영. 사용자 토글로 끌 수 있는 부수 기능이며, 핵심 동작은 이 동기화 없이도 유지된다.

## 도메인 모델 — 반드시 이해해야 할 부분

### `MenstrualRecordType` (6종 분류)

```
실제 기록        .menstrualRecord                       (사용자가 HealthKit에 기록한 월경)
사후 추정        .ovulationEstimated                    (실제 기록으로부터 역산한 과거 배란일)
                .ovulationFertileWindowEstimated       (과거 배란기 구간)
미래 예측        .menstrualPrediction                   (다음 월경 예측)
                .ovulationPrediction                   (다음 배란일 예측)
                .ovulationFertileWindowPrediction      (다음 배란기 구간 예측)
```

`isPrediction`/`isEstimated`로 구분. HealthKit에 기록되는 것은 `.menstrualRecord`와 `.menstrualPrediction`(`healthDataType == .menstrualCycle`)뿐. 나머지는 앱 내부 표시용.

### 현재 월경 상태 판정

현재 월경 여부의 source of truth는 **HealthKit에 실제로 남아 있는 최신 `.menstrualRecord`**다. 로컬 `CurrentMenstrualEpisode`(`UserDefaults`)는 HealthKit 기록을 대체하는 저장소가 아니라, 같은 시작일의 월경에 대해 "사용자가 종료했는지/자동 종료됐는지"만 보조로 기억한다.

- HealthKit mapper는 샘플 날짜 범위를 그대로 닫힌 record로 읽는다. 오늘 샘플이라고 `endDate = nil`로 바꾸지 않는다.
- 월경 시작 버튼은 선택한 시작일 하루만 HealthKit에 저장하고, 로컬에는 `CurrentMenstrualEpisode(startDate, endDate: nil, closedReason: nil)`을 저장한다.
- `CurrentMenstrualStatusResolver`는 HealthKit 최신 월경 시작일을 기준으로 현재 상태를 계산한다.
  - 오늘이 최신 HealthKit 월경 record 범위 안이면 월경 중.
  - 오늘 기록이 없어도 최신 시작일이 `predictedPeriodLength` 기반 예상 종료일 + 유예 2일 이내면 월경 중.
  - 같은 시작일의 로컬 episode가 `.userEnded` 또는 `.autoClosed`면 월경 중이 아니다.
  - HealthKit 기록이 없으면 로컬 open episode가 있어도 월경 중으로 보지 않는다.
  - HealthKit 최신 시작일과 로컬 episode 시작일이 다르면 로컬 episode는 stale로 보고 무시한다.
- `RefreshMenstrualCycleUseCaseImpl`은 HealthKit에 대응되는 시작일이 없는 stale 로컬 episode를 `clearCurrentEpisode()`로 정리한다. 사용자가 건강 앱에서 월경 기록을 삭제한 경우 앱이 다시 월경 중으로 되살리거나 자동 종료로 재저장하지 않게 하기 위함이다.
- 자동 종료는 HealthKit 최신 기록이 있고, 같은 시작일의 open episode가 있으며, 예상 종료일 + 유예 2일을 지난 경우에만 실행한다. 이때 HealthKit에는 시작일~예상 종료일까지 닫힌 월경 기록을 저장하고 로컬 episode는 `.autoClosed`로 저장한다.
- `HomePhaseUseCase`는 `CurrentMenstrualStatus.activeStartDate`가 있을 때만 `.menstrual` phase를 최우선 표시한다. 예측 월경일이 지났지만 사용자가 시작하지 않았다면 월경기로 바꾸지 않고 기존 난포기/배란기/황체기 규칙을 따른다.
- 예측 엔진에는 현재 월경 중일 때 `MenstrualRecordUseCaseImpl.makePredictionSourceRecords`가 해당 시작일의 실제 record를 제외하고 `endDate == nil` open record를 임시 주입한다. 이는 예측 anchor용이며 HealthKit 원본이 open record라는 뜻은 아니다.

### `HomePhaseUseCase` — 현재 phase 판정 우선순위

`HomePhaseUseCaseImpl.execute()`는 다음 순서로 결정한다 (이 순서는 비즈니스 로직의 핵심):

1. 진행 중 월경(`activeMenstrualStartDate != nil`) → `.menstrual`
2. 다음 사이클 시작 경계 이후 예측 record는 현재 phase 계산에서 **제외** (`makeScopedRecords`)
3. 오늘이 배란기 record 안이면 `.ovulation`
4. 이전 월경기 ~ 다음 배란기 사이의 gap → `.follicular`
5. 이전 배란기 ~ 다음 월경기 사이의 gap → `.luteal`
6. 어디에도 안 속하면 직전 배란기 다음 날부터 오늘까지 `.luteal`로 연장

### 예측 엔진 — `MenstrualPredictionEngine`

`Domain/Helper/MenstrualPredictionEngine.swift`. 룰 기반 통계 모델 (ML 아님). 단계:

1. `extractActualRecords` / `extractOpenRecord` — type/endDate로 분리
2. `validateRecords` — 유효 기간 범위 (`validPeriodRange = 2...8`, `validCycleRange = 20...45`)
3. `makePeriodSamples` / `makeCycleSamples` — 길이 표본 추출
4. `cleanCycleSamples` — 중앙값 대비 편차로 이상치 가중치 부여 (normal 1.0 / mild 0.35 / severe 0.10)
5. `classifyVariability` — 최근 6개 cycle range로 `regular`/`moderate`/`irregular` 분류 (severe 제외)
6. `detectShift` — 최근 3개 vs 이전 3~6개 중앙값 차이가 `shiftThreshold(4.0)` 이상이면 패턴 전환 감지
7. `predictCycleLength` — 가중 EWMA(short-term) + median(long-term) 혼합. variability/shift에 따라 short-term 비중 조정.
8. `predictPeriodLength` — 비슷한 short/long 혼합 (단순 중앙값 fallback)
9. `blendPredictedLengths` — 모델 예측과 사용자 입력을 `userInputMode`에 따라 blend
10. `buildMenstrualPredictions` — 마지막 시작일 기준으로 `predictionCount(=3)`개 미래 record 생성

설정값은 모두 `Config.default`에 모여 있다 — 로직 튜닝 시 이 한 곳만 수정.

`UserInputMode` (3종):
- `onlyUserInput` — 모델 무시, 사용자 입력만으로 예측 (별도 메서드 `predictFromUserInput`)
- `blendUserInput` — 모델 + 사용자 입력 혼합 (기본값)
- `notBlendUserInput` — 사용자 입력 무시, 모델만 사용

### `MenstrualOverview` — UseCase 레이어의 합성 결과물

```swift
actualRecords  // HealthKit 원본 (실제 샘플 날짜 범위 그대로 닫힌 record)
allRecords     // actual(endDate 있는 것만) + 미래 월경 예측 + 추정/예측 배란 record, 시작일 정렬
prediction     // MenstrualPredictionResult (예측 길이, 신뢰도, shift 감지 여부 등)
```

`fetchMenstrualOverview()` 호출 시마다 예측 엔진 + `OvulationRecordGenerator`가 새로 돌아 만들어진다. 캐싱 없음.

## 데이터 흐름 (사용자 액션 예시: "월경 시작" 버튼)

```
HomeView Tap
  → HomeViewModel.startMenstruation()
  → RecordCurrentMenstrualPeriodUseCase.start(...)
       → HealthKit에는 시작일 하루짜리 .menstrualRecord 저장
       → UserDefaults에는 open CurrentMenstrualEpisode 저장
  → HealthKitRepository.updateMenstrualCycleRecord(...)
  → HealthKit (시스템)
  → AppState.refreshMenstrualData()
       → RefreshMenstrualCycleUseCase.execute(...)
       → MenstrualRecordUseCase.fetchMenstrualOverview()
            → readMenstrualCycleRecords + predictionEngine + ovulationRecordGenerator
       → CurrentMenstrualStatusResolver.resolve(...)
       → SyncMenstrualCalendarUseCase.execute(...)            // 토글 켜졌을 때만
  → @Published menstrualOverview/currentMenstrualStatus 갱신
  → HomeViewModel이 관찰 → PhaseWindow 재계산 → View 재렌더링
```

## 테스트

Swift Testing(`@Test`) 사용. 두 개 파일이 비즈니스 로직의 핵심을 커버한다:

- `MithmTests/MithmTests.swift` — 예측 엔진. record 필터링/검증, period·cycle 표본화, 이상치 가중치, variability 분류, EWMA, blend 로직, 신뢰도 산정 등 80+ 케이스.
- `MithmTests/HomePhaseUseCaseTests.swift` — phase window 계산. 진행 중 월경, 예측 record 제외, 배란기 포함, gap 기반 follicular/luteal, fallback 시나리오.
- `MithmTests/MaintainabilityRefactorTests.swift` — 현재 월경 시작/종료 use case, refresh orchestration, stale `CurrentMenstrualEpisode` 정리, 자동 종료 흐름.

테스트 헬퍼: `TestCalendar`/`HomePhaseTestCalendar`로 결정론적 날짜 조작, `makeRecord(...)` 팩토리 사용. UI 흐름은 자동화 테스트 없이 시뮬레이터에서 수동 검증.

비즈니스 로직(예측 엔진, UseCase, Helper) 변경 시 반드시 단위 테스트로 검증할 것 — UI 회귀보다 계산 회귀가 사용자에게 직접 영향을 준다.

## 코드 컨벤션

- **언어**: 사용자에게 보이는 문자열·주석·문서는 한국어. 식별자는 영어. 모델 의미를 한글 단어로 정의한 곳(`name`, `notes`, `title`)이 많으니 임의로 영문화하지 말 것.
- **커밋 메시지**: `[Feat]`, `[Fix]`, `[Refactor]`, `[Merge]` 같은 한국어 prefix 패턴(`git log`로 확인). PR 번호 인용은 `#19` 형식.
- **`Demo/` 하위 폴더**: `Core/HealthKit/Demo/`, `Core/EventKit/Demo/`, `Domain/UseCase/MenstrualRecordUseCase/Demo/` 등 — 개발/디버깅용 화면. 본 앱 흐름에 포함되지 않음. 새 기능 검증용으로 활용 가능.
- **권한**: HealthKit·EventKit 사용 설명문은 `Info.plist`에 정의. entitlement는 `Mithm.entitlements`.

## 자주 건드리는 위치

| 작업 | 파일 |
| --- | --- |
| 예측 알고리즘 튜닝 | `Domain/Helper/MenstrualPredictionEngine.swift` (`Config.default`) |
| 현재 월경 상태 판정 | `Domain/Helper/OpenPeriodAutoCloser.swift` (`CurrentMenstrualStatusResolver`), `Domain/UseCase/MenstrualCycleUseCase/RefreshMenstrualCycleUseCaseImpl.swift` |
| 현재 phase 판정 규칙 | `Domain/UseCase/HomePhaseUseCase/HomePhaseUseCaseImpl.swift` |
| 새 UseCase/Repository 등록 | `Presentation/App/AppDIContainer.swift` |
| 앱 라이프사이클(권한·갱신) | `Domain/State/AppState.swift` |
| HealthKit 읽기/쓰기 | `Data/HealthKit/HealthKitRepositoryImpl.swift`, `Core/HealthKit/Sources/HealthKitDataStoreImpl.swift` |
| 색상·폰트 추가 | `Resource/DesignSystem/FontSystem.swift`, `Assets.xcassets` |
| 사용자 설정 추가 | `Domain/Repository/UserSettingRepository.swift`, `Data/UserSetting/UserSettingRepositoryImpl.swift`, `Domain/State/UserSettingState.swift` |

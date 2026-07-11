# Mithm Architecture

이 문서는 Mithm의 구조를 빠르게 파악하기 위한 공통 지도다. 세부 규칙은 수정 대상 영역의 `AGENTS.md` 또는 `CLAUDE.md`를 함께 읽는다.

## 프로젝트 개요

Mirideum(미리듬)은 월경 주기 기록을 넘어 몸의 변화(월경기, 난포기, 배란기, 황체기)를 인식하고 일정을 조율하도록 돕는 iOS 앱이다.

- 앱: SwiftUI
- 시스템 연동: HealthKit, EventKit
- 의존성: 외부 라이브러리 없음
- Xcode 프로젝트: `Mithm/Mithm.xcodeproj`
- 테스트: Swift Testing 기반 `MithmTests`

## 계층 구조

의존성 방향은 반드시 지킨다.

```text
Presentation -> Domain <- Data <- Core
```

- `Presentation`: SwiftUI View, ViewModel, 앱 진입점, `AppDIContainer`, `AppState`, UseCase
- `Domain`: 순수 비즈니스 로직, Model, State, Repository 프로토콜, 예측/판정 Helper
- `Data`: Repository 구현체, HealthKit/EventKit Mapper, UserDefaults 변환
- `Core`: HealthKit/EventKit 네이티브 API 래퍼
- `Resource`: 폰트, 색상, 로컬라이징
- `Utility`: 포매터 등 Presentation 보조 유틸리티
- `MithmTests`: 예측 엔진, Phase 판정, UseCase 단위 테스트

UseCase와 `AppState`는 `Presentation/App/` 아래에 있다. UseCase 구현체는 Domain의 Repository 프로토콜에만 의존하므로 위 의존성 방향은 그대로 유지된다. Domain에 `UseCase/`나 `AppState`를 새로 만들지 않는다.

## 주요 경계

- `Domain/Repository/`: Domain과 Data 사이의 계약(`CurrentMenstrualEpisodeStore` 포함)
- `Presentation/App/UseCase/`: 화면과 Domain 사이의 기능 계약
- `Core/HealthKit/Sources/HealthKitDataStore`: Core와 Data 사이의 HealthKit 계약
- `Core/EventKit/Sources/EventKitDataStore`: Core와 Data 사이의 EventKit 계약
- `Presentation/App/AppDIContainer.swift`: 앱 전체 의존성 그래프 조립 지점(composition root)
- `Presentation/App/AppState.swift`: 앱 전역 상태와 화면 갱신의 중심

`AppDIContainer`는 composition root이므로 예외적으로 Data 구현체와 Core DataStore를 직접 생성한다. 이 예외는 `AppDIContainer` 한 파일에만 적용되며, 다른 Presentation 파일은 Data/Core를 직접 참조하지 않는다. `Demo/` 화면과 `#Preview`도 예외가 아니며 `AppDIContainer`의 팩토리를 거친다.

앱이 쓰는 그래프 조립 경로는 `makeAppDependencyGraph()` 하나뿐이다. ViewModel마다 별도 조립 팩토리를 두면 같은 그래프를 두 번 조립하게 되므로 만들지 않는다.

## 작업 시작 위치

- 예측 알고리즘, 월경 상태 판정, 도메인 모델: `Mithm/Mithm/Domain/`
- UseCase(Phase 판정, refresh 오케스트레이션, 캘린더 동기화 조율): `Mithm/Mithm/Presentation/App/UseCase/`
- HealthKit/EventKit 데이터 변환, Repository 구현: `Mithm/Mithm/Data/`
- HealthKit/EventKit 네이티브 API 호출: `Mithm/Mithm/Core/`
- 화면, ViewModel, DI, 로컬라이징, 디자인 시스템: `Mithm/Mithm/Presentation/`, `Mithm/Mithm/Resource/`, `Mithm/Mithm/Utility/`
- 테스트 추가/수정: `Mithm/MithmTests/`

## 금지되는 구조 변경

- Domain에서 Data/Core/Presentation import 금지
- Core에서 Domain/Data/Presentation import 금지 (`Demo/`도 예외 없음)
- Domain에 `UseCase/` 또는 `AppState` 신설 금지 (기존 위치는 `Presentation/App/`)
- `AppDIContainer` 외의 Presentation 파일에서 Data 구현체나 Core DataStore 직접 참조 금지
- View에서 UseCase 직접 호출 금지
- View/ViewModel 내부에서 Repository 구현체 직접 생성 금지
- DI 프레임워크, DB 프레임워크, 외부 Mock 라이브러리 도입 금지
- HealthKit 외 별도 월경 기록 영속 저장소 추가 금지

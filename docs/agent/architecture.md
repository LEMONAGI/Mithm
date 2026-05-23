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

- `Presentation`: SwiftUI View, ViewModel, 앱 진입점, `AppDIContainer`
- `Domain`: 순수 비즈니스 로직, UseCase, State, Model, Repository 프로토콜, 예측 엔진
- `Data`: Repository 구현체, HealthKit/EventKit Mapper, UserDefaults 변환
- `Core`: HealthKit/EventKit 네이티브 API 래퍼
- `Resource`: 폰트, 색상, 로컬라이징
- `Utility`: 포매터 등 Presentation 보조 유틸리티
- `MithmTests`: 예측 엔진, Phase 판정, UseCase 단위 테스트

## 주요 경계

- `Domain/Repository/`: Domain과 Data 사이의 계약
- `Domain/UseCase/`: Domain과 Presentation 사이의 기능 계약
- `Core/HealthKit/Sources/HealthKitDataStore`: Core와 Data 사이의 HealthKit 계약
- `Core/EventKit/Sources/EventKitDataStore`: Core와 Data 사이의 EventKit 계약
- `Presentation/App/AppDIContainer.swift`: 앱 전체 의존성 그래프 조립 지점
- `Domain/State/AppState.swift`: 앱 전역 상태와 화면 갱신의 중심

## 작업 시작 위치

- 예측 로직, Phase 판정, 월경 상태 판정: `Mithm/Mithm/Domain/`
- HealthKit/EventKit 데이터 변환, Repository 구현: `Mithm/Mithm/Data/`
- HealthKit/EventKit 네이티브 API 호출: `Mithm/Mithm/Core/`
- 화면, ViewModel, DI, 로컬라이징, 디자인 시스템: `Mithm/Mithm/Presentation/`, `Mithm/Mithm/Resource/`, `Mithm/Mithm/Utility/`
- 테스트 추가/수정: `Mithm/MithmTests/`

## 금지되는 구조 변경

- Domain에서 Data/Core/Presentation import 금지
- Core에서 Domain/Data/Presentation import 금지
- View에서 UseCase 직접 호출 금지
- View/ViewModel 내부에서 Repository 구현체 직접 생성 금지
- DI 프레임워크, DB 프레임워크, 외부 Mock 라이브러리 도입 금지
- HealthKit 외 별도 월경 기록 영속 저장소 추가 금지

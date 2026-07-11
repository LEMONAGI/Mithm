# Core 작업 가이드

> 이 가이드는 에이전트가 이 영역에서 코드를 건드리기 전에 반드시 알아야 할 컨텍스트를 담는다.
> 코드만 읽어선 알 수 없는 의도/함정/배경이 핵심이다.

## 1. WHAT — 이 모듈은 무엇을 하는가

HealthKit과 EventKit 네이티브 API를 감싸는 최하위 계층 래퍼다. 이 계층이 없어지면 앱이 Apple 시스템 프레임워크와 직접 결합되어 테스트와 교체가 불가능해진다. `Data/` 계층이 이 계층을 사용하며, `Presentation/App/AppDIContainer.swift`가 composition root로서 DataStore 구현체를 생성한다.

## 2. CONTENTS — 파일/디렉토리와 기술 스택

- `HealthKit/Sources/` — `HealthKitDataStore` 프로토콜 + `HealthKitDataStoreImpl` (권한 요청, 샘플 CRUD)
- `HealthKit/Demo/` — HealthKit 기능 개발/디버깅용 화면 (**본 앱 흐름 미포함**)
- `EventKit/Sources/` — `EventKitDataStore` 프로토콜 + `EventKitDataStoreImpl` (캘린더 이벤트 CRUD)
- `EventKit/Demo/` — EventKit 기능 개발/디버깅용 화면 (**본 앱 흐름 미포함**)
- `Helper/` — Core 계층 공통 유틸리티 (`DeepLinkHandler`)

기술 스택: Swift, HealthKit, EventKit (`Demo/`는 SwiftUI/Combine 사용)

## 3. HOW — 일반적인 수정은 어떻게 하는가

- **새 HealthKit 쿼리 추가**: `HealthKitDataStore` 프로토콜에 메서드 정의 → `HealthKitDataStoreImpl`에 구현 → `Data/HealthKit/HealthKitRepositoryImpl`에서 호출
- **권한 추가**: `HealthKitDataStoreImpl`의 권한 요청 집합에 추가 + `Info.plist`의 사용 설명문 갱신
- **Demo 폴더 활용**: 새 Core 기능을 본 앱 흐름에 통합하기 전에 `Demo/` 화면으로 빠르게 검증 가능

## 4. ⛔ HOW NOT — 시스템을 깨뜨리는 비명백한 함정

- **Core가 Domain 또는 Data를 import 금지** — 의존성 방향: `Presentation → Domain ← Data ← Core`. Core는 최하위이므로 상위 계층을 알면 의존성 사이클이 생긴다
- **`Demo/`도 이 규칙의 예외가 아니다** — 앱이 단일 타겟이라 Domain 타입(`MenstrualRecord`, `WristTemperatureRecord` 등)을 쓰면 컴파일은 통과한다. 그래서 실수로 새어 들어가기 쉽다. Demo 화면에 표시용 타입이 필요하면 `HealthKitDemoWristTemperatureSample`처럼 Core 안에서 자체 정의한다
- **Demo/ 폴더 코드를 본 앱 NavigationStack/TabView에 연결 금지** — `Demo/` 는 개발 검증용 격리 화면이다. 본 앱 흐름(MithmApp → HomeView 등)에 연결하면 릴리스 빌드에 디버깅 UI가 노출된다
- **HealthKit 샘플 저장/삭제 시 날짜 범위를 Core에서 임의 조정 금지** — Core는 받은 날짜를 그대로 HealthKit에 전달하는 역할만 한다. 날짜 계산은 Domain/Data 계층의 책임이다

## 5. WHERE — 다른 모듈과의 의존성

- **의존**: Apple HealthKit SDK, Apple EventKit SDK
- **피의존**: `Data/`(HealthKitRepositoryImpl, EventKitRepositoryImpl), `Presentation/App/AppDIContainer.swift`(DataStore 구현체 생성)
- **경계**: `HealthKitDataStore` 프로토콜과 `EventKitDataStore` 프로토콜이 Core ↔ Data 계약 지점

## 6. WHY — 코드에 안 적힌 배경 지식

- **Demo/ 폴더가 있는 이유** — HealthKit/EventKit은 시뮬레이터에서 동작이 제한적이고 권한 흐름도 복잡하다. 새 API를 전체 앱 흐름에 연결하기 전에 Core 기능만 독립적으로 검증하기 위한 샌드박스 역할을 한다
- **DataStore 프로토콜 + Impl 분리 이유** — 테스트 시 `HealthKitDataStore` 프로토콜을 mock으로 교체할 수 있도록 인터페이스를 분리했다. Impl이 프로토콜을 채택하는 표준 패턴

_(이 영역의 비명백한 함정·배경 지식이 더 있다면 자유롭게 추가하세요. `learn` 스킬(`/learn` 또는 `$learn`)로도 누적 가능합니다.)_

## 7. ⚠️ LEARNED CAUTIONS — 학습된 주의사항
> `learn` 스킬(`/learn` 또는 Codex의 `$learn`)로 누적되는 영역.

_(아직 없음)_

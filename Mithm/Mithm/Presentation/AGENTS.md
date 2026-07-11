# Presentation 작업 가이드

> 이 가이드는 에이전트가 이 영역에서 코드를 건드리기 전에 반드시 알아야 할 컨텍스트를 담는다.
> 코드만 읽어선 알 수 없는 의도/함정/배경이 핵심이다.

## 1. WHAT — 이 모듈은 무엇을 하는가

사용자에게 보이는 모든 UI(SwiftUI View)와 그 ViewModel, 앱 전역 상태 `AppState`, 앱의 **모든 UseCase**, 그리고 의존성 그래프를 조립하는 `AppDIContainer`가 있다. `AppState`를 통해 Domain 데이터를 관찰하고 화면을 렌더링한다. `Resource/`(폰트/색상/로컬라이징)와 `Utility/`(포매터 등)도 Presentation 작업 시 함께 참조한다.

## 2. CONTENTS — 파일/디렉토리와 기술 스택

- `App/` — `MithmApp.swift`(진입점), `AppDIContainer.swift`(의존성 조립), `AppState.swift`(앱 전역 상태), `ContentView.swift`, `LaunchSplashView.swift`
- `App/UseCase/` — 앱의 모든 UseCase 인터페이스 + 구현체. `HomePhaseUseCase`, `MenstrualCycleUseCase`(refresh 오케스트레이션), `MenstrualRecordUseCase`, `MenstrualRecordEditingUseCase`, `CurrentMenstrualPeriodUseCase`, `CycleCalendarUseCase`, `SyncMenstrualCalendarUseCase`, `UserSettingUseCase`
- `App/UseCase/MenstrualRecordUseCase/Demo/` — 개발/디버깅용 Demo 화면 (본 앱 흐름 미포함)
- `Home/` — 메인 화면 View + `HomeViewModel`
- `Calendar/` — 캘린더 View
- `Setting/` — 설정 화면 View
- `Onboarding/` — 온보딩 화면 View + 스텝 컴포넌트
- `Component/` — 화면 공통 컴포넌트
- `../Resource/DesignSystem/` — `FontSystem.swift`, 색상 팔레트
- `../Resource/Font/` — 커스텀 폰트 파일 + 등록
- `../Resource/Localization/` — 한국어 로컬라이징 문자열
- `../Resource/extension/` — SwiftUI/Foundation 확장
- `../Utility/` — `FormatterUtility` 등

기술 스택: SwiftUI, Combine(ObservableObject/@Published)

## 3. HOW — 일반적인 수정은 어떻게 하는가

- **새 화면 추가**: View + ViewModel 파일 생성 → `AppDIContainer`에 `makeXxxViewModel()` 팩토리 메서드 추가
- **새 UseCase 추가**: `App/UseCase/<이름>/`에 프로토콜 + `Impl` 생성(의존성은 Domain의 Repository 프로토콜로만 받는다) → `AppDIContainer`에서 조립해 ViewModel에 주입 → `MithmTests/`에 단위 테스트 추가
- **새 UseCase 화면 연결**: `AppDIContainer`에서 UseCase 인스턴스를 생성해 ViewModel 생성자에 주입
- **색상/폰트 추가**: `Resource/DesignSystem/FontSystem.swift` 또는 `Assets.xcassets/Color/` 수정
- **로컬라이징 문자열 추가**: `Resource/Localization/Localizable.xcstrings`에 한국어 키-값 추가 (앱 표시 문자열), `InfoPlist.xcstrings`(권한 설명문)
- **HomeViewModel 수정**: `AppState.menstrualOverview` / `currentMenstrualStatus` 구독 흐름 먼저 파악 후 수정

## 4. ⛔ HOW NOT — 시스템을 깨뜨리는 비명백한 함정

- **View에서 UseCase 직접 호출 금지** — View는 ViewModel만 알아야 한다. UseCase를 View에 직접 주입하면 재사용성과 테스트 격리가 깨진다
- **`AppDIContainer` 우회해서 의존성 직접 생성 금지** — `RepositoryImpl`, `UseCaseImpl`을 View나 ViewModel 내부에서 직접 `init`하면 DI 그래프 밖에 떠 있는 인스턴스가 생겨 상태 불일치가 발생한다. Data 구현체와 Core DataStore를 직접 생성해도 되는 파일은 composition root인 `AppDIContainer` 하나뿐이다
- **UseCase 구현체가 Data/Core 타입을 직접 참조 금지** — UseCase는 `Presentation/App/UseCase/`에 있지만 Domain의 Repository 프로토콜만 알아야 한다. `HealthKitRepositoryImpl`이나 `HealthKitDataStore`를 직접 참조하면 단위 테스트에서 교체가 불가능해진다
- **DI 프레임워크(Swinject, Needle 등) 도입 금지** — 이 프로젝트는 수동 팩토리 방식을 의도적으로 선택했다. 프레임워크를 도입하면 기존 팩토리 메서드 패턴과 혼재되어 그래프 추적이 불가능해진다
- **`AppState`를 ViewModel 없이 View에서 직접 수정 금지** — 상태 변경은 ViewModel을 거쳐야 한다. View에서 `appState.xxx = yyy`를 직접 쓰면 변경 흐름 추적이 불가능해진다
- **사용자에게 보이는 문자열을 영문 하드코딩 금지** — `Localizable.xcstrings`에 한국어 키-값으로 관리한다. 영문 식별자를 UI에 직접 노출하면 안 된다

## 5. WHERE — 다른 모듈과의 의존성

- **의존**: `Domain/`(Model/Helper 사용, State 관찰), `Resource/`, `Utility/`. `AppDIContainer`만 예외적으로 `Data/`와 `Core/`를 직접 참조한다
- **피의존**: 없음 (최상위 계층)
- **경계**: `AppDIContainer`가 Domain ↔ Data ↔ Core 전체 그래프를 조립하는 진입점. `AppState`가 Domain → 화면 데이터 흐름의 경계. UseCase가 화면 ↔ Domain 기능 계약 지점

## 6. WHY — 코드에 안 적힌 배경 지식

- **수동 DI(`AppDIContainer`) 선택 이유** — SPM/CocoaPods 의존성을 전혀 추가하지 않는다는 원칙 하에 DI 프레임워크 없이 손수 조립. 그래프가 작아 오버헤드가 없고, 컴파일 타임에 누락이 바로 잡힌다
- **`AppState`가 단일 전역 상태인 이유** — `menstrualOverview`는 앱 전반(홈/캘린더/설정)에서 필요하다. ViewModel마다 별도 fetch를 두면 데이터 불일치가 생기므로 단일 `@Published` 값을 공유한다
- **`refreshOnForeground()` 호출 이유** — 사용자가 건강 앱에서 데이터를 수정하고 돌아왔을 때 앱이 최신 상태를 반영하도록 `scenePhase == .active` 전환 시마다 재조회한다
- **`MithmApp` 진입점에서의 흐름**: `MithmApp` → `AppDIContainer.makeAppState()` / `makeHomeViewModel(appState:)` → SwiftUI Environment/ObservableObject로 주입

_(이 영역의 비명백한 함정·배경 지식이 더 있다면 자유롭게 추가하세요. `learn` 스킬(`/learn` 또는 `$learn`)로도 누적 가능합니다.)_

## 7. ⚠️ LEARNED CAUTIONS — 학습된 주의사항
> `learn` 스킬(`/learn` 또는 Codex의 `$learn`)로 누적되는 영역.

- SwiftUI Liquid Glass 버튼은 `glassEffect`로 수동 구성하기 전에 Apple 공식 문서의 `buttonStyle` 계열(`.glass`, `.glassProminent`)을 먼저 확인한다.
- iOS 기본 컴포넌트(SwiftUI/UIKit 등)를 사용할 때 API 선택이나 modifier 적용 방식이 애매하면 추측하지 말고 Apple 공식 문서를 먼저 참고한다.

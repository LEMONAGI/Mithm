//
//  AppDIContainer.swift
//  Mithm
//
//  Created by YunhakLee on 3/14/26.
//

import Foundation

struct AppDependencyGraph {
    let appState: AppState
    let homeViewModel: HomeViewModel
    let calendarViewModel: CalendarViewModel
    let settingViewModel: SettingViewModel
    let cycleSettingViewModel: CycleSettingViewModel
    let onboardingViewModel: OnboardingViewModel
}

struct AppDIContainer {

    static func makeAppDependencyGraph() -> AppDependencyGraph {
        let calendar = Calendar.current
        let healthKitRepository = makeHealthKitRepository()
        let menstrualRecordUseCase = MenstrualRecordUseCaseImpl(
            healthKitRepository: healthKitRepository,
            calendar: calendar
        )

        let eventKitRepository = makeEventKitRepository()
        let syncMenstrualCalendarUseCase = SyncMenstrualCalendarUseCaseImpl(
            eventKitRepository: eventKitRepository
        )

        let userSettingRepository = UserSettingRepositoryImpl()
        let userSettingUseCase = UserSettingUseCaseImpl(
            userSettingRepository: userSettingRepository
        )
        let loadUserSettingsUseCase = LoadUserSettingsUseCaseImpl(
            userSettingUseCase: userSettingUseCase
        )
        let currentMenstrualEpisodeStore = UserDefaultsCurrentMenstrualEpisodeStore()

        let refreshMenstrualCycleUseCase = RefreshMenstrualCycleUseCaseImpl(
            menstrualRecordUseCase: menstrualRecordUseCase,
            syncMenstrualCalendarUseCase: syncMenstrualCalendarUseCase,
            currentMenstrualEpisodeStore: currentMenstrualEpisodeStore,
            currentMenstrualStatusResolver: CurrentMenstrualStatusResolver(),
            calendar: calendar
        )
        let recordCurrentMenstrualPeriodUseCase = RecordCurrentMenstrualPeriodUseCaseImpl(
            menstrualRecordUseCase: menstrualRecordUseCase,
            currentMenstrualEpisodeStore: currentMenstrualEpisodeStore,
            calendar: calendar
        )
        let homePhaseUseCase = HomePhaseUseCaseImpl()
        let cycleCalendarUseCase = CycleCalendarUseCaseImpl(calendar: calendar)
        let menstrualRecordEditingUseCase = MenstrualRecordEditingUseCaseImpl(
            menstrualRecordUseCase: menstrualRecordUseCase,
            currentMenstrualEpisodeStore: currentMenstrualEpisodeStore,
            calendar: calendar
        )

        let appState = AppState(
            menstrualRecordUseCase: menstrualRecordUseCase,
            refreshMenstrualCycleUseCase: refreshMenstrualCycleUseCase,
            loadUserSettingsUseCase: loadUserSettingsUseCase,
            userSettingUseCase: userSettingUseCase,
            syncMenstrualCalendarUseCase: syncMenstrualCalendarUseCase
        )

        let homeViewModel = HomeViewModel(
            appState: appState,
            calendar: calendar,
            recordCurrentMenstrualPeriodUseCase: recordCurrentMenstrualPeriodUseCase,
            homePhaseUseCase: homePhaseUseCase
        )
        let calendarViewModel = CalendarViewModel(
            appState: appState,
            cycleCalendarUseCase: cycleCalendarUseCase,
            menstrualRecordEditingUseCase: menstrualRecordEditingUseCase,
            calendar: calendar
        )

        let settingViewModel = SettingViewModel(appState: appState)
        let cycleSettingViewModel = CycleSettingViewModel(appState: appState)
        let onboardingViewModel = OnboardingViewModel(
            appState: appState,
            menstrualRecordUseCase: menstrualRecordUseCase,
            syncMenstrualCalendarUseCase: syncMenstrualCalendarUseCase
        )

        return AppDependencyGraph(
            appState: appState,
            homeViewModel: homeViewModel,
            calendarViewModel: calendarViewModel,
            settingViewModel: settingViewModel,
            cycleSettingViewModel: cycleSettingViewModel,
            onboardingViewModel: onboardingViewModel
        )
    }

    /// 개발/디버깅용 Demo 화면 전용. 본 앱 흐름(`makeAppDependencyGraph`)과 분리된 그래프다.
    static func makeMenstrualRecordUseCaseDemoViewModel() -> MenstrualRecordUseCaseDemoViewModel {
        let healthKitRepository = makeHealthKitRepository()

        return MenstrualRecordUseCaseDemoViewModel(
            healthKitRepository: healthKitRepository,
            eventKitRepository: makeEventKitRepository(),
            useCase: MenstrualRecordUseCaseImpl(healthKitRepository: healthKitRepository)
        )
    }

    private static func makeHealthKitRepository() -> HealthKitRepository {
        HealthKitRepositoryImpl(dataStore: HealthKitDataStoreImpl())
    }

    private static func makeEventKitRepository() -> EventKitRepository {
        EventKitRepositoryImpl(dataStore: EventKitDataStoreImpl())
    }
}

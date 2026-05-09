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
}

struct AppDIContainer {

    static func makeAppDependencyGraph() -> AppDependencyGraph {
        let calendar = Calendar.current
        let healthKitDataStore = HealthKitDataStoreImpl()
        let healthKitRepository = HealthKitRepositoryImpl(dataStore: healthKitDataStore)
        let menstrualRecordUseCase = MenstrualRecordUseCaseImpl(
            healthKitRepository: healthKitRepository,
            calendar: calendar
        )

        let eventKitDataStore = EventKitDataStoreImpl()
        let eventKitRepository = EventKitRepositoryImpl(dataStore: eventKitDataStore)
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
            userSettingUseCase: userSettingUseCase
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

        return AppDependencyGraph(
            appState: appState,
            homeViewModel: homeViewModel,
            calendarViewModel: calendarViewModel,
            settingViewModel: settingViewModel
        )
    }

    static func makeAppState() -> AppState {
        makeAppDependencyGraph().appState
    }

    static func makeHomeViewModel(appState: AppState) -> HomeViewModel {
        let calendar = Calendar.current
        let healthKitRepository = HealthKitRepositoryImpl(
            dataStore: HealthKitDataStoreImpl()
        )
        let menstrualRecordUseCase = MenstrualRecordUseCaseImpl(
            healthKitRepository: healthKitRepository,
            calendar: calendar
        )
        let recordCurrentMenstrualPeriodUseCase = RecordCurrentMenstrualPeriodUseCaseImpl(
            menstrualRecordUseCase: menstrualRecordUseCase,
            currentMenstrualEpisodeStore: UserDefaultsCurrentMenstrualEpisodeStore(),
            calendar: calendar
        )

        return HomeViewModel(
            appState: appState,
            calendar: calendar,
            recordCurrentMenstrualPeriodUseCase: recordCurrentMenstrualPeriodUseCase,
            homePhaseUseCase: HomePhaseUseCaseImpl()
        )
    }

    static func makeCalendarViewModel(appState: AppState) -> CalendarViewModel {
        let calendar = Calendar.current
        let healthKitRepository = HealthKitRepositoryImpl(
            dataStore: HealthKitDataStoreImpl()
        )
        let menstrualRecordUseCase = MenstrualRecordUseCaseImpl(
            healthKitRepository: healthKitRepository,
            calendar: calendar
        )
        let currentMenstrualEpisodeStore = UserDefaultsCurrentMenstrualEpisodeStore()
        let menstrualRecordEditingUseCase = MenstrualRecordEditingUseCaseImpl(
            menstrualRecordUseCase: menstrualRecordUseCase,
            currentMenstrualEpisodeStore: currentMenstrualEpisodeStore,
            calendar: calendar
        )

        return CalendarViewModel(
            appState: appState,
            cycleCalendarUseCase: CycleCalendarUseCaseImpl(calendar: calendar),
            menstrualRecordEditingUseCase: menstrualRecordEditingUseCase,
            calendar: calendar
        )
    }
}

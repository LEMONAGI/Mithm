//
//  AppDIContainer.swift
//  Mithm
//
//  Created by YunhakLee on 3/14/26.
//

import Foundation

struct AppDIContainer {

    static func makeAppState() -> AppState {
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
        let currentMenstrualEpisodeStore = UserDefaultsCurrentMenstrualEpisodeStore()

        return AppState(
            menstrualRecordUseCase: menstrualRecordUseCase,
            syncMenstrualCalendarUseCase: syncMenstrualCalendarUseCase,
            userSettingUseCase: userSettingUseCase,
            currentMenstrualEpisodeStore: currentMenstrualEpisodeStore,
            currentMenstrualStatusResolver: CurrentMenstrualStatusResolver()
        )
    }

    static func makeHomeViewModel(appState: AppState) -> HomeViewModel {
        let calendar = Calendar.current
        let healthKitDataStore = HealthKitDataStoreImpl()
        let healthKitRepository = HealthKitRepositoryImpl(dataStore: healthKitDataStore)
        let menstrualRecordUseCase = MenstrualRecordUseCaseImpl(
            healthKitRepository: healthKitRepository,
            calendar: calendar
        )
        let homePhaseUseCase = HomePhaseUseCaseImpl()
        let currentMenstrualEpisodeStore = UserDefaultsCurrentMenstrualEpisodeStore()

        return HomeViewModel(
            appState: appState,
            calendar: calendar,
            menstrualRecordUseCase: menstrualRecordUseCase,
            homePhaseUseCase: homePhaseUseCase,
            currentMenstrualEpisodeStore: currentMenstrualEpisodeStore
        )
    }
}

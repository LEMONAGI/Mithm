//
//  AppDIContainer.swift
//  Mithm
//
//  Created by YunhakLee on 3/14/26.
//

import Foundation

struct AppDIContainer {

    static func makeAppState() -> AppState {
        let healthKitDataStore = HealthKitDataStoreImpl()
        let healthKitRepository = HealthKitRepositoryImpl(dataStore: healthKitDataStore)
        let menstrualRecordUseCase = MenstrualRecordUseCaseImpl(
            healthKitRepository: healthKitRepository
        )
        let userSettingRepository = UserSettingRepositoryImpl()

        return AppState(
            menstrualRecordUseCase: menstrualRecordUseCase,
            userSettingRepository: userSettingRepository
        )
    }
}

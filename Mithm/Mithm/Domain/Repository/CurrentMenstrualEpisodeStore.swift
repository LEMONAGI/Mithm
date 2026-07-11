//
//  CurrentMenstrualEpisodeStore.swift
//  Mithm
//
//  Created by YunhakLee on 3/15/26.
//

import Foundation

/// HealthKit 기록의 대체 저장소가 아니라, 같은 시작일의 월경을 사용자가 종료했는지 또는
/// 자동 종료됐는지만 보조로 기억하는 플래그 저장소다.
protocol CurrentMenstrualEpisodeStore {
    func loadCurrentEpisode() -> CurrentMenstrualEpisode?
    func saveCurrentEpisode(_ episode: CurrentMenstrualEpisode)
    func clearCurrentEpisode()
}

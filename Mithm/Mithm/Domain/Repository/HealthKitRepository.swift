//
//  HealthKitRepository.swift
//  Mithm
//
//  Created by YunhakLee on 11/20/25.
//

import Foundation

protocol HealthKitRepository {
    
    // MARK: - Authorization
    
    /// 쓰기 권한 상태 검증
    func checkWriteAuthorization(
        for type: HealthDataType
    ) async throws
    
    /// 권한 요청
    func requestAuthorization(
        writeTypes: Set<HealthDataType>,
        readTypes: Set<HealthDataType>
    ) async throws
    
    
    // MARK: - MenstrualCycleRecord
    
    /// from ~ to  기간 내의 월경 기록을 healthKit에서 받아온다.
    /// 온보딩에서 반드시 이전 월경 기록을 건강앱에 작성하므로, 결과가 비어있다면 권한이 없는 것이 되어 오류를 던진다.
    func readMenstrualCycleRecords(
        from startDate: Date,
        to endDate: Date
    ) async throws -> [MenstrualRecord] 

    /// from ~ to 기간 내의 손목 온도 기록을 HealthKit에서 받아온다.
    func readWristTemperatureRecords(
        from startDate: Date,
        to endDate: Date
    ) async throws -> [WristTemperatureRecord]
    
    /// 해당 월경 기록을 healthKit에 업데이트 한다
    ///
    /// - `deleteFrom ~ deleteThrough` 범위의 기존 샘플을 삭제한 뒤, record를 새로 저장한다.
    /// - `deleteFrom`: 삭제 시작점. nil이면 record.startDate를 사용한다.
    /// - `deleteThrough`: 삭제 끝점. nil이면 record.endDate(또는 record.startDate)를 사용한다.
    /// - 기록 수정 시에는 이전 기록 범위를, open record 갱신 시에는 Date()를 지정한다.
    func updateMenstrualCycleRecord(
        _ record: MenstrualRecord,
        deleteFrom: Date?,
        deleteThrough: Date?
    ) async throws

    /// 해당 기간의 월경 기록을 HealthKit에서 삭제한다.
    func deleteMenstrualCycleRecords(
        from startDate: Date,
        to endDate: Date
    ) async throws
}

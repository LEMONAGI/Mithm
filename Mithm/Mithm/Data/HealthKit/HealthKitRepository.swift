//
//  HealthKitRepository.swift
//  Mithm
//
//  Created by YunhakLee on 11/20/25.
//

import Foundation
import HealthKit

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
    func readMenstrualCycleRecords(
        from startDate: Date,
        to endDate: Date
    ) async throws -> [MenstrualRecord] 
    
    /// 해당 월경 기록을 healthKit에 업데이트 한다
    ///
    /// - 기록 범위에 있는 healthKit 월경 기록을 삭제하고, 입력받은 월경 기록을 새로 저장한다.
    func updateMenstrualCycleRecord(
        _ record: MenstrualRecord
    ) async throws
}

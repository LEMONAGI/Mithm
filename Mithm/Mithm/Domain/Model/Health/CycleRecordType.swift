//
//  CycleRecordType.swift
//  Mithm
//
//  Created by YunhakLee on 11/19/25.
//

enum CycleRecordType {
    case menstrualRecord             // 과거 월경 기록
    case ovulationEstimated          // 과거 배란일 추정 (하루)
    case menstrualPrediction         // 미래 월경 예정
    case ovulationPrediction         // 미래 배란일 예측 (하루)
    
    case ovulationFertileWindowEstimated   // 과거 기록 기반 배란기(추정)
    case ovulationFertileWindowPrediction  // 미래 예측 기반 배란기(예상)
}

// MARK: - Metadata
extension CycleRecordType {
    
    var title: String {
        switch self {
        case .menstrualRecord:
            return "월경 기록"
        case .ovulationEstimated:
            return "배란일(추정)"
        case .menstrualPrediction:
            return "월경 예정 기간"
        case .ovulationPrediction:
            return "배란일(예상)"
        case .ovulationFertileWindowEstimated:
            return "배란기(추정)"
        case .ovulationFertileWindowPrediction:
            return "배란기(예상)"
        }
    }
    
    var notes: String? {
        switch self {
        case .menstrualRecord:
            return "사용자 기록에 기반한 실제 월경 기간입니다."
        case .ovulationEstimated:
            return "앱이 건강 기록을 기반으로 사후적으로 추정한 배란일입니다."
        case .menstrualPrediction:
            return "앱에서 예측한 월경 예정 기간입니다."
        case .ovulationPrediction:
            return "앱에서 예측한 배란일입니다."
        case .ovulationFertileWindowEstimated:
            return "월경 기록을 기반으로 추정한 배란기(가임기)입니다."
        case .ovulationFertileWindowPrediction:
            return "예측된 월경 예정일을 바탕으로 계산한 배란기(가임기)입니다."
        }
    }
    
    var typeString: String {
        switch self {
        case .menstrualRecord:
            return "menstrual_record"
        case .ovulationEstimated:
            return "ovulation_estimated"
        case .menstrualPrediction:
            return "menstrual_prediction"
        case .ovulationPrediction:
            return "ovulation_prediction"
        case .ovulationFertileWindowEstimated:
            return "ovulation_fertile_window_estimated"
        case .ovulationFertileWindowPrediction:
            return "ovulation_fertile_window_prediction"
        }
    }
    
    /// 예측 데이터인지 여부
    var isPrediction: Bool {
        switch self {
        case .menstrualPrediction,
                .ovulationPrediction,
                .ovulationFertileWindowEstimated,
                .ovulationFertileWindowPrediction:
            return true
        default:
            return false
        }
    }
    
    var healthDataType: HealthDataType? {
        switch self {
        case .menstrualPrediction,
                .menstrualRecord:
            return .menstrualCycle
        default:
            return nil
        }
    }
}

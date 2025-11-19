//
//  CycleRecordType.swift
//  Mithm
//
//  Created by YunhakLee on 11/19/25.
//

enum CycleRecordType {
    case menstrualRecord        // 과거 월경 기록
    case ovulationEstimated        // 과거 배란일 추정값
    case menstrualPrediction    // 미래 월경 예정
    case ovulationPrediction    // 미래 배란일 예측
}

// MARK: - Metadata

extension CycleRecordType {
    
    /// 캘린더 이벤트 제목
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
        }
    }
    
    /// 이벤트 설명 (notes)
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
        }
    }
    
    /// URL 식별자 type 문자열
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
        }
    }
}

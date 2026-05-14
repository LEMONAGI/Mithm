//
//  UIKitDatePicker.swift
//  Mithm
//
//  Created by YunhakLee on 5/15/26.
//

import SwiftUI
import UIKit

struct UIKitDatePicker: UIViewRepresentable {
    @Binding var date: Date
    let range: ClosedRange<Date>
    
    func makeUIView(context: Context) -> UIDatePicker {
        let picker = UIDatePicker()
        picker.datePickerMode = .date
        picker.preferredDatePickerStyle = .compact
        picker.minimumDate = range.lowerBound
        picker.maximumDate = range.upperBound
        
        
        picker.tintColor = UIColor(named: "AccentColor")
        
        picker.setContentCompressionResistancePriority(.required, for: .horizontal)
        picker.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        
        picker.addTarget(context.coordinator, action: #selector(Coordinator.dateChanged(_:)), for: .valueChanged)
        
        
        return picker
    }
    
    func updateUIView(_ uiView: UIDatePicker, context: Context) {
        uiView.date = date
        uiView.minimumDate = range.lowerBound
        uiView.maximumDate = range.upperBound
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject {
        var parent: UIKitDatePicker
        
        init(_ parent: UIKitDatePicker) {
            self.parent = parent
        }
        
        @objc func dateChanged(_ sender: UIDatePicker) {
            parent.date = sender.date
        }
    }
}

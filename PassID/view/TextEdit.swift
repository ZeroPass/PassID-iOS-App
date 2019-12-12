//
//  TextEdit.swift
//  PassID
//
//  Created by smlu on 03/12/2019.
//  Copyright © 2019 ZeroPass. All rights reserved.
//

import SwiftUI


// Defines TextField with label.
// TODO: constrain TextEdit to StringProtocol, Numeric and URL
struct TextEdit<T> : View {

    init(label: String, placeholder: String = "", value: Binding<T>) {
        self.label = label
        self.placeholder = placeholder
        self.value = value
    }
    
    func defaultValue(_ value: T?) -> TextEdit {
        var copy = self
        copy.defaultValue = value
        return copy
    }
    
    func inputValidator(_ validator: ((_:String) -> Bool)?) -> TextEdit {
        var copy = self
        copy.validator = validator
        return copy
    }
    
    func keyboardType(_ type: UIKeyboardType) -> TextEdit {
        var copy = self
        copy.keyboardType = type
        return copy
    }
    
    func maxInputLength(_ maxLength: Int) -> TextEdit {
        var copy = self
        copy.maxLength = maxLength
        return copy
    }
    
    func textContentType(_ type: UITextContentType?) -> TextEdit {
        var copy = self
        copy.textContentType = type
        return copy
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(label)
                .font(.headline)

            TextField(self.placeholder, text: self.valueProxy, onEditingChanged: { isEditing in
                let resetValue = (self.valueProxy.wrappedValue.isEmpty //||
                   // self.value.wrappedValue is Numeric.self
                )
                if !isEditing && resetValue {
                    var value = self.value.wrappedValue
                    let setDefault =  value is Int ? value as! Int == 0 : true
                    if self.defaultValue != nil && setDefault {
                        value = self.defaultValue!
                    }
                    self.value.wrappedValue = value
                }
            })
                .disableAutocorrection(true)
                .keyboardType(self.keyboardType)
                .textContentType(self.textContentType)
        }
        // Finish editing if text edit is tapped.
        .onTapGesture { UIApplication.shared.sendAction(#selector(UIView.resignFirstResponder), to: nil, from: nil, for: nil) }
    }
    
    private var defaultValue: T?
    private var minValue: T?
    private var maxValue: T?
    private var maxLength: Int = -1
    private var validator: ((_ val: String) -> Bool)?
    
    private var label: String
    private var placeholder: String
    
    private var keyboardType: UIKeyboardType = .default
    private var textContentType: UITextContentType?
    
    private var value: Binding<T>
    private var valueProxy: Binding<String> {
        Binding<String>(
            get: { self.getValueAsString() },
            set: {
                self.setValueFromString(newValue: $0)
            }
        )
    }

    private func getValueAsString() -> String {
        if let str = self.value.wrappedValue as? String {
            return str
        }
        else if let url = self.value.wrappedValue as? URL {
            return url.absoluteString
        }
        else {
            let n = value.wrappedValue
            return NumberFormatter().string(for: n)! // Will crash the app if T is not Numeric here.
                                                     // This is mini bug until LabelTextField is constrained
                                                     // to allow only either StringProtocol or Numeric type.
        }
    }
    
    private func setValueFromString(newValue: String)  {
        let valid = (validator != nil ? validator!(newValue) : true)
        if  valid && (
            self.maxLength == -1 ||
            newValue.count <= self.maxLength  ||
            newValue.count < self.valueProxy.wrappedValue.count)
        {
            if self.value.wrappedValue is String {
                self.value.wrappedValue = newValue as! T
                return
            }
            else if self.value.wrappedValue is URL {
                if let url = URL(string: newValue) as? T {
                    self.value.wrappedValue = url
                    return
                }
            }
            else if let value = getNumberInRangeFromString(newValue) {
                self.value.wrappedValue = value
                return
            }
        }
        
        if newValue != getValueAsString() && !newValue.isEmpty {
            self.value.wrappedValue = self.value.wrappedValue
        }
    }
    
    // Function returns number if number can be parsed from string otherwise nil.
    // Returned value is clamped to minValue (if set).
    private func getNumberInRangeFromString(_ strValue: String) -> T? {
        guard var value = NumberFormatter().number(from: strValue) else {
            return nil
        }

        if self.maxValue != nil {
            let maxVal =  self.maxValue! as! NSNumber
            if value.compare(maxVal) == .orderedDescending {
                // If value is greater then maxValue, return nil.
                // The caller should restore presented value to the stored value.
                return nil
            }
        }
        if self.minValue != nil {
            let minVal =  self.minValue! as! NSNumber
            value = (minVal.compare(value) == .orderedDescending ? minVal : value) //max(self.minValue as! T, value)
        }
        return value as? T
    }
}


extension TextEdit where T: Numeric & Comparable {
    func maxValue(_ maxValue: T) -> TextEdit {
        var copy = self
        copy.maxValue = maxValue
        return copy
    }
    
    func minValue(_ minValue: T) -> TextEdit {
        var copy = self
        copy.minValue = minValue
        return copy
    }
}

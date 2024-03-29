//
//  NumericTextField.swift
//
//

import SwiftUI
import AssessmentModel
import JsonModel
import SharedMobileUI

struct NumericTextField<Value : JsonNumber>: View where Value : JsonValue {
    @SwiftUI.Environment(\.surveyTintColor) var surveyTint: Color
    @EnvironmentObject var keyboard: KeyboardObserver
    @Binding var isEditingText: Bool
    @Binding var value: Value?
    
    private let inputItem: TextInputItem
    
    init(value bindingValue: Binding<Value?>,
         isEditing: Binding<Bool>,
         inputItem: TextInputItem? = nil) {
        self.inputItem = inputItem ?? ((Value.self == Int.self) ? IntegerTextInputItemObject() : DoubleTextInputItemObject())
        self._value = bindingValue
        self._isEditingText = isEditing
    }
    
    var body: some View {
        ZStack {
            #if canImport(UIKit)
            NumericTextFieldContainer($value, isEditingText: $isEditingText, inputItem: inputItem)
                .padding(.horizontal)
                .accentColor(.sageBlack)
            #endif
        }
        .background(isEditingText ? surveyTint : Color.sageWhite)
        .border(Color.sageBlack, width: 1)
        .onChange(of: isEditingText) { newValue in
            keyboard.keyboardFocused = newValue
        }
    }
}

struct PreviewNumericTextField: View {
    @State var value: Int?
    @State var isEditing: Bool = false
    
    var body: some View {
        VStack {
            NumericTextField(value: $value, isEditing: $isEditing)
                .border(Color.sageBlack, width: 1)
            NumericTextField(value: $value, isEditing: $isEditing,
                             inputItem: IntegerTextInputItemObject(formatOptions: .init(minimumValue: 0, maximumValue: 100)))
                .border(Color.sageBlack, width: 1)
        }
        .padding(.horizontal, 64)
    }
}

struct NumericTextField_Previews: PreviewProvider {
    static var previews: some View {
        PreviewNumericTextField()
    }
}

#if canImport(UIKit)

fileprivate struct NumericTextFieldContainer<Value : JsonNumber>: UIViewRepresentable where Value : JsonValue {
    private let inputItem: TextInputItem
    private let validator: TextEntryValidator
    private var value: Binding<Value?>
    private var isEditingText: Binding<Bool>

    init(_ bindingValue: Binding<Value?>, isEditingText: Binding<Bool>, inputItem: TextInputItem) {
        self.inputItem = inputItem
        self.validator = inputItem.buildTextValidator()
        self.value = bindingValue
        self.isEditingText = isEditingText
    }

    func makeCoordinator() -> NumericTextFieldContainer.Coordinator {
        Coordinator(self)
    }

    func makeUIView(context: UIViewRepresentableContext<NumericTextFieldContainer>) -> UITextField {

        let backingView = UITextField(frame: .zero)
        backingView.text = backingViewText()
        backingView.placeholder = inputItem.placeholder
        backingView.delegate = context.coordinator
        backingView.backgroundColor = .clear
        backingView.font = .textField
        backingView.adjustsFontForContentSizeCategory = true
        backingView.textColor = .textForeground
        
        // Set up keyboard options
        backingView.autocapitalizationType = .none
        backingView.autocorrectionType = .no
        backingView.keyboardType = inputItem.keyboardOptions.keyboardType.uiType
        
        // Add done button
        let doneToolbar: UIToolbar = UIToolbar(frame: CGRect.init(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 50))
        doneToolbar.barStyle = .default
        let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let doneTitle = NSLocalizedString("Done", bundle: .module, comment: "Done button for entering text")
        let done: UIBarButtonItem = UIBarButtonItem(title: doneTitle, style: .done, target: nil, action: nil)
        doneToolbar.items = [flexSpace, done]
        doneToolbar.sizeToFit()
        backingView.inputAccessoryView = doneToolbar
        done.target = backingView
        done.action = #selector( backingView.resignFirstResponder )

        return backingView
    }

    func updateUIView(_ uiView: UITextField, context: UIViewRepresentableContext<NumericTextFieldContainer>) {
        uiView.text = backingViewText()
        uiView.inputAccessoryView?.tintColor = uiView.tintColor
    }
    
    func backingViewText() -> String {
        validator.localizedText(for: value.wrappedValue) ?? ""
    }

    class Coordinator: NSObject, UITextFieldDelegate {
        var parent: NumericTextFieldContainer

        init(_ textFieldContainer: NumericTextFieldContainer) {
            self.parent = textFieldContainer
        }
        
        @objc func textFieldDidBeginEditing(_ textField: UITextField) {
            parent.isEditingText.wrappedValue = true
        }
        
        @objc func textFieldDidEndEditing(_ textField: UITextField) {
            parent.isEditingText.wrappedValue = false
        }
        
        @objc func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
            let newString = NSString(string: textField.text!).replacingCharacters(in: range, with: string)
            do {
                parent.value.wrappedValue = try parent.validator.bindingValue(for: newString) as? Value
                return true
            }
            catch {
                return false
            }
        }
    }
}

#endif

//
//  TextInputItems.swift
//  
//

import Foundation
import JsonModel
import ResultModel

/// An ``TextInputItem`` describes input entry that is freeform with ranges and validation. Typically, this is
/// presented as a text field, but depending upon the requirements of the survey designer, it may use a slider,
/// Likert scale, date picker, or other custom UI/UX to allow for validation of the entered value.
public protocol TextInputItem : InputItem, PolymorphicTyped {

    /// Options for displaying a text field. This is only applicable for certain types of UI hints
    /// and data types. If not applicable, it will be ignored.
    var keyboardOptions: KeyboardOptions { get }
    
    /// A localized string that displays a short text offering a hint to the user of the data to be entered for this field.
    var fieldLabel: String? { get }

    /// A localized string that displays placeholder information for the ``InputItem``.
    ///
    /// You can display placeholder text in a text field or text area to help users understand how to answer the item's
    /// question. If the input field brings up another view to enter the answer, this could also be used at the button title.
    var placeholder: String? { get }

    /// This can be used to return a class used to format and/or validate the text input.
    func buildTextValidator() -> TextEntryValidator
}

public protocol StringTextInputItem : TextInputItem {
    var characterLimit: Int? { get }
}

public protocol IntegerTextInputItem : TextInputItem {
    var range: IntegerRange? { get }
}

public protocol DoubleTextInputItem : TextInputItem {
    var range: DoubleRange? { get }
}

public protocol DurationTextInputItem : TextInputItem {
    var displayUnits: [DurationUnit] { get }
}

public protocol TimeTextInputItem : TextInputItem {
    var range: TimeRange  { get }
}

public final class TextInputItemSerializer : GenericPolymorphicSerializer<TextInputItem>, DocumentableInterface {
    public var documentDescription: String? {
        """
        A `TextInputItem` describes input entry that is freeform with ranges and validation.
        Typically, this is presented as a text field, but depending upon the requirements of the
        survey designer, it may use a slider, Likert scale, date picker, or other custom UI/UX to
        allow for validation of the entered value.
        """.replacingOccurrences(of: "\n", with: " ").replacingOccurrences(of: "  ", with: "\n")
    }
    
    public var jsonSchema: URL {
        URL(string: "\(AssessmentFactory.defaultFactory.modelName(for: self.interfaceName)).json", relativeTo: kBDHJsonSchemaBaseURL)!
    }
    
    override init() {
        super.init([
            DoubleTextInputItemObject(),
            DurationTextInputItemObject(),
            IntegerTextInputItemObject(),
            StringTextInputItemObject(),
            TimeTextInputItemObject(),
            YearTextInputItemObject(),
        ])
    }
    
    private enum InterfaceKeys : String, OrderedEnumCodingKey, OpenOrderedCodingKey {
        case resultIdentifier = "identifier", fieldLabel, placeholder
        var relativeIndex: Int { 1 }
    }
    
    public override class func codingKeys() -> [CodingKey] {
        var keys = super.codingKeys()
        keys.append(contentsOf: InterfaceKeys.allCases)
        return keys
    }
    
    public override class func documentProperty(for codingKey: CodingKey) throws -> DocumentProperty {
        guard let key = codingKey as? InterfaceKeys else {
            return try super.documentProperty(for: codingKey)
        }
        switch key {
        case .resultIdentifier:
            return .init(propertyType: .primitive(.string), propertyDescription:
                            """
                            The result identifier is an optional value that can be used to help in building the serializable answer result
                            from this ``InputItem``. If null, then it is assumed that the ``Question`` that holds this ``InputItem``
                            has some custom serialization strategy or only contains a single field and this property can be ignored.
                            """.replacingOccurrences(of: "\n", with: " ").replacingOccurrences(of: "  ", with: "\n"))
        case .fieldLabel:
            return .init(propertyType: .primitive(.string), propertyDescription:
                            "A localized string that displays a short text offering a hint to the user of the data to be entered for this field.")
        case .placeholder:
            return .init(propertyType: .primitive(.string), propertyDescription:
                            "A localized string that displays placeholder information for the ``InputItem``.")
        }
    }
}

@available(*, deprecated, message: "Use TextInputItem directly")
public protocol SerializableTextInputItem : TextInputItem, PolymorphicTyped, Codable {
    var textInputType: TextInputType { get }
}

@available(*, deprecated, message: "Use TextInputItem directly")
public extension SerializableTextInputItem {
    var typeName: String { return textInputType.rawValue }
}

@available(*, deprecated, message: "Use @SerialName")
public enum TextInputType : String, StringEnumSet, DocumentableStringEnum {
    case number, integer, string, year, duration, time
}

@Serializable
@SerialName("string")
public struct StringTextInputItemObject : StringTextInputItem, Codable {

    @Transient public let answerType: AnswerType = AnswerTypeString()
    
    public let fieldLabel: String?
    public let placeholder: String?
    @SerialName("identifier") public let resultIdentifier: String?
    public let characterLimit: Int?
    @SerialName("keyboardOptions") private var _keyboardOptions: KeyboardOptionsObject?
    private let regExValidator: RegExValidator?
    
    public var keyboardOptions: KeyboardOptions {
        return _keyboardOptions ?? KeyboardOptionsObject()
    }
    
    public func buildTextValidator() -> TextEntryValidator {
        regExValidator ?? PassThruValidator()
    }
    
    public init(fieldLabel: String? = nil, placeholder: String? = nil, resultIdentifier: String? = nil, keyboardOptions: KeyboardOptionsObject? = nil, regExValidator: RegExValidator? = nil, characterLimit: Int? = nil) {
        self.fieldLabel = fieldLabel
        self.placeholder = placeholder
        self.resultIdentifier = resultIdentifier
        self.characterLimit = characterLimit
        self._keyboardOptions = keyboardOptions
        self.regExValidator = regExValidator
    }
}

extension StringTextInputItemObject : DocumentableStruct {

    public static func codingKeys() -> [CodingKey] {
        CodingKeys.allCases
    }
    
    public static func isRequired(_ codingKey: CodingKey) -> Bool {
        codingKey.stringValue == "type"
    }
    
    public static func documentProperty(for codingKey: CodingKey) throws -> DocumentProperty {
        guard let key = codingKey as? CodingKeys else {
            throw DocumentableError.invalidCodingKey(codingKey, "\(codingKey) is not handled by \(self).")
        }
        switch key {
        case .typeName:
            return .init(constValue: serialTypeName)
        case .resultIdentifier, .fieldLabel, .placeholder:
            return .init(propertyType: .primitive(.string))
        case ._keyboardOptions:
            return .init(propertyType: .reference(KeyboardOptionsObject.documentableType()), propertyDescription:
                            "The keyboard options to use with this text field.")
        case .regExValidator:
            return .init(propertyType: .reference(RegExValidator.documentableType()), propertyDescription:
                            "The regex validator to use to validate this text field.")
        case .characterLimit:
            return .init(propertyType: .primitive(.integer), propertyDescription:
                            "The character limit for text entry.")
        }
    }
    
    public static func examples() -> [StringTextInputItemObject] {
        [.init()]
    }
}

@Serializable
@SerialName("integer")
public struct IntegerTextInputItemObject : IntegerTextInputItem, Codable {

    @Transient public let answerType: AnswerType = AnswerTypeInteger()
    
    public let fieldLabel: String?
    public let placeholder: String?
    @SerialName("identifier") public let resultIdentifier: String?
    public let formatOptions: IntegerFormatOptions?

    public var keyboardOptions: KeyboardOptions {
        return KeyboardOptionsObject.integerEntryOptions
    }

    public var range: IntegerRange? {
        return formatOptions
    }
    
    public init(fieldLabel: String? = nil,
                placeholder: String? = nil,
                resultIdentifier: String? = nil,
                formatOptions: IntegerFormatOptions? = nil) {
        self.fieldLabel = fieldLabel
        self.placeholder = placeholder
        self.resultIdentifier = resultIdentifier
        self.formatOptions = formatOptions
    }
    
    public func buildTextValidator() -> TextEntryValidator {
        return formatOptions ?? IntegerFormatOptions()
    }
}

extension IntegerTextInputItemObject : DocumentableStruct {

    public static func codingKeys() -> [CodingKey] {
        CodingKeys.allCases
    }
    
    public static func isRequired(_ codingKey: CodingKey) -> Bool {
        codingKey.stringValue == "type"
    }
    
    public static func documentProperty(for codingKey: CodingKey) throws -> DocumentProperty {
        guard let key = codingKey as? CodingKeys else {
            throw DocumentableError.invalidCodingKey(codingKey, "\(codingKey) is not handled by \(self).")
        }
        switch key {
        case .typeName:
            return .init(constValue: serialTypeName)
        case .resultIdentifier, .fieldLabel, .placeholder:
            return .init(propertyType: .primitive(.string))
        case .formatOptions:
            return .init(propertyType: .reference(IntegerFormatOptions.documentableType()), propertyDescription:
                            "The formatting and range options to use with input item.")
        }
    }
    
    public static func examples() -> [IntegerTextInputItemObject] {
        [.init()]
    }
}

@Serializable
@SerialName("number")
public struct DoubleTextInputItemObject : DoubleTextInputItem, Codable {
    public var answerType: AnswerType {
        AnswerTypeNumber(significantDigits: formatOptions?.significantDigits)
    }
    
    public let fieldLabel: String?
    public let placeholder: String?
    @SerialName("identifier") public let resultIdentifier: String?
    public let formatOptions: DoubleFormatOptions?

    public var keyboardOptions: KeyboardOptions {
        KeyboardOptionsObject.decimalEntryOptions
    }
    
    public var range: DoubleRange? { formatOptions }
    
    public init(fieldLabel: String? = nil,
                placeholder: String? = nil,
                resultIdentifier: String? = nil,
                formatOptions: DoubleFormatOptions? = nil) {
        self.fieldLabel = fieldLabel
        self.placeholder = placeholder
        self.resultIdentifier = resultIdentifier
        self.formatOptions = formatOptions
    }
    
    public func buildTextValidator() -> TextEntryValidator {
        formatOptions ?? DoubleFormatOptions()
    }
}

extension DoubleTextInputItemObject : DocumentableStruct {

    public static func codingKeys() -> [CodingKey] {
        CodingKeys.allCases
    }
    
    public static func isRequired(_ codingKey: CodingKey) -> Bool {
        codingKey.stringValue == "type"
    }
    
    public static func documentProperty(for codingKey: CodingKey) throws -> DocumentProperty {
        guard let key = codingKey as? CodingKeys else {
            throw DocumentableError.invalidCodingKey(codingKey, "\(codingKey) is not handled by \(self).")
        }
        switch key {
        case .typeName:
            return .init(constValue: serialTypeName)
        case .resultIdentifier, .fieldLabel, .placeholder:
            return .init(propertyType: .primitive(.string))
        case .formatOptions:
            return .init(propertyType: .reference(DoubleFormatOptions.documentableType()), propertyDescription:
                            "The formatting and range options to use with input item.")
        }
    }
    
    public static func examples() -> [DoubleTextInputItemObject] {
        [.init()]
    }
}

@Serializable
@SerialName("duration")
public struct DurationTextInputItemObject : DurationTextInputItem, Codable {
    public var answerType: AnswerType {
        AnswerTypeDuration(displayUnits: displayUnits)
    }
    
    public let fieldLabel: String?
    public let placeholder: String?
    @SerialName("identifier") public let resultIdentifier: String?
    public var displayUnits: [DurationUnit] = DurationUnit.defaultDispayUnits

    public var keyboardOptions: KeyboardOptions {
        KeyboardOptionsObject.integerEntryOptions
    }
    
    public func buildTextValidator() -> TextEntryValidator {
        DoubleFormatOptions()
    }
}

extension DurationTextInputItemObject : DocumentableStruct {

    public static func codingKeys() -> [CodingKey] {
        CodingKeys.allCases
    }
    
    public static func isRequired(_ codingKey: CodingKey) -> Bool {
        codingKey.stringValue == "type"
    }
    
    public static func documentProperty(for codingKey: CodingKey) throws -> DocumentProperty {
        guard let key = codingKey as? CodingKeys else {
            throw DocumentableError.invalidCodingKey(codingKey, "\(codingKey) is not handled by \(self).")
        }
        switch key {
        case .typeName:
            return .init(constValue: serialTypeName)
        case .resultIdentifier, .fieldLabel, .placeholder:
            return .init(propertyType: .primitive(.string))
        case .displayUnits:
            return .init(propertyType: .referenceArray(DurationUnit.documentableType()), propertyDescription:
                            "The display units to show for duration.")
        }
    }
    
    public static func examples() -> [DurationTextInputItemObject] {
        [.init()]
    }
}

@Serializable
@SerialName("year")
public struct YearTextInputItemObject : IntegerTextInputItem, Codable {
    
    @Transient public let answerType: AnswerType = AnswerTypeInteger()
    
    public let fieldLabel: String?
    public let placeholder: String?
    @SerialName("identifier") public let resultIdentifier: String?

    public var keyboardOptions: KeyboardOptions {
        KeyboardOptionsObject.integerEntryOptions
    }

    public let formatOptions: YearFormatOptions?
    
    public var range: IntegerRange? { formatOptions }
    
    public init(fieldLabel: String? = nil,
                placeholder: String? = "YYYY",
                resultIdentifier: String? = nil,
                formatOptions: YearFormatOptions? = nil) {
        self.fieldLabel = fieldLabel
        self.placeholder = placeholder
        self.resultIdentifier = resultIdentifier
        self.formatOptions = formatOptions
    }
    
    public func buildTextValidator() -> TextEntryValidator {
        formatOptions ?? YearFormatOptions()
    }
}

extension YearTextInputItemObject : DocumentableStruct {

    public static func codingKeys() -> [CodingKey] {
        CodingKeys.allCases
    }
    
    public static func isRequired(_ codingKey: CodingKey) -> Bool {
        codingKey.stringValue == "type"
    }
    
    public static func documentProperty(for codingKey: CodingKey) throws -> DocumentProperty {
        guard let key = codingKey as? CodingKeys else {
            throw DocumentableError.invalidCodingKey(codingKey, "\(codingKey) is not handled by \(self).")
        }
        switch key {
        case .typeName:
            return .init(constValue: serialTypeName)
        case .resultIdentifier, .fieldLabel, .placeholder:
            return .init(propertyType: .primitive(.string))
        case .formatOptions:
            return .init(propertyType: .reference(YearFormatOptions.documentableType()), propertyDescription:
                            "The formatting and range options to use with input item.")
        }
    }
    
    public static func examples() -> [YearTextInputItemObject] {
        [.init()]
    }
}

@Serializable
@SerialName("time")
public struct TimeTextInputItemObject : TimeTextInputItem, Codable {
    
    @Transient public let answerType: AnswerType = AnswerTypeInteger()
    
    public let fieldLabel: String?
    public let placeholder: String?
    @SerialName("identifier") public let resultIdentifier: String?

    public var keyboardOptions: KeyboardOptions {
        KeyboardOptionsObject.dateTimeEntryOptions
    }

    public let formatOptions: TimeFormatOptions?
    
    public var range: TimeRange { formatOptions ?? TimeFormatOptions() }
    
    public init(fieldLabel: String? = nil,
                placeholder: String? = nil,
                resultIdentifier: String? = nil,
                formatOptions: TimeFormatOptions? = nil) {
        self.fieldLabel = fieldLabel
        self.placeholder = placeholder
        self.resultIdentifier = resultIdentifier
        self.formatOptions = formatOptions
    }
    
    public func buildTextValidator() -> TextEntryValidator {
        PassThruValidator()
    }
}

extension TimeTextInputItemObject : DocumentableStruct {

    public static func codingKeys() -> [CodingKey] {
        CodingKeys.allCases
    }
    
    public static func isRequired(_ codingKey: CodingKey) -> Bool {
        codingKey.stringValue == "type"
    }
    
    public static func documentProperty(for codingKey: CodingKey) throws -> DocumentProperty {
        guard let key = codingKey as? CodingKeys else {
            throw DocumentableError.invalidCodingKey(codingKey, "\(codingKey) is not handled by \(self).")
        }
        switch key {
        case .typeName:
            return .init(constValue: serialTypeName)
        case .resultIdentifier, .fieldLabel, .placeholder:
            return .init(propertyType: .primitive(.string))
        case .formatOptions:
            return .init(propertyType: .reference(TimeFormatOptions.documentableType()), propertyDescription:
                            "The formatting and range options to use with input item.")
        }
    }
    
    public static func examples() -> [TimeTextInputItemObject] {
        [.init()]
    }
}

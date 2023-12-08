//
//  NodeSerializer.swift
//  
//

import Foundation
import JsonModel
import ResultModel

/// `SerializableNode` is the base implementation for `Node` that is serialized using
/// the `Codable` protocol and the polymorphic serialization defined by this framework.
///
public protocol SerializableNode : Node, Decodable {
    var serializableType: SerializableNodeType { get }
}

extension SerializableNode {
    public var typeName: String { serializableType.stringValue }
}

/// `SerializableNodeType` is an extendable string enum used by the `SerializationFactory` to
/// create the appropriate result type.
public struct SerializableNodeType : TypeRepresentable, Codable, Hashable {
    
    public let rawValue: String
    
    public init(rawValue: String) {
        self.rawValue = rawValue
    }
    
    public enum StandardTypes : String, CaseIterable {
        case assessment, section
        case completion, instruction, overview
        case choiceQuestion, simpleQuestion
        case countdown, permission

        public var nodeType: SerializableNodeType {
            .init(rawValue: self.rawValue)
        }
    }
    
    /// List of all the standard types.
    public static func allStandardTypes() -> [SerializableNodeType] {
        StandardTypes.allCases.map { $0.nodeType }
    }
}

extension SerializableNodeType : ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        self.init(rawValue: value)
    }
}

extension SerializableNodeType : DocumentableStringLiteral {
    public static func examples() -> [String] {
        return allStandardTypes().map{ $0.rawValue }
    }
}

public final class NodeSerializer : GenericPolymorphicSerializer<Node>, DocumentableInterface {
    public var documentDescription: String? {
        """
        The interface for any `Node` that is serialized using the `Codable` protocol and the
        polymorphic serialization defined by this framework.
        """.replacingOccurrences(of: "\n", with: " ").replacingOccurrences(of: "  ", with: "\n")
    }
    
    public var jsonSchema: URL {
        URL(string: "\(self.interfaceName).json", relativeTo: kBDHJsonSchemaBaseURL)!
    }
    
    override init() {
        super.init([
            AssessmentObject.examples().first!,
            ChoiceQuestionStepObject.examples().first!,
            CompletionStepObject.examples().first!,
            CountdownStepObject.examples().first!,
            InstructionStepObject.examples().first!,
            OverviewStepObject.examples().first!,
            PermissionStepObject.examples().first!,
            SectionObject.examples().first!,
            SimpleQuestionStepObject.examples().first!,
            TransformableNode()
        ])
    }
    
    private enum InterfaceKeys : String, OrderedEnumCodingKey, OpenOrderedCodingKey {
        case identifier
        var relativeIndex: Int { 1 }
    }
    
    public override class func codingKeys() -> [CodingKey] {
        var keys = super.codingKeys()
        keys.append(contentsOf: InterfaceKeys.allCases)
        return keys
    }
    
    public override class func isRequired(_ codingKey: CodingKey) -> Bool {
        return (codingKey is InterfaceKeys) || super.isRequired(codingKey)
    }
    
    public override class func documentProperty(for codingKey: CodingKey) throws -> DocumentProperty {
        return .init(propertyType: .primitive(.string), propertyDescription:
                        "The identifier for the node. This will map to the identifier for the result")
    }
}

open class AbstractNodeObject : SerializableNode {
    private enum CodingKeys : String, OrderedEnumCodingKey, OpenOrderedCodingKey {
        case serializableType="type", identifier, comment, shouldHideButtons="shouldHideActions", buttonMap="actions", nextNode = "nextStepIdentifier", webConfig
        var relativeIndex: Int { 2 }
    }
    public private(set) var serializableType: SerializableNodeType = .init(rawValue: "null")
    
    public let identifier: String
    public let comment: String?
    var webConfig: JsonElement?
    
    /// List of button actions that should be hidden for this node even if the node subtype typically supports displaying
    /// the button on screen. This property can be defined at any level and will default to whichever is the lowest level
    /// for which this mapping is defined.
    public let shouldHideButtons: Set<ButtonType>
    
    /// A mapping of a ``ButtonAction`` to a ``ButtonActionInfo``.
    ///
    /// For example, this mapping can be used to  to customize the title of the ``ButtonAction.navigation(.goForward)``
    /// button. It can also define the title, icon, etc. on a custom button as long as the application knows how to
    /// interpret the custom action.
    ///
    /// Finally, a mapping can be used to explicitly mark a button as "should display" even if the overall assessment or
    /// section includes the button action in the list of hidden buttons. For example, an assessment may define the
    /// skip button as hidden but a lower level step within that assessment's hierarchy can return a mapping for the
    /// skip button. The lower level mapping should be respected and the button should be displayed for that step only.
    public let buttonMap: [ButtonType : ButtonActionInfo]
    
    /// The identifier for the node that the navigator should move to next. This is included in the base class so that branches
    /// can set up next node logic for direct navigation.
    public let nextNode: NavigationIdentifier?
    
    open class func defaultType() -> SerializableNodeType {
        fatalError("The default type *must* be overriden for this abstract class")
    }
    
    /// Default implementation is to return a ``ResultObject``.
    open func instantiateResult() -> ResultData {
        ResultObject(identifier: self.identifier)
    }
    
    open func button(_ buttonType: ButtonType, node: Node) -> ButtonActionInfo? {
        ((node as? AbstractNodeObject) === self) ? buttonMap[buttonType] : nil
    }
    
    open func shouldHideButton(_ buttonType: ButtonType, node: Node) -> Bool? {
        ((node as? AbstractNodeObject) === self) ? shouldHideButtons.contains(buttonType) : nil
    }
    
    open func nextNodeIdentifier(branchResult: BranchNodeResult, isPeeking: Bool) -> NavigationIdentifier? {
        nextNode
    }
    
    public init(identifier: String,
                shouldHideButtons: Set<ButtonType>? = nil,
                buttonMap: [ButtonType : ButtonActionInfo]? = nil,
                comment: String? = nil,
                nextNode: NavigationIdentifier? = nil) {
        self.identifier = identifier
        self.comment = comment
        self.nextNode = nextNode
        self.shouldHideButtons = shouldHideButtons ?? []
        self.buttonMap = buttonMap ?? [:]
        self.serializableType = Self.defaultType()
    }
    
    public init(identifier: String, copyFrom object: AbstractNodeObject) {
        self.identifier = identifier
        self.comment = object.comment
        self.nextNode = object.nextNode
        self.shouldHideButtons = object.shouldHideButtons
        self.buttonMap = object.buttonMap
        self.serializableType = Self.defaultType()
    }

    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.serializableType = Self.defaultType()
        self.identifier = try container.decode(String.self, forKey: .identifier)
        self.comment = try container.decodeIfPresent(String.self, forKey: .comment)
        self.nextNode = try container.decodeIfPresent(NavigationIdentifier.self, forKey: .nextNode)
        self.shouldHideButtons = try container.decodeIfPresent(Set<ButtonType>.self, forKey: .shouldHideButtons) ?? []
        if container.contains(.buttonMap) {
            let nestedDecoder = try container.superDecoder(forKey: .buttonMap)
            let nestedContainer = try nestedDecoder.container(keyedBy: AnyCodingKey.self)
            var buttonMap = [ButtonType : ButtonActionInfo]()
            for key in nestedContainer.allKeys {
                let objectDecoder = try nestedContainer.superDecoder(forKey: key)
                let actionType = ButtonType(rawValue: key.stringValue)
                let action = try decoder.serializationFactory.decodePolymorphicObject(ButtonActionInfo.self, from: objectDecoder)
                buttonMap[actionType] = action
            }
            self.buttonMap = buttonMap
        }
        else {
            self.buttonMap = [:]
        }
    }

    /// Define the encoder, but do not require protocol conformance of subclasses.
    /// - parameter encoder: The encoder to use to encode this instance.
    /// - throws: `EncodingError`
    open func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(serializableType, forKey: .serializableType)
        try container.encode(identifier, forKey: .identifier)
        try container.encodeIfPresent(comment, forKey: .comment)
        try container.encodeIfPresent(nextNode, forKey: .nextNode)
        
        if self.buttonMap.count > 0 {
            var nestedContainer = container.nestedContainer(keyedBy: ButtonType.self, forKey: .buttonMap)
            try self.buttonMap.forEach { (key, action) in
                guard let encodableAction = action as? Encodable else { return }
                let objectEncoder = nestedContainer.superEncoder(forKey: key)
                try encodableAction.encode(to: objectEncoder)
            }
        }
        if self.shouldHideButtons.count > 0 {
            try container.encode(self.shouldHideButtons, forKey: .shouldHideButtons)
        }
    }

    // DocumentableObject implementation
    
    class func supportsNextNode() -> Bool {
        true
    }

    open class func codingKeys() -> [CodingKey] {
        var keys = CodingKeys.allCases
        if !supportsNextNode() {
            keys.removeAll(where: { $0 == .nextNode })
        }
        return keys
    }

    open class func isRequired(_ codingKey: CodingKey) -> Bool {
        guard let key = codingKey as? CodingKeys else {
            return false
        }
        return (key == .identifier) || (key == .serializableType)
    }

    open class func documentProperty(for codingKey: CodingKey) throws -> DocumentProperty {
        guard let key = codingKey as? CodingKeys else {
            throw DocumentableError.invalidCodingKey(codingKey, "\(codingKey) is not handled by \(self).")
        }
        switch key {
        case .serializableType:
            return .init(constValue: defaultType())
        case .identifier:
            return .init(propertyType: .primitive(.string))
        case .comment:
            return .init(propertyType: .primitive(.string), propertyDescription:
                            "A developer-facing comment about this node.")
        case .buttonMap:
            return .init(propertyType: .interfaceDictionary("\(ButtonActionInfo.self)"), propertyDescription:
                            "A mapping of button action to content information for that button.")
        case .shouldHideButtons:
            return .init(propertyType: .referenceArray(ButtonType.documentableType()), propertyDescription:
                            "A list of buttons that should be hidden even if the default is to show them.")
        case .nextNode:
            return .init(propertyType: .reference(NavigationIdentifier.documentableType()), propertyDescription:
                            "Used in direct navigation to allow the node to indicate that the navigator should jump to the given node identifier.")
        case .webConfig:
            return .init(propertyType: .any, propertyDescription:
                            "A blob of JSON that can be used by a web-based survey building tool.")
        }
    }
}

open class AbstractContentNodeObject : AbstractNodeObject, ContentNode {
    private enum CodingKeys : String, OrderedEnumCodingKey, OpenOrderedCodingKey {
        case title, subtitle, detail, imageInfo = "image"
        var relativeIndex: Int { 4 }
    }
    
    open private(set) var title: String?
    open private(set) var subtitle: String?
    open private(set) var detail: String?
    open private(set) var imageInfo: ImageInfo?
    
    public init(identifier: String,
                title: String? = nil, subtitle: String? = nil, detail: String? = nil, imageInfo: ImageInfo? = nil,
                shouldHideButtons: Set<ButtonType>? = nil, buttonMap: [ButtonType : ButtonActionInfo]? = nil, comment: String? = nil, nextNode: NavigationIdentifier? = nil) {
        self.title = title
        self.subtitle = subtitle
        self.detail = detail
        self.imageInfo = imageInfo
        super.init(identifier: identifier, shouldHideButtons: shouldHideButtons, buttonMap: buttonMap, comment: comment, nextNode: nextNode)
    }
    
    public init(identifier: String, copyFrom object: AbstractContentNodeObject) {
        self.title = object.title
        self.subtitle = object.subtitle
        self.detail = object.detail
        self.imageInfo = object.imageInfo
        super.init(identifier: identifier, copyFrom: object)
    }
    
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.title = try container.decodeIfPresent(String.self, forKey: .title)
        self.subtitle = try container.decodeIfPresent(String.self, forKey: .subtitle)
        self.detail = try container.decodeIfPresent(String.self, forKey: .detail)
        if container.contains(.imageInfo) {
            let nestedDecoder = try container.superDecoder(forKey: .imageInfo)
            self.imageInfo = try decoder.serializationFactory.decodePolymorphicObject(ImageInfo.self, from: nestedDecoder)
        }
        else {
            self.imageInfo = nil
        }
        try super.init(from: decoder)
    }
    
    open override func encode(to encoder: Encoder) throws {
        try super.encode(to: encoder)
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(title, forKey: .title)
        try container.encodeIfPresent(subtitle, forKey: .subtitle)
        try container.encodeIfPresent(detail, forKey: .detail)
        try encodeObject(object: self.imageInfo, to: encoder, forKey: CodingKeys.imageInfo)
    }
    
    override open class func codingKeys() -> [CodingKey] {
        var keys = super.codingKeys()
        keys.append(contentsOf: CodingKeys.allCases)
        return keys
    }

    override open class func documentProperty(for codingKey: CodingKey) throws -> DocumentProperty {
        guard let key = codingKey as? CodingKeys else {
            return try super.documentProperty(for: codingKey)
        }
        switch key {
        case .title:
            return .init(propertyType: .primitive(.string), propertyDescription:
                            "The primary text to display for the node in a localized string. The UI should display this using a larger font.")
        case .subtitle:
            return .init(propertyType: .primitive(.string), propertyDescription:
                            "A subtitle to display for the node in a localized string.")
        case .detail:
            return .init(propertyType: .primitive(.string), propertyDescription:
                            "Detail text to display for the node in a localized string.")
        case .imageInfo:
            return .init(propertyType: .interface("\(ImageInfo.self)"), propertyDescription:
                            "An image or animation to display with this node.")
        }
    }
}

open class AbstractStepObject : AbstractContentNodeObject, ContentStep, NavigationRule {
    /// Default implementation returns `nil`.
    open func spokenInstruction(at timeInterval: TimeInterval) -> String? {
        nil
    }
}

internal func encodeObject<Key>(object: Any?, to encoder: Encoder, forKey: Key) throws where Key : CodingKey {
    guard let obj = object else { return }
    guard let encodable = obj as? Encodable else {
        var codingPath = encoder.codingPath
        codingPath.append(forKey)
        let context = EncodingError.Context(codingPath: codingPath, debugDescription: "\(obj) does not conform to the `Encodable` protocol")
        throw EncodingError.invalidValue(obj, context)
    }
    var container = encoder.container(keyedBy: Key.self)
    let nestedEncoder = container.superEncoder(forKey: forKey)
    try encodable.encode(to: nestedEncoder)
}

struct TransformableNode : SerializableNode {
    var serializableType: SerializableNodeType { .init(rawValue: "transform")}
    let identifier: String
    let node: Node
    
    init() {
        self.identifier = "example"
        self.node = InstructionStepObject(identifier: "example")
    }
    
    private enum CodingKeys : String, CodingKey {
        case identifier, resourceName
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let identifier = try container.decode(String.self, forKey: .identifier)
        let resourceName = try container.decode(String.self, forKey: .resourceName)
        guard let bundle = decoder.bundle as? Bundle,
              let url = bundle.url(forResource: resourceName, withExtension: "json")
        else {
            throw DecodingError.dataCorrupted(.init(codingPath: decoder.codingPath, debugDescription: "Cannot find file in expected bundle."))
        }
        let data = try Data(contentsOf: url)
        let jsonDecoder = decoder.serializationFactory.createJSONDecoder()
        let wrapper = try jsonDecoder.decode(NodeWrapper.self, from: data)
        self.node = ((wrapper.node as? CopyWithIdentifier)?.copy(with: identifier) as? Node) ?? wrapper.node
        self.identifier = identifier
    }
    
    struct NodeWrapper : Decodable {
        let node: Node
        init(from decoder: Decoder) throws {
            self.node = try decoder.serializationFactory.decodePolymorphicObject(Node.self, from: decoder)
        }
    }
    
    var comment: String? { nil }
    
    func instantiateResult() -> ResultData {
        ResultObject(identifier: identifier)
    }
    
    func button(_ buttonType: ButtonType, node: Node) -> ButtonActionInfo? {
        nil
    }
    
    func shouldHideButton(_ buttonType: ButtonType, node: Node) -> Bool? {
        nil
    }

}


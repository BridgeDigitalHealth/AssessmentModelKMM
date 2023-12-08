//
//  AssessmentModelTests.swift
//  

import XCTest
@testable import JsonModel
@testable import ResultModel
@testable import AssessmentModel

class AssessmentModelTests: XCTestCase {
    
    let factory = AssessmentFactory()
    
    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        
        // Use a statically defined timezone.
        ISO8601TimestampFormatter.timeZone = TimeZone(secondsFromGMT: Int(-2.5 * 60 * 60))
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    func testCreateJsonSchemaDocumentation() {
        let doc = JsonDocumentBuilder(factory: factory)
        
        do {
            let schemas = try doc.buildSchemas()

            XCTAssertEqual(schemas.count, 14)
            
            checkAnswerTypeSchema(schemas)
            checkButtonActionInfoSchema(schemas)
            checkImageInfoSchema(schemas)
            checkNodeSchema(schemas)
            checkResultDataSchema(schemas)
            checkTextInputItemSchema(schemas)
    
        }
        catch let err {
            XCTFail("Failed to build the JsonSchema: \(err)")
        }
    }
    
    func checkAnswerTypeSchema(_ schemas: [JsonSchema]) {
        guard let answerTypeSchema = schemas.first(where: { $0.id.className == "AnswerType" })
        else {
            XCTFail("Failed to build the expected JSON schema for `AnswerType`.")
            return
        }
        
        let expectedAnswerTypeClassAndType = [
            ("AnswerTypeMeasurement","measurement"),
            ("AnswerTypeDateTime","date-time"),
            ("AnswerTypeArray","array"),
            ("AnswerTypeBoolean","boolean"),
            ("AnswerTypeInteger","integer"),
            ("AnswerTypeNumber","number"),
            ("AnswerTypeObject","object"),
            ("AnswerTypeString","string"),
        ]
        expectedAnswerTypeClassAndType.forEach {
            guard let _ = checkDefinitions(on: answerTypeSchema,
                                           className: $0.0,
                                           expectedType: $0.1,
                                           sharedKeys: [],
                                           expectedSerializableType: "AnswerTypeType")
            else {
                XCTFail("Unexpected nil for \($0.0)")
                return
            }
        }
    }
    
    func checkButtonActionInfoSchema(_ schemas: [JsonSchema]) {
        guard let schema = schemas.first(where: { $0.id.className == "ButtonActionInfo" })
        else {
            XCTFail("Failed to build the expected JSON schema for `ButtonActionInfo`.")
            return
        }
        
        let expectedAnswerTypeClassAndType = [
            ("ButtonActionInfoObject","default"),
        ]
        expectedAnswerTypeClassAndType.forEach {
            guard let _ = checkDefinitions(on: schema,
                                           className: $0.0,
                                           expectedType: $0.1,
                                           sharedKeys: ["buttonTitle", "iconName", "bundleIdentifier", "packageName"],
                                           expectedSerializableType: "ButtonActionInfoType")
            else {
                XCTFail("Unexpected nil for \($0.0)")
                return
            }
        }
    }
    
    func checkImageInfoSchema(_ schemas: [JsonSchema]) {
        guard let schema = schemas.first(where: { $0.id.className == "ImageInfo" })
        else {
            XCTFail("Failed to build the expected JSON schema for `ImageInfo`.")
            return
        }
        
        let expectedAnswerTypeClassAndType = [
            ("FetchableImage","fetchable"),
            ("AnimatedImage","animated"),
        ]
        expectedAnswerTypeClassAndType.forEach {
            guard let _ = checkDefinitions(on: schema,
                                           className: $0.0,
                                           expectedType: $0.1,
                                           sharedKeys: [],
                                           expectedSerializableType: "ImageInfoType")
            else {
                XCTFail("Unexpected nil for \($0.0)")
                return
            }
        }
    }
    
    func checkNodeSchema(_ schemas: [JsonSchema]) {
        guard let schema = schemas.first(where: { $0.id.className == "Node" })
        else {
            XCTFail("Failed to build the expected JSON schema for `Node`.")
            return
        }
        
        let expectedAnswerTypeClassAndType = [
            ("ChoiceQuestionStepObject","choiceQuestion"),
            ("CompletionStepObject","completion"),
            ("InstructionStepObject","instruction"),
            ("OverviewStepObject","overview"),
            ("PermissionStepObject","permission"),
            ("SectionObject","section"),
            ("SimpleQuestionStepObject","simpleQuestion"),
        ]
        expectedAnswerTypeClassAndType.forEach {
            guard let _ = checkDefinitions(on: schema,
                                           className: $0.0,
                                           expectedType: $0.1,
                                           sharedKeys: ["identifier"],
                                           expectedSerializableType: "SerializableNodeType")
            else {
                XCTFail("Unexpected nil for \($0.0)")
                return
            }
        }
    }
    
    func checkTextInputItemSchema(_ schemas: [JsonSchema]) {
        guard let schema = schemas.first(where: { $0.id.className == "TextInputItem" })
        else {
            XCTFail("Failed to build the expected JSON schema for `TextInputItem`.")
            return
        }
        
        let expectedAnswerTypeClassAndType = [
            ("DoubleTextInputItemObject","number"),
            ("IntegerTextInputItemObject","integer"),
            ("StringTextInputItemObject","string"),
            ("YearTextInputItemObject","year"),
        ]
        expectedAnswerTypeClassAndType.forEach {
            guard let _ = checkDefinitions(on: schema,
                                           className: $0.0,
                                           expectedType: $0.1,
                                           sharedKeys: ["identifier", "fieldLabel", "placeholder"],
                                           expectedSerializableType: "TextInputType")
            else {
                XCTFail("Unexpected nil for \($0.0)")
                return
            }
        }
    }
    
    
    func checkResultDataSchema(_ schemas: [JsonSchema]) {
        guard let resultDataSchema = schemas.first(where: { $0.id.className == "ResultData" })
        else {
            XCTFail("Failed to build the expected JSON schema for `ResultData`.")
            return
        }
        
        let expectedOrder = ["type", "identifier", "startDate", "endDate"]
        let propertyKeys = resultDataSchema.root.orderedProperties?.orderedDictionary.keys.filter({ expectedOrder.contains($0.stringValue)
        }).sorted(by: { lhs, rhs in
            (lhs.sortOrderIndex ?? -1) < (rhs.sortOrderIndex ?? -1)
        }).map { $0.stringValue }
        XCTAssertEqual(expectedOrder, propertyKeys)
         
        XCTAssertEqual(["type","identifier","startDate"], resultDataSchema.root.required)
        XCTAssertNil(resultDataSchema.root.allOf)
        
        let sharedKeys = ["identifier", "startDate", "endDate"]
        let expectedSerializableType = "SerializableResultType"
        
        let expectedClassAndType = [
            ("AnswerResultObject","answer"),
            ("CollectionResultObject","collection"),
            ("FileResultObject","file"),
            ("ErrorResultObject","error"),
        ]
        expectedClassAndType.forEach {
            guard let def = checkDefinitions(on: resultDataSchema,
                                             className: $0.0,
                                             expectedType: $0.1,
                                             sharedKeys: sharedKeys,
                                             expectedSerializableType: expectedSerializableType)
            else {
                XCTFail("Unexpected nil for \($0.0)")
                return
            }
            // Check that the circle reference to the parent is set properly.
            if def.className == "CollectionResultObject" {
               if let childrenProp = def.properties?["children"],
                   case .array(let arrayProp) = childrenProp,
                   case .reference(let objRef) = arrayProp.items {
                    XCTAssertEqual("#", objRef.ref)
                }
                else {
                    XCTFail("Failed to find the children property: \(String(describing: def.properties)) ")
                }
            }
        }
    }
    
    @discardableResult
    func checkDefinitions(on rootSchema: JsonSchema,
                          className: String,
                          expectedType: String,
                          sharedKeys: [String],
                          expectedSerializableType: String) -> JsonSchemaObject? {
        guard let definition = rootSchema.definitions?[className],
               case .object(let schema) = definition
        else {
            XCTFail("Failed to add `\(className)` to the `\(rootSchema.id.className)` definitions.")
            return nil
        }
                
        XCTAssertEqual(.init(className), schema.id)
        // Each class that implements the parent interface should have a reference to "#" as something it conforms to.
        XCTAssertTrue(schema.allOf?.map { $0.ref }.contains("#") ?? false)
        
        if let defProperties = schema.orderedProperties?.orderedDictionary {

            // identifier, startDate, endDate should use the property definitions on the interface
            sharedKeys.forEach { sharedKey in
                XCTAssertNil(defProperties.first(where: { $0.key.stringValue == sharedKey }), "\(className) has \(sharedKey)")
            }
            
            if let serializationType = defProperties.first(where: { $0.key.stringValue == "type" }) {
                XCTAssertEqual(
                    .const(.init(const: expectedType, description: nil)),
                    serializationType.value,
                    "\(className) does not match expected type."
                )
            }
            else {
                XCTFail("\(className) does not have required 'type' key.")
            }
            
            defProperties.forEach { (key, prop) in
                if (key.stringValue == "type") { return }
                switch prop {
                case .primitive(let defProp):
                    XCTAssertNotNil(defProp.description, "\(className) property \(key.stringValue) has a nil description")
                case .array(let defProp):
                    XCTAssertNotNil(defProp.description, "\(className) property \(key.stringValue) has a nil description")
                case .dictionary(let defProp):
                    XCTAssertNotNil(defProp.description, "\(className) property \(key.stringValue) has a nil description")
                case .reference(let defProp):
                    XCTAssertNotNil(defProp.description, "\(className) property \(key.stringValue) has a nil description")
                default:
                    break
                }
            }
        }
        else {
            XCTFail("Failed to build the expected properties for `\(className)`.")
        }
        
        return schema
    }
    
    func testSerializers() {
        let factory = AssessmentFactory()
        
        XCTAssertTrue(checkPolymorphicExamples(for: factory.resultSerializer.examples,
                                                using: factory, protocolType: ResultData.self))
        XCTAssertTrue(checkPolymorphicExamples(for: factory.answerTypeSerializer.examples,
                                                using: factory, protocolType: AnswerType.self))
        XCTAssertTrue(checkPolymorphicExamples(for: factory.buttonActionSerializer.examples,
                                                using: factory, protocolType: ButtonActionInfo.self))
        XCTAssertTrue(checkPolymorphicExamples(for: factory.imageInfoSerializer.examples,
                                                using: factory, protocolType: ImageInfo.self))
    }
    
    func checkPolymorphicExamples<ProtocolType>(for objects: [ProtocolType], using factory: SerializationFactory, protocolType: ProtocolType.Type) -> Bool {
        var success = true
        objects.forEach {
            guard let original = $0 as? DocumentableObject else {
                XCTFail("Object does not conform to DocumentableObject. \($0)")
                success = false
                return
            }

            do {
                let decoder = factory.createJSONDecoder()
                let examples = try type(of: original).jsonExamples()
                examples.forEach { example in
                    do {
                        // Check that the example can be decoded without errors.
                        let wrapper = example.jsonObject()
                        let encodedObject = try JSONSerialization.data(withJSONObject: wrapper, options: [])
                        let decodingWrapper = try decoder.decode(_DecodablePolymorphicWrapper.self, from: encodedObject)
                        let decodedObject = try factory.decodePolymorphicObject(protocolType, from: decodingWrapper.decoder)
                        
                        // Check that the decoded object is the same Type as the original.
                        let originalType = type(of: original as Any)
                        let decodedType = type(of: decodedObject as Any)
                        let isSameType = (originalType == decodedType)
                        XCTAssertTrue(isSameType, "\(decodedType) is not equal to \(originalType)")
                        success = success && isSameType
                        
                        // Check that the decoded type name is the same as the original type name
                        guard let decodedTypeName = (decodedObject as? PolymorphicTyped)?.typeName
                            else {
                                XCTFail("Decoded object does not conform to PolymorphicRepresentable. \(decodedObject)")
                                return
                        }
                        guard let originalTypeName = (original as? PolymorphicTyped)?.typeName
                            else {
                                XCTFail("Example object does not conform to PolymorphicRepresentable. \(original)")
                                return
                        }
                        XCTAssertEqual(originalTypeName, decodedTypeName)
                        success = success && (originalTypeName == decodedTypeName)
                        
                    } catch let err {
                        XCTFail("Failed to decode \(example) for \(protocolType). \(err)")
                        success = false
                    }
                }
            }
            catch let err {
                XCTFail("Failed to decode \(original). \(err)")
                success = false
            }
        }
        return success
    }

    fileprivate struct _DecodablePolymorphicWrapper : Decodable {
        let decoder: Decoder
        init(from decoder: Decoder) throws {
            self.decoder = decoder
        }
    }
}

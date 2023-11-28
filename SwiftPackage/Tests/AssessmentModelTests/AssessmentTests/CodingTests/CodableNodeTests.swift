//
//  CodableQuestionTests.swift
//

import XCTest
@testable import AssessmentModel
import JsonModel
import ResultModel

class CodableQuestionTests: XCTestCase {
    
    let decoder = AssessmentFactory().createJSONDecoder()
    let encoder = AssessmentFactory().createJSONEncoder()

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    // MARK: Branch and Assessment
    
    func testAssessment_Default_Codable() {
        
        let json = """
            {
                 "identifier": "foo",
                 "type": "assessment",
                 "steps": [
                    {
                         "identifier": "foo",
                         "type": "instruction"
                    }
                ]
            }
        """.data(using: .utf8)! // our data in native (JSON) format
        
        XCTAssertEqual(.StandardTypes.assessment.nodeType, AssessmentObject.defaultType())
        checkDefaultSharedKeys(step: AssessmentObject(identifier: "foo", children: []))
        checkResult(step: AssessmentObject(identifier: "foo", children: []), type: AssessmentResultObject.self)
        
        do {
            
            let wrapper = try decoder.decode(NodeWrapper<AssessmentObject>.self, from: json)
            let object = wrapper.node
            
            checkDefaultSharedKeys(step: object)
            XCTAssertEqual("foo", object.identifier)
            XCTAssertEqual(.StandardTypes.assessment.nodeType, object.serializableType)
            
            let actualEncoding = try encoder.encode(object)
            try checkEncodedJson(expected: json, actual: actualEncoding)

        } catch let err {
            XCTFail("Failed to decode/encode object: \(err)")
            return
        }
    }
    
    func testAssessment_AllFields_Codable() {
        
        let json = """
        {
            "type": "assessment",
            "identifier": "foo",
            "versionString":"0.1.2",
            "estimatedMinutes":3,
            "copyright":"Baroo, Inc.",
            "comment": "comment",
            "shouldHideActions": ["skip"],
            "actions": {
                "goForward": {
                    "type": "default",
                    "buttonTitle": "Go, Dogs! Go!"
                }
            },
            "title": "Hello World!",
            "subtitle": "Question subtitle",
            "detail": "Some text. This is a test.",
            "image": {
                "type": "animated",
                "imageNames": ["foo1", "foo2", "foo3", "foo4"],
                "animationDuration": 2
            },
            "interruptionHandling": {
                "reviewIdentifier" : "foo",
                "canSaveForLater" : false,
                "canResume" : false,
                "canSkip" : false
            },
             "steps": [
                {
                     "identifier": "foo",
                     "type": "instruction"
                }
            ]
        }
        """.data(using: .utf8)! // our data in native (JSON) format
        
        do {
            
            let wrapper = try decoder.decode(NodeWrapper<AssessmentObject>.self, from: json)
            let object = wrapper.node
            
            XCTAssertEqual("foo", object.identifier)
            XCTAssertEqual(.StandardTypes.assessment.nodeType, object.serializableType)
            XCTAssertEqual(1, object.children.count)
            XCTAssertTrue(object.children.first is InstructionStepObject)
            XCTAssertEqual("0.1.2", object.versionString)
            XCTAssertEqual("Baroo, Inc.", object.copyright)
            XCTAssertEqual(3, object.estimatedMinutes)
            
            checkSharedEncodingKeys(step: object)

            let actualEncoding = try encoder.encode(object)
            try checkEncodedJson(expected: json, actual: actualEncoding)

        } catch let err {
            XCTFail("Failed to decode/encode object: \(err)")
            return
        }
    }
    
    func testSection_Default_Codable() {
        
        let json = """
            {
                 "identifier": "foo",
                 "type": "section",
                 "steps": [
                    {
                         "identifier": "foo",
                         "type": "instruction"
                    }
                ]
            }
        """.data(using: .utf8)! // our data in native (JSON) format
        
        XCTAssertEqual(.StandardTypes.section.nodeType, SectionObject.defaultType())
        checkDefaultSharedKeys(step: SectionObject(identifier: "foo", children: []))
        checkResult(step: SectionObject(identifier: "foo", children: []), type: BranchNodeResultObject.self)
        
        do {
            
            let wrapper = try decoder.decode(NodeWrapper<SectionObject>.self, from: json)
            let object = wrapper.node
            
            checkDefaultSharedKeys(step: object)
            XCTAssertEqual("foo", object.identifier)
            XCTAssertEqual(.StandardTypes.section.nodeType, object.serializableType)
            
            let actualEncoding = try encoder.encode(object)
            try checkEncodedJson(expected: json, actual: actualEncoding)

        } catch let err {
            XCTFail("Failed to decode/encode object: \(err)")
            return
        }
    }
    
    func testSection_AllFields_Codable() {
        
        let json = """
        {
            "type": "section",
            "identifier": "foo",
            "comment": "comment",
            "shouldHideActions": ["skip"],
            "actions": {
                "goForward": {
                    "type": "default",
                    "buttonTitle": "Go, Dogs! Go!"
                }
            },
            "title": "Hello World!",
            "subtitle": "Question subtitle",
            "detail": "Some text. This is a test.",
            "image": {
                "type": "animated",
                "imageNames": ["foo1", "foo2", "foo3", "foo4"],
                "animationDuration": 2
            },
             "steps": [
                {
                     "identifier": "foo",
                     "type": "instruction"
                }
            ]
        }
        """.data(using: .utf8)! // our data in native (JSON) format
        
        do {
            
            let wrapper = try decoder.decode(NodeWrapper<SectionObject>.self, from: json)
            let object = wrapper.node
            
            XCTAssertEqual("foo", object.identifier)
            XCTAssertEqual(.StandardTypes.section.nodeType, object.serializableType)
            XCTAssertEqual(1, object.children.count)
            XCTAssertTrue(object.children.first is InstructionStepObject)
            
            checkSharedEncodingKeys(step: object)

            let actualEncoding = try encoder.encode(object)
            try checkEncodedJson(expected: json, actual: actualEncoding)
            
            let copy = object.copy(with: "bar")
            XCTAssertEqual("bar", copy.identifier)
            XCTAssertEqual(.StandardTypes.section.nodeType, copy.serializableType)
            XCTAssertEqual(1, copy.children.count)
            checkSharedEncodingKeys(step: copy)

        } catch let err {
            XCTFail("Failed to decode/encode object: \(err)")
            return
        }
    }
    
    // MARK: Instructions
    
    func testImage_Animated_Codable() {
        
        let json = """
            {
                "identifier": "foo",
                "type": "overview",
                "image": {
                    "type": "animated",
                    "imageNames": ["foo1", "foo2", "foo3", "foo4"],
                    "animationDuration": 2
                }
            }
        """.data(using: .utf8)! // our data in native (JSON) format
        
        do {
            
            let wrapper = try decoder.decode(NodeWrapper<OverviewStepObject>.self, from: json)
            let object = wrapper.node
            
            
            if let image = object.imageInfo {
                XCTAssertTrue(image is AnimatedImage)
                XCTAssertEqual("foo1", image.imageName)
            }
            else {
                XCTFail("Failed to decode image.")
            }
            
            let actualEncoding = try encoder.encode(object)
            try checkEncodedJson(expected: json, actual: actualEncoding)

        } catch let err {
            XCTFail("Failed to decode/encode object: \(err)")
            return
        }
    }
    
    func testImage_Fetchable_Codable() {
        
        let json = """
            {
                "identifier": "foo",
                "type": "overview",
                "image": {
                    "type": "fetchable",
                    "imageName": "foo"
                }
            }
        """.data(using: .utf8)! // our data in native (JSON) format
        
        do {
            
            let wrapper = try decoder.decode(NodeWrapper<OverviewStepObject>.self, from: json)
            let object = wrapper.node
            
            
            if let image = object.imageInfo {
                XCTAssertTrue(image is FetchableImage)
                XCTAssertEqual("foo", image.imageName)
            }
            else {
                XCTFail("Failed to decode image.")
            }
            
            let actualEncoding = try encoder.encode(object)
            try checkEncodedJson(expected: json, actual: actualEncoding)

        } catch let err {
            XCTFail("Failed to decode/encode object: \(err)")
            return
        }
    }
    
    func testImage_SageResource_Codable() {
        
        let json = """
            {
                "identifier": "foo",
                "type": "overview",
                "image": {
                    "type": "sageResource",
                    "imageName": "survey"
                }
            }
        """.data(using: .utf8)! // our data in native (JSON) format
        
        do {
            
            let wrapper = try decoder.decode(NodeWrapper<OverviewStepObject>.self, from: json)
            let object = wrapper.node
            
            
            if let image = object.imageInfo {
                XCTAssertTrue(image is SageResourceImage)
                XCTAssertEqual("survey", image.imageName)
            }
            else {
                XCTFail("Failed to decode image.")
            }
            
            let actualEncoding = try encoder.encode(object)
            try checkEncodedJson(expected: json, actual: actualEncoding)

        } catch let err {
            XCTFail("Failed to decode/encode object: \(err)")
            return
        }
    }
    
    func testOverviewStep_Default_Codable() {
        
        let json = """
            {
                 "identifier": "foo",
                 "type": "overview"
            }
        """.data(using: .utf8)! // our data in native (JSON) format
        
        XCTAssertEqual(.StandardTypes.overview.nodeType, OverviewStepObject.defaultType())
        checkDefaultSharedKeys(step: OverviewStepObject(identifier: "foo"))
        checkResult(step: OverviewStepObject(identifier: "foo"), type: ResultObject.self)
        
        do {
            
            let wrapper = try decoder.decode(NodeWrapper<OverviewStepObject>.self, from: json)
            let object = wrapper.node
            
            checkDefaultSharedKeys(step: object)
            XCTAssertEqual("foo", object.identifier)
            XCTAssertEqual(.StandardTypes.overview.nodeType, object.serializableType)
            
            let actualEncoding = try encoder.encode(object)
            try checkEncodedJson(expected: json, actual: actualEncoding)

        } catch let err {
            XCTFail("Failed to decode/encode object: \(err)")
            return
        }
    }
    
    func testOverviewStep_AllFields_Codable() {
        
        let json = """
        {
            "type": "overview",
            "identifier": "foo",
            "comment": "comment",
            "shouldHideActions": ["skip"],
            "actions": {
                "goForward": {
                    "type": "default",
                    "buttonTitle": "Go, Dogs! Go!"
                }
            },
            "title": "Hello World!",
            "subtitle": "Question subtitle",
            "detail": "Some text. This is a test.",
            "image": {
                "type": "animated",
                "imageNames": ["foo1", "foo2", "foo3", "foo4"],
                "animationDuration": 2
            },
            "permissions": [
                {"permissionType" : "motion"}
            ]
        }
        """.data(using: .utf8)! // our data in native (JSON) format
        
        do {
            
            let wrapper = try decoder.decode(NodeWrapper<OverviewStepObject>.self, from: json)
            let object = wrapper.node
            
            XCTAssertEqual("foo", object.identifier)
            XCTAssertEqual(.StandardTypes.overview.nodeType, object.serializableType)
            
            checkSharedEncodingKeys(step: object)

            let actualEncoding = try encoder.encode(object)
            try checkEncodedJson(expected: json, actual: actualEncoding)
            
            let copy = object.copy(with: "bar")
            XCTAssertEqual("bar", copy.identifier)
            XCTAssertEqual(object.serializableType, copy.serializableType)
            checkSharedEncodingKeys(step: copy)

        } catch let err {
            XCTFail("Failed to decode/encode object: \(err)")
            return
        }
    }
    
    func testInstructionStep_Default_Codable() {
        
        let json = """
            {
                 "identifier": "foo",
                 "type": "instruction"
            }
        """.data(using: .utf8)! // our data in native (JSON) format
        
        XCTAssertEqual(.StandardTypes.instruction.nodeType, InstructionStepObject.defaultType())
        checkDefaultSharedKeys(step: InstructionStepObject(identifier: "foo"))
        checkResult(step: InstructionStepObject(identifier: "foo"), type: ResultObject.self)
        
        do {
            
            let wrapper = try decoder.decode(NodeWrapper<InstructionStepObject>.self, from: json)
            let object = wrapper.node
            
            checkDefaultSharedKeys(step: object)
            XCTAssertEqual("foo", object.identifier)
            XCTAssertEqual(.StandardTypes.instruction.nodeType, object.serializableType)
            XCTAssertFalse(object.fullInstructionsOnly)
            XCTAssertNil(object.spokenInstructions)
            
            let actualEncoding = try encoder.encode(object)
            try checkEncodedJson(expected: json, actual: actualEncoding)

        } catch let err {
            XCTFail("Failed to decode/encode object: \(err)")
            return
        }
    }
    
    func testInstructionStep_AllFields_Codable() {
        
        let json = """
        {
            "type": "instruction",
            "identifier": "foo",
            "comment": "comment",
            "shouldHideActions": ["skip"],
            "actions": {
                "goForward": {
                    "type": "default",
                    "buttonTitle": "Go, Dogs! Go!"
                }
            },
            "title": "Hello World!",
            "subtitle": "Question subtitle",
            "detail": "Some text. This is a test.",
            "image": {
                "type": "animated",
                "imageNames": ["foo1", "foo2", "foo3", "foo4"],
                "animationDuration": 2
            },
            "fullInstructionsOnly": true,
            "spokenInstructions": {
                "start": "Begin now",
                "end": "You are done!"
            }
        }
        """.data(using: .utf8)! // our data in native (JSON) format
        
        do {
            
            let wrapper = try decoder.decode(NodeWrapper<InstructionStepObject>.self, from: json)
            let object = wrapper.node
            
            XCTAssertEqual("foo", object.identifier)
            XCTAssertEqual(.StandardTypes.instruction.nodeType, object.serializableType)
            XCTAssertTrue(object.fullInstructionsOnly)
            XCTAssertEqual([.start : "Begin now", .end : "You are done!"], object.spokenInstructions)
            
            checkSharedEncodingKeys(step: object)

            let actualEncoding = try encoder.encode(object)
            try checkEncodedJson(expected: json, actual: actualEncoding)
            
            let copy = object.copy(with: "bar")
            XCTAssertEqual("bar", copy.identifier)
            XCTAssertEqual(object.serializableType, copy.serializableType)
            XCTAssertTrue(copy.fullInstructionsOnly)
            checkSharedEncodingKeys(step: copy)

        } catch let err {
            XCTFail("Failed to decode/encode object: \(err)")
            return
        }
    }
    
    func testCompletionStep_Default_Codable() {
        
        let json = """
            {
                 "identifier": "foo",
                 "type": "completion"
            }
        """.data(using: .utf8)! // our data in native (JSON) format
        
        XCTAssertEqual(.StandardTypes.completion.nodeType, CompletionStepObject.defaultType())
        checkDefaultSharedKeys(step: CompletionStepObject(identifier: "foo"))
        checkResult(step: CompletionStepObject(identifier: "foo"), type: ResultObject.self)
        
        do {
            
            let wrapper = try decoder.decode(NodeWrapper<CompletionStepObject>.self, from: json)
            let object = wrapper.node
            
            checkDefaultSharedKeys(step: object)
            XCTAssertEqual("foo", object.identifier)
            XCTAssertEqual(.StandardTypes.completion.nodeType, object.serializableType)
            
            let actualEncoding = try encoder.encode(object)
            try checkEncodedJson(expected: json, actual: actualEncoding)

        } catch let err {
            XCTFail("Failed to decode/encode object: \(err)")
            return
        }
    }
    
    // MARK: Active
    
    func testCountdownStep_Default_Codable() {
        
        let json = """
            {
                 "identifier": "foo",
                 "type": "countdown",
                 "duration": 5
            }
        """.data(using: .utf8)! // our data in native (JSON) format
        
        XCTAssertEqual(.StandardTypes.countdown.nodeType, CountdownStepObject.defaultType())
        checkDefaultSharedKeys(step: CountdownStepObject(identifier: "foo", duration: 5))
        checkResult(step: CountdownStepObject(identifier: "foo", duration: 5), type: ResultObject.self)
        
        do {
            
            let wrapper = try decoder.decode(NodeWrapper<CountdownStepObject>.self, from: json)
            let object = wrapper.node
            
            checkDefaultSharedKeys(step: object)
            XCTAssertEqual("foo", object.identifier)
            XCTAssertEqual(.StandardTypes.countdown.nodeType, object.serializableType)
            XCTAssertEqual(5, object.duration)
            XCTAssertFalse(object.fullInstructionsOnly)
            XCTAssertNil(object.spokenInstructions)
            
            let actualEncoding = try encoder.encode(object)
            try checkEncodedJson(expected: json, actual: actualEncoding)

        } catch let err {
            XCTFail("Failed to decode/encode object: \(err)")
            return
        }
    }
    
    func testCountdownStep_AllFields_Codable() {
        
        let json = """
        {
            "type": "countdown",
            "identifier": "foo",
            "duration": 5,
            "comment": "comment",
            "shouldHideActions": ["skip"],
            "actions": {
                "goForward": {
                    "type": "default",
                    "buttonTitle": "Go, Dogs! Go!"
                }
            },
            "title": "Hello World!",
            "subtitle": "Question subtitle",
            "detail": "Some text. This is a test.",
            "image": {
                "type": "animated",
                "imageNames": ["foo1", "foo2", "foo3", "foo4"],
                "animationDuration": 2
            },
            "fullInstructionsOnly": true,
            "spokenInstructions": {
                "start": "Begin now",
                "end": "You are done!"
            }
        }
        """.data(using: .utf8)! // our data in native (JSON) format
        
        do {
            
            let wrapper = try decoder.decode(NodeWrapper<CountdownStepObject>.self, from: json)
            let object = wrapper.node
            
            XCTAssertEqual("foo", object.identifier)
            XCTAssertEqual(.StandardTypes.countdown.nodeType, object.serializableType)
            XCTAssertTrue(object.fullInstructionsOnly)
            XCTAssertEqual([.start : "Begin now", .end : "You are done!"], object.spokenInstructions)
            
            checkSharedEncodingKeys(step: object)

            let actualEncoding = try encoder.encode(object)
            try checkEncodedJson(expected: json, actual: actualEncoding)
            
            let copy = object.copy(with: "bar")
            XCTAssertEqual("bar", copy.identifier)
            XCTAssertEqual(object.serializableType, copy.serializableType)
            XCTAssertEqual(object.duration, copy.duration)
            XCTAssertTrue(copy.fullInstructionsOnly)
            checkSharedEncodingKeys(step: copy)

        } catch let err {
            XCTFail("Failed to decode/encode object: \(err)")
            return
        }
    }
    
    func testPermissionStep_AllFields_Codable() {
        
        let json = """
        {
            "type": "permission",
            "identifier": "foo",
            "permissionType": "motion",
            "optional": false,
            "restrictedMessage": "This device is restricted.",
            "deniedMessage": "You have previously denied this permission.",
            "comment": "comment",
            "shouldHideActions": ["skip"],
            "actions": {
                "goForward": {
                    "type": "default",
                    "buttonTitle": "Go, Dogs! Go!"
                }
            },
            "title": "Hello World!",
            "subtitle": "Question subtitle",
            "detail": "Some text. This is a test.",
            "image": {
                "type": "animated",
                "imageNames": ["foo1", "foo2", "foo3", "foo4"],
                "animationDuration": 2
            },
            "fullInstructionsOnly": true,
            "spokenInstructions": {
                "start": "Begin now",
                "end": "You are done!"
            }
        }
        """.data(using: .utf8)! // our data in native (JSON) format
        
        do {
            
            let wrapper = try decoder.decode(NodeWrapper<PermissionStepObject>.self, from: json)
            let object = wrapper.node
            
            XCTAssertEqual("foo", object.identifier)
            XCTAssertEqual(.StandardTypes.permission.nodeType, object.serializableType)
            XCTAssertTrue(object.fullInstructionsOnly)
            XCTAssertEqual([.start : "Begin now", .end : "You are done!"], object.spokenInstructions)
            
            checkSharedEncodingKeys(step: object)

            let actualEncoding = try encoder.encode(object)
            try checkEncodedJson(expected: json, actual: actualEncoding)
            
            let copy = object.copy(with: "bar")
            XCTAssertEqual("bar", copy.identifier)
            XCTAssertEqual(object.serializableType, copy.serializableType)
            XCTAssertTrue(copy.fullInstructionsOnly)
            checkSharedEncodingKeys(step: copy)

        } catch let err {
            XCTFail("Failed to decode/encode object: \(err)")
            return
        }
    }
    
    // MARK: Questions

    func testSimpleQuestion_Default_Codable() {
        
        let json = """
            {
                 "identifier": "foo",
                 "type": "simpleQuestion"
            }
        """.data(using: .utf8)! // our data in native (JSON) format
        
        XCTAssertEqual(.StandardTypes.simpleQuestion.nodeType, SimpleQuestionStepObject.defaultType())
        checkDefaultSharedKeys(step: SimpleQuestionStepObject(identifier: "foo"))
        checkResult(step: SimpleQuestionStepObject(identifier: "foo"), type: AnswerResultObject.self)
        
        do {
            
            let wrapper = try decoder.decode(NodeWrapper<SimpleQuestionStepObject>.self, from: json)
            let object = wrapper.node
            
            checkDefaultSharedKeys(step: object)
            XCTAssertEqual("foo", object.identifier)
            XCTAssertEqual(.StandardTypes.simpleQuestion.nodeType, object.serializableType)
            XCTAssertTrue(object.inputItem is StringTextInputItemObject)
            
            let actualEncoding = try encoder.encode(object)
            try checkEncodedJson(expected: json, actual: actualEncoding)

        } catch let err {
            XCTFail("Failed to decode/encode object: \(err)")
            return
        }
    }
    
    func testSimpleQuestion_AllFields_Codable() {
        
        let json = """
        {
            "type": "simpleQuestion",
            "identifier": "foo",
            "comment": "comment",
            "shouldHideActions": ["skip"],
            "actions": {
                "goForward": {
                    "type": "default",
                    "buttonTitle": "Go, Dogs! Go!"
                }
            },
            "title": "Hello World!",
            "subtitle": "Question subtitle",
            "detail": "Some text. This is a test.",
            "image": {
                "type": "animated",
                "imageNames": ["foo1", "foo2", "foo3", "foo4"],
                "animationDuration": 2
            },
            "optional": true,
            "uiHint": "allThatJazz",
            "inputItem": {
                "type": "year"
            },
            "surveyRules": [{"skipToIdentifier" : "boomer", "matchingAnswer" : 1964, "ruleOperator": "lt" }]
        }
        """.data(using: .utf8)! // our data in native (JSON) format
        
        do {
            
            let wrapper = try decoder.decode(NodeWrapper<SimpleQuestionStepObject>.self, from: json)
            let object = wrapper.node
            
            let expectedRules = [JsonSurveyRuleObject(skipToIdentifier: "boomer", matchingValue: .integer(1964), ruleOperator: .lessThan)]
            
            XCTAssertEqual("foo", object.identifier)
            XCTAssertEqual(.StandardTypes.simpleQuestion.nodeType, object.serializableType)
            XCTAssertTrue(object.inputItem is YearTextInputItemObject)
            XCTAssertEqual(expectedRules, object.surveyRules)
            checkSharedEncodingKeys(question: object)

            let actualEncoding = try encoder.encode(object)
            try checkEncodedJson(expected: json, actual: actualEncoding)
            
            let copy = object.copy(with: "bar")
            XCTAssertEqual("bar", copy.identifier)
            XCTAssertEqual(object.serializableType, copy.serializableType)
            XCTAssertTrue(copy.inputItem is YearTextInputItemObject)
            XCTAssertEqual(expectedRules, copy.surveyRules)
            checkSharedEncodingKeys(question: copy)

        } catch let err {
            XCTFail("Failed to decode/encode object: \(err)")
            return
        }
    }
    
    func testChoiceQuestion_Default_Codable() {
        
        let json = """
            {
                "identifier": "foo",
                "type": "choiceQuestion",
                "choices": [{
                        "text": "one",
                        "value": "one"
                    },
                    {
                        "text": "two",
                        "value": "two"
                    },
                    {
                        "text": "none",
                        "selectorType": "exclusive"
                    }
                ]
            }
        """.data(using: .utf8)! // our data in native (JSON) format
        
        let expectedJson = """
            {
                "identifier": "foo",
                "type": "choiceQuestion",
                "choices": [{
                        "text": "one",
                        "value": "one",
                        "selectorType": "default"
                    },
                    {
                        "text": "two",
                        "value": "two",
                        "selectorType": "default"
                    },
                    {
                        "text": "none",
                        "selectorType": "exclusive"
                    }
                ]
            }
        """.data(using: .utf8)! // our data in native (JSON) format
        
        XCTAssertEqual(.StandardTypes.choiceQuestion.nodeType, ChoiceQuestionStepObject.defaultType())
        checkDefaultSharedKeys(step: ChoiceQuestionStepObject(identifier: "foo", choices: [.init(text: "bar")]))
        checkResult(step: ChoiceQuestionStepObject(identifier: "foo", choices: [.init(text: "bar")]), type: AnswerResultObject.self)
        
        do {
            
            let wrapper = try decoder.decode(NodeWrapper<ChoiceQuestionStepObject>.self, from: json)
            let object = wrapper.node
            checkDefaultSharedKeys(step: object)
            
            XCTAssertEqual("foo", object.identifier)
            XCTAssertEqual(.StandardTypes.choiceQuestion.nodeType, object.serializableType)
            XCTAssertEqual(.string, object.baseType)
            
            let choices: [JsonChoice] = [
                .init(value: .string("one"), text: "one"),
                .init(value: .string("two"), text: "two"),
                .init(text: "none", selectorType: .exclusive)
            ]
            XCTAssertEqual(choices, object.choices)
            
            let actualEncoding = try encoder.encode(object)
            try checkEncodedJson(expected: expectedJson, actual: actualEncoding)

        } catch let err {
            XCTFail("Failed to decode/encode object: \(err)")
            return
        }
    }
    
    func testChoiceQuestion_AllFields_Codable() {
        
        let json = """
        {
            "identifier": "foo",
            "type": "choiceQuestion",
            "baseType": "integer",
            "choices": [{
                    "text": "one",
                    "value": 1,
                    "selectorType": "default"
                },
                {
                    "text": "two",
                    "value": 2,
                    "selectorType": "default"
                },
                {
                    "text": "none",
                    "selectorType": "exclusive"
                }
            ],
            "other": { "type": "integer" },
            "comment": "comment",
            "shouldHideActions": ["skip"],
            "actions": {
                "goForward": {
                    "type": "default",
                    "buttonTitle": "Go, Dogs! Go!"
                }
            },
            "title": "Hello World!",
            "subtitle": "Question subtitle",
            "detail": "Some text. This is a test.",
            "image": {
                "type": "animated",
                "imageNames": ["foo1", "foo2", "foo3", "foo4"],
                "animationDuration": 2
            },
            "optional": true,
            "uiHint": "allThatJazz",
            "surveyRules": [{"skipToIdentifier" : "one", "matchingAnswer" : 1, "ruleOperator": "le" }]
        }
        """.data(using: .utf8)! // our data in native (JSON) format
        
        do {

            let wrapper = try decoder.decode(NodeWrapper<ChoiceQuestionStepObject>.self, from: json)
            let object = wrapper.node
            
            let expectedRules = [JsonSurveyRuleObject(skipToIdentifier: "one", matchingValue: .integer(1), ruleOperator: .lessThanEqual)]
            
            XCTAssertEqual("foo", object.identifier)
            XCTAssertEqual(.StandardTypes.choiceQuestion.nodeType, object.serializableType)
            XCTAssertEqual(.integer, object.baseType)
            XCTAssertEqual(expectedRules, object.surveyRules)
            
            let choices: [JsonChoice] = [
                .init(value: .integer(1), text: "one"),
                .init(value: .integer(2), text: "two"),
                .init(text: "none", selectorType: .exclusive)
            ]
            XCTAssertEqual(choices, object.choices)
            XCTAssertTrue(object.other is IntegerTextInputItemObject)
            
            checkSharedEncodingKeys(question: object)

            let actualEncoding = try encoder.encode(object)
            try checkEncodedJson(expected: json, actual: actualEncoding)
            
            let copy = object.copy(with: "bar")
            XCTAssertEqual("bar", copy.identifier)
            XCTAssertEqual(object.serializableType, copy.serializableType)
            XCTAssertEqual(.integer, copy.baseType)
            XCTAssertEqual(choices, copy.choices)
            XCTAssertTrue(copy.other is IntegerTextInputItemObject)
            XCTAssertEqual(expectedRules, object.surveyRules)
            checkSharedEncodingKeys(question: copy)

        } catch let err {
            XCTFail("Failed to decode/encode object: \(err)")
            return
        }
    }
    
    // Transformable
    
    func testTransformableNode_Codable() {
        
        let json = """
        {
            "identifier": "foo",
            "type": "transform",
            "resourceName": "sample_step"
        }
        """.data(using: .utf8)! // our data in native (JSON) format
        
        do {

            let jsonDecoder = AssessmentFactory().createJSONDecoder(resourceInfo: TestResourceInfo())
            let wrapper = try jsonDecoder.decode(NodeWrapper<InstructionStepObject>.self, from: json)
            let object = wrapper.node
            
            XCTAssertEqual("foo", object.identifier)
            XCTAssertEqual("Example of a transformable node", object.title)

        } catch let err {
            XCTFail("Failed to decode/encode object: \(err)")
            return
        }
    }
    
    // MARK: helpers
    
    func checkResult<T : ResultData>(step: AbstractNodeObject, type: T.Type) {
        let result = step.instantiateResult()
        XCTAssertEqual(result.identifier, step.identifier)
        XCTAssertTrue(result is T)
    }
    
    func checkDefaultSharedKeys(step: AbstractContentNodeObject) {
        XCTAssertEqual(type(of: step).defaultType(), step.serializableType)
        XCTAssertNil(step.comment)
        XCTAssertTrue(step.shouldHideButtons.isEmpty)
        XCTAssertTrue(step.buttonMap.isEmpty)
        XCTAssertNil(step.title)
        XCTAssertNil(step.subtitle)
        XCTAssertNil(step.detail)
        XCTAssertNil(step.imageInfo)
    }
    
    func checkSharedEncodingKeys(step: AbstractContentNodeObject) {
        XCTAssertEqual(type(of: step).defaultType(), step.serializableType)
        XCTAssertEqual("comment", step.comment)
        XCTAssertEqual([ButtonType.navigation(.skip)], step.shouldHideButtons)
        let expectedButtonMap: [ButtonType : ButtonActionInfoObject] = [
            .navigation(.goForward) : ButtonActionInfoObject(buttonTitle: "Go, Dogs! Go!")
        ]
        XCTAssertEqual(expectedButtonMap, step.buttonMap as? [ButtonType : ButtonActionInfoObject])
        XCTAssertEqual("Hello World!", step.title)
        XCTAssertEqual("Question subtitle", step.subtitle)
        XCTAssertEqual("Some text. This is a test.", step.detail)
        if let image = step.imageInfo as? AnimatedImage {
            XCTAssertEqual(["foo1", "foo2", "foo3", "foo4"], image.imageNames)
            XCTAssertEqual(2.0, image.animationDuration, accuracy: 0.001)
        }
        else {
            XCTFail("Failed to decoded expected image.")
        }
    }
    
    func checkSharedEncodingKeys(question: AbstractQuestionStepObject) {
        checkSharedEncodingKeys(step: question)
        XCTAssertTrue(question.optional)
        XCTAssertEqual(QuestionUIHint(rawValue: "allThatJazz"), question.uiHint)
    }
    
    func checkEncodedJson(expected: Data, actual: Data) throws {
        guard let dictionary = try JSONSerialization.jsonObject(with: actual, options: []) as? [String : Any]
            else {
                XCTFail("Encoded object is not a dictionary")
                return
        }
        guard let expectedDictionary = try JSONSerialization.jsonObject(with: expected, options: []) as? [String : Any]
            else {
                XCTFail("input json not a dictionary")
                return
        }
        
        expectedDictionary.forEach { (pair) in
            let encodedValue = dictionary[pair.key]
            XCTAssertNotNil(encodedValue, "\(pair.key)")
            if let str = pair.value as? String {
                XCTAssertEqual(str, encodedValue as? String, "\(pair.key)")
            }
            else if let num = pair.value as? NSNumber {
                XCTAssertEqual(num, encodedValue as? NSNumber, "\(pair.key)")
            }
            else if let arr = pair.value as? NSArray {
                XCTAssertEqual(arr, encodedValue as? NSArray, "\(pair.key)")
            }
            else if let dict = pair.value as? NSDictionary {
                XCTAssertEqual(dict, encodedValue as? NSDictionary, "\(pair.key)")
            }
            else {
                XCTFail("Failed to match \(pair.key)")
            }
        }
    }
    
    struct NodeWrapper<Value : Node> : Decodable {
        let node : Value
        init(from decoder: Decoder) throws {
            let step = try decoder.serializationFactory.decodePolymorphicObject(Node.self, from: decoder)
            guard let qStep = step as? Value else {
                let context = DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Failed to decode a QuestionStep")
                throw DecodingError.typeMismatch(Value.self, context)
            }
            self.node = qStep
        }
    }
    
    struct TestResourceInfo : ResourceInfo {
        let factoryBundle: ResourceBundle? = Bundle.module
        let bundleIdentifier: String? = nil
        let packageName: String? = nil
    }
}

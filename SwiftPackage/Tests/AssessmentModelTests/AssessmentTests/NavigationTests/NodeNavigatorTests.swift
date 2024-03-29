//
//  NodeNavigatorTests.swift
//  
//

import Foundation

import XCTest
import JsonModel
import ResultModel
@testable import AssessmentModel

class NodeNavigatorTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testSurveyANavigation_SkipQuestion() {
        let state = TestNavigationState(surveyA)
        let _ = navigateForward(state, to: "choiceQ1")
        guard let _ = state.currentNode else {
            XCTFail("Current node is nil")
            return
        }
        guard let answerResult = state.assessmentResult.stepHistory.last as? AnswerResult else {
            XCTFail("\(String(describing: state.assessmentResult.stepHistory.last)) last node is not an AnswerResult")
            return
        }
        
        XCTAssertEqual(answerResult.identifier, "choiceQ1")
        XCTAssertNil(answerResult.jsonValue)
        
        let multipleChoiceResult = followupNavigationSurveyA(state, expectedPrevious: "choiceQ1")
        XCTAssertNotNil(multipleChoiceResult)
        
        let restoredState = TestNavigationState(surveyA, restoredResult: state.assessmentResult)
        let restoredNode = restoredState.nodeNavigator.nodeAfter(currentNode: nil, branchResult: restoredState.assessmentResult)
        XCTAssertEqual("multipleChoice", restoredNode.node?.identifier)
        XCTAssertEqual(.forward, restoredNode.direction)
    }
    
    func testSurveyANavigation_Q3() {
        let state = TestNavigationState(surveyA)
        let _ = navigateForward(state, to: "choiceQ1")
        guard let _ = state.currentNode else {
            XCTFail("Current node is nil")
            return
        }
        guard let answerResult = state.assessmentResult.stepHistory.last as? AnswerResult else {
            XCTFail("\(String(describing: state.assessmentResult.stepHistory.last)) last node is not an AnswerResult")
            return
        }
        
        XCTAssertEqual(answerResult.identifier, "choiceQ1")
        XCTAssertNil(answerResult.jsonValue)
        
        answerResult.jsonValue = .integer(3)
        
        guard let q3Result = navToQuestion(state, identifier: "simpleQ3", direction: .forward, previous: "choiceQ1") else {
            XCTFail("Expecting to navigation to 'simpleQ3'")
            return
        }
        
        q3Result.jsonValue = .integer(4)
        
        let multipleChoiceResult = followupNavigationSurveyA(state, expectedPrevious: "simpleQ3")
        XCTAssertNotNil(multipleChoiceResult)
        
        let restoredState = TestNavigationState(surveyA, restoredResult: state.assessmentResult)
        let restoredNode = restoredState.nodeNavigator.nodeAfter(currentNode: nil, branchResult: restoredState.assessmentResult)
        XCTAssertEqual("multipleChoice", restoredNode.node?.identifier)
        XCTAssertEqual(.forward, restoredNode.direction)
    }

    
    func navigateForward(_ state: TestNavigationState, to identifier: String) -> NavigationPoint {
        var loopCount = 0
        var point: NavigationPoint = .init(node: nil, direction: .forward)
        repeat {
            point = state.nodeNavigator.nodeAfter(currentNode: state.currentNode, branchResult: state.assessmentResult)
            state.currentNode = point.node
            if point.node != nil {
                state.assessmentResult.appendStepHistory(with: point.node!.instantiateResult(), direction: point.direction)
            }
            loopCount += 1
        } while state.currentNode != nil && state.currentNode!.identifier != identifier && loopCount < 100
        
        XCTAssertEqual(identifier, state.currentNode?.identifier)
        XCTAssertLessThan(loopCount, 100, "Infinite loop of wacky madness")
        
        return point
    }
    
    func followupNavigationSurveyA(_ state: TestNavigationState, expectedPrevious: String) -> AnswerResult? {
        guard let followupAnswerResult1 = navToQuestion(state, identifier: "followupQ", direction: .forward, previous: expectedPrevious) else {
            XCTFail("Failed first loop")
            return nil
        }
        
        followupAnswerResult1.jsonValue = .boolean(false)
        
        guard let choiceQ1Result = navToQuestion(state, identifier: "choiceQ1", direction: .forward, previous: "overview") else {
            XCTFail("Failed to navigate to 'choiceQ1'")
            return nil
        }
        
        choiceQ1Result.jsonValue = .integer(2)
        
        guard let yearResult = navToQuestion(state, identifier: "simpleQ2", direction: .forward, previous: "choiceQ1") else {
            XCTFail("Failed to navigate to 'simpleQ2'")
            return nil
        }
                
        yearResult.jsonValue = .integer(1975)
        
        guard let followupAnswerResult2 = navToQuestion(state, identifier: "followupQ", direction: .forward, previous: "simpleQ2") else {
            XCTFail("Failed to navigate to 'followupQ'")
            return nil
        }
        
        followupAnswerResult2.jsonValue = .boolean(true)
        
        return navToQuestion(state, identifier: "multipleChoice", direction: .forward, previous: "followupQ")
    }
    
    func navToQuestion(_ state: TestNavigationState, identifier: String, direction: PathMarker.Direction, previous: String) -> AnswerResult? {
        guard let _ = state.currentNode else {
            XCTFail("Current node is nil")
            return nil
        }
        
        let point = state.nodeNavigator.nodeAfter(currentNode: state.currentNode, branchResult: state.assessmentResult)
        XCTAssertEqual(identifier, point.node?.identifier)
        XCTAssertEqual(direction, point.direction)
        
        guard let question = point.node, question.identifier == identifier,
              let result = question.instantiateResult() as? AnswerResult
        else {
            return nil
        }
        
        state.currentNode = question
        state.assessmentResult.appendStepHistory(with: result, direction: point.direction)
        
        let previousNode = state.nodeNavigator.previousNode(currentNode: state.currentNode, branchResult: state.assessmentResult)
        XCTAssertEqual(previous, previousNode?.identifier)
        
        return result
    }
    
    class TestNavigationState : NavigationState {
        let assessment: AssessmentObject
        let assessmentResult: AssessmentResultObject
        public private(set) var nodeNavigator: NodeNavigator! = nil
        
        var currentNode: Node?
        
        init(_ assessment: AssessmentObject, restoredResult: AssessmentResultObject? = nil) {
            self.assessment = assessment
            self.assessmentResult = restoredResult?.deepCopy() ?? assessment.instantiateAssessmentResult() as! AssessmentResultObject
            self.nodeNavigator = try! assessment.instantiateNavigator(state: self) as! NodeNavigator
        }
    }
}

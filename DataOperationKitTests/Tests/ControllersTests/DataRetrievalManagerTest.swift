//
//  DataRetrievalManagerTest.swift
//  SwiftWeather
//
//  Created by Mykhailo Vorontsov on 01/04/2016.
//  Copyright © 2016 Mykhailo Vorontsov. All rights reserved.
//

import XCTest

@testable import DataOperationKit

class SampleObject:NSObject{
  var identifier: Int = 0
}

class SampleDataOperation: DataRetrievalOperation {
  
  
  override var status: OperationStatus {
    didSet{
      print("\(oldValue) -> \(status)")
      XCTAssertTrue(oldValue.rawValue < status.rawValue)
    }
  }
  
  override func parseData() throws {
    try super.parseData()
    
    // Add delay to make sure that operation not completed before cancel or error is called from test thread
    sleep(1)
    
    guard false == cancelled else {
      return
    }
    
    var objects = [SampleObject]()
    
    // Create 10 sample objects
    for index in 0...9 {
      let newObject = SampleObject()
      newObject.identifier = index
      objects.append(newObject)
    }
    results = objects
  }
  
}

class SampleCoreDataOperation: SampleDataOperation, ManagedObjectRetrievalOperationProtocol {
  var dataManager: CoreDataManager!
}

class DataRetrievalOperationManagerTests: XCTestCase {
  
  func testManagerSharedObject() {
    let manager:DataRetrievalOperationManager = DataRetrievalOperationManager()
    XCTAssertNotNil(manager)
    XCTAssertEqual(manager.operations.count, 0)
    
    let sharedManager:DataRetrievalOperationManager = DataRetrievalOperationManager()
    XCTAssertNotNil(sharedManager)
    XCTAssertNotEqual(sharedManager, manager)
    XCTAssertEqual(sharedManager.operations.count, 0)
  }
  
  func testSimpleOperation() {
    
    let manager:DataRetrievalOperationManager = DataRetrievalOperationManager(remote:"http://jsonplaceholder.typicode.com")
    
    let operation = SampleDataOperation()
    XCTAssertNotNil(operation)
    XCTAssertEqual(operation.stage, OperationStage.Awaiting)
    XCTAssertEqual(operation.status, OperationStatus.Created)
    
    var completed:Bool = false
    
    let expct:XCTestExpectation = self.expectationWithDescription("Awaiting request")
    
    manager.addOperations([operation]) { (success, results, errors) -> Void in
      XCTAssertTrue(success)
      XCTAssertNil(errors)
      XCTAssertFalse(completed)
      XCTAssertGreaterThan(results.count, 1)
      
      if (results.count > 2) {
        let sampleObject1:SampleObject? = results[0] as? SampleObject
        let sampleObject2:SampleObject? = results[1] as? SampleObject
        XCTAssertNotNil(sampleObject1)
        XCTAssertNotNil(sampleObject2)
        XCTAssertNotEqual(sampleObject1, sampleObject2)
        XCTAssertNotEqual(sampleObject1?.identifier, sampleObject2?.identifier)
      }
      
      XCTAssertEqual(manager.operations.count, 0)
      
      XCTAssertEqual(operation.stage, OperationStage.Completed)
      completed = true
      expct.fulfill()
    }
    
    XCTAssertEqual(manager.operations.count, 2)
    
    XCTAssertFalse(completed)
    
    self.waitForExpectationsWithTimeout(30.0) { (error:NSError?) -> Void in
      XCTAssertNil(error)
    }
    
    XCTAssertTrue(completed)
  }
  
  func testCoreDataOperation() {
    let operation = SampleCoreDataOperation()
    XCTAssertNotNil(operation)
    let manager:DataRetrievalOperationManager = DataRetrievalOperationManager(remote:"http://jsonplaceholder.typicode.com")
    manager.coreDataManager = CoreDataManager()
    XCTAssertNil(operation.dataManager)
    manager.addOperations([operation], completionBLock: nil)
    XCTAssertNotNil(operation.dataManager)
  }
  
  func testDependantOperation() {
    let manager:DataRetrievalOperationManager = DataRetrievalOperationManager(remote:"http://jsonplaceholder.typicode.com")
    
    let operation3 = SampleDataOperation()
    let operation1 = SampleDataOperation()
    let operation2 = SampleDataOperation()
    
    var completed1:Bool = false
    var completed2:Bool = false
    var completed3:Bool = false
    var completed:Bool = false
    
    operation1.completionBlock =  { (Void) -> Void in
      XCTAssertEqual(operation3.status, OperationStatus.Queued)
      XCTAssertNotEqual(operation3.status, OperationStatus.Completed)
      XCTAssertEqual(operation1.status, OperationStatus.Completed)
      completed1 = true;
    }
    
    operation2.completionBlock =  { (Void) -> Void in
      XCTAssertEqual(operation3.status, OperationStatus.Queued)
      
      XCTAssertEqual(operation1.status, OperationStatus.Completed)
      XCTAssertEqual(operation2.status, OperationStatus.Completed)
      XCTAssertNotEqual(operation3.status, OperationStatus.Completed)
      completed2 = true;
    }
    
    operation3.completionBlock =  { (Void) -> Void in
      XCTAssertEqual(operation3.status, OperationStatus.Completed)
      XCTAssertEqual(operation3.stage, OperationStage.Completed)
      completed3 = true;
    }
    
    operation2.addDependency(operation1)
    operation3.addDependency(operation2)
    
    let expct:XCTestExpectation = self.expectationWithDescription("Awaiting request")
    
    manager.addOperations([operation3, operation2, operation1]) { (success, results, errors) -> Void in
      XCTAssertTrue(completed1)
      XCTAssertTrue(completed2)
      XCTAssertTrue(completed3)
      
      XCTAssertTrue(success)
      XCTAssertNil(errors)
      XCTAssertFalse(completed)
      XCTAssertGreaterThan(results.count, 1)
      XCTAssertEqual(manager.operations.count, 0)
      completed = true
      expct.fulfill()
    }
    
    XCTAssertEqual(manager.operations.count, 4)
    
    XCTAssertFalse(completed1)
    XCTAssertFalse(completed2)
    XCTAssertFalse(completed3)
    XCTAssertFalse(completed)
    
    self.waitForExpectationsWithTimeout(30.0) { (error:NSError?) -> Void in
      XCTAssertNil(error)
    }
    
    XCTAssertEqual(manager.operations.count, 0)
    
    XCTAssertTrue(completed)
    XCTAssertTrue(completed1)
    XCTAssertTrue(completed2)
    XCTAssertTrue(completed3)
  }
  
  func testOperationCancellation() {
    let manager:DataRetrievalOperationManager = DataRetrievalOperationManager(remote:"http://jsonplaceholder.typicode.com")
    
    let operation = SampleDataOperation()
    XCTAssertNotNil(operation)
    XCTAssertEqual(operation.status, OperationStatus.Created)
    
    var completed:Bool = false
    
    let expct:XCTestExpectation = self.expectationWithDescription("Awaiting request")
    
    manager.addOperations([operation]) { (success, results, errors) -> Void in
      XCTAssertFalse(success)
      XCTAssertNil(errors)
      XCTAssertFalse(completed)
      XCTAssertEqual(results.count, 0)
      XCTAssertEqual(operation.status, OperationStatus.Cancelled)
      completed = true
      expct.fulfill()
    }
    
    dispatch_async(dispatch_get_main_queue()) {
      operation.cancel()
    }
    
    XCTAssertEqual(manager.operations.count, 2)
    
    XCTAssertFalse(completed)
    
    self.waitForExpectationsWithTimeout(30.0) { (error:NSError?) -> Void in
      XCTAssertNil(error)
    }
    
    XCTAssertTrue(completed)
    
  }
  
  func testOperationBreakingWithError() {
    
    enum TestErrors:ErrorType {
      case TestErrorWithParam(param:Int)
    }
    
    let manager:DataRetrievalOperationManager = DataRetrievalOperationManager(remote:"http://jsonplaceholder.typicode.com")
    
    let operation = SampleDataOperation()
    XCTAssertNotNil(operation)
    XCTAssertEqual(operation.status, OperationStatus.Created)
    
    var completed:Bool = false
    
    let expct:XCTestExpectation = self.expectationWithDescription("Awaiting request")
    
    manager.addOperations([operation]) { (success, results, errors) -> Void in
      XCTAssertFalse(success)
      XCTAssertNotNil(errors)
      XCTAssertEqual(errors?.count, 1)
      if let error = errors?.last {
        switch error {
        case TestErrors.TestErrorWithParam(let param):
          XCTAssertEqual(param, 999)
          default:
          XCTAssert(false, "TestErrors.TestErrorWithParam(999) expected!")
        }
      } else {
        XCTAssert(false, "Error expected!")
      }
      XCTAssertEqual(results.count, 0)
      XCTAssertEqual(operation.status, OperationStatus.Error)
      completed = true
      expct.fulfill()
    }
    
    
    XCTAssertEqual(manager.operations.count, 2)
    
    dispatch_async(dispatch_get_main_queue()) {
      operation.breakWithError(TestErrors.TestErrorWithParam(param: 999))
    }
    
    
    XCTAssertFalse(completed)
    
    self.waitForExpectationsWithTimeout(30.0) { (error:NSError?) -> Void in
      XCTAssertNil(error)
    }
    XCTAssertEqual(operation.status, OperationStatus.Error)
    XCTAssertTrue(completed)
    
  }
  
  func testNotForcedFailureOperation() {
    let manager:DataRetrievalOperationManager = DataRetrievalOperationManager(remote:"http://jsonplaceholder.typicode.com")
    
    let operation3 = SampleDataOperation()
    let operation1 = SampleDataOperation()
    let operation2 = SampleDataOperation()
    
    var completed1:Bool = false
    var completed2:Bool = false
    var completed3:Bool = false
    var completed:Bool = false
    
    operation1.completionBlock =  { (Void) -> Void in
      XCTAssertEqual(operation3.status, OperationStatus.Queued)
      XCTAssertEqual(operation1.status, OperationStatus.Error)
      completed1 = true;
    }
    
    operation2.completionBlock =  { (Void) -> Void in
      XCTAssertEqual(operation3.status, OperationStatus.Queued)
      XCTAssertEqual(operation2.status, OperationStatus.Completed)
      completed2 = true;
    }
    
    operation3.completionBlock =  { (Void) -> Void in
      XCTAssertEqual(operation3.status, OperationStatus.Cancelled)
      completed3 = true;
    }
    
    operation3.addDependency(operation1)
    operation3.addDependency(operation2)
    
    let expct:XCTestExpectation = self.expectationWithDescription("Awaiting request")
    
    manager.addOperations([operation3, operation2, operation1]) { (success, results, errors) -> Void in
      XCTAssertTrue(completed1)
      XCTAssertTrue(completed2)
      XCTAssertTrue(completed3)
      
      XCTAssertFalse(success)
      XCTAssertNotNil(errors)
      XCTAssertEqual(errors?.count, 1)
      XCTAssertFalse(completed)
      XCTAssertGreaterThan(results.count, 1)
      XCTAssertEqual(manager.operations.count, 0)
      completed = true
      expct.fulfill()
    }
    
    XCTAssertEqual(manager.operations.count, 4)
    
    XCTAssertFalse(completed1)
    XCTAssertFalse(completed2)
    XCTAssertFalse(completed3)
    XCTAssertFalse(completed)
    
    dispatch_async(dispatch_get_main_queue()) {
      operation1.breakWithError(NSError(domain: "TestErrorDomain", code: 999, userInfo: nil))
    }
    
    self.waitForExpectationsWithTimeout(30.0) { (error:NSError?) -> Void in
      XCTAssertNil(error)
    }
    
    XCTAssertEqual(manager.operations.count, 0)
    
    XCTAssertTrue(completed)
    XCTAssertTrue(completed1)
    XCTAssertTrue(completed2)
    XCTAssertTrue(completed3)
  }
  
  func testForcedOperation() {
    let manager:DataRetrievalOperationManager = DataRetrievalOperationManager(remote:"http://jsonplaceholder.typicode.com")
    
    let operation3 = SampleDataOperation()
    let operation1 = SampleDataOperation()
    let operation2 = SampleDataOperation()
    
    var completed1:Bool = false
    var completed2:Bool = false
    var completed3:Bool = false
    var completed:Bool = false
    
    operation1.completionBlock =  { (Void) -> Void in
      XCTAssertEqual(operation1.status, OperationStatus.Error)
      completed1 = true;
    }
    
    operation2.completionBlock =  { (Void) -> Void in
      XCTAssertEqual(operation2.status, OperationStatus.Completed)
      completed2 = true;
    }
    
    operation3.completionBlock =  { (Void) -> Void in
      XCTAssertEqual(operation1.status, OperationStatus.Error)
      XCTAssertEqual(operation2.status, OperationStatus.Completed)
      XCTAssertEqual(operation3.status, OperationStatus.Completed)
      completed3 = true;
    }
    
    operation3.force = true
    
    operation3.addDependency(operation1)
    operation3.addDependency(operation2)
    
    let expct:XCTestExpectation = self.expectationWithDescription("Awaiting request")
    
    manager.addOperations([operation3, operation2, operation1]) { (success, results, errors) -> Void in
      XCTAssertTrue(completed1)
      XCTAssertTrue(completed2)
      XCTAssertTrue(completed3)
      
      XCTAssertFalse(success)
      XCTAssertNotNil(errors)
      XCTAssertEqual(errors?.count, 1)
      XCTAssertFalse(completed)
      XCTAssertGreaterThan(results.count, 1)
      XCTAssertEqual(manager.operations.count, 0)
      
      XCTAssertEqual(operation1.status, OperationStatus.Error)
      XCTAssertEqual(operation2.status, OperationStatus.Completed)
      XCTAssertEqual(operation3.status, OperationStatus.Completed)
      
      completed = true
      expct.fulfill()
    }
    
    XCTAssertEqual(manager.operations.count, 4)
    
    XCTAssertFalse(completed1)
    XCTAssertFalse(completed2)
    XCTAssertFalse(completed3)
    XCTAssertFalse(completed)
    
    dispatch_async(dispatch_get_main_queue()) {
      operation1.breakWithError(NSError(domain: "TestErrorDomain", code: 999, userInfo: nil))
    }
    
    self.waitForExpectationsWithTimeout(30.0) { (error:NSError?) -> Void in
      XCTAssertNil(error)
    }
    
    XCTAssertEqual(manager.operations.count, 0)
    
    XCTAssertTrue(completed)
    XCTAssertTrue(completed1)
    XCTAssertTrue(completed2)
    XCTAssertTrue(completed3)
  }
  
  func testOperationCopmparison() {
    let op1 = SampleDataOperation()
    let op2 = SampleDataOperation()
    let opNet = NetworkDataRetrievalOperation()
    XCTAssertNotNil(op1)
    XCTAssertNotNil(op2)
    XCTAssertNotNil(opNet)
    XCTAssertEqual(op1, op1)
    XCTAssertEqual(op1, op2)
    XCTAssertTrue([op2].contains(op1))
    
    XCTAssertEqual(([op1, op2] as NSArray).indexOfObject(op2), 0)
    XCTAssertEqual(([opNet, op1] as NSArray).indexOfObject(op2), 1)
    XCTAssertEqual(([op1, op1] as NSArray).indexOfObject(opNet), NSNotFound)
    
    XCTAssertNotEqual(op1, opNet)
    let operationName = "Imortant"
    op1.name = operationName
    XCTAssertNotEqual(op1, op2)
    op2.name = operationName
    XCTAssertEqual(op1, op2)
    XCTAssertTrue([op2].contains(op1))
    opNet.name = operationName
    print(" --------------- NET OPERATION: \(opNet.operationFullName)")
    XCTAssertNotEqual(op1, opNet)
    XCTAssertFalse([op2].contains(opNet))
  }

  func testEqualOperationProcessing() {
    let op1 = SampleDataOperation()
    let op2 = SampleDataOperation()
    let op3 = SampleDataOperation()
    op1.name = "Named"
    var op3Done = false
    var op2Done = false
    var op1Done = false
    let op1Exp = expectationWithDescription("op1.cb.exp")
    let op2Exp = expectationWithDescription("op2.cb.exp")
    let op3Exp = expectationWithDescription("op3.cb.exp")
    
    op3.completionBlock = {
      op3Done = true
      op3Exp.fulfill()
    }
    op2.completionBlock = {
      op2Done = true
      op2Exp.fulfill()
    }
    op1.completionBlock = {
      op1Done = true
      op1Exp.fulfill()
    }
    
    let manager:DataRetrievalOperationManager = DataRetrievalOperationManager(remote:"http://jsonplaceholder.typicode.com")
    
    manager.suspended = true
    let exp1 = expectationWithDescription("1")
    var comp1 = false
    manager.addOperations([op1]) { (success, results, errors) in
      comp1 = true
      XCTAssertTrue(success)
      exp1.fulfill()
    }
    
    XCTAssertEqual(op1.status, OperationStatus.Queued)

    XCTAssertFalse(manager.operations.contains(op3))
    XCTAssertFalse(manager.operations.contains(op2))
    XCTAssertTrue(manager.operations.contains(op1))
    
    let exp2 = expectationWithDescription("2")

    var comp2 = false

    manager.addOperations([op2]) { (success, results, errors) in
      comp2 = true
      XCTAssertTrue(success)
      exp2.fulfill()
    }
    
    XCTAssertEqual(op2.status, OperationStatus.Queued)

    
    XCTAssertTrue(manager.operations.contains(op3))
    XCTAssertTrue(manager.operations.contains(op2))
    XCTAssertTrue(manager.operations.contains(op1))
    
    var comp13 = false
    
    XCTAssertTrue((manager.operations as NSArray).containsObject(op2))
    let exp13 = expectationWithDescription("13")
    manager.addOperations([op3, op1]) { (success, results, errors) in
      comp13 = true
      XCTAssertTrue(success)
      exp13.fulfill()
    }
    
    XCTAssertEqual(op3.status, OperationStatus.Duplicate)

    let exp123 = expectationWithDescription("123")
    var comp123 = false
    manager.addOperations([op3, op2, op1]) { (success, results, errors) in
      comp123 = true
      XCTAssertTrue(success)
      exp123.fulfill()
    }

    
    manager.suspended = false
    waitForExpectationsWithTimeout(900.0, handler: nil)
    XCTAssertTrue(comp1)
    XCTAssertTrue(comp2)
    XCTAssertTrue(comp13)
    XCTAssertTrue(comp123)
    XCTAssertEqual(op3.status, OperationStatus.Completed)
    XCTAssertEqual(op2.status, OperationStatus.Completed)
    XCTAssertEqual(op1.status, OperationStatus.Completed)
    XCTAssertTrue(op3Done)
    XCTAssertTrue(op2Done)
    XCTAssertTrue(op1Done)
  }
}


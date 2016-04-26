//
//  NetwrokOperationTests.swift
//  SwiftWeather
//
//  Created by Mykhailo Vorontsov on 01/04/2016.
//  Copyright © 2016 Mykhailo Vorontsov. All rights reserved.
//


import XCTest

@testable import DataOperationKit


class NetwrokOperationTests: XCTestCase {
  
  func testSimpleOperation() {
    
    let manager:DataRetrievalOperationManager = DataRetrievalOperationManager(remote:"http://jsonplaceholder.typicode.com")
    
    let operation = SampleNetworkSyncOperation()
    XCTAssertNotNil(operation)
    XCTAssertNil(operation.requestPath)
    XCTAssertNil(operation.requestEndPoint)
    XCTAssertEqual(operation.stage, OperationStage.Awaiting)
    XCTAssertEqual(operation.status, OperationStatus.Created)
    XCTAssertNil(operation.request)
    
    var completed:Bool = false
    
    let expct:XCTestExpectation = self.expectationWithDescription("Awaiting request")
    
    manager.addOperations([operation]) { (success, results, errors) -> Void in
      
      //TODO: Add network condition error check
      XCTAssertTrue(success)
      XCTAssertNil(errors)
      XCTAssertFalse(completed)
      XCTAssertGreaterThan(results.count, 1)
      
      if results.count > 1 {
        let sampleObject1:SampleMSGObject = results[0] as! SampleMSGObject
        let sampleObject2:SampleMSGObject = results[1] as! SampleMSGObject
        XCTAssertNotNil(sampleObject1)
        XCTAssertNotNil(sampleObject2)
        XCTAssertNotEqual(sampleObject1, sampleObject2)
        XCTAssertEqual(sampleObject1.userID, sampleObject2.userID)
        XCTAssertNotEqual(sampleObject1.sid, sampleObject2.sid)
        XCTAssertNotEqual(sampleObject1.title, sampleObject2.title)
        XCTAssertNotEqual(sampleObject1.body, sampleObject2.body)
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
    
    XCTAssertNotNil(operation.requestPath)
    XCTAssertEqual(operation.requestPath, "posts")
    XCTAssertEqual(operation.requestEndPoint, "http://jsonplaceholder.typicode.com")
    XCTAssertNotNil(operation.request)
    XCTAssertEqual(operation.request?.URL?.absoluteString, "http://jsonplaceholder.typicode.com/posts")
    XCTAssertTrue(completed)
  }
  
}

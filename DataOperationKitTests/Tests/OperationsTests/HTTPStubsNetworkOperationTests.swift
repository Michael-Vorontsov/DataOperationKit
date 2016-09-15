//
//  HTTPStubsNetworkOperationTests.swift
//  DataOperationKit
//
//  Created by Mykhailo Vorontsov on 07/04/2016.
//  Copyright © 2016 Mykhailo Vorontsov. All rights reserved.
//

import XCTest
import OHHTTPStubs

@testable import DataOperationKit


class SampleMSGObject:NSObject{
  var userID:Int = 0
  var sid: Int = 0
  var title: String?
  var body: String?
}

class SampleNetworkSyncOperation: NetworkDataRetrievalOperation {
  
  override func prepareForRetrieval() throws {
    requestPath = "posts"
    try super.prepareForRetrieval()
  }
  
  override func parseData() throws {
    try super.parseData()
    var objects:[AnyObject] = []
    let dataInfo = convertedObject
    guard  false == cancelled else  { return }
    
    let infoArray  = dataInfo as! [[String : AnyObject]]
    for objectInfo:[String : AnyObject] in infoArray {
      guard let userID = objectInfo["userId"] as? Int,
        let sid = objectInfo["id"] as? Int else { continue }
      
      let object = SampleMSGObject()
      
      object.userID = userID
      object.sid = sid
      object.title = objectInfo["title"] as? String
      object.body = objectInfo["body"] as? String
      
      objects .append(object)
    }
    results =  objects;
  }
}

class SampleAcceessTokenOperation: SampleNetworkSyncOperation, AccessKeyOperationProtocol {}

class HTTPStubsNetworkOperationTests: XCTestCase {
  
  let JSONObject = [
    [
      "userId": 1,
      "id": 1,
      "title": "sunt aut facere repellat provident occaecati excepturi optio reprehenderit",
      "body": "quia et suscipit\nsuscipit recusandae consequuntur expedita et cum\nreprehenderit molestiae ut ut quas totam\nnostrum rerum est autem sunt rem eveniet architecto"
    ],
    [
      "userId": 1,
      "id": 2,
      "title": "qui est esse",
      "body": "est rerum tempore vitae\nsequi sint nihil reprehenderit dolor beatae ea dolores neque\nfugiat blanditiis voluptate porro vel nihil molestiae ut reiciendis\nqui aperiam non debitis possimus qui neque nisi nulla"
    ]
  ]
  weak var savedStub: OHHTTPStubsDescriptor?
  var manager:DataRetrievalOperationManager!
  
  private func stubMock() {
    
    savedStub = stub(isHost("stubbed_request.com")) { _ in
      
      
      return OHHTTPStubsResponse(JSONObject: self.JSONObject, statusCode: 200, headers: nil).requestTime(1.0, responseTime: 3.0)
    }
  }
  
  private func stubMock(executionBlock:(request:NSURLRequest) -> Void) {
    
//    savedStub = stub(
    savedStub = stub(isHost("stubbed_request.com")) { request in
     
      executionBlock(request:request)
      return OHHTTPStubsResponse(JSONObject: self.JSONObject, statusCode: 200, headers: nil).requestTime(1.0, responseTime: 3.0)
    }
  }
  
  func stubError(code:Int) {
    savedStub = stub(isHost("stubbed_request.com")) { _ in
      
      let errorObject = [
        "error": "Stub for error",
        "errorDescription": "sunt aut facere repellat provident occaecati excepturi optio reprehenderit",
        ]
      
      return OHHTTPStubsResponse(JSONObject: errorObject, statusCode: Int32(code), headers: nil).requestTime(1.0, responseTime: 3.0)
    }
  }
  
  override func setUp() {
    super.setUp()
    
    if nil == manager {
      manager = DataRetrievalOperationManager(remote:"http://stubbed_request.com")
      manager.accessKey = "some_key"
    }
    manager.session = NSURLSession(configuration: NSURLSessionConfiguration.defaultSessionConfiguration())
  }
  
  override func tearDown() {
    super.tearDown()
    OHHTTPStubs.removeAllStubs()
    OHHTTPStubs.setEnabled(false)
  }
  
  func testSimpleOperation() {
    
    stubMock()
    
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
      
      XCTAssertEqual(self.manager.operations.count, 0)
      
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
    XCTAssertEqual(operation.requestEndPoint, "http://stubbed_request.com")
    XCTAssertNotNil(operation.request)
    XCTAssertEqual(operation.request?.URL?.absoluteString, "http://stubbed_request.com/posts")
    XCTAssertTrue(completed)
  }
  
  func testAccessToken() {
    stubMock()
    
    let operation = SampleAcceessTokenOperation()
    XCTAssertNotNil(operation)
    XCTAssertNotNil(operation.requestParameters)
    XCTAssertNil(operation.requestParameters["key"])
    let expct:XCTestExpectation = self.expectationWithDescription("Awaiting request")
    
    manager.addOperations([operation]) { (success, results, errors) -> Void in
      expct.fulfill()
    }
    
    XCTAssertNotNil(operation.requestParameters["key"])
    XCTAssertEqual(operation.requestParameters["key"] as? String, "some_key")
    waitForExpectationsWithTimeout(30.0, handler: nil)
  }
  
  func testError() {
    stubError(400)
    
    let operation = SampleNetworkSyncOperation()
    var completed:Bool = false
    let expct:XCTestExpectation = self.expectationWithDescription("Awaiting request")
    manager.addOperations([operation]) { (success, results, errors) -> Void in
      XCTAssertFalse(success)
      XCTAssertNotNil(errors)
      XCTAssertNotNil(results)
      XCTAssertEqual(results.count, 0)
      
      if let errors = errors,
        let error = errors.first as? DataRetrievalOperationError {
        
        switch error {
        case .ServerResponse(let errorCode, let errorResponse, _) :
          XCTAssertEqual(errorCode, 400)
          XCTAssertNotNil(errorResponse)
        default:
          XCTAssertTrue(false, "ServerResponse error expected")
        }
      } else {
        XCTAssert(false, "Errors expected")
      }
      
      XCTAssertEqual(self.manager.operations.count, 0)
      
      XCTAssertEqual(operation.stage, OperationStage.Requesting)
      XCTAssertEqual(operation.status, OperationStatus.Error)
      completed = true
      expct.fulfill()
    }
    
    XCTAssertEqual(manager.operations.count, 2)
    
    XCTAssertFalse(completed)
    
    self.waitForExpectationsWithTimeout(300.0) { (error:NSError?) -> Void in
      XCTAssertNil(error)
    }
  }
  
  func testGetOperationParams() {
    stubMock { (request) in
      let requestString = request.URL!.absoluteString
      XCTAssertTrue(requestString!.containsString("key=value"))
      XCTAssertTrue(requestString!.containsString("another=1"))
      XCTAssertEqual(request.HTTPMethod, "GET")
      if let headers = request.allHTTPHeaderFields {
        XCTAssertEqual(headers["header_key"], "header_value")
      } else {
        XCTAssert(false, "Header expected")
      }
    }
    
    let operation = SampleNetworkSyncOperation()
    operation.requestParameters = ["key" : "value", "another" : 1]
    operation.requestHeaders = ["header_key" : "header_value"]
    XCTAssertNotNil(operation)
    XCTAssertNotNil(operation.requestParameters)
    let expct:XCTestExpectation = self.expectationWithDescription("Awaiting request")
    
    manager.addOperations([operation]) { (success, results, errors) -> Void in
      expct.fulfill()
    }
    waitForExpectationsWithTimeout(30.0, handler: nil)
    
  }
  
  func testPostOperationParams() {
    
    // OHHTTPMocks has limitations: request body is colapsed and can not be verified
    stubMock { (request) in
      let requestString = request.URL!.absoluteString
      // Keys shouldn't contains keys in request string
      XCTAssertFalse(requestString!.containsString("key=value"))
      XCTAssertFalse(requestString!.containsString("another=1"))
      
      XCTAssertEqual(request.HTTPMethod, "POST")
      if let headers = request.allHTTPHeaderFields {
        XCTAssertEqual(headers["header_key"], "header_value")
      } else {
        XCTAssert(false, "Header expected")
      }
    }
    
    let operation = SampleNetworkSyncOperation()
    operation.requestParameters = ["key" : "value", "another" : 1]
    operation.requestHeaders = ["header_key" : "header_value"]
    operation.requestMethod = .POST
    XCTAssertNotNil(operation)
    XCTAssertNotNil(operation.requestParameters)
    let expct:XCTestExpectation = self.expectationWithDescription("Awaiting request")
    
    manager.addOperations([operation]) { (success, results, errors) -> Void in
      expct.fulfill()
    }
    waitForExpectationsWithTimeout(30.0, handler: nil)
    
  }
  
  
}

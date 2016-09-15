
//
//  ImageNetworkOperationTests.swift
//  DataOperationKit
//
//  Created by Mykhailo Vorontsov on 12/04/2016.
//  Copyright © 2016 Mykhailo Vorontsov. All rights reserved.
//

import XCTest
import OHHTTPStubs
@testable import DataOperationKit

class ImageNetworkOperationTests: XCTestCase {
  
  var manager:DataRetrievalOperationManager! = nil
  
  override func setUp() {
    super.setUp()
    
    if nil == manager {
      manager = DataRetrievalOperationManager(remote:"http://stubbed_request.com")
      manager.accessKey = "some_key"
    }
    
  }
  
  override func tearDown() {
    OHHTTPStubs.removeAllStubs()
    super.tearDown()
  }
  
  private func stubMock() {
    let bundle = NSBundle(forClass: ImageNetworkOperationTests.self)
    stub(isHost("stubbed_request.com")) { _ in
      let imageURL = bundle.URLForResource("test", withExtension: "jpeg")
      return OHHTTPStubsResponse(fileURL: imageURL!, statusCode: 200, headers: nil)
    }
  }
  
  private func stubError() {
    stub(isHost("wrong_stubbed_request.com")) { _ in
      let JSONObject = ["error": 0]
      return OHHTTPStubsResponse(JSONObject: JSONObject, statusCode: 500, headers: nil).requestTime(0.1, responseTime: 0.1)
    }
  }
  
  func testImageOperationShortPath() {
    stubMock()
    stubError()
    let operation = ImageNetworkOperation(imagePath: "/image")
    operation.cache = false
    let exp = expectationWithDescription("Operation expectation")
    manager.addOperations([operation]) { (success, results, errors) in
      XCTAssertTrue(success)
      XCTAssertEqual(results.count, 1)
      let fetchedImage = results.first as? UIImage
      XCTAssertNotNil(fetchedImage)
      exp.fulfill()
    }
    waitForExpectationsWithTimeout(60.0, handler: nil)
  }
  
  func testImageOperationWithFullName() {
    stubMock()
    stubError()
    let operation = ImageNetworkOperation(imagePath: "http://wrong_stubbed_request.com/image")
    operation.cache = false
    let exp = expectationWithDescription("Operation expectation")
    manager.addOperations([operation]) { (success, results, errors) in
      XCTAssertFalse(success)
      exp.fulfill()
    }
    waitForExpectationsWithTimeout(60.0, handler: nil)
  }
 
}

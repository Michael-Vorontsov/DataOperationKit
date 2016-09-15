//
//  CachedNetworkOperationTests.swift
//  DataOperationKit
//
//  Created by Mykhailo Vorontsov on 12/04/2016.
//  Copyright © 2016 Mykhailo Vorontsov. All rights reserved.
//

import XCTest
import OHHTTPStubs
@testable import DataOperationKit

//
//class SampleCacheOperation:NetworkDataRetrievalOperation {
//  override func retriveData() throws {
//    
//    stage = .Requesting
//    
//    var shouldRequestFromNetwork = true
//    var cacheURL:NSURL? = nil
//    
//    //Try to retrive data from cache first
//    if let request = request where true == cache {
//      let cacheName = String(request.hash)
//      let cacheDirectory = NSFileManager.applicationCachesDirectory
//      let fileURL = cacheDirectory.URLByAppendingPathComponent(cacheName)
//      cacheURL = fileURL
//      if let content = NSData(contentsOfURL: fileURL) {
//        data = content
//        shouldRequestFromNetwork = false
//      }
//      
//    }
//    // Retrieve from network if no file avaialble
//    if shouldRequestFromNetwork {
//      try super.retriveData()
//      // And save it to cahce if needed
//      if let fileURL = cacheURL, let fileData = data where false == cancelled {
//        do {
//          try fileData.writeToURL(fileURL, options: .DataWritingAtomic)
//        } catch {
//          throw DataRetrievalOperationError.InternalError(error: error)
//        }
//      }
//    }
//  }
//}

class CachedNetworkOperationTests: XCTestCase {
  
  var manager:DataRetrievalOperationManager! = nil
  
  override func setUp() {
    super.setUp()
    
    if nil == manager {
      manager = DataRetrievalOperationManager(remote:"http://stubbed_request.com")
      manager.accessKey = "some_key"
    }
    
    //Clear cache directory
    let fileManager = NSFileManager.defaultManager()
    let cacheDirectory = NSFileManager.applicationCachesDirectory
    if  let content = try? fileManager.contentsOfDirectoryAtURL(cacheDirectory, includingPropertiesForKeys: nil, options: NSDirectoryEnumerationOptions(rawValue: 0)) {
      for file in content {
        _ = try? fileManager.removeItemAtURL(file)
      }
    }
    
  }
  
  override func tearDown() {
    OHHTTPStubs.removeAllStubs()
    super.tearDown()
  }
  
  private func stubMock() {
    stub(isHost("stubbed_request.com")) { _ in
      let JSONObject = ["key": 1]
      return OHHTTPStubsResponse(JSONObject: JSONObject, statusCode: 200, headers: nil).requestTime(0.1, responseTime: 0.1)
    }
  }
  
  private func stubError() {
    stub(isHost("stubbed_request.com")) { _ in
      let JSONObject = ["error": 0]
      return OHHTTPStubsResponse(JSONObject: JSONObject, statusCode: 500, headers: nil).requestTime(0.1, responseTime: 0.1)
    }
  }
  
  func testOperationWithoutCache() {
    stubMock()
    let operation = NetCacheDataRetrievalOperation()
    operation.cache = false
    let exp = expectationWithDescription("Operation expectation")
    manager.addOperations([operation]) { (success, results, errors) in
      
      XCTAssertTrue(success)
      exp.fulfill()
    }
    waitForExpectationsWithTimeout(60.0, handler: nil)
    XCTAssertNotNil(operation.convertedObject)
    if let convertedObject = operation.convertedObject as? [String : Int] {
      XCTAssertEqual(convertedObject["key"], 1)
    } else {
      XCTAssert(false, "Dictionary expected")
    }
  }
  
  func testOperationErrorWithoutCache() {
    stubError()
    let operation = NetCacheDataRetrievalOperation()
    operation.cache = false
    let exp = expectationWithDescription("Operation expectation")
    manager.addOperations([operation]) { (success, results, errors) in
      XCTAssertFalse(success)
      exp.fulfill()
    }
    waitForExpectationsWithTimeout(60.0, handler: nil)
  }
  
  func testOperationErrorWithCache() {
    stubError()
    let operation = NetCacheDataRetrievalOperation()
//    let operation = NetworkDataRetrievalOperation()
    operation.cache = false
    let exp = expectationWithDescription("Operation expectation")
    manager.addOperations([operation]) { (success, results, errors) in
      XCTAssertFalse(success)
      exp.fulfill()
    }
    waitForExpectationsWithTimeout(60.0, handler: nil)
  }
  
  func testOperationWithCache() {
    stubMock()
    let operation = NetCacheDataRetrievalOperation()
    operation.cache = true
    let exp = expectationWithDescription("Operation expectation")
    manager.addOperations([operation]) { (success, results, errors) in
      XCTAssertTrue(success)
      exp.fulfill()
    }
    waitForExpectationsWithTimeout(60.0, handler: nil)
    XCTAssertNotNil(operation.convertedObject)
    
    
    if let convertedObject = operation.convertedObject as? [String : Int] {
      XCTAssertEqual(convertedObject["key"], 1)
    } else {
      XCTAssert(false, "Dictionary expected")
    }
    
    OHHTTPStubs.removeAllStubs()
    stubError()
    
    let nonCachedOperation = NetCacheDataRetrievalOperation()
    nonCachedOperation.cache = false
    let exp2 = expectationWithDescription("Operation expectation")
    manager.addOperations([nonCachedOperation]) { (success, results, errors) in
      XCTAssertFalse(success)
      exp2.fulfill()
    }
    waitForExpectationsWithTimeout(60.0, handler: nil)
    XCTAssertNil(nonCachedOperation.convertedObject)
    
    
    let cachedOperation = NetCacheDataRetrievalOperation()
    cachedOperation.cache = true
    let exp3 = expectationWithDescription("Operation expectation")
    manager.addOperations([cachedOperation]) { (success, results, errors) in
      XCTAssertTrue(success)
      exp3.fulfill()
    }
    waitForExpectationsWithTimeout(60.0, handler: nil)
    
    if let convertedObject = cachedOperation.convertedObject as? [String : Int] {
      XCTAssertEqual(convertedObject["key"], 1)
    } else {
      XCTAssert(false, "Dictionary expected")
    }
  }
  
}

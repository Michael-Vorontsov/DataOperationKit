//
//  NetworkDataRetrievalOperationProtocol.swift
//  DataOperationKit
//
//  Created by Mykhailo Vorontsov on 08/04/2016.
//  Copyright © 2016 Mykhailo Vorontsov. All rights reserved.
//

import Foundation

public enum NetworkRequestMethod:String {
  case GET
  case POST
}

// Additional methods and encoding types can be added, if needed
public enum NetworkParameterEncoding:String {
  case JSON = "application/json"
}

/**
 Public inteface for Network Retrieval operation.
 
 Based on Common data Retrieval operation, (see: DataRetrievalOperationProtocol)
 
 Contains fields specific for network operations. Based on them, NSURLRequest shoould be generated during Preapare stage,
 and executed during Retrieval stage.
 
 By default operation expected JSON data, so JSON objects trying to generate during Convert stages.
 Parsing stage expected to be override in specific network operations.
 
 By default paramters passed as URL encoding suffix for get operations, or as JSON data in request body for POST operations
 
 To generate custom request, prepareForRetrieval() should be overriden
 */
public protocol NetworkDataRetrievalOperationProtocol: DataRetrievalOperationProtocol {
  
  var task: NSURLSessionTask? {get set}
  var session:NSURLSession? {get set}
  
  var request: NSURLRequest? {get set}
  var requestEndPoint: String? {get set}
  var requestPath: String? {get set}
  
  var requestParameters: [String : AnyObject]! {get set}
  var requestHeaders: [String : AnyObject]! {get set}
  
  var requestMethod: NetworkRequestMethod {get set}
  var requestParametersEncoding: NetworkParameterEncoding {get set}
  
//  var requestCache:Bool? {get set}
//  var cache:Bool? {get set}

  
  var response:NSURLResponse? {get set}
}

public protocol NetCacheDataRetrievalOperationProtocol: DataRetrievalOperationProtocol {
  var cache:Bool? {get set}
}


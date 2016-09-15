//
//  NetworkDataRetrievalOperation.swift
//  DataOperationKit
//
//  Created by Mykhailo Vorontsov on 29/03/2016.
//  Copyright © 2016 Mykhailo Vorontsov. All rights reserved.
//

import Foundation

private let Consts = (
  networkTimeout : 60.0,
  allowedCharacters : (
    generalDelimitersToEncode : ":#[]@", // does not include "?" or "/" due to RFC 3986 - Section 3.4
    subDelimitersToEncode : "!$&'()*+,;="
  ),
  
  headerContentTypeKey : "Content-Type"
)

public class NetworkDataRetrievalOperation: DataRetrievalOperation, NetworkDataRetrievalOperationProtocol {
  
  public var task: NSURLSessionTask? = nil
  public var session:NSURLSession? = nil
  public var request: NSURLRequest? = nil
  public var requestEndPoint: String? = nil
  public var requestPath: String? = nil
  
  public var cache:Bool? = false
  
  public var requestMethod: NetworkRequestMethod = .GET
  public var requestParametersEncoding: NetworkParameterEncoding = .JSON
  
  public lazy var requestParameters: [String : AnyObject]! = {
    return [String : AnyObject]()
  }()
  
  public lazy var requestHeaders: [String : AnyObject]! = {
    return [String : AnyObject]()
  }()
  

  public var response: NSURLResponse? = nil
  
  func encodeParameters(parameters:[String : AnyObject]) -> String {
    var parametersString = ""
    let generalDelimitersToEncode = Consts.allowedCharacters.generalDelimitersToEncode
    let subDelimitersToEncode = Consts.allowedCharacters.subDelimitersToEncode
    
    let allowedCharacterSet = NSCharacterSet.URLQueryAllowedCharacterSet().mutableCopy() as! NSMutableCharacterSet
    allowedCharacterSet.removeCharactersInString(generalDelimitersToEncode + subDelimitersToEncode)
    
    for (key, value) in parameters {
      parametersString += parametersString.characters.count > 0 ? "&" : ""
      if let formattedKey = NSString(string:key).stringByAddingPercentEncodingWithAllowedCharacters(allowedCharacterSet),
        let formattedValue = NSString(string:String(value)).stringByAddingPercentEncodingWithAllowedCharacters(allowedCharacterSet) {
        parametersString += "\(formattedKey)=\(formattedValue)"
      }
    }
    return parametersString
  }
  
  override public func prepareForRetrieval() throws {
    try super.prepareForRetrieval()
    // Generate base URL by endPoint. No request possible without endPoint
    guard
      let base = requestEndPoint,
      var url = NSURL(string: base)
      else {
        throw DataRetrievalOperationError.InvalidParameter(parameterName: "URL")
    }
    // Add path if any
    if let path = requestPath {
      url = url.URLByAppendingPathComponent(path)!
    }
    
    let method = requestMethod
    
    if  requestParameters.count > 0 {
      switch method {
      case .GET:
        let parametersString = encodeParameters(requestParameters)
        url = NSURL(string: "?" + parametersString, relativeToURL: url) ?? url
      case .POST:
        //TODO: Insert some code for assembling POST reuqest if needed
        break
      }
    }
    
    //MARK: Construct request
    let theRequest = NSMutableURLRequest(URL:url)
    theRequest.HTTPMethod = method.rawValue
    
//    var headers = requestHeaders
    var headers = [String : AnyObject]()
    requestHeaders = headers
    headers[Consts.headerContentTypeKey] = requestParametersEncoding.rawValue
    for (key, value) in headers {
      guard let value = value as? String else {
        continue
      }
      theRequest.addValue(value, forHTTPHeaderField: key)
    }
    
    request = theRequest
  }
  
  override public func retriveData() throws {
    try super.retriveData()
    
    // If no particular session specified - use shared session
    if nil == session {
      session = NSURLSession.sharedSession()
    }
    
    guard let session = session,
      let request = request else {
        throw DataRetrievalOperationError.InvalidParameter(parameterName: "Session")
    }
    let semaphore = dispatch_semaphore_create(0)
    var inTaskError:DataRetrievalOperationError? = nil
    
    task = session.dataTaskWithRequest(request) {[unowned self] (data, response, nserror) -> Void in
      
      guard false == self.cancelled else {
        return
      }
      
      self.response = response
      self.data = data
      
//      // For debug purpose: print string representation of response data, if any. Uncoment code bellow.
//            if let data = data {
//              let stringRepresentation = NSString(data: data, encoding: 0)
//              print("Request:\(self.task?.originalRequest)\nResponse:\(response)\nData:\(stringRepresentation)")
//            }
      
      // Process possible network layer errors:
      if let nserror = nserror {
        inTaskError = DataRetrievalOperationError.NetworkError(error: nserror)
        
      }
      //  Process server errors
      if let response = response as? NSHTTPURLResponse,
        let statusCode:Int = response.statusCode where false == (200 ..< 299 ~= statusCode) && nil == inTaskError {
        inTaskError = DataRetrievalOperationError.ServerResponse(errorCode: statusCode, errorResponse: response, responseData: data)
        
      }
      
      // Release semaphore
      dispatch_semaphore_signal(semaphore)
    }
    
    guard let task = task else {
      throw DataRetrievalOperationError.InvalidParameter(parameterName: "Task")
    }
    task.resume()
    
    let timeout = session.configuration.timeoutIntervalForRequest + 1.0
    dispatch_semaphore_wait(semaphore, dispatch_time(DISPATCH_TIME_NOW, Int64(timeout * Double(NSEC_PER_SEC))))
    
    // If error occured during netwrok tesk execution - throw
    if let taskError = inTaskError {
      throw taskError
    }
    
    // If network task doesn't completed - throw
    guard .Completed == task.state else {
      throw DataRetrievalOperationError.NetworkError(error: nil)
    }
  }
  
  public override func convertData() throws {
    try super.convertData()
    guard let data = data else {
      throw DataRetrievalOperationError.WrongDataFormat(error: nil)
    }
    do {
      let converted = try NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions(rawValue:0))
      convertedObject = converted
    }
    catch {
      throw DataRetrievalOperationError.WrongDataFormat(error: error)
    }
  }
  
  public override func cancel() {
    task?.cancel()
    super.cancel()
  }
  
}

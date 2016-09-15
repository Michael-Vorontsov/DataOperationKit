//
//  NetCacheDataRetrievalOperation.swift
//  DataOperationKit
//
//  Created by Mykhailo Vorontsov on 27/04/2016.
//  Copyright © 2016 Mykhailo Vorontsov. All rights reserved.
//

import Foundation
//@testable import DataOperationKit

public class NetCacheDataRetrievalOperation: NetworkDataRetrievalOperation, NetCacheDataRetrievalOperationProtocol {
  
//  public var cache:Bool? = false

  override public func retriveData() throws {
    
    stage = .Requesting
    
    var shouldRequestFromNetwork = true
    var cacheURL:NSURL? = nil
    
    //Try to retrive data from cache first
    if let request = request where true == cache {
      let cacheName = String(request.hash)
      let cacheDirectory = NSFileManager.applicationCachesDirectory
      let fileURL = cacheDirectory.URLByAppendingPathComponent(cacheName)
      cacheURL = fileURL
      if let content = NSData(contentsOfURL: fileURL!) {
        data = content
        shouldRequestFromNetwork = false
      }
      
    }
    // Retrieve from network if no file avaialble
    if shouldRequestFromNetwork {
      try super.retriveData()
      // And save it to cahce if needed
      if let fileURL = cacheURL, let fileData = data where false == cancelled {
        do {
          try fileData.writeToURL(fileURL, options: .DataWritingAtomic)
        } catch {
          throw DataRetrievalOperationError.InternalError(error: error)
        }
      }
    }
  }
  
}

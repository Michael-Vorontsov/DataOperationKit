//
//  ImageNetworkOperation.swift
//  DataOperationKit
//
//  Created by Mykhailo Vorontsov on 12/04/2016.
//  Copyright © 2016 Mykhailo Vorontsov. All rights reserved.
//

/**
 Operation for loading image from cache or remote location.
 
 Actually is a general kind of operations and can be moved to DataRetrievalKit
 */
public class ImageNetworkOperation: NetCacheDataRetrievalOperation {
  
  private let imagePath:String
  
  public init(imagePath:String) {
    self.imagePath = imagePath
    super.init()
  }
  
  public override func prepareForRetrieval() throws {
    cache = true
    // If path contains ':/' then it is a full address,
    // else it is a local address and should by added to endpoint
    if imagePath.containsString(":/") {
      requestEndPoint = imagePath
    } else {
      requestPath = imagePath
    }
    try super.prepareForRetrieval()
  }
  
  // Convert and parse data
  public override func convertData() throws {
//    stage = .Converting
//    guard let data = data,
//      let image = UIImage(data: data) else {
//        throw DataRetrievalOperationError.WrongDataFormat(error: nil)
//    }
//    stage = .Parsing
//    results = [image]
  }
  
  
}

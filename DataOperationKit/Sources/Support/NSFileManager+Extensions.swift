//
//  NSFileManager+Extensions.swift
//  DataOperationKit
//
//  Created by Mykhailo Vorontsov on 18/03/2016.
//  Copyright © 2016 Mykhailo Vorontsov. All rights reserved.
//

import Foundation

extension NSFileManager {
  /**
   Return application document directory
   */
  @nonobjc static let applicationDocumentsDirectory: NSURL = {
    let urls = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)
    return urls.last!
  }()
  
  /**
   Return application cache directory
   */
  @nonobjc static let applicationCachesDirectory: NSURL = {
    let urls = NSFileManager.defaultManager().URLsForDirectory(.CachesDirectory, inDomains: .UserDomainMask)
    return urls.last!
  }()

  
}

//
//  GroupDataRetrievalOperation.swift
//  OfflineCommute
//
//  Created by Mykhailo Vorontsov on 27/07/2016.
//  Copyright © 2016 Mykhailo Vorontsov. All rights reserved.
//

import UIKit

class GroupDataRetrievalOperation: DataRetrievalOperation, GroupDataRetrievalOperationProtocol {
  
//  var operationQueue: NSOperationQueue! = nil
  
  var operationManager:DataRetrievalOperationManager! = nil
  var operations: [NSOperation]! = nil
  
  
  override func retriveData() throws {
    
    let semaphor = dispatch_semaphore_create(0)
    
    let completionOperation = NSBlockOperation(block: {
      dispatch_semaphore_signal(semaphor)
    })
    
    for eachOperation in operations {
      completionOperation.addDependency(eachOperation)
    }
    
    operationManager.addOperations(operations)
    operationManager.addOperations([completionOperation])
    
    dispatch_semaphore_wait(semaphor, DISPATCH_TIME_FOREVER)
    
  }

  override func convertData() throws {
    var results = [AnyObject]()
    for operation in operations {
      if let operation = operation as? DataRetrievalOperation {
        if let operationResults = operation.results  {
          results.append(operationResults)
        }
        if let error = operation.error {
          throw error
        }
      }
    }
  }
  
  override func cancel() {
    for eachOperation in operations {
      eachOperation.cancel()
    }
    super.cancel()
  }
  
}

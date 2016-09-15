//
//  DataRetrievalOperationManager.swift
//  DataOperationKit
//
//  Created by Mykhailo Vorontsov on 01/04/2016.
//  Copyright © 2016 Mykhailo Vorontsov. All rights reserved.
//

import Foundation

// TODO: Remove hardcoded constants to app delegate
private let Consts = (
  
  defalutBackend : "http://google.com",
  accessKeyParam : "key"
)

public protocol DataRequestor:NSObjectProtocol {
  var dataOperationManager:DataRetrievalOperationManager! {get set}
}

public typealias DataRetrivalCompetionBlock = (success: Bool, results: [AnyObject], errors: [ErrorType]?) -> Void

/**
 Class responsible for retriving data from remote servever.
 
 For each data type specific operation should be created.
 */
public class DataRetrievalOperationManager: NSObject {
  
  public let endPoint:String
  
  public var accessKey:String? = nil
  
  public init(remote:String, accessKey:String? = nil){
    endPoint = remote
    self.accessKey = accessKey
    super.init()
  }
  
  public lazy var session:NSURLSession = {
    return NSURLSession.sharedSession()
  }()
  
  public override convenience init() {
    self.init(remote:Consts.defalutBackend)
  }
  
  public var coreDataManager:CoreDataManager? = nil
  
  public var objectBuilder:ObjectBuilder? = nil
  
  /**
   Shared instance of Data Retrieval Operation Manager be accessible in different part of application
   */
  public static let sharedManager = DataRetrievalOperationManager()
  
  /**
   Operation queue
   */
  private lazy var operationQueue: NSOperationQueue = {
    return NSOperationQueue()
  }()
  
  var operations:[NSOperation] {
    return operationQueue.operations
  }
  
  public var suspended:Bool {
    set {
      operationQueue.suspended = newValue
    }
    get {
      return operationQueue.suspended
    }
  }
  
  
  //  public private(set) lazy var operations:[NSOperation] = {
  //    return [NSOperation]()
  //  }()
  
  /**
   Helpers function for creating completion block operation for specififc operations
   */
  private func completionBlockOperationForOperations(operations:[NSOperation],
                                                     completionBLock: DataRetrivalCompetionBlock?) -> NSOperation {
    
    let completionOperation = NSBlockOperation {() -> Void in
      var success = true
      var errors:[ErrorType]? = nil
      var results:[AnyObject] = []
      
      for operation in operations {
        if  true != operation.finished || true == operation.cancelled {
          success = false
        }
        if let operation = operation as? DataRetrievalOperationProtocol {
          
          if operation.status != .Completed {
            if let opError = operation.error {
              if nil == errors {
                errors = [NSError]()
              }
              errors?.append(opError)
            }
            success = false
          }
          if operation.results?.count > 0 {
            results.appendContentsOf(operation.results!)
          }
        }
      }
      
      if let completionBLock = completionBLock {
        NSOperationQueue.mainQueue().addOperationWithBlock({ () -> Void in
          for operation in operations {
            print("Completion block for: \(operation.name ?? "-")")
          }
          completionBLock(success: success, results: results, errors: errors)
        })
      }
    }
    return completionOperation
  }
  
  /**
   Configure operation, add auth headers, endpoints, sesions etc.
   */
  public func prepareOperation(operation:NSOperation) {
    
    //Setup endpoints for all operations
    if let operation = operation as? NetworkDataRetrievalOperationProtocol where nil == operation.requestEndPoint {
      operation.requestEndPoint = self.endPoint
      operation.session = session
    }
    
    if let operation = operation as? ManagedObjectRetrievalOperationProtocol where nil == operation.dataManager {
      operation.dataManager = self.coreDataManager
    }
    
    if let operation = operation as? AccessKeyOperationProtocol, let accessKey = accessKey where  nil == operation.requestParameters[Consts.accessKeyParam] {
      operation.requestParameters[Consts.accessKeyParam] = accessKey
    }
    
    if let operation = operation as? ObjectBuildeOperationProtocol where nil == operation.objectBuilder {
      operation.objectBuilder = self.objectBuilder
    }
    
    if let operation = operation as? GroupDataRetrievalOperationProtocol where nil == operation.operationManager {
      operation.operationManager = self
    }
    
  }
  
  /**
   Add operations to Queue with completion block.
   Operation should be just created and not executed in any other queue.
   If equal operation already in queue -> then switch all dependecies including completion block to queued one,
   and mark operation as Duplicate
   */
  public func addOperations(operations: [NSOperation],
                            completionBLock:DataRetrivalCompetionBlock? = nil) -> Void {
    
    dispatch_sync(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) { [unowned self] in
      
      
      let completionOperation = self.completionBlockOperationForOperations(operations, completionBLock: completionBLock)
      var operationToAdd = [NSOperation]()
      operationToAdd.append(completionOperation)
      let queuedOperations = self.operations as NSArray
      
      for operation in operations {
        // Attach comppletion operation
        completionOperation.addDependency(operation)
        
        // Skip is not in Created state
        if let operation = operation as? DataRetrievalOperationProtocol where operation.status != .Created {
          continue
        }
        
        operationToAdd.append(operation)
        
        //TODO: Complete
        let indexOfSameOperation = queuedOperations.indexOfObject(operation)
        
        // Is similar operation already in queue
        if indexOfSameOperation != NSNotFound, let sameOperation = queuedOperations[indexOfSameOperation] as? NSOperation {
          if let operation = operation as? DataRetrievalOperationProtocol {
            operation.status = .Duplicate
          }
          operation.addDependency(sameOperation)
        } else {
          self.prepareOperation(operation)
          if let operation = operation as? DataRetrievalOperationProtocol {
            operation.status = .Queued
          }
        }
        
      }
      self.operationQueue.addOperations(operationToAdd, waitUntilFinished: false)
    }
  }
  
}


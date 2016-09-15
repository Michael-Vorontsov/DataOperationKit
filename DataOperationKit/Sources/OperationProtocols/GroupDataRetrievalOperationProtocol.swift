//
//  GroupDataRetrievalOperation.swift
//  OfflineCommute
//
//  Created by Mykhailo Vorontsov on 27/07/2016.
//  Copyright © 2016 Mykhailo Vorontsov. All rights reserved.
//

import Foundation

protocol GroupDataRetrievalOperationProtocol: DataRetrievalOperationProtocol {
  
  var operationManager:DataRetrievalOperationManager! {get set}

}
//
//  AttachmentToImageAttachmentMigrationPolicyV3toV4.swift
//  UnCloudNotes
//
//  Created by Skyler Svendsen on 5/26/18.
//  Copyright © 2018 Ray Wenderlich. All rights reserved.
//

import Foundation
import CoreData
import UIKit

let errorDomain = "Migration"

class AttachmentToImageAttachmentMigrationPolicyV3toV4: NSEntityMigrationPolicy {
  
  override func createDestinationInstances(forSource sInstance: NSManagedObject, in mapping: NSEntityMapping, manager: NSMigrationManager) throws {
    //1
    let description = NSEntityDescription.entity(forEntityName: "ImageAttachment", in: manager.destinationContext)
    let newAttachment = ImageAttachment(entity: description!, insertInto: manager.destinationContext)
    
    //2
    func traversePropertyMappings(block: (NSPropertyMapping, String) -> ()) throws {
      if let attributeMappings = mapping.attributeMappings {
        for propertyMapping in attributeMappings {
          if let destinationName = propertyMapping.name {
            block(propertyMapping, destinationName)
          } else {
            let message = "Attribute destination not configured properly"
            let userInfo = [NSLocalizedFailureReasonErrorKey: message]
            throw NSError(domain: errorDomain, code: 0, userInfo: userInfo)
          }
        }
      } else {
        //3
        let message = "No Attribute Mappings found!"
        let userInfo = [NSLocalizedFailureReasonErrorKey: message]
        throw NSError(domain: errorDomain, code: 0, userInfo: userInfo)
      }
    }
    
    //4
    try traversePropertyMappings { propertyMapping, destinationName in
      guard let valueExpression = propertyMapping.valueExpression else { return }
      
      let context: NSMutableDictionary = ["source": sInstance]
      guard let destinationValue = valueExpression.expressionValue(with: sInstance, context: context) else { return }
      
      newAttachment.setValue(destinationValue, forKey: destinationName)
    }
    
    //5
    if let image = sInstance.value(forKey: "image") as? UIImage {
      newAttachment.setValue(image.size.width, forKey: "width")
      newAttachment.setValue(image.size.height, forKey: "height")
    }
    
    //6
    let body = sInstance.value(forKeyPath: "note.body") as? NSString ?? ""
    newAttachment.setValue(body.substring(to: 80), forKey: "caption")
    
    //7
    manager.associate(sourceInstance: sInstance, withDestinationInstance: newAttachment, for: mapping)
  }
}

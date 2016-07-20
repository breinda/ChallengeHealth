//
//  Goal.swift
//  ChallengeHealth
//
//  Created by Brenda Carrocino on 18/07/16.
//  Copyright © 2016 Brenda Carrocino. All rights reserved.
//

import UIKit

struct Goal {
    let name : String!
    let description : String!
    let steps : [Step]!
    
    init(name: String, description: String, steps: [Step]) {
        
        self.name = name
        self.description = description
        self.steps = steps
    }
    
}
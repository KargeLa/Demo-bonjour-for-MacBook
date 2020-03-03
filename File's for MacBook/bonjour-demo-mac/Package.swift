//
//  Package.swift
//  bonjour-demo-mac
//
//  Created by Алексей Смоляк on 3/3/20.
//  Copyright © 2020 James Zaghini. All rights reserved.
//

import Foundation

enum ActionType: Int {
    case play/*0*/, pause/*1*/, next/*2*/, prev/*3*/, volume/*4*/, time/*5*/
}

struct Package: Decodable {
    var maxCurrentTime: Int?
    var currentTime: Int?
    var currentVolume: Float?
    var action: Int?
}

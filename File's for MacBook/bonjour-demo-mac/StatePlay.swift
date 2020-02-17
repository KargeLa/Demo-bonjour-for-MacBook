//
//  StatePlay.swift
//  bonjour-demo-mac
//
//  Created by Ilya Lagutovsky on 2/17/20.
//  Copyright © 2020 James Zaghini. All rights reserved.
//

import Foundation

enum StatePlay: String {
    case playningMusic
    case notPlayningMusic
    
    var opposite: StatePlay {
        switch self {
        case .playningMusic:
            return .notPlayningMusic
        case .notPlayningMusic:
            return .playningMusic
        }
    }
}

//
//  Model.swift
//  bonjour-demo-mac
//
//  Created by Ilya Lagutovsky on 1/15/20.
//  Copyright © 2020 James Zaghini. All rights reserved.
//

import Foundation

struct SoundPlayer: Codable {
    var titleSound: String
    var titleAlbum: String
    var imageData: Data
}

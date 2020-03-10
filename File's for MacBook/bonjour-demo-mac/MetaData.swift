//
//  Package.swift
//  bonjour-demo-mac
//
//  Created by Алексей Смоляк on 3/3/20.
//  Copyright © 2020 James Zaghini. All rights reserved.
//

import Foundation

enum ActionType: Int {
    case connect, play, pause, next, prev, volume, time, changedTrack, changedDir
}

struct MetaData: Codable {
    var title: String
    var albumName: String
    var albumArt: Data
}
struct FileSystem: Codable {
    var folder: Bool?
    var track: Bool?
}

struct PlayerManager: Codable {
    var pathNewFolder: String?
    var fileSystem: [File]?
    var currentTrack: MetaData?
    var action: Int?
    var maxCurrentTime: Int?
    var currentTime: Int?
    var currentVolume: Float?
    var currentTrackName: String?
    
    var json: Data? {
        guard let data = try? JSONEncoder().encode(self) else { return nil }
        return data
    }
}


struct File: Codable {
    var name: String
    var type: TypeFile
    var path: String
}

enum TypeFile: String, Codable {
    case music
    case folder
}

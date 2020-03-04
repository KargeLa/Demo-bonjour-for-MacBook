//
//  TrackModel.swift
//  bonjour-demo-mac
//
//  Created by Ilya Lagutovsky on 1/31/20.
//  Copyright © 2020 James Zaghini. All rights reserved.
//

import Foundation

//struct TrackList: Codable {
//    var tracksInformation: [TrackInformation]
//    var currentTrack: TrackInformation
//    
//    func searchTrack(byTrackName trackName: String) -> TrackInformation? {
//        return tracksInformation.first { $0.trackName == trackName }
//    }
//    
//    mutating func nextTrack() -> TrackInformation? {
//       if currentTrack.trackName == tracksInformation.last?.trackName {
//            return nil
//        } else {
//            guard let currentIndex = tracksInformation.firstIndex(where: { $0.trackName == currentTrack.trackName }) else { return nil }
//            currentTrack = tracksInformation[currentIndex + 1]
//            return currentTrack
//        }
//    }
//    
//    mutating func prevTrack() -> TrackInformation? {
//       if currentTrack.trackName == tracksInformation.first?.trackName {
//            return nil
//        } else {
//            guard let currentIndex = tracksInformation.firstIndex(where: { $0.trackName == currentTrack.trackName }) else { return nil }
//            currentTrack = tracksInformation[currentIndex - 1]
//            return currentTrack
//        }
//    }
//    
//    var json: Data? {
//        guard let data = try? JSONEncoder().encode(self) else { return nil }
//        return data
//    }
//}

struct PlayerData: Codable {
    var volume: Int?
    var metaData: TrackInformation?
    var command: String?
    var currentTime: Int?
    var listTrack: [String]?
    var currentTrackName: String?
    
    var json: Data? {
        guard let data = try? JSONEncoder().encode(self) else { return nil }
        return data
    }
}

struct TrackInformation: Codable {
    var trackName: String
    var albumName: String
    var imageData: Data
}

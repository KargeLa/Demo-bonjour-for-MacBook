//
//  ViewController.swift
//  bonjour-demo-mac
//
//  Created by James Zaghini on 8/05/2015.
//  Copyright (c) 2015 James Zaghini. All rights reserved.
//

import Cocoa

struct TrackList: Codable {
    
    //MARK: - TrackList Properties
    var tracksInformation: [TrackInformation]
}

struct TrackInformation: Codable {
    
    //MARK: - TrackInformation Properties
    var trackName: String
    var albumName: String
    var imageData: Data
    
    var json: Data? {
        return try? JSONEncoder().encode(self)
    }
}

class ViewController: NSViewController {
    
    //MARK: - NSViewController Propeties
    var tracksInformation: [TrackInformation] = []
    private var bonjourServer: BonjourServer! {
        didSet {
            bonjourServer.delegate = self
        }
    }
    private var bonjourClient: BonjourClient! {
        didSet {
            bonjourClient.delegate = self
        }
    }
    
    private var countTrack = 0
    
    //MARK: - Outlets
    @IBOutlet private weak var commandFromRemote: NSTextField!
    @IBOutlet private weak var trackImage: NSImageView!
    @IBOutlet private weak var trackNameLabel: NSTextField!
    @IBOutlet private weak var albumNameLabel: NSTextField!
    @IBOutlet private weak var connectedToLabel: NSTextField!
    
    //MARK: - Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        // create tracks
        let firstTrack = TrackInformation(trackName: "FirstTrack", albumName: "FitsrAlbum", imageData: (NSImage(named: "image_1")?.tiffRepresentation)! )
        tracksInformation.append(firstTrack)
        let secondTrack = TrackInformation(trackName: "SecondTrack", albumName: "SecondAlbum", imageData: (NSImage(named: "image_2")?.tiffRepresentation)! )
        tracksInformation.append(secondTrack)
        let thirdTrack = TrackInformation(trackName: "ThirdTrack", albumName: "ThirdAlbum", imageData: (NSImage(named: "image_3")?.tiffRepresentation)! )
        tracksInformation.append(thirdTrack)
    
        bonjourServer = BonjourServer()
        bonjourClient = BonjourClient()
        
    }
    //MARK: Sending a playlist to a remotecontrol
    private func sendData(tracksInformation: [TrackInformation]) {
        let trackResponse = TrackList(tracksInformation: tracksInformation)
        guard let data = try? JSONEncoder().encode(trackResponse) else { return }
        
        bonjourClient.send(data)
    }
    
    //MARK: Track information update in QXPlayer
    private func updateUI(trackInformation: TrackInformation) {
        trackNameLabel.stringValue = trackInformation.trackName
        albumNameLabel.stringValue = trackInformation.albumName
        trackImage.image = NSImage(data: trackInformation.imageData)
    }
}

    //MARK: - BonjourServerDelegate, BonjourClientDelegate
extension ViewController: BonjourServerDelegate, BonjourClientDelegate {
    func didChangeServices() {
        print("didChangeServices in bonjour demo mac ")
    }
    
    func connected() {
        print("connected in bonjour demo mac ")
    }
    
    func disconnected() {
        print("disconnected in bonjour demo mac ")
    }
    
    func connectedTo(_ socket: GCDAsyncSocket!) {
        connectedToLabel.stringValue = "Connected to " + (socket.connectedHost ?? "-")
        sendData(tracksInformation: tracksInformation)
        updateUI(trackInformation: tracksInformation[0])
    }
    
    func handleBody(_ body: Data?) {
        guard let body = body else { return }
        if let command = String(data: body, encoding: .utf8) {
            switch command {
            case "play":
                commandFromRemote.stringValue = "Playning music"
            case "pause":
                commandFromRemote.stringValue = "music not playning "
            case "back":
                countTrack = countTrack - 1
                updateUI(trackInformation: tracksInformation[countTrack])
            case "forward":
                countTrack = countTrack + 1
                updateUI(trackInformation: tracksInformation[countTrack])

            default:
                print("Default")
            }
        }
    }
}

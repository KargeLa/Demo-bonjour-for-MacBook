//
//  ViewController.swift
//  bonjour-demo-mac
//
//  Created by James Zaghini on 8/05/2015.
//  Copyright (c) 2015 James Zaghini. All rights reserved.
//

import Cocoa

class ViewController: NSViewController {
    
    //MARK: - Propeties
    
    var trackList: TrackList?
    
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
        var tracksInformation: [TrackInformation] = []
        
        let firstTrack = TrackInformation(trackName: "FirstTrack", albumName: "FitsrAlbum", imageData: (NSImage(named: "image_1")?.tiffRepresentation)! )
        tracksInformation.append(firstTrack)
        let secondTrack = TrackInformation(trackName: "SecondTrack", albumName: "SecondAlbum", imageData: (NSImage(named: "image_2")?.tiffRepresentation)! )
        tracksInformation.append(secondTrack)
        let thirdTrack = TrackInformation(trackName: "ThirdTrack", albumName: "ThirdAlbum", imageData: (NSImage(named: "image_3")?.tiffRepresentation)! )
        tracksInformation.append(thirdTrack)
        
        trackList = TrackList(tracksInformation: tracksInformation, currentTrack: tracksInformation[0])
        
        bonjourServer = BonjourServer()
        bonjourClient = BonjourClient()
        
    }
    
    //MARK: Sending a playlist to a remotecontrol
    
    private func sendData(trackList: TrackList) {

        guard let data = try? JSONEncoder().encode(trackList) else { return }
        
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
        bonjourServer = BonjourServer()
        bonjourClient = BonjourClient()
        trackNameLabel.stringValue = ""
        albumNameLabel.stringValue = ""
        trackImage.image = NSImage()
        commandFromRemote.stringValue = ""
         connectedToLabel.stringValue = ""
    }
    
    func connectedTo(_ socket: GCDAsyncSocket!) {
        connectedToLabel.stringValue = "Connected to " + (socket.connectedHost ?? "-")
        
        guard let trackList = trackList else { return }
        updateUI(trackInformation: trackList.currentTrack)
        
        sendData(trackList: trackList)
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
                guard let trackInformation = trackList?.prevTrack() else { return }
                updateUI(trackInformation: trackInformation)
            case "forward":
                guard let trackInformation = trackList?.nextTrack() else { return }
                updateUI(trackInformation: trackInformation)
            default:
                if let trackInformation = trackList?.searchTrack(byTrackName: command) {
                    trackList?.currentTrack = trackInformation
                    updateUI(trackInformation: trackInformation)
                }
            }
        }
    }
}

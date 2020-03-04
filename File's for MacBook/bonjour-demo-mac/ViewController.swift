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
    
    var currentTrack: TrackInformation?
    var listTrack: [String]?
    
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
    
    var currentState: StatePlay = .notPlayningMusic {
        didSet {
            commandFromRemote.stringValue = currentState.rawValue
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

        let firstTrack = TrackInformation(trackName: "FirstTrack", albumName: "FitsrAlbum", imageData: (NSImage(named: "image_1")?.tiffRepresentation)! )
        let secondTrack = TrackInformation(trackName: "SecondTrack", albumName: "SecondAlbum", imageData: (NSImage(named: "image_2")?.tiffRepresentation)! )
        let thirdTrack = TrackInformation(trackName: "ThirdTrack", albumName: "ThirdAlbum", imageData: (NSImage(named: "image_3")?.tiffRepresentation)! )
       
        
        currentTrack = firstTrack
        listTrack = [firstTrack.trackName, secondTrack.trackName, thirdTrack.trackName]
        
        bonjourServer = BonjourServer()
        bonjourClient = BonjourClient()
        
    }
    
    //MARK: - Action
    
    @IBAction func playButtonAction(_ sender: Any) {
        if connectedToLabel.stringValue != "" {
            currentState = currentState.opposite
            sendCommand(command: currentState.rawValue)
        }
    }
    
    //MARK: Sending a playlist to a remotecontrol
    
    //MARK: Track information update in QXPlayer
    
    private func updateUI(trackInformation: TrackInformation) {
        trackNameLabel.stringValue = trackInformation.trackName
        albumNameLabel.stringValue = trackInformation.albumName
        trackImage.image = NSImage(data: trackInformation.imageData)
    }
    
    private func sendCommand(command: String) {
        if let data = command.data(using: .utf8) {
            bonjourClient.send(data)
        }
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
        
        guard let currentTrack = currentTrack else { return }
        let playerData = PlayerData(volume: nil, metaData: currentTrack, command: nil, currentTime: nil, listTrack: listTrack, currentTrackName: nil)
        updateUI(trackInformation: currentTrack)
        
         guard let data = playerData.json else { return }
         bonjourClient.send(data)
    }
    
    func handleBody(_ body: Data?) {
        guard let data = body else { return }
        guard let playerData = try? JSONDecoder().decode(PlayerData.self, from: data) else { return }
        
        if let _ = playerData.volume {
            print("Volume")
        }
        if let _ = playerData.metaData {
            print("metadata")
        }
        if let command = playerData.command {
            switch command {
            case "back": print("back")
            case "forward": print("forward")
            case StatePlay.notPlayningMusic.rawValue: print("notPlayningMusic")
            case StatePlay.playningMusic.rawValue: print("playningMusic")
                
            default:
                print("default")
            }
        }
        if let _ = playerData.currentTime {
            print("currentTime")
        }
        if let _ = playerData.listTrack {
            print("listTrack")
        }
        if let currentTrackName = playerData.currentTrackName {
            if let track = listTrack!.first(where: { (elements) -> Bool in
                elements == currentTrackName
            }) {
                let playerData = PlayerData(volume: nil, metaData: TrackInformation(trackName: "SecondTrack", albumName: "SecondAlbum", imageData: (NSImage(named: "image_2")?.tiffRepresentation)! ), command: nil, currentTime: nil, listTrack: nil, currentTrackName: nil)
                updateUI(trackInformation: TrackInformation(trackName: "SecondTrack", albumName: "SecondAlbum", imageData: (NSImage(named: "image_2")?.tiffRepresentation)! ))
                
                 guard let data = playerData.json else { return }
                 bonjourClient.send(data)
            }
        }
    }
}

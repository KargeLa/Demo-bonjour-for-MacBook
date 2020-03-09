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
    
    var currentTrack: MetaData?
    var listTrack: [String]?
    var trackList: [MetaData]?
    
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

        trackList = []
        let firstTrack = MetaData(title: "FirstTrack", albumName: "FitsrAlbum", albumArt: (NSImage(named: "image_1")?.tiffRepresentation)! )
        let secondTrack = MetaData(title: "SecondTrack", albumName: "SecondAlbum", albumArt: (NSImage(named: "image_2")?.tiffRepresentation)! )
        let thirdTrack = MetaData(title: "ThirdTrack", albumName: "ThirdAlbum", albumArt: (NSImage(named: "image_3")?.tiffRepresentation)! )
        trackList?.append(firstTrack)
        trackList?.append(secondTrack)
        trackList?.append(thirdTrack)
        
        currentTrack = firstTrack
        listTrack = []
        listTrack = trackList!.map({ $0.title })
        
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
    
    private func updateUI(trackInformation: MetaData) {
        trackNameLabel.stringValue = trackInformation.title
        albumNameLabel.stringValue = trackInformation.albumName
        trackImage.image = NSImage(data: trackInformation.albumArt)
    }
    
    private func sendCommand(command: String) {
        if let data = command.data(using: .utf8) {
            bonjourClient.send(data)
        }
    }
    
    private func forwardAction() {
        if currentTrack!.title == trackList!.last?.title {
            return
        } else {
            guard let currentIndex = trackList!.firstIndex(where: { $0.title == currentTrack!.title }) else { return }
            currentTrack = trackList![currentIndex + 1]
            updateUI(trackInformation: currentTrack!)
            
            let playerData = PlayerData(volume: nil, metaData: currentTrack!, command: nil, currentTime: nil, fileSystem: nil, currentTrackName: nil)
            guard let data = playerData.json else { return }
            bonjourClient.send(data)
        }
    }
    
    private func backwardAction() {
        if currentTrack!.title == trackList!.first?.title {
            return
        } else {
            guard let currentIndex = trackList!.firstIndex(where: { $0.title == currentTrack!.title }) else { return }
            currentTrack = trackList![currentIndex - 1]
            updateUI(trackInformation: currentTrack!)
            
            let playerData = PlayerData(volume: nil, metaData: currentTrack!, command: nil, currentTime: nil, fileSystem: nil, currentTrackName: nil)
            guard let data = playerData.json else { return }
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
        
        var fileSystem: [File] = []
        
        for i in 0..<4 { // add folders
            fileSystem.append(File(name: "folder\(i)", type: .folder, path: "/path\(i)/" + "folder\(i)"))
        }
        
        for i in 0..<listTrack!.count { // add music files
            fileSystem.append(File(name: listTrack![i], type: .music, path: "/path\(i)/" + "\(listTrack![i])"))
        }
        
        let playerData = PlayerData(volume: nil,
                                    metaData: currentTrack,
                                    command: currentState.rawValue,
                                    currentTime: nil,
                                    fileSystem: fileSystem,
                                    currentTrackName: nil,
                                    pathNewFolder: nil)
        
        updateUI(trackInformation: currentTrack)
        
        guard let data = playerData.json else { return }
        bonjourClient.send(data)
    }
    
    func handleBody(_ body: Data?) {
        guard let data = body else { return }
        guard let playerData = try? JSONDecoder().decode(PlayerData.self, from: data) else { return }
        
        if let volume = playerData.volume {
            print(volume)
        }
        if let _ = playerData.metaData {
            print("metadata")
        }
        if let command = playerData.command {
            switch command {
            case "back": backwardAction()
            case "forward": forwardAction()
            case StatePlay.notPlayningMusic.rawValue: currentState = .notPlayningMusic
            case StatePlay.playningMusic.rawValue: currentState = .playningMusic
                
            default:
                print("default")
            }
        }
        if let currentTime = playerData.currentTime {
            print(currentTime)
        }
        if let _ = playerData.fileSystem {
            print("listTrack")
        }
        if let currentTrackName = playerData.currentTrackName {
            
            if let track = trackList!.first(where: { (elements) -> Bool in
                elements.title == currentTrackName
            }) {
                let playerData = PlayerData(volume: nil, metaData: track, command: nil, currentTime: nil, fileSystem: nil, currentTrackName: nil, pathNewFolder: nil)
                currentTrack = track
                updateUI(trackInformation: track)
                
                guard let data = playerData.json else { return }
                bonjourClient.send(data)
            }
        }
        if let path = playerData.pathNewFolder {
            print(path)
        }
    }
}

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
    
    var trackList: [MetaData] = []
    var sendingTrackInformation: PlayerManager?
    var playCommand: Bool = false
    
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
    @IBOutlet weak var currentTimeSlider: NSSlider!
    @IBOutlet weak var currentValumeSlider: NSSlider!
    
    //MARK: - Actions
    
    @IBAction func playStopButtonClicked(_ sender: NSButton) {
        playStopButtonFunction()
    }
    
    @IBAction func prevButtonClicked(_ sender: NSButton) {
        let json = ["action": 3, "maxCurrentTime": 100,"currentTime": 0, "currentVolume": 20]
        sendCommand(json)
    }
    
    @IBAction func nextButtonClicked(_ sender: NSButton) {
        let json = ["action": 2, "maxCurrentTime": 80,"currentTime": 0, "currentVolume": 20]
        sendCommand(json)
    }
    @IBAction func currentTimeSliderChanged(_ sender: NSSlider) {
    }
    @IBAction func currentVolumeSliderChanged(_ sender: NSSlider) {
    }
    
    //MARK: - Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // create tracks
        sendingTrackInformation = PlayerManager()
        let firstTrack = MetaData(title: "FirstTrack", albumName: "FitsrAlbum", albumArt: (NSImage(named: "image_1")?.tiffRepresentation)!)
        let secondTrack = MetaData(title: "SecondTrack", albumName: "SecondAlbum", albumArt: (NSImage(named: "image_2")?.tiffRepresentation)!)
        let thirdTrack = MetaData(title: "ThirdTrack", albumName: "ThirdAlbum", albumArt: (NSImage(named: "image_3")?.tiffRepresentation)!)
        trackList.append(firstTrack)
        trackList.append(secondTrack)
        trackList.append(thirdTrack)
        
        sendingTrackInformation?.currentTrack = firstTrack
        
        sendingTrackInformation?.nameOfTracks = []
        
        sendingTrackInformation?.nameOfTracks = trackList.map({ $0.title })
        
        bonjourServer = BonjourServer()
        bonjourClient = BonjourClient()
        
    }
    
    //MARK: - Supporting
    
    func searchTrack(byTrackName trackName: String) -> MetaData? {
        return trackList.first { $0.title == trackName }
    }
    
    func nextTrack() -> MetaData? {
        print("сейчас \(sendingTrackInformation?.currentTrack?.title)")
        if let currentTrack = sendingTrackInformation?.currentTrack?.title {
            if currentTrack == trackList[trackList.count - 1].title {
                return nil
            } else {
                var i = 0
                for trackInfo in trackList {
                    if sendingTrackInformation?.currentTrack?.title == trackInfo.title {
                        sendingTrackInformation?.currentTrack = trackList[i + 1]
                        let package = PlayerManager(currentTrack: sendingTrackInformation?.currentTrack, action: 7, maxCurrentTime: 50, currentTime: 0)
                        if let data = try? JSONEncoder().encode(package) {
                            bonjourClient.send(data)
                        }
                        return sendingTrackInformation?.currentTrack
                    }
                    i = i + 1
                }
            }
        }
        return nil
    }
    
    func prevTrack() -> MetaData? {
        
        if let currentTrack = sendingTrackInformation?.currentTrack?.title {
            if currentTrack == trackList[0].title {
                return nil
            } else {
                var i = 0
                for trackInfo in trackList {
                    if sendingTrackInformation?.currentTrack?.title == trackInfo.title {
                        sendingTrackInformation?.currentTrack = trackList[i - 1]
                        let package = PlayerManager(currentTrack: sendingTrackInformation?.currentTrack, action: 7, maxCurrentTime: 50, currentTime: 0)
                        if let data = try? JSONEncoder().encode(package) {
                            bonjourClient.send(data)
                        }
                        return sendingTrackInformation?.currentTrack
                    }
                    i = i + 1
                }
            }
        }
        return nil
    }
    
    private func playStopButtonFunction() {
        playCommand.toggle()
        if playCommand == true {
            commandFromRemote.stringValue = "Playning music"
            let json = ["action": 0]
            sendCommand(json)
        } else if playCommand == false {
            commandFromRemote.stringValue = "music not playning "
            let json = ["action": 1]
            sendCommand(json)
        }
    }
    
    //MARK: Sending a playlist to a remotecontrol
    
    private func sendCommand(_ json: [String: Any]) {
        guard let commandData = try? JSONSerialization.data(withJSONObject: json, options: [.prettyPrinted]) else {
            return
        }
        bonjourClient.send(commandData)
    }
    
    //MARK: Track information update in QXPlayer
    
    private func updateUI(metaData: MetaData) {
        trackNameLabel.stringValue = metaData.title
        albumNameLabel.stringValue = metaData.albumName
        trackImage.image = NSImage(data: metaData.albumArt)
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
        guard let currentTrack = sendingTrackInformation?.currentTrack else {
            return
        }
        guard let nameOfTrack = sendingTrackInformation?.nameOfTracks else {
            return
        }
        let package = PlayerManager(nameOfTracks: nameOfTrack, currentTrack: currentTrack, action: 0, maxCurrentTime: 100, currentTime: 0, currentVolume: 100)
        guard let data = try? JSONEncoder().encode(package) else {
            return
        }
        updateUI(metaData: currentTrack)
        bonjourClient.send(data)
    }
    
    func handleBody(_ body: Data?) {
        guard let body = body else { return }
        if let package = try? JSONDecoder().decode(PlayerManager.self, from: body),
            let actionInt = package.action,
            let action = ActionType(rawValue: actionInt) {
            switch action {
               
            case .connect:
                break
            case .play:
                commandFromRemote.stringValue = "Playning music"
                break
            case .pause:
                if let currentTime = package.currentTime {
                    commandFromRemote.stringValue = "music not playning, stop on \(currentTime)"
                }
                break
            case .next:
                if let trackInformation = nextTrack()  {
                    updateUI(metaData: trackInformation)
                }
                break
            case .prev:
                if let trackInformation = prevTrack()  {
                updateUI(metaData: trackInformation)
                }
                break
            case .volume:
                break
            case .time:
                break
            case .changedTrack:
                if let trackName = package.currentTrackName {
                    let currentTrack = searchTrack(byTrackName: trackName)
                    if let currentTrack = currentTrack {
                        updateUI(metaData: currentTrack)
                        let package = PlayerManager(currentTrack: currentTrack, action: 7, maxCurrentTime: 90, currentTime: 0)
                        guard let data = try? JSONEncoder().encode(package) else {
                            return
                        }
                        bonjourClient.send(data)
                    }
                }
                break
            }
        }
    }
}

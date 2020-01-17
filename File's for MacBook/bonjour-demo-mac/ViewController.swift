//
//  ViewController.swift
//  bonjour-demo-mac
//
//  Created by James Zaghini on 8/05/2015.
//  Copyright (c) 2015 James Zaghini. All rights reserved.
//

import Cocoa

struct TrackInformation: Codable {
    var trackName: String
    var albumName: String
    var imageData: Data
}

class ViewController: NSViewController {
    
    //MARK: - Propeties
    
    var trackInformationArray: [InformationAboutTrack] = []
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
    
    @IBOutlet private weak var tableView: NSTableView!
    @IBOutlet private weak var commandFromRemote: NSTextField!
    @IBOutlet private weak var trackImage: NSImageView!
    @IBOutlet private weak var trackNameLabel: NSTextField!
    @IBOutlet private weak var albumNameLabel: NSTextField!
    @IBOutlet private weak var connectedToLabel: NSTextField!
    
    //MARK: - Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        let trackNumberOne = InformationAboutTrack()
        trackNumberOne.trackName = "trackNumberOne"
        trackNumberOne.albumName = "albumNumberOne"
        trackInformationArray.append(trackNumberOne)
        let trackNumberTwo = InformationAboutTrack()
        trackNumberTwo.trackName = "trackNumberTwo"
        trackNumberTwo.albumName = "albumNumberTwo"
        trackInformationArray.append(trackNumberTwo)
        let trackNumberThird = InformationAboutTrack()
        trackNumberThird.trackName = "trackNumberThird"
        trackNumberThird.albumName = "albumNumberThird"
        trackInformationArray.append(trackNumberThird)
        
        bonjourServer = BonjourServer()
        bonjourClient = BonjourClient()
        
    }
    
    private func createJson(with titleSound: String, with titleAlbum: String, with image: NSImage) -> Data? {
        guard let imageData = image.tiffRepresentation else { return Data() }
        let soundPlayer = TrackInformation(trackName: titleSound, albumName: titleAlbum, imageData: imageData)
        return try? JSONEncoder().encode(soundPlayer)
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
    }
    
    func handleBody(_ body: Data?) {
        guard let body = body else { return }
        if let command = String(data: body, encoding: .utf8) {
            commandFromRemote.stringValue = command
        }
        
        if commandFromRemote.stringValue == "PLAY" {
            trackNameLabel.stringValue = trackInformationArray[0].trackName!
            albumNameLabel.stringValue = trackInformationArray[0].albumName!
            trackImage.image = NSImage(named: "image_1")
        } else {
            trackNameLabel.stringValue = " "
            albumNameLabel.stringValue = " "
            trackImage.image = NSImage(named: "pause")
        }
        
        if let image = trackImage.image,
            let dataToSend = createJson(with: trackNameLabel.stringValue, with: albumNameLabel.stringValue, with: image) {
            bonjourClient.send(dataToSend)
        }
    }
}

//MARK: - NSTableViewDelegate, NSTableViewDataSource

extension ViewController: NSTableViewDelegate, NSTableViewDataSource {
    func numberOfRows(in aTableView: NSTableView) -> Int {
        return bonjourServer.devices.count
    }
    
    func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any?{
        var result = ""
        
        let columnIdentifier = tableColumn!.identifier.rawValue
        if columnIdentifier == "bonjour-device" {
            let device = bonjourServer.devices[row]
            result = device.name
        }
        return result
    }
    
    func tableViewSelectionDidChange(_ notification: Notification) {
        print("notification: \(String(describing: notification.userInfo))")
        
        if !bonjourServer.devices.isEmpty {
            let service = bonjourServer.devices[tableView.selectedRow]
            bonjourServer.connectTo(service)
        }
    }
}

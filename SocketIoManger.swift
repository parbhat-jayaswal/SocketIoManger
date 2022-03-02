//
//  SocketIoManger.swift
//
//  Created by Parbhat Jayaswal on 02/03/22.
//  Copyright © 2022 Parbhat All rights reserved.
//

import UIKit
import SocketIO

//MARK:- Create link through token
var token = UserDefaults.standard.string(forKey: Constants.userDefaults.usrToken) ?? ""
var manager = SocketManager(socketURL: URL(string: BASEURL)!, config: [.log(true),.connectParams(["token": token]), .compress])

typealias SocketHandlerGeneric<T> = (T?) -> Void

class SocketIoManager: NSObject {
    static var socket = manager.defaultSocket
    static let shared = SocketIoManager()
}

// MARK:- EXTENSION OF SOCKET IO MANAGER
extension SocketIoManager {
    class func establishConnection() {
        let socketConnectionStatus = socket.status
        
        switch socketConnectionStatus {
            case SocketIOStatus.connected:
                print("socket connected")
            
            case SocketIOStatus.connecting:
                print("socket connecting")
            
            case SocketIOStatus.disconnected:
                print("socket disconnected")
                socket.connect()
            
            case SocketIOStatus.notConnected:
                print("socket not connected")
                socket.connect()
        }
        
        print(socket.status)
        socket.on(clientEvent: .connect) {data, ack in
            print("socket connected in")
        }
    }
    
    class func closeConnection () {
        socket.disconnect()
    }
    
    class func reCreateConnection (token: String) {
        socket.disconnect()
        manager = SocketManager(socketURL: URL(string: BASEURL)!, config: [.log(true),.connectParams(["token": token]), .compress])
        socket = manager.defaultSocket
    }
    
    class func connectSocket () {
        socket.connect()
    }
    
}

//MARK:- Listener Methods
extension SocketIoManager {
    
    //MARK: To send Encodable Object to socket emitter
    class func emit<T: Encodable>(key: String, request: T)  {
        do{
            let data = try JSONEncoder().encode(request)
            guard let dictionary = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any] else {
                throw NSError()
            }
            socket.emit(key, dictionary)
        }catch let error{
            print(error)
        }
    }
    
    //MARK: To send Dict data to socket
    class func emitDict(key: String, dict : [String: Any])  {
        socket.emit(key, dict)
    }
     
    
    //MARK: Listen new Request with Generic Way (Key for Socket, Response Generic Type, Result closure with Generic data Response
    class func listenNewRequest<T>(key: String, type: T.Type, completion : @escaping (Result<T, Error>) -> Void) where T: Codable{
        socket.on(key) { (data, ack) in
            guard let dict = data[0] as? [String : Any] else {
                return
            }

            do {
                let json = try JSONSerialization.data(withJSONObject: dict)
                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .convertFromSnakeCase
                let dataReply = try decoder.decode(T.self, from: json) //Check for Generic type and Convert the json
                completion(.success(dataReply)) //Complete the response with Generic data
            }catch let error{
                completion(.failure(error))
            }
           
        }
    }
    
}

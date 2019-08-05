//
//  TekoTrackingLib.swift
//  TekoTrackingLib
//
//  Created by tuananhi on 8/2/19.
//  Copyright © 2019 tuananhi. All rights reserved.
//

import Foundation


public class TekoTracking {

    public static let shared = TekoTracking()
    
    
    public func trackEvent(params : [String : Any]){
        
    
    }
    
    public func buttonClickLog(){
        print(#function)
        let clickEvent : TrackingEvent = .type1
        Tracking.shared.trackEvent(event: clickEvent)
        RequestManager.shared.start()
        
    }
    
    public func bar(){
        
    }
}

struct Queue<T> {
    fileprivate var array = [T]()
    
    public var isEmpty: Bool {
        return array.isEmpty
    }
    
    public var count: Int {
        return array.count
    }
    
    public mutating func enqueue(_ element: T) {
        array.append(element)
    }
    
    public mutating func dequeue() -> T? {
        if isEmpty {
            return nil
        } else {
            return array.removeFirst()
        }
    }
    
    public var front: T? {
        return array.first
    }
}


class Tracking : NSObject {
    static let shared = Tracking(a: 100)
    let limmitedTime = 30
    var sessionId = ""
    var timer : Timer?
    var isSessionValid = false
    var count = 0
    
    func runTimer() {
        timer = Timer.scheduledTimer(timeInterval: 5, target: self,   selector: (#selector(updateTimer)), userInfo: nil, repeats: true)
    }
    
    @objc func updateTimer(){
        print("tik tok")
        count = count + 1
        print(count)
        if count == limmitedTime {
            updateSession()
        }
    }
    
    @objc func updateSession(){
        print("updateSession")
        isSessionValid = false
        delay(9) {
            
            let newSessionId = SessionManager.shared.requestNewSessionId()
            if !newSessionId.isEmpty {
                self.sessionId = newSessionId
                self.isSessionValid = true
                print("assign new ss Id")
                RequestManager.shared.resume()
                self.count = 0
            }
        }
        
        
    }
    
    init(a : Int) {
        
        let ssId = SessionManager.shared.genarateSesstionId()
        if !ssId.isEmpty {
            sessionId =  ssId
            isSessionValid = true
        }
        
    }
    
    func trackEvent(event : TrackingEvent){
        print(#function)
        count = 0
        RequestManager.shared.addReqAndPush(event: event)
        
    }
    
}

class SessionManager : NSObject {
    static let shared = SessionManager()
    
    func requestNewSessionId()->String{
        return "newSessionId"
    }
    
    func genarateSesstionId()->String{
        return "initSessionId"
    }
}


enum TrackingEvent {
    
    case type1
    case type2
    case type3
    
    func params()-> [String : Any] {
        switch self {
        case .type1:
            return ["param1" : "foo" , "param2" : "bar"]
        case .type2:
            return ["param3" : "foo" , "param4" : "bar"]
        case .type3:
            return ["param3" : "foo" , "param4" : "bar"]
        }
    }
}


class DataRequest {
    var collection = [String : Any]()
    let dummyResCode = [200 , 404 , 413 , 500]
    
    
    func push(){
        
        let number = dummyResCode.randomElement()!
        switch number {
        case 200:
            print("event push thành công")
        case 404:
            saveOffline()
        case 413 :
            resizeAndPush()
        case 500:
            saveOffline()
        default:
            print("nothing at all")
        }
    }
    
    private func saveOffline(){
        // save DataRequest  to local with unique key
        // để sau khi online get ra và tiếp tục gửi request  lên server
        
        
    }
    private func resizeAndPush(){
        let s : Int = collection.count/2
        let lPart = DataRequest()
        let rPart = DataRequest()
        let dictKeys = Array(collection.keys)
        for i in 0..<dictKeys.count {
            let k = dictKeys[i]
            if i <= s {
                lPart.collection[k] = collection[k]
            }else{
                rPart.collection[k] = collection[k]
            }
        }
        lPart.push()
        rPart.push()
        
    }
    
    
}


class QueueManager {
    static let shared = QueueManager()
    var data = [Queue<TrackingEvent>]()
    
    let maxSize = 100
    
    func addEvent(e : TrackingEvent){
        DispatchQueue.global(qos: .userInitiated).async {
            print("DispatchQueue.global - qos: .userInitiated")
            if var queue = self.data.last {
                if queue.count == self.maxSize {
                    var newQueue = Queue<TrackingEvent>()
                    newQueue.enqueue(e)
                    self.data.append(newQueue)
                }else{
                    queue.enqueue(e)
                }
            }
        }
    }
        
        
}



class RequestManager {
    static let shared = RequestManager()
    var eventQueue = Queue<TrackingEvent>()
    
    
    func addReqAndPush(event : TrackingEvent)
    {
//        QueueManager.shared.addEvent(e: event)
        DispatchQueue.global(qos: .userInitiated).async {
            print("DispatchQueue.global - qos: .userInitiated")
            self.eventQueue.enqueue(event)
            
        }
        
        
    }
    func start(){
        sendLog()
    }
    
    func resume(){
        sendLog()
    }
    
    func sendLog()
    {

        var data = [String : Any]()
        while !eventQueue.isEmpty && Tracking.shared.isSessionValid {
            sleep(1)
            if let event = eventQueue.dequeue() {
                push()
                data.update(other: event.params())
                if data.keys.count == 10 || data.keys.count == eventQueue.count{
                    let dataReq = DataRequest()
                    dataReq.collection = data
                    dataReq.push()
                }
            }
        }
    }
    
    func push(){
        print(#function)
        DispatchQueue.global(qos: .default).async {
            print("DispatchQueue.global(qos: .default).async")
            // do something
            print("push log thành công")
        }
        
        
    }
    
    func saveOffline(){
        /// save eventQueue to local with key "eventQueue"
        //  để phân biệt với cái dữ liệu DataRequest
        //  lặp lại quá trình sendLog()
    }
    
}



func delay(_ delay:Double, closure:@escaping ()->()) {
    DispatchQueue.main.asyncAfter(
        deadline: DispatchTime.now() + Double(Int64(delay * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC), execute: closure)
}

extension Dictionary {
    mutating func update(other:Dictionary) {
        for (key,value) in other {
            self.updateValue(value, forKey:key)
        }
    }
}

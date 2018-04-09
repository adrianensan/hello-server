import Foundation

class Socket {
    
    let acceptBacklog: Int32 = 20
    let bufferSize = 100 * 1024
    
    let socketFileDescriptor: Int32
    
    init(socketFD: Int32) {
        socketFileDescriptor = socketFD;
    }
    
    deinit {
        close(socketFileDescriptor)
    }
    
    func acceptRequest() -> Request? {
        var requestBuffer: [UInt8] = [UInt8](repeating: 0, count: bufferSize)
        var requestLength: Int = 0
        while true {
            let bytesRead = recv(socketFileDescriptor, &requestBuffer[requestLength], bufferSize - requestLength, 0)
            guard bytesRead > 0 else { return nil }
            requestLength += bytesRead
            if let requestString = String(bytes: requestBuffer[..<requestLength], encoding: .utf8) {
                return Request.parse(string: requestString);
            }
        }
    }
    
    func sendResponse(_ response: Response) {
        let responseString = response.toString()
        let responseBytes: [UInt8] = [UInt8](responseString.data)
        sendData(data: responseBytes)
    }
    
    func sendData(data: [UInt8]) {
        var bytesToSend = data.count
        repeat {
            let bytesSent = send(socketFileDescriptor, data, bytesToSend, 0);
            if bytesSent <= 0 { return }
            bytesToSend -= bytesSent
        } while bytesToSend > 0
    }
}

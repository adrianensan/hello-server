import Foundation

class ClientSocket: Socket  {
    
    func peak() -> [UInt8]? {
        var requestBuffer: [UInt8] = [UInt8](repeating: 0, count: Socket.bufferSize)
        while true {
            let bytesRead = Int(recv(socketFileDescriptor, &requestBuffer, Socket.bufferSize, Int32(MSG_PEEK)))
            guard bytesRead > 0 else { return nil }
            return [UInt8](requestBuffer[..<bytesRead])
        }
    }
    
    func acceptRequest() -> Request? {
        var requestBuffer: [UInt8] = [UInt8](repeating: 0, count: Socket.bufferSize)
        var requestLength: Int = 0
        while true {
            let bytesRead = recv(socketFileDescriptor, &requestBuffer[requestLength], Socket.bufferSize - requestLength, 0)
            guard bytesRead > 0 else { return nil }
            requestLength += bytesRead
            if let requestString = String(bytes: requestBuffer[..<requestLength].filter{$0 != 13}, encoding: .utf8) {
                requestLength = 0
                return Request.parse(string: requestString);
            }
        }
    }
    
    func sendResponse(_ response: Response) {
        let responseString: String = response.description
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

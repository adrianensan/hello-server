import Foundation

class Response {
    
    var httpVersion: HTTPVersion = .http1_1
    var status: Status = .ok
    var contentType: ContentType = .none
    var body: String = ""

    private var socket: Socket?
    
    init(clientSocket: Socket? = nil) {
        socket = clientSocket
    }
    
    func setBodyJSON<T: Encodable>(object: T, append: Bool = false) {
        if let json = try? JSONEncoder().encode(object),
            let jsonString = String(data: json, encoding: String.Encoding.utf8) {
            if append {
                body += jsonString
            } else {
                body = jsonString
            }
        }
    }
    
    func complete() {
        if let socket = socket { socket.sendResponse(self) }
        socket = nil
    }
    
    func toString() -> String {
        var string = ""
        string += httpVersion.string
        string += " "
        string += status.string
        string += "\r\n"
        string += contentType.string
        string += "\r\n"
        
        if body.count > 0 {
            string += "Content-Length: \(body.count)"
            string += "\r\n\r\n"
            string += body
        }
        
        return string
    }
}

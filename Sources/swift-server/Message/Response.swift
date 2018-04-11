import Foundation

class Response: Message, CustomStringConvertible {
    
    var httpVersion: HTTPVersion = .http1_1
    var status: ResponseStatus = .ok
    var cookies: [Cookie] = [Cookie]()
    var customeHeaders: [String] = [String]()
    var contentType: ContentType = .none
    var location: String?
    var omitBody: Bool = false

    private var socket: ClientSocket?
    
    init(clientSocket: ClientSocket? = nil) {
        socket = clientSocket
    }
    
    func add(cookie: Cookie) {
        cookies.append(cookie)
    }
    
    func addCustomHeader(_ line: String) {
        customeHeaders.append(line.filterNewlines)
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
    
    var description: String {
        var string = ""
        string += httpVersion.string
        string += " "
        string += status.description
        string += "\r\n"
        
        if let location = location {
            string += Header.locationHeader + location
            string += "\r\n"
        }
        
        for cookie in cookies {
            string += cookie.description
            string += "\r\n"
        }
        
        for customHeader in customeHeaders {
            string += customHeader
            string += "\r\n"
        }
        
        switch contentType {
        case .none:
            ()
        default:
            string += contentType.description
            string += "\r\n"
        }
        
        if body.count > 0 && !omitBody {
            string += "Content-Length: \(body.count)"
            string += "\r\n\r\n"
            string += body
        } else { string += "\r\n\r\n" }
        
        return string
    }
}

import Foundation

public class Response: Message, CustomStringConvertible {
    
    var httpVersion: HTTPVersion = .http1_1
    public var status: ResponseStatus = .ok
    var cookies: [Cookie] = [Cookie]()
    var customeHeaders: [String] = [String]()
    public var contentType: ContentType = .none
    public var location: String?
    public var omitBody: Bool = false

    private var socket: ClientSocket?
    
    init(clientSocket: ClientSocket? = nil) {
        socket = clientSocket
    }
    
    public func add(cookie: Cookie) {
        cookies.append(cookie)
    }
    
    public func addCustomHeader(_ line: String) {
        customeHeaders.append(line.filterNewlines)
    }
    
    public func setBodyJSON<T: Encodable>(object: T, append: Bool = false) {
        if let json = try? JSONEncoder().encode(object),
            let jsonString = String(data: json, encoding: String.Encoding.utf8) {
            if append {
                body += jsonString
            } else {
                body = jsonString
            }
        }
    }
    
    public func complete() {
        if let socket = socket { socket.sendResponse(self) }
        socket = nil
    }
    
    public var description: String {
        var string = ""
        string += httpVersion.description
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

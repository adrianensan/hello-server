import Foundation

public class Request: Message, CustomStringConvertible {
    
    public internal(set) var method: Method
    public internal(set) var url: String
    public internal(set) var host: String?
    public internal(set) var cookies: [String: String] = [String: String]()
    
    init(method: Method, url: String) {
        self.method = method
        self.url = url
    }
    
    public var description: String {
        return
            """
            \(method) \(url)\n
            Host: \(host ?? "Not Set")
             
            \(bodyString)
            """
    }
}

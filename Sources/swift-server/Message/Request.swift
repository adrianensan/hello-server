import Foundation

class Request: Message, CustomStringConvertible {
    
    var method: Method
    var url: String
    var cookies: [String: String] = [String: String]()
    
    init(method: Method, url: String) {
        self.method = method
        self.url = url
    }
    
    var description: String {
        return
            """
            \(method) \(url)\n
            \(body.count > 0 ? body : "[No Body]")
            """
    }
}

import Foundation

class Request: CustomStringConvertible {
    
    var method: Method
    var url: String
    var body: String?
    
    init(method: Method, url: String) {
        self.method = method
        self.url = url
    }
    
    var description: String {
        return
            """
            \(method) \(url)\n
            \(body ?? "[No Body]")
            """
    }
}

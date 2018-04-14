import Foundation

extension String {
    var data: Data {
        return self.data(using: .utf8) ?? Data()
    }
    
    var filterNewlines: String {
        return self.filter{!"\r\n".contains($0)}
    }
}

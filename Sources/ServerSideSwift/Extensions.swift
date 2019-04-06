import Foundation

extension String {
    
    static let lineBreak: String = "\r\n"
    
    var data: Data {
        return data(using: .utf8) ?? Data()
    }
    
    var filterNewlines: String {
        return filter{!String.lineBreak.contains($0)}
    }
}

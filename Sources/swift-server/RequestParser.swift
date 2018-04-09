import Foundation
extension Request {
    static func parse(string: String) -> Request? {
        var request: Request?
        let headerAndBodySplit = string.range(of: "\n\n")
        let headerEnd = headerAndBodySplit?.lowerBound ?? string.endIndex
        let headerFields = string[..<headerEnd].split(separator: "\n")
        for headerField in headerFields {
            let segments = headerField.lowercased().split(separator: " ")
            if segments.count == 3 && segments[2].starts(with: "http") {
                request = Request(method: Method.inferFrom(string: String(segments[0])), url: String(segments[1]))
            }
        }
        
        if let request = request, let bodyStartIndex = headerAndBodySplit?.upperBound, bodyStartIndex != string.endIndex {
            request.body = String(string[string.index(after: bodyStartIndex)..<string.endIndex])
        }
        
        return request
    }
}

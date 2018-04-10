import Foundation

extension Request {
    static func parse(string: String) -> Request? {
        var request: Request?
        let headerEnd = string.range(of: "\n\n")
        let headerFields = string[..<(headerEnd?.lowerBound ?? string.endIndex)].split(separator: "\n")
        for headerField in headerFields {
            let segments = headerField.lowercased().split(separator: " ")
            if segments.count == 3 && segments[2].starts(with: "http/") {
                request = Request(method: Method.inferFrom(string: String(segments[0])), url: String(segments[1]))
            }
        }
        
        if let request = request, let bodyStartIndex = headerEnd?.upperBound, bodyStartIndex != string.endIndex {
            request.body = String(string[string.index(after: bodyStartIndex)..<string.endIndex])
        }
        
        return request
    }
}

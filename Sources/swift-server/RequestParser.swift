import Foundation
extension Request {
    static func parse(string: String) -> Request? {
        var request: Request?
        let requestString = string.replacingOccurrences(of: "\r", with: "").lowercased()
        print(requestString)
        let headerEnd = requestString.range(of: "\n\n")?.lowerBound ?? requestString.endIndex
        let headerFields = requestString[..<headerEnd].split(separator: "\n")
        for headerField in headerFields {
            let segments = headerField.split(separator: " ")
            if segments.count == 3 && segments[2].starts(with: "http") {
                request = Request(method: Method.inferFrom(string: String(segments[0])), url: String(segments[1]))
            }
        }
        
        return request
    }
}

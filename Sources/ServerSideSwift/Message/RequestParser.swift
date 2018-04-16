import Foundation

extension Request {
    static func parse(string: String) -> Request? {
        var request: Request?
        let headerEnd = string.range(of: "\n\n")
        let headerFields = string[..<(headerEnd?.lowerBound ?? string.endIndex)].split(separator: "\n")
        for headerField in headerFields {
            if let request = request {
                if headerField.starts(with: "Host: ") {
                    request.host = headerField.split(separator: ":", maxSplits: 1)[1].trimmingCharacters(in: .whitespaces)
                } else if headerField.starts(with: Header.cookieHeader) {
                    let cookies = headerField.split(separator: ":", maxSplits: 1)[1].split(separator: ";")
                    for cookieAttribute in cookies {
                        var parts = cookieAttribute.split(separator: "=", maxSplits: 1)
                        if parts.count == 2 {
                            let name = parts[0].trimmingCharacters(in: .whitespaces)
                            let value = parts[1].trimmingCharacters(in: .whitespaces)
                            if name.count > 0 { request.cookies[name] = value }
                        }
                    }
                }
            } else {
                let segments = headerField.lowercased().split(separator: " ")
                if segments.count == 3 && segments[2].starts(with: "http/") {
                    request = Request(method: Method.inferFrom(string: String(segments[0])), url: String(segments[1]))
                }
            }
        }
        
        if let request = request, let bodyStartIndex = headerEnd?.upperBound, bodyStartIndex != string.endIndex {
            request.body = String(string[string.index(after: bodyStartIndex)..<string.endIndex])
        }
        
        return request
    }
}

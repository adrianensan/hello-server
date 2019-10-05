import Foundation

extension Request {
  static func parse(data: [UInt8]) -> Request? {
    var request: Request?
    guard let headerEnd = Request.findHeaderEnd(data: data) else { return nil }
    let headerFields = data[..<headerEnd].split(separator: 10)
    for headerField in headerFields {
      if let headerLine = String(data: Data(headerField), encoding: .utf8) {
        if let request = request {
          if headerLine.starts(with: "Host: ") {
            request.host = headerLine.split(separator: ":", maxSplits: 1)[1].trimmingCharacters(in: .whitespaces)
          } else if headerLine.starts(with: Header.cookieHeader) {
            let cookies = headerLine.split(separator: ":", maxSplits: 1)[1].split(separator: ";")
            for cookieAttribute in cookies {
              let parts = cookieAttribute.split(separator: "=", maxSplits: 1)
              if parts.count == 2 {
                let name = parts[0].trimmingCharacters(in: .whitespaces)
                let value = parts[1].trimmingCharacters(in: .whitespaces)
                if name.count > 0 { request.cookies[name] = value }
              }
            }
          }
        } else {
          let segments = headerLine.lowercased().split(separator: " ")
          if segments.count == 3 && segments[2].starts(with: "http/") {
            request = Request(method: Method.inferFrom(string: String(segments[0])), url: String(segments[1]))
          }
        }
      }
    }
    
    let bodyStartIndex = headerEnd + 2
    if let request = request, bodyStartIndex < data.count {
      request.body = Data(data[bodyStartIndex..<data.count])
    }
    
    return request
  }
  
  static func findHeaderEnd(data: [UInt8]) -> Int? {
    for i in 0..<(data.count - 1) {
      if data[i] == 10 && data[i + 1] == 10 {
        return i
      }
    }
    
    return nil
  }
}

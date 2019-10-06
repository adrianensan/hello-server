import Foundation

extension Request {
  static func parse(data: [UInt8]) -> Request? {
    var requestBuilder: RequestBuilder?
    guard let headerEnd = Request.findHeaderEnd(data: data) else { return nil }
    let headerFields = data[..<headerEnd].split(separator: 10)
    for headerField in headerFields {
      if let headerLine = String(data: Data(headerField), encoding: .utf8) {
        if let requestBuilder = requestBuilder {
          if headerLine.starts(with: "Host: ") {
            requestBuilder.host = headerLine.split(separator: ":", maxSplits: 1)[1].trimmingCharacters(in: .whitespaces)
          } else if headerLine.starts(with: Header.cookiePrefix) {
            let cookies = headerLine.split(separator: ":", maxSplits: 1)[1].split(separator: ";")
            for cookieAttribute in cookies {
              let parts = cookieAttribute.split(separator: "=", maxSplits: 1)
              if parts.count == 2 {
                let name = parts[0].trimmingCharacters(in: .whitespaces)
                let value = parts[1].trimmingCharacters(in: .whitespaces)
                if name.count > 0 { requestBuilder.cookies[name] = value }
              }
            }
          }
        } else {
          let segments = headerLine.lowercased().split(separator: " ")
          if segments.count == 3 && segments[2].starts(with: "http/") {
            requestBuilder = RequestBuilder()
            requestBuilder?.method = Method.infer(from: String(segments[0]))
            requestBuilder?.url = String(segments[1])
          }
        }
      }
    }
    
    let bodyStartIndex = headerEnd + 2
    if let requestBuilder = requestBuilder, bodyStartIndex < data.count {
      requestBuilder.body = Data(data[bodyStartIndex..<data.count])
    }
    
    return requestBuilder?.finalizedRequest
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

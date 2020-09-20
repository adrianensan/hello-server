import Foundation

extension Request {
  static func parse(data: [UInt8]) -> Request? {
    var requestBuilder: RequestBuilder?
    var contentLength: Int?
    guard let headerEnd = Message.findHeaderEnd(data: data) else { return nil }
    let headerFields = data[..<headerEnd].split(separator: 10)
    for headerField in headerFields {
      if let headerLine = String(data: Data(headerField), encoding: .utf8) {
        if let requestBuilder = requestBuilder {
          if headerLine.lowercased().starts(with: Header.HostPrefix.lowercased()) {
            requestBuilder.host = headerLine.split(separator: ":", maxSplits: 1)[1].trimmingCharacters(in: .whitespaces)
          } else if headerLine.lowercased().starts(with: Header.contentLengthPrefix.lowercased()) {
            contentLength = Int(headerLine.split(separator: ":", maxSplits: 1)[1].trimmingCharacters(in: .whitespaces))
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
    
    if let requestBuilder = requestBuilder {
      if let contentLength = contentLength {
        if contentLength > 0 {
          var index = headerEnd
          while (data[index] == .newlineCharacter || data[index] == .nullCharacter) && data.count - index > contentLength {
            index += 1
          }
          if data.count - index > contentLength {
            requestBuilder.body = Data(data[index..<(index + contentLength)])
          }
          else { return nil }
        }
      }
      else {
        let bodyStartIndex = headerEnd + 2
        if bodyStartIndex < data.count {
          requestBuilder.body = Data(data[bodyStartIndex..<data.count])
        }
      }
    }
    
    return requestBuilder?.request
  }
}

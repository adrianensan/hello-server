import Foundation

import HelloCore

public enum HTTPRequestParseError: Error {
  case invalidRequest
  case incompleteRequest
}

extension HTTPRequest {
  static func parse(data: [UInt8], allowHeaderOnly: Bool = false, from clientAddress: NetworkAddress) throws -> HTTPRequest<Data?> {
    var requestBuilder: HTTPRequestBuilder?
    var contentLength: Int?
    guard let headerEnd = Message.findHeaderEnd(data: data) else {
      throw HTTPRequestParseError.invalidRequest
    }
    let headerFields = data[..<headerEnd].split(separator: 10)
    for headerField in headerFields {
      if let headerLine = String(data: Data(headerField), encoding: .utf8) {
        if let requestBuilder = requestBuilder {
          let headerSplits = headerLine.split(separator: ":", maxSplits: 2)
          guard headerSplits.count == 2 else { continue }
          let key = headerSplits[0].trimmingCharacters(in: .whitespaces).lowercased()
          let value = headerSplits[1].trimmingCharacters(in: .whitespaces)
          guard !key.isEmpty && !value.isEmpty else { continue }
          switch key {
          case "content-length":
            contentLength = Int(value)
            requestBuilder.headers[key] = value
          case "cookie":
            let cookies = value.split(separator: ":", maxSplits: 1)[1].split(separator: ";")
            for cookieAttribute in cookies {
              let parts = cookieAttribute.split(separator: "=", maxSplits: 1)
              if parts.count == 2 {
                let name = parts[0].trimmingCharacters(in: .whitespaces)
                let value = parts[1].trimmingCharacters(in: .whitespaces)
                if name.count > 0 { requestBuilder.cookies[name] = value }
              }
            }
          default:
            requestBuilder.headers[key] = value
          }
        } else {
          let segments = headerLine.lowercased().split(separator: " ")
          if segments.count == 3 && segments[2].starts(with: "http/") {
            requestBuilder = HTTPRequestBuilder(clientAddress: clientAddress)
            requestBuilder?.method = HTTPMethod.infer(from: String(segments[0]))
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
          if index + contentLength <= data.count {
            requestBuilder.body = Data(data[index..<(index + contentLength)])
          } else if !allowHeaderOnly {
            throw HTTPRequestParseError.incompleteRequest
          }
        }
      } else {
        let bodyStartIndex = headerEnd + 2
        if bodyStartIndex < data.count {
          requestBuilder.body = Data(data[bodyStartIndex..<data.count])
        }
      }
    }
    
    guard let requestBuilder else {
      throw HTTPRequestParseError.invalidRequest
    }
    return .init(clientAddress: requestBuilder.clientAddress,
                 method: requestBuilder.method,
                 url: requestBuilder.url,
                 headers: requestBuilder.headers,
                 cookies: requestBuilder.cookies,
                 body: requestBuilder.body)
  }
}

import Foundation

extension Response {
  static func parse(data: [UInt8]) -> Response? {
    guard let headerEnd = Message.findHeaderEnd(data: data) else { return nil }
    guard let blockEnd = Message.findMessageEnd(data: data) else { return nil }
    var responseBuilder: ResponseBuilder?
    var messageEnd = headerEnd
    let headerFields = data[..<headerEnd].split(separator: 10)
    for headerField in headerFields {
      if let headerLine = String(data: Data(headerField), encoding: .utf8) {
        if let responseBuilder = responseBuilder {
          if headerLine.lowercased().starts(with: Header.contentLengthPrefix.lowercased()) {
            let contentLength = Int(headerLine.split(separator: ":", maxSplits: 1)[1].trimmingCharacters(in: .whitespaces)) ?? 0
            messageEnd = headerEnd + contentLength + 2
            guard messageEnd < data.count else { return nil }
          }
          if headerLine.lowercased().starts(with: Header.contentTypePrefix.lowercased()) {
            responseBuilder.contentType = ContentType.fromHeader(string: headerLine.split(separator: ":", maxSplits: 1)[1].trimmingCharacters(in: .whitespaces))
            guard headerEnd < blockEnd else { return nil }
            if messageEnd == headerEnd { messageEnd = blockEnd }
          }
          else if headerLine.lowercased().starts(with: Header.setCookiePrefix.lowercased()) {
            let cookieAttributes = headerLine.split(separator: ":", maxSplits: 1)[1].split(separator: ";")
            let nameValue = cookieAttributes[0]
            let nameValueParts = nameValue.split(separator: "=", maxSplits: 1)
            guard nameValueParts.count == 2 else { continue }
            let cookieBuilder = CookieBuilder(name: String(nameValueParts[0]).trimWhitespace,
                                              value: String(nameValueParts[1]).trimWhitespace)

            /*
            for cookieAttribute in cookieAttributes.dropFirst() {
              let parts = cookieAttribute.split(separator: "=", maxSplits: 1)
            }
            */
            
            responseBuilder.addCookie(cookieBuilder.cookie)
          }
        } else {
          let segments = headerLine.lowercased().split(separator: " ")
          if segments.count >= 2 && segments[0].starts(with: "http/") {
            responseBuilder = ResponseBuilder()
            responseBuilder?.status = ResponseStatus.from(code: String(segments[1]))
          }
        }
      }
    }
    
    if let responseBuilder = responseBuilder, messageEnd != headerEnd {
      let bodyStartIndex = headerEnd + 2
      responseBuilder.body = Data(data[bodyStartIndex..<messageEnd])
    }
    
    return responseBuilder?.response
  }
}

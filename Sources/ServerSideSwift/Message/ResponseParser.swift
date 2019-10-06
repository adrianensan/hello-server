import Foundation

extension Response {
  static func parse(data: [UInt8]) -> Response? {
    var responseBuilder: ResponseBuilder?
    guard let headerEnd = Message.findHeaderEnd(data: data) else { return nil }
    let headerFields = data[..<headerEnd].split(separator: 10)
    for headerField in headerFields {
      if let headerLine = String(data: Data(headerField), encoding: .utf8) {
        if let responseBuilder = responseBuilder {
          if headerLine.starts(with: Header.setCookiePrefix) {
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
            
            responseBuilder.addCookie(cookieBuilder.finalizedCookie)
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
    
    let bodyStartIndex = headerEnd + 2
    if let responseBuilder = responseBuilder, bodyStartIndex < data.count {
      responseBuilder.body = Data(data[bodyStartIndex..<data.count])
    }
    
    return responseBuilder?.finalizedResponse
  }
}

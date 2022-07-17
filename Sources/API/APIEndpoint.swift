import Foundation

import ServerModels

public struct EmptyResponse: Decodable {
  public init(from decoder: Decoder) throws {}
  
  public init() {}
}

public enum APIEndpointContentType {
  case json
  case multipart(boundary: String)
  
  public var string: String {
    switch self {
    case .json: return "application/json"
    case .multipart(let boundary): return "multipart/form-data; boundary=\(boundary)"
    }
  }
}

public struct APIHeader {
  public var key: String
  public var value: String
  
  public static func custom(key: String, value: String) -> APIHeader {
    APIHeader(key: key, value: value)
  }
}

public enum AuthType {
  case user
  case rep
  case none
}

public enum RequestType {
  case normal
  case upload
  case longPoll
}

public protocol APIEndpoint {
  
  associatedtype ResponseType: Codable = EmptyResponse
  associatedtype RequestBodyType: Codable = Data?
  
  static var method: HTTPMethod { get }
  var contentType: APIEndpointContentType? { get }
  var headers: [APIHeader] { get }
  var authType: AuthType { get }
  var type: RequestType { get }
  var timeout: TimeInterval { get }
  
  static var path: String { get }
  
  var parameters: [String: String] { get }
  
  var body: RequestBodyType { get }
}

extension APIEndpoint {
  
  public var contentType: APIEndpointContentType? { nil }
  
  public var headers: [APIHeader] { [] }
  
  public var authType: AuthType { .none }
  public var type: RequestType { .normal }
  public var timeout: TimeInterval {
    switch type {
    case .normal: return 20
    case .upload: return 100
    case .longPoll: return 120
    }
  }
  
  public var body: Data? { nil }
  
  public var parameters: [String: String] { [:] }
}

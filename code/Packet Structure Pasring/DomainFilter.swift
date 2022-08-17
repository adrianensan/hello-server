import Foundation

public struct DomainFilter: Equatable, Hashable, Codable {
  public var domain: String
  public var includeSubDomains: Bool
  public var ignoreWWW: Bool
  
  public init(domain: String,
              includeSubDomains: Bool,
              ignoreWWW: Bool = true) {
    self.domain = domain
    self.includeSubDomains = includeSubDomains
    self.ignoreWWW = ignoreWWW
  }
  
  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    self.domain = try container.decode(String.self, forKey: .domain)
    self.includeSubDomains = try container.decode(Bool.self, forKey: .includeSubDomains)
    self.ignoreWWW = (try? container.decode(Bool.self, forKey: .ignoreWWW)) ?? true
  }
}

public enum Cache: CustomStringConvertible {
  case noCache
  case noStore
  
  private static let baseString = "HTTP/"
  
  public var description: String {
    switch self {
    case .noCache: return "\(Header.cacheControl)no-cache"
    case .noStore: return "\(Header.cacheControl)no-store"
    }
  }
}

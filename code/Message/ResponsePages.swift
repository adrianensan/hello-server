import Foundation

import HelloCore

public extension HTTPResponseStatus {
  var defaultPage: String? {
    switch self {
    case .notFound: return notFoundPage
    default: return nil
    }
  }
}

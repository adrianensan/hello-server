import Foundation

class DomainProperties {
  var domain: String
  var includeSubDomains: Bool
  var trackedIPv4Addresses: Set<String>
  var trackedIPv6Addresses: Set<String>
  
  init(domain: String, includeSubDomains: Bool) {
    self.domain = domain
    self.includeSubDomains = includeSubDomains
    self.trackedIPv4Addresses = []
    self.trackedIPv6Addresses = []
  }
}

extension TrieNode where T == DomainProperties {
  func search<S: StringProtocol>(for domain: S) -> DomainProperties? {
    var node: TrieNode? = self
    let searchArray = domain.utf8.reversed()
    for (i, byte) in searchArray.enumerated() {
      var byte = byte
      if 65 <= byte && byte <= 90 {
        byte += 32
      }
      
      node = node?.map[byte]
      if let node = node {
        if let value = node.value, value.includeSubDomains &&
            (i + 1 == searchArray.endIndex || searchArray[i + 1] == 46) {
          return value
        }
      } else {
        return nil
      }
    }
    return node?.value
  }
}

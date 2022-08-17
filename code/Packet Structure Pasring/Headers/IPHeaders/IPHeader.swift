import Foundation

import HelloCore

protocol IPHeader {
  var version: IPVersion { get }
  var headerSize: Int { get }
  var `protocol`: IPProtocol { get }
}

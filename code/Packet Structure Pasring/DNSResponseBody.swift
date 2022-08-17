import Foundation

import HelloCore

public struct DNSResponseBody {
  public let ipAddresses: [String: [IPAddress]]
  
  public static func parse(from dataReader: DataReader, header: DNSHeader) throws -> [DNSAnswer]? {
    
    var labelPointers: [Int: String] = [:]
    var packetOffset = DNSHeader.size
    
    // Parse Queries
    var dnsQueries: [DNSQuery] = []

    for _ in 0..<header.questionCount {
      guard let domain = DNSLabel.parseDomain(from: dataReader, labelPointers: &labelPointers, packetOffset: &packetOffset) else {
        return nil
      }
      
      guard let recordTypeInt = dataReader.uint16(),
            let recordClassInt = dataReader.uint16(at: 2)
      else { return nil }
      
      dnsQueries.append(DNSQuery(domain: domain,
                                 recordType: .infer(from: recordTypeInt),
                                 recordClass: .infer(from: recordClassInt)))
      
      dataReader.advanceCursor(by: 4)
      packetOffset += 4
    }
    
    // Parse Answers
    var dnsRecords: [DNSAnswer] = []
    
    for _ in 0..<header.answerCount {
      guard let domain = DNSLabel.parseDomain(from: dataReader, labelPointers: &labelPointers, packetOffset: &packetOffset) else {
        return nil
      }
      
      guard let recordTypeInt = dataReader.uint16(),
            let recordClassInt = dataReader.uint16(at: 2),
            let sizeInt = dataReader.uint16(at: 8)
      else { return nil }
      let recordType: DNSRecordType = .infer(from: recordTypeInt)
      let recordClass: DNSRecordClass = .infer(from: recordClassInt)
      let size = Int(sizeInt)
      
      guard let valueData = dataReader.bytes(at: 10, length: size) else { return nil }
      dataReader.advanceCursor(by: 10 + size)
      packetOffset += 10
      
      switch recordType {
      case .a:
        packetOffset += size
        guard size == 4 else { continue }
        dnsRecords.append(DNSAnswer(domain: domain,
                                    recordType: recordType,
                                    recordClass: recordClass,
                                    value: IPv4Address(valueData[0], valueData[1], valueData[2], valueData[3]).string))
      case .aaaa:
        packetOffset += size
        do {
          let ipv6Address = try IPv6Address([UInt8](valueData))
          dnsRecords.append(DNSAnswer(domain: domain,
                                      recordType: recordType,
                                      recordClass: recordClass,
                                      value: ipv6Address.string))
        } catch {
          
        }
      case .cname, .mx:
        guard let aliasDomain = DNSLabel.parseDomain(from: DataReader(valueData),
                                                labelPointers: &labelPointers,
                                                packetOffset: &packetOffset)
        else { continue }
        dnsRecords.append(DNSAnswer(domain: domain,
                                    recordType: recordType,
                                    recordClass: recordClass,
                                    value: aliasDomain))
      case .other:
        packetOffset += size
      }
    }
    
    return dnsRecords
  }
}

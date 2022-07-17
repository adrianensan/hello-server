import Foundation

public struct DNSRequestBody {
  var domains: [DNSQuery]
  
  public static func parse(from dataReader: DataReader, header: DNSHeader) -> [DNSQuery]? {
    var dnsQueries: [DNSQuery] = []
    
    var labelPointers: [Int: String] = [:]
    var packetOffset = DNSHeader.size
    
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
      dataReader.advanceCursor(by: 5)
    }
    
    return dnsQueries
  }
}

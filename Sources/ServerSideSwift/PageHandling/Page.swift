import Foundation

public class Page {
  
  static func replaceIncludes(in originalString: String, from directory: String, staticRoot: String? = nil, depth: Int = 0) -> String {
    guard depth < 3 else { return originalString }
    var string: String = ""
    for line in originalString.components(separatedBy: .newlines) {
      if line.trimWhitespace.starts(with: keyword) {
        let requestFile = line.trimWhitespace.replacingOccurrences(of: keyword, with: "")
        if requestFile.starts(with: "/"), let fileString = try? String(contentsOfFile: (staticRoot ?? "") + requestFile) {
          string += replaceIncludes(in: fileString, from: directory, depth: depth + 1)
        }
        else if let fileString = try? String(contentsOfFile: directory + requestFile) {
          string += replaceIncludes(in: fileString, from: directory, depth: depth + 1)
        }
      }
      else { string += line + "\n"}
    }
    return string
  }
  
  let rawPage: String
  
  init?(filePath: String) {
    guard let fileString = try? String(contentsOfFile: filePath) else { return nil }
    let directory = String(filePath[...(filePath.lastIndex(of: "/") ?? filePath.endIndex)])
    
    var staticRoot: String? = nil
    if let staticRootIndex = filePath.range(of: "/static/")?.upperBound {
      staticRoot = String(filePath[...staticRootIndex])
    }
    
    rawPage = Page.replaceIncludes(in: fileString, from: directory, staticRoot: staticRoot)
  }
  
  init(rawPage: String) {
    self.rawPage = rawPage
  }
  
  var insertions: [String: String] = [:]
  
  var compiledPage: String {
    var compiledPage = rawPage
    for (insertionKey, insertion) in insertions {
      compiledPage.replacingOccurrences(of: "?insertion:${\(insertionKey)}", with: insertion)
    }
    return compiledPage
  }
}

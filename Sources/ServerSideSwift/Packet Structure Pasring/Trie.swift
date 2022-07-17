import Foundation

public class TrieNode<T> {
  public private(set) var value: T?
  public private(set) var map: [UInt8: TrieNode]
  
  public static func construct(from valuesMap: [String: T]) -> TrieNode {
    let root = TrieNode()
    root.add(from: valuesMap)
    return root
  }
  
  public init(value: T? = nil) {
    self.value = value
    self.map = [:]
  }
  
  public func add(from valuesMap: [String: T]) {
    for (key, value) in valuesMap {
      var currentNode: TrieNode = self
      for character in key.utf8 {
        if let node = currentNode.map[character] {
          currentNode = node
          continue
        } else {
          let newNode = TrieNode()
          currentNode.map[character] = newNode
          currentNode = newNode
        }
      }
      currentNode.value = value
    }
  }
}

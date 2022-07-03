import Foundation
import System
import HelloLog

enum SocketState {
  case closed
  case readyToRead
  case idle
}

actor SocketPool {
  static var main: SocketPool = SocketPool()
  
  var sockets: Set<Int32> = []
  var pollTask: Task<[Int32: SocketState], any Error>?
  var socketListeners: [Int32: CheckedContinuation<SocketState, Never>] = [:]
  
  func waitForChange(on socket: Socket) async -> SocketState {
    if !sockets.contains(socket.socketFileDescriptor) {
      sockets.insert(socket.socketFileDescriptor)
    }
    
    return await withCheckedContinuation { continuation in
      addListener(continuation, to: socket.socketFileDescriptor)
      startPollTask()
    }
  }
  
  func startPollTask() {
    Task {
      let socketStates = try await pollSocketStates()
      for socketState in socketStates where socketState.value != .idle {
        sockets.remove(socketState.key)
        socketListeners[socketState.key]?.resume(returning: socketState.value)
        socketListeners[socketState.key] = nil
      }
      if !sockets.isEmpty {
        startPollTask()
      }
    }
  }
  
  func addListener(_ continuation: CheckedContinuation<SocketState, Never>, to fd: Int32) {
    socketListeners[fd]?.resume(returning: .idle)
    socketListeners[fd] = continuation
  }
  
  func pollSocketStates() async throws -> [Int32: SocketState] {
    Log.info("waiting on \(self.sockets.count) sockets", context: "Poll")
    self.pollTask?.cancel()
    let pollTask = Task { () -> [Int32: SocketState] in
      while true {
        var pollSockets = self.sockets.map {
          pollfd(fd: $0, events: Int16(POLLIN | POLLPRI), revents: 0)
        }
        poll(&pollSockets, nfds_t(pollSockets.count), 0)
        var socketStates: [Int32: SocketState] = [:]
        for pollSocket in pollSockets {
          socketStates[pollSocket.fd] = .idle
          if pollSocket.revents != 0 {
            if pollSocket.revents & Int16(POLLERR | POLLHUP | POLLNVAL) != 0 {
              socketStates[pollSocket.fd] = .closed
            } else if pollSocket.revents & Int16(POLLIN | POLLPRI) != 0 {
              socketStates[pollSocket.fd] = .readyToRead
            }
          }
        }
        if socketStates.contains(where: { $0.value != .idle }) {
          Log.info("poll done", context: "Poll")
          return socketStates
        } else {
          try await Task.sleep(nanoseconds: 10_000_000)
        }
      }
    }
    self.pollTask = pollTask
    let value = try await pollTask.value
    self.pollTask = nil
    return value
  }
}

import Foundation

class PipeBuffer {
  enum StreamID: String {
    case stdOut, stdErr
  }
  
  let pipe = Pipe()
  private var buffer: Data = .init()
  private let queue: DispatchQueue

  private let semaphore = DispatchGroup()
  
  convenience init(id: StreamID, qos: DispatchQoS.QoSClass = .userInitiated) {
    self.init(label: id.rawValue, qos: qos)
  }
  
  init(label: String, qos: DispatchQoS.QoSClass = .userInitiated) {

    self.queue = DispatchQueue(
      label: label,
      target: DispatchQueue.global(qos: qos)
    )

    self.pipe.fileHandleForReading.readabilityHandler = { handler in

      self.queue.async {
        self.semaphore.enter()
        let data = try! handler.readToEnd()
        self.buffer.append(contentsOf: data ?? Data())
        self.semaphore.leave()
      }
    }
  }

  func closeReturningData() -> Data {

    let data = queue.sync {
      self.semaphore.wait()
      return self.buffer
    }

    self.pipe.fileHandleForReading.readabilityHandler = nil
    self.buffer = Data()

    return data
  }
}

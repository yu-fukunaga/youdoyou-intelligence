import Foundation

extension UUID {
  /// Generates a version 7 UUID (RFC 9562): a 48-bit millisecond Unix timestamp
  /// followed by random bits, so values sort chronologically by creation time.
  public static func v7(now: Date = Date()) -> UUID {
    let timestampMs = UInt64(now.timeIntervalSince1970 * 1000)
    var generator = SystemRandomNumberGenerator()

    var bytes = [UInt8](repeating: 0, count: 16)
    bytes[0] = UInt8((timestampMs >> 40) & 0xFF)
    bytes[1] = UInt8((timestampMs >> 32) & 0xFF)
    bytes[2] = UInt8((timestampMs >> 24) & 0xFF)
    bytes[3] = UInt8((timestampMs >> 16) & 0xFF)
    bytes[4] = UInt8((timestampMs >> 8) & 0xFF)
    bytes[5] = UInt8(timestampMs & 0xFF)

    for i in 6..<16 {
      bytes[i] = UInt8.random(in: 0...255, using: &generator)
    }

    bytes[6] = (bytes[6] & 0x0F) | 0x70  // version 7
    bytes[8] = (bytes[8] & 0x3F) | 0x80  // variant 10

    let uuid = uuid_t(
      bytes[0], bytes[1], bytes[2], bytes[3],
      bytes[4], bytes[5], bytes[6], bytes[7],
      bytes[8], bytes[9], bytes[10], bytes[11],
      bytes[12], bytes[13], bytes[14], bytes[15]
    )
    return UUID(uuid: uuid)
  }
}

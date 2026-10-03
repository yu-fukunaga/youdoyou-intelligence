import Foundation

public struct User: Identifiable, Sendable {
  public var id: String
  public var displayName: String?
  public var email: String?
  public var photoURL: URL?

  public init(
    id: String,
    displayName: String? = nil,
    email: String? = nil,
    photoURL: URL? = nil
  ) {
    self.id = id
    self.displayName = displayName
    self.email = email
    self.photoURL = photoURL
  }
}

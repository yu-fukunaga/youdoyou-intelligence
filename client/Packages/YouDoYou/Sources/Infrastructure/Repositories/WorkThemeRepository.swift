import Domain
import FirebaseFirestore
import FirebaseStorage
import Foundation

public struct WorkThemeRepository: WorkThemeRepositoryProtocol, @unchecked Sendable {
  private let db: Firestore
  private let storage: Storage

  private var collection: CollectionReference {
    db.collection(DomainCollection.name)
  }

  public init(db: Firestore = Firestore.firestore(), storage: Storage = Storage.storage()) {
    self.db = db
    self.storage = storage
  }

  public func observe(onChange: @escaping ([Domain.WorkTheme]) -> Void) -> any ListenerHandle {
    let registration =
      collection
      .order(by: WorkThemeFields.createdAt, descending: true)
      .addSnapshotListener { snapshot, _ in
        let workThemes =
          snapshot?.documents.compactMap { doc -> Domain.WorkTheme? in
            (try? doc.data(as: WorkTheme.self))?.toDomainModel()
          } ?? []
        onChange(workThemes)
      }
    return FirestoreListenerHandle(registration)
  }

  public func add(_ workTheme: Domain.WorkTheme) async throws {
    try collection.document(workTheme.id).setData(from: workTheme.toDTO())
  }

  public func update(_ workTheme: Domain.WorkTheme) async throws {
    try collection.document(workTheme.id).setData(from: workTheme.toDTO(), merge: true)
  }

  public func delete(id: String) async throws {
    try await collection.document(id).delete()
  }

  public func uploadTopicImage(topicId: String, data: Data) async throws -> String {
    let ref = storage.reference().child("topics/\(topicId)/icon")
    _ = try await ref.putDataAsync(data)
    let url = try await ref.downloadURL()
    return url.absoluteString
  }
}

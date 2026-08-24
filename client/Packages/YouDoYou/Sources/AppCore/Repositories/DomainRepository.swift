import FirebaseFirestore
import FirebaseStorage
import Foundation

protocol DomainRepositoryProtocol: Sendable {
  func observe(onChange: @escaping ([Domain]) -> Void) -> ListenerRegistration
  func create(title: String, description: String, topics: [Topic], color: String?) async throws
  func update(_ domain: Domain) async throws
  func delete(id: String) async throws
  func uploadTopicImage(topicId: String, data: Data) async throws -> String
}

struct DomainRepository: DomainRepositoryProtocol, @unchecked Sendable {
  private let db: Firestore
  private let storage: Storage

  private var collection: CollectionReference {
    db.collection(DomainCollection.name)
  }

  init(db: Firestore = Firestore.firestore(), storage: Storage = Storage.storage()) {
    self.db = db
    self.storage = storage
  }

  func observe(onChange: @escaping ([Domain]) -> Void) -> ListenerRegistration {
    collection
      .order(by: DomainFields.createdAt, descending: true)
      .addSnapshotListener { snapshot, _ in
        let domains =
          snapshot?.documents.compactMap { doc -> Domain? in
            do {
              return try doc.data(as: Domain.self)
            }
            catch {
              print("デコードエラー: \(error)")
              return nil
            }
          } ?? []
        onChange(domains)
      }
  }

  func create(title: String, description: String, topics: [Topic], color: String?) async throws {
    let newDomain = Domain(
      title: title,
      description: description,
      topics: topics,
      color: color
    )
    try collection.addDocument(from: newDomain)
  }

  func update(_ domain: Domain) async throws {
    guard let id = domain.id else { return }
    try collection.document(id).setData(from: domain, merge: true)
  }

  func delete(id: String) async throws {
    try await collection.document(id).delete()
  }

  func uploadTopicImage(topicId: String, data: Data) async throws -> String {
    let ref = storage.reference().child("topics/\(topicId)/icon")
    _ = try await ref.putDataAsync(data)
    let url = try await ref.downloadURL()
    return url.absoluteString
  }
}

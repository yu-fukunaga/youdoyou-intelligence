import FirebaseFirestore
import Foundation

protocol DomainRepositoryProtocol: Sendable {
  func observe(onChange: @escaping ([Domain]) -> Void) -> ListenerRegistration
  func create(title: String, description: String, topics: [Topic]) async throws
  func update(_ domain: Domain) async throws
  func delete(id: String) async throws
}

struct DomainRepository: DomainRepositoryProtocol, @unchecked Sendable {
  private let db: Firestore

  private var collection: CollectionReference {
    db.collection(DomainCollection.name)
  }

  init(db: Firestore = Firestore.firestore()) {
    self.db = db
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

  func create(title: String, description: String, topics: [Topic]) async throws {
    let newDomain = Domain(
      title: title,
      description: description,
      topics: topics
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
}

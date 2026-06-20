import FirebaseFirestore
import Foundation
import YouDoYouFirestore

protocol ActivityRepositoryProtocol: Sendable {
  func observe(onChange: @escaping ([Activity]) -> Void) -> ListenerRegistration
  func create(_ activity: Activity) async throws
  func delete(id: String) async throws
  func update(_ activity: Activity) async throws
  func query(from: Date, to: Date) async throws -> [Activity]
}

struct ActivityRepository: ActivityRepositoryProtocol, @unchecked Sendable {
  private let db: Firestore

  private var collection: CollectionReference {
    db.collection(ActivityCollection.name)
  }

  init(db: Firestore = Firestore.firestore()) {
    self.db = db
  }

  func observe(onChange: @escaping ([Activity]) -> Void) -> ListenerRegistration {
    collection
      .order(by: ActivityFields.startedAt, descending: true)
      .addSnapshotListener { snapshot, _ in
        let items =
          snapshot?.documents.compactMap {
            try? $0.data(as: Activity.self)
          } ?? []
        onChange(items)
      }
  }

  func create(_ activity: Activity) async throws {
    try collection.addDocument(from: activity)
  }

  func delete(id: String) async throws {
    try await collection.document(id).delete()
  }

  func update(_ activity: Activity) async throws {
    try collection.document(activity.id ?? "").setData(from: activity)
  }

  func query(from: Date, to: Date) async throws -> [Activity] {
    let snapshot =
      try await collection
      .whereField(ActivityFields.startedAt, isGreaterThanOrEqualTo: from)
      .whereField(ActivityFields.startedAt, isLessThanOrEqualTo: to)
      .order(by: ActivityFields.startedAt, descending: false)
      .getDocuments()
    return snapshot.documents.compactMap { try? $0.data(as: Activity.self) }
  }

}

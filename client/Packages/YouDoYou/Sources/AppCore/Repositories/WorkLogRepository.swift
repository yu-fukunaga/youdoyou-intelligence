import FirebaseFirestore
import Foundation

protocol WorkLogRepositoryProtocol: Sendable {
  func observe(onChange: @escaping ([WorkLog]) -> Void) -> ListenerRegistration
  func create(_ workLog: WorkLog) async throws
  func delete(id: String) async throws
  func update(_ workLog: WorkLog) async throws
  func query(from: Date, to: Date) async throws -> [WorkLog]
}

struct WorkLogRepository: WorkLogRepositoryProtocol, @unchecked Sendable {
  private let db: Firestore

  private var collection: CollectionReference {
    db.collection(WorkLogCollection.name)
  }

  init(db: Firestore = Firestore.firestore()) {
    self.db = db
  }

  func observe(onChange: @escaping ([WorkLog]) -> Void) -> ListenerRegistration {
    collection
      .order(by: WorkLogFields.startedAt, descending: true)
      .addSnapshotListener { snapshot, _ in
        let items =
          snapshot?.documents.compactMap {
            try? $0.data(as: WorkLog.self)
          } ?? []
        onChange(items)
      }
  }

  func create(_ workLog: WorkLog) async throws {
    try collection.addDocument(from: workLog)
  }

  func delete(id: String) async throws {
    try await collection.document(id).delete()
  }

  func update(_ workLog: WorkLog) async throws {
    try collection.document(workLog.id ?? "").setData(from: workLog)
  }

  func query(from: Date, to: Date) async throws -> [WorkLog] {
    let snapshot =
      try await collection
      .whereField(WorkLogFields.startedAt, isGreaterThanOrEqualTo: from)
      .whereField(WorkLogFields.startedAt, isLessThanOrEqualTo: to)
      .order(by: WorkLogFields.startedAt, descending: false)
      .getDocuments()
    return snapshot.documents.compactMap { try? $0.data(as: WorkLog.self) }
  }

}

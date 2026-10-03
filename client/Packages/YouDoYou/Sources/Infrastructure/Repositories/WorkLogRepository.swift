import Domain
import FirebaseFirestore
import Foundation

public struct WorkLogRepository: WorkLogRepositoryProtocol, @unchecked Sendable {
  private let db: Firestore

  private var collection: CollectionReference {
    db.collection(WorkLogCollection.name)
  }

  public init(db: Firestore = Firestore.firestore()) {
    self.db = db
  }

  public func observe(onChange: @escaping ([Domain.WorkLog]) -> Void) -> any ListenerHandle {
    let registration =
      collection
      .order(by: WorkLogFields.startedAt, descending: true)
      .addSnapshotListener { snapshot, _ in
        let items =
          snapshot?.documents.compactMap { doc -> Domain.WorkLog? in
            (try? doc.data(as: WorkLog.self))?.toDomainModel()
          } ?? []
        onChange(items)
      }
    return FirestoreListenerHandle(registration)
  }

  public func add(_ workLog: Domain.WorkLog) async throws {
    try collection.document(workLog.id).setData(from: workLog.toDTO())
  }

  public func update(_ workLog: Domain.WorkLog) async throws {
    try collection.document(workLog.id).setData(from: workLog.toDTO(), merge: true)
  }

  public func delete(id: String) async throws {
    try await collection.document(id).delete()
  }

  public func query(from: Date, to: Date) async throws -> [Domain.WorkLog] {
    let snapshot =
      try await collection
      .whereField(WorkLogFields.startedAt, isGreaterThanOrEqualTo: from)
      .whereField(WorkLogFields.startedAt, isLessThanOrEqualTo: to)
      .order(by: WorkLogFields.startedAt, descending: false)
      .getDocuments()
    return snapshot.documents.compactMap { (try? $0.data(as: WorkLog.self))?.toDomainModel() }
  }
}

import Domain
import FirebaseFirestore
import FirebaseStorage
import Foundation

public struct WorkTopicRepository: WorkTopicRepositoryProtocol, @unchecked Sendable {
  private let db: Firestore
  private let storage: Storage

  private var collection: CollectionReference {
    db.collection(WorkTopicCollection.name)
  }

  public init(db: Firestore = Firestore.firestore(), storage: Storage = Storage.storage()) {
    self.db = db
    self.storage = storage
  }

  public func observe(onChange: @escaping ([Domain.WorkTopic]) -> Void) -> any ListenerHandle {
    let registration =
      collection
      .order(by: WorkTopicFields.createdAt, descending: true)
      .addSnapshotListener { snapshot, _ in
        let workTopics =
          snapshot?.documents.compactMap { doc -> Domain.WorkTopic? in
            (try? doc.data(as: WorkTopic.self))?.toDomainModel()
          } ?? []
        onChange(workTopics)
      }
    return FirestoreListenerHandle(registration)
  }

  public func add(_ workTopic: Domain.WorkTopic) async throws {
    try collection.document(workTopic.id).setData(from: workTopic.toDTO())
  }

  public func update(_ workTopic: Domain.WorkTopic) async throws {
    try collection.document(workTopic.id).setData(from: workTopic.toDTO(), merge: true)
  }

  public func delete(id: String) async throws {
    try await collection.document(id).delete()
  }

  public func uploadImage(workTopicId: String, data: Data) async throws -> String {
    let ref = storage.reference().child("work_topics/\(workTopicId)/icon")
    _ = try await ref.putDataAsync(data)
    let url = try await ref.downloadURL()
    return url.absoluteString
  }
}

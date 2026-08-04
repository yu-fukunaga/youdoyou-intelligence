import FirebaseAuth
import FirebaseCore
import FirebaseFirestore
import FirebaseStorage

public func configureFirebase() {
  #if DEBUG
    if EnvUtils.isEmulator {
      configureWithEmulator()
      return
    }
  #endif
  FirebaseApp.configure()
}

#if DEBUG
  private func configureWithEmulator() {
    FirebaseApp.configure()

    let host = EnvUtils.emulatorHost
    let firestoreSettings = Firestore.firestore().settings
    firestoreSettings.host = "\(host):8080"
    firestoreSettings.cacheSettings = MemoryCacheSettings()
    firestoreSettings.isSSLEnabled = false
    Firestore.firestore().settings = firestoreSettings

    Storage.storage().useEmulator(withHost: host, port: 9199)
    Auth.auth().useEmulator(withHost: host, port: 9099)
  }
#endif

// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "youdoyou-firestore-gen-swift",
    platforms: [.iOS(.v16)],
    products: [
        .library(name: "YouDoYouFirestore", targets: ["YouDoYouFirestore"])
    ],
    dependencies: [
        .package(url: "https://github.com/firebase/firebase-ios-sdk.git", from: "12.0.0")
    ],
    targets: [
        .target(
            name: "YouDoYouFirestore",
            dependencies: [
                .product(name: "FirebaseFirestore", package: "firebase-ios-sdk")
            ],
            path: "schema"
        )
    ]
)

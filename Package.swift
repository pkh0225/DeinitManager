// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "DeinitChecker",
    platforms: [
        .iOS(.v12)
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "DeinitChecker",
            targets: ["DeinitChecker"]),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "DeinitChecker",
            dependencies: [],
            path: "Sources", // 소스 경로를 명시적으로 설정
            exclude: [],     // 제외할 파일이나 디렉토리 설정
            resources: [],   // 리소스 파일 추가 시 필요
            swiftSettings: [] // Swift 관련 추가 설정),
        )
    ]
)

// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "YPImagePicker",
    defaultLocalization: "en",
    platforms: [.iOS(.v13)],
    products: [
        .library(
            name: "YPImagePicker",
            targets: ["YPImagePicker"]),
    ],
    dependencies: [
        .package(
            name: "PryntTrimmerView",
            url: "git@github.com:HHK1/PryntTrimmerView.git",
            .upToNextMajor(from: .init(4, 0, 2))
        ),
        .package(
            name: "Stevia",
            url: "git@github.com:freshOS/Stevia.git",
            .upToNextMajor(from: .init(5, 1, 1))
        )
    ],
    targets: [
        .target(
            name: "YPImagePicker",
            dependencies: [
                .product(
                    name: "Stevia",
                    package: "Stevia"
                ),
                .product(
                    name: "PryntTrimmerView",
                    package: "PryntTrimmerView"
                )
            ]),
        .testTarget(
            name: "YPImagePickerTests",
            dependencies: ["YPImagePicker"]),
    ]
)

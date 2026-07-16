#!/bin/bash

set -e

DIR="$(cd "$(dirname "$0")" && pwd)"

cd "$DIR"

BUILD_DIR="$DIR/build"

rm -rf "$BUILD_DIR"

mkdir "$BUILD_DIR"
cd "$BUILD_DIR"

echo "Initializing Swift package..."

swift package init --type executable

cp "$DIR/main.swift" Sources/main.swift

cat > Package.swift <<'EOF'
 // swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "MountainClient",
    platforms: [
        .macOS(.v13)
    ],
    dependencies: [
        .package(
            url: "https://github.com/emqx/CocoaMQTT.git",
            from: "2.1.0"
        )
    ],
    targets: [
        .executableTarget(
            name: "MountainClient",
            dependencies: [
                .product(
                    name: "CocoaMQTT",
                    package: "CocoaMQTT"
                )
            ]
        )
    ]
)
EOF

echo "Resolving dependencies..."
swift package resolve

echo "Building..."
swift build -c release

echo "Copying binary..."

cp .build/release/MountainClient "$DIR/mountain-client"

chmod +x "$DIR/mountain-client"

cd "$DIR"

rm -rf "$BUILD_DIR"

echo "Done:"
file "$DIR/mountain-client"
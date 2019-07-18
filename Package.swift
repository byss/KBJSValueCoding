// swift-tools-version:5.3

import PackageDescription

private let libraryName = "KBJSValueCoding";

let package = Package (
	name: libraryName,
	products: [ .library (name: libraryName, targets: [libraryName]) ],
	targets: [ .target (name: libraryName, path: ".") ]
);

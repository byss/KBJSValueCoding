//
//  KBJSCodingKey.swift
//  KBJSValueCoding
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

import Foundation

internal struct KBJSCodingKey: CodingKey {
	internal static let `super` = KBJSCodingKey (stringValue: "super");
	
	internal let stringValue: String;
	internal let intValue: Int?;
	
	internal init (stringValue: String) {
		self.stringValue = stringValue;
		self.intValue = nil;
	}
	
	internal init (intValue: Int) {
		self.stringValue = "\(intValue)";
		self.intValue = intValue;
	}
	
	internal init (convertingToSnakeCase other: CodingKey) {
		self.init (stringValue: String (convertingToSnakeCase: other.stringValue));
	}
	
	internal init (convertingFromSnakeCase other: CodingKey) {
		self.init (stringValue: String (convertingFromSnakeCase: other.stringValue));
	}
}

/* fileprivate */ extension String {
	fileprivate init (convertingToSnakeCase string: String) {
		self.init (source: string) {
			var result = ContiguousArray <UTF16.CodeUnit> ();
			result.reserveCapacity ($0.count * 3 / 2);
			for scalar in string.unicodeScalars {
				if (scalar.properties.isUppercase) {
					result.append (.underscore);
					result.append (contentsOf: scalar.properties.lowercaseMapping.utf16);
				} else {
					result.append (contentsOf: scalar.utf16);
				}
			}
			return result;
		};
	}

	fileprivate init (convertingFromSnakeCase string: String) {
		self.init (source: string) {
			var result = ContiguousArray <UTF16.CodeUnit> ();
			result.reserveCapacity ($0.count);
			var lastIdx = $0.startIndex;
			while (lastIdx < $0.endIndex), let underscoreIdx = $0 [lastIdx...].firstIndex (of: .underscore) {
				result.append (contentsOf: $0 [lastIdx ..< underscoreIdx]);
				lastIdx = underscoreIdx + 1;
				if (lastIdx < $0.endIndex) {
					var codec = UTF16 (), nextCharIterator = $0.makeIterator (at: lastIdx);
					guard case .scalarValue (let decodedScalar) = codec.decode (&nextCharIterator) else {
						continue;
					}
					result.append (contentsOf: decodedScalar.properties.uppercaseMapping.utf16);
					lastIdx = nextCharIterator.index;
				}
			}
			if (lastIdx < $0.endIndex) {
				result.append (contentsOf: $0 [lastIdx...]);
			}
			return result;
		};
	}
	
	private init (source string: String, transformingUTF16CodeUnitsUsing transform: (ContiguousArray <UTF16.CodeUnit>) -> ContiguousArray <UTF16.CodeUnit>) {
		self = transform (ContiguousArray (string.utf16)).withUnsafeBufferPointer { String (utf16CodeUnits: $0.baseAddress!, count: $0.count) };
	}
}

/* fileprivate */ extension ContiguousArray where Element == UTF16.CodeUnit {
	fileprivate struct RandomAccessIterator: IteratorProtocol {
		fileprivate private (set) var index: ContiguousArray.Index;
		private let array: ContiguousArray;
		
		fileprivate init (index: ContiguousArray.Index, in array: ContiguousArray) {
			self.array = array;
			self.index = index;
		}
		
		fileprivate mutating func next () -> UTF16.CodeUnit? {
			guard (self.index < self.array.endIndex) else {
				return nil;
			}
			defer { self.index = self.array.index (after: self.index) };
			return self.array [self.index];
		}
	}
	
	fileprivate func makeIterator (at index: Index) -> RandomAccessIterator {
		return RandomAccessIterator (index: index, in: self);
	}
}

/* fileprivate */ extension UTF16.CodeUnit {
	fileprivate static let underscore = "_".utf16.first!;
}

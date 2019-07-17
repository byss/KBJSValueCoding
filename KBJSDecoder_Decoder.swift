//
//  KBJSDecoder_Decoder.swift
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
import JavaScriptCore

/* internal */ extension KBJSDecoder {
	internal final class Decoder {
		internal let value: JSValue;
		internal let keyDecodingStrategy: KeyDecodingStrategy;
		
		internal let codingPath: [CodingKey];
		internal let userInfo: [CodingUserInfoKey: Any];
		
		internal convenience init (value: JSValue, keyDecodingStrategy: KeyDecodingStrategy, userInfo: [CodingUserInfoKey: Any]) {
			self.init (value: value, keyDecodingStrategy: keyDecodingStrategy, codingPath: [], userInfo: userInfo);
		}
		
		fileprivate convenience init (parent: Decoder, key: CodingKey) {
			self.init (parent: parent, value: parent.value, key: key);
		}
		
		fileprivate convenience init (parent: Decoder, value: JSValue, key: CodingKey) {
			self.init (value: parent.value, keyDecodingStrategy: parent.keyDecodingStrategy, codingPath: parent.codingPath + [key], userInfo: parent.userInfo);
		}
		
		private init (value: JSValue, keyDecodingStrategy: KeyDecodingStrategy, codingPath: [CodingKey], userInfo: [CodingUserInfoKey: Any]) {
			self.value = value;
			self.keyDecodingStrategy = keyDecodingStrategy;
			self.codingPath = [];
			self.userInfo = userInfo;
		}
	}
}

extension KBJSDecoder.Decoder: Decoder {
	internal func container <Key> (keyedBy type: Key.Type) -> KeyedDecodingContainer <Key> where Key: CodingKey {
		return KeyedDecodingContainer (KBJSDecoder.KeyedDecodingContainer (self));
	}
	
	internal func unkeyedContainer () -> UnkeyedDecodingContainer {
		return KBJSDecoder.UnkeyedDecodingContainer (self);
	}
	
	internal func singleValueContainer () -> SingleValueDecodingContainer {
		return KBJSDecoder.SingleValueDecodingContainer (self);
	}

	fileprivate func decodedKey (_ codingKey: CodingKey) -> CodingKey {
		switch (self.keyDecodingStrategy) {
		case .useDefaultKeys:
			return codingKey;
		case .convertFromSnakeCase:
			return codingKey; // TODO
		case .custom (let block):
			return block (self.codingPath + [codingKey]);
		@unknown default:
			fatalError ("\(self.keyDecodingStrategy) is not supported");
		}
	}
}

/* fileprivate */ extension KBJSDecoder {
	fileprivate struct KeyedDecodingContainer <Key>: KeyedDecodingContainerProtocol where Key: CodingKey {
		fileprivate var allKeys: [Key] {
			return self.value.toDictionary ()!.keys.compactMap { ($0 as? String).flatMap (Key.init) };
		}
		
		fileprivate var codingPath: [CodingKey] {
			return self.decoder.codingPath;
		}
		
		private var value: JSValue {
			return self.decoder.value;
		}
		
		private let decoder: Decoder;

		fileprivate init (_ decoder: Decoder) {
			self.decoder = decoder;
		}
		
		fileprivate func contains (_ key: Key) -> Bool {
			return self.value.hasProperty (self.decoder.decodedKey (key).stringValue);
		}
		
		fileprivate func decodeNil (forKey key: Key) -> Bool {
			return self.decodeValue (forKey: key).isNull;
		}

		fileprivate func decode (_ type: Bool.Type, forKey key: Key) -> Bool {
			return self.decodeValue (forKey: key).isNull;
		}
		
		fileprivate func decode (_ type: String.Type, forKey key: Key) -> String {
			return self.decodeValue (forKey: key).toString ();
		}
		
		fileprivate func decode (_ type: Double.Type, forKey key: Key) -> Double {
			return self.decodeValue (forKey: key).toDouble ();
		}
		
		fileprivate func decode (_ type: Int32.Type, forKey key: Key) -> Int32 {
			return self.decodeValue (forKey: key).toInt32 ();
		}
		
		fileprivate func decode (_ type: UInt32.Type, forKey key: Key) -> UInt32 {
			return self.decodeValue (forKey: key).toUInt32 ();
		}

		fileprivate func decode (_ type: Float.Type, forKey key: Key) -> Float {
			return Float (self.decode (Double.self, forKey: key));
		}
		
		fileprivate func decode (_ type: Int.Type, forKey key: Key) -> Int {
			return numericCast (self.decode (Int32.self, forKey: key));
		}
		
		fileprivate func decode (_ type: Int8.Type, forKey key: Key) -> Int8 {
			return numericCast (self.decode (Int32.self, forKey: key));
		}
		
		fileprivate func decode (_ type: Int16.Type, forKey key: Key) -> Int16 {
			return numericCast (self.decode (Int32.self, forKey: key));
		}

		fileprivate func decode (_ type: Int64.Type, forKey key: Key) -> Int64 {
			return numericCast (self.decode (Int32.self, forKey: key));
		}
		
		fileprivate func decode (_ type: UInt.Type, forKey key: Key) -> UInt {
			return numericCast (self.decode (UInt32.self, forKey: key));
		}
		
		fileprivate func decode (_ type: UInt8.Type, forKey key: Key) -> UInt8 {
			return numericCast (self.decode (UInt32.self, forKey: key));
		}
		
		fileprivate func decode (_ type: UInt16.Type, forKey key: Key) -> UInt16 {
			return numericCast (self.decode (UInt32.self, forKey: key));
		}
		
		fileprivate func decode (_ type: UInt64.Type, forKey key: Key) -> UInt64 {
			return numericCast (self.decode (UInt32.self, forKey: key));
		}
		
		fileprivate func decode <T> (_ type: T.Type, forKey key: Key) throws -> T where T: Decodable {
			if (type == Date.self) {
				return unsafeBitCast (self.decodeValue (forKey: key).toDate ()!, to: T.self);
			}
			return try type.init (from: self.decoder);
		}

		fileprivate func nestedContainer <NestedKey> (keyedBy type: NestedKey.Type, forKey key: Key) -> Swift.KeyedDecodingContainer <NestedKey> where NestedKey : CodingKey {
			return Decoder (parent: self.decoder, value: self.decodeValue (forKey: key), key: key).container (keyedBy: type);
		}
		
		fileprivate func nestedUnkeyedContainer (forKey key: Key) -> Swift.UnkeyedDecodingContainer {
			return Decoder (parent: self.decoder, value: self.decodeValue (forKey: key), key: key).unkeyedContainer ();
		}
		
		fileprivate func superDecoder () -> Swift.Decoder {
			return Decoder (parent: self.decoder, key: KBJSCodingKey.super);
		}
		
		fileprivate func superDecoder (forKey key: Key) -> Swift.Decoder {
			return Decoder (parent: self.decoder, key: key);
		}
		
		private func decodeValue (forKey key: Key) -> JSValue {
			return self.value.forProperty (self.decoder.decodedKey (key).stringValue);
		}
	}
}

/* fileprivate */ extension KBJSDecoder {
	fileprivate struct UnkeyedDecodingContainer: Swift.UnkeyedDecodingContainer {
		fileprivate var codingPath: [CodingKey] {
			return self.decoder.codingPath;
		}
		
		fileprivate var count: Int? {
			return Int (self.value.forProperty ("length").toInt32 ());
		}
		
		fileprivate var isAtEnd: Bool {
			return self.currentIndex >= self.count!;
		}
		
		fileprivate private (set) var currentIndex: Int = 0;
		
		private var value: JSValue {
			return self.decoder.value;
		}
		
		private var currentKey: CodingKey {
			return KBJSCodingKey (intValue: self.currentIndex);
		}
		
		private let decoder: Decoder;
		
		fileprivate init (_ decoder: Decoder) {
			self.decoder = decoder;
		}
		
		fileprivate mutating func decodeNil () -> Bool {
			return self.decodeNext ().isNull;
		}
		
		fileprivate mutating func decode (_ type: Bool.Type) -> Bool {
			return self.decodeNext ().toBool ();
		}
		
		fileprivate mutating func decode (_ type: String.Type) -> String {
			return self.decodeNext ().toString ();
		}
		
		fileprivate mutating func decode (_ type: Double.Type) -> Double {
			return self.decodeNext ().toDouble ();
		}
		
		fileprivate mutating func decode (_ type: Int32.Type) -> Int32 {
			return self.decodeNext ().toInt32 ();
		}
		
		fileprivate mutating func decode (_ type: UInt32.Type) -> UInt32 {
			return self.decodeNext ().toUInt32 ();
		}
		
		fileprivate mutating func decode (_ type: Float.Type) -> Float {
			return Float (self.decode (Double.self));
		}
		
		fileprivate mutating func decode (_ type: Int.Type) -> Int {
			return numericCast (self.decode (Int32.self));
		}
		
		fileprivate mutating func decode (_ type: Int8.Type) -> Int8 {
			return numericCast (self.decode (Int32.self));
		}
		
		fileprivate mutating func decode (_ type: Int16.Type) -> Int16 {
			return numericCast (self.decode (Int32.self));
		}
		
		fileprivate mutating func decode (_ type: Int64.Type) -> Int64 {
			return numericCast (self.decode (Int32.self));
		}
		
		fileprivate mutating func decode (_ type: UInt.Type) -> UInt {
			return numericCast (self.decode (UInt32.self));
		}
		
		fileprivate mutating func decode (_ type: UInt8.Type) -> UInt8 {
			return numericCast (self.decode (UInt32.self));
		}
		
		fileprivate mutating func decode (_ type: UInt16.Type) -> UInt16 {
			return numericCast (self.decode (UInt32.self));
		}
		
		fileprivate mutating func decode (_ type: UInt64.Type) -> UInt64 {
			return numericCast (self.decode (UInt32.self));
		}
		
		fileprivate mutating func decode <T> (_ type: T.Type) throws -> T where T: Decodable {
			if (type == Date.self) {
				return unsafeBitCast (self.decodeNext ().toDate ()!, to: T.self);
			}
			return try type.init (from: self.decoder);
		}
		
		fileprivate mutating func nestedContainer <NestedKey> (keyedBy type: NestedKey.Type) throws -> Swift.KeyedDecodingContainer <NestedKey> where NestedKey: CodingKey {
			let key = self.currentKey, value = self.decodeNext ();
			return Decoder (parent: self.decoder, value: value, key: key).container (keyedBy: type);
		}
		
		fileprivate mutating func nestedUnkeyedContainer () throws -> Swift.UnkeyedDecodingContainer {
			let key = self.currentKey, value = self.decodeNext ();
			return Decoder (parent: self.decoder, value: value, key: key).unkeyedContainer ();
		}
		
		fileprivate func superDecoder () throws -> Swift.Decoder {
			return Decoder (parent: self.decoder, key: KBJSCodingKey.super);
		}
		
		private mutating func decodeNext () -> JSValue {
			defer { self.currentIndex += 1 }
			return self.value.atIndex (self.currentIndex);
		}
	}
}

/* fileprivate */ extension KBJSDecoder {
	fileprivate struct SingleValueDecodingContainer: Swift.SingleValueDecodingContainer {
		fileprivate var codingPath: [CodingKey] {
			return self.decoder.codingPath;
		}
		
		private var value: JSValue {
			return self.decoder.value;
		}
		
		private let decoder: Decoder;
		
		fileprivate init (_ decoder: Decoder) {
			self.decoder = decoder;
		}
		
		fileprivate func decodeNil () -> Bool {
			return self.value.isNull;
		}
		
		fileprivate func decode (_ type: Bool.Type) -> Bool {
			return self.value.toBool ();
		}
		
		fileprivate func decode (_ type: String.Type) -> String {
			return self.value.toString ();
		}
		
		fileprivate func decode (_ type: Double.Type) -> Double {
			return self.value.toDouble ();
		}
		
		fileprivate func decode (_ type: Int32.Type) -> Int32 {
			return self.value.toInt32 ();
		}
		
		fileprivate func decode (_ type: UInt32.Type) -> UInt32 {
			return self.value.toUInt32 ();
		}

		fileprivate func decode (_ type: Float.Type) -> Float {
			return Float (self.decode (Double.self));
		}
		
		fileprivate func decode (_ type: Int.Type) -> Int {
			return numericCast (self.decode (Int32.self));
		}
		
		fileprivate func decode (_ type: Int8.Type) -> Int8 {
			return numericCast (self.decode (Int32.self));
		}
		
		fileprivate func decode (_ type: Int16.Type) -> Int16 {
			return numericCast (self.decode (Int32.self));
		}
		
		fileprivate func decode (_ type: Int64.Type) -> Int64 {
			return numericCast (self.decode (Int32.self));
		}
		
		fileprivate func decode (_ type: UInt.Type) -> UInt {
			return numericCast (self.decode (UInt32.self));
		}
		
		fileprivate func decode (_ type: UInt8.Type) -> UInt8 {
			return numericCast (self.decode (UInt32.self));
		}
		
		fileprivate func decode (_ type: UInt16.Type) -> UInt16 {
			return numericCast (self.decode (UInt32.self));
		}
		
		fileprivate func decode (_ type: UInt64.Type) -> UInt64 {
			return numericCast (self.decode (UInt32.self));
		}
		
		fileprivate func decode <T> (_ type: T.Type) throws -> T where T: Decodable {
			if (type == Date.self) {
				return unsafeBitCast (self.value.toDate ()!, to: T.self);
			}
			return try type.init (from: self.decoder);
		}
	}
}

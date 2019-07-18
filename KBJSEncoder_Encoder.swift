//
//  KBJSEncoder_Encoder.swift
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

/* internal */ extension KBJSEncoder {
	internal final class Encoder {
		internal let context: JSContext;
		internal let keyEncodingStrategy: KeyEncodingStrategy;
		
		internal let codingPath: [CodingKey];
		internal let userInfo: [CodingUserInfoKey: Any];
		
		internal fileprivate (set) var result: JSValue {
			get {
				guard let result = self.resultStorage else {
					fatalError ("container <Key> (keyedBy type: Key.Type), unkeyedContainer () or singleValueContainer () was never called");
				}
				return result;
			}
			set {
				guard (self.resultStorage == nil) else {
					fatalError ("container <Key> (keyedBy type: Key.Type), unkeyedContainer () or singleValueContainer () was already called earlier");
				}
				self.resultStorage = newValue;
			}
		}
		
		private var resultStorage: JSValue?;
		
		internal convenience init (context: JSContext, keyEncodingStrategy: KeyEncodingStrategy, userInfo: [CodingUserInfoKey: Any]) {
			self.init (context: context, keyEncodingStrategy: keyEncodingStrategy, codingPath: [], userInfo: userInfo);
		}
		
		fileprivate convenience init (parent: Encoder, key: CodingKey) {
			self.init (context: parent.context, keyEncodingStrategy: parent.keyEncodingStrategy, codingPath: parent.codingPath + [key], userInfo: parent.userInfo);
		}

		private init (context: JSContext, keyEncodingStrategy: KeyEncodingStrategy, codingPath: [CodingKey], userInfo: [CodingUserInfoKey: Any]) {
			self.context = context;
			self.keyEncodingStrategy = keyEncodingStrategy;
			self.codingPath = codingPath;
			self.userInfo = userInfo;
		}
	}
}

extension KBJSEncoder.Encoder: Encoder {
	internal func container <Key> (keyedBy type: Key.Type) -> KeyedEncodingContainer <Key> where Key: CodingKey {
		if (self.resultStorage == nil) {
			self.result = JSValue (newObjectIn: self.context);
		}
		return KeyedEncodingContainer (KBJSEncoder.KeyedEncodingContainer (self));
	}
	
	internal func unkeyedContainer () -> UnkeyedEncodingContainer {
		if (self.resultStorage == nil) {
			self.result = JSValue (newArrayIn: self.context);
		}
		return KBJSEncoder.UnkeyedEncodingContainer (self);
	}
	
	internal func singleValueContainer () -> SingleValueEncodingContainer {
		return KBJSEncoder.SingleValueEncodingContainer (self);
	}
	
	fileprivate func encodedKey (_ codingKey: CodingKey) -> CodingKey {
		switch (self.keyEncodingStrategy) {
		case .useDefaultKeys:
			return codingKey;
		case .convertToSnakeCase:
			return KBJSCodingKey (convertingToSnakeCase: codingKey);
		case .custom (let block):
			return block (self.codingPath + [codingKey]);
		@unknown default:
			fatalError ("\(self.keyEncodingStrategy) is not supported");
		}
	}
}

/* fileprivate */ extension KBJSEncoder {
	fileprivate struct KeyedEncodingContainer <Key>: KeyedEncodingContainerProtocol where Key: CodingKey {
		fileprivate var codingPath: [CodingKey] {
			return self.encoder.codingPath;
		}
		
		private let encoder: Encoder;
		
		private var target: JSValue {
			return self.encoder.result;
		}
		
		private var context: JSContext {
			return self.encoder.context;
		}
		
		fileprivate init (_ encoder: Encoder) {
			self.encoder = encoder;
		}
		
		fileprivate func encodeNil (forKey key: Key) {
			self.encode (JSValue (nullIn: self.context), forKey: key);
		}
		
		fileprivate func encode (_ value: Bool, forKey key: Key) {
			self.encode (JSValue (bool: value, in: self.context), forKey: key);
		}
		
		fileprivate func encode (_ value: String, forKey key: Key) {
			self.encode (JSValue (object: value, in: self.context), forKey: key);
		}
		
		fileprivate func encode (_ value: Double, forKey key: Key) {
			self.encode (JSValue (double: value, in: self.context), forKey: key);
		}
		
		fileprivate func encode (_ value: Int32, forKey key: Key) {
			self.encode (JSValue (int32: value, in: self.context), forKey: key);
		}
		
		fileprivate func encode (_ value: UInt32, forKey key: Key) {
			self.encode (JSValue (uInt32: value, in: self.context), forKey: key);
		}

		fileprivate func encode (_ value: Float, forKey key: Key) {
			self.encode (Double (value), forKey: key);
		}
		
		fileprivate func encode (_ value: Int, forKey key: Key) {
			self.encode (Int32 (value), forKey: key);
		}
		
		fileprivate func encode (_ value: Int8, forKey key: Key) {
			self.encode (Int32 (value), forKey: key);
		}
		
		fileprivate func encode (_ value: Int16, forKey key: Key) {
			self.encode (Int32 (value), forKey: key);
		}

		fileprivate func encode (_ value: Int64, forKey key: Key) {
			self.encode (Int32 (value), forKey: key);
		}
		
		fileprivate func encode (_ value: UInt, forKey key: Key) {
			self.encode (UInt32 (value), forKey: key);
		}
		
		fileprivate func encode (_ value: UInt8, forKey key: Key) {
			self.encode (UInt32 (value), forKey: key);
		}
		
		fileprivate func encode (_ value: UInt16, forKey key: Key) {
			self.encode (UInt32 (value), forKey: key);
		}
		
		fileprivate func encode (_ value: UInt64, forKey key: Key) {
			self.encode (UInt32 (value), forKey: key);
		}
		
		fileprivate func encode <T> (_ value: T, forKey key: Key) throws where T: Encodable {
			switch (value) {
			case let date as Date:
				self.encode (JSValue (object: date, in: self.context), forKey: key);
			case let value:
				let encoder = Encoder (parent: self.encoder, key: key);
				try value.encode (to: encoder);
				self.encode (encoder.result, forKey: key);
			}
		}
		
		fileprivate mutating func nestedContainer <NestedKey> (keyedBy keyType: NestedKey.Type, forKey key: Key) -> Swift.KeyedEncodingContainer <NestedKey> where NestedKey: CodingKey {
			return Encoder (parent: self.encoder, key: key).container (keyedBy: keyType);
		}
		
		fileprivate mutating func nestedUnkeyedContainer (forKey key: Key) -> Swift.UnkeyedEncodingContainer {
			return Encoder (parent: self.encoder, key: key).unkeyedContainer ();
		}
		
		fileprivate mutating func superEncoder () -> Swift.Encoder {
			return Encoder (parent: self.encoder, key: KBJSCodingKey.super);
		}
		
		fileprivate mutating func superEncoder (forKey key: Key) -> Swift.Encoder {
			return Encoder (parent: self.encoder, key: key);
		}

		private func encode (_ jsValue: JSValue, forKey key: Key) {
			self.target.setValue (jsValue, forProperty: self.encoder.encodedKey (key).stringValue);
		}
	}
}

/* fileprivate */ extension KBJSEncoder {
	fileprivate struct UnkeyedEncodingContainer: Swift.UnkeyedEncodingContainer {
		fileprivate var codingPath: [CodingKey] {
			return self.encoder.codingPath;
		}
		
		fileprivate var count: Int {
			return Int (self.target.forProperty ("length").toInt32 ());
		}
		
		private var currentKey: CodingKey {
			return KBJSCodingKey (intValue: self.count);
		}
		
		private let encoder: Encoder;
		
		private var target: JSValue {
			return self.encoder.result;
		}
		
		private var context: JSContext {
			return self.encoder.context;
		}
		
		fileprivate init (_ encoder: Encoder) {
			self.encoder = encoder;
		}
		
		fileprivate func encodeNil () {
			self.encode (JSValue (nullIn: self.context));
		}
		
		fileprivate func encode (_ value: Bool) {
			self.encode (JSValue (bool: value, in: self.context));
		}
		
		fileprivate func encode (_ value: String) {
			self.encode (JSValue (object: value, in: self.context));
		}
		
		fileprivate func encode (_ value: Double) {
			self.encode (JSValue (double: value, in: self.context));
		}
		
		fileprivate func encode (_ value: Int32) {
			self.encode (JSValue (int32: value, in: self.context));
		}
		
		fileprivate func encode (_ value: UInt32) {
			self.encode (JSValue (uInt32: value, in: self.context));
		}
		
		fileprivate func encode (_ value: Float) {
			self.encode (Double (value));
		}
		
		fileprivate func encode (_ value: Int) {
			self.encode (Int32 (value));
		}
		
		fileprivate func encode (_ value: Int8) {
			self.encode (Int32 (value));
		}
		
		fileprivate func encode (_ value: Int16) {
			self.encode (Int32 (value));
		}
		
		fileprivate func encode (_ value: Int64) {
			self.encode (Int32 (value));
		}
		
		fileprivate func encode (_ value: UInt) {
			self.encode (UInt32 (value));
		}
		
		fileprivate func encode (_ value: UInt8) {
			self.encode (UInt32 (value));
		}
		
		fileprivate func encode (_ value: UInt16) {
			self.encode (UInt32 (value));
		}
		
		fileprivate func encode (_ value: UInt64) {
			self.encode (UInt32 (value));
		}
		
		fileprivate func encode <T> (_ value: T) throws where T: Encodable {
			switch (value) {
			case let date as Date:
				self.encode (JSValue (object: date, in: self.context));
			case let value:
				let encoder = Encoder (parent: self.encoder, key: self.currentKey);
				try value.encode (to: encoder);
				self.encode (encoder.result);
			}
		}
		
		fileprivate func nestedContainer <NestedKey> (keyedBy keyType: NestedKey.Type) -> Swift.KeyedEncodingContainer <NestedKey> where NestedKey: CodingKey {
			return Encoder (parent: self.encoder, key: self.currentKey).container (keyedBy: keyType);
		}
		
		fileprivate func nestedUnkeyedContainer () -> Swift.UnkeyedEncodingContainer {
			return Encoder (parent: self.encoder, key: self.currentKey).unkeyedContainer ();
		}
		
		fileprivate func superEncoder () -> Swift.Encoder {
			return Encoder (parent: self.encoder, key: KBJSCodingKey.super);
		}
		
		private func encode (_ jsValue: JSValue) {
			self.target.setValue (jsValue, at: self.count);
		}
	}
}

/* fileprivate */ extension KBJSEncoder {
	fileprivate struct SingleValueEncodingContainer: Swift.SingleValueEncodingContainer {
		fileprivate var codingPath: [CodingKey] {
			return self.encoder.codingPath;
		}
		
		private let encoder: Encoder;
		
		private var context: JSContext {
			return self.encoder.context;
		}
		
		fileprivate init (_ encoder: Encoder) {
			self.encoder = encoder;
		}
		
		fileprivate func encodeNil () {
			self.encode (JSValue (nullIn: self.context));
		}
		
		fileprivate func encode (_ value: Bool) {
			self.encode (JSValue (bool: value, in: self.context));
		}
		
		fileprivate func encode (_ value: String) {
			self.encode (JSValue (object: value, in: self.context));
		}
		
		fileprivate func encode (_ value: Double) {
			self.encode (JSValue (double: value, in: self.context));
		}
		
		fileprivate func encode (_ value: Int32) {
			self.encode (JSValue (int32: value, in: self.context));
		}
		
		fileprivate func encode (_ value: UInt32) {
			self.encode (JSValue (uInt32: value, in: self.context));
		}
		
		fileprivate func encode (_ value: Float) {
			self.encode (Double (value));
		}
		
		fileprivate func encode (_ value: Int) {
			self.encode (Int32 (value));
		}
		
		fileprivate func encode (_ value: Int8) {
			self.encode (Int32 (value));
		}
		
		fileprivate func encode (_ value: Int16) {
			self.encode (Int32 (value));
		}
		
		fileprivate func encode (_ value: Int64) {
			self.encode (Int32 (value));
		}
		
		fileprivate func encode (_ value: UInt) {
			self.encode (UInt32 (value));
		}
		
		fileprivate func encode (_ value: UInt8) {
			self.encode (UInt32 (value));
		}
		
		fileprivate func encode (_ value: UInt16) {
			self.encode (UInt32 (value));
		}
		
		fileprivate func encode (_ value: UInt64) {
			self.encode (UInt32 (value));
		}
		
		fileprivate func encode <T> (_ value: T) throws where T: Encodable {
			switch (value) {
			case let date as Date:
				self.encode (JSValue (object: date, in: self.context));
			case let value:
				try value.encode (to: self.encoder);
			}
		}
		
		private func encode (_ jsValue: JSValue) {
			self.encoder.result = jsValue;
		}
	}
}

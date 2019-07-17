//
//  KBJSValueCoding.swift
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

open class KBJSEncoder {
	public typealias KeyEncodingStrategy = JSONEncoder.KeyEncodingStrategy;
	
	open var keyEncodingStrategy = KeyEncodingStrategy.useDefaultKeys;
	open var userInfo = [CodingUserInfoKey: Any] ();

	open func encode <T> (_ value: T, in context: JSContext) throws -> JSValue where T: Encodable {
		let encoder = Encoder (context: context, keyEncodingStrategy: self.keyEncodingStrategy, userInfo: self.userInfo);
		try value.encode (to: encoder);
		return encoder.result;
	}
}

open class KBJSDecoder {
	public typealias KeyDecodingStrategy = JSONDecoder.KeyDecodingStrategy;
	
	open var keyDecodingStrategy = KeyDecodingStrategy.useDefaultKeys;
	open var userInfo = [CodingUserInfoKey: Any] ();

	open func decode <T> (_ type: T.Type = T.self, from value: JSValue) throws -> T where T: Decodable {
		let decoder = Decoder (value: value, keyDecodingStrategy: self.keyDecodingStrategy, userInfo: self.userInfo);
		return try type.init (from: decoder);
	}
}

public protocol LinkDetectorType {
	func detectLinks(string: String) -> [Range<String.Index>]
	var callback: ((_ matchedString: String) -> Void)? { get }
}

public struct RangeLinkDetector: LinkDetectorType {
	public var ranges:   [Range<String.Index>] = []
	public var callback: ((_ matchedString: String) -> Void)?
	
	public init(ranges: [Range<String.Index>], callback: ((_ matchedString: String) -> Void)? = nil) {
		self.ranges   = ranges
		self.callback = callback
	}
	
	public func detectLinks(string: String) -> [Range<String.Index>] {
		return ranges
	}
}

public struct SubstringLinkDetector: LinkDetectorType {
	public var substring: String
	public var callback:  ((_ matchedString: String) -> Void)?
	
	public init(substring: String, callback: ((_ matchedString: String) -> Void)? = nil) {
		self.substring = substring
		self.callback  = callback
	}
	
	public func detectLinks(string: String) -> [Range<String.Index>] {
		if let range = string.range(of: substring) {
			return [range]
		}
		
		return []
	}
}

public struct RegexLinkDetector: LinkDetectorType {
	public static func usernameLinkDetector(callback: ((_ matchedString: String) -> Void)? = nil) -> RegexLinkDetector {
		return RegexLinkDetector(pattern: "(?<!\\w)@([\\w\\_]+)?", options: .caseInsensitive, callback: callback)
	}
	
	public static func hashtagLinkDetector(callback: ((_ matchedString: String) -> Void)? = nil) -> RegexLinkDetector {
		return RegexLinkDetector(pattern: "(?<!\\w)#([\\w\\_]+)?", options: .caseInsensitive, callback: callback)
	}
	
	public static func urlLinkDetector(callback: ((_ matchedString: String) -> Void)? = nil) -> RegexLinkDetector {
		return RegexLinkDetector(regex: try! NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue), callback: callback)
	}
	
	public init(pattern: String, options: NSRegularExpression.Options, callback: ((_ matchedString: String) -> Void)? = nil) {
		self.init(regex: try! NSRegularExpression(pattern: pattern, options: options), callback: callback)
	}
	
	public init(regex: NSRegularExpression, callback: ((_ matchedString: String) -> Void)? = nil) {
		self.regex    = regex
		self.callback = callback
	}
	
	public var regex:    NSRegularExpression
	public var callback: ((_ matchedString: String) -> Void)?
	
	public func detectLinks(string: String) -> [Range<String.Index>] {
		let length = string.characters.count
		
		return regex.matches(in: string, options: .reportCompletion, range: NSRange(location: 0, length: length)).map { match in
			let range = match.range
			return string.characters.index(string.startIndex, offsetBy: range.location) ..< string.characters.index(string.startIndex, offsetBy: range.location + range.length)
		}
	}
}

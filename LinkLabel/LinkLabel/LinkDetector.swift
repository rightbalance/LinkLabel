public protocol LinkDetectorType {
	func detectLinks(string string: String) -> [Range<String.Index>]
	var callback: ((matchedString: String) -> Void)? { get }
}

public struct RangeLinkDetector: LinkDetectorType {
	public var ranges:   [Range<String.Index>] = []
	public var callback: ((matchedString: String) -> Void)?
	
	public init(ranges: [Range<String.Index>], callback: ((matchedString: String) -> Void)? = nil) {
		self.ranges   = ranges
		self.callback = callback
	}
	
	public func detectLinks(string string: String) -> [Range<String.Index>] {
		return ranges
	}
}

public struct SubstringLinkDetector: LinkDetectorType {
	public var substring: String
	public var callback:  ((matchedString: String) -> Void)?
	
	public init(substring: String, callback: ((matchedString: String) -> Void)? = nil) {
		self.substring = substring
		self.callback  = callback
	}
	
	public func detectLinks(string string: String) -> [Range<String.Index>] {
		if let range = string.rangeOfString(substring) {
			return [range]
		}
		
		return []
	}
}

public struct RegexLinkDetector: LinkDetectorType {
	public static func usernameLinkDetector(callback callback: ((matchedString: String) -> Void)? = nil) -> RegexLinkDetector {
		return RegexLinkDetector(pattern: "(?<!\\w)@([\\w\\_]+)?", options: .CaseInsensitive, callback: callback)
	}
	
	public static func hashtagLinkDetector(callback callback: ((matchedString: String) -> Void)? = nil) -> RegexLinkDetector {
		return RegexLinkDetector(pattern: "(?<!\\w)#([\\w\\_]+)?", options: .CaseInsensitive, callback: callback)
	}
	
	public static func urlLinkDetector(callback callback: ((matchedString: String) -> Void)? = nil) -> RegexLinkDetector {
		return RegexLinkDetector(regex: try! NSDataDetector(types: NSTextCheckingType.Link.rawValue), callback: callback)
	}
	
	public init(pattern: String, options: NSRegularExpressionOptions, callback: ((matchedString: String) -> Void)? = nil) {
		self.init(regex: try! NSRegularExpression(pattern: pattern, options: options), callback: callback)
	}
	
	public init(regex: NSRegularExpression, callback: ((matchedString: String) -> Void)? = nil) {
		self.regex    = regex
		self.callback = callback
	}
	
	public var regex:    NSRegularExpression
	public var callback: ((matchedString: String) -> Void)?
	
	public func detectLinks(string string: String) -> [Range<String.Index>] {
		let length = string.characters.count
		
		return regex.matchesInString(string, options: .ReportCompletion, range: NSRange(location: 0, length: length)).map { match in
			let range = match.range
			return string.startIndex.advancedBy(range.location) ..< string.startIndex.advancedBy(range.location + range.length)
		}
	}
}

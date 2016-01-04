//
// Originally based off of Michael Loistl's [ContextLabel](https://github.com/michaelloistl/ContextLabel.Swift).
//

import Foundation
import UIKit

public class LinkLabel: UILabel, NSLayoutManagerDelegate {
	// MARK: Initializing
	
	public override init(frame: CGRect) {
		super.init(frame: frame)
		textContainer.layoutManager = layoutManager
		userInteractionEnabled      = true
	}
	
	public required init(coder: NSCoder) {
		fatalError("NSCoding not supported.")
	}
	
	// MARK: Content
	
	public override var text: String! {
		didSet { updateLinks() }
	}
	
	// MARK: Callbacks
	
	public func whenLinkIsTapped(callback: (matchString: String) -> Void) {
		whenLinkIsTappedCallbacks.append(callback)
	}
	
	private var whenLinkIsTappedCallbacks: [(matchString: String) -> Void] = []
	
	// MARK: Appearance
	
	public override var textColor: UIColor! {
		didSet { highlightLinks() }
	}
	
	public var highlightedLinkColor: UIColor?
	
	internal var effectiveHighlightedLinkColor: UIColor {
		return highlightedLinkColor ?? tintColor.colorWithAlphaComponent(0.5)
	}
	
	// MARK: Links
	
	public var linkDetectors = [LinkDetectorType]() {
		didSet { updateLinks() }
	}
	
	private var highlightedLink: Link? {
		didSet {
			if highlightedLink != oldValue {
				highlightLinks()
			}
		}
	}
	
	private var links = [Link]()
	
	private func updateLinks() {
		links = linkDetectors.flatMap { detector in
			detector.detectLinks(string: self.text ?? "").map { range in
				Link(range: range, callback: detector.callback)
			}
		}
		
		highlightLinks()
	}
	
	private func highlightLinks() {
		let text             = self.text ?? ""
		let attributedString = NSMutableAttributedString(string: text, attributes: baseAttributes)
		
		for link in links {
			let range = NSRange(
				location: text.startIndex.distanceTo(link.range.startIndex),
				length:   link.range.startIndex.distanceTo(link.range.endIndex)
			)
			
			if range.location + range.length >= attributedString.length {
				continue
			}
			
			attributedString.setAttributes(highlightAttributes(highlighted: link == highlightedLink), range: range)
		}
		
		attributedText = attributedString
		textStorage.setAttributedString(attributedString)
	}
	
	private var baseAttributes: [String:AnyObject] {
		let mutableParagraphStyle       = NSMutableParagraphStyle()
		mutableParagraphStyle.alignment = textAlignment
		
		let attributes = [
			NSFontAttributeName:            font,
			NSForegroundColorAttributeName: textColor,
			NSParagraphStyleAttributeName:  mutableParagraphStyle
		]
		
		return attributes
	}
	
	private func highlightAttributes(highlighted highlighted: Bool) -> [String:AnyObject] {
		var attributes                             = baseAttributes
		attributes[NSForegroundColorAttributeName] = highlighted ? effectiveHighlightedLinkColor : tintColor
		return attributes
	}
	
	// MARK: Text storage
	
	public lazy var textContainer: NSTextContainer = {
		let _textContainer                  = NSTextContainer()
		_textContainer.lineFragmentPadding  = 0.0
		_textContainer.maximumNumberOfLines = self.numberOfLines
		_textContainer.lineBreakMode        = self.lineBreakMode
		_textContainer.size                 = CGSize(width: self.bounds.width, height: CGFloat.max)
		return _textContainer
	}()
	
	public lazy var layoutManager: NSLayoutManager = {
		let _layoutManager      = NSLayoutManager()
		_layoutManager.delegate = self
		_layoutManager.addTextContainer(self.textContainer)
		return _layoutManager
	}()
	
	public lazy var textStorage: NSTextStorage = {
		let _textStorage = NSTextStorage()
		_textStorage.addLayoutManager(self.layoutManager)
		return _textStorage
	}()
	
	private func updateTextContainerSize() {
		textContainer.size = CGSize(width: bounds.width, height: CGFloat.max)
	}
	
	// MARK: Events
	
	public override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
		highlightedLink = getLink(touches: touches)
		super.touchesBegan(touches, withEvent: event)
	}
	
	public override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?) {
		highlightedLink = getLink(touches: touches)
		super.touchesMoved(touches, withEvent: event)
	}
	
	public override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
		if let highlightedLink = highlightedLink {
			let matchString = text.substringWithRange(highlightedLink.range)
			
			for callback in whenLinkIsTappedCallbacks {
				callback(matchString: matchString)
			}
			
			highlightedLink.callback?(matchString: matchString)
		}
		
		highlightedLink = nil
		
		super.touchesEnded(touches, withEvent: event)
	}
	
	public override func touchesCancelled(touches: Set<UITouch>?, withEvent event: UIEvent?) {
		highlightedLink = nil
		super.touchesCancelled(touches, withEvent: event)
	}
	
	private func getLink(touches touches: Set<UITouch>?) -> Link? {
		if let touch = touches?.first {
			return getLink(location: touch.locationInView(self))
		}
		
		return nil
	}
	
	private func getLink(location location: CGPoint) -> Link? {
		var fractionOfDistance = CGFloat(0.0)
		let characterIndex     = layoutManager.characterIndexForPoint(location, inTextContainer: textContainer, fractionOfDistanceBetweenInsertionPoints: &fractionOfDistance)
		
		guard characterIndex <= textStorage.length else {
			return nil
		}
		
		for link in links {
			let rangeLocation = text.startIndex.distanceTo(link.range.startIndex)
			let rangeLength   = link.range.startIndex.distanceTo(link.range.endIndex)
			
			if rangeLocation <= characterIndex && (rangeLocation + rangeLength - 1) >= characterIndex {
				let glyphRange   = layoutManager.glyphRangeForCharacterRange(NSMakeRange(rangeLocation, rangeLength), actualCharacterRange: nil)
				let boundingRect = layoutManager.boundingRectForGlyphRange(glyphRange, inTextContainer: textContainer)
				
				if boundingRect.contains(location) {
					return link
				}
			}
		}
		
		return nil
	}
	
	// MARK: Layout
	
	public override var frame: CGRect {
		didSet { updateTextContainerSize() }
	}
	
	public override var bounds: CGRect {
		didSet { updateTextContainerSize() }
	}
	
	public override var numberOfLines: Int {
		didSet {
			textContainer.maximumNumberOfLines = numberOfLines
		}
	}
	
	public override var lineBreakMode: NSLineBreakMode {
		didSet {
			textContainer.lineBreakMode = lineBreakMode
		}
	}
	
	public override func layoutSubviews() {
		super.layoutSubviews()
		updateTextContainerSize()
	}
}

private struct Link: Equatable {
	var range:    Range<String.Index>
	var callback: ((matchString: String) -> Void)?
}

private func ==(link1: Link, link2: Link) -> Bool {
	return link1.range == link2.range
}

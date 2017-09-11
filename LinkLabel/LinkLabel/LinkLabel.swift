//
// Originally based off of Michael Loistl's [ContextLabel](https://github.com/michaelloistl/ContextLabel.Swift).
//

import Foundation
import UIKit

open class LinkLabel: UILabel, NSLayoutManagerDelegate {
	// MARK: Initializing
	
	public override init(frame: CGRect) {
		super.init(frame: frame)
		initialize()
	}
	
	public required init?(coder: NSCoder) {
		super.init(coder: coder)
		initialize()
	}
	
	fileprivate func initialize() {
		textContainer.layoutManager = layoutManager
		isUserInteractionEnabled      = true
	}
	
	// MARK: Content
	
	open override var text: String! {
		didSet { updateLinks() }
	}
	
	// MARK: Callbacks
	
	open func whenLinkIsTapped(_ callback: @escaping (_ matchString: String) -> Void) {
		whenLinkIsTappedCallbacks.append(callback)
	}
	
	fileprivate var whenLinkIsTappedCallbacks: [(_ matchString: String) -> Void] = []
	
	// MARK: Appearance
	
	open override var textColor: UIColor! {
		didSet { highlightLinks() }
	}
	
	open var highlightedLinkColor: UIColor?
	
	internal var effectiveHighlightedLinkColor: UIColor {
		return highlightedLinkColor ?? tintColor.withAlphaComponent(0.5)
	}
	
	// MARK: Links
	
	open var linkDetectors = [LinkDetectorType]() {
		didSet { updateLinks() }
	}
	
	fileprivate var highlightedLink: Link? {
		didSet {
			if highlightedLink != oldValue {
				highlightLinks()
			}
		}
	}
	
	fileprivate var links = [Link]()
	
	fileprivate func updateLinks() {
		links = linkDetectors.flatMap { detector in
			detector.detectLinks(string: self.text ?? "").map { range in
				Link(range: range, callback: detector.callback)
			}
		}
		
		highlightLinks()
	}
	
	fileprivate func highlightLinks() {
		let text             = self.text ?? ""
		let attributedString = NSMutableAttributedString(string: text, attributes: baseAttributes)
		
		for link in links {
			let range = NSRange(
				location: text.characters.distance(from: text.startIndex, to: link.range.lowerBound),
				length:   text.characters.distance(from: link.range.lowerBound, to: link.range.upperBound)
			)
			
			if range.location + range.length >= attributedString.length {
				continue
			}
			
			attributedString.setAttributes(highlightAttributes(highlighted: link == highlightedLink), range: range)
		}
		
		attributedText = attributedString
		textStorage.setAttributedString(attributedString)
	}
	
	fileprivate var baseAttributes: [String:AnyObject] {
		let mutableParagraphStyle       = NSMutableParagraphStyle()
		mutableParagraphStyle.alignment = textAlignment
		
		let attributes = [
			NSFontAttributeName:            font,
			NSForegroundColorAttributeName: textColor,
			NSParagraphStyleAttributeName:  mutableParagraphStyle
		] as [String : Any]
		
		return attributes as [String : AnyObject]
	}
	
	fileprivate func highlightAttributes(highlighted: Bool) -> [String:AnyObject] {
		var attributes                             = baseAttributes
		attributes[NSForegroundColorAttributeName] = highlighted ? effectiveHighlightedLinkColor : tintColor
		return attributes
	}
	
	// MARK: Text storage
	
	open lazy var textContainer: NSTextContainer = {
		let _textContainer                  = NSTextContainer()
		_textContainer.lineFragmentPadding  = 0.0
		_textContainer.maximumNumberOfLines = self.numberOfLines
		_textContainer.lineBreakMode        = self.lineBreakMode
		_textContainer.size                 = CGSize(width: self.bounds.width, height: CGFloat.greatestFiniteMagnitude)
		return _textContainer
	}()
	
	open lazy var layoutManager: NSLayoutManager = {
		let _layoutManager      = NSLayoutManager()
		_layoutManager.delegate = self
		_layoutManager.addTextContainer(self.textContainer)
		return _layoutManager
	}()
	
	open lazy var textStorage: NSTextStorage = {
		let _textStorage = NSTextStorage()
		_textStorage.addLayoutManager(self.layoutManager)
		return _textStorage
	}()
	
	fileprivate func updateTextContainerSize() {
		textContainer.size = CGSize(width: bounds.width, height: CGFloat.greatestFiniteMagnitude)
	}
	
	// MARK: Events
	
	open override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
		highlightedLink = getLink(touches: touches)
		super.touchesBegan(touches, with: event)
	}
	
	open override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
		highlightedLink = getLink(touches: touches)
		super.touchesMoved(touches, with: event)
	}
	
	open override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
		if let highlightedLink = highlightedLink {
			let matchString = text.substring(with: highlightedLink.range)
			
			for callback in whenLinkIsTappedCallbacks {
				callback(matchString)
			}
			
			highlightedLink.callback?(matchString)
		}
		
		highlightedLink = nil
		
		super.touchesEnded(touches, with: event)
	}
	
	open override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
		highlightedLink = nil
		super.touchesCancelled(touches, with: event)
	}
	
	fileprivate func getLink(touches: Set<UITouch>?) -> Link? {
		if let touch = touches?.first {
			return getLink(location: touch.location(in: self))
		}
		
		return nil
	}
	
	fileprivate func getLink(location: CGPoint) -> Link? {
		var fractionOfDistance = CGFloat(0.0)
		let characterIndex     = layoutManager.characterIndex(for: location, in: textContainer, fractionOfDistanceBetweenInsertionPoints: &fractionOfDistance)
		
		guard characterIndex <= textStorage.length else {
			return nil
		}
		
		for link in links {
			let rangeLocation = text.distance(from: text.startIndex, to: link.range.lowerBound)
			let rangeLength   = text.distance(from: link.range.lowerBound, to: link.range.upperBound)
			
			if rangeLocation <= characterIndex && (rangeLocation + rangeLength - 1) >= characterIndex {
				let glyphRange   = layoutManager.glyphRange(forCharacterRange: NSMakeRange(rangeLocation, rangeLength), actualCharacterRange: nil)
				let boundingRect = layoutManager.boundingRect(forGlyphRange: glyphRange, in: textContainer)
				
				if boundingRect.contains(location) {
					return link
				}
			}
		}
		
		return nil
	}
	
	// MARK: Layout
	
	open override var frame: CGRect {
		didSet { updateTextContainerSize() }
	}
	
	open override var bounds: CGRect {
		didSet { updateTextContainerSize() }
	}
	
	open override var numberOfLines: Int {
		didSet {
			textContainer.maximumNumberOfLines = numberOfLines
		}
	}
	
	open override var lineBreakMode: NSLineBreakMode {
		didSet {
			textContainer.lineBreakMode = lineBreakMode
		}
	}
	
	open override func layoutSubviews() {
		super.layoutSubviews()
		updateTextContainerSize()
	}
}

private struct Link: Equatable {
	var range:    Range<String.Index>
	var callback: ((_ matchString: String) -> Void)?
}

private func ==(link1: Link, link2: Link) -> Bool {
	return link1.range == link2.range
}

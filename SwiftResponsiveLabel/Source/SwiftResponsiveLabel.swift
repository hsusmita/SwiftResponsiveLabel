//
//  SwiftResponsiveLabel.swift
//  SwiftResponsiveLabel
//
//  Created by Susmita Horrow on 01/03/16.
//  Copyright © 2016 hsusmita.com. All rights reserved.
//

import Foundation
import UIKit

@IBDesignable
open class SwiftResponsiveLabel: UILabel {
	var textKitStack = TextKitStack()
	var touchHandler: TouchHandler?
	var patternHighlighter = PatternHighlighter()

	override init(frame: CGRect) {
		super.init(frame: frame)
		self.attributedTruncationToken = NSAttributedString(string: truncationToken, attributes: self.attributesFromProperties)
	}

	required public init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
		self.attributedTruncationToken = NSAttributedString(string: truncationToken, attributes: self.attributesFromProperties)
	}

	override open var frame: CGRect {
		didSet {
			self.textKitStack.resizeTextContainer(frame.size)
		}
	}

	override open var bounds: CGRect {
		didSet {
			self.textKitStack.resizeTextContainer(bounds.size)
		}
	}

	override open var preferredMaxLayoutWidth: CGFloat {
		didSet {
			self.textKitStack.resizeTextContainer(frame.size)
		}
	}

	override open var text: String? {
		didSet {
			self.textKitStack.updateTextStorage(self.attributedTextToDisplay)
			setNeedsDisplay()
		}
	}

	override open var attributedText: NSAttributedString? {
		didSet {
			self.textKitStack.updateTextStorage(self.attributedTextToDisplay)
			setNeedsDisplay()
		}
	}
	
	override open var numberOfLines: Int {
		didSet {
			let rect = self.textKitStack.rectFittingTextForContainerSize(self.bounds.size, numberOfLines: self.numberOfLines, font: self.font)
			self.textKitStack.resizeTextContainer(rect.size)
		}
	}
	
	
	/** This boolean determines if custom truncation token should be added
	*/
	
	@IBInspectable open var customTruncationEnabled: Bool = true {
		didSet {
			self.textKitStack.updateTextStorage(self.attributedTextToDisplay)
			self.setNeedsDisplay()
		}
	}
	
	/** Custom truncation token string. The default value is "..."
	
	If customTruncationEnabled is true, then this text will be seen while truncation in place of default ellipse
	*/
	@IBInspectable open var truncationToken: String = "..." {
		didSet {
			self.attributedTruncationToken = NSAttributedString(string: truncationToken, attributes: self.attributesFromProperties)
		}
	}
	
	/** Custom truncation token atributed string. The default value is "..."
	
	If customTruncationEnabled is true, then this text will be seen while truncation in place of default ellipse
	*/
	@IBInspectable open var attributedTruncationToken: NSAttributedString? {
		didSet {
			if let _ = self.attributedTruncationToken {
				self.textKitStack.updateTextStorage(self.attributedTextToDisplay)
				self.setNeedsDisplay()
			}
		}
	}
	
	@IBInspectable open var truncationIndicatorImage: UIImage? {
		didSet {
			if let image = truncationIndicatorImage {
				self.attributedTruncationToken = self.attributedStringWithImage(image, withSize: CGSize(width: 20.0, height: 20.0), andAction: nil)
			}
		}
	}
	
	fileprivate var attributesFromProperties: AttributesDictionary {
		let shadow = NSShadow()
		if let shadowColor = self.shadowColor {
			shadow.shadowColor = shadowColor
			shadow.shadowOffset = self.shadowOffset
		} else {
			shadow.shadowOffset = CGSize(width: 0, height: -1)
			shadow.shadowColor = nil
		}
		
		var color = self.textColor
		if !self.isEnabled {
			color = UIColor.lightGray
		} else if let _ = self.highlightedTextColor, self.isHighlighted == true {
			color = self.highlightedTextColor;
		}
		
		let paragraph = NSMutableParagraphStyle()
		paragraph.alignment = self.textAlignment
		
        return [NSAttributedString.Key.font : self.font ?? UIFont.systemFont(ofSize: 10),
		        NSAttributedString.Key.foregroundColor : color!,
		        NSAttributedString.Key.shadow: shadow,
		        NSAttributedString.Key.paragraphStyle: paragraph]
	}


	open var attributedTextToDisplay: NSAttributedString {
		var finalAttributedString = NSAttributedString()
		if let attributedText = attributedText?.wordWrappedAttributedString() {
			finalAttributedString = NSAttributedString(attributedString: attributedText)
		} else {
			finalAttributedString = NSAttributedString(string: text ?? "", attributes: self.attributesFromProperties)
		}
		return finalAttributedString
	}
	
	// MARK: Override methods from Superclass
	
	override open func awakeFromNib() {
		super.awakeFromNib()
		self.initialTextConfiguration()
		if isUserInteractionEnabled {
			self.touchHandler = TouchHandler(responsiveLabel: self)
		}
	}
	
	override open func drawText(in rect: CGRect) {
		// Add truncation token if necessary
		var finalString: NSAttributedString = textKitStack.currentAttributedText
		if let _ = self.attributedTruncationToken, self.shouldTruncate() && self.customTruncationEnabled {
			if let string = self.stringWithTruncationToken(), self.truncationTokenAppended() == false {
				finalString = string
			}
		}
		// Apply pattern
		self.patternHighlighter.updateAttributedText(finalString)
		if let highlightedString = self.patternHighlighter.patternHighlightedText {
			finalString = highlightedString
		}
		textKitStack.updateTextStorage(finalString)
		self.textKitStack.drawText(self.textOffSet(rect))
	}

	override open func textRect(forBounds bounds: CGRect, limitedToNumberOfLines numberOfLines: Int) -> CGRect {
		let rect = self.textKitStack.rectFittingTextForContainerSize(bounds.size, numberOfLines: self.numberOfLines, font: self.font)
		self.textKitStack.resizeTextContainer(rect.size)
		return rect
	}

	// MARK: Public methods
	
	/** Method to set an image as truncation indicator
	- parameters:
		- image: UIImage
		- size: CGSize : The height of image size should be approximately equal to or less than the font height. Otherwise the image will not be rendered properly
		- action: PatternTapResponder action to be performed on tap on the image
	*/
	func setTruncationIndicatorImage(_ image: UIImage, withSize size: CGSize, andAction action: PatternTapResponder?) {
		let attributedString = self.attributedStringWithImage(image, withSize: size, andAction: action)
		self.attributedTruncationToken = attributedString
	}
	
	/** Add attributes to all the occurences of pattern dictated by pattern descriptor
	- parameters:
		- patternDescriptor: The descriptor for the pattern to be detected
	*/
	open func enablePatternDetection(patternDescriptor: PatternDescriptor) {
		self.patternHighlighter.enablePatternDetection(patternDescriptor)
		self.textKitStack.updateTextStorage(self.attributedTextToDisplay)
		self.setNeedsDisplay()
	}
	
	/** Add given attributes to urls
	- parameters:
		- attributes: AttributesDictionary
	*/
	open func enableURLDetection(attributes: AttributesDictionary) {
		do {
			let regex = try NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
			let descriptor = PatternDescriptor(regularExpression: regex, searchType: .all, patternAttributes: attributes)
			self.enablePatternDetection(patternDescriptor: descriptor)
		} catch let error as NSError {
			print("NSDataDetector Error: \(error.debugDescription)")
		}
	}
	
	/** Add given attributes to user handles
	- parameters:
		- attributes: AttributesDictionary
	*/
	open func enableUserHandleDetection(attributes: AttributesDictionary) {
		self.highlightPattern(PatternHighlighter.RegexStringForUserHandle, attributes: attributes)
	}
	
	/** Add given attributes to hastags
	- parameters:
		- attributes: AttributesDictionary
	*/
	open func enableHashTagDetection(attributes: AttributesDictionary) {
		self.highlightPattern(PatternHighlighter.RegexStringForHashTag, attributes: attributes)
	}
	
	/** Add given attributes to the occurrences of given string
	- parameters:
		- string: String
		- attributes: AttributesDictionary
	*/
	open func enableStringDetection(_ string: String, attributes: AttributesDictionary) {
		let pattern = String(format: PatternHighlighter.RegexFormatForSearchWord, string)
		self.highlightPattern(pattern, attributes: attributes)
	}
	
	/** Add given attributes to the occurrences of all the strings of given array
	- parameters:
		- stringsArray: [String]
		- attributes: AttributesDictionary
	*/
	open func enableDetectionForStrings(_ stringsArray: [String], attributes: AttributesDictionary) {
		for string in stringsArray {
			enableStringDetection(string, attributes: attributes)
		}
	}
	
	/** Removes previously applied attributes from all the occurences of pattern dictated by pattern descriptor
	- parameters:
		- patternDescriptor: The descriptor for the pattern to be detected
	*/
	open func disablePatternDetection(_ patternDescriptor: PatternDescriptor) {
		self.patternHighlighter.disablePatternDetection(patternDescriptor)
		self.textKitStack.updateTextStorage(self.attributedTextToDisplay)
		self.setNeedsLayout()
	}
	
	/** remove attributes form url
	*/
	open func disableURLDetection() {
		let key = String(NSTextCheckingResult.CheckingType.link.rawValue)
		self.unhighlightPattern(key)
	}
	
	/** remove attributes form user handle
	*/
	open func disableUserHandleDetection() {
		self.unhighlightPattern(PatternHighlighter.RegexStringForUserHandle)
	}
	
	/** remove attributes form hash tags
	*/
	open func disableHashTagDetection() {
		self.unhighlightPattern(PatternHighlighter.RegexStringForHashTag)
	}
	
	/** Remove attributes from all the occurrences of given string
	- parameters:
		- string: String
	*/
	open func disableStringDetection(_ string: String) {
		let pattern = String(format: PatternHighlighter.RegexFormatForSearchWord, string)
		self.unhighlightPattern(pattern)
	}
	
	/** Remove attributes from all the occurrences of all the strings in the array
	- parameters:
		- string: [String]
	*/
	open func disableDetectionForStrings(_ stringsArray:[String]) {
		for string in stringsArray {
			disableStringDetection(string)
		}
	}

	// MARK: Private Helpers
	
	fileprivate func highlightPattern(_ pattern: String, attributes: AttributesDictionary) {
		patternHighlighter.highlightPattern(pattern, dictionary: attributes)
		self.textKitStack.updateTextStorage(self.attributedTextToDisplay)
		self.setNeedsDisplay()
	}
	
	fileprivate func unhighlightPattern(_ pattern: String) {
		self.patternHighlighter.unhighlightPattern(regexString: pattern)
		self.textKitStack.updateTextStorage(self.attributedTextToDisplay)
		self.setNeedsDisplay()
	}

	internal func shouldTruncate() -> Bool {
		guard numberOfLines > 0 else {
			return false
		}
		let range = self.textKitStack.rangeForTokenInsertion(self.attributedTextToDisplay)
		return (range.location + range.length <= self.attributedTextToDisplay.length)
	}

	fileprivate func textOffSet(_ rect: CGRect) -> CGPoint {
		var textOffset = CGPoint.zero
		let textBounds = self.textKitStack.boundingRectForCompleteText()
		let paddingHeight = (rect.size.height - textBounds.size.height) / 2.0
		if textBounds.origin.x > 0 {
			textOffset.x = 0 - textBounds.origin.x
		}
		if paddingHeight > 0 {
			textOffset.y = paddingHeight
		} else {
			textOffset.y = 0
		}
		return textOffset
	}

	fileprivate func initialTextConfiguration() {
		var currentText = NSAttributedString()
		if let attributedText = self.attributedText {
			currentText = attributedText.wordWrappedAttributedString()
		} else if let text = self.text {
			currentText = NSAttributedString(string: text, attributes: self.attributesFromProperties)
		}
		self.textKitStack.updateTextStorage(currentText)
	}
}

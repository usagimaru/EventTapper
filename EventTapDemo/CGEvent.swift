//
//  CGEvent.swift
//
//  Created by usagimaru on 2023/03/05.
//

import Foundation
import CoreGraphics

extension CGEvent {
	
	// https://developer.apple.com/documentation/coregraphics/cgeventfield
	// https://www.hammerspoon.org/docs/hs.eventtap.event.html
	
	var sourcePID: Int64 {
		getIntegerValueField(.eventSourceUnixProcessID)
	}
	var targetPID: Int64 {
		getIntegerValueField(.eventTargetUnixProcessID)
	}
	
	var keyCode: Int64 {
		getIntegerValueField(.keyboardEventKeycode)
	}
	
	var keyCharacter: String? {
		var uniChar = UniChar()
		var length = 0
		keyboardGetUnicodeString(maxStringLength: 1, actualStringLength: &length, unicodeString: &uniChar)
		
		if let uniScalar = UnicodeScalar(uniChar) {
			return String(Character(uniScalar))
		}
		return nil
	}
	
	var isAutorepeatKeyEvent: Bool {
		getIntegerValueField(.keyboardEventAutorepeat) != 0
	}
	
	var scrollWhellDeltaY: Int64 {
		getIntegerValueField(.scrollWheelEventDeltaAxis1)
	}
	
	var scrollWhellDeltaX: Int64 {
		getIntegerValueField(.scrollWheelEventDeltaAxis2)
	}
	
	var mouseButtonNumber: Int64 {
		getIntegerValueField(.mouseEventButtonNumber)
	}
	
	var mouseEventNumber: Int64 {
		getIntegerValueField(.mouseEventNumber)
	}
	
	var isSingleClick: Bool {
		getIntegerValueField(.mouseEventClickState) == 1
	}
	
	var isDoubleClick: Bool {
		getIntegerValueField(.mouseEventClickState) == 2
	}
	
	var isTripleClick: Bool {
		getIntegerValueField(.mouseEventClickState) == 3
	}
	
	var windowUnderMouse: CGWindowID {
		CGWindowID(getIntegerValueField(.mouseEventWindowUnderMousePointer))
	}
	
	var windowUnderMouseThatCanHandle: CGWindowID {
		CGWindowID(getIntegerValueField(.mouseEventWindowUnderMousePointerThatCanHandleThisEvent))
	}
	
}

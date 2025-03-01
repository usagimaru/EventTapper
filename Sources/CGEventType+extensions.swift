//
//  CGKeyCode.swift
//
//  Created by usagimaru on 2023/12/26.
//

import CoreGraphics

// References:
// https://www.reddit.com/r/swift/comments/dc5mdu/converting_between_cgeventtype_and_cgeventmask/
// https://stackoverflow.com/questions/55616797/how-can-i-pass-an-anonymous-method-into-a-closure-that-captures-context-in-swift
// https://github.com/pnoqable/PinchBar/blob/main/PinchBar/EventTap.swift#L21

public struct CGEventTypeSet: OptionSet {
	
	public let rawValue: CGEventMask
	
	public init(rawValue: CGEventMask) {
		self.rawValue = rawValue
	}
	
	public init(_ eventType: CGEventType) {
		self.rawValue = (1 << eventType.rawValue)
	}
	
	public var eventMask: CGEventMask {
		return rawValue
	}
	
}

public extension [CGEventType] {
	
	var eventMask: CGEventMask {
		self.reduce(CGEventMask(0), { $0 | (1 << $1.rawValue) })
	}
	
}

public extension CGEventMask {
	
	static let trackpadEvents = 1 << 29
	
}

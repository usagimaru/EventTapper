//
//  EventWatcher.swift
//
//  Created by usagimaru on 2023.02.27.
//  Copyright © 2023 usagimaru.
//

#if os(macOS)
import Cocoa

@objc public protocol EventTapperDelegate: AnyObject {
	
	@objc optional func eventTapperDidCatchFlagsChanged(event: NSEvent)
	@objc optional func eventTapperDidCatchKeyEvent(event: NSEvent, isDown: Bool)
	
	@objc optional func eventTapperDidCatchLeftMouseEvent(event: NSEvent, isDown: Bool)
	@objc optional func eventTapperDidCatchLeftMouseDraggedEvent(event: NSEvent)
	@objc optional func eventTapperDidCatchRightMouseEvent(event: NSEvent, isDown: Bool)
	@objc optional func eventTapperDidCatchRightMouseDraggedEvent(event: NSEvent)
	@objc optional func eventTapperDidCatchMouseMoved(event: NSEvent)
	
}

open class EventTapper: NSObject {
	
	public static let shared = EventTapper()
	public weak var delegate: EventTapperDelegate?
	
	public var eventTapHandler: ((_ event: CGEvent) -> Void)?
	
	private var tapWrappers = [[CGEventType] : EventTapWrapper]()
	
	open func tapEvents(for eventTypes: [CGEventType],
						location: CGEventTapLocation = .cghidEventTap,
						placement: CGEventTapPlacement = .headInsertEventTap,
						tapOption: CGEventTapOptions = .defaultTap,
						evaluationHandler: @escaping (_ event: CGEvent) -> Bool) {
		self.tapWrappers[eventTypes]?.removeFromRunLoop()
		let tapWrapper = EventTapWrapper(location: .cghidEventTap,
										 placement: .headInsertEventTap,
										 tapOption: .defaultTap,
										 eventTypes: eventTypes)
		{ eventTapWrapper, event in
			evaluationHandler(event)
			
		} handler: { eventTapProxy, event in
			guard let nsevent = NSEvent(cgEvent: event)
			else { return }
			
			self.eventTapHandler?(event)
			
			if event.type == .flagsChanged {
				self.delegate?.eventTapperDidCatchFlagsChanged?(event: nsevent)
			}
			if event.type == .keyDown {
				self.delegate?.eventTapperDidCatchKeyEvent?(event: nsevent, isDown: true)
			}
			if event.type == .keyUp {
				self.delegate?.eventTapperDidCatchKeyEvent?(event: nsevent, isDown: false)
			}
			if event.type == .leftMouseDown {
				self.delegate?.eventTapperDidCatchLeftMouseEvent?(event: nsevent, isDown: true)
			}
			if event.type == .leftMouseUp {
				self.delegate?.eventTapperDidCatchLeftMouseEvent?(event: nsevent, isDown: false)
			}
			if event.type == .leftMouseDragged {
				self.delegate?.eventTapperDidCatchLeftMouseDraggedEvent?(event: nsevent)
			}
			if event.type == .rightMouseDown {
				self.delegate?.eventTapperDidCatchRightMouseEvent?(event: nsevent, isDown: true)
			}
			if event.type == .rightMouseUp {
				self.delegate?.eventTapperDidCatchRightMouseEvent?(event: nsevent, isDown: false)
			}
			if event.type == .rightMouseDragged {
				self.delegate?.eventTapperDidCatchRightMouseDraggedEvent?(event: nsevent)
			}
			if event.type == .mouseMoved {
				self.delegate?.eventTapperDidCatchMouseMoved?(event: nsevent)
			}
		}
		
		if let tapWrapper {
			self.tapWrappers[eventTypes] = tapWrapper
			tapWrapper.addToRunLoop()
		}
	}
	
}


// MARK: -

public extension EventTapper {
	
	/// Simulate key event
	public static func postKeyEvent(virtualKey: CGKeyCode,
							 isKeyDown: Bool,
							 settings: ((_ event: CGEvent) -> (Void))? = nil,
							 eventSourceStateID: CGEventSourceStateID = .combinedSessionState,
							 tapLocation: CGEventTapLocation = .cghidEventTap)
	{
		let source = CGEventSource(stateID: eventSourceStateID)
		if let event = CGEvent(keyboardEventSource: source, virtualKey: virtualKey, keyDown: isKeyDown) {
			settings?(event)
			event.post(tap: tapLocation)
		}
	}
	
	/// Simulate key down event
	public static func postKeyDown(key: CGKeyCode, flags: CGEventFlags = .maskNonCoalesced, keyDown: Bool = true) {
		postKeyEvent(virtualKey: key, isKeyDown: keyDown) { event in
			event.flags = flags // To override the modifier key being pressed by the user. (Do not insert new flags)
		}
	}
	
	/// Simulate mouse button event
	public static func postMouseButtonEvent(mouseType: CGEventType,
									 mouseButton: CGMouseButton,
									 position: CGPoint? = nil,
									 settings: ((_ event: CGEvent) -> (Void))? = nil,
									 eventSourceStateID: CGEventSourceStateID = .combinedSessionState,
									 tapLocation: CGEventTapLocation = .cghidEventTap)
	{
		let mousePosition = position ?? CGEvent(source: nil)?.location ?? .zero
		let source = CGEventSource(stateID: eventSourceStateID)
		if let event = CGEvent(mouseEventSource: source, mouseType: mouseType, mouseCursorPosition: mousePosition, mouseButton: mouseButton) {
			settings?(event)
			event.post(tap: tapLocation)
		}
	}
	
	/// Simulate primary mouse button click
	public static func postPrimaryMouseClick() {
		postMouseButtonEvent(mouseType: .leftMouseDown, mouseButton: .left)
		postMouseButtonEvent(mouseType: .leftMouseUp, mouseButton: .left)
	}
	
	/// Simulate secondary mouse button click
	public static func postSecondaryMouseClick() {
		postMouseButtonEvent(mouseType: .rightMouseDown, mouseButton: .right)
		postMouseButtonEvent(mouseType: .rightMouseUp, mouseButton: .right)
	}
	
}
#endif

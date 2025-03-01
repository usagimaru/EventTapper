//
//  EventWatcher.swift
//
//  Created by usagimaru on 2023.02.27.
//  Copyright © 2023 usagimaru.
//

#if os(macOS)
import Cocoa

@objc public protocol EventTapperDelegate: AnyObject {
	
	@objc optional func eventTapper(_ eventTapper: EventTapper, didCatchFlagsChanged event: NSEvent, tapIdentifier: EventTapWrapper.EventTapID)
	@objc optional func eventTapper(_ eventTapper: EventTapper, didCatchKeyEvent event: NSEvent, isDown: Bool, tapIdentifier: EventTapWrapper.EventTapID)
	
	@objc optional func eventTapper(_ eventTapper: EventTapper, didCatchLeftMouseClick event: NSEvent, isDown: Bool, tapIdentifier: EventTapWrapper.EventTapID)
	@objc optional func eventTapper(_ eventTapper: EventTapper, didCatchLeftMouseDragging event: NSEvent, tapIdentifier: EventTapWrapper.EventTapID)
	@objc optional func eventTapper(_ eventTapper: EventTapper, didCatchRightMouseClick event: NSEvent, isDown: Bool, tapIdentifier: EventTapWrapper.EventTapID)
	@objc optional func eventTapper(_ eventTapper: EventTapper, didCatchRightMouseDragging event: NSEvent, tapIdentifier: EventTapWrapper.EventTapID)
	
	@objc optional func eventTapper(_ eventTapper: EventTapper, didCatchMouseMoving event: NSEvent, tapIdentifier: EventTapWrapper.EventTapID)
	@objc optional func eventTapper(_ eventTapper: EventTapper, didCatchAnyEvent event: NSEvent, tapIdentifier: EventTapWrapper.EventTapID)
	
}

/// A high-level wrapper class for EventTapWrapper
open class EventTapper: NSObject {
	
	public weak var delegate: EventTapperDelegate?
	public private(set) var tapWrapper: EventTapWrapper? {
		willSet {
			tapWrapper?.disableTap()
		}
		didSet {
			tapWrapper?.enableTap()
		}
	}
	
	@discardableResult
	open func tap(for eventMask: CGEventMask,
				  location: CGEventTapLocation = .cghidEventTap,
				  placement: CGEventTapPlacement = .headInsertEventTap,
				  tapOptions: CGEventTapOptions = .defaultTap,
				  setup: ((_ tapWrapper: EventTapWrapper) -> Void)? = nil,
				  evaluationHandler: @escaping (_ event: CGEvent, _ evaluationFunction: EventTapWrapper.EvaluationFunction) -> Bool) -> EventTapWrapper.EventTapID? {
		// CGEventTapLocation note:
		// https://www.monkeybreadsoftware.net/class-cgeventtapmbs.shtml
		
		let tapWrapper = EventTapWrapper(location: location,
										 placement: placement,
										 tapOptions: tapOptions,
										 eventMask: eventMask)
		{ eventTapWrapper, event, evaluationFunction in
			evaluationHandler(event, evaluationFunction)
			
		} eventHandler: { eventTapWrapper, event in
			guard let nsevent = NSEvent(cgEvent: event)
			else { return }
			
			let tapIdentifier = eventTapWrapper.identifier
			
			switch event.type {
				case .flagsChanged:
					self.delegate?.eventTapper?(self, didCatchFlagsChanged: nsevent, tapIdentifier: tapIdentifier)
					
				case .keyDown:
					self.delegate?.eventTapper?(self, didCatchKeyEvent: nsevent, isDown: true, tapIdentifier: tapIdentifier)
					
				case .keyUp:
					self.delegate?.eventTapper?(self, didCatchKeyEvent: nsevent, isDown: false, tapIdentifier: tapIdentifier)
					
				case .leftMouseDown:
					self.delegate?.eventTapper?(self, didCatchLeftMouseClick: nsevent, isDown: true, tapIdentifier: tapIdentifier)
					
				case .leftMouseUp:
					self.delegate?.eventTapper?(self, didCatchLeftMouseClick: nsevent, isDown: false, tapIdentifier: tapIdentifier)
					
				case .leftMouseDragged:
					self.delegate?.eventTapper?(self, didCatchLeftMouseDragging: nsevent, tapIdentifier: tapIdentifier)
					
				case .rightMouseDown:
					self.delegate?.eventTapper?(self, didCatchRightMouseClick: nsevent, isDown: true, tapIdentifier: tapIdentifier)
					
				case .rightMouseUp:
					self.delegate?.eventTapper?(self, didCatchRightMouseClick: nsevent, isDown: false, tapIdentifier: tapIdentifier)
					
				case .rightMouseDragged:
					self.delegate?.eventTapper?(self, didCatchRightMouseDragging: nsevent, tapIdentifier: tapIdentifier)
					
				case .mouseMoved:
					self.delegate?.eventTapper?(self, didCatchMouseMoving: nsevent, tapIdentifier: tapIdentifier)
					
				case _: ()
			}
			
			self.delegate?.eventTapper?(self, didCatchAnyEvent: nsevent, tapIdentifier: tapIdentifier)
		}
		
		if let tapWrapper {
			setup?(tapWrapper)
		}
		self.tapWrapper = tapWrapper
		
		return tapWrapper?.identifier
	}
	
	@discardableResult
	open func tap(for eventTypes: [CGEventType],
				  location: CGEventTapLocation = .cghidEventTap,
				  placement: CGEventTapPlacement = .headInsertEventTap,
				  tapOptions: CGEventTapOptions = .defaultTap,
				  setup: ((_ tapWrapper: EventTapWrapper) -> Void)? = nil,
				  evaluationHandler: @escaping (_ event: CGEvent, _ evaluationFunction: EventTapWrapper.EvaluationFunction) -> Bool) -> EventTapWrapper.EventTapID? {
		tap(for: eventTypes.eventMask,
			location: location,
			placement: placement,
			tapOptions: tapOptions,
			setup: setup,
			evaluationHandler: evaluationHandler)
	}
	
	@discardableResult
	open func keyTap(location: CGEventTapLocation = .cghidEventTap,
					 placement: CGEventTapPlacement = .headInsertEventTap,
					 tapOptions: CGEventTapOptions = .defaultTap,
					 setup: ((_ tapWrapper: EventTapWrapper) -> Void)? = nil,
					 reservedKeyEvents: [ReservedKeyEvent]) -> EventTapWrapper.EventTapID? {
		tap(for: [.keyDown, .keyUp, .flagsChanged],
			location: location,
			placement: placement,
			tapOptions: tapOptions,
			setup: setup) { event, evaluationFunction in
			
			guard let nsevent = NSEvent(cgEvent: event)
			else { return false }
			
			for revent in reservedKeyEvents {
				if revent.evaluate(with: nsevent) {
					if evaluationFunction == .shouldContinueToHandle {
#if DEBUG_EVENT_TAPPER
						print("== Handle this event: \(nsevent)\n")
#endif
						return true
					}
					if evaluationFunction == .shouldStopDispatchingToSystem {
#if DEBUG_EVENT_TAPPER
						print("== Stop event dispatching to the system")
#endif
						return true
					}
				}
			}
			
			return false
		}
	}
	
}


// MARK: -

public extension EventTapper {
	
	/// Simulate key event
	static func postKeyEvent(virtualKey: CGKeyCode,
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
	static func postKeyDown(key: CGKeyCode, flags: CGEventFlags = .maskNonCoalesced, keyDown: Bool = true) {
		postKeyEvent(virtualKey: key, isKeyDown: keyDown) { event in
			event.flags = flags // To override the modifier key being pressed by the user. (Do not insert new flags)
		}
	}
	
	/// Simulate mouse button event
	static func postMouseButtonEvent(mouseType: CGEventType,
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
	static func postPrimaryMouseClick() {
		postMouseButtonEvent(mouseType: .leftMouseDown, mouseButton: .left)
		postMouseButtonEvent(mouseType: .leftMouseUp, mouseButton: .left)
	}
	
	/// Simulate secondary mouse button click
	static func postSecondaryMouseClick() {
		postMouseButtonEvent(mouseType: .rightMouseDown, mouseButton: .right)
		postMouseButtonEvent(mouseType: .rightMouseUp, mouseButton: .right)
	}
	
}

#endif

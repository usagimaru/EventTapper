//
//  EventWatcher.swift
//
//  Created by usagimaru on 2017.06.18.
//  Copyright © 2017 usagimaru.
//

#if os(macOS)
import Cocoa

/// A standalone utility for monitoring events via `NSEvent`'s global and local monitor APIs.
///
/// Unlike `EventTapper` / `EventTapWrapper`, which use low-level `CGEventTap`,
/// this class relies entirely on `NSEvent.addGlobalMonitorForEvents(matching:handler:)` and
/// `NSEvent.addLocalMonitorForEvents(matching:handler:)`. It is independent of the
/// `EventTapper` family and can be used on its own.
///
/// - The global monitor observes events targeted at other applications.
/// - The local monitor observes events targeted at the current application
///   and consumes them (returns `nil`) to prevent further dispatching.
///
/// Provides both a delegate (`EventWatcherDelegate`) and a closure (`eventWatcherHandler`)
/// for receiving events. A shared singleton is available via `EventWatcher.shared`.
///
/// ```
/// EventWatcher.shared.delegate = self
/// EventWatcher.shared.watchEvent(for: [.keyDown, .leftMouseDown])
/// ```
///
/// - Note: Does not require Accessibility permission, but the global monitor
///   cannot observe key events unless the app is trusted or sandboxed appropriately.
open class EventWatcher: NSObject {
	
	public static let shared = EventWatcher()
	open weak var delegate: EventWatcherDelegate?
	
	public var eventWatcherHandler: ((_ event: NSEvent) -> Void)?
	
	private var globalMonitor: Any?
	private var localMonitor: Any?
	
	open var isWatching: Bool {
		self.globalMonitor != nil
	}
	
	open func stopWatching() {
		if let globalMonitor {
			NSEvent.removeMonitor(globalMonitor)
		}
		if let localMonitor {
			NSEvent.removeMonitor(localMonitor)
		}
		
		self.globalMonitor = nil
		self.localMonitor = nil
	}
	
	open func watchEvent(for mask: NSEvent.EventTypeMask) {
		stopWatching()
		
		func eventHandler(event: NSEvent, isGlobalEvent: Bool) {
			self.eventWatcherHandler?(event)
			
			if event.type == .keyDown {
				self.delegate?.eventWatcherDidCatchKeyEvent?(event: event, isDown: true)
			}
			if event.type == .keyUp {
				self.delegate?.eventWatcherDidCatchKeyEvent?(event: event, isDown: false)
			}
			if event.type == .flagsChanged {
				self.delegate?.eventWatcherDidCatchFlagsChanged?(event: event)
			}
			
			if event.type == .leftMouseDown {
				self.delegate?.eventWatcherDidCatchLeftMouseEvent?(event: event, isDown: true)
			}
			if event.type == .leftMouseUp {
				self.delegate?.eventWatcherDidCatchLeftMouseEvent?(event: event, isDown: false)
			}
			if event.type == .leftMouseDragged {
				self.delegate?.eventWatcherDidCatchLeftMouseDraggedEvent?(event: event)
			}
			
			if event.type == .rightMouseDown {
				self.delegate?.eventWatcherDidCatchRightMouseEvent?(event: event, isDown: true)
			}
			if event.type == .rightMouseUp {
				self.delegate?.eventWatcherDidCatchRightMouseEvent?(event: event, isDown: false)
			}
			if event.type == .rightMouseDragged {
				self.delegate?.eventWatcherDidCatchRightMouseDraggedEvent?(event: event)
			}
			
			if event.type == .mouseMoved {
				self.delegate?.eventWatcherDidCatchMouseMoved?(event: event)
			}
		}
		
		self.globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: mask, handler: { (event: NSEvent) in
			eventHandler(event: event, isGlobalEvent: true)
		})
		self.localMonitor = NSEvent.addLocalMonitorForEvents(matching: mask) { (event: NSEvent?) in
			if let event {
				eventHandler(event: event, isGlobalEvent: false)
				// To end event dispatching, return nil here.
				return nil
			}
			return event
		}
		
	}
	
}


// MARK: - EventWatcherDelegate

/// Delegate protocol for receiving categorized events from `EventWatcher`.
///
/// All methods are optional. Implement only the event types you need to observe.
@objc public protocol EventWatcherDelegate: AnyObject {
	
	@objc optional func eventWatcherDidCatchFlagsChanged(event: NSEvent)
	@objc optional func eventWatcherDidCatchKeyEvent(event: NSEvent, isDown: Bool)
	
	@objc optional func eventWatcherDidCatchLeftMouseEvent(event: NSEvent, isDown: Bool)
	@objc optional func eventWatcherDidCatchLeftMouseDraggedEvent(event: NSEvent)
	@objc optional func eventWatcherDidCatchRightMouseEvent(event: NSEvent, isDown: Bool)
	@objc optional func eventWatcherDidCatchRightMouseDraggedEvent(event: NSEvent)
	@objc optional func eventWatcherDidCatchMouseMoved(event: NSEvent)
	
}

#endif

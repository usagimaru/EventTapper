//
//  EventWatcher.swift
//
//  Created by usagimaru on 2017.06.18.
//  Copyright © 2017 usagimaru.
//

#if os(macOS)
import Cocoa

@objc public protocol EventWatcherDelegate: AnyObject {
	
	@objc optional func eventWatcherDidCatchFlagsChanged(event: NSEvent)
	@objc optional func eventWatcherDidCatchKeyEvent(event: NSEvent, isDown: Bool)
	
	@objc optional func eventWatcherDidCatchLeftMouseEvent(event: NSEvent, isDown: Bool)
	@objc optional func eventWatcherDidCatchLeftMouseDraggedEvent(event: NSEvent)
	@objc optional func eventWatcherDidCatchRightMouseEvent(event: NSEvent, isDown: Bool)
	@objc optional func eventWatcherDidCatchRightMouseDraggedEvent(event: NSEvent)
	@objc optional func eventWatcherDidCatchMouseMoved(event: NSEvent)
	
}

open class EventWatcher: NSObject {
	
	public static let shared = EventWatcher()
	open weak var delegate: EventWatcherDelegate?
	
	public var eventWacherHandler: ((_ event: NSEvent) -> Void)?
	
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
			self.eventWacherHandler?(event)
			
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
				// nilを返すとイベントディスパッチを終える
				return nil
			}
			return event
		}
		
	}
	
}

#endif

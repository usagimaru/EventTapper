//
//  EventTapWrapper.swift
//
//  Created by usagimaru on 2023.02.25.
//  Copyright © 2023 usagimaru.
//
//  References:
//  https://stackoverflow.com/questions/9352939/how-can-one-detect-mission-control-or-command-tab-switcher-superseding-ones-pro
//  https://stackoverflow.com/questions/55616797/how-can-i-pass-an-anonymous-method-into-a-closure-that-captures-context-in-swift
//  https://github.com/briankendall/forceFullDesktopBar/blob/master/dockInjection/dockInjection.m
//  https://github.com/wilix-team/iohook/blob/master/libuiohook/src/darwin/input_hook.c
//  https://github.com/lwouis/alt-tab-macos/blob/master/src/logic/events/KeyboardEvents.swift

#if os(macOS)
import Cocoa

open class EventTapWrapper {
	
	public enum Function {
		/// Determines which events to pass to the Handler. (When returning the true, the event is passed to the Handler.)
		case shouldHandle
		/// Determines to release caught events to the system. (When returning the true, the event is not released to the system.)
		case shouldStopDispatching
	}
	
	public typealias EventTapID = UUID
	public typealias EvaluationHandler = (EventTapWrapper, CGEvent, Function) -> Bool
	public typealias Handler = (EventTapWrapper, CGEvent) -> ()
	
	open private(set) var identifier: EventTapID = UUID()
	open private(set) var eventTypes = [CGEventType]()
	open private(set) var tap: CFMachPort?
	
	private var evaluationHandler: EvaluationHandler
	private var handler: Handler?
	
	public init?(location: CGEventTapLocation,
				 placement: CGEventTapPlacement,
				 tapOption: CGEventTapOptions,
				 eventTypes: [CGEventType],
				 evaluation: @escaping EvaluationHandler,
				 handler: Handler?) {
		self.evaluationHandler = evaluation
		self.handler = handler
		self.eventTypes = eventTypes
		disableTap()
		self.tap = nil
		
		let callback: CGEventTapCallBack = { tapProxy, eventType, event, selfPointer in
			let eventTapWrapper = Unmanaged<EventTapWrapper>.fromOpaque(selfPointer!).takeUnretainedValue()
			var shouldProcess = true
			
			// Re-enable the tap if it is disabled.
			if let tap = eventTapWrapper.tap,
			   (eventType == .tapDisabledByTimeout ||
				eventType == .tapDisabledByUserInput)
			{
				CGEvent.tapEnable(tap: tap, enable: true)
				eventTapWrapper.debug_print()
				shouldProcess = false
			}
			
			// Evaluate 1
			let shoudHandle = eventTapWrapper.evaluationHandler(eventTapWrapper, event, .shouldHandle)
			if shoudHandle == false {
				shouldProcess = false
			}
			
			if shouldProcess == true {
				// Evaluate 2
				let shouldStopDispatching = eventTapWrapper.evaluationHandler(eventTapWrapper, event, .shouldStopDispatching)
				
				// Handle
				eventTapWrapper.handler?(eventTapWrapper, event)
				
				if shouldStopDispatching == true {
					// If nil is not returned, the event dispatching will continue and a system beep may sound.
					// Then CGEventTapOptions must be `defaultTap`.
					return nil
				}
			}
			
			// The event dispatching will continue.
			return Unmanaged<CGEvent>.passUnretained(event)
		}
		let eventMask = eventTypes.reduce(CGEventMask(0), { $0 | (1 << $1.rawValue) })
		
		guard let tap = CGEvent.tapCreate(tap: location,
										  place: placement,
										  options: tapOption,
										  eventsOfInterest: eventMask,
										  callback: callback,
										  userInfo: Unmanaged<EventTapWrapper>.passUnretained(self).toOpaque())
		else { return nil }
		
		self.tap = tap
	}
		
	private func debug_print() {
#if DEBUG
		if let tap = self.tap {
			print(#function, "The tap \(tap) is re-enabled.")
		}
		else {
			print(#function, "The tap does not exist.")
		}
#endif
	}
	
	open func enableTap(_ runLoop: CFRunLoop = CFRunLoopGetCurrent(), mode: CFRunLoopMode = .commonModes) {
		if let tap = self.tap {
			CFRunLoopAddSource(runLoop,
							   CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0),
							   mode)
			CGEvent.tapEnable(tap: tap, enable: true)
			CFRunLoopRun()
		}
	}
	
	open func disableTap(_ runLoop: CFRunLoop = CFRunLoopGetCurrent(), mode: CFRunLoopMode = .commonModes) {
		if let tap = self.tap {
			CGEvent.tapEnable(tap: tap, enable: false)
			CFRunLoopRemoveSource(runLoop,
								  CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0),
								  mode)
		}
	}
	
}

#endif

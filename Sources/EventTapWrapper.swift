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


/// A low-level wrapper for CGEventTap
public class EventTapWrapper {
	
	/// Evaluation types for `EvaluationHandler`
	public enum EvaluationFunction {
		/// Determines which events to pass to the Handler. If true is returned from `EvaluationHandler`, the event is passed to the `EventHandler`. If false is returned, the `EventHandler` is not called with `shouldStopDispatchingToSystem`.
		case shouldContinueToHandle
		/// Determines to release caught events to the system. If true is returned from `EvaluationHandler`, the event is not passed to the system.
		case shouldStopDispatchingToSystem
	}
	
	public typealias EventTapID = UUID
	public typealias EvaluationHandler = (EventTapWrapper, CGEvent, EvaluationFunction) -> Bool
	public typealias EventHandler = (EventTapWrapper, CGEvent) -> ()
	
	public var activatesTapAtTimeoutAutomatically: Bool = true
	public var activatesTapAtUserInputAutomatically: Bool = true
	
	public private(set) var identifier: EventTapID = UUID()
	public private(set) var tap: CFMachPort?
	
	private var evaluationHandler: EvaluationHandler
	private var eventHandler: EventHandler?
	
	private var tapOptionsOfLastTap: CGEventTapOptions?
	
	/// - Parameters:
	///   - location: Event tapping location like `CGEventTapLocation.cghidEventTap`
	///   - placement: Event insertion location on existing event
	///   - tapOptions: Specifies that the tap is an active filter (`CGEventTapOptions.defaultTap`) or passive listener (`CGEventTapOptions.listenOnly`)
	///   - eventMask: Specifies event types like mouseDown, keyUp, and etc. You can use the extension `[CGEventType].eventMask`.
	///   - evaluationHandler: Evaluate whether to handle the existing event. If false is returned, exit without processing.
	///   - eventHandler: Handle events as you like.
	/// - Discussion:
	///   - The `EventHandler` may be called once or twice in succession. Each should be judged by `EvaluationFunction` and return how it behaves by Bool.
	public init?(location: CGEventTapLocation,
				 placement: CGEventTapPlacement,
				 tapOptions: CGEventTapOptions,
				 eventMask: CGEventMask,
				 evaluationHandler: @escaping EvaluationHandler,
				 eventHandler: EventHandler?) {
		self.evaluationHandler = evaluationHandler
		self.eventHandler = eventHandler
		self.tapOptionsOfLastTap = tapOptions
		disableTap()
		self.tap = nil
		
		// Callback
		let callback: CGEventTapCallBack = { tapProxy, eventType, event, selfPointer in
			let eventTapWrapper = Unmanaged<EventTapWrapper>.fromOpaque(selfPointer!).takeUnretainedValue()
			var shouldProcess = true
			
			// Re-enable the tap if it is disabled.
			if let tap = eventTapWrapper.tap {
				if eventTapWrapper.activatesTapAtTimeoutAutomatically == true,
				   eventType == .tapDisabledByTimeout {
					CGEvent.tapEnable(tap: tap, enable: true)
					eventTapWrapper.debug_print()
					shouldProcess = false
				}
				if eventTapWrapper.activatesTapAtUserInputAutomatically == true,
				   eventType == .tapDisabledByUserInput {
					CGEvent.tapEnable(tap: tap, enable: true)
					eventTapWrapper.debug_print()
					shouldProcess = false
				}
			}
			// Evaluate 1: First evaluate whether to handle this event. If false is returned, exit without processing.
			let shoudHandle = eventTapWrapper.evaluationHandler(eventTapWrapper, event, .shouldContinueToHandle)
			if shoudHandle == false {
				shouldProcess = false
			}
			
			if shouldProcess == true {
				let shouldStopDispatching: Bool
				if eventTapWrapper.tapOptionsOfLastTap == .defaultTap {
					// Evaluate 2: Evaluate whether to dispatch this event to the system.
					shouldStopDispatching = eventTapWrapper.evaluationHandler(eventTapWrapper, event, .shouldStopDispatchingToSystem)
				}
				else {
					// When using tapOptions as `CGEventTapOptions.listenOnly`, do not run Evaluate 2.
					// Events are always dispatched to the system.
					shouldStopDispatching = false
				}
				
				// Handle the event
				eventTapWrapper.eventHandler?(eventTapWrapper, event)
				
				if shouldStopDispatching == true {
					// Stop the event dispatching.
					// If nil is not returned, the event dispatching will continue and a system beep may sound.
					// Then CGEventTapOptions must be `defaultTap`.
					return nil
				}
				
				// When `shouldStopDispatching == false`, this tapping is listen only.
			}
			
			// The event dispatching to the system will continue.
			return Unmanaged<CGEvent>.passUnretained(event)
		}
		
		guard let tap = CGEvent.tapCreate(tap: location,
										  place: placement,
										  options: tapOptions,
										  eventsOfInterest: eventMask,
										  callback: callback,
										  userInfo: Unmanaged<EventTapWrapper>.passUnretained(self).toOpaque())
		else { return nil }
		
		self.tap = tap
	}
	
	public convenience init?(location: CGEventTapLocation,
							 placement: CGEventTapPlacement,
							 tapOptions: CGEventTapOptions,
							 eventTypes: [CGEventType],
							 evaluationHandler: @escaping EvaluationHandler,
							 eventHandler: EventHandler?) {
		self.init(location: location,
				  placement: placement,
				  tapOptions: tapOptions,
				  eventMask: eventTypes.eventMask,
				  evaluationHandler: evaluationHandler,
				  eventHandler: eventHandler)
	}
		
	private func debug_print() {
#if DEBUG_EVENT_TAPPER
		if let tap = self.tap {
			print(#function, "The tap \(tap) is re-enabled.")
		}
		else {
			print(#function, "The tap does not exist.")
		}
#endif
	}
	
	public func enableTap(_ runLoop: CFRunLoop = CFRunLoopGetCurrent(), mode: CFRunLoopMode = .commonModes) {
		if let tap = self.tap {
			CFRunLoopAddSource(runLoop,
							   CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0),
							   mode)
			CGEvent.tapEnable(tap: tap, enable: true)
			CFRunLoopRun()
		}
	}
	
	public func disableTap(_ runLoop: CFRunLoop = CFRunLoopGetCurrent(), mode: CFRunLoopMode = .commonModes) {
		if let tap = self.tap {
			CGEvent.tapEnable(tap: tap, enable: false)
			CFRunLoopRemoveSource(runLoop,
								  CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0),
								  mode)
		}
	}
	
}

#endif

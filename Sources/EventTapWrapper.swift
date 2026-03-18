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


/// A low-level wrapper around `CGEvent.tapCreate()` that manages the lifecycle of a CGEventTap.
///
/// This class handles:
/// - Creating a CGEventTap with a C callback bridge
/// - Attaching/detaching the tap's run loop source
/// - Automatic re-enabling when the tap is disabled by timeout or user input
/// - Two-phase event evaluation via `EvaluationHandler`
///
/// ## Event Processing Flow
///
/// When an event arrives, the callback performs the following steps:
///
/// 1. **Auto re-enable** — If the tap was disabled by timeout or user input,
///    it is automatically re-enabled (controlled by `activatesTapAtTimeoutAutomatically`
///    and `activatesTapAtUserInputAutomatically`).
///
/// 2. **Evaluate 1 (`.shouldContinueToHandle`)** — The `EvaluationHandler` is called to decide
///    whether this event should be processed. Return `false` to skip.
///
/// 3. **Evaluate 2 (`.shouldStopDispatchingToSystem`)** — Only when `tapOptions` is `.defaultTap`.
///    Return `true` to consume the event (prevent it from reaching the system).
///
/// 4. **Handle** — The `EventHandler` is called with the event.
///
/// 5. **Dispatch** — If not consumed, the event is passed through to the system.
///
/// ## Usage
///
/// Typically used indirectly through `EventTapper`, but can be used standalone:
/// ```
/// let tap = EventTapWrapper(
///     location: .cghidEventTap,
///     placement: .headInsertEventTap,
///     tapOptions: .defaultTap,
///     eventTypes: [.keyDown, .keyUp],
///     evaluationHandler: { wrapper, event, phase in
///         // return true/false based on phase
///     },
///     eventHandler: { wrapper, event in
///         // process the event
///     }
/// )
/// tap?.enableTap()
/// ```
///
/// - Important: Requires macOS Accessibility permission for most event tap locations.
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
	
	/// If `true`, the tap is automatically re-enabled when the system disables it due to timeout.
	/// This can happen when the callback takes too long to return.
	public var activatesTapAtTimeoutAutomatically: Bool = true
	
	/// If `true`, the tap is automatically re-enabled when the system disables it due to user input.
	public var activatesTapAtUserInputAutomatically: Bool = true
	
	public private(set) var identifier: EventTapID = UUID()
	public private(set) var tap: CFMachPort?
	
	private var evaluationHandler: EvaluationHandler
	private var eventHandler: EventHandler?
	
	private var tapOptionsOfLastTap: CGEventTapOptions?
	private var runLoopSource: CFRunLoopSource?
	private var attachedRunLoop: CFRunLoop?
	private var attachedRunLoopMode: CFRunLoopMode?
	
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
			let shouldHandle = eventTapWrapper.evaluationHandler(eventTapWrapper, event, .shouldContinueToHandle)
			if shouldHandle == false {
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
	
	/// Convenience initializer that accepts an array of `CGEventType` instead of a raw bitmask.
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
		if let tap {
			print(#function, "The tap \(tap) is re-enabled.")
		}
		else {
			print(#function, "The tap does not exist.")
		}
#endif
	}
	
	/// Attach the tap to a run loop and enable it.
	///
	/// - Parameters:
	///   - runLoop: The run loop to attach to. Defaults to the current thread's run loop.
	///   - mode: The run loop mode. Defaults to `.commonModes`.
	public func enableTap(_ runLoop: CFRunLoop = CFRunLoopGetCurrent(), mode: CFRunLoopMode = .commonModes) {
		guard let tap else { return }
		
		// Remove existing source if already attached
		removeRunLoopSource()
		
		// Retain the run loop source and its associated run loop/mode so that disableTap() can remove the exact same instance later.
		// CFMachPortCreateRunLoopSource() returns a new object each time, so passing a freshly created source to CFRunLoopRemoveSource() would fail.
		guard let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0) else { return }
		runLoopSource = source
		attachedRunLoop = runLoop
		attachedRunLoopMode = mode
		
		CFRunLoopAddSource(runLoop, source, mode)
		CGEvent.tapEnable(tap: tap, enable: true)
	}
	
	/// Disable the tap and detach it from the run loop.
	public func disableTap() {
		if let tap {
			CGEvent.tapEnable(tap: tap, enable: false)
		}
		removeRunLoopSource()
	}
	
	private func removeRunLoopSource() {
		if let attachedRunLoop, let runLoopSource, let attachedRunLoopMode {
			CFRunLoopRemoveSource(attachedRunLoop, runLoopSource, attachedRunLoopMode)
		}
		runLoopSource = nil
		attachedRunLoop = nil
		attachedRunLoopMode = nil
	}
	
}

#endif

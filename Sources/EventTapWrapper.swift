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

#if os(macOS)
import Cocoa

open class EventTapWrapper {
	
	public typealias Handler = (CGEventTapProxy, CGEvent) -> ()
	public typealias EvaluationHandler = (EventTapWrapper, CGEvent) -> Bool
	
	open private(set) var identifier = UUID()
	open private(set) var eventTypes = [CGEventType]()
	open private(set) var tap: CFMachPort?
	
	private let handler: Handler
	private let evaluationHandler: EvaluationHandler
	
	public init?(location: CGEventTapLocation,
		  placement: CGEventTapPlacement,
		  tapOption: CGEventTapOptions,
		  eventTypes: [CGEventType],
		  shouldCatch: @escaping EvaluationHandler,
		  handler: @escaping Handler) {
		self.handler = handler
		self.evaluationHandler = shouldCatch
		self.eventTypes = eventTypes
		self.tap = nil
		
		let eventMask = eventTypes.reduce(CGEventMask(0), { $0 | (1 << $1.rawValue) })
		
		guard let tap = CGEvent.tapCreate(
			tap: location,
			place: placement,
			options: tapOption,
			eventsOfInterest: eventMask,
			callback: { tapProxy, eventType, event, selfPointer in
				let eventTapWrapper = Unmanaged<EventTapWrapper>.fromOpaque(selfPointer!).takeUnretainedValue()
				let shoudCatch = eventTapWrapper.evaluationHandler(eventTapWrapper, event)
				
				// Note. CGEventTapOptions.defaultTap にして nil を返すと beep が鳴らなくなるが、キーイベントを全て奪うので扱い注意
				if shoudCatch == true {
					eventTapWrapper.handler(tapProxy, event)
					return nil
				}
				return Unmanaged<CGEvent>.passUnretained(event)
			},
			userInfo: Unmanaged.passUnretained(self).toOpaque())
		else { return nil }
		
		self.tap = tap
	}
	
	open func addToRunLoop(_ runLoop: CFRunLoop = CFRunLoopGetCurrent(), mode: CFRunLoopMode = .commonModes) {
		if let tap = self.tap {
			CFRunLoopAddSource(
				runLoop,
				CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0),
				mode
			)
			
			CGEvent.tapEnable(tap: tap, enable: true)
			CFRunLoopRun()
		}
	}
	
	open func removeFromRunLoop(_ runLoop: CFRunLoop = CFRunLoopGetCurrent(), mode: CFRunLoopMode = .commonModes) {
		if let tap = self.tap {
			CFRunLoopRemoveSource(runLoop,
								  CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0),
								  mode)
		}
	}
	
}

#endif

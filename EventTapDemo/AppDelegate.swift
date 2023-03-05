//
//  AppDelegate.swift
//  EventTapDemo
//
//  Created by usagimaru on 2023/02/28.
//

/*
 [Note 1]
 To tap any events, we must have the permission of accessibility_access.
 However, if our app is sandboxed, the system alert dialog for accessibility_access does not appear.
 In this case, we will probably need to implement that UI on your own.
 It should be noted that apps that use accessibility_access cannot be distributed on the App Store.
 
 [Note 2]
 I have set up a debug script in the "Build Phase" of this project to reset the permission in order to efficiently debug accessibility_access.
 So the script is executed at each build and the permission is reset.
 */

import Cocoa

@main
class AppDelegate: NSObject, NSApplicationDelegate, EventTapperDelegate {

	private var eventTapperActive = EventTapper()
	private var eventTapperPassive = EventTapper()

	func applicationDidFinishLaunching(_ aNotification: Notification) {
		// Try to get the accessibility_access.
		AccessibilityAuthorization.askAccessibilityAccessIfNeeded()
		AccessibilityAuthorization.pollAccessibilityAccessTrusted { [self] in
			tapEvents()
			//listenEvents()
		}
	}
	
	
	// MARK: -
	
	/// Tap events
	private func tapEvents() {
		// EventTapperDelegate
		self.eventTapperActive.delegate = self
		
		// Target event types
		let eventTypes: [CGEventType] = [
			.flagsChanged,
			.keyDown,
		]
		
		self.eventTapperActive.tap(for: eventTypes) { event, function in
			// Check the `function` parameter (as EventTapWrapper.Function) to evaluate which events to pass to Handler
			// or whether to dispatch caught events to the system.
			// When `function == .shouldHandle` in this closure, returning true does handle the event.
			// When `function == .shouldStopDispatching` in this closure, returning true does stop the event dispatching.
			
			guard let nsevent = NSEvent(cgEvent: event)
			else { return false }
			
			let modifiers = nsevent.modifierFlags.intersection(.deviceIndependentFlagsMask)
			
			switch event.type {
				case .flagsChanged: ()
					
				case .keyDown:
					let command = modifiers.contains(.command)
					let option = modifiers.contains(.option)
					let control = modifiers.contains(.control)
					let option_command = modifiers.contains([.option, .command])
					let shift_command = modifiers.contains([.shift, .command])
					
					// ⌥⌘D
					if nsevent.charactersIgnoringModifiers == "d" && option_command {
						// These are print twice, which is the correct.
						print("☎️ \(event.timestamp) evaluate [ ⌥⌘D ], function: \(function)")
						return true
					}
					
					// ⌥⌘⎋
					if event.keyCode == KeyCode.escape && option_command {
						print("☎️ \(event.timestamp) evaluate [ ⌥⌘⎋ ], function: \(function)")
						return true
					}
					
					// ⇧⌘⇥
					if event.keyCode == KeyCode.tab && shift_command {
						print("☎️ \(event.timestamp) evaluate [ ⇧⌘⇥ ], function: \(function)")
						return true
					}
					
					// ⌘⎋
					if event.keyCode == KeyCode.escape && command {
						print("☎️ \(event.timestamp) evaluate [ ⌘⎋ ], function: \(function)")
						return true
					}
					
					// ⌘K
					if event.keyCharacter == "k" && command {
						print("☎️ \(event.timestamp) evaluate [ ⌘K ], function: \(function)")
						// Catch the event and stop dispatching.
						return true
					}
					
					// ⌃G
					if nsevent.charactersIgnoringModifiers == "g" && control {
						print("☎️ \(event.timestamp) evaluate [ ⌃G ], function: \(function)")
						return true
					}
					
					// ⌥Space
					if event.keyCode == KeyCode.space && option {
						print("☎️ \(event.timestamp) evaluate [ ⌥Space ], function: \(function)")
						return true
					}
					
				case _: ()
			}
			
			// Don't dispatch any events to the system or don't handle other unchecked events.
			return false
		}
	}
	
	/// Listen only
	private func listenEvents() {
		self.eventTapperPassive.delegate = self
		
		let eventTypes: [CGEventType] = [
			.flagsChanged,
			.keyDown,
			.keyUp,
			.leftMouseDown,
			.leftMouseUp,
			.leftMouseDragged,
		]
		
		self.eventTapperPassive.tap(for: eventTypes,
									location: .cghidEventTap,
									placement: .headInsertEventTap,
									tapOption: .listenOnly) { event, function in
			if function == .shouldHandle {
				return true
			}
			
			// Don't dispatch an event to the system.
			return false
		}
	}
	
	
	// MARK: - EventTapperDelegate
	// Implement any processes here.
	
	func eventTapper(_ eventTapper: EventTapper, didCatchFlagsChanged event: NSEvent, tapIdentifier: EventTapWrapper.EventTapID) {
		print("modifier keys: \(event)")
	}
	
	func eventTapper(_ eventTapper: EventTapper, didCatchKeyEvent event: NSEvent, isDown: Bool, tapIdentifier: EventTapWrapper.EventTapID) {
		print("key: \(isDown ? "press" : "release") | \(event)")
	}
	
	func eventTapper(_ eventTapper: EventTapper, didCatchLeftMouseClick event: NSEvent, isDown: Bool, tapIdentifier: EventTapWrapper.EventTapID) {
		print("left mouse click: \(isDown ? "press" : "release")")
	}
	
	func eventTapper(_ eventTapper: EventTapper, didCatchLeftMouseDragging event: NSEvent, tapIdentifier: EventTapWrapper.EventTapID) {
		
	}
	
	func eventTapper(_ eventTapper: EventTapper, didCatchRightMouseClick event: NSEvent, isDown: Bool, tapIdentifier: EventTapWrapper.EventTapID) {
		
	}
	
	func eventTapper(_ eventTapper: EventTapper, didCatchRightMouseDragging event: NSEvent, tapIdentifier: EventTapWrapper.EventTapID) {
		
	}
	
	func eventTapper(_ eventTapper: EventTapper, didCatchMouseMoving event: NSEvent, tapIdentifier: EventTapWrapper.EventTapID) {
		
	}
	
	func eventTapper(_ eventTapper: EventTapper, didCatchAnyEvent event: NSEvent, tapIdentifier: EventTapWrapper.EventTapID) {
		
	}

}

struct KeyCode {
	// Key codes from Carbon HIToolbox/Events.h
	
	static let tab = CGKeyCode(0x30)
	static let space = CGKeyCode(0x31)
	static let escape = CGKeyCode(0x35)
}

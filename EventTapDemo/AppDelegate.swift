//
//  AppDelegate.swift
//  EventTapDemo
//
//  Created by usagimaru on 2023/02/28.
//

/*
 [Note 1]
 To tap any events, we must have the permission of accessibility_access.
 However, if the app is sandboxed, the system alert dialog for accessibility_access does not appear.
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
		// (Need to deactivate sandboxing build setting)
		AccessibilityAuthorization.askAccessibilityAccessIfNeeded()
		AccessibilityAuthorization.pollAccessibilityAccessTrusted { [self] in
			start()
		}
	}
	
	func start() {
		if AccessibilityAuthorization.isAccessibilityAccessTrusted() {
			// There are three ways of tapping events
			
			// Type A
			// Register custom key conbinations with `ReservedKeyEvent` representation
			tapEventsWithReservedKeyEvents()
			
			// Type B
			// Tap any events directly
			//tapEvents()
			
			// Type C
			// Listen for key, mouse and other events
			//listenEvents()
		}
	}
	
	
	// MARK: - Type A
	
	private func tapEventsWithReservedKeyEvents() {
		print(
"""
===================================================
You can demonstrate the following key combinations:
  ✓ Option Command 1
  ✓ Command K
  ✓ Command Esc
  ✓ Control Command 2 (key down / key up)
  ✓ Shift Command (detects only modifier keys)
    Arrow keys:
	✓ Shift Command ↓
	✓ Shift Command ↑
	✓ Shift Command ←
	✓ Shift Command →
===================================================
"""
		)
		
		tapKeyEvents(reservedKeyEvents: [
			// Option-Command-1
			ReservedKeyEvent(keyRepresentation: KeyRepresentation(character: "1", modifierFlags: [.option, .command])),
			
			// Command-Escape
			ReservedKeyEvent(keyRepresentation: KeyRepresentation(keyCode: CGKeyCode.escape, modifierFlags: .command)),
			
			// Control-Command-2 on key down / key up
			ReservedKeyEvent(tappingPoint: .keyDown, keyRepresentation: KeyRepresentation(character: "2", modifierFlags: [.control, .command])),
			ReservedKeyEvent(tappingPoint: .keyUp, keyRepresentation: KeyRepresentation(character: "2", modifierFlags: [.control, .command])),
			
			// Command and Shift
			ReservedKeyEvent(keyRepresentation: KeyRepresentation(onlyModifierFlags: [.command, .shift])),
			
			// Arrow keys
			ReservedKeyEvent(keyRepresentation: KeyRepresentation(specialKey: .downArrow, modifierFlags:  [.shift, .command])),
			ReservedKeyEvent(keyRepresentation: KeyRepresentation(specialKey: .upArrow, modifierFlags:  [.shift, .command])),
			ReservedKeyEvent(keyRepresentation: KeyRepresentation(specialKey: .leftArrow, modifierFlags:  [.shift, .command])),
			ReservedKeyEvent(keyRepresentation: KeyRepresentation(specialKey: .rightArrow, modifierFlags:  [.shift, .command])),
			
			// Custom evaluation (Command-K)
			ReservedKeyEvent(customEvaluator: { event in
				// Do not return `true` when event.type == .flagsChanged
				
				if event.type == .keyDown {
					return event.modifierFlags.contains(.command) && event.charactersIgnoringModifiers == "k"
				}
				return false
			}),
		])
	}
	
	/// Tap events
	private func tapKeyEvents(_ setup: ((EventTapWrapper) -> Void)? = nil, reservedKeyEvents: [ReservedKeyEvent]) {
		// EventTapperDelegate
		eventTapperActive.delegate = self
		// Tap key events with ReservedKeyEvent
		eventTapperActive.keyTap(setup: setup, reservedKeyEvents: reservedKeyEvents)
	}
	
	
	// MARK: - Type B
	
	/// Tap events
	private func tapEvents() {
		// EventTapperDelegate
		eventTapperActive.delegate = self
		
		// Target event types
		let eventTypes: [CGEventType] = [
			.flagsChanged,
			.keyDown,
		]
		
		eventTapperActive.tap(for: eventTypes) { event, function in
			// Check the `function` parameter (as EventTapWrapper.EvaluationFunction) to evaluate which events to pass to EventHandler
			// or whether to dispatch caught events to the system.
			// When `evaluationFunction == .shouldContinueToHandle` in this closure, returning true does handle the event.
			// When `evaluationFunction == .shouldStopDispatchingToSystem` in this closure, returning true does stop the event dispatching to the system.
			
			guard let nsevent = NSEvent(cgEvent: event)
			else { return false }
			
			//let modifiers = nsevent.modifierFlags.intersection(.deviceIndependentFlagsMask)
			let modifiers = nsevent.modifierFlags._plainFlags
			
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
					if event.keyCode == CGKeyCode.escape && option_command {
						print("☎️ \(event.timestamp) evaluate [ ⌥⌘⎋ ], function: \(function)")
						return true
					}
					
					// ⇧⌘⇥
					if event.keyCode == CGKeyCode.tab && shift_command {
						print("☎️ \(event.timestamp) evaluate [ ⇧⌘⇥ ], function: \(function)")
						return true
					}
					
					// ⌘⎋
					if event.keyCode == CGKeyCode.escape && command {
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
					if event.keyCode == CGKeyCode.space && option {
						print("☎️ \(event.timestamp) evaluate [ ⌥Space ], function: \(function)")
						return true
					}
					
				case _: ()
			}
			
			// Don't dispatch any events to the system or don't handle other unchecked events.
			return false
		}
	}
	
	
	// MARK: - Type C
	
	/// Listen only
	private func listenEvents() {
		eventTapperPassive.delegate = self
		
		let eventTypes: [CGEventType] = [
			.flagsChanged,
			.keyDown,
			.keyUp,
			.leftMouseDown,
			.leftMouseUp,
			.leftMouseDragged,
		]
		
		eventTapperPassive.tap(for: eventTypes,
							   location: .cghidEventTap,
							   placement: .headInsertEventTap,
							   tapOptions: .listenOnly) { event, _ in
			
			if let nsevent = NSEvent(cgEvent: event), nsevent.type == .keyDown {
				return nsevent.modifierFlags.contains(.command) && nsevent.charactersIgnoringModifiers == "k"
			}
			
			// If tapOptions is `CGEventTapOptions.listenOnly`, evaluation with `shouldStopDispatchingToSystem` is not performed.
			return false
		}
	}
	
	
	// MARK: - EventTapperDelegate
	// Implement any processes here.
	
	func eventTapper(_ eventTapper: EventTapper, didCatchFlagsChanged event: NSEvent, tapIdentifier: EventTapWrapper.EventTapID) {
		print("✅ detect modifier keys: \(event)\n")
	}
	
	func eventTapper(_ eventTapper: EventTapper, didCatchKeyEvent event: NSEvent, isDown: Bool, tapIdentifier: EventTapWrapper.EventTapID) {
		print("✅ detect key combination: \(isDown ? "press" : "release") | \(event)\n")
	}
	
	func eventTapper(_ eventTapper: EventTapper, didCatchLeftMouseClick event: NSEvent, isDown: Bool, tapIdentifier: EventTapWrapper.EventTapID) {
		print("✅ detect left mouse click: \(isDown ? "press" : "release")\n")
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

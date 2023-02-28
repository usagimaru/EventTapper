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
		AccessibilityAuthorization.askAccessibilityAccessIfNeeded()
		AccessibilityAuthorization.pollAccessibilityAccessTrusted { [self] in
			tapEvents()
			//listenEvents()
		}
	}
	
	
	// MARK: -
	
	private func tapEvents() {
		// Handle with delegate method
		self.eventTapperActive.delegate = self
		
		let eventTypes: [CGEventType] = [
			.flagsChanged,
			.keyDown,
		]
		
		self.eventTapperActive.tap(for: eventTypes) { event, function in
			guard let nsevent = NSEvent(cgEvent: event)
			else { return false }
			
			switch event.type {
				case .keyDown:
					let flags_command = nsevent.modifierFlags
						.intersection(.deviceIndependentFlagsMask)
						.contains(.command)
					
					// ⌘K
					if nsevent.charactersIgnoringModifiers == "k" && flags_command {
						print("☎️ Timestamp: \(event.timestamp), Override [ ⌘K ]")
						return true
					}
					
					// ⌘G
					if nsevent.charactersIgnoringModifiers == "g" && flags_command {
						print("☎️ Timestamp: \(event.timestamp), Override [ ⌘G ]")
						return true
					}
					
					let flags_option_command = nsevent.modifierFlags
						.intersection(.deviceIndependentFlagsMask)
						.contains([.command, .option])
					
					// ⌥⌘⎋
					if nsevent.keyCode == KeyCode.escape && flags_option_command {
						print("☎️ Timestamp: \(event.timestamp), Override [ ⌥⌘⎋ ]")
						return true
					}
					
					// ⌘⎋
					if nsevent.keyCode == KeyCode.escape && flags_command {
						print("☎️ Timestamp: \(event.timestamp), Override [ ⌘⎋ ]")
						return true
					}
					
					// ⌥⌘D
					if nsevent.charactersIgnoringModifiers == "d" && flags_option_command {
						print("☎️ Timestamp: \(event.timestamp), Override [ ⌥⌘D ]")
						return true
					}
					
				case _: ()
			}
			
			return false
		}
	}
	
	private func listenEvents() {
		// Handle with delegate method
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
									placement: .tailAppendEventTap,
									tapOption: .listenOnly) { event, function in
			if function == .shouldHandle {
				return true
			}
			
			// Don't dispatch an event to the system
			return false
		}
	}
	
	func applicationWillTerminate(_ aNotification: Notification) {
		// Insert code here to tear down your application
	}
	
	func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
		return true
	}
	
	
	// MARK: - EventTapperDelegate
	
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
	
	static let space = CGKeyCode(0x31)
	static let escape = CGKeyCode(0x35)
	static let eisu = CGKeyCode(0x66)
	static let kana = CGKeyCode(0x68)
}

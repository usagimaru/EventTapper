//
//  ReservedEvent.swift
//
//  Created by usagimaru on 2023/12/25.
//

import Cocoa

/// Defines a specific key event to intercept with `EventTapper.keyTap()`.
///
/// Each instance represents a single key combination or condition to match against incoming events.
/// Pass an array of `ReservedKeyEvent` to `EventTapper.keyTap(reservedKeyEvents:)` to intercept
/// matching events and optionally prevent them from being dispatched to the system.
///
/// There are two ways to define a matching condition:
///
/// 1. **KeyRepresentation** — Match by character, key code, special key, or modifier flags:
///    ```
///    // Match Command-Tab by character
///    ReservedKeyEvent(keyRepresentation: KeyRepresentation(character: "\t", modifierFlags: .command))
///
///    // Match arrow key by key code
///    ReservedKeyEvent(keyRepresentation: KeyRepresentation(keyCode: .leftArrow, modifierFlags: nil))
///
///    // Match modifier-only (e.g. Option key press)
///    ReservedKeyEvent(keyRepresentation: KeyRepresentation(onlyModifierFlags: .option))
///    ```
///
/// 2. **Custom evaluator** — Provide a closure for arbitrary matching logic:
///    ```
///    ReservedKeyEvent(tappingPoint: .keyDown) { event in
///        event.keyCode == 0x31 // space bar
///    }
///    ```
///
/// The `tappingPoint` determines which event phase (keyDown, keyUp, flagsChanged) this instance
/// responds to. Events of other types are filtered out before evaluation.
public struct ReservedKeyEvent {
	
	public enum TappingPoint {
		case keyDown
		case keyUp
		case flagsChanged
		
		public func eventType() -> CGEventType {
			switch self {
				case .keyDown: .keyDown
				case .keyUp: .keyUp
				case .flagsChanged: .flagsChanged
			}
		}
	}
	
	public private(set) var tappingPoint: TappingPoint = .keyDown
	public private(set) var keyRepresentation: KeyRepresentation?
	public private(set) var customEvaluator: ((_ nsevent: NSEvent) -> Bool)?
	
	/// With KeyRepresentation
	public init(tappingPoint: TappingPoint = .keyDown, keyRepresentation: KeyRepresentation) {
		self.keyRepresentation = keyRepresentation
		
		if keyRepresentation.onlyModifiers {
			self.tappingPoint = .flagsChanged
		}
		else {
			self.tappingPoint = tappingPoint
		}
	}
	
	/// With the custom evaluator
	public init(tappingPoint: TappingPoint = .keyDown, customEvaluator: ((_ event: NSEvent) -> Bool)?) {
		self.tappingPoint = tappingPoint
		self.customEvaluator = customEvaluator
	}
	
	public func evaluate(with event: NSEvent) -> Bool {
		// Filter by tappingPoint so that only the expected event type is evaluated.
		guard event.cgEvent?.type == tappingPoint.eventType() else {
			return false
		}
		
		if let customEvaluator {
			return customEvaluator(event)
		}
		
		if let keyRepresentation {
			switch keyRepresentation.type() {
				case .character:
					if let character = keyRepresentation.character, event.type != .flagsChanged {
						return character == event.charactersIgnoringModifiers && keyRepresentation.evaluateModifierFlags(with: event)
					}
					
				case .keyCode:
					if let keyCode = keyRepresentation.keyCode, event.type != .flagsChanged {
						return keyCode == event.keyCode && keyRepresentation.evaluateModifierFlags(with: event)
					}
					
				case .specialKey:
					if let specialKey = keyRepresentation.specialKey, event.type != .flagsChanged {
						return specialKey == event.specialKey && keyRepresentation.evaluateModifierFlags(with: event)
					}
					
				case .modifiers:
					return keyRepresentation.evaluateModifierFlags(with: event)
					
				case _: ()
			}
		}
		
		return false
	}
	
}

/// Represents a key or modifier combination to match against an NSEvent.
///
/// Use one of the designated initializers to specify the matching strategy:
/// - `init(character:modifierFlags:)` — Match by keyboard character (e.g. "a", "\t")
/// - `init(keyCode:modifierFlags:)` — Match by CGKeyCode value
/// - `init(specialKey:modifierFlags:)` — Match by NSEvent.SpecialKey
/// - `init(onlyModifierFlags:)` — Match modifier key presses only (automatically sets tappingPoint to `.flagsChanged`)
public struct KeyRepresentation {
	
	public enum RepresentationType {
		case none
		case character
		case keyCode
		case specialKey
		case modifiers
	}
	
	public private(set) var character: String?
	public private(set) var keyCode: CGKeyCode?
	public private(set) var specialKey: NSEvent.SpecialKey?
	public private(set) var modifierFlags: NSEvent.ModifierFlags?
	public private(set) var onlyModifiers: Bool = false
	
	/// Keyboard character with modifier flags
	public init(character: String, modifierFlags: NSEvent.ModifierFlags?) {
		self.character = character
		self.modifierFlags = modifierFlags
	}
	
	/// Key code with modifier flags
	public init(keyCode: CGKeyCode, modifierFlags: NSEvent.ModifierFlags?) {
		self.keyCode = keyCode
		self.modifierFlags = modifierFlags
	}
	
	/// NSEvent’s specialKey with modifier flags
	public init(specialKey: NSEvent.SpecialKey, modifierFlags: NSEvent.ModifierFlags?) {
		self.specialKey = specialKey
		self.modifierFlags = modifierFlags
	}
	
	/// Modifier flags
	public init(onlyModifierFlags: NSEvent.ModifierFlags) {
		self.modifierFlags = onlyModifierFlags
		self.onlyModifiers = true
	}
	
	/// Representation type
	public func type() -> RepresentationType {
		if character != nil {
			return .character
		}
		if keyCode != nil {
			return .keyCode
		}
		if specialKey != nil {
			return .specialKey
		}
		if modifierFlags != nil && onlyModifiers == true {
			return .modifiers
		}
		return .none
	}
	
	/// Evaluate equality for modifier flags with NSEvent object
	public func evaluateModifierFlags(with event: NSEvent) -> Bool {
		if let modifierFlags {
			return event.modifierFlags._plainFlags == modifierFlags
			//return modifierFlags.contains(event.modifierFlags._plainFlags)
		}
		return true
	}
	
}

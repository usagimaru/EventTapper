//
//  ReservedEvent.swift
//
//  Created by usagimaru on 2023/12/25.
//

import Cocoa

public struct ReservedKeyEvent {
	
	public enum TappingPoint {
		case keyDown
		case keyUp
		case flagsChanged
		
		func eventType() -> CGEventType {
			switch self {
				case .keyDown: .keyDown
				case .keyUp: .keyUp
				case .flagsChanged: .flagsChanged
			}
		}
	}
	
	private(set) var tappingPoint: TappingPoint = .keyDown
	private(set) var keyRepresentation: KeyRepresentation?
	private(set) var customEvaluator: ((_ nsevent: NSEvent) -> Bool)?
	
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
		if let customEvaluator {
			return customEvaluator(event)
		}
		
		if let keyRepresentation, event.cgEvent?.type == tappingPoint.eventType() {
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

public struct KeyRepresentation {
	
	public enum RepresentationType {
		case none
		case character
		case keyCode
		case specialKey
		case modifiers
	}
	
	private(set) var character: String?
	private(set) var keyCode: CGKeyCode?
	private(set) var specialKey: NSEvent.SpecialKey?
	private(set) var modifierFlags: NSEvent.ModifierFlags?
	private(set) var onlyModifiers: Bool = false
	
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

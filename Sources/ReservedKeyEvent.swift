//
//  ReservedEvent.swift
//  EventTapDemo
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
	public init(tappingPoint: TappingPoint = .keyDown, customEvaluator: ((_ event: NSEvent) -> Bool)? = nil) {
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
		}
		return true
	}
	
}

public struct KeyCode {
	// Keycodes from Carbon’s HIToolbox/Events.h
	// I do not guarantee that these will function correctly in all environments.
	// I think it is safer to handle some special keys such as arrow keys with NSEvent.SpecialKey.
	
	static let capsLock = CGKeyCode(0x39)
	static let command = CGKeyCode(0x37)
	static let control = CGKeyCode(0x3B)
	static let delete = CGKeyCode(0x33)
	static let downArrow = CGKeyCode(0x7D)
	static let end = CGKeyCode(0x77)
	static let escape = CGKeyCode(0x35)
	static let f1 = CGKeyCode(0x7A)
	static let f2 = CGKeyCode(0x78)
	static let f3 = CGKeyCode(0x63)
	static let f4 = CGKeyCode(0x76)
	static let f5 = CGKeyCode(0x60)
	static let f6 = CGKeyCode(0x61)
	static let f7 = CGKeyCode(0x62)
	static let f8 = CGKeyCode(0x64)
	static let f9 = CGKeyCode(0x65)
	static let f10 = CGKeyCode(0x6D)
	static let f11 = CGKeyCode(0x67)
	static let f12 = CGKeyCode(0x6F)
	static let f13 = CGKeyCode(0x69)
	static let f14 = CGKeyCode(0x6B)
	static let f15 = CGKeyCode(0x71)
	static let f16 = CGKeyCode(0x6A)
	static let f17 = CGKeyCode(0x40)
	static let f18 = CGKeyCode(0x4F)
	static let f19 = CGKeyCode(0x50)
	static let f20 = CGKeyCode(0x5A)
	static let forwardDelete = CGKeyCode(0x75)
	static let function = CGKeyCode(0x3F)
	static let help = CGKeyCode(0x72)
	static let home = CGKeyCode(0x73)
	static let leftArrow = CGKeyCode(0x7B)
	static let mute = CGKeyCode(0x4A)
	static let option = CGKeyCode(0x3A)
	static let pageDown = CGKeyCode(0x79)
	static let pageUp = CGKeyCode(0x74)
	static let `return` = CGKeyCode(0x24)
	static let rightArrow = CGKeyCode(0x7C)
	static let rightCommand = CGKeyCode(0x36)
	static let rightControl = CGKeyCode(0x3E)
	static let rightOption = CGKeyCode(0x3D)
	static let rightShift = CGKeyCode(0x3C)
	static let shift = CGKeyCode(0x38)
	static let space = CGKeyCode(0x31)
	static let tab = CGKeyCode(0x30)
	static let upArrow = CGKeyCode(0x7E)
	static let volumeDown = CGKeyCode(0x49)
	static let volumeUp = CGKeyCode(0x48)
	
	static let ISO_Section = CGKeyCode(0x0A)
	
	static let JIS_Yen = CGKeyCode(0x5D)
	static let JIS_Underscore = CGKeyCode(0x5E)
	static let JIS_KeypadComma = CGKeyCode(0x5F)
	static let JIS_Eisu = CGKeyCode(0x66)
	static let JIS_Kana = CGKeyCode(0x68)

}


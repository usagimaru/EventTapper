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
	private(set) var modifierFlags: NSEvent.ModifierFlags?
	private(set) var character: String?
	private(set) var customEvaluator: ((_ nsevent: NSEvent) -> Bool)?
	
	/// Keyboard character with modifier flags
	public init(tappingPoint: TappingPoint = .keyDown, modifierFlags: NSEvent.ModifierFlags?, character: String?) {
		self.tappingPoint = tappingPoint
		self.modifierFlags = modifierFlags
		self.character = character
	}
	
	/// For modifier flags only
	public init(flagsChanged flags: NSEvent.ModifierFlags) {
		self.tappingPoint = .flagsChanged
		self.modifierFlags = flags
		self.character = "" // To detect modifier flags, empty character must be set.
	}
	
	/// With the custom evaluator
	public init(tappingPoint: TappingPoint = .keyDown, customEvaluator: ((_ event: NSEvent) -> Bool)? = nil) {
		self.tappingPoint = tappingPoint
		self.customEvaluator = customEvaluator
	}
	
	func evaluate(with event: NSEvent) -> Bool {
		var flagsEvaluation: Bool {
			if let flags = modifierFlags {
				return event.modifierFlags._plainFlags == flags
			}
			return true
		}
		
		if let customEvaluator = customEvaluator {
			return customEvaluator(event)
		}
		
		if let char = character, event.type != .flagsChanged {
			if event.cgEvent?.type == tappingPoint.eventType() {
				return char == event.charactersIgnoringModifiers && flagsEvaluation
			}
		}
		else {
			return flagsEvaluation
		}
		
		return false
	}
	
}

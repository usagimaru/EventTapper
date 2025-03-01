//
//  CGKeyCode+extensions.swift
//
//  Created by usagimaru on 2023/12/26.
//

import CoreGraphics

public extension CGKeyCode {
	// Keycodes from Carbon’s HIToolbox/Events.h
	// I do not guarantee that these will function correctly in all environments.
	// I think it is safer to handle some special keys such as arrow keys with NSEvent.SpecialKey.
	
	static let capsLock = Self(0x39)
	static let command = Self(0x37)
	static let control = Self(0x3B)
	static let delete = Self(0x33)
	static let downArrow = Self(0x7D)
	static let end = Self(0x77)
	static let escape = Self(0x35)
	static let f1 = Self(0x7A)
	static let f2 = Self(0x78)
	static let f3 = Self(0x63)
	static let f4 = Self(0x76)
	static let f5 = Self(0x60)
	static let f6 = Self(0x61)
	static let f7 = Self(0x62)
	static let f8 = Self(0x64)
	static let f9 = Self(0x65)
	static let f10 = Self(0x6D)
	static let f11 = Self(0x67)
	static let f12 = Self(0x6F)
	static let f13 = Self(0x69)
	static let f14 = Self(0x6B)
	static let f15 = Self(0x71)
	static let f16 = Self(0x6A)
	static let f17 = Self(0x40)
	static let f18 = Self(0x4F)
	static let f19 = Self(0x50)
	static let f20 = Self(0x5A)
	static let forwardDelete = Self(0x75)
	static let function = Self(0x3F)
	static let help = Self(0x72)
	static let home = Self(0x73)
	static let leftArrow = Self(0x7B)
	static let mute = Self(0x4A)
	static let option = Self(0x3A)
	static let pageDown = Self(0x79)
	static let pageUp = Self(0x74)
	static let `return` = Self(0x24)
	static let rightArrow = Self(0x7C)
	static let rightCommand = Self(0x36)
	static let rightControl = Self(0x3E)
	static let rightOption = Self(0x3D)
	static let rightShift = Self(0x3C)
	static let shift = Self(0x38)
	static let space = Self(0x31)
	static let tab = Self(0x30)
	static let upArrow = Self(0x7E)
	static let volumeDown = Self(0x49)
	static let volumeUp = Self(0x48)
	
	static let ISO_Section = Self(0x0A)
	
	static let JIS_Yen = Self(0x5D)
	static let JIS_Underscore = Self(0x5E)
	static let JIS_KeypadComma = Self(0x5F)
	static let JIS_Eisu = Self(0x66)
	static let JIS_Kana = Self(0x68)
	
}

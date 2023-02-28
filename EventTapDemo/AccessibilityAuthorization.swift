//
//  AccessibilityAuthorization.swift
//
//  Created by usagimaru on 2022/11/05.
//

import Cocoa

// https://github.com/bonyadmitr/XcodeProjects/blob/de6f1b11b2c847b30b900c8a2539e0a30a06c7ba/_mac/Bluetooth-Keyboard-Emulator/Keyboard%20Connect%20Open%20Source/PermissionManager.swift
// https://stackoverflow.com/questions/853833/how-can-my-app-detect-a-change-to-another-apps-window
// https://stackoverflow.com/a/36260107

class AccessibilityAuthorization {
	
	private static let sandboxEnvironmentIdKey: String = "APP_SANDBOX_CONTAINER_ID"
	
	static func isSandboxingApp() -> Bool {
		let environment = ProcessInfo.processInfo.environment
		return environment[sandboxEnvironmentIdKey] != nil
	}
	
	static func isAccessibilityAccessTrusted() -> Bool {
		return AXIsProcessTrusted()
	}
	
	@discardableResult
	static func askAccessibilityAccessIfNeeded() -> Bool {
		let showsSystemAlert = true
		let options = [kAXTrustedCheckOptionPrompt.takeRetainedValue(): showsSystemAlert] as CFDictionary
		let result = AXIsProcessTrustedWithOptions(options)
		return result
	}
	
	static func pollAccessibilityAccessTrusted(completion: @escaping () -> Void) {
		DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
			if AXIsProcessTrusted() {
				completion()
			} else {
				pollAccessibilityAccessTrusted(completion: completion)
			}
		}
	}
	
}

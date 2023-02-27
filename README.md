# EventTapper
A Carbon free event-tapping module for keyboard and mouse on macOS (experimental).

Detect hot key events using CGEventTap without using the Carbon framework. Accessibility access permission is required for use.

Many hot key implementations on modern macOS still rely on the Carbon framework, but apparently hot key can be achieved by event tapping using CGEvent's low-level API. My hope is to achieve hot key on macOS using a carbon free and safe API.

The list of requirements is as follows:

- Carbon free
- For modern macOS environment
- To be used with Swift
- Can be used from the background
- Exclude system beeps
- Receives only registered key combinations (does not pass events to the system)
- Exclude non-registered key combinations (pass events to the system)

Note:
It may not work correctly because it has not yet been fully research and tested.


## EventWatcher

Monitors keyboard and mouse events, using two methods of NSEvent.

- [`addGlobalMonitorForEvents()`](https://developer.apple.com/documentation/appkit/nsevent/1535472-addglobalmonitorforevents)
- [`addLocalMonitorForEvents()`](https://developer.apple.com/documentation/appkit/nsevent/1534971-addlocalmonitorforevents)

This is the most popular solution for event tapping on macOS, but it has a problem: it catches the events but passes it on to the system. Thus, inputting some key combinations from the background may cause a system beep.

To solve this problem, use `EventTapper` and `EventTapWrapper`.


## EventTapper, EventTapWrapper

An easy-to-handle wrapper class in Swift for low-level event tapping using CGEvent.

My approach is to stop event dispatching when tapping events using CGEvent's [`tapCreate()`](https://developer.apple.com/documentation/coregraphics/cgevent/1454426-tapcreate). This prevents the event from being passed to the system, thus avoiding the depressing system beep.

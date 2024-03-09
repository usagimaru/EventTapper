# EventTapper
A CGEventTap-based module for catching keyboard and mouse events on macOS. Easily detect hot keys and global mouse events in your apps.

Many hot key implementations on modern macOS still rely on the Carbon framework, but apparently hot key can be achieved by event tapping using CGEvent's low-level API. My hope is to achieve hot key on macOS using a carbon free and safe API.

## Features

- For modern macOS
- Carbon free
- Swift
- Prevents events from being intercepted and passed to the system (no beeps)
- Can register key combinations to catch events
- Can be used in the background (Accessibility access permission is need for use)

Note:
It may not work correctly because it has not yet been fully research and tested.


## Classes

### `EventWatcher`

Monitors keyboard and mouse events, using two methods of NSEvent.

- [`addGlobalMonitorForEvents()`](https://developer.apple.com/documentation/appkit/nsevent/1535472-addglobalmonitorforevents)
- [`addLocalMonitorForEvents()`](https://developer.apple.com/documentation/appkit/nsevent/1534971-addlocalmonitorforevents)

This is the most popular solution for event tapping on macOS, but it has a problem: it catches the events but passes it on to the system. Thus, inputting some key combinations from the background may cause a system beep.

To solve this problem, use `EventTapper` and `EventTapWrapper`.


### `EventTapWrapper`

A low-level class for handling CGEventTap.

My approach is to stop event dispatching when tapping events using CGEvent's [`tapCreate()`](https://developer.apple.com/documentation/coregraphics/cgevent/1454426-tapcreate). This would allow the events to be intercepted so they would not be passed on to other apps and the system would stop beeping. This mechanism enables system-wide hot keys.


### `EventTapper`

A class that adds a high-level convenience API to EventTapWrapper. Normally use this class.


### `ReservedKeyEvent`

A class used to register key combinations. Refer to the demo.


## License

See [LICENSE](./LICENSE) for details

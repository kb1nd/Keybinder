# Keybinder for creating key repeating sequences through window systems
Window systems supported:


| API          | Support  | Window System   | Builds                       |
|--------------|----------|-----------------|------------------------------|
| Win32        | 🟢       | Windows         | v1windows, v2windows         |
| Wayland      | 🟡       | Wayland         | v1wayland, v2wayland         |
| X11          | 🟢       | X Window System | v1x11, v2x11                 |
| Carbon/Cocoa | 🔴       | macOS           | v1carboncocoa, v2carboncocoa |
| XCB          | 🟢       | X Window System | v1xcb, v2xcb                 |


# This application splits into two parts:

The V1, which uses a fabric client to automatically toggle the key repeating sequence based on the item you're holding, through communication with the desktop program.

The V2, which doesn't require you to run a fabric client, but requires you to additionally bind a key which works like a manual alternative for the key repeating sequence toggling automation featured in V1.

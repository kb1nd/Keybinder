# Keybinder for creating key repeating sequences through window systems
These are The supported APIs of The window systems supported


| API          | Support | Window System   |
|--------------|---------|-----------------|
| Windows      | 🟡       | Windows         |
| Wayland      | 🟡       | Wayland         |
| X11          | 🟢       | X Window System |
| Carbon/Cocoa | 🔴       | macOS           |
| XCB          | 🟡       | X Window System |


# This application splits into two parts:
The V1, which uses a fabric client to automatically toggle the key repeating sequence based on the item you're holding through communicating with the desktop program.
The V2, which doesn't require you to run a fabric client, but requires you to additionally bind a key which toggles the key repeating sequence off instead.

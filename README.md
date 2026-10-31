# Astra UI

A native Luau UI library for Roblox clients. Dark/violet styling, readable typography, draggable windows and launcher, tabs, controls, notifications and JSON configuration.

**Version: 1.1.0**

## Files

| File | Purpose |
| --- | --- |
| `menu.luau` | Pure library. Returns `UI`; creates no windows or demo tabs. |
| `example.luau` | Consumer script. Loads the library from this repository and builds a custom menu. |
| `demo.luau` | Self-contained demo with the library included; no HTTP loading needed. |
| `API.md` | Public API and examples for developers and AI assistants. |

## Quick start

In a client environment that provides `loadstring` and `game:HttpGet`:

```lua
local UI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Jairoxdpro/menu/main/menu.luau"))()
local Window = UI:CreateWindow({Name = "My Hub", ToggleKey = "RightShift"})
local Main = Window:CreateTab("Main")

Main:CreateToggle({
    Name = "My option",
    Flag = "my_option",
    CurrentValue = false,
    Callback = function(value)
        print("Enabled:", value)
    end,
})

Main:SetName("Dashboard")
-- Main:Destroy() -- Removes the tab and its controls.
```

In Roblox Studio, put the contents of `menu.luau` in a ModuleScript named `AstraUI` under ReplicatedStorage and load it from a LocalScript:

```lua
local UI = require(game:GetService("ReplicatedStorage"):WaitForChild("AstraUI"))
```

## Window controls

- Drag the header to move the window.
- **− / +** folds the window to its header and restores it.
- **X** hides the full menu.
- The draggable **A** button and **RightShift** show or hide the full menu.
- `Window:Destroy()` unloads the window and disconnects its events.

## Dynamic tabs

```lua
local Tab = Window:CreateTab("Tools")
Tab:SetName("Utilities")
Tab:Select()
Tab:Destroy()
```

Deleting a tab disconnects its events, releases its flags and keybinds, removes its controls, and selects another available tab if necessary. Deleting the last tab leaves an empty window where new tabs can be created. A destroyed tab cannot be reused.

## Using this library with an AI assistant

Give the assistant this repository's `API.md` and the Raw URL for `menu.luau`. Ask it to write a **separate consumer script** that loads `UI`, creates a window and uses the documented public methods. It does not need to modify the library internals to create, rename or delete tabs.

Only `demo.luau` contains the Home, Components and Settings demo tabs. Loading `menu.luau` does not create them.

## Configuration

Controls with a unique `Flag` participate in `Window:ExportConfig()` and `Window:ImportConfig(json)`. Storage is the consumer's responsibility; the library does not write files automatically.

See [API.md](API.md) for supported options and lifecycle behavior.

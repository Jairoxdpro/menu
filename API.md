# Astra UI 1.1 public API

For developers and AI assistants: load `menu.luau` as a library, then write your own consumer script. Do not edit the library to build an ordinary menu. The library creates no windows or tabs until its methods are called.

## Load

```lua
local UI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Jairoxdpro/menu/main/menu.luau"))()
```

This HTTP loading form requires a compatible client environment. In Studio use a ModuleScript and `require` instead. `UI.Version` is `"1.1.0"`.

## Window

```lua
local Window = UI:CreateWindow({
    Name = "My Hub",
    Subtitle = "My tools",
    Accent = Color3.fromRGB(158, 127, 255),
    ToggleKey = "RightShift", -- A KeyCode name or Enum.KeyCode.
    ReducedMotion = false,
    -- Parent = game.Players.LocalPlayer.PlayerGui,
})
```

Parent resolution: explicit `Parent`, then optional `gethui()`, then `LocalPlayer.PlayerGui`.

| Method | Result |
| --- | --- |
| `Window:CreateTab(name)` | Creates and returns a tab. Also accepts `{Name = name}`. |
| `Window:Notify({Title, Content, Duration})` | Shows a notification. Duration is clamped to 1–30 seconds. |
| `Window:SetVisible(boolean)` | Shows/hides the full menu. Showing it restores a folded window. |
| `Window:SetMinimized(boolean)` | Folds/restores the window header without losing controls. |
| `Window:ExportConfig()` | Returns JSON for all controls with flags. |
| `Window:ImportConfig(json, fireCallbacks?)` | Validates the full known configuration before applying it. Unknown flags are ignored. Default is silent. Keybind actions are not invoked by import. |
| `Window:Destroy()` | Destroys all tabs, GUI roots and event connections. Safe to call again. |

Each `CreateWindow` call creates an independent window. Keep the returned handle and destroy it before replacing an integration. Multiple simultaneous windows sharing the same toggle key will all respond to that key.

## Tabs

```lua
local Tab = Window:CreateTab("Main")
Tab:SetName("Dashboard") -- Returns the same Tab for chaining.
Tab:Select()
Tab:Destroy()
```

- Names must contain at least one non-whitespace character. `SetName` requires a string.
- Renaming the selected tab also updates the page heading. Existing controls and their values are preserved.
- Destroying a tab removes all its controls, disconnects its events and unregisters its flags/keybinds.
- If the selected tab is deleted, the next tab is selected, or the previous tab when deleting the last entry. Removing every tab clears the heading.
- Remaining tabs are renumbered automatically. New tabs can be created after all tabs have been removed.
- `Tab:Destroy()` is idempotent. Other operations on destroyed tabs/controls raise an error.
- Retain tab handles in your script. Directly destroying `Tab.Page` or `Tab.Button` bypasses lifecycle cleanup; use `Tab:Destroy()`.

## Common control options

`Name`, optional `Description`, optional `Callback`. Value controls also accept optional `Flag`, a nonempty string unique within the window. Flags become available for reuse when their owning tab is destroyed.

## Sections and paragraphs

```lua
Tab:CreateSection("PREFERENCES")
Tab:CreateParagraph({Title = "Welcome", Content = "Your explanatory text."})
```

These return their Frame instances. They do not have value-control Get/Set methods.

## Button

```lua
local Button = Tab:CreateButton({Name = "Run action", Description = "An optional description.", ButtonText = "Run",
    Callback = function() print("Clicked") end})
Button:Fire() -- Invoke its callback programmatically.
```

Buttons expose `Instance` and `Fire()`. They do not have Get/Set.

## Toggle

```lua
local Toggle = Tab:CreateToggle({Name = "Enabled", Flag = "enabled", CurrentValue = false,
    Callback = function(value) print(value) end})
Toggle:Set(true)
print(Toggle:Get())
```

Set expects a boolean.

## Slider

```lua
local Slider = Tab:CreateSlider({Name = "Amount", Flag = "amount", Range = {0, 100}, Increment = 5,
    CurrentValue = 50, Suffix = "%", Callback = function(value) print(value) end})
```

Range must contain finite minimum and maximum numbers with maximum greater than minimum. Increment must be finite and positive. Values clamp to the range and snap to the increment using the minimum as origin. NaN and infinity are rejected.

## Dropdown

```lua
local Dropdown = Tab:CreateDropdown({Name = "Profile", Flag = "profile",
    Options = {"Balanced", "Creative", "Minimal"}, CurrentOption = "Balanced",
    Callback = function(value) print(value) end})
Dropdown:Set("Creative")
```

Options must be a nonempty array of unique strings. One string is selected at a time. Set rejects unknown choices. No multi-select or SetOptions API is provided.

## Input

```lua
local Input = Tab:CreateInput({Name = "Project name", Flag = "project", CurrentValue = "My project",
    PlaceholderText = "Enter a name", MaxLength = 60, Callback = function(value) print(value) end})
```

Values must be valid UTF-8 strings. MaxLength defaults to 256 characters. Text commits when the field loses focus.

## Keybind

```lua
local Keybind = Tab:CreateKeybind({Name = "Shortcut", Flag = "shortcut", CurrentKeybind = "K",
    Callback = function(key) print("Pressed:", key) end})
Keybind:Set("J") -- Changes the binding; does not run the action.
```

Keybind values accept KeyCode names or Enum.KeyCode items. Get returns a string name. Clicking the keybind captures a new key; Escape cancels capture. Actions are ignored while the window is hidden/minimized or while typing into a TextBox. The window toggle key has priority.

Keybind dispatch uses a snapshot of the current binding list. Bindings created by a callback wait until the next input event; bindings whose tab has been destroyed are skipped. Configuration-import callbacks also skip controls whose tabs were destroyed by an earlier callback.

## Value control methods

Toggle, Slider, Dropdown, Input and Keybind expose `Instance`, `Get()` and `Set(value, silent?)`.

Initial construction is silent. For value controls other than keybind actions, Set invokes Callback only when the normalized value changes. `Set(value, true)` is silent. Keybind Set never runs the key action. Destroying a tab invalidates its returned controls.

The API is inspired by Rayfield's pattern but is not a complete Rayfield-compatible replacement. Use only methods documented here.

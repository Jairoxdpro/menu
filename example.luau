-- Requires the pure library at Jairoxdpro/menu/main/menu.luau.
local UI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Jairoxdpro/menu/main/menu.luau"))()
assert(type(UI) == "table" and type(UI.CreateWindow) == "function", "Upload the new pure menu.luau library to GitHub first")

local window = UI:CreateWindow({
    Name = "My Hub",
    Subtitle = "Built with Astra UI",
    ToggleKey = "RightShift",
})

local main = window:CreateTab("Main")
main:CreateParagraph({Title = "Your own menu", Content = "Create tabs and controls here. The library does not add any demo tabs."})
main:CreateToggle({Name = "Example option", Description = "Connect your own callback.", Flag = "example_enabled", CurrentValue = false,
    Callback = function(value) print("Example option:", value) end})
main:CreateDropdown({Name = "Profile", Description = "Choose a profile.", Flag = "profile",
    Options = {"Balanced", "Creative", "Minimal"}, CurrentOption = "Balanced"})

local tools = window:CreateTab("Tools")
tools:CreateButton({Name = "Rename Main", Description = "Change an existing tab without editing the library.", ButtonText = "Rename to Dashboard",
    Callback = function() main:SetName("Dashboard") end})
tools:CreateButton({Name = "Create a temporary tab", Description = "The new tab includes a button to delete itself.", ButtonText = "Create tab",
    Callback = function()
        local temporary = window:CreateTab("Temporary")
        temporary:CreateButton({Name = "Delete this tab", Description = "Remove this tab and all its controls.", ButtonText = "Delete tab",
            Callback = function() temporary:Destroy() end})
        temporary:Select()
    end})

return window

-- Astra UI: standalone demo. No HTTP loading required.
local UI = (function()
-- Astra UI 1.0 | Native Roblox UI, standalone Luau / ModuleScript.
-- No network requests or dependencies. See README.md for the public API.
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")

local Library = {Version = "1.0.0"}
local Window = {}
Window.__index = Window
local Tab = {}
Tab.__index = Tab
local Theme = {
    Background = Color3.fromRGB(17, 18, 24),
    Sidebar = Color3.fromRGB(22, 23, 31),
    Surface = Color3.fromRGB(29, 30, 40),
    Raised = Color3.fromRGB(38, 39, 52),
    Border = Color3.fromRGB(49, 50, 65),
    Text = Color3.fromRGB(248, 249, 255),
    Muted = Color3.fromRGB(193, 197, 214),
    Description = Color3.fromRGB(214, 217, 228),
    Accent = Color3.fromRGB(158, 127, 255),
}

local function make(class, props, parent)
    local object = Instance.new(class)
    for key, value in pairs(props) do object[key] = value end
    object.Parent = parent
    return object
end
local function corner(object, radius)
    make("UICorner", {CornerRadius = UDim.new(0, radius or 10)}, object)
end
local function stroke(object, color)
    return make("UIStroke", {Color = color or Theme.Border, Thickness = 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border}, object)
end
local function text(parent, value, size, color, props)
    local p = {BackgroundTransparency = 1, Text = value, Font = Enum.Font.GothamMedium,
        TextSize = math.max(size or 14, 13), TextColor3 = color or Theme.Text, TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd, Size = UDim2.new(1, 0, 0, 20)}
    for k, v in pairs(props or {}) do p[k] = v end
    return make("TextLabel", p, parent)
end
local function button(parent, value, props)
    local p = {Text = value, TextColor3 = Theme.Text, Font = Enum.Font.GothamBold, TextSize = 14,
        BackgroundColor3 = Theme.Raised, BorderSizePixel = 0, AutoButtonColor = false, Selectable = true}
    for k, v in pairs(props or {}) do p[k] = v end
    local b = make("TextButton", p, parent)
    corner(b, 7)
    return b
end
local function pad(parent, amount)
    make("UIPadding", {PaddingLeft = UDim.new(0, amount), PaddingRight = UDim.new(0, amount),
        PaddingTop = UDim.new(0, amount), PaddingBottom = UDim.new(0, amount)}, parent)
end
local function list(parent, gap)
    return make("UIListLayout", {Padding = UDim.new(0, gap or 8), SortOrder = Enum.SortOrder.LayoutOrder}, parent)
end
local function finite(value)
    return type(value) == "number" and value == value and math.abs(value) < math.huge
end
local function keyName(value)
    if typeof(value) == "EnumItem" then
        assert(tostring(value.EnumType) == tostring(Enum.KeyCode), "Expected a KeyCode")
        value = value.Name
    end
    assert(type(value) == "string" and Enum.KeyCode[value] and value ~= "Unknown", "Invalid keybind")
    return value
end
local function resolveParent(explicit)
    if explicit then return explicit end
    -- gethui is optional and is never called in a normal Studio client.
    if type(gethui) == "function" then
        local ok, container = pcall(gethui)
        if ok and typeof(container) == "Instance" then return container end
    end
    local player = Players.LocalPlayer
    assert(player, "AstraUI must run on a client, or receive an explicit Parent")
    return player:WaitForChild("PlayerGui")
end

function Window:_connect(signal, fn)
    local connection = signal:Connect(fn)
    table.insert(self.Connections, connection)
    return connection
end
function Window:_tween(object, props)
    if self.Destroyed then return end
    if self.ReducedMotion then
        for k, v in pairs(props) do object[k] = v end
    else
        TweenService:Create(object, TweenInfo.new(0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), props):Play()
    end
end
function Window:_callback(fn, value)
    if not fn or self.Destroyed then return end
    local ok, err = pcall(fn, value)
    if not ok then warn("[AstraUI callback] " .. tostring(err)) end
end
function Window:SetVisible(visible)
    assert(not self.Destroyed, "Window has been destroyed")
    self.Gui.Enabled = visible == true
    if self.Gui.Enabled and self.Minimized then self:SetMinimized(false) end
    if not self.Gui.Enabled then
        self.Drag = nil; self.SliderDrag = nil
        self:_cancelCapture()
        local focused = UIS:GetFocusedTextBox()
        if focused and focused:IsDescendantOf(self.Gui) then focused:ReleaseFocus() end
    end
end
function Window:SetMinimized(minimized)
    assert(not self.Destroyed, "Window has been destroyed")
    minimized = minimized == true
    if self.Minimized == minimized then return end
    self.Minimized = minimized
    self.Drag = nil; self.SliderDrag = nil
    self:_cancelCapture()
    local focused = UIS:GetFocusedTextBox()
    if focused and focused:IsDescendantOf(self.Gui) then focused:ReleaseFocus() end
    self.Body.Visible = not minimized
    self.Navigation.Visible = not minimized
    self.Footer.Visible = not minimized
    self.MinimizeButton.Text = minimized and "+" or "-"
    self.Main:SetAttribute("Minimized", minimized)
    local viewport = self.Gui.AbsoluteSize
    local p = self.Main.Position
    local x = p.X.Scale * viewport.X + p.X.Offset
    local y = p.Y.Scale * viewport.Y + p.Y.Offset
    local top = y - self.Main.AbsoluteSize.Y / 2
    local height = minimized and self.HeaderHeight or self.ExpandedSize.Y
    y = math.clamp(top + height / 2, height / 2, math.max(height / 2, viewport.Y - height / 2))
    self:_tween(self.Main, {Size = UDim2.fromOffset(self.ExpandedSize.X, height), Position = UDim2.fromOffset(x, y)})
end
function Window:_cancelCapture()
    if self.Capturing then
        self.Capturing.Render(self.Capturing.Value)
        self.Capturing = nil
    end
end
function Window:Destroy()
    if self.Destroyed then return end
    self.Destroyed = true
    for _, c in ipairs(self.Connections) do c:Disconnect() end
    table.clear(self.Connections)
    self.Drag = nil
    self.SliderDrag = nil
    self.Capturing = nil
    self.Gui:Destroy()
    self.Launcher:Destroy()
    table.clear(self.Flags)
    table.clear(self.Keybinds)
end
function Window:ExportConfig()
    assert(not self.Destroyed, "Window has been destroyed")
    local values = {}
    for flag, control in pairs(self.Flags) do values[flag] = control:Get() end
    return HttpService:JSONEncode({version = 1, values = values})
end
function Window:ImportConfig(json, fireCallbacks)
    assert(not self.Destroyed, "Window has been destroyed")
    local data = HttpService:JSONDecode(json)
    assert(type(data) == "table" and data.version == 1 and type(data.values) == "table", "Invalid AstraUI configuration")
    local pending = {}
    -- Validate all values before changing any control.
    for flag, value in pairs(data.values) do
        local c = self.Flags[flag]
        if c then table.insert(pending, {Control = c, Value = c.Validate(value)}) end
    end
    for _, entry in ipairs(pending) do entry.Control:Set(entry.Value, true) end
    if fireCallbacks then
        for _, entry in ipairs(pending) do
            if not entry.Control.ActionOnly then self:_callback(entry.Control.Callback, entry.Value) end
        end
    end
end
function Window:Notify(options)
    if self.Destroyed then return end
    options = options or {}
    if #self.Notices:GetChildren() >= 5 then
        for _, item in ipairs(self.Notices:GetChildren()) do
            if item:IsA("Frame") then item:Destroy(); break end
        end
    end
    local card = make("Frame", {Name = "Notification", BackgroundColor3 = Theme.Surface, BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 84)}, self.Notices)
    corner(card); stroke(card, self.Accent)
    text(card, tostring(options.Title or "Astra UI"), 13, Theme.Text,
        {Position = UDim2.fromOffset(14, 12), Size = UDim2.new(1, -28, 0, 20), Font = Enum.Font.GothamBold})
    text(card, tostring(options.Content or ""), 12, Theme.Muted,
        {Position = UDim2.fromOffset(14, 36), Size = UDim2.new(1, -28, 0, 36), TextWrapped = true, TextTruncate = Enum.TextTruncate.None})
    task.delay(math.clamp(tonumber(options.Duration) or 4, 1, 30), function()
        if not self.Destroyed and card.Parent then card:Destroy() end
    end)
end

function Library.CreateWindow(_library, options)
    options = options or {}
    local parent = resolveParent(options.Parent)
    local self = setmetatable({Connections = {}, Flags = {}, Tabs = {}, Keybinds = {},
        Accent = options.Accent or Theme.Accent, ReducedMotion = options.ReducedMotion == true,
        ToggleKey = keyName(options.ToggleKey or "RightShift"), Destroyed = false, Minimized = false, Query = ""}, Window)
    self.Gui = make("ScreenGui", {Name = "AstraUI", ResetOnSpawn = false, IgnoreGuiInset = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling, DisplayOrder = 80}, parent)
    self.Launcher = make("ScreenGui", {Name = "AstraUI_Launcher", ResetOnSpawn = false, DisplayOrder = 81}, parent)
    local launcher = button(self.Launcher, "A", {Name = "Reopen", Size = UDim2.fromOffset(46, 46),
        Position = UDim2.new(0, 16, 1, -62), TextColor3 = self.Accent, TextSize = 20})
    stroke(launcher, self.Accent)
    local launcherDrag, suppressLauncherClick
    local function moveLauncher(x, y)
        local viewport = self.Launcher.AbsoluteSize
        if viewport.X <= 0 or viewport.Y <= 0 then return end
        local maxX = math.max(0, viewport.X - launcher.AbsoluteSize.X)
        local maxY = math.max(0, viewport.Y - launcher.AbsoluteSize.Y)
        local minX, minY = math.min(8, maxX), math.min(8, maxY)
        launcher.Position = UDim2.fromOffset(
            math.round(math.clamp(x, minX, math.max(minX, maxX - 8))),
            math.round(math.clamp(y, minY, math.max(minY, maxY - 8))))
    end
    self:_connect(launcher.InputBegan, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            local p, v = launcher.Position, self.Launcher.AbsoluteSize
            launcherDrag = {Input = input, Start = input.Position, Moved = false,
                Origin = Vector2.new(p.X.Scale * v.X + p.X.Offset, p.Y.Scale * v.Y + p.Y.Offset)}
            suppressLauncherClick = false
            self.Drag = nil; self.SliderDrag = nil
        end
    end)
    self:_connect(launcher.Activated, function(input)
        local pointer = not input or input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch
        if pointer and (suppressLauncherClick or (launcherDrag and launcherDrag.Moved)) then return end
        self:SetVisible(not self.Gui.Enabled)
    end)
    self:_connect(self.Launcher:GetPropertyChangedSignal("AbsoluteSize"), function()
        local p, v = launcher.Position, self.Launcher.AbsoluteSize
        if launcherDrag then suppressLauncherClick = true; launcherDrag = nil end
        moveLauncher(p.X.Scale * v.X + p.X.Offset, p.Y.Scale * v.Y + p.Y.Offset)
    end)
    local main = make("Frame", {Name = "Window", BackgroundColor3 = Theme.Background, BorderSizePixel = 0,
        AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(800, 550),
        ClipsDescendants = true}, self.Gui)
    self.Main = main
    corner(main, 14); stroke(main)
    local accentLine = make("Frame", {Name = "AccentLine", BackgroundColor3 = self.Accent, BorderSizePixel = 0,
        Position = UDim2.fromOffset(16, 1), Size = UDim2.new(1, -32, 0, 2)}, main)
    corner(accentLine, 1)
    local header = make("Frame", {Name = "Header", Active = true, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 72)}, main)
    local mark = text(header, "A", 24, self.Accent, {Position = UDim2.fromOffset(22, 20), Size = UDim2.fromOffset(26, 30), Font = Enum.Font.GothamBold})
    local windowTitle = text(header, tostring(options.Name or "Astra UI"), 22, Theme.Text,
        {Position = UDim2.fromOffset(62, 15), Size = UDim2.new(1, -170, 0, 25), Font = Enum.Font.GothamBold})
    local subtitle = text(header, tostring(options.Subtitle or "Your tools. Your space."), 11, Theme.Muted,
        {Position = UDim2.fromOffset(62, 41), Size = UDim2.new(1, -170, 0, 17)})
    local minimize = button(header, "-", {Name = "Minimize", Position = UDim2.new(1, -106, 0, 14), Size = UDim2.fromOffset(44, 44), TextSize = 22})
    local close = button(header, "×", {Name = "Close", Position = UDim2.new(1, -56, 0, 14), Size = UDim2.fromOffset(44, 44), TextSize = 22})
    self.MinimizeButton = minimize
    self:_connect(minimize.Activated, function() self:SetMinimized(not self.Minimized) end)
    self:_connect(close.Activated, function() self:SetVisible(false) end)
    for _, control in ipairs({minimize, close}) do
        self:_connect(control.MouseEnter, function()
            self:_tween(control, {BackgroundColor3 = control == close and Color3.fromRGB(90, 42, 59) or Theme.Raised:Lerp(self.Accent, 0.2)})
        end)
        self:_connect(control.MouseLeave, function() self:_tween(control, {BackgroundColor3 = Theme.Raised}) end)
    end
    local nav = make("ScrollingFrame", {Name = "Tabs", BackgroundColor3 = Theme.Sidebar, BorderSizePixel = 0,
        ScrollBarThickness = 2, ScrollBarImageColor3 = self.Accent, CanvasSize = UDim2.new(),
        AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollingDirection = Enum.ScrollingDirection.Y}, main)
    self.Navigation = nav
    pad(nav, 12)
    local navPadding = nav:FindFirstChildOfClass("UIPadding")
    local navList = list(nav, 7)
    local body = make("Frame", {Name = "Body", BackgroundTransparency = 1}, main)
    self.Body = body
    self.PageTitle = text(body, "Overview", 24, Theme.Text,
        {Position = UDim2.fromOffset(18, 12), Size = UDim2.new(1, -36, 0, 28), Font = Enum.Font.GothamBold})
    local search = make("TextBox", {Name = "Search", Text = "", PlaceholderText = "Search controls…", ClearTextOnFocus = false,
        Position = UDim2.fromOffset(18, 49), Size = UDim2.new(1, -36, 0, 36), BackgroundColor3 = Theme.Surface,
        BorderSizePixel = 0, Font = Enum.Font.GothamMedium, TextSize = 14, TextColor3 = Theme.Text,
        PlaceholderColor3 = Theme.Muted, TextXAlignment = Enum.TextXAlignment.Left}, body)
    corner(search, 8); pad(search, 10)
    self:_connect(search:GetPropertyChangedSignal("Text"), function()
        self.Query = string.lower(search.Text)
        for _, tab in ipairs(self.Tabs) do tab:_filter() end
    end)
    self.Pages = make("Frame", {Name = "Pages", BackgroundTransparency = 1, Position = UDim2.fromOffset(18, 97),
        Size = UDim2.new(1, -36, 1, -129)}, body)
    local footer = text(main, self.ToggleKey .. "  /  show or hide", 10, Theme.Muted,
        {Name = "Footer", Position = UDim2.new(0, 18, 1, -24), Size = UDim2.new(1, -36, 0, 16)})
    self.Footer = footer
    self.Notices = make("Frame", {Name = "Notifications", BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 1),
        Position = UDim2.new(1, -18, 1, -18), Size = UDim2.new(0, 300, 0, 366)}, self.Gui)
    local noticesList = list(self.Notices, 8)
    noticesList.VerticalAlignment = Enum.VerticalAlignment.Bottom
    local function resize()
        if self.Destroyed then return end
        local viewport = self.Gui.AbsoluteSize
        local width = math.min(800, math.max(100, viewport.X - 24))
        local height = math.min(550, math.max(140, viewport.Y - 24))
        local narrow = width < 600
        local compact = height < 430
        local headerHeight = compact and 56 or 72
        self.ExpandedSize = Vector2.new(width, height)
        self.HeaderHeight = headerHeight
        main.Size = UDim2.fromOffset(width, self.Minimized and headerHeight or height)
        local navHeight = compact and 56 or 62
        local showSearch = height >= 290
        self.Narrow = narrow
        header.Size = UDim2.new(1, 0, 0, headerHeight)
        subtitle.Visible = not compact
        windowTitle.Position = UDim2.fromOffset(62, compact and 17 or 15)
        mark.Position = UDim2.fromOffset(22, compact and 13 or 20)
        minimize.Position = UDim2.new(1, -106, 0, compact and 6 or 14)
        close.Position = UDim2.new(1, -56, 0, compact and 6 or 14)
        self.PageTitle.Visible = not compact
        search.Visible = showSearch
        if not showSearch and search.Text ~= "" then search.Text = "" end
        local pageTop = compact and (showSearch and 42 or 0) or 97
        search.Position = UDim2.fromOffset(18, compact and 0 or 49)
        search.Size = UDim2.new(1, -36, 0, compact and 32 or 36)
        self.Pages.Position = UDim2.fromOffset(18, pageTop)
        self.Pages.Size = UDim2.new(1, -36, 1, -(pageTop + 8))
        navPadding.PaddingTop = UDim.new(0, compact and 6 or 12)
        navPadding.PaddingBottom = UDim.new(0, compact and 6 or 12)
        if narrow then
            nav.Position = UDim2.fromOffset(0, headerHeight); nav.Size = UDim2.new(1, 0, 0, navHeight)
            navList.FillDirection = Enum.FillDirection.Horizontal
            nav.AutomaticCanvasSize = Enum.AutomaticSize.X; nav.ScrollingDirection = Enum.ScrollingDirection.X
            body.Position = UDim2.fromOffset(0, headerHeight + navHeight)
            body.Size = UDim2.new(1, 0, 1, -(headerHeight + navHeight + 20))
        else
            nav.Position = UDim2.fromOffset(0, headerHeight); nav.Size = UDim2.new(0, 170, 1, -(headerHeight + 32))
            navList.FillDirection = Enum.FillDirection.Vertical
            nav.AutomaticCanvasSize = Enum.AutomaticSize.Y; nav.ScrollingDirection = Enum.ScrollingDirection.Y
            body.Position = UDim2.fromOffset(170, headerHeight); body.Size = UDim2.new(1, -170, 1, -(headerHeight + 20))
        end
        nav.CanvasSize = UDim2.new()
        for _, tab in ipairs(self.Tabs) do tab.Button.Size = narrow and UDim2.fromOffset(130, compact and 44 or 38) or UDim2.new(1, 0, 0, 44) end
        self.Notices.Size = UDim2.fromOffset(math.min(300, width - 12), math.min(366, height - 12))
        main.Position = UDim2.fromScale(0.5, 0.5)
    end
    self:_connect(self.Gui:GetPropertyChangedSignal("AbsoluteSize"), resize)
    resize()
    self:_connect(header.InputBegan, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            self.Drag = {Input = input, Start = input.Position, Position = main.Position}
        end
    end)
    self:_connect(UIS.InputChanged, function(input)
        local touch = input.UserInputType == Enum.UserInputType.Touch
        local mouse = input.UserInputType == Enum.UserInputType.MouseMovement
        if launcherDrag and ((touch and input == launcherDrag.Input) or (mouse and launcherDrag.Input.UserInputType == Enum.UserInputType.MouseButton1)) then
            local delta = Vector2.new(input.Position.X - launcherDrag.Start.X, input.Position.Y - launcherDrag.Start.Y)
            if launcherDrag.Moved or delta.Magnitude >= 6 then
                launcherDrag.Moved = true
                suppressLauncherClick = true
                moveLauncher(launcherDrag.Origin.X + delta.X, launcherDrag.Origin.Y + delta.Y)
            end
        end
        if self.Drag and ((touch and input == self.Drag.Input) or (mouse and self.Drag.Input.UserInputType == Enum.UserInputType.MouseButton1)) then
            local d = input.Position - self.Drag.Start
            local p = self.Drag.Position
            local v = self.Gui.AbsoluteSize
            local centerX = math.clamp(p.X.Scale * v.X + p.X.Offset + d.X, main.AbsoluteSize.X / 2, v.X - main.AbsoluteSize.X / 2)
            local centerY = math.clamp(p.Y.Scale * v.Y + p.Y.Offset + d.Y, main.AbsoluteSize.Y / 2, v.Y - main.AbsoluteSize.Y / 2)
            main.Position = UDim2.fromOffset(centerX, centerY)
        end
        local drag = self.SliderDrag
        if drag and ((touch and input == drag.Input) or (mouse and drag.Input.UserInputType == Enum.UserInputType.MouseButton1)) then drag.Update(input.Position.X) end
    end)
    self:_connect(UIS.InputEnded, function(input)
        if launcherDrag and input == launcherDrag.Input then
            suppressLauncherClick = launcherDrag.Moved
            launcherDrag = nil
        end
        if self.Drag and input == self.Drag.Input then self.Drag = nil end
        if self.SliderDrag and input == self.SliderDrag.Input then self.SliderDrag = nil end
    end)
    self:_connect(UIS.InputBegan, function(input, processed)
        if self.Capturing then
            if input.UserInputType ~= Enum.UserInputType.Keyboard then return end
            local control = self.Capturing
            self.Capturing = nil
            if input.KeyCode ~= Enum.KeyCode.Escape and input.KeyCode ~= Enum.KeyCode.Unknown then control:Set(input.KeyCode) else control.Render(control.Value) end
            return
        end
        if processed or UIS:GetFocusedTextBox() then return end
        if input.KeyCode.Name == self.ToggleKey then self:SetVisible(not self.Gui.Enabled); return end
        if not self.Gui.Enabled or self.Minimized then return end
        for _, control in ipairs(self.Keybinds) do
            if input.KeyCode.Name == control.Value then self:_callback(control.Callback, control.Value) end
        end
    end)
    return self
end

function Window:CreateTab(name)
    assert(not self.Destroyed, "Window has been destroyed")
    if type(name) == "table" then name = name.Name end
    name = tostring(name or "Tab")
    local tab = setmetatable({Window = self, Name = name, Rows = {}}, Tab)
    local order = #self.Tabs + 1
    tab.Button = button(self.Navigation, string.format("%02d   %s", order, name), {Name = "Tab_" .. name,
        Size = self.Narrow and UDim2.fromOffset(130, 38) or UDim2.new(1, 0, 0, 44),
        BackgroundTransparency = 1, TextColor3 = Theme.Muted, TextXAlignment = Enum.TextXAlignment.Left, LayoutOrder = order})
    pad(tab.Button, 10)
    tab.Page = make("ScrollingFrame", {Name = "Page_" .. name, BackgroundTransparency = 1, BorderSizePixel = 0,
        Size = UDim2.fromScale(1, 1), CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollingDirection = Enum.ScrollingDirection.Y, ScrollBarThickness = 3,
        ScrollBarImageColor3 = self.Accent, Visible = false}, self.Pages)
    make("UIPadding", {PaddingBottom = UDim.new(0, 6), PaddingRight = UDim.new(0, 6), PaddingLeft = UDim.new(0, 1), PaddingTop = UDim.new(0, 1)}, tab.Page)
    list(tab.Page, 9)
    table.insert(self.Tabs, tab)
    self:_connect(tab.Button.Activated, function() tab:Select() end)
    if order == 1 then tab:Select() end
    return tab
end
function Tab:Select()
    local window = self.Window
    assert(not window.Destroyed, "Window has been destroyed")
    window:_cancelCapture()
    window.SelectedTab = self
    window.PageTitle.Text = self.Name
    for _, tab in ipairs(window.Tabs) do
        local selected = tab == self
        tab.Page.Visible = selected
        tab.Button.BackgroundTransparency = selected and 0 or 1
        tab.Button.BackgroundColor3 = Theme.Raised
        tab.Button.TextColor3 = selected and window.Accent or Theme.Muted
    end
end
function Tab:_filter()
    for _, row in ipairs(self.Rows) do
        row.Frame.Visible = self.Window.Query == "" or string.find(row.Search, self.Window.Query, 1, true) ~= nil
        if not row.Frame.Visible and self.Window.Capturing and self.Window.Capturing.Instance == row.Frame then self.Window:_cancelCapture() end
    end
end
function Tab:_row(options, height)
    assert(not self.Window.Destroyed, "Window has been destroyed")
    if options.Flag then
        assert(type(options.Flag) == "string" and options.Flag ~= "", "Flag must be a nonempty string")
        assert(not self.Window.Flags[options.Flag], "Duplicate flag: " .. options.Flag)
    end
    local row = make("Frame", {Name = tostring(options.Name or "Control"), BackgroundColor3 = Theme.Surface,
        BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, height or 92), LayoutOrder = #self.Rows + 1}, self.Page)
    corner(row, 9)
    text(row, tostring(options.Name or "Control"), 16, Theme.Text,
        {Position = UDim2.fromOffset(14, 10), Size = UDim2.new(1, -28, 0, 22), Font = Enum.Font.GothamBold})
    if options.Description then
        text(row, tostring(options.Description), 13, Theme.Description,
            {Position = UDim2.fromOffset(14, 33), Size = UDim2.new(1, -28, 0, 18)})
    end
    table.insert(self.Rows, {Frame = row, Search = string.lower(tostring(options.Name or "") .. " " .. tostring(options.Description or ""))})
    self:_filter()
    return row
end
function Tab:_control(options, row, validate, render, initial)
    local window = self.Window
    local c = {Instance = row, Validate = validate, Render = render, Callback = options.Callback}
    function c:Get() return self.Value end
    function c:Set(value, silent)
        assert(not window.Destroyed, "Window has been destroyed")
        value = self.Validate(value)
        local changed = self.Value ~= value
        self.Value = value
        self.Render(value)
        if changed and not silent then window:_callback(self.Callback, value) end
    end
    c:Set(initial, true)
    if options.Flag then window.Flags[options.Flag] = c end
    return c
end
function Tab:CreateSection(name)
    local row = self:_row({Name = tostring(name)}, 36)
    row.BackgroundTransparency = 1
    return row
end
function Tab:CreateParagraph(options)
    local row = self:_row({Name = options.Title or options.Name or "Info"}, 104)
    local content = text(row, tostring(options.Content or ""), 14, Theme.Description, {Position = UDim2.fromOffset(14, 39),
        Size = UDim2.new(1, -28, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
        TextWrapped = true, TextYAlignment = Enum.TextYAlignment.Top, TextTruncate = Enum.TextTruncate.None})
    local function reflow()
        if not self.Window.Destroyed then
            row.Size = UDim2.new(1, 0, 0, math.max(104, 53 + content.AbsoluteSize.Y))
        end
    end
    self.Window:_connect(content:GetPropertyChangedSignal("AbsoluteSize"), reflow)
    reflow()
    return row
end
function Tab:CreateButton(options)
    local row = self:_row(options)
    local b = button(row, options.ButtonText or "Run  →", {Name = "Action", Position = UDim2.new(0, 14, 1, -37),
        Size = UDim2.new(1, -28, 0, 28), TextColor3 = self.Window.Accent})
    self.Window:_connect(b.Activated, function() self.Window:_callback(options.Callback) end)
    return {Instance = row, Fire = function() self.Window:_callback(options.Callback) end}
end
function Tab:CreateToggle(options)
    local window = self.Window
    local row = self:_row(options, 88)
    for _, label in ipairs(row:GetChildren()) do
        if label:IsA("TextLabel") then label.Size = UDim2.new(1, -128, 0, label.Size.Y.Offset) end
    end
    local outline = stroke(row)
    local b = button(row, "", {Name = "Toggle", Position = UDim2.new(1, -92, 0.5, -22),
        Size = UDim2.fromOffset(76, 44), BackgroundTransparency = 1})
    local track = make("Frame", {Name = "Track", BorderSizePixel = 0, BackgroundColor3 = Theme.Raised,
        Position = UDim2.fromOffset(0, 5), Size = UDim2.fromOffset(76, 34)}, b)
    corner(track, 17)
    local trackBorder = stroke(track)
    local stateText = text(track, "", 9, Theme.Muted, {Name = "State", Position = UDim2.fromOffset(32, 7),
        Size = UDim2.fromOffset(38, 20), TextXAlignment = Enum.TextXAlignment.Center, Font = Enum.Font.GothamBold})
    local dot = make("Frame", {Name = "Knob", BorderSizePixel = 0, BackgroundColor3 = Theme.Text,
        Position = UDim2.fromOffset(4, 4), Size = UDim2.fromOffset(26, 26), ZIndex = 2}, track)
    corner(dot, 13)
    local knobBorder = stroke(dot)
    knobBorder.Transparency = 0.8
    local check = make("Frame", {Name = "OnIcon", BackgroundTransparency = 1,
        Position = UDim2.fromOffset(6, 6), Size = UDim2.fromOffset(14, 14), ZIndex = 3}, dot)
    for i, segment in ipairs({{4, 8, 5, 45}, {9, 6, 9, -45}}) do
        local line = make("Frame", {Name = "Line" .. i, BorderSizePixel = 0, BackgroundColor3 = Theme.Background,
            AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(segment[1], segment[2]),
            Size = UDim2.fromOffset(segment[3], 2), Rotation = segment[4], ZIndex = 3}, check)
        corner(line, 1)
    end
    local offIcon = make("Frame", {Name = "OffIcon", BorderSizePixel = 0, BackgroundColor3 = Theme.Muted,
        Position = UDim2.fromOffset(9, 12), Size = UDim2.fromOffset(8, 2), ZIndex = 3}, dot)
    corner(offIcon, 1)
    local status = text(row, "", 10, Theme.Muted, {Name = "Status", Position = UDim2.new(0, 14, 1, -26), Size = UDim2.new(1, -128, 0, 16)})
    local current, hovered, focused = false, false, false
    local function paintBorder()
        window:_tween(outline, {Color = (current or hovered or focused) and window.Accent or Theme.Border,
            Transparency = (hovered or focused) and 0.15 or (current and 0.65 or 0.7)})
    end
    local c = self:_control(options, row, function(v) assert(type(v) == "boolean", "Toggle expects boolean"); return v end,
        function(v)
            current = v
            status.Text = v and "Enabled" or "Disabled"
            status.TextColor3 = v and window.Accent or Theme.Muted
            stateText.Text = v and "ON" or "OFF"
            stateText.Position = UDim2.fromOffset(v and 4 or 32, 7)
            stateText.TextColor3 = v and Theme.Background or Theme.Muted
            check.Visible = v; offIcon.Visible = not v
            window:_tween(track, {BackgroundColor3 = v and window.Accent or Theme.Background})
            window:_tween(trackBorder, {Color = v and window.Accent or Theme.Border})
            window:_tween(dot, {Position = UDim2.fromOffset(v and 46 or 4, 4), BackgroundColor3 = v and Theme.Text or Color3.fromRGB(187, 190, 208)})
            paintBorder()
        end, options.CurrentValue == true)
    window:_connect(b.Activated, function() c:Set(not c:Get()) end)
    window:_connect(b.MouseEnter, function() hovered = true; paintBorder() end)
    window:_connect(b.MouseLeave, function() hovered = false; paintBorder() end)
    window:_connect(b.SelectionGained, function() focused = true; paintBorder() end)
    window:_connect(b.SelectionLost, function() focused = false; paintBorder() end)
    return c
end
function Tab:CreateSlider(options)
    local range = options.Range or {0, 100}
    local lo, hi = range[1], range[2]
    local step = options.Increment or 1
    assert(finite(lo) and finite(hi) and hi > lo and finite(step) and step > 0, "Invalid slider range or increment")
    assert(finite(options.CurrentValue or lo), "Slider expects a finite initial value")
    local row = self:_row(options, 108)
    local valueLabel = text(row, "", 11, self.Window.Accent,
        {Position = UDim2.new(0, 14, 1, -53), Size = UDim2.new(1, -28, 0, 18)})
    local track = button(row, "", {Name = "Slider", BackgroundTransparency = 1, Position = UDim2.new(0, 14, 1, -35), Size = UDim2.new(1, -28, 0, 30)})
    local rail = make("Frame", {BackgroundColor3 = Theme.Raised, BorderSizePixel = 0, Position = UDim2.new(0, 0, 0.5, -3), Size = UDim2.new(1, 0, 0, 6)}, track)
    corner(rail, 3)
    local fill = make("Frame", {BackgroundColor3 = self.Window.Accent, BorderSizePixel = 0, Size = UDim2.fromScale(0, 1)}, rail)
    corner(fill, 3)
    local knob = make("Frame", {BackgroundColor3 = Theme.Text, BorderSizePixel = 0, AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0, 0.5), Size = UDim2.fromOffset(12, 12)}, rail)
    corner(knob, 6)
    local c = self:_control(options, row, function(v)
        assert(finite(v), "Slider expects a finite number")
        local snapped = lo + math.floor((math.clamp(v, lo, hi) - lo) / step + 0.5) * step
        local rounded = tonumber(string.format("%.9f", snapped))
        assert(rounded ~= nil, "Slider rounding failed")
        return math.clamp(rounded, lo, hi)
    end, function(v)
        local alpha = (v - lo) / (hi - lo)
        fill.Size = UDim2.fromScale(alpha, 1); knob.Position = UDim2.fromScale(alpha, 0.5)
        valueLabel.Text = tostring(v) .. (options.Suffix and " " .. options.Suffix or "")
    end, options.CurrentValue or lo)
    local function update(x)
        if track.AbsoluteSize.X > 0 then c:Set(lo + math.clamp((x - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1) * (hi - lo)) end
    end
    self.Window:_connect(track.InputBegan, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            self.Window.SliderDrag = {Input = input, Update = update}; update(input.Position.X)
        end
    end)
    self.Window:_connect(track.InputBegan, function(input)
        if input.KeyCode == Enum.KeyCode.Left or input.KeyCode == Enum.KeyCode.DPadLeft then c:Set(c:Get() - step) end
        if input.KeyCode == Enum.KeyCode.Right or input.KeyCode == Enum.KeyCode.DPadRight then c:Set(c:Get() + step) end
    end)
    return c
end
function Tab:CreateDropdown(options)
    local choices = table.clone(options.Options or {})
    assert(#choices > 0, "Dropdown requires at least one option")
    local found = {}
    for _, value in ipairs(choices) do
        assert(type(value) == "string" and not found[value], "Options must be unique strings")
        found[value] = true
    end
    assert(found[options.CurrentOption or choices[1]], "Unknown initial dropdown option")
    local window = self.Window
    local row = self:_row(options, 110)
    row.ClipsDescendants = true
    local outline = stroke(row)
    outline.Transparency = 0.55
    local b = button(row, "", {Name = "Dropdown", Position = UDim2.fromOffset(14, 54),
        Size = UDim2.new(1, -28, 0, 44), BackgroundColor3 = Theme.Background,
        TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd})
    make("UIPadding", {PaddingLeft = UDim.new(0, 14), PaddingRight = UDim.new(0, 48)}, b)
    local selectorBorder = stroke(b)
    local arrow = make("Frame", {Name = "Chevron", BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(1, 28, 0.5, 0), Size = UDim2.fromOffset(14, 14)}, b)
    -- Draw the chevron with native geometry so no font glyph or asset is needed.
    for i, rotation in ipairs({45, -45}) do
        local line = make("Frame", {Name = "Line" .. i, BorderSizePixel = 0, BackgroundColor3 = Theme.Muted,
            AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(i == 1 and 4 or 9, 7),
            Size = UDim2.fromOffset(8, 2), Rotation = rotation}, arrow)
        corner(line, 1)
    end
    local panelHeight = math.min(#choices * 48 + 8, 200)
    local panel = make("ScrollingFrame", {Name = "Options", BackgroundColor3 = Theme.Background, BorderSizePixel = 0,
        Position = UDim2.fromOffset(14, 106), Size = UDim2.new(1, -28, 0, panelHeight),
        Visible = false, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollingDirection = Enum.ScrollingDirection.Y, ScrollBarThickness = 3,
        ScrollBarImageColor3 = window.Accent, ClipsDescendants = true}, row)
    corner(panel, 8); stroke(panel); pad(panel, 6); list(panel, 4)
    local expanded, hovered = false, false
    local entries = {}
    local c
    local function selectorStyle()
        window:_tween(selectorBorder, {Color = (expanded or hovered) and window.Accent or Theme.Border})
        window:_tween(outline, {Color = expanded and window.Accent or Theme.Border, Transparency = expanded and 0.35 or 0.55})
    end
    local function paint(entry)
        local selected = c and c.Value == entry.Value
        local active = entry.Hovered or entry.Focused
        window:_tween(entry.Button, {BackgroundColor3 = selected and Theme.Raised:Lerp(window.Accent, 0.17) or Theme.Raised,
            BackgroundTransparency = selected and 0 or (active and 0.35 or 1), TextColor3 = selected and window.Accent or Theme.Text})
        entry.Mark.Visible = selected == true
    end
    local function expand(value)
        expanded = value
        panel.Visible = value
        b:SetAttribute("Expanded", value)
        window:_tween(row, {Size = UDim2.new(1, 0, 0, value and 118 + panelHeight or 110)})
        window:_tween(arrow, {Rotation = value and 180 or 0})
        selectorStyle()
    end
    c = self:_control(options, row, function(v) assert(found[v], "Unknown dropdown option"); return v end,
        function(v)
            b.Text = v
            for _, entry in ipairs(entries) do paint(entry) end
        end, options.CurrentOption or choices[1])
    for i, value in ipairs(choices) do
        local option = button(panel, value, {Name = "Option_" .. i, LayoutOrder = i,
            Size = UDim2.new(1, -4, 0, 44), BackgroundTransparency = 1,
            TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd})
        make("UIPadding", {PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 38)}, option)
        local mark = make("Frame", {Name = "Selected", BorderSizePixel = 0, BackgroundColor3 = window.Accent,
            AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 24, 0.5, 0), Size = UDim2.fromOffset(20, 20)}, option)
        corner(mark, 6)
        for j, segment in ipairs({{7, 11, 5, 45}, {12, 9, 9, -45}}) do
            local line = make("Frame", {Name = "Check" .. j, BorderSizePixel = 0, BackgroundColor3 = Theme.Background,
                AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(segment[1], segment[2]),
                Size = UDim2.fromOffset(segment[3], 2), Rotation = segment[4]}, mark)
            corner(line, 1)
        end
        local entry = {Button = option, Mark = mark, Value = value, Hovered = false, Focused = false}
        table.insert(entries, entry)
        window:_connect(option.MouseEnter, function() entry.Hovered = true; paint(entry) end)
        window:_connect(option.MouseLeave, function() entry.Hovered = false; paint(entry) end)
        window:_connect(option.SelectionGained, function() entry.Focused = true; paint(entry) end)
        window:_connect(option.SelectionLost, function() entry.Focused = false; paint(entry) end)
        window:_connect(option.Activated, function() c:Set(value); expand(false) end)
        paint(entry)
    end
    window:_connect(b.MouseEnter, function() hovered = true; selectorStyle() end)
    window:_connect(b.MouseLeave, function() hovered = false; selectorStyle() end)
    window:_connect(b.SelectionGained, function() hovered = true; selectorStyle() end)
    window:_connect(b.SelectionLost, function() hovered = false; selectorStyle() end)
    window:_connect(b.Activated, function() expand(not expanded) end)
    return c
end
function Tab:CreateInput(options)
    local maxLength = options.MaxLength or 256
    assert(finite(maxLength) and maxLength >= 1 and maxLength % 1 == 0, "MaxLength must be a positive integer")
    local function validate(v)
        assert(type(v) == "string" and utf8.len(v) ~= nil, "Input expects valid UTF-8 text")
        local cutoff = utf8.offset(v, maxLength + 1)
        return cutoff and string.sub(v, 1, cutoff - 1) or v
    end
    local initial = validate(options.CurrentValue or "")
    local row = self:_row(options)
    local box = make("TextBox", {Name = "Input", Text = "", PlaceholderText = options.PlaceholderText or "Type here…",
        Position = UDim2.fromOffset(14, 55), Size = UDim2.new(1, -28, 0, 28), BackgroundColor3 = Theme.Raised,
        BorderSizePixel = 0, TextColor3 = Theme.Text, PlaceholderColor3 = Theme.Muted, Font = Enum.Font.GothamMedium,
        TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left, ClearTextOnFocus = false}, row)
    corner(box, 7); pad(box, 7)
    local c = self:_control(options, row, validate, function(v) box.Text = v end, initial)
    self.Window:_connect(box.FocusLost, function() c:Set(box.Text) end)
    return c
end
function Tab:CreateKeybind(options)
    local initial = keyName(options.CurrentKeybind or "K")
    local row = self:_row(options)
    local b = button(row, "", {Name = "Keybind", Position = UDim2.fromOffset(14, 55), Size = UDim2.new(1, -28, 0, 28), TextColor3 = self.Window.Accent})
    local c = self:_control(options, row, keyName, function(v) b.Text = "[ " .. v .. " ]   Change key" end, initial)
    -- Binding changes do not invoke the action callback; pressing the bound key does.
    function c:Set(value)
        assert(not self.Window.Destroyed, "Window has been destroyed")
        self.Value = self.Validate(value); self.Render(self.Value)
    end
    c.Window = self.Window
    c.ActionOnly = true
    self.Window:_connect(b.Activated, function()
        if self.Window.Capturing then self.Window.Capturing.Render(self.Window.Capturing.Value) end
        self.Window.Capturing = c; b.Text = "Press a key…  (Esc to cancel)"
    end)
    table.insert(self.Window.Keybinds, c)
    return c
end

return Library

end)()

local window = UI:CreateWindow({
    Name = "ASTRA",
    Subtitle = "INTERFACE LIBRARY  /  01",
    Accent = Color3.fromRGB(158, 127, 255),
    ToggleKey = "RightShift",
})

local home = window:CreateTab("Home")
home:CreateParagraph({
    Title = "A space for your ideas.",
    Content = "A lightweight Luau interface library. Explore the controls, connect your callbacks, and build your own panel.",
})
home:CreateSection("TRY THE CONTROLS")
home:CreateToggle({
    Name = "Notifications",
    Description = "A toggle with state and a callback.",
    Flag = "notifications",
    CurrentValue = true,
    Callback = function(value)
        window:Notify({Title = "Preference updated", Content = value and "Notifications enabled." or "Notifications disabled."})
    end,
})
home:CreateSlider({
    Name = "Intensity",
    Description = "Drag the slider or use arrow keys when selected.",
    Flag = "intensity", Range = {0, 100}, Increment = 5, CurrentValue = 65, Suffix = "%",
})
home:CreateButton({
    Name = "A little signal",
    Description = "Display a sample notification.",
    ButtonText = "Test notification  →",
    Callback = function()
        window:Notify({Title = "All connected", Content = "This button ran its callback successfully."})
    end,
})

local components = window:CreateTab("Components")
components:CreateSection("SELECTION & INPUT")
components:CreateDropdown({
    Name = "Profile", Description = "Choose an option from the list.",
    Flag = "profile", Options = {"Balanced", "Creative", "Minimal"}, CurrentOption = "Balanced",
    Callback = function(value) window:Notify({Title = "Profile", Content = value}) end,
})
components:CreateInput({
    Name = "Project name", Description = "Changes are confirmed when the field loses focus.",
    Flag = "project", CurrentValue = "My project", PlaceholderText = "Give it a name…", MaxLength = 60,
})
components:CreateKeybind({
    Name = "Test shortcut", Description = "Press K to try it; click to assign a different key.",
    Flag = "shortcut", CurrentKeybind = "K",
    Callback = function(key) window:Notify({Title = "Shortcut triggered", Content = "Key: " .. key}) end,
})

local settings = window:CreateTab("Settings")
settings:CreateParagraph({Title = "Make it yours.", Content = "-/+ folds and restores the window. X hides the menu. A and RightShift open or close it. Drag the header to move the window."})
local saved
settings:CreateButton({
    Name = "Save configuration", Description = "Keep a JSON copy in memory for this session.", ButtonText = "Save a copy  →",
    Callback = function()
        saved = window:ExportConfig()
        window:Notify({Title = "Copy saved", Content = "Values for all flagged controls have been saved."})
    end,
})
settings:CreateButton({
    Name = "Restore configuration", Description = "Restore values from the latest copy in this session.", ButtonText = "Restore copy  →",
    Callback = function()
        if saved then
            window:ImportConfig(saved)
            window:Notify({Title = "Copy restored", Content = "The controls have returned to their saved values."})
        else
            window:Notify({Title = "No saved copy yet", Content = "Save a configuration first."})
        end
    end,
})
settings:CreateButton({Name = "Unload interface", Description = "Destroy the window and disconnect its events.", ButtonText = "Close and clean up",
    Callback = function() window:Destroy() end})

-- Optional handle for integration; remove the existing window before re-running.
return window

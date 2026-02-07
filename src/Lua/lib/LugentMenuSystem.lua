-- Key constants
rawset(_G, "KEY_UP", 230)
rawset(_G, "KEY_DOWN", 238)
rawset(_G, "KEY_LEFT", 233)
rawset(_G, "KEY_RIGHT", 235)
rawset(_G, "KEY_ESC", 27)
rawset(_G, "KEY_ENTER", 13)
rawset(_G, "KEY_CONSOLE", 96)

rawset(_G, "LugentMenu", {
	Version = "v2.0.1", -- version, just to display on load
	Active = false, -- if active
	Current = -1, -- current menu table
	Cursor = -1, -- the actual cursor item position
	Page = -1, -- the actual page on the menu
	TextInput = "",
	InputActive = false,
	ShiftOn = false
})

local MENU = LugentMenu
function MENU:IsActive()
	return self.Active and (self.Current ~= -1) and (gamestate == GS_LEVEL)
end

function MENU:Reset()
	self.Active = false
	self.Current = -1
	self.Cursor = -1
	self.Page = -1
	self.TextInput = ""
	self.InputActive = false
	self.ShiftOn = false
end

function MENU:Update()
	if not self:IsActive() then return end
	
	local entries = self.Current[MENU.Page].entries
	for index, entry in ipairs(entries) do
		if (entry.input ~= nil) and entry.cvar then
			entry.input = entry.cvar.string
		end
		
		if (entry.color ~= nil) and entry.cvar then
			local fallback = entry.color
			entry.color = R_GetColorByName(entry.cvar.string) or fallback
		end
	end
end

function MENU:CloseMenu()
	if not self:IsActive() then return end
	input.setMouseGrab(true)
	input.ignoregameinputs = false
	self:Reset()
end

function MENU:OpenMenu(menu, page)
	if (menu == nil) then
		CONS_Printf(consoleplayer, "MENU.OpenMenu(): Tried to open an non-existant menu.")
		return
	end

	if (page < 1) and (page > #menu) then
		CONS_Printf(consoleplayer, "MENU.OpenMenu(): Tried to open a menu with specified page out of bounds.")
		return
	end
	
	self.Active = true
	self.Page = page
	self.Current = menu
	self.Cursor = self.Current[self.Page].start_item
	if self.Current[self.Page].on_open then
		self.Current[self.Page].on_open(self.Current, MENU:GetCurrentPage())
	end
	self:Update()
end

function MENU:GetCurrentPage()
	return self.Current[self.Page]
end

function MENU:PrevPage()
	if not self:IsActive() then return end
	
	if (self.Current[self.Page].previous_page < 1) then
		if self.Current[self.Page].on_close and self.Current[self.Page].on_close(self.Current) then
			return
		end
		self:CloseMenu()
		return
	end
	
	self.Cursor = self.Current[self.Page].previous_item
	self.Page = self.Current[self.Page].previous_page
	if self.Current[self.Page].on_previous_page then
		self.Current[self.Page].on_previous_page(self.Current, MENU:GetCurrentPage())
	end
	self:Update()
end

function MENU:GoToPage(page)
	if not self:IsActive() then return end
	
	if (page < 1) or (page > #self.Current) then
		CONS_Printf(consoleplayer, "MENU.GoToPage(): Tried to go out of bounds.")
		return
	end
	
	self.Page = page
	self.Cursor = self.Current[self.Page].start_item
	if self.Current[self.Page].on_page then
		self.Current[self.Page].on_page(self.Current, page)
	end
	self:Update()
end

function MENU:ExecuteThinker()
	if not self:IsActive() then return end
	if not self.Current[self.Page] then return end
	
	local page = self.Current[self.Page]
	for index, entry in ipairs(page.entries) do
		if (entry.player ~= nil) then
			if not players[entry.player] then			
				entry.player = $ - 1
				if (entry.player < 0) then
					entry.player = #players - 1
				end
				
				while not players[entry.player] do
					entry.player = $ - 1
					if (entry.player < 0) then
						entry.player = #players - 1
					end
				end
			end
		end
	end
	
	if page.thinker then
		page.thinker(self.Current, page)
	end
end

function MENU:PressedKey(keyevent, code)
	return (keyevent.num == code)
end

local ShiftedKeys = {
    ["`"] = "~",
    ["1"] = "!",
    ["2"] = "@",
    ["3"] = "#",
    ["4"] = "$",
    ["5"] = "%",
    ["6"] = "^",
    ["7"] = "&",
    ["8"] = "*",
    ["9"] = "(",
    ["0"] = ")",
    ["-"] = "_",
    ["="] = "+",
    ["["] = "{",
    ["]"] = "}",
    ["'"] = "\"",
    ["\\"] = "|",
    [","] = "<",
    ["."] = ">",
    ["/"] = "?",
}
function MENU:KeyToCharacter(key, shifted)
    if (key.num >= input.keyNameToNum("a")) and (key.num <= input.keyNameToNum("z")) then
        return shifted and key.name:upper() or key.name
    elseif ShiftedKeys[key.name] then
        return shifted and ShiftedKeys[key.name] or key.name
    elseif (key.name == "space") then
        return " "
    else
        return nil
    end
end

addHook("PreThinkFrame", do
	if not MENU:IsActive() then return end
	
	input.setMouseGrab(false)
	input.ignoregameinputs = true
	MENU:ExecuteThinker()
end)

addHook("KeyUp", function(keyevent)
	if not MENU:IsActive() then return end
	if MENU:PressedKey(keyevent, KEY_CONSOLE) then return end
	
	local page = MENU.Current[MENU.Page]
	local entry = page.entries[MENU.Cursor]
	if (entry.input ~= nil) then
		if MENU.InputActive then
			if (keyevent.name == "lshift") or (keyevent.name == "rshift") then
				MENU.ShiftOn = false
			end
		end	
	end
end)

addHook("KeyDown", function(keyevent)
	if not MENU:IsActive() then return end
	if MENU:PressedKey(keyevent, KEY_CONSOLE) then return end
	
	if MENU:PressedKey(keyevent, KEY_ESC) then
		if MENU.InputActive then
			MENU.InputActive = false
			return true
		end
		MENU:PrevPage()
		return true
	end
	
	local page = MENU.Current[MENU.Page]
	local entry = page.entries[MENU.Cursor]
	if (entry.input ~= nil) then
		if MENU:PressedKey(keyevent, KEY_ENTER) and not MENU.InputActive then
			if entry.cvar then
				entry.input = entry.cvar.string
			end
		
			MENU.TextInput = entry.input
			MENU.InputActive = true
			S_StartSound(nil, sfx_menu1, consoleplayer)
			return true
		elseif MENU.InputActive then
			if MENU:PressedKey(keyevent, KEY_ENTER) then
				entry.input = MENU.TextInput
				MENU.InputActive = false
				if entry.cvar then
					COM_BufInsertText(consoleplayer, entry.cvar.name .. " " .. '"' .. entry.input ..  '"')
				end
				
				if entry.action then
					entry.action(MENU.Current, entry, page)
				end
				
				S_StartSound(nil, sfx_menu1, consoleplayer)
				return true
			end
		
			local keyName = keyevent.name
			local char = MENU:KeyToCharacter(keyevent, MENU.ShiftOn)
			if char then
				MENU.TextInput = $ .. char
			elseif (keyName == "lshift") or (keyName == "rshift") then
				MENU.ShiftOn = true
			elseif (keyName == "backspace") then
				MENU.TextInput = $:sub(1, -2)
			end
			return true
		end
	end
	
	if page.on_keypress and page.on_keypress(keyevent, MENU.Current, entry, page) then
		return true
	end
	
	if MENU:PressedKey(keyevent, KEY_UP) then
		local next_entry = page.entries[MENU.Cursor]
		repeat
			MENU.Cursor = $ - 1
			if not MENU.Cursor then
				MENU.Cursor = #page.entries
			end
			next_entry = page.entries[MENU.Cursor]
		until not next_entry.header and not next_entry.disabled
		S_StartSound(nil, sfx_menu1, consoleplayer)
		return true
	end
	
	if MENU:PressedKey(keyevent, KEY_DOWN) then
		local next_entry = page.entries[MENU.Cursor]
		repeat
			MENU.Cursor = $ + 1
			if MENU.Cursor > #page.entries then
				MENU.Cursor = 1
			end
			next_entry = page.entries[MENU.Cursor]
		until not next_entry.header and not next_entry.disabled
		S_StartSound(nil, sfx_menu1, consoleplayer)
		return true
	end
	
	if MENU:PressedKey(keyevent, KEY_LEFT) then
		if (entry.color ~= nil) then
			entry.color = M_GetColorBefore($)
			if (entry.color < 1) then
				entry.color = M_GetColorBefore(#skincolors - 1)
			end
			
			while not skincolors[entry.color].accessible do
				entry.color = M_GetColorBefore($)
				if (entry.color < 1) then
					entry.color = M_GetColorBefore(#skincolors - 1)
				end
			end
			if (entry.cvar ~= nil) then
				COM_BufInsertText(consoleplayer, entry.cvar.name .. ' "' .. skincolors[entry.color].name .. '"')
			end
			S_StartSound(nil, sfx_menu1, consoleplayer)
		elseif (entry.cvar ~= nil) and (entry.input == nil) then
			local amount = (entry.amount == nil) and "1" or entry.amount
			COM_BufInsertText(consoleplayer, "add " .. entry.cvar.name .. " -" .. amount)
			S_StartSound(nil, sfx_menu1, consoleplayer)
		elseif (entry.range ~= nil) then
			local amount = (entry.amount == nil) and 1 or entry.amount
			entry.value  = $ - amount
			if (entry.value < entry.range[1]) then
				entry.value = entry.range[2]
			end
			S_StartSound(nil, sfx_menu1, consoleplayer)
		elseif (entry.options ~= nil) then
			local options = entry.options
			entry.value  = $ - 1
			if (entry.value <= 0) then
				entry.value = #entry.options
			end
			S_StartSound(nil, sfx_menu1, consoleplayer)
		elseif (entry.player ~= nil) then
			entry.player = $ - 1
			if (entry.player < 0) then
				entry.player = #players - 1
			end
			
			while not players[entry.player] do
				entry.player = $ - 1
				if (entry.player < 0) then
					entry.player = #players - 1
				end
			end
			S_StartSound(nil, sfx_menu1, consoleplayer)
		end
		return true
	end
	
	if MENU:PressedKey(keyevent, KEY_RIGHT) then
		if (entry.color ~= nil) then
			entry.color = M_GetColorAfter($)
			if (entry.color < 1) then
				entry.color = 1
			end
			
			while not skincolors[entry.color].accessible do
				entry.color = M_GetColorAfter($)
				if (entry.color < 1) then
					entry.color = 1
				end
			end
			if (entry.cvar ~= nil) then
				COM_BufInsertText(consoleplayer, entry.cvar.name .. ' "' .. skincolors[entry.color].name .. '"')
			end
			S_StartSound(nil, sfx_menu1, consoleplayer)
		elseif (entry.cvar ~= nil) and (entry.input == nil) then
			local amount = (entry.amount == nil) and "1" or entry.amount
			COM_BufInsertText(consoleplayer, "add " .. entry.cvar.name .. " " .. amount)
			S_StartSound(nil, sfx_menu1, consoleplayer)
		elseif (entry.range ~= nil) then
			local amount = (entry.amount == nil) and 1 or entry.amount
			entry.value  = $ + amount
			if (entry.value > entry.range[2]) then
				entry.value = entry.range[1]
			end
			S_StartSound(nil, sfx_menu1, consoleplayer)
		elseif (entry.options ~= nil) then
			local options = entry.options
			entry.value  = $ + 1
			if (entry.value > #entry.options) then
				entry.value = 1
			end
			S_StartSound(nil, sfx_menu1, consoleplayer)
		elseif (entry.player ~= nil) then
			entry.player = $ + 1
			if (entry.player >= #players) then
				entry.player = 0
			end
			
			while not players[entry.player] do
				entry.player = $ + 1
				if (entry.player >= #players) then
					entry.player = 0
				end
			end
			S_StartSound(nil, sfx_menu1, consoleplayer)
		end
		return true
	end
	
	if MENU:PressedKey(keyevent, KEY_ENTER) then
		if entry.action and entry.action(MENU.Current, entry, page) then
			S_StartSound(nil, sfx_menu1, consoleplayer)
		end
		return true
	end
	return true
end)

function MENU:DrawColorRamp(v, menu, x, y, w, h, skincolor)
	local color = skincolors[skincolor]
	for index = 0, 15, 1 do
		v.drawFill(x, y + (index * h), w, h, color.ramp[index]);
	end
end

function MENU:DrawStandard(v, menu)
	if not menu.no_background then
		v.fadeScreen(31, 5)
	end

	if menu.header_text then
		local color_flag = menu.header_color or 0
		v.drawString(160, 10, menu.header_text, V_ALLOWLOWERCASE|color_flag, "center")
	end

	local cursor_y = 0
	for index, item in ipairs(menu.entries) do
		local selected = (index == MENU.Cursor)
		if selected then
			cursor_y = item.y_pos
		end
		
		if item.invisible then continue end
		if item.header then
			local color_flag = V_YELLOWMAP
			v.drawString(19, menu.y_pos + item.y_pos, item.text, V_ALLOWLOWERCASE|color_flag, left_style)
			v.drawFill(19, (menu.y_pos + item.y_pos) + 9, 281, 1, 73)
			v.drawFill(300, (menu.y_pos + item.y_pos) + 9, 1, 1, 26)
			v.drawFill(19, (menu.y_pos + item.y_pos) + 10, 281, 1, 26)
			continue
		end
		
		local width_type = item.thintext and "thin" or "normal"
		local left_style = item.thintext and "thin" or "left"
		local right_style = item.thintext and "thin-right" or "right"
		local selected_flag = selected and V_YELLOWMAP or 0
		local disabled_flag = item.disabled and V_TRANSLUCENT or 0
		local string_flags = disabled_flag|selected_flag
		v.drawString(menu.x_pos, menu.y_pos + item.y_pos, item.text, V_ALLOWLOWERCASE|string_flags, left_style)
		
		if (item.input ~= nil) then
			local boxwidth = 320 - 2 * (menu.x_pos + 5)
			v.drawFill(menu.x_pos, (menu.y_pos + item.y_pos) + 9, boxwidth, 14, 159)
			
			local text = (MENU.InputActive and selected) and MENU.TextInput or item.input
			v.drawString(menu.x_pos + 8, (menu.y_pos + item.y_pos) + 12, text, V_ALLOWLOWERCASE, "left")
			
			local textWidth = v.stringWidth(text, V_ALLOWLOWERCASE)
			local blinkSpeed = TICRATE / 8
			if MENU.InputActive and selected and (((leveltime / blinkSpeed) % 2) == 0) then -- !!!
				v.drawString(menu.x_pos + 8 + textWidth, (menu.y_pos + item.y_pos) + 12, "_", V_ALLOWLOWERCASE, "left")
			end
			
			if (item.options ~= nil) then
				local option = item.options[item.value]
				v.drawString(320 - menu.x_pos, (menu.y_pos + item.y_pos), option, V_ALLOWLOWERCASE|string_flags, right_style)
				
				if selected and not MENU.InputActive then
					v.drawString((((320 - menu.x_pos) - 10) - v.stringWidth(option, 0, width_type)) - ((leveltime % 9) / 5), (menu.y_pos + item.y_pos), "\x1C", V_YELLOWMAP|V_ALLOWLOWERCASE|string_flags)
					v.drawString(((320 - menu.x_pos) + 2) + ((leveltime % 9) / 5), (menu.y_pos + item.y_pos), "\x1D", V_YELLOWMAP|V_ALLOWLOWERCASE|string_flags)
				end
			end
		elseif (item.color ~= nil) then
			local charw = 74
			local indexwidth = 8
			local boxwidth = 320 - 2 * (menu.x_pos + 5)
			local numcolors = (282 - charw) / (2 * indexwidth)
			local x = menu.x_pos + (numcolors * indexwidth) + indexwidth
			local basecolor = item.color
			if (item.cvar ~= nil) then
				basecolor = R_GetColorByName(item.cvar.string) or item.color
			end
			self:DrawColorRamp(v, menu, x, (menu.y_pos + item.y_pos) + 10, 36, 1, basecolor)
			
			local displaycolor = M_GetColorBefore(basecolor)
			if (displaycolor < 1) then
				displaycolor = M_GetColorBefore(#skincolors - 1)
			end
					
			for index = 0, numcolors, 1 do
				x = $ - indexwidth
				while not skincolors[displaycolor].accessible do
					displaycolor = M_GetColorBefore(displaycolor)
					if (displaycolor < 1) then
						displaycolor = M_GetColorBefore(#skincolors - 1)
					end
				end
				self:DrawColorRamp(v, menu, x, (menu.y_pos + item.y_pos) + 10, indexwidth, 1, displaycolor)
				displaycolor = M_GetColorBefore(displaycolor)
				if (displaycolor < 1) then
					displaycolor = M_GetColorBefore(#skincolors - 1)
				end
			end
			
			x = (numcolors * indexwidth) + charw
			displaycolor = M_GetColorAfter(basecolor)
			if (displaycolor < 1) then
				displaycolor = 1
			end
			
			for index = 0, numcolors, 1 do
				while not skincolors[displaycolor].accessible do
					displaycolor = M_GetColorAfter(displaycolor)
					if (displaycolor < 1) then
						displaycolor = 1
					end
				end
				self:DrawColorRamp(v, menu, x, (menu.y_pos + item.y_pos) + 10, indexwidth, 1, displaycolor)
				x = $ + indexwidth
				displaycolor = M_GetColorAfter(displaycolor)
				if (displaycolor < 1) then
					displaycolor = 1
				end
			end
			
			local colorname = skincolors[basecolor].name
			v.drawString(320 - menu.x_pos, (menu.y_pos + item.y_pos), colorname, V_ALLOWLOWERCASE|string_flags, right_style)
			if selected then
				v.drawString((((320 - menu.x_pos) - 10) - v.stringWidth(colorname, 0, width_type)) - ((leveltime % 9) / 5), (menu.y_pos + item.y_pos), "\x1C", V_YELLOWMAP|V_ALLOWLOWERCASE|string_flags)
				v.drawString(((320 - menu.x_pos) + 2) + ((leveltime % 9) / 5), (menu.y_pos + item.y_pos), "\x1D", V_YELLOWMAP|V_ALLOWLOWERCASE|string_flags)
			end
		elseif (item.cvar ~= nil) then
			v.drawString(320 - menu.x_pos, (menu.y_pos + item.y_pos), item.cvar.string, V_ALLOWLOWERCASE|string_flags, right_style)
			
			if selected then
				v.drawString((((320 - menu.x_pos) - 10) - v.stringWidth(item.cvar.string, 0, width_type)) - ((leveltime % 9) / 5), (menu.y_pos + item.y_pos), "\x1C", V_YELLOWMAP|V_ALLOWLOWERCASE|string_flags)
				v.drawString(((320 - menu.x_pos) + 2) + ((leveltime % 9) / 5), (menu.y_pos + item.y_pos), "\x1D", V_YELLOWMAP|V_ALLOWLOWERCASE|string_flags)
			end
		elseif (item.range ~= nil) then
			local option = item.value
			v.drawString(320 - menu.x_pos, (menu.y_pos + item.y_pos), option, V_ALLOWLOWERCASE|string_flags, right_style)
			
			if selected then
				v.drawString((((320 - menu.x_pos) - 10) - v.stringWidth(option, 0, width_type)) - ((leveltime % 9) / 5), (menu.y_pos + item.y_pos), "\x1C", V_YELLOWMAP|V_ALLOWLOWERCASE|string_flags)
				v.drawString(((320 - menu.x_pos) + 2) + ((leveltime % 9) / 5), (menu.y_pos + item.y_pos), "\x1D", V_YELLOWMAP|V_ALLOWLOWERCASE|string_flags)
			end
		elseif (item.options ~= nil) then
			local option = item.options[item.value]
			v.drawString(320 - menu.x_pos, (menu.y_pos + item.y_pos), option, V_ALLOWLOWERCASE|string_flags, right_style)
			
			if selected then
				v.drawString((((320 - menu.x_pos) - 10) - v.stringWidth(option, 0, width_type)) - ((leveltime % 9) / 5), (menu.y_pos + item.y_pos), "\x1C", V_YELLOWMAP|V_ALLOWLOWERCASE|string_flags)
				v.drawString(((320 - menu.x_pos) + 2) + ((leveltime % 9) / 5), (menu.y_pos + item.y_pos), "\x1D", V_YELLOWMAP|V_ALLOWLOWERCASE|string_flags)
			end
		elseif (item.player ~= nil) then
			local text = players[item.player] and players[item.player].name or "Unknown"
			v.drawString(320 - menu.x_pos, menu.y_pos + item.y_pos, text, V_ALLOWLOWERCASE|string_flags, right_style)
			
			if selected then
				v.drawString((((320 - menu.x_pos) - 10) - v.stringWidth(text, 0, width_type)) - ((leveltime % 9) / 5), menu.y_pos + item.y_pos, "\x1C", V_YELLOWMAP|V_ALLOWLOWERCASE|string_flags)
				v.drawString(((320 - menu.x_pos) + 2) + ((leveltime % 9) / 5), menu.y_pos + item.y_pos, "\x1D", V_YELLOWMAP|V_ALLOWLOWERCASE|string_flags)
			end
		end
	end
	v.drawScaled((menu.x_pos - 24) * FU, (menu.y_pos + cursor_y) * FU, FU, v.cachePatch("M_CURSOR"))
end

local scrollareaheight = 88
function MENU:DrawScroll(v, menu)
	if not menu.no_background then
		v.fadeScreen(31, 5)
	end

	if menu.header_text then
		local color_flag = menu.header_color or 0
		v.drawString(160, 10, menu.header_text, V_ALLOWLOWERCASE|color_flag, "center")
	end

	local arrow_up, arrow_down = false, false
	if (menu.entries[#menu.entries].y_pos > scrollareaheight) then
		arrow_up, arrow_down = false, true
	end
	
	local offset_y = 0
	if (menu.entries[MENU.Cursor].y_pos >= scrollareaheight) then
		arrow_up, arrow_down = true, true
		offset_y = menu.entries[MENU.Cursor].y_pos - scrollareaheight
		if (((menu.entries[#menu.entries].y_pos + menu.y_pos) - offset_y) <= (scrollareaheight * 2)) then
			arrow_up, arrow_down = true, false
			offset_y = (menu.entries[#menu.entries].y_pos + menu.y_pos) - (scrollareaheight * 2)
		end
	end
	
	if arrow_up then
		v.drawString(menu.x_pos - 20, menu.y_pos - ((leveltime % 9) / 5), "\x1A", V_YELLOWMAP)
	end
	
	if arrow_down then
		v.drawString(menu.x_pos - 20, ((scrollareaheight * 2)) + ((leveltime % 9) / 5), "\x1B", V_YELLOWMAP)
	end

	local cursor_y = 0
	for index, item in ipairs(menu.entries) do
		local selected = (index == MENU.Cursor)
		if selected then
			cursor_y = item.y_pos - offset_y
		end
	
		if (((item.y_pos + menu.y_pos) - offset_y) < menu.y_pos) or (((item.y_pos + menu.y_pos) - offset_y) > (scrollareaheight * 2)) then
			continue
		end
		
		local string_position = (menu.y_pos + item.y_pos) - offset_y
		if item.invisible then continue end
		if item.header then
			local color_flag = V_YELLOWMAP
			v.drawString(19, string_position, item.text, V_ALLOWLOWERCASE|color_flag, left_style)
			v.drawFill(19, string_position + 9, 281, 1, 73);
			v.drawFill(300, string_position + 9, 1, 1, 26);
			v.drawFill(19, string_position + 10, 281, 1, 26);
			continue
		end
		
		local width_type = item.thintext and "thin" or "normal"
		local left_style = item.thintext and "thin" or "left"
		local right_style = item.thintext and "thin-right" or "right"
		local selected_flag = selected and V_YELLOWMAP or 0
		local disabled_flag = item.disabled and V_TRANSLUCENT or 0
		local string_flags = disabled_flag|selected_flag
		v.drawString(menu.x_pos, string_position, item.text, V_ALLOWLOWERCASE|string_flags, left_style)
		
		if (item.input ~= nil) then
			local boxwidth = 320 - 2 * (menu.x_pos + 5)
			v.drawFill(menu.x_pos, string_position + 9, boxwidth, 14, 159)
			
			local text = (MENU.InputActive and selected) and MENU.TextInput or item.input
			v.drawString(menu.x_pos + 8, string_position + 12, text, V_ALLOWLOWERCASE, "left")
			
			local textWidth = v.stringWidth(text, V_ALLOWLOWERCASE)
			local blinkSpeed = TICRATE / 8
			if MENU.InputActive and selected and (((leveltime / blinkSpeed) % 2) == 0) then -- !!!
				v.drawString(menu.x_pos + 8 + textWidth, string_position + 12, "_", V_ALLOWLOWERCASE, "left")
			end
			
			if (item.options ~= nil) then
				local option = item.options[item.value]
				v.drawString(320 - menu.x_pos, string_position, option, V_ALLOWLOWERCASE|string_flags, right_style)
				
				if selected and not MENU.InputActive then
					v.drawString((((320 - menu.x_pos) - 10) - v.stringWidth(option, 0, width_type)) - ((leveltime % 9) / 5), string_position, "\x1C", V_YELLOWMAP|V_ALLOWLOWERCASE|string_flags)
					v.drawString(((320 - menu.x_pos) + 2) + ((leveltime % 9) / 5), string_position, "\x1D", V_YELLOWMAP|V_ALLOWLOWERCASE|string_flags)
				end
			end
		elseif (item.color ~= nil) then
			local charw = 74
			local indexwidth = 8
			local boxwidth = 320 - 2 * (menu.x_pos + 5)
			local numcolors = (282 - charw) / (2 * indexwidth)
			local x = menu.x_pos + (numcolors * indexwidth) + indexwidth
			local basecolor = item.color
			if (item.cvar ~= nil) then
				basecolor = R_GetColorByName(item.cvar.string) or item.color
			end
			self:DrawColorRamp(v, menu, x, string_position + 10, 36, 1, basecolor)
			
			local displaycolor = M_GetColorBefore(basecolor)
			if (displaycolor < 1) then
				displaycolor = M_GetColorBefore(#skincolors - 1)
			end
					
			for index = 0, numcolors, 1 do
				x = $ - indexwidth
				while not skincolors[displaycolor].accessible do
					displaycolor = M_GetColorBefore(displaycolor)
					if (displaycolor < 1) then
						displaycolor = M_GetColorBefore(#skincolors - 1)
					end
				end
				self:DrawColorRamp(v, menu, x, string_position + 10, indexwidth, 1, displaycolor)
				displaycolor = M_GetColorBefore(displaycolor)
				if (displaycolor < 1) then
					displaycolor = M_GetColorBefore(#skincolors - 1)
				end
			end
			
			x = (numcolors * indexwidth) + charw
			displaycolor = M_GetColorAfter(basecolor)
			if (displaycolor < 1) then
				displaycolor = 1
			end
			
			for index = 0, numcolors, 1 do
				while not skincolors[displaycolor].accessible do
					displaycolor = M_GetColorAfter(displaycolor)
					if (displaycolor < 1) then
						displaycolor = 1
					end
				end
				self:DrawColorRamp(v, menu, x, string_position + 10, indexwidth, 1, displaycolor)
				x = $ + indexwidth
				displaycolor = M_GetColorAfter(displaycolor)
				if (displaycolor < 1) then
					displaycolor = 1
				end
			end
			
			local colorname = skincolors[basecolor].name
			v.drawString(320 - menu.x_pos, string_position, colorname, V_ALLOWLOWERCASE|string_flags, right_style)
			if selected then
				v.drawString((((320 - menu.x_pos) - 10) - v.stringWidth(colorname, 0, width_type)) - ((leveltime % 9) / 5), string_position, "\x1C", V_YELLOWMAP|V_ALLOWLOWERCASE|string_flags)
				v.drawString(((320 - menu.x_pos) + 2) + ((leveltime % 9) / 5), string_position, "\x1D", V_YELLOWMAP|V_ALLOWLOWERCASE|string_flags)
			end
		elseif (item.cvar ~= nil) then
			v.drawString(320 - menu.x_pos, string_position, item.cvar.string, V_ALLOWLOWERCASE|string_flags, right_style)
			
			if selected then
				v.drawString((((320 - menu.x_pos) - 10) - v.stringWidth(item.cvar.string, 0, width_type)) - ((leveltime % 9) / 5), string_position, "\x1C", V_YELLOWMAP|V_ALLOWLOWERCASE|string_flags)
				v.drawString(((320 - menu.x_pos) + 2) + ((leveltime % 9) / 5), string_position, "\x1D", V_YELLOWMAP|V_ALLOWLOWERCASE|string_flags)
			end
		elseif (item.range ~= nil) then
			local option = item.value
			v.drawString(320 - menu.x_pos, string_position, option, V_ALLOWLOWERCASE|string_flags, right_style)
			
			if selected then
				v.drawString((((320 - menu.x_pos) - 10) - v.stringWidth(option, 0, width_type)) - ((leveltime % 9) / 5), string_position, "\x1C", V_YELLOWMAP|V_ALLOWLOWERCASE|string_flags)
				v.drawString(((320 - menu.x_pos) + 2) + ((leveltime % 9) / 5), string_position, "\x1D", V_YELLOWMAP|V_ALLOWLOWERCASE|string_flags)
			end
		elseif (item.options ~= nil) then
			local option = item.options[item.value]
			v.drawString(320 - menu.x_pos, string_position, option, V_ALLOWLOWERCASE|string_flags, right_style)
			
			if selected then
				v.drawString((((320 - menu.x_pos) - 10) - v.stringWidth(option, 0, width_type)) - ((leveltime % 9) / 5), string_position, "\x1C", V_YELLOWMAP|V_ALLOWLOWERCASE|string_flags)
				v.drawString(((320 - menu.x_pos) + 2) + ((leveltime % 9) / 5), string_position, "\x1D", V_YELLOWMAP|V_ALLOWLOWERCASE|string_flags)
			end
		elseif (item.player ~= nil) then
			local text = players[item.player] and players[item.player].name or "Unknown"
			v.drawString(320 - menu.x_pos, string_position, text, V_ALLOWLOWERCASE|string_flags, right_style)
			
			if selected then
				v.drawString((((320 - menu.x_pos) - 10) - v.stringWidth(text, 0, width_type)) - ((leveltime % 9) / 5), string_position, "\x1C", V_YELLOWMAP|V_ALLOWLOWERCASE|string_flags)
				v.drawString(((320 - menu.x_pos) + 2) + ((leveltime % 9) / 5), string_position, "\x1D", V_YELLOWMAP|V_ALLOWLOWERCASE|string_flags)
			end
		end
	end
	v.drawScaled((menu.x_pos - 24) * FU, (menu.y_pos + cursor_y) * FU, FU, v.cachePatch("M_CURSOR"))
end

hud.add(function (v, _, _)
	if not MENU:IsActive() then return end
	
	local page = MENU:GetCurrentPage()
	if page.drawer then
		page.drawer(v, page, MENU.Current)
		return
	end
	
	if page.scroll then
		MENU:DrawScroll(v, page, MENU.Current)
		return
	end
	MENU:DrawStandard(v, page, MENU.Current)
end, "game")
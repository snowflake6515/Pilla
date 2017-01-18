-- Buddy Box Mode Visual / Vibrate - Lua app for JETI DC/DS-24 Tx

-- Constants
local appName = "Buddy Box Enhancements"

-- Useful default values, variables, etc.
local left = false				-- left stick indicator for system.vibration
local right = not left
local vibProfiles = {"1 Long", "1 Short", "2 Short", "3 Short"}	-- index 1-4, convert to 0-3, error in manual

local colorLevel = 255			-- full intensity
local transparencyLevel = 255	-- no transparency
local brightYellow = {colorLevel, colorLevel, 0}	-- red and green, but no blue, creates yellow
local brightWhite = {colorLevel, colorLevel, colorLevel}
curColor = brightYellow			-- overwritten when controlling object changes
curColorSet = false				-- true tied to when lcd.setColor invoked

local icons = {":modelG", ":modelGDS"}		-- Personal choice: my master Tx is a DC-24 and my buddybox Tx is a DS-14
	local masterIconIdx = 1
	local bbIconIdx = 2
----------------------------

-- Local Variables for entire APP
local switch				-- holds item representing trainer switch (obtained from form)
local switchVal = 0			-- holds changed (@ runtime) trainer switch value (1=BuddyBox in control), nil if no change
local switchBB = 1			-- as configured in my DC-24, value of trainer switch when BB is enabled
local enableTelem = 0		-- optional telemetry double display

------- Objects -------
--[[	Double Height Telemetry Display Box Object
Attributes:
	state		-- indicates size set
	bbWidth		-- stores telemetry box width
	bbHeight	-- stores telemetry box height
	bbXoffset	-- style placement in pixels
	bbYoffset	-- style placement in pixels

Methods:
	set			(set width and height dimensions)
	get			(get width, height, xOffset, yOffset dimensions)
	chk			(check if initialized)

----	Master / Buddy Box Object Template
Attributes:
	state			(1=enabled / 0=disabled)	-- idiosyncrasies with true/false ???  TBD
	message			(adjoining icon display)
	icon			(displayable icon in telemetry window)
	stick			(which stick is associated with Master or Buddy Box)
	vibProfile		(vibration profile)
	color

Methods:
	new			(create a new instance)
	chk			(check if object initialized)
	disp		(displays the status in telemetry window)
	vib			(vibrates to signify state change)
-]]

-- Object Definitions and Instances

-- Telemetry Double Window for Master/Buddy Box Mode Indication
local dbox = {
	-- attributes
	state = false,	-- indicates whether dbox attributes have been set
	bbWidth = 152,	-- overwritten at run-time, but observed value for double telemetry box
	bbHeight = 90,	-- overwritten at run-time, but observed value for double telemetry box
	bbXoffset = 7,	-- placement style
	bbYoffset = 5,	-- placement style
	
	-- methods
	chk = function(self) return self.state end,
	
		set = function(self, width, height)
		self.bbRectW = width
		self.bbRectH = height
		self.state = true
	end,
		
	get = function(self) return self.bbWidth, self.bbHeight, self.bbXoffset, self.bbYoffset end
}

-- hold values of Telemetry Double Box window set/get dbox object
local w, h, x, y = 0, 0, 0, 0

-- Buddy Box Instance and Template for Master Instance
local master		-- instantiation will be finished when "new" invoked...

local bbox = {
	-- attributes
	state = true,		-- true when initialized
	message = "Buddy Box",
	message2 = "In Control",
	icon = icons[bbIconIdx],
	stick = left,
	vibProfile = 2,
	color = brightYellow,		-- can be overwritten via setup form 
	
	-- methods
	new = function(self, o)
		o = o or {}
		self.__index = self
		setmetatable(o, self)
		return o
	end,
	
	disp = function(self)
		if switchVal
		then
			lcd.setColor(table.unpack(curColor))				-- here?  or in dispTelem?
			lcd.drawImage(x, y, self.icon, transparencyLevel)	-- position icon in left half of box
			lcd.drawText(w/2 + 2, y, self.message)				-- position text in right half (plus 2 pixels) of box
			lcd.drawText(w/2 + 2, y+20, self.message2)			-- standard second line, unless overwritten in "new()"
		end
	end,
	
	vib = function(self)
		if(self.state)
		then
			system.vibration(self.stick, self.vibProfile)
		end
	end
}

-- Support Functions
--[[
Function checkSwChange
Check for change in trainer switch (switch - obtained from input form)
return:
	-1	indicates no change in state
	 0	indicates change to Master in control
	 1	indicates change to Buddy Box in control
--]]
local function checkSwChange(sw)
	-- check for abnormal situations, first, and then for no change, next
	if(not sw) then return -1 end					-- trainer switch assigned, yet?
	switchVal = system.getInputsVal(sw)
	if(not switchVal) then return -1 end			-- able to obtain value of trainer switch?
	if(switchVal == curSwVal) then return -1 end	-- no change; majority of cases given 20-30 msec loop f()

	-- switch has changed	
	curSwVal = switchVal		-- save new state as "current" state
	colorSet = false			-- force dispTelem to reset color to new object's color parameter
	if(curSwVal == switchBB)
	then
		-- Budddy Box is now in control
		return switchBB
	else
		-- Master is now in control
		return 0
	end
--	return -1	-- redundant
end

--[[
Function setObjParams
Could be cleaned up so as to not violate object encapsularion (too bad inline f() not available)
--]]
local stk	-- holds default stick selection for form menu
local vib	-- holds default vibration profile selection for form menu
local setObjParams = function(obj)
	-- prepare menu default selections to conform to object instance values
	if(obj.stick == right) then stk = 2 else stk = 1 end
	vib = obj.vibProfile + 1		-- manual error, off by one
	
	form.addRow(3)
	form.addLabel({label=obj.message})
		-- left or right stick
	form.addSelectbox({"Left", "Right"}, stk, true,
		function(value)
			if(value == 1)
			then obj.stick = left	-- left stick
			else obj.stick = right	-- right stick
			end
		end)
		-- vibration profile
	form.addSelectbox(vibProfiles, vib, true,
		function(value)
			obj.vibProfile=(value-1)		-- error in Lua manual: 1-4 really 0-3
		end)
		-- image selection
	-- form.TBD
	
end

-- System support functions
-- This telemetry function is called regularly and is the primary place to update a telemetry window
local function dispTelem(width, height)
	if(not dbox:chk())				-- check if Double Box Telemetry window created
	then
		dbox:set(width, height)
		w, h, x, y = dbox:get()
	else
		--regularly refresh telemetry window with current state; otherwise, momenetary flash result
		if (curSwVal == switchBB)
		then
			bbox:disp()
		else
			master:disp()
		end
	end
end

--------------
local function initForm(formID)
	form.addLabel({label="Set Buddy Box Features",font=2})
	form.addRow(2)
	-- Select Trainer Switch (better if system would allow obtaining value set from wireless...)
	form.addLabel({label="Trainer Switch"})
	form.addInputbox(switch, false, function(value) switch=value end) -- "false": binary switch, not proportional
		
	-- Master Selections:		prepare menu default selections to conform to object instance values
	setObjParams(master)
	-- Buddy Box Selections:	prepare menu default selections to conform to object instance values
	setObjParams(bbox)
end

---------------- 
-- Init function
local function init()
	-- create instance to hold master using buddy box template
	master = bbox:new {
		state = true,
		message = "Master",
		icon = icons[masterIconIdx],
		stick = right,		-- default: vibrate right stick to indicate Master has control
		vibProfile = 1,		-- default: 1 Short to indicate Master has control (manual error: 2)
		color = brightWhite
}
	-- create a form to allow user to select (1) trainer switch, (2) which stick to vibrate, and (3) vibration profile
	system.registerForm(1, MENU_APPS, appName, initForm, nil, nil)
	
	-- ask if display/telemetry box should be added (??? Requires Tx R4.20, minimum ???)
	--[[
	enableTelem = form.question("Enable Telemetry Display?", "Telemetry Display window will be created", "", 10000, false, 500)
	--]]
	---[[
	enableTelem = 1		-- Temporary workaround until DC-24 Tx R4.20 arrives to fix "question" bits
	--]]
	if (enableTelem == 1)			-- 1: Yes / 0 and -1: error, timeout, or "No" selected
	then
		-- create a double Telemetry box to display Buddy Box state
		system.registerTelemetry(1, "Buddy Box Status", 2, dispTelem)
	end
	--]]
	
	---[[
	local mem = collectgarbage("count")
	print("Memory usage: ", mem)	-- 28.63531 (.lua) / 27.038 (.lc)
	--]]
end
 
-------------- 
-- Loop function	called at regular 20 - 30 msec intervals: checks trainer switch change and then vibrates stick
local function loop()
	local val = checkSwChange(switch)
	-- check if trainer switch assisgned/changed state and indicate by haptic vibration
	if(val < 0)
	then
		return					-- no switch change
	elseif (val == switchBB)
	then
		-- Buddy Box now in control
		bbox:vib()
		curColor = bbox.color	-- set local app-global parameter to new controlling object's color
		colorSet = false		-- force dispTelem f() to lcd.setColor to new controlling object's color
	else
		-- Master now in control
		master:vib()
		curColor = master.color
		colorSet = false
	end
end

----------------- 

return { init=init, loop=loop, author="M. A. Pilla", version="1.2", name=appName}

--[[
Notes:
	1. "switch" variable holds value of trainer enable switch (five logical switches)
	2. "switch" variable thereby indicates state; whether Master or Buddy Box is in control
	3. "switch" variable, when changed, triggers haptic vibration to signify change of control
	4. Form used to obtain (1) the trainer switch, (2) which stick (L/R) corresponds to which state and (3) vibration profile
	
Versions:
	1.0		Setup menus, obtain user choices for trainer switch, left/right stick and vibration profile
	1.1		Add visual telemetry window to display Master / BB icon
	1.1.1	Incorporated more OO features as a coding experiment
	1.2		Make Telemetry Display optional
--]]
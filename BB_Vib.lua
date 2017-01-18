-- Buddy Box Mode Visual / Vibrate - Lua app for JETI DC/DS-24 Tx
--[[
	Versions:
		1.0		Setup menus, obtain user choices for trainer switch, left/right stick and vibration profile
--]]

local appName = "Buddy Box Enhancements"
local switch			-- holds "trainer" switch selection from input form and getInputsVal used for state changes
local switchVal = 0		-- holds changed (@ runtime) trainer switch value (1=BuddyBox in control), nil if no change
local switchBB = 1		-- as configured in my DC-24, value of trainer switch when BB is enabled

-- stick / vibration variables (with defaults)
local vibProfiles = {"1 Long", "1 Short", "2 Short", "3 Short"}	-- index 1-4, convert to 0-3, error in manual
local masterStick = false	-- default: right stick
local masterProfile = 0		-- default: one long pulse
local bboxStick = true		-- default: left stick
local bboxProfile = 2		-- default: two short pulses
--------------
-- Support Functions
--[[
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
	curSwVal = switchVal						-- save new state as "current" state
	if(curSwVal == switchBB)
	then
		-- Budddy Box is now in control
		return 1
	else
		-- Master is now in control
		return 0
	end
end



local function initForm(formID)
	form.addLabel({label="Set Buddy Box Features",font=2})
	form.addRow(2)
	-- Select Trainer Switch (better if system would allow obtaining value set from wireless...)
	form.addLabel({label="Trainer Switch"})
	form.addInputbox(switch, false, function(value) switch=value end) -- false: binary switch, not proportional
		
	-- Master Selections
	form.addRow(3)
	form.addLabel({label="Master"})
		-- left or right stick
	form.addSelectbox({"Left", "Right"}, 2, true,	-- default is right
		function(value)
			if(value == 1)
			then masterStick=false	-- left stick
			else masterStick=true	-- right stick
			end
		end)
		-- vibration profile
	form.addSelectbox(vibProfiles, 1, true,		-- default is 1 Long
		function(value)
			masterProfile=(value-1)		-- error in Lua manual: 1-4 really 0-3
		end)
		-- image selection
	-- form.TBD
	
	-- Buddy Box Selections
	form.addRow(3)
	form.addLabel({label="Buddy Box"})
		-- left or right stick
	form.addSelectbox({"Left", "Right"}, 1, true,	-- default is left
		function(value)
			if(value == 1)
			then bboxStick=false	-- left stick
			else bboxStick=true	-- right stick
			end
		end)
		-- vibration profile
	form.addSelectbox(vibProfiles, 3, true,		-- default is 2-Short (+1 for index)
		function(value)
			bboxProfile=(value-1)		-- error in Lua manual: 1-4 really 0-3
		end)
		-- image selection
	-- form.TBD
end

--[[
local function dispForm()
	-- does nothing; needed?
end
--]]

---------------- 
-- Init function
local function init()
	system.registerForm(1, MENU_APPS, appName, initForm, nil, nil);
	local mem = collectgarbage("count")
	print("Memory usage: ", mem)	-- TBD (.lua) / TBD  (.lc) 
end
 
-------------- 
-- Loop function
local function loop()
	-- check if trainer switch changed state and indicate via haptic vibration
	local val = checkSwChange(switch)
	if(val < 0)
	then
		return					-- no switch change
	elseif (val == switchBB)
	then
		-- Buddy Box now in control
		system.vibration(bboxStick, bboxProfile)
	else
		-- Master now in control
		system.vibration(masterStick, masterProfile)
	end
end
 

----------------- 

return { init=init, loop=loop, author="M. A. Pilla", version="1.0", name=appName}
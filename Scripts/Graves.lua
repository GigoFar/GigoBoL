local version = 0.1
local autoUpdate = true
local SilentPrint = false 

if not VIP_USER or myHero.charName ~= "Graves" then return end
--[[Credits to Hellsing, QQQ and Honda7]]--

local host = "https://github.com/"
local path = "/GigoFar/GigoBoL/blob/master/Scripts/Graves.lua".."?rand="..math.random(1,10000)
local url  = "https://"..host..path
local printMessage = function(message) if not SilentPrint then print("<font color=\"#6699ff\"><b>Graves:</b></font> <font color=\"#FFFFFF\">" .. message .. "</font>") end end
local webResult = GetWebResult(host, path)
if autoUpdate then
	if webResult then
		local serverVersion = string.match(webResult, "%s*local%s+version%s+=%s+.*%d+%.%d+")
		if serverVersion then
			serverVersion = tonumber(string.match(serverVersion, "%d+%.?%d*"))
			if version < serverVersion then
				printMessage("New version available: v" .. serverVersion)
				printMessage("Updating, please don't press F9")
				DelayAction(function () DownloadFile(url, SCRIPT_PATH .. GetCurrentEnv().FILE_NAME, function () printMessage("Successfully updated, please reload with double F9!") end) end, 2)
			else
				printMessage("You've got the latest version: v" .. serverVersion)
			end
		else
			printMessage("Please manually update the script!")
		end
	else
		printMessage("Error downloading version info!")
	end
end


local REQUIRED_LIBS = {
	["VPrediction"] = "https://raw.githubusercontent.com/honda7/BoL/master/Common/VPrediction.lua",
	["SOW"] = "https://raw.githubusercontent.com/honda7/BoL/master/Common/SOW.lua"

}               
local DOWNLOADING_LIBS = false
local DOWNLOAD_COUNT = 0
local SELF_NAME = GetCurrentEnv() and GetCurrentEnv().FILE_NAME or ""
function AfterDownload()
	DOWNLOAD_COUNT = DOWNLOAD_COUNT - 1
	if DOWNLOAD_COUNT == 0 then
		DOWNLOADING_LIBS = false
		printMessage("Required libraries downloaded successfully, please reload (double [F9]).</font>")
	end
end 
for DOWNLOAD_LIB_NAME, DOWNLOAD_LIB_URL in pairs(REQUIRED_LIBS) do
	if FileExist(LIB_PATH .. DOWNLOAD_LIB_NAME .. ".lua") then
		require(DOWNLOAD_LIB_NAME)
	else
		DOWNLOADING_LIBS = true
		DOWNLOAD_COUNT = DOWNLOAD_COUNT + 1
		printMessage("Not all required libraries are installed. Downloading: <b><u><font color=\"#73B9FF\">"..DOWNLOAD_LIB_NAME.."</font></u></b> now! Please don't press [F9]!</font>")
		DownloadFile(DOWNLOAD_LIB_URL, LIB_PATH .. DOWNLOAD_LIB_NAME..".lua", AfterDownload)
	end
end 
if DOWNLOADING_LIBS then return end
--[[End of Credits]]-- 

local Graves = {
	Q = {range = 900, speed = 0.902, delay = 250, collision = false},
	W = {range = 950, speed = 1.650, delay = 250, collision = false},
	R = {range = 1000, speed = 1.4, delay = 250, radius = 210, collision = true}
}

function OnLoad()
	wayPointManager = WayPointManager()
	VP = VPrediction(true)
	Recall = false
	Tick = GetTickCount()
	if _G.MMA_Loaded ~= nil then
		PrintChat("<font color = \"#00FF00\">Grave MMA Status:</font> <font color = \"#fff8e7\"> Loaded</font>")
		isMMA = true
	elseif _G.AutoCarry ~= nil then
		PrintChat("<font color = \"#00FF00\">Grave SAC Status:</font> <font color = \"#fff8e7\"> Loaded</font>")
		isSAC = true
	else
		isSOW = true
	end
	Menu = scriptConfig("Graves","Graves")
	Menu:addParam("Version","Version: "..version,0.1,"")
	Menu:addSubMenu("Graves: Key Bindings","General")
		Menu.General:addParam("Combo","Combo",2,false,32)
		Menu.General:addParam("LastHit","LastHit",2,false,X)
		Menu.General:addParam("Harass","Harass",2,false,C)
		Menu.General:addParam("LaneClear","LeaneClear",2,false,V)
	Menu:addSubMenu("Graves: Combo","Combo")
		Menu.Combo:addParam("Q","Use Q in 'Combo'",1,true)
		Menu.Combo:addParam("W","Use W in 'Combo'",1,true)
		Menu.Combo:addParam("R","Use R in 'Combo'",1,true)
	Menu:addSubMenu("Graves: Harass","Harass")
		Menu.Harass:addParam("Q","Use Q in 'Harass'",1,true)
		Menu.Harass:addParam("W","Use W in 'Harass'",1,true)
	Menu:addSubMenu("Graves: LaneClear","LaneClear")
		Menu.Jungle:addParam("Q","Auto Attack in 'LaneClear'",1,true)
	Menu:addSubMenu("Graves: Hit Chances","HC")
		Menu.HC:addParam("Q","Cast Q if:",7,Graves.Q["hitchance"], { "Low Hit Chance", "High Hit Chance", "Target Slow/Close", "Target Immobilised", "Target Dashing/Blinking"})
		Menu.HC:addParam("R","Cast R if:",7,Graves.Q["hitchance"], { "Low Hit Chance", "High Hit Chance", "Target Slow/Close", "Target Immobilised", "Target Dashing/Blinking"})
	Menu:addSubMenu("Graves: Extra","Extra")
		Menu.Extra:addParam("KS", "Auto Killsteal", SCRIPT_PARAM_ONOFF, true)	
	Menu:addSubMenu("Graves: Show","Show")
		Menu.Show:addParam("Combo","Show 'Combo'",1,true)
		Menu.Show:addParam("LastHit","Show 'LastHit'",1,true)
		Menu.Show:addParam("Harass","Show 'Harass'",1,true)
		Menu.Show:addParam("LaneClear","Show 'LaneClear'",1,true)
		if Menu.Show.Combo then
			Menu.General:permaShow("Combo")
		end
		if Menu.Show.LastHit then
			Menu.General:permaShow("LastHit")
		end
		if Menu.Show.Harass then
			Menu.General:permaShow("Harass")
		end
		if Menu.Show.LaneClear then
			Menu.General:permaShow("LaneClear")
		end
	ts = TargetSelector(7,1100,1,false)
	ts.name = "Graves Target"
	Menu:addTS(ts)
	printMessage("Script Loaded")
	if not _G.SOWLoaded then
		SOWi = SOW(VP)
		SMenu = scriptConfig("Simple Orbwalker", "Simple Orbwalker")
		SMenu:addSubMenu("Drawing", "Drawing")
		SMenu.Drawing:addParam("Range", "Draw auto-attack range", SCRIPT_PARAM_ONOFF, true)
		SOWi:LoadToMenu(SMenu)
		SOWi:RegisterAfterAttackCallback(AfterAttack)
	end
end

function GetCustomTarget()
	ts:update()
	if _G.MMA_Target and _G.MMA_Target.type == myHero.type then return _G.MMA_Target end
	if _G.AutoCarry and _G.AutoCarry.Crosshair and _G.AutoCarry.Attack_Crosshair and _G.AutoCarry.Attack_Crosshair.target and _G.AutoCarry.Attack_Crosshair.target.type == myHero.type then return _G.AutoCarry.Attack_Crosshair.target end
	return ts.target
end

function OnTick()
	ts:update()
	Target = ts.target
	QREADY = (myHero:CanUseSpell(_Q) ~= COOLDOWN or myHero:CanUseSpell(_Q) == READY)
	WREADY = (myHero:CanUseSpell(_W) ~= COOLDOWN or myHero:CanUseSpell(_W) == READY)
	RREADY = (myHero:CanUseSpell(_R) ~= COOLDOWN or myHero:CanUseSpell(_R) == READY)
	end
	
	if Target then
		if Menu.General.Combo then
			if Menu.Combo.Q and QREADY then
				local CastPosition, HitChance, Position = VP:GetLineCastPosition(Target,Grave.Q["delay"],Graves.Q["width"],Graves.Q["range"],Graves.Q["speed"],myHero,)
				if GetDistance(myHero,CastPosition) <= Graves.Q["range"] and HitChance >= Menu.HC.Q 
				end
			end
			if Menu.Combo.W and WREADY then
				local CastPosition, HitChance, Position = VP:GetLineCastPosition(Target,Grave.W["delay"],Graves.W["width"],Graves.W["range"],Graves.W["speed"],myHero,)
				if GetDistance(myHero,CastPosition) <= Graves.W["range"] and HitChance >= Menu.HC.W 
				end
			end
			if Menu.Combo.R and RREADY then
				local CastPosition, HitChance, Position = VP:GetLineCastPosition(Target,Grave.R["delay"],Graves.R["width"],Graves.R["range"],Graves.R["speed"],myHero,)
				if GetDistance(myHero,CastPosition) <= Graves.W["range"] and HitChance >= Menu.HC.W 
				end
			end
		end
		if Menu.General.Harass then
			if Menu.Combo.Q and QREADY then
				local CastPosition, HitChance, Position = VP:GetLineCastPosition(Target,Grave.Q["delay"],Graves.Q["width"],Graves.Q["range"],Graves.Q["speed"],myHero,)
				if GetDistance(myHero,CastPosition) <= Graves.Q["range"] and HitChance >= Menu.HC.Q 
				end
			end
		end
	end
end

function KS(Target)
	if QREADY and getDmg("Q", Target, myHero) > Target.health then
		local CastPos = VP:GetLineCastPosition(Target, Qdelay, Qwidth, Qrange, Qspeed, myHero, false)
		if GetDistance(Target) <= Qrange and QREADY then
		CastSpell(_Q, CastPos.x, CastPos.z)
		end
	end
	if RREADY and getDmg("R", Target, myHero) > Target.health then
		local CastPos = VP:GetLineCastPosition(Target, Rdelay, Rwidth, Rrange, Rspeed, myHero, false)
		if GetDistance(Target) <= Rrange and RREADY then
		CastSpell(_R, CastPos.x, CastPos.z)
		end
	end
end

function OnGainBuff(unit, buff)
	if unit.isMe and buff.name:lower():find("recall") then
		Recall = true
	end
end
function OnLoseBuff(unit, buff)
	if unit.isMe and buff.name:lower():find("recall") then
		Recall = false
	end
end

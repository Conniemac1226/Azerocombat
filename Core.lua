-- AzeroCombat: Auto Combat Rotation Addon for WotLK
-- For private server use only

-- Main addon frame and initialization
local AddonName, AC = ...

-- This is important: Make sure AC exists before trying to use it
if not AC then AC = {} end

-- Then continue with the addon setup
AC = LibStub("AceAddon-3.0"):NewAddon(AC, AddonName, "AceEvent-3.0", "AceTimer-3.0")
AC.version = "1.2"
AC.rotations = {}
AC.enabled = false
AC.initialized = false -- Flag to prevent double initialization
AC.debugMode = false   -- Debug mode flag
AC.silentMode = false  -- Silent mode flag
AC.debugWindowEnabled = false  -- Debug window mode flag
AC.debugMessages = {}  -- Store debug messages for the debug window
AC.maxDebugMessages = 200  -- Maximum number of debug messages to keep

-- ONLY CHANGE: Use AceDB defaults for position like Core(1)
local defaults = {
    profile = {
        framePosition = {
            point = "TOPRIGHT",
            relativeTo = nil,
            relativePoint = "TOPRIGHT",
            x = -20,
            y = -100
        },
        egtEnabled = false,  -- Add this line
        autofarmEnabled = false,  -- Add autofarm state
        targetingMode = "auto",
        feralRoleMode = "auto",
        debugWindowEnabled = false,  -- Debug window state
        debugWindowPosition = {
            point = "TOPLEFT",
            relativeTo = nil,
            relativePoint = "TOPLEFT",
            x = 20,
            y = -200
        }
    }
}

-- Core frame for updates
local updateFrame = CreateFrame("Frame")

-- Helper function to run slash commands
function RunSlashCmd(cmd)
    local slash, rest = cmd:match("^(%S+)%s*(.-)$")
    if slash then
        slash = string.lower(slash)
        -- Try to find the slash command
        for name, func in pairs(SlashCmdList) do
            local i = 1
            while true do
                local slashCmd = _G["SLASH_"..name..i]
                if not slashCmd then break end
                if slashCmd == slash then
                    func(rest)
                    return true
                end
                i = i + 1
            end
        end
    end
    return false
end

-- Enhanced throttle system to prevent function spam
local throttleTimes = {}
function AC:Throttle(key, interval)
    if not throttleTimes[key] or (GetTime() - throttleTimes[key] > interval) then
        throttleTimes[key] = GetTime()
        return true
    end
    return false
end

-- Enhanced throttle system with action-specific timings
function AC:ActionThrottle(action, interval)
    local key = "action_" .. action
    if not throttleTimes[key] or (GetTime() - throttleTimes[key] > interval) then
        throttleTimes[key] = GetTime()
        return true
    end
    return false
end

-- Class-specific throttle intervals
AC.ClassThrottles = {
    ROGUE = {
        poison_check = 2.0,     -- Faster poison checking
        stealth_check = 1.0,    -- Quick stealth decisions
        combo_point = 0.3,      -- Fast combo point spending
        energy_check = 0.2,     -- Very fast energy decisions
        cooldown_check = 1.0,   -- Regular cooldown checking
        defensive = 0.5,        -- Quick defensive reactions
    }
}

-- Get class-specific throttle interval
function AC:GetThrottleInterval(action)
    local class = self:GetPlayerClass()
    local intervals = self.ClassThrottles[class]
    
    if intervals and intervals[action] then
        return intervals[action]
    end
    
    -- Default intervals
    local defaults = {
        poison_check = 5.0,
        stealth_check = 2.0,
        combo_point = 0.5,
        energy_check = 0.5,
        cooldown_check = 2.0,
        defensive = 1.0,
    }
    
    return defaults[action] or 1.0
end

-- =============================================
-- ENHANCED RESOURCE MANAGEMENT
-- =============================================

-- Track resource states for better decision making
AC.ResourceStates = {}

function AC:UpdateResourceState()
    local class = self:GetPlayerClass()
    local state = {
        timestamp = GetTime(),
        health = UnitHealth("player") / UnitHealthMax("player") * 100,
        primary = UnitPower("player", 0), -- Mana for most classes
        secondary = UnitPower("player", 3), -- Energy for rogues
        tertiary = GetComboPoints("player", "target"), -- Combo points for rogues
    }
    
    self.ResourceStates[class] = state
    return state
end

function AC:GetResourceTrend(resource)
    local class = self:GetPlayerClass()
    local current = self.ResourceStates[class]
    
    if not current or GetTime() - current.timestamp > 5 then
        return 0 -- No trend data
    end
    
    local previous = current[resource] or 0
    local currentValue = 0
    
    if resource == "health" then
        currentValue = UnitHealth("player") / UnitHealthMax("player") * 100
    elseif resource == "energy" then
        currentValue = UnitPower("player", 3)
    elseif resource == "combo" then
        currentValue = GetComboPoints("player", "target")
    end
    
    return currentValue - previous
end

-- =============================================
-- ENHANCED COMBAT STATE TRACKING
-- =============================================

-- Track combat phases for better rotation decisions
AC.CombatPhases = {
    OPENER = "opener",
    BURST = "burst", 
    SUSTAIN = "sustain",
    EXECUTE = "execute",
    DEFENSIVE = "defensive"
}

function AC:GetCombatPhase()
    if not UnitAffectingCombat("player") then
        return "out_of_combat"
    end
    
    local targetHP = UnitExists("target") and (UnitHealth("target") / UnitHealthMax("target") * 100) or 100
    local playerHP = UnitHealth("player") / UnitHealthMax("player") * 100
    local combatTime = self:GetCombatTime()
    
    -- Execute phase
    if targetHP < 25 then
        return self.CombatPhases.EXECUTE
    end
    
    -- Defensive phase
    if playerHP < 30 then
        return self.CombatPhases.DEFENSIVE
    end
    
    -- Opener phase (first 6 seconds)
    if combatTime < 6 then
        return self.CombatPhases.OPENER
    end
    
    -- Burst phase (high health target, cooldowns available)
    if targetHP > 75 and self:HasMajorCooldownsAvailable() then
        return self.CombatPhases.BURST
    end
    
    -- Default sustain phase
    return self.CombatPhases.SUSTAIN
end

function AC:GetCombatTime()
    -- Track when combat started
    if not self.combatStartTime then
        if UnitAffectingCombat("player") then
            self.combatStartTime = GetTime()
        end
        return 0
    end
    
    if not UnitAffectingCombat("player") then
        self.combatStartTime = nil
        return 0
    end
    
    return GetTime() - self.combatStartTime
end

function AC:GetRotationComplexity()
    local level = UnitLevel("player")
    
    -- Determine rotation complexity based on player level
    if level >= 75 then
        return "ADVANCED"
    elseif level >= 60 then
        return "MODERATE" 
    elseif level >= 40 then
        return "SIMPLE"
    else
        return "BASIC"
    end
end

function AC:HasMajorCooldownsAvailable()
    local class = self:GetPlayerClass()
    
    if class == "ROGUE" then
        local spec = self:GetPlayerSpec()
        if spec == "Assassination" then
            return self:GetSpellCooldown("Vendetta") == 0 or self:GetSpellCooldown("Cold Blood") == 0
        elseif spec == "Combat" then
            return self:GetSpellCooldown("Adrenaline Rush") == 0 or self:GetSpellCooldown("Killing Spree") == 0
        elseif spec == "Subtlety" then
            return self:GetSpellCooldown("Shadow Dance") == 0 or self:GetSpellCooldown("Preparation") == 0
        end
    end
    
    return false
end

-- =============================================
-- GROUND AOE TARGETING SYSTEM (FIXED)
-- =============================================

-- Global ground targeting system with improved channel tracking
AC.groundAOELastCastTime = {}
AC.groundAOEChannelEndTimes = {}  -- Track when channels are expected to end
AC.groundAOESpellDurations = {
    ["Rain of Fire"] = 8,     -- 8 second channel
    ["Blizzard"] = 8,         -- 8 second channel
    ["Hurricane"] = 10,       -- 10 second channel
    ["Volley"] = 6,           -- 6 second channel
    ["Flamestrike"] = 8,      -- Not channeled but has 8s effect
    ["Consecration"] = 8,     -- Not channeled but has 8s effect
    ["Death and Decay"] = 10  -- Not channeled but has 10s effect
}

-- FIXED: Much simpler IsChanneling function
function AC:IsChanneling(spellName)
    -- Just use the API - if it doesn't work, we don't need fallbacks that cause delays
    local channelName = UnitChannelInfo and UnitChannelInfo("player")
    
    if channelName then
        if spellName then
            return channelName == spellName
        end
        return true
    end
    
    return false
end

-- FIXED: WotLK-compatible SafeCastGroundAOE optimized for server modules
function AC:SafeCastGroundAOE(spellName)
    -- First check if the spell is usable
    if not self:IsUsableSpell(spellName) then
        return false
    end
    
    -- Skip if already channeling
    if UnitChannelInfo and UnitChannelInfo("player") then
        return false
    end
    
    -- Don't cast if moving (most ground AoE requires standing still)
    if self:IsPlayerMoving() then
        return false
    end
    
    self:Debug("Casting " .. spellName .. " (Ground AoE)")
    
    -- Cast the spell
    CastSpellByName(spellName)
    
    -- Handle targeting - optimized for server modules that auto-place
    local frame = CreateFrame("Frame")
    local attempts = 0
    local maxAttempts = 15 -- Increased attempts for reliability
    
    frame:SetScript("OnUpdate", function(self, elapsed)
        attempts = attempts + 1
        
        if SpellIsTargeting() then
            -- Use WotLK 3.3.5a compatible targeting methods
            
            -- Method 1: Camera controls (WotLK compatible)
            CameraOrSelectOrMoveStart()
            CameraOrSelectOrMoveStop()
            AC:Debug(spellName .. " clicked (camera method)")
            self:SetScript("OnUpdate", nil)
            
        elseif attempts >= maxAttempts then
            -- Timeout - cancel the spell
            AC:Debug(spellName .. " targeting timeout - cancelling")
            if SpellIsTargeting() then
                SpellStopTargeting()
            end
            self:SetScript("OnUpdate", nil)
        end
    end)
    
    return self:GetGroupSize() <= 5
end

-- SIMPLIFIED: Remove the aggressive blocking
function AC:IsBusyChanneling()
    -- Only check the API - no fallback tracking that causes delays
    return UnitChannelInfo and UnitChannelInfo("player") ~= nil
end

-- Enhanced enemy count for AoE determination
function AC:GetEnemiesAtLocation(unit, radius)
    -- Don't run this function too often - but return cached value instead of 0
    if not unit or not UnitExists(unit) then return 0 end
    if not self:Throttle("EnemyCount"..unit, 0.5) then 
        return self.lastLocationEnemyCount or 1 -- Return cached instead of 0
    end
    
    -- FIXED: Use the same robust logic as main GetEnemyCount()
    local count = 0
    local processedGUIDs = {}
    radius = radius or 30
    
    -- METHOD 1: Check current target
    if UnitExists("target") and UnitCanAttack("player", "target") and not UnitIsDead("target") then
        local targetGUID = UnitGUID("target")
        if targetGUID then
            count = count + 1
            processedGUIDs[targetGUID] = true
        end
    end
    
    -- METHOD 2: Check party/raid member targets
    local groupSize = GetNumRaidMembers() > 0 and GetNumRaidMembers() or GetNumPartyMembers()
    local unitPrefix = GetNumRaidMembers() > 0 and "raid" or "party"
    
    for i = 1, groupSize do
        local memberUnit = unitPrefix .. i
        if UnitExists(memberUnit) then
            local memberTarget = memberUnit .. "target"
            if UnitExists(memberTarget) and UnitCanAttack("player", memberTarget) and not UnitIsDead(memberTarget) then
                local targetGUID = UnitGUID(memberTarget)
                if targetGUID and not processedGUIDs[targetGUID] then
                    count = count + 1
                    processedGUIDs[targetGUID] = true
                end
            end
        end
    end
    
    -- METHOD 3: Check combat log enemies (recent)
    if self.combatEnemies then
        for guid, data in pairs(self.combatEnemies) do
            if not processedGUIDs[guid] and GetTime() - data.lastSeen <= 2 then
                count = count + 1
                processedGUIDs[guid] = true
            end
        end
    end
    
    -- Cache the result
    self.lastLocationEnemyCount = count
    return count
end

-- =============================================
-- ERROR HANDLING SYSTEM
-- =============================================

-- Replace your SilenceErrorSounds function with this DPS-preserving version
function AC:SilenceErrorSounds()
    -- Only set up once
    if self.soundsDisabled then return end
    
    -- APPROACH 1: SILENCE ERROR SOUNDS WITHOUT AFFECTING CASTING FREQUENCY
    
    -- Directly intercept and block error sounds
    local originalPlaySound = _G.PlaySound
    _G.PlaySound = function(sound, channel)
        -- Block ONLY these specific error sounds
        local errorSounds = {
            "igAbilityFailed",
            "igAbilityFailedAMSpecial",
            "GAMEERRORWARNING",
            "SPELLCASTFAILED",
            "SPELLFAILQUESTREQUIREMENTS"
        }
        
        -- Check if this is an error sound that should be blocked
        for _, errorSound in ipairs(errorSounds) do
            if sound == errorSound then
                return true -- Silently consume the sound without affecting the spell cast
            end
        end
        
        -- For all other sounds, proceed normally
        return originalPlaySound(sound, channel)
    end
    
    -- APPROACH 2: PREVENT ERROR MESSAGES WITHOUT AFFECTING CASTING
    
    -- Prevent error messages from showing
    if UIErrorsFrame then
        -- Save original function
        local originalOnEvent = UIErrorsFrame:GetScript("OnEvent")
        
        -- Replace with filtered version
        UIErrorsFrame:SetScript("OnEvent", function(self, event, ...)
            -- Filter out error messages only
            if event == "UI_ERROR_MESSAGE" then
                -- Don't show the error, but still allow the action to proceed
                return true
            else
                -- For all other events, use the original handler
                if originalOnEvent then
                    return originalOnEvent(self, event, ...)
                end
            end
        end)
        
        -- Hide the frame to be sure
        UIErrorsFrame:Hide()
    end
    
    -- Set flag to prevent multiple setups
    self.soundsDisabled = true
    self:Print("Error Sounds Silenced (DPS Preserved)")
end

-- =============================================
-- PLAYER AND CHARACTER INFORMATION (FIXED SPEC DETECTION)
-- =============================================

-- ENHANCED: Spec detection with proper loading detection and caching - FIXED SPAM
function AC:GetPlayerSpec()
    -- Use cached spec if it's recent (within 10 seconds) to reduce spam
    if self.cachedSpec and self.cachedSpecTime and (GetTime() - self.cachedSpecTime) < 10 then
        return self.cachedSpec
    end
    
    -- Check if talents are actually loaded
    local talentsLoaded = false
    for i = 1, GetNumTalentTabs() do
        local numTalents = GetNumTalents(i)
        if numTalents and numTalents > 0 then
            talentsLoaded = true
            break
        end
    end
    
    -- If talents aren't loaded yet, return cached spec or None
    if not talentsLoaded then
        if self.cachedSpec then
            -- Only debug this once per session to prevent spam
            if not self.talentsNotLoadedWarned then
                if self.debugMode then
                    self:Debug("Talents not loaded, using cached spec: " .. self.cachedSpec)
                end
                self.talentsNotLoadedWarned = true
            end
            return self.cachedSpec
        else
            -- Only debug this once per session to prevent spam
            if not self.noSpecWarned then
                if self.debugMode then
                    self:Debug("Talents not loaded and no cached spec")
                end
                self.noSpecWarned = true
            end
            return "None"
        end
    end
    
    -- Reset warning flags when talents are loaded
    self.talentsNotLoadedWarned = false
    self.noSpecWarned = false
    
    -- Get current talents to determine spec
    local highestPoints, specIndex = 0, 1
    for i = 1, GetNumTalentTabs() do
        local points = select(3, GetTalentTabInfo(i))
        if points and points > highestPoints then
            highestPoints = points
            specIndex = i
        end
    end
    
    local classSpecs = {
        ["WARRIOR"] = {"Arms", "Fury", "Protection"},
        ["PALADIN"] = {"Holy", "Protection", "Retribution"},
        ["HUNTER"] = {"Beast Mastery", "Marksmanship", "Survival"},
        ["ROGUE"] = {"Assassination", "Combat", "Subtlety"},
        ["PRIEST"] = {"Discipline", "Holy", "Shadow"},
        ["DEATHKNIGHT"] = {"Blood", "Frost", "Unholy"},
        ["SHAMAN"] = {"Elemental", "Enhancement", "Restoration"},
        ["MAGE"] = {"Arcane", "Fire", "Frost"},
        ["WARLOCK"] = {"Affliction", "Demonology", "Destruction"},
        ["DRUID"] = {"Balance", "Feral", "Restoration"}
    }
    
    local class = self:GetPlayerClass()
    local spec = "None"
    
    if classSpecs[class] and classSpecs[class][specIndex] then
        spec = classSpecs[class][specIndex]
    end
    
    -- Only consider it a valid spec if we have some talent points
    if highestPoints < 5 then
        spec = "None"
    end
    
    -- Cache the spec with timestamp to prevent spam
    local specChanged = self.cachedSpec ~= spec
    self.cachedSpec = spec
    self.cachedSpecTime = GetTime()
    
    -- Only debug when spec actually changes or every 60 seconds
    if specChanged or not self.lastSpecDebugTime or (GetTime() - self.lastSpecDebugTime) > 60 then
        if self.debugMode then
            self:Debug("Detected spec: " .. spec .. " with " .. highestPoints .. " points")
        end
        self.lastSpecDebugTime = GetTime()
    end
    
    return spec
end

-- Force spec refresh function - FIXED to reduce spam
function AC:RefreshPlayerSpec()
    -- Clear cache to force refresh
    self.cachedSpec = nil
    self.cachedSpecTime = nil
    local newSpec = self:GetPlayerSpec()
    
    -- Update UI if it exists
    if self.infoText then
        self.infoText:SetText(self:GetPlayerClass() .. " - " .. newSpec)
    end
    
    -- Only print if called manually, not automatically
    if not self.silentSpecRefresh then
        self:Print("Spec refreshed: " .. newSpec)
    end
    return newSpec
end

-- Enhanced talent loading detection - FIXED to reduce spam
function AC:EnsureTalentsLoaded()
    local attempts = 0
    local maxAttempts = 5 -- Reduced attempts
    
    local function CheckTalents()
        attempts = attempts + 1
        
        -- Check if any talent tab has talents
        local hasData = false
        for i = 1, GetNumTalentTabs() do
            local numTalents = GetNumTalents(i)
            if numTalents and numTalents > 0 then
                hasData = true
                break
            end
        end
        
        if hasData then
            if self.debugMode and not self.talentsLoadedLogged then
                self:Debug("Talents loaded after " .. attempts .. " attempts")
                self.talentsLoadedLogged = true
            end
            -- Silent refresh to prevent spam
            self.silentSpecRefresh = true
            self:RefreshPlayerSpec()
            self.silentSpecRefresh = false
            return true
        elseif attempts < maxAttempts then
            -- Try again in 2 seconds (increased delay)
            local retryFrame = CreateFrame("Frame")
            local elapsed = 0
            retryFrame:SetScript("OnUpdate", function(self, dt)
                elapsed = elapsed + dt
                if elapsed >= 2 then
                    retryFrame:SetScript("OnUpdate", nil)
                    CheckTalents()
                end
            end)
        else
            if self.debugMode and not self.talentsFailedLogged then
                self:Debug("Failed to load talents after " .. maxAttempts .. " attempts")
                self.talentsFailedLogged = true
            end
        end
        
        return false
    end
    
    return CheckTalents()
end

-- Enhanced event registration for spec detection - FIXED to reduce spam
function AC:SetupSpecDetection()
    -- Register for talent-related events with throttling
    self:RegisterEvent("PLAYER_TALENT_UPDATE", function()
        -- Throttle talent updates to prevent spam
        if self:Throttle("TalentUpdate", 3) then
            if self.debugMode then
                self:Debug("PLAYER_TALENT_UPDATE fired")
            end
            self.silentSpecRefresh = true
            self:RefreshPlayerSpec()
            self.silentSpecRefresh = false
        end
    end)
    
    self:RegisterEvent("CHARACTER_POINTS_CHANGED", function()
        -- Throttle character point changes
        if self:Throttle("CharacterPointsChanged", 3) then
            if self.debugMode then
                self:Debug("CHARACTER_POINTS_CHANGED fired")
            end
            self.silentSpecRefresh = true
            self:RefreshPlayerSpec()
            self.silentSpecRefresh = false
        end
    end)
    
    self:RegisterEvent("PLAYER_ENTERING_WORLD", function()
        -- Only debug this once per session
        if self.debugMode and not self.enteringWorldLogged then
            self:Debug("PLAYER_ENTERING_WORLD fired")
            self.enteringWorldLogged = true
        end
        -- Delay spec detection to ensure data is loaded
        local delayFrame = CreateFrame("Frame")
        local elapsed = 0
        delayFrame:SetScript("OnUpdate", function(self, dt)
            elapsed = elapsed + dt
            if elapsed >= 3 then -- Increased delay to 3 seconds
                AC:EnsureTalentsLoaded()
                delayFrame:SetScript("OnUpdate", nil)
            end
        end)
    end)
    
    self:RegisterEvent("ADDON_LOADED", function(event, addonName)
        if addonName == AddonName then
            if self.debugMode and not self.addonLoadedLogged then
                self:Debug("Addon loaded, checking talents")
                self.addonLoadedLogged = true
            end
            self:EnsureTalentsLoaded()
        end
    end)
end

-- Manual spec detection command - FIXED output
function AC:ForceSpecDetection()
    self:Print("=== MANUAL SPEC DETECTION ===")
    
    -- Clear cache for fresh detection
    self.cachedSpec = nil
    self.cachedSpecTime = nil
    
    -- Check talent loading status
    local talentTabs = GetNumTalentTabs()
    self:Print("Talent tabs available: " .. (talentTabs or 0))
    
    for i = 1, (talentTabs or 0) do
        local name, _, pointsSpent = GetTalentTabInfo(i)
        local numTalents = GetNumTalents(i)
        self:Print("  Tab " .. i .. ": " .. (name or "Unknown") .. " - " .. (pointsSpent or 0) .. " points, " .. (numTalents or 0) .. " talents")
    end
    
    -- Force refresh
    local spec = self:RefreshPlayerSpec()
    self:Print("Detected spec: " .. spec)
    
    self:Print("=============================")
end

-- Get player class
function AC:GetPlayerClass()
    local _, class = UnitClass("player")
    return class
end

-- Get player health percentage
function AC:GetPlayerHealthPercent()
    return UnitHealth("player") / UnitHealthMax("player") * 100
end

-- Get target health percentage
function AC:GetTargetHealthPercent(unit)
    unit = unit or "target"
    if not UnitExists(unit) then return 0 end
    return UnitHealth(unit) / UnitHealthMax(unit) * 100
end

-- Player movement detection
function AC:IsPlayerMoving()
    return GetUnitSpeed("player") > 0
end

-- =============================================
-- ENHANCED TARGET ANALYSIS
-- =============================================

-- Get target priority based on threat and value
function AC:GetTargetPriority(unit)
    if not UnitExists(unit) then return 0 end
    
    local priority = 0
    local hp = self:GetTargetHealthPercent(unit)
    local classification = UnitClassification(unit)
    local level = UnitLevel(unit)
    local playerLevel = UnitLevel("player")
    
    -- Base priority by health (lower health = higher priority for execute)
    priority = 100 - hp
    
    -- Adjust for mob type
    if classification == "elite" then
        priority = priority + 20
    elseif classification == "rare" or classification == "rareelite" then
        priority = priority + 30
    elseif classification == "worldboss" then
        priority = priority + 50
    end
    
    -- Adjust for level difference
    local levelDiff = level - playerLevel
    if levelDiff > 2 then
        priority = priority + 10 -- Prioritize higher level threats
    elseif levelDiff < -2 then
        priority = priority - 10 -- Deprioritize low level mobs
    end
    
    -- Prioritize targets that are attacking the player
    if UnitExists(unit.."target") and UnitIsUnit(unit.."target", "player") then
        priority = priority + 25
    end
    
    -- Prioritize casters
    if UnitCastingInfo(unit) then
        priority = priority + 15
    end
    
    return math.max(priority, 0)
end

-- =============================================
-- UNIVERSAL TANK LOOSE MOB DETECTION SYSTEM
-- =============================================

-- Tank ability mappings by class (WotLK 3.3.5a specific)
AC.TankAbilities = {
    WARRIOR = {
        taunt = "Taunt",
        aoe_taunt = "Challenging Shout", 
        threat_abilities = {"Shield Slam", "Revenge", "Devastate", "Sunder Armor", "Thunder Clap"},
        gap_closers = {"Charge", "Intercept"},
        tank_stance = function() 
            -- Defensive Stance = form 2 in WotLK
            return GetShapeshiftForm() == 2 
        end,
        taunt_range = 30,
        aoe_taunt_range = 10
    },
    PALADIN = {
        taunt = "Hand of Reckoning",
        alt_taunt = "Righteous Defense", -- Multi-target taunt
        aoe_taunt = "Consecration", -- Not a taunt but AoE threat
        threat_abilities = {"Hammer of the Righteous", "Shield of Righteousness", "Consecration"},
        tank_stance = function() 
            -- Paladins don't have stance requirements
            return true 
        end,
        taunt_range = 30,
        alt_taunt_range = 40,
        aoe_taunt_range = 8
    },
    DRUID = {
        taunt = "Growl",
        aoe_taunt = "Challenging Roar",
        threat_abilities = {"Mangle (Bear)", "Swipe (Bear)", "Lacerate", "Maul"},
        tank_stance = function() 
            -- Bear Form = form 1, Dire Bear Form = form 1 in WotLK
            return GetShapeshiftForm() == 1 
        end,
        taunt_range = 30,
        aoe_taunt_range = 10
    },
    DEATHKNIGHT = {
        taunt = "Dark Command",
        pull_taunt = "Death Grip", -- Unique pull + taunt
        aoe_threat = "Death and Decay", -- AoE threat, not taunt
        threat_abilities = {"Icy Touch", "Rune Strike", "Death and Decay"},
        gap_closers = {"Death Grip"},
        tank_stance = function() 
            -- Check for Frost Presence buff
            for i = 1, 40 do
                local name = UnitBuff("player", i)
                if name and name == "Frost Presence" then
                    return true
                end
            end
            return false
        end,
        taunt_range = 30,
        pull_taunt_range = 30,
        aoe_threat_range = 30
    }
}

-- Initialize tank tracking tables
AC.expectedThreatTargets = AC.expectedThreatTargets or {}
AC.lastTauntTime = AC.lastTauntTime or 0
AC.lastTauntTarget = AC.lastTauntTarget or ""
AC.universalTauntHistory = AC.universalTauntHistory or {}

function AC:GetTankThreatState(unit)
    if self:GetGroupSize() > 5 then return nil end
    if not UnitExists(unit) or not UnitCanAttack("player", unit) or UnitIsDead(unit) then return nil end

    local threatState = nil
    if type(UnitDetailedThreatSituation) == "function" then
        local ok, isTanking, status, scaledPercent, rawPercent, threatValue = pcall(UnitDetailedThreatSituation, "player", unit)
        if ok and status ~= nil then
            threatState = {
                isTanking = isTanking,
                status = status,
                scaledPercent = scaledPercent,
                rawPercent = rawPercent,
                threatValue = threatValue
            }
        end
    end

    if not threatState and type(UnitThreatSituation) == "function" then
        local ok, status = pcall(UnitThreatSituation, "player", unit)
        if ok then
            threatState = {
                status = status
            }
        end
    end

    return threatState
end

function AC:GetTankThreatPriorityBonus(unit, inMeleeRange, groupSize, threatState)
    if groupSize > 5 then return 0 end

    threatState = threatState or self:GetTankThreatState(unit)
    if not threatState or threatState.status == nil then return 0 end

    local status = threatState.status
    local bonus = 0

    if inMeleeRange then
        if status <= 0 then
            bonus = 75
        elseif status == 1 then
            bonus = 55
        elseif status == 2 then
            bonus = 30
        else
            bonus = 10
        end
    else
        if status <= 0 then
            bonus = 28
        elseif status == 1 then
            bonus = 18
        elseif status == 2 then
            bonus = 10
        else
            bonus = 0
        end
    end

    local targetUnit = unit .. "target"
    if UnitExists(targetUnit) and UnitIsFriend("player", targetUnit) and not UnitIsUnit(targetUnit, "player") then
        bonus = bonus + 12
    end

    return bonus
end

function AC:GetTankThreatRiskScore(unit, threatState)
    if self:GetGroupSize() > 5 then return 0 end
    if not UnitExists(unit) or not UnitCanAttack("player", unit) or UnitIsDead(unit) then return 0 end

    threatState = threatState or self:GetTankThreatState(unit)
    if not threatState or threatState.status == nil then return 0 end

    local status = threatState.status
    local score = 0

    if status <= 0 then
        score = score + 90
    elseif status == 1 then
        score = score + 75
    elseif status == 2 then
        score = score + 45
    end

    local scaledPercent = threatState.scaledPercent or threatState.rawPercent
    if scaledPercent then
        if scaledPercent >= 95 then
            score = score + 60
        elseif scaledPercent >= 80 then
            score = score + 40
        elseif scaledPercent >= 65 then
            score = score + 20
        end
    end

    local targetUnit = unit .. "target"
    if UnitExists(targetUnit) and UnitIsFriend("player", targetUnit) and not UnitIsUnit(targetUnit, "player") then
        score = score + 70
    end

    return score
end

-- Universal tank detection (WotLK 3.3.5a compatible)
function AC:IsTankSpec(unit)
    unit = unit or "player"
    if not UnitExists(unit) then return false end
    
    local _, class = UnitClass(unit)
    local abilities = self.TankAbilities[class]
    
    if not abilities then return false end
    
    -- For player, check stance/form and spell knowledge
    if UnitIsUnit(unit, "player") then
        return abilities.tank_stance() and self:KnowsSpell(abilities.taunt)
    end
    
    -- For other units, check class and stance/form indicators
    if class == "WARRIOR" then
        -- Check if in defensive stance (limited detection for other players)
        return true -- Assume tank if warrior (can't reliably detect other players' stances)
    elseif class == "PALADIN" then
        -- Paladins don't have visible stance indicators
        return true -- Assume tank capability
    elseif class == "DRUID" then
        -- Check for bear form
        for i = 1, 40 do
            local name = UnitBuff(unit, i)
            if name and (name == "Bear Form" or name == "Dire Bear Form") then
                return true
            end
        end
        return false
    elseif class == "DEATHKNIGHT" then
        -- Check for frost presence
        for i = 1, 40 do
            local name = UnitBuff(unit, i)
            if name and name == "Frost Presence" then
                return true
            end
        end
        return false
    end
    
    return false
end

function AC:IsAutoTargetSwitchAllowed()
    if not self:IsTankSpec() then
        return true
    end

    return self:GetGroupSize() <= 5
end

function AC:GetTankAbilitiesForUnit(unit)
    unit = unit or "player"
    local _, class = UnitClass(unit)
    return class and self.TankAbilities[class] or nil
end

function AC:GetTankAbilitiesForPlayer()
    return self:GetTankAbilitiesForUnit("player")
end

function AC:IsInSpellRangeSafe(spellName, unit)
    if not spellName or not UnitExists(unit) then return false end
    local ok, result = pcall(IsSpellInRange, spellName, unit)
    return ok and result == 1
end

function AC:IsInMeleeRange(unit, strict)
    unit = unit or "target"
    if not UnitExists(unit) or not UnitCanAttack("player", unit) or UnitIsDeadOrGhost(unit) then
        return false
    end

    local _, class = UnitClass("player")
    local classMeleeSpells = {
        WARRIOR = {"Shield Slam", "Revenge", "Devastate", "Heroic Strike", "Mortal Strike", "Bloodthirst"},
        PALADIN = {"Hammer of the Righteous", "Shield of Righteousness", "Crusader Strike"},
        DRUID = {"Maul", "Mangle (Bear)", "Swipe (Bear)", "Lacerate"},
        DEATHKNIGHT = {"Heart Strike", "Blood Strike", "Plague Strike", "Rune Strike"},
    }

    local spells = classMeleeSpells[class]
    if spells then
        local sawValidRangeResult = false
        for _, spellName in ipairs(spells) do
            if self:KnowsSpell(spellName) or self:IsUsableSpell(spellName) then
                local ok, inRange = pcall(IsSpellInRange, spellName, unit)
                if ok and inRange ~= nil then
                    sawValidRangeResult = true
                    if inRange == 1 then
                        return true
                    end
                end
            end
        end

        if sawValidRangeResult then
            return false
        end
    end

    if strict then
        return false
    end

    local success, result = pcall(CheckInteractDistance, unit, 3)
    return success and result or false
end

function AC:GetTankMovementAbility(unit)
    unit = unit or "target"
    if not UnitExists(unit) or not UnitCanAttack("player", unit) or UnitIsDeadOrGhost(unit) then
        return nil
    end

    local _, class = UnitClass("player")
    if class == "WARRIOR" then
        local isProtection = self.GetPlayerSpec and self:GetPlayerSpec() == "Protection"
        local inCombat = UnitAffectingCombat("player")

        if self:KnowsSpell("Charge") and self:IsUsableSpell("Charge") and self:GetSpellCooldown("Charge") == 0 and
           self:IsInSpellRangeSafe("Charge", unit) then
            if not inCombat then
                return "Charge"
            end

            if isProtection and self.HasWarbringerTalent and self:HasWarbringerTalent() then
                return "Charge"
            end
        end

        if self:KnowsSpell("Intercept") and self:IsUsableSpell("Intercept") and self:GetSpellCooldown("Intercept") == 0 and
           ((self.HasWarbringerTalent and self:HasWarbringerTalent()) or (self.GetCurrentStance and self:GetCurrentStance() == 3)) and
           self:IsInSpellRangeSafe("Intercept", unit) then
            return "Intercept"
        end
    elseif class == "DEATHKNIGHT" then
        if self:KnowsSpell("Death Grip") and self:IsUsableSpell("Death Grip") and self:GetSpellCooldown("Death Grip") == 0 and
           self:IsInSpellRangeSafe("Death Grip", unit) then
            return "Death Grip"
        end
    end

    return nil
end

function AC:GetTankActionResponse(unit)
    unit = unit or "target"
    if not UnitExists(unit) or not UnitCanAttack("player", unit) or UnitIsDeadOrGhost(unit) then
        return nil
    end

    if self:IsInMeleeRange(unit, true) then
        return "melee"
    end

    local abilities = self:GetTankAbilitiesForPlayer()
    if abilities and self.CanTauntTarget then
        local tauntAbility = self:CanTauntTarget(unit, abilities)
        if tauntAbility then
            return tauntAbility
        end
    end

    return self:GetTankMovementAbility(unit)
end

function AC:GetTankTargetPriority(unit)
    if not UnitExists(unit) or not UnitCanAttack("player", unit) or UnitIsDead(unit) then
        return 0
    end

    local priority = 0
    local groupSize = self:GetGroupSize()
    local hp = self:GetTargetHealthPercent(unit)
    local classification = UnitClassification(unit)
    local level = UnitLevel(unit)
    local playerLevel = UnitLevel("player")
    local inMeleeRange = self:IsInMeleeRange(unit, true)
    local threatState = self:GetTankThreatState(unit)
    local movementAbility = self:GetTankMovementAbility(unit)
    local abilities = self:GetTankAbilitiesForPlayer()

    priority = 100 - hp

    if inMeleeRange then
        priority = priority + 100
    else
        if movementAbility then
            priority = priority + 18
        elseif abilities and abilities.taunt and self:IsInSpellRangeSafe(abilities.taunt, unit) then
            priority = priority + 20
        elseif abilities and abilities.pull_taunt and self:IsInSpellRangeSafe(abilities.pull_taunt, unit) then
            priority = priority + 20
        else
            priority = priority - 200
        end
    end

    if classification == "elite" then
        priority = priority + 25
    elseif classification == "rare" or classification == "rareelite" then
        priority = priority + 35
    elseif classification == "worldboss" then
        priority = priority + 50
    end

    local levelDiff = level - playerLevel
    if levelDiff > 2 then
        priority = priority + 15
    elseif levelDiff < -3 then
        priority = priority - 20
    end

    local unitTarget = unit .. "target"
    if UnitExists(unitTarget) then
        if UnitIsUnit(unitTarget, "player") then
            priority = priority + 30
        elseif UnitIsFriend("player", unitTarget) then
            local _, targetClass = UnitClass(unitTarget)
            if targetClass == "PRIEST" or targetClass == "PALADIN" or
               targetClass == "SHAMAN" or targetClass == "DRUID" then
                priority = priority + 40
            else
                priority = priority + 25
            end
        end
    end

    if UnitCastingInfo(unit) then
        priority = priority + 20
    end

    local unitGUID = UnitGUID(unit)
    if unitGUID and self.expectedThreatTargets and self.expectedThreatTargets[unitGUID] then
        local timeSinceMarked = GetTime() - self.expectedThreatTargets[unitGUID]
        if timeSinceMarked < 15 and (inMeleeRange or groupSize > 5) then
            priority = priority + 35
        end
    end

    if self.lastTauntTarget and unitGUID == self.lastTauntTarget then
        local timeSinceTaunt = GetTime() - (self.lastTauntTime or 0)
        if timeSinceTaunt < 15 and (inMeleeRange or groupSize > 5) then
            priority = priority + 50
        end
    end

    local threatBonus = self:GetTankThreatPriorityBonus(unit, inMeleeRange, groupSize, threatState)
    if threatBonus > 0 then
        priority = priority + threatBonus
    end

    local threatRisk = self:GetTankThreatRiskScore(unit, threatState)
    if threatRisk > 0 then
        if inMeleeRange then
            priority = priority + threatRisk
        else
            priority = priority + math.floor(threatRisk * 0.5)
        end
    end

    return math.max(priority, 0)
end

function AC:FindBestTankTarget(meleeOnly, ignoreThrottle, excludeGUID)
    if not ignoreThrottle and not self:Throttle("FindBestTankTarget", 0.2) then
        return UnitExists("target") and "target" or nil, self:GetTankTargetPriority("target")
    end

    local bestTarget = nil
    local highestPriority = 0
    local currentTarget = UnitExists("target") and "target" or nil
    local currentInMelee = currentTarget and self:IsInMeleeRange(currentTarget, true)

    local currentGUID = currentTarget and UnitGUID(currentTarget)
    if currentTarget and currentGUID ~= excludeGUID and UnitCanAttack("player", currentTarget) and not UnitIsDead(currentTarget) then
        if not meleeOnly or currentInMelee then
            local currentPriority = self:GetTankTargetPriority(currentTarget)
            if currentInMelee then
                currentPriority = currentPriority + 40
            end
            highestPriority = currentPriority
            bestTarget = currentTarget
        end
    end

    local candidates = {}
    local seenGUIDs = {}

    for i = 1, 20 do
        local unit = "nameplate" .. i
        if UnitExists(unit) and UnitCanAttack("player", unit) and not UnitIsDead(unit) then
            if not currentTarget or (not UnitIsUnit(unit, currentTarget) and UnitGUID(unit) ~= excludeGUID) then
                local guid = UnitGUID(unit)
                if guid and not seenGUIDs[guid] then
                    seenGUIDs[guid] = true
                    candidates[#candidates + 1] = {unit = unit, priority = self:GetTankTargetPriority(unit), name = UnitName(unit)}
                end
            end
        end
    end

    if IsInGroup() then
        local groupSize = math.min(self:GetGroupSize(), 40)
        local unitPrefix = GetNumRaidMembers() > 0 and "raid" or "party"

        for i = 1, groupSize do
            local groupTarget = unitPrefix .. i .. "target"
            if UnitExists(groupTarget) and UnitCanAttack("player", groupTarget) and not UnitIsDead(groupTarget) then
                if not currentTarget or (not UnitIsUnit(groupTarget, currentTarget) and UnitGUID(groupTarget) ~= excludeGUID) then
                    local guid = UnitGUID(groupTarget)
                    if guid and not seenGUIDs[guid] then
                        seenGUIDs[guid] = true
                        local priority = self:GetTankTargetPriority(groupTarget)
                        priority = priority + 15
                        if self:IsTankSpec(unitPrefix .. i) then
                            priority = priority + 25
                        end
                        candidates[#candidates + 1] = {unit = groupTarget, priority = priority, name = UnitName(groupTarget)}
                    end
                end
            end
        end
    end

    if self.combatEnemies then
        for guid, data in pairs(self.combatEnemies) do
            if GetTime() - data.lastSeen <= 3 then
                for i = 1, 20 do
                    local unit = "nameplate" .. i
                    if UnitExists(unit) and UnitGUID(unit) == guid then
                        if not currentTarget or (not UnitIsUnit(unit, currentTarget) and guid ~= excludeGUID) then
                            if not seenGUIDs[guid] then
                                seenGUIDs[guid] = true
                                candidates[#candidates + 1] = {unit = unit, priority = self:GetTankTargetPriority(unit) + 10, name = UnitName(unit)}
                            end
                        end
                        break
                    end
                end
            end
        end
    end

    for _, candidate in ipairs(candidates) do
        local candidateInMelee = self:IsInMeleeRange(candidate.unit, true)
        local canReachCandidate = candidateInMelee or self:GetTankActionResponse(candidate.unit) ~= nil
        if meleeOnly then
            canReachCandidate = candidateInMelee
        end

        if canReachCandidate then
            if candidateInMelee and not currentInMelee then
                candidate.priority = candidate.priority + 100
            elseif not candidateInMelee and currentInMelee then
                if candidate.priority < (highestPriority + 50) then
                    -- skip
                elseif candidate.priority - highestPriority >= 75 and candidate.priority > highestPriority then
                    highestPriority = candidate.priority
                    bestTarget = candidate.unit
                end
            elseif candidate.priority > highestPriority then
                highestPriority = candidate.priority
                bestTarget = candidate.unit
            end
        end
    end

    return bestTarget, highestPriority
end

function AC:ShouldSwitchTankTarget()
    if not UnitExists("target") then return true end
    if not self:IsAutoTargetSwitchAllowed() and UnitCanAttack("player", "target") and not UnitIsDead("target") then
        return false
    end

    local currentTarget = "target"
    local currentGUID = UnitGUID(currentTarget)
    local currentInMelee = self:IsInMeleeRange(currentTarget, true)
    local currentPriority = self:GetTankTargetPriority(currentTarget)
    local groupSize = self:GetGroupSize()
    local currentThreatState = groupSize <= 5 and self:GetTankThreatState(currentTarget) or nil

    if currentGUID and self.lastTauntTarget == currentGUID then
        local tauntAge = GetTime() - (self.lastTauntTime or 0)
        local recentTaunt = tauntAge < 6
        if recentTaunt then
            local meleeTarget = self:FindBestTankTarget(true, true, currentGUID)
            if meleeTarget and not UnitIsUnit(meleeTarget, currentTarget) then
                if self.debugMode then
                    self:Debug("Recent taunt: returning to melee target " .. (UnitName(meleeTarget) or "Unknown"))
                end
                return true
            end

            if not currentInMelee then
                if self.debugMode then
                    self:Debug("Recent taunt: ranged target not in melee, releasing hold")
                end
                self.lastTauntTarget = nil
                return false
            end

            if self.debugMode then
                self:Debug("Recent taunt: no melee alternative, holding target")
            end
            return false
        end
    end

    if UnitCanAttack("player", currentTarget) and not UnitIsDead(currentTarget) then
        local bestTarget, bestPriority = self:FindBestTankTarget(false, false, currentGUID)
        if bestTarget and not UnitIsUnit(bestTarget, currentTarget) then
            local bestInMelee = self:IsInMeleeRange(bestTarget, true)
            local bestThreatState = groupSize <= 5 and self:GetTankThreatState(bestTarget) or nil
            local currentThreatRisk = groupSize <= 5 and self:GetTankThreatRiskScore(currentTarget, currentThreatState) or 0
            local bestThreatRisk = groupSize <= 5 and self:GetTankThreatRiskScore(bestTarget, bestThreatState) or 0

            if currentInMelee then
                if bestInMelee and groupSize <= 5 and bestThreatRisk >= currentThreatRisk + 35 and bestPriority > currentPriority + 20 then
                    if self.debugMode then
                        self:Debug("Proactive threat switch: " .. (UnitName(bestTarget) or "Unknown") ..
                                   " risk " .. tostring(bestThreatRisk) .. " over " ..
                                   (UnitName(currentTarget) or "Unknown") .. " risk " .. tostring(currentThreatRisk))
                    end
                    return true
                end

                if not bestInMelee and bestPriority >= 200 then
                    if self.debugMode then
                        self:Debug("Proactive ranged switch blocked while current target is in melee")
                    end
                end
                return false
            end

            if bestInMelee then
                return true
            end

            if groupSize <= 5 then
                local currentThreatStatus = currentThreatState and currentThreatState.status
                local bestThreatStatus = bestThreatState and bestThreatState.status
                if bestThreatStatus ~= nil and currentThreatStatus ~= nil and bestThreatStatus < currentThreatStatus then
                    if self.debugMode then
                        self:Debug("Threat switch: " .. (UnitName(bestTarget) or "Unknown") .. " (status " .. tostring(bestThreatStatus) .. ") over " ..
                                   (UnitName(currentTarget) or "Unknown") .. " (status " .. tostring(currentThreatStatus) .. ")")
                    end
                    return true
                end
            end

            if bestPriority > currentPriority + 50 then
                return true
            end
        end
        return false
    end

    return true
end

function AC:UpdateTankTargeting()
    if not UnitAffectingCombat("player") then return false end
    if not self:Throttle("TankTargeting", 0.5) then return false end

    if self:ShouldSwitchTankTarget() then
        local currentGUID = UnitGUID("target")
        local bestTarget, priority

        if UnitExists("target") and UnitCanAttack("player", "target") and not self:IsInMeleeRange("target", true) then
            bestTarget, priority = self:FindBestTankTarget(true, true, currentGUID)
            if not bestTarget then
                return false
            end
        end

        if not bestTarget then
            bestTarget, priority = self:FindBestTankTarget(false, true, currentGUID)
        end

        if bestTarget then
            local oldTarget = UnitExists("target") and UnitName("target") or "None"
            TargetUnit(bestTarget)
            if not IsCurrentSpell("Attack") then
                StartAttack()
            end
            self:Debug("Tank target switch: " .. oldTarget .. " -> " .. (UnitName("target") or "Unknown") .. " (Priority: " .. priority .. ")")
            self:MarkAsOurTarget(UnitGUID("target"))
            return true
        end
    end

    return false
end

function AC:HandleTankTargeting()
    if not self:IsTankSpec() then return false end
    if self:GetGroupSize() > 5 then return false end
    if self:HandleTauntedLooseMobGapClosing() then return true end

    if self:HandleUniversalLooseMobs() then return true end

    local threatLoss = self.DetectThreatLoss and self:DetectThreatLoss() or nil
    if threatLoss and threatLoss.priority and threatLoss.priority >= 150 then
        if UnitExists(threatLoss.lostTarget) and UnitCanAttack("player", threatLoss.lostTarget) then
            local sameAsCurrentTarget = UnitExists("target") and UnitIsUnit(threatLoss.lostTarget, "target")
            local actionResponse = self.GetTankActionResponse and self:GetTankActionResponse(threatLoss.lostTarget) or nil

            if sameAsCurrentTarget then
                if self.TryImmediateTankTaunt and self:TryImmediateTankTaunt("target", threatLoss.newTarget) then
                    return true
                end

                if self.debugMode and self:Throttle("ThreatLossCurrentTargetDebug", 1.0) then
                    self:Debug("Threat loss on current target; allowing combat logic to act (" .. tostring(actionResponse or "none") .. ")")
                end
                return false
            end

            if not actionResponse then
                if self.debugMode then
                    self:Debug("Skipped threat-loss retarget to unreachable ranged enemy: " .. (UnitName(threatLoss.lostTarget) or "Unknown"))
                end
                return false
            end

            TargetUnit(threatLoss.lostTarget)
            if not IsCurrentSpell("Attack") then
                StartAttack()
            end
            self.lastTargetSwitch = GetTime()
            self:MarkAsOurTarget(UnitGUID("target"))
            return true
        end
    end

    if UnitAffectingCombat("player") and self:UpdateTankTargeting() then
        return true
    end

    return false
end

function AC:TrackTauntedLooseMob(guid, targetName)
    if not guid then return end

    self.tauntedLooseMobs = self.tauntedLooseMobs or {}
    self.tauntedLooseMobs[guid] = {
        name = targetName or "Unknown",
        tauntTime = GetTime(),
        needsGapCloser = true
    }
end

function AC:CleanupTauntedLooseMobs()
    if not self.tauntedLooseMobs then return end

    local now = GetTime()
    local toRemove = {}
    for guid, data in pairs(self.tauntedLooseMobs) do
        if now - data.tauntTime > 10 then
            toRemove[#toRemove + 1] = guid
        end
    end

    for _, guid in ipairs(toRemove) do
        self.tauntedLooseMobs[guid] = nil
    end
end

function AC:HandleTauntedLooseMobGapClosing()
    if not self.tauntedLooseMobs or not UnitExists("target") then return false end

    local targetGUID = UnitGUID("target")
    local tauntedData = self.tauntedLooseMobs[targetGUID]
    if not tauntedData or not tauntedData.needsGapCloser then
        return false
    end

    local timeSinceTaunt = GetTime() - tauntedData.tauntTime
    if timeSinceTaunt >= 6 then
        tauntedData.needsGapCloser = false
        local meleeTarget = self:FindBestTankTarget(true, true, targetGUID)
        if meleeTarget and UnitExists(meleeTarget) and not UnitIsUnit(meleeTarget, "target") then
            TargetUnit(meleeTarget)
            self.lastTargetSwitch = GetTime()
            self:MarkAsOurTarget(UnitGUID("target"))
            if not IsCurrentSpell("Attack") then
                StartAttack()
            end
            self:Debug("Taunted ranged mob timed out; returned to melee target " .. (UnitName("target") or "Unknown"))
            return true
        end
        return false
    end

    local movementAbility = self:GetTankMovementAbility("target")
    if not movementAbility and self:IsInMeleeRange("target", true) then
        tauntedData.needsGapCloser = false
        return false
    end
    if movementAbility then
        local moved = false
        local function castMovementAttempt(spellName, unit)
            if not spellName or not unit or not UnitExists(unit) then
                return false
            end

            if not self:IsUsableSpell(spellName) or self:GetSpellCooldown(spellName) > 0 then
                return false
            end

            CastSpellByName(spellName, unit)
            return true
        end

        moved = castMovementAttempt(movementAbility, "target")

        if moved then
            tauntedData.needsGapCloser = false
            self:MarkAsOurTarget(targetGUID)
            if self.RecordUniversalTaunt then
                self:RecordUniversalTaunt(targetGUID)
            end
            return true
        end
    end

    tauntedData.needsGapCloser = false
    local meleeTarget = self:FindBestTankTarget(true, true, targetGUID)
    if meleeTarget and UnitExists(meleeTarget) and not UnitIsUnit(meleeTarget, "target") then
        TargetUnit(meleeTarget)
        self.lastTargetSwitch = GetTime()
        self:MarkAsOurTarget(UnitGUID("target"))
        if not IsCurrentSpell("Attack") then
            StartAttack()
        end
        self:Debug("No gap closer for taunted ranged mob; returned to melee target " .. (UnitName("target") or "Unknown"))
        return true
    end

    return false
end

function AC:ShouldSkipTankRepeatTaunt(mobGUID, victimUnit)
    if self.WasRecentlyUniversalTaunted then
        local recentlyTaunted, elapsed = self:WasRecentlyUniversalTaunted(mobGUID, victimUnit)
        if recentlyTaunted then
            return true
        end
    end
    return false
end

function AC:RecordTankTaunt(mobGUID)
    if self.RecordUniversalTaunt then
        self:RecordUniversalTaunt(mobGUID)
    end
end

AC.SharedTrackTauntedLooseMob = AC.TrackTauntedLooseMob
AC.SharedCleanupTauntedLooseMobs = AC.CleanupTauntedLooseMobs
AC.SharedHandleTauntedLooseMobGapClosing = AC.HandleTauntedLooseMobGapClosing
AC.SharedShouldSkipTankRepeatTaunt = AC.ShouldSkipTankRepeatTaunt
AC.SharedRecordTankTaunt = AC.RecordTankTaunt

-- Group utilities
function AC:GetGroupSize()
    local raidMembers = GetNumRaidMembers()
    if raidMembers and raidMembers > 0 then
        return raidMembers
    end

    local partyMembers = GetNumPartyMembers()
    if partyMembers and partyMembers > 0 then
        return partyMembers + 1
    end

    return 1
end

function AC:IsAutoTauntAllowed()
    if self.db and self.db.profile and self.db.profile.autoTauntEnabled == false then
        return false
    end

    return true
end

function AC:IsProtectedRaidTankVictim(victimUnit, mobGUID)
    if not victimUnit or not UnitExists(victimUnit) or UnitIsUnit(victimUnit, "player") then
        return false
    end

    if self:GetGroupSize() <= 5 then
        return false
    end

    local _, victimClass = UnitClass(victimUnit)
    if not victimClass then
        return false
    end

    if victimClass == "WARRIOR" then
        return self:HasBuff(victimUnit, "Defensive Stance")
    end

    if victimClass == "PALADIN" then
        return self:HasBuff(victimUnit, "Righteous Fury")
    end

    if victimClass == "DRUID" then
        return self:HasBuff(victimUnit, "Bear Form") or self:HasBuff(victimUnit, "Dire Bear Form")
    end

    if victimClass == "DEATHKNIGHT" then
        return self:HasBuff(victimUnit, "Frost Presence")
    end

    return false
end

function AC:IsRaidTauntSafeVictim(victimUnit)
    if not victimUnit or not UnitExists(victimUnit) then
        return false
    end

    if self:GetGroupSize() <= 5 then
        return true
    end

    return not self:IsProtectedRaidTankVictim(victimUnit)
end

-- Universal loose mob priority calculation
function AC:CalculateUniversalLooseMobPriority(attackerUnit, targetUnit)
    if not UnitExists(attackerUnit) or not UnitExists(targetUnit) then return 0 end
    
    local priority = 100
    local _, targetClass = UnitClass(targetUnit)
    
    -- Healer protection (highest priority)
    if targetClass == "PRIEST" or targetClass == "PALADIN" or 
       targetClass == "SHAMAN" or targetClass == "DRUID" then
        priority = priority + 300
        self:Debug("Loose mob priority: Healer protection +300")
    -- DPS protection  
    elseif targetClass == "MAGE" or targetClass == "WARLOCK" or 
           targetClass == "HUNTER" or targetClass == "ROGUE" then
        priority = priority + 150
        self:Debug("Loose mob priority: DPS protection +150")
    -- Tank protection
    elseif targetClass == "WARRIOR" or targetClass == "DEATHKNIGHT" then
        priority = priority + 200
        self:Debug("Loose mob priority: Tank protection +200")
    end
    
    -- Health urgency (WotLK 3.3.5a compatible)
    local targetHP = UnitHealth(targetUnit) / UnitHealthMax(targetUnit) * 100
    if targetHP < 30 then
        priority = priority + 200 -- Critical health
        self:Debug("Loose mob priority: Critical health +200")
    elseif targetHP < 50 then
        priority = priority + 100 -- Low health
        self:Debug("Loose mob priority: Low health +100")
    end
    
    -- Elite mobs get higher priority
    local classification = UnitClassification(attackerUnit)
    if classification == "elite" or classification == "rareelite" then
        priority = priority + 100
        self:Debug("Loose mob priority: Elite mob +100")
    end
    
    -- Distance factor (closer = higher priority)
    if CheckInteractDistance(attackerUnit, 3) then -- ~10 yards
        priority = priority + 50
        self:Debug("Loose mob priority: Close range +50")
    end
    
    -- Previously our target bonus
    local attackerGUID = UnitGUID(attackerUnit)
    if attackerGUID and self.expectedThreatTargets[attackerGUID] then
        local timeSinceMarked = GetTime() - self.expectedThreatTargets[attackerGUID]
        if timeSinceMarked < 15 then
            priority = priority + 250
            self:Debug("Loose mob priority: Previously our target +250")
        end
    end
    
    return priority
end

-- Universal taunt capability check (WotLK 3.3.5a compatible)
function AC:CanTauntTarget(unit, abilities)
    if not UnitExists(unit) or not abilities then return false end
    
    -- Check primary taunt
    if abilities.taunt and self:IsUsableSpell(abilities.taunt) then
        local ok, rangeResult = pcall(IsSpellInRange, abilities.taunt, unit)
        local inRange = ok and rangeResult == 1
        local notOnCooldown = self:GetSpellCooldown(abilities.taunt) == 0
        if inRange and notOnCooldown then
            return abilities.taunt
        end
    end
    
    -- Check alternative taunt (Paladin Righteous Defense)
    if abilities.alt_taunt and self:IsUsableSpell(abilities.alt_taunt) then
        local ok, rangeResult = pcall(IsSpellInRange, abilities.alt_taunt, unit)
        local inRange = ok and rangeResult == 1
        local notOnCooldown = self:GetSpellCooldown(abilities.alt_taunt) == 0
        if inRange and notOnCooldown then
            return abilities.alt_taunt
        end
    end
    
    -- Check Death Knight Death Grip (pull + taunt)
    if abilities.pull_taunt and self:IsUsableSpell(abilities.pull_taunt) then
        local ok, rangeResult = pcall(IsSpellInRange, abilities.pull_taunt, unit)
        local inRange = ok and rangeResult == 1
        local notOnCooldown = self:GetSpellCooldown(abilities.pull_taunt) == 0
        if inRange and notOnCooldown then
            return abilities.pull_taunt
        end
    end
    
    return false
end

function AC:TryImmediateTankTaunt(unit, victimUnit)
    if not unit or not UnitExists(unit) or not UnitCanAttack("player", unit) or UnitIsDeadOrGhost(unit) then
        return false
    end

    local abilities = self:GetTankAbilitiesForPlayer()
    if not abilities then return false end

    local tauntAbility = self:CanTauntTarget(unit, abilities)
    if not tauntAbility then return false end

    local mobGUID = UnitGUID(unit)
    if mobGUID and self:ShouldSkipTankRepeatTaunt(mobGUID, victimUnit) then
        if self.debugMode and self:Throttle("ImmediateTankTauntSkip", 1.0) then
            self:Debug("Immediate tank taunt skipped on " .. (UnitName(unit) or "Unknown") .. " - recently taunted")
        end
        return false
    end

    local castUnit = unit
    if tauntAbility == "Righteous Defense" and victimUnit and UnitExists(victimUnit) then
        castUnit = victimUnit
    end

    CastSpellByName(tauntAbility, castUnit)

    if mobGUID then
        self.lastTauntTime = GetTime()
        self.lastTauntTarget = mobGUID
        self:RecordTankTaunt(mobGUID)
        self:MarkAsOurTarget(mobGUID)
        if self.TrackTauntedLooseMob then
            self:TrackTauntedLooseMob(mobGUID, UnitName(unit))
        end
    end

    if self.debugMode then
        self:Debug("Immediate tank taunt: " .. tauntAbility .. " on " .. (UnitName(unit) or "Unknown") ..
                   " for " .. (victimUnit and UnitName(victimUnit) or "Unknown"))
    end

    return true
end

-- Universal loose mob detection with WotLK 3.3.5a group functions
function AC:GetUniversalLooseMobs()
    if not self:IsTankSpec() then return {} end
    
    local looseMobs = {}
    local _, class = UnitClass("player")
    local abilities = self.TankAbilities[class]
    
    -- Method 1: Group member threat scan (WotLK 3.3.5a compatible)
    local numMembers = GetNumPartyMembers() + GetNumRaidMembers()
    if numMembers > 0 then
        local maxMembers = GetNumRaidMembers() > 0 and GetNumRaidMembers() or GetNumPartyMembers()
        local unitPrefix = GetNumRaidMembers() > 0 and "raid" or "party"
        
        for i = 1, maxMembers do
            local unit = unitPrefix .. i
            if UnitExists(unit) and not UnitIsUnit(unit, "player") then
                local attacker = unit .. "target"
                if UnitExists(attacker) and UnitCanAttack("player", attacker) and not UnitIsDead(attacker) then
                    -- Check if mob is attacking group member but not us
                    local mobTarget = attacker .. "target"
                    if UnitExists(mobTarget) and UnitIsUnit(mobTarget, unit) and not UnitIsUnit(mobTarget, "player") then
                        if self:IsRaidTauntSafeVictim(unit) then
                            local priority = self:CalculateUniversalLooseMobPriority(attacker, unit)
                            if priority > 100 then -- Lowered threshold for better loose mob detection
                                local tauntAbility = self:CanTauntTarget(attacker, abilities)
                                if tauntAbility then
                                    table.insert(looseMobs, {
                                        unit = attacker,
                                        priority = priority,
                                        source = "group_scan",
                                        tauntAbility = tauntAbility,
                                        victimUnit = unit
                                    })
                                    self:Debug("Found loose mob via group scan: " .. (UnitName(attacker) or "Unknown") .. " attacking " .. (UnitName(unit) or "Unknown"))
                                end
                            end
                        else
                            self:Debug("Skipped raid tank victim for loose mob handling: " .. (UnitName(unit) or "Unknown"))
                        end
                    end
                end
            end
        end
    end
    
    -- Method 2: Enhanced nameplate scan (WotLK 3.3.5a compatible)
    for i = 1, 40 do
        local unit = "nameplate" .. i
        if UnitExists(unit) and UnitCanAttack("player", unit) and not UnitIsDead(unit) then
            local target = unit .. "target"
            if UnitExists(target) and UnitIsFriend("player", target) and not UnitIsUnit(target, "player") then
                -- Enemy attacking friendly = potential loose mob
                if self:IsRaidTauntSafeVictim(target) then
                    local priority = self:CalculateUniversalLooseMobPriority(unit, target)
                    if priority > 75 then
                        local tauntAbility = self:CanTauntTarget(unit, abilities)
                        if tauntAbility then
                            -- Check if not already in list
                            local exists = false
                            for _, existing in ipairs(looseMobs) do
                                if UnitIsUnit(existing.unit, unit) then
                                    exists = true
                                    break
                                end
                            end
                            
                            if not exists then
                                table.insert(looseMobs, {
                                    unit = unit,
                                    priority = priority,
                                    source = "nameplate",
                                    tauntAbility = tauntAbility,
                                    victimUnit = target
                                })
                                self:Debug("Found loose mob via nameplate: " .. (UnitName(unit) or "Unknown") .. " attacking " .. (UnitName(target) or "Unknown"))
                            end
                        end
                    end
                else
                    self:Debug("Skipped raid tank victim for loose mob handling: " .. (UnitName(target) or "Unknown"))
                end
            end
        end
    end
    
    -- Sort by priority (highest first)
    table.sort(looseMobs, function(a, b) return a.priority > b.priority end)
    
    return looseMobs
end

-- Mark target as ours for tracking (universal version)
function AC:MarkAsOurTarget(unitGUID)
    if unitGUID then
        self.expectedThreatTargets = self.expectedThreatTargets or {}
        self.expectedThreatTargets[unitGUID] = GetTime()
        self:Debug("Marked target as ours: " .. (UnitName("target") or "Unknown"))
    end
end

function AC:WasRecentlyUniversalTaunted(mobGUID, victimUnit)
    if not mobGUID then return false end
    self.universalTauntHistory = self.universalTauntHistory or {}

    local lastTaunt = self.universalTauntHistory[mobGUID]
    if not lastTaunt then return false end

    local elapsed = GetTime() - lastTaunt
    if elapsed >= 6 then return false end

    -- If the ally is about to die, allow a second taunt attempt sooner.
    if victimUnit and UnitExists(victimUnit) then
        local maxHealth = UnitHealthMax(victimUnit)
        local victimHP = maxHealth > 0 and (UnitHealth(victimUnit) / maxHealth * 100) or 100
        if victimHP < 35 then
            return false
        end
    end

    return true, elapsed
end

function AC:RecordUniversalTaunt(mobGUID)
    if not mobGUID then return end
    self.universalTauntHistory = self.universalTauntHistory or {}
    self.universalTauntHistory[mobGUID] = GetTime()
end

-- Clean up old threat targets (universal version)
function AC:CleanupThreatTargets()
    if not self.expectedThreatTargets then return end
    
    local now = GetTime()
    local toRemove = {}
    
    -- Collect entries to remove (older than 30 seconds)
    for guid, timestamp in pairs(self.expectedThreatTargets) do
        if now - timestamp > 30 then
            table.insert(toRemove, guid)
        end
    end
    
    -- Remove collected entries
    for _, guid in ipairs(toRemove) do
        self.expectedThreatTargets[guid] = nil
    end

    if self.universalTauntHistory then
        local oldTaunts = {}
        for guid, timestamp in pairs(self.universalTauntHistory) do
            if now - timestamp > 20 then
                table.insert(oldTaunts, guid)
            end
        end
        for _, guid in ipairs(oldTaunts) do
            self.universalTauntHistory[guid] = nil
        end
    end
    
    -- Prevent memory leaks by limiting table size
    local count = 0
    for _ in pairs(self.expectedThreatTargets) do
        count = count + 1
        if count > 50 then
            self.expectedThreatTargets = {}
            break
        end
    end
end

-- Universal loose mob handler (main function called by all tank classes)
function AC:HandleUniversalLooseMobs()
    if not self:IsTankSpec() then return false end
    if not self:IsAutoTauntAllowed() then return false end
    if not self:Throttle("UniversalLooseMobCheck", 0.3) then return false end
    
    -- Clean up old threat targets periodically
    if self:Throttle("ThreatTargetCleanup", 10) then
        self:CleanupThreatTargets()
    end
    
    local looseMobs = self:GetUniversalLooseMobs()
    if #looseMobs == 0 then return false end
    
    local _, class = UnitClass("player")
    local abilities = self.TankAbilities[class]
    
    self:Debug("Found " .. #looseMobs .. " loose mobs to handle")

    local function startAttackOnCurrentTarget()
        if UnitExists("target") and UnitCanAttack("player", "target") and not IsCurrentSpell("Attack") then
            StartAttack()
        end
    end

    local function swapToBestMeleeTargetAfterTaunt()
        if not self:IsAutoTargetSwitchAllowed() then
            return false
        end

        local excludeGUID = UnitGUID("target")
        local meleeTarget, meleePriority = self:FindBestTankTarget(true, true, excludeGUID)
        if meleeTarget and UnitExists(meleeTarget) and not UnitIsUnit(meleeTarget, "target") then
            TargetUnit(meleeTarget)
            self.lastTargetSwitch = GetTime()
            self:MarkAsOurTarget(UnitGUID("target"))
            startAttackOnCurrentTarget()
            self:Debug("Swapped back to melee target after taunt: " .. (UnitName(meleeTarget) or "Unknown") ..
                       " (Priority: " .. tostring(meleePriority or 0) .. ")")
            return true
        end

        if self.debugMode then
            self:Debug("No melee target available after taunt")
        end
        return false
    end
    
    -- Handle highest priority loose mob first
    local highestPriority = looseMobs[1]
    local function recordTauntedLooseMob(unit)
        if not unit or not UnitExists(unit) then
            return nil
        end

        local mobGUID = UnitGUID(unit)
        if mobGUID then
            self.lastTauntTarget = mobGUID
            self.lastTauntTime = GetTime()
            self:RecordUniversalTaunt(mobGUID)
            self:MarkAsOurTarget(mobGUID)
            if self.TrackTauntedLooseMob then
                self:TrackTauntedLooseMob(mobGUID, UnitName(unit))
            end
        end

        return mobGUID
    end

    local function handlePostTauntTargeting()
        if not UnitExists("target") then
            return false
        end

        local currentGUID = UnitGUID("target")
        local tauntedData = currentGUID and self.tauntedLooseMobs and self.tauntedLooseMobs[currentGUID] or nil
        if tauntedData and tauntedData.needsGapCloser then
            local movementAbility = self.GetTankMovementAbility and self:GetTankMovementAbility("target") or nil
            if movementAbility then
                if self.debugMode then
                    self:Debug("Holding taunted ranged mob for gap closer: " .. (UnitName("target") or "Unknown") ..
                               " via " .. tostring(movementAbility))
                end
                return true
            end
        end

        if not swapToBestMeleeTargetAfterTaunt() then
            startAttackOnCurrentTarget()
        end

        return true
    end

    local function castSingleTargetTaunt(looseMob)
        if not looseMob or not looseMob.tauntAbility then
            return false
        end

        local function castTauntAttempt(spellName, unit)
            if not spellName or not unit or not UnitExists(unit) then
                return false
            end

            if not self:IsUsableSpell(spellName) or self:GetSpellCooldown(spellName) > 0 then
                return false
            end

            CastSpellByName(spellName, unit)
            return true
        end

        if looseMob.tauntAbility == "Righteous Defense" then
            if looseMob.victimUnit and UnitExists(looseMob.victimUnit) then
                if castTauntAttempt(looseMob.tauntAbility, looseMob.victimUnit) then
                    if looseMob.unit and UnitExists(looseMob.unit) then
                        TargetUnit(looseMob.unit)
                        recordTauntedLooseMob("target")
                    end
                    handlePostTauntTargeting()
                    return true
                end
            end
            return false
        end

        if not looseMob.unit or not UnitExists(looseMob.unit) then
            return false
        end

        TargetUnit(looseMob.unit)
        if castTauntAttempt(looseMob.tauntAbility, "target") then
            recordTauntedLooseMob("target")
            handlePostTauntTargeting()
            return true
        end

        if not self:IsInMeleeRange("target", true) then
            swapToBestMeleeTargetAfterTaunt()
        end
        return false
    end
    
    -- Strategic AoE taunt usage - less restrictive but smart conditions
    if #looseMobs >= 2 then
        -- Check for AoE taunt ability
        if abilities.aoe_taunt and self:IsUsableSpell(abilities.aoe_taunt) and self:GetSpellCooldown(abilities.aoe_taunt) == 0 then
            local canUseAoE = false
            local reason = ""
            
            -- Enhanced range and situation checking
            if abilities.aoe_taunt_range and abilities.aoe_taunt_range <= 10 then
                -- Close range AoE (Challenging Shout, Challenging Roar)
                local nearbyEnemies = 0
                local criticalSituation = false
                
                -- Check for enemies within AoE range using nameplate scan
                for i = 1, 40 do
                    local unitID = "nameplate" .. i
                    if UnitExists(unitID) and UnitCanAttack("player", unitID) and not UnitIsDead(unitID) then
                        if CheckInteractDistance(unitID, 3) then -- Within ~10 yards
                            nearbyEnemies = nearbyEnemies + 1
                        end
                    end
                end
                
                -- Check for critical situations requiring immediate AoE taunt
                for _, looseMob in ipairs(looseMobs) do
                    -- Critical: Healer being attacked
                    if looseMob.priority >= 400 then -- Healer (base 100 + 300 = 400)
                        criticalSituation = true
                        reason = "healer under attack"
                        break
                    -- Critical: Anyone at very low health (<30%) being attacked
                    elseif looseMob.priority >= 300 and looseMob.victimUnit and UnitExists(looseMob.victimUnit) then
                        local targetHP = UnitHealth(looseMob.victimUnit) / UnitHealthMax(looseMob.victimUnit) * 100
                        if targetHP < 30 then
                            criticalSituation = true
                            reason = "critical health ally (" .. string.format("%.0f", targetHP) .. "%)"
                            break
                        end
                    end
                end
                
                -- Use AoE taunt if:
                -- 1. Critical situation (protect healer/low health ally)
                -- 2. 3+ loose mobs and 2+ enemies in range
                -- 3. 4+ loose mobs (overwhelming threat)
                if criticalSituation then
                    canUseAoE = true
                    reason = "CRITICAL - " .. reason
                elseif #looseMobs >= 4 then
                    canUseAoE = true
                    reason = "overwhelming threat (" .. #looseMobs .. " loose mobs)"
                elseif #looseMobs >= 3 and nearbyEnemies >= 2 then
                    canUseAoE = true
                    reason = "tactical AoE (" .. #looseMobs .. " loose, " .. nearbyEnemies .. " in range)"
                end
                
            elseif abilities.aoe_taunt_range and abilities.aoe_taunt_range > 10 then
                -- Ranged AoE (Death and Decay) - can always use strategically
                canUseAoE = true
                reason = "ranged AoE threat"
            end
            
            if canUseAoE then
                CastSpellByName(abilities.aoe_taunt)
                startAttackOnCurrentTarget()
                self:Debug("Universal AoE taunt: " .. abilities.aoe_taunt .. " - " .. reason .. " (" .. #looseMobs .. " loose mobs)")
                return true
            end
        end
    end
    
    if highestPriority.priority >= 200 and highestPriority.tauntAbility then
        local mobGUID = UnitGUID(highestPriority.unit)
        local victimUnit = highestPriority.victimUnit
        local raidTauntSafe = self:IsRaidTauntSafeVictim(victimUnit)
        local recentlyTaunted, tauntElapsed = self:WasRecentlyUniversalTaunted(mobGUID, victimUnit)
        if recentlyTaunted then
            self:Debug("Skipped repeat universal taunt on " .. (UnitName(highestPriority.unit) or "Unknown") ..
                       " (" .. string.format("%.1f", tauntElapsed) .. "s since last taunt)")
            return false
        end
        
        if raidTauntSafe then
            if castSingleTargetTaunt(highestPriority) then
                self:Debug("Universal HIGH PRIORITY taunt: " .. highestPriority.tauntAbility .. " on " .. (UnitName(highestPriority.unit) or "Unknown") .. " (Priority: " .. highestPriority.priority .. ")")
                return true
            end
        else
            self:Debug("Skipped raid tank victim for universal taunt: " .. (UnitName(victimUnit) or "Unknown"))
            return false
        end
    end
    
    -- Strategic fallback: handle harder-to-prioritize threats if they still warrant attention
    if highestPriority.priority >= 300 and highestPriority.tauntAbility then
        -- Additional validation: ensure this is actually a worthwhile taunt
        local victimUnit = highestPriority.victimUnit
        if not victimUnit or not UnitExists(victimUnit) then
            return false
        end

            local targetHP = UnitHealth(victimUnit) / UnitHealthMax(victimUnit) * 100
            
            local mobGUID = UnitGUID(highestPriority.unit)
            local raidTauntSafe = self:IsRaidTauntSafeVictim(victimUnit)
            local recentlyTaunted, tauntElapsed = self:WasRecentlyUniversalTaunted(mobGUID, victimUnit)
            if recentlyTaunted then
                self:Debug("Skipped repeat strategic taunt on " .. (UnitName(highestPriority.unit) or "Unknown") ..
                           " (" .. string.format("%.1f", tauntElapsed) .. "s since last taunt)")
                return false
            end
            
            if raidTauntSafe and (targetHP < 50 or highestPriority.priority >= 400) then
                if castSingleTargetTaunt(highestPriority) then
                self:Debug("Universal STRATEGIC taunt: " .. highestPriority.tauntAbility .. " on " .. (UnitName(highestPriority.unit) or "Unknown") .. " (Priority: " .. highestPriority.priority .. ", HP: " .. string.format("%.0f", targetHP) .. "%)")
                return true
                end
            elseif not raidTauntSafe then
                self:Debug("Skipped strategic Taunt on raid tank victim: " .. (UnitName(victimUnit) or "Unknown"))
                return false
            else
                self:Debug("Skipped non-critical taunt: " .. (UnitName(highestPriority.unit) or "Unknown") .. " (Priority: " .. highestPriority.priority .. ", HP: " .. string.format("%.0f", targetHP) .. "%) - not critical enough")
            end
        end
    
    return false
end

-- ENHANCED: Threat loss detection for tanks (WotLK 3.3.5a compatible)
function AC:DetectThreatLoss()
    if not self:IsTankSpec() then return nil end
    if not UnitExists("target") or UnitIsDead("target") then return nil end
    
    local currentTarget = "target" 
    local currentTargetGUID = UnitGUID(currentTarget)
    
    -- Method 1: Check if our target is attacking someone else
    local targetTarget = currentTarget .. "target"
    if UnitExists(targetTarget) and not UnitIsUnit(targetTarget, "player") then
        -- Validation: Make sure this isn't a false positive
        -- Skip if target just switched recently (within 2 seconds)
        if not self.lastTargetSwitch or (GetTime() - self.lastTargetSwitch) > 2 then
            -- Our target is attacking someone else - we may have lost threat
            local threatTarget = targetTarget
            local threatTargetClass = select(2, UnitClass(threatTarget))
            local threatTargetHP = (UnitHealth(threatTarget) / UnitHealthMax(threatTarget)) * 100
            
            -- Additional validation: Only care if the threatened ally is in our group
            local isGroupMember = false
            if IsInGroup() then
                local groupSize = GetNumRaidMembers() > 0 and GetNumRaidMembers() or GetNumPartyMembers()
                local unitPrefix = GetNumRaidMembers() > 0 and "raid" or "party"
                
                for i = 1, groupSize do
                    local groupUnit = unitPrefix .. i
                    if UnitExists(groupUnit) and UnitIsUnit(groupUnit, threatTarget) then
                        isGroupMember = true
                        break
                    end
                end
                
                -- Also check if it's the player
                if UnitIsUnit(threatTarget, "player") then
                    isGroupMember = true
                end
            else
                -- Solo play - always care about player
                if UnitIsUnit(threatTarget, "player") then
                    isGroupMember = true
                end
            end
            
            -- Only proceed if this is a group member being threatened
            if not isGroupMember then return nil end
            
            -- Calculate threat loss priority
            local priority = 100
            
            -- High priority if healer is being attacked
            if threatTargetClass == "PRIEST" or threatTargetClass == "PALADIN" or 
               threatTargetClass == "SHAMAN" or threatTargetClass == "DRUID" then
                priority = priority + 300
            -- Medium priority for DPS
            elseif threatTargetClass == "MAGE" or threatTargetClass == "WARLOCK" or 
                   threatTargetClass == "HUNTER" or threatTargetClass == "ROGUE" then
                priority = priority + 150
            -- Tank priority
            elseif threatTargetClass == "WARRIOR" or threatTargetClass == "DEATHKNIGHT" then
                priority = priority + 200
            end
            
            -- Urgent if target is low health
            if threatTargetHP < 30 then
                priority = priority + 200
            elseif threatTargetHP < 50 then
                priority = priority + 100
            end
            
            -- Return threat loss info
            return {
                lostTarget = currentTarget,
                lostTargetGUID = currentTargetGUID,
                newTarget = threatTarget,
                priority = priority,
                reason = "target switched to " .. (UnitName(threatTarget) or "Unknown") .. " (" .. string.format("%.0f", threatTargetHP) .. "% HP)"
            }
        end
    end
    
    -- Method 2: Check if enemies in combat log are attacking others instead of us
    if self.combatEnemies then
        for guid, enemyData in pairs(self.combatEnemies) do
            if GetTime() - enemyData.lastSeen <= 2 then -- Recently seen enemy
                -- Try to find this enemy
                for i = 1, 20 do
                    local unit = "nameplate" .. i
                    if UnitExists(unit) and UnitGUID(unit) == guid then
                        local enemyTarget = unit .. "target"
                        if UnitExists(enemyTarget) and not UnitIsUnit(enemyTarget, "player") then
                            -- This enemy is attacking someone else
                            local threatTargetHP = (UnitHealth(enemyTarget) / UnitHealthMax(enemyTarget)) * 100
                            local threatTargetClass = select(2, UnitClass(enemyTarget))
                            
                            -- Only care about high-priority threat losses
                            local priority = 0
                            if threatTargetClass == "PRIEST" or threatTargetClass == "PALADIN" or 
                               threatTargetClass == "SHAMAN" or threatTargetClass == "DRUID" then
                                priority = 400 -- Healer in danger
                            elseif threatTargetHP < 30 then
                                priority = 300 -- Anyone critically injured
                            end
                            
                            if priority >= 300 then
                                return {
                                    lostTarget = unit,
                                    lostTargetGUID = guid,
                                    newTarget = enemyTarget,
                                    priority = priority,
                                    reason = "loose enemy attacking " .. (UnitName(enemyTarget) or "Unknown") .. " (" .. string.format("%.0f", threatTargetHP) .. "% HP)"
                                }
                            end
                        end
                        break
                    end
                end
            end
        end
    end
    
    return nil
end

-- Enhanced target selection for all classes
function AC:FindBestTarget()
    local bestTarget = nil
    local highestPriority = 0
    local currentTarget = UnitExists("target") and "target" or nil
    
    -- Check current target first
    if currentTarget and UnitCanAttack("player", currentTarget) and not UnitIsDead(currentTarget) then
        highestPriority = self:GetTargetPriority(currentTarget)
        bestTarget = currentTarget
    end
    
    -- Check other available targets
    for i = 1, 40 do
        local unit = "nameplate"..i
        if UnitExists(unit) and UnitCanAttack("player", unit) and not UnitIsDead(unit) then
            local priority = self:GetTargetPriority(unit)
            
            -- Add bonus for targets already in combat with group
            if IsInGroup() then
                for j = 1, 4 do
                    local partyUnit = "party"..j.."target"
                    if UnitExists(partyUnit) and UnitIsUnit(partyUnit, unit) then
                        priority = priority + 15
                        break
                    end
                end
            end
            
            if priority > highestPriority then
                highestPriority = priority
                bestTarget = unit
            end
        end
    end
    
    return bestTarget, highestPriority
end

-- =============================================
-- ENHANCED INTERRUPT SYSTEM
-- =============================================

-- Priority interrupt list
AC.InterruptPriorities = {
    -- High priority spells to always interrupt
    ["Heal"] = 100,
    ["Greater Heal"] = 100,
    ["Flash Heal"] = 90,
    ["Healing Touch"] = 90,
    ["Chain Heal"] = 95,
    
    -- Damage spells
    ["Fireball"] = 70,
    ["Frostbolt"] = 70,
    ["Lightning Bolt"] = 70,
    ["Shadow Bolt"] = 70,
    ["Mind Blast"] = 75,
    
    -- Crowd control
    ["Polymorph"] = 85,
    ["Fear"] = 85,
    ["Banish"] = 80,
    
    -- Buffs
    ["Blessing of Protection"] = 60,
    ["Divine Shield"] = 90,
}

function AC:ShouldInterruptSpell(spellName)
    if not spellName then return false end
    
    -- Check priority list
    local priority = self.InterruptPriorities[spellName]
    if priority and priority >= 70 then
        return true
    end
    
    -- Interrupt any heal spell
    if spellName:lower():find("heal") then
        return true
    end
    
    -- Interrupt high damage spells
    local highDamageSpells = {"fireball", "frostbolt", "lightning", "shadow bolt", "mind blast"}
    for _, spell in ipairs(highDamageSpells) do
        if spellName:lower():find(spell) then
            return true
        end
    end
    
    return false
end

-- Enhanced interrupt function for all classes
function AC:TryInterrupt(interruptSpell, unit)
    unit = unit or "target"
    
    if not UnitExists(unit) then return false end
    
    local spellName, _, _, _, _, _, _, _, uninterruptible = UnitCastingInfo(unit)
    if not spellName or uninterruptible then return false end
    
    -- Check if we should interrupt this spell
    if not self:ShouldInterruptSpell(spellName) then return false end
    
    -- Try to interrupt
    if self:GetSpellCooldown(interruptSpell) == 0 then
        self:CastSpell(interruptSpell, unit)
        self:Debug("Interrupted " .. spellName .. " with " .. interruptSpell)
        return true
    end
    
    return false
end

-- =============================================
-- COMBAT LOG TRACKING (FIXED FOR WOTLK)
-- =============================================

-- Combat log tracking table
AC.combatEnemies = AC.combatEnemies or {}
AC.lastCombatUpdate = AC.lastCombatUpdate or 0

-- Fixed Combat Log Event Handler for WotLK 3.3.5
function AC:COMBAT_LOG_EVENT_UNFILTERED(event, ...)
    -- In WotLK, the combat log parameters come in differently
    local timestamp, subevent, sourceGUID, sourceName, sourceFlags, destGUID, destName, destFlags = select(1, ...)
    
    -- Convert flags to numbers if they're strings (WotLK compatibility)
    if type(sourceFlags) == "string" then
        sourceFlags = tonumber(sourceFlags) or 0
    end
    if type(destFlags) == "string" then
        destFlags = tonumber(destFlags) or 0
    end
    
    -- Make sure we have valid flags before using bit operations
    if not sourceFlags or sourceFlags == 0 then
        return
    end
    
    -- Define the flag constants for WotLK
    local COMBATLOG_OBJECT_TYPE_NPC = 0x00000008
    local COMBATLOG_OBJECT_REACTION_HOSTILE = 0x00000040
    local COMBATLOG_OBJECT_TYPE_PLAYER = 0x00000400
    local COMBATLOG_OBJECT_TYPE_PET = 0x00001000
    local COMBATLOG_OBJECT_CONTROL_PLAYER = 0x00000100
    
    -- Track hostile NPCs that are in combat with us or our group
    if sourceGUID and sourceName and sourceGUID ~= "" then
        -- Check if source is a hostile NPC
        local isNPC = bit.band(sourceFlags, COMBATLOG_OBJECT_TYPE_NPC) > 0
        local isHostile = bit.band(sourceFlags, COMBATLOG_OBJECT_REACTION_HOSTILE) > 0
        
        if isNPC and isHostile then
            -- Check if this enemy is targeting us or our group
            if destGUID == UnitGUID("player") or self:IsGroupMember(destGUID) then
                self.combatEnemies[sourceGUID] = {
                    name = sourceName,
                    lastSeen = GetTime(),
                    guid = sourceGUID
                }
            end
        end
    end
    
    -- Also track if we're damaging enemies
    if destGUID and destName and destGUID ~= "" and destFlags and destFlags > 0 then
        local isNPC = bit.band(destFlags, COMBATLOG_OBJECT_TYPE_NPC) > 0
        local isHostile = bit.band(destFlags, COMBATLOG_OBJECT_REACTION_HOSTILE) > 0
        
        if isNPC and isHostile then
            -- If we or our group are damaging this enemy
            if sourceGUID == UnitGUID("player") or self:IsGroupMember(sourceGUID) then
                self.combatEnemies[destGUID] = {
                    name = destName,
                    lastSeen = GetTime(),
                    guid = destGUID
                }
            end
        end
    end
    
    -- Track enemy deaths to remove them
    if subevent == "UNIT_DIED" and destGUID then
        self.combatEnemies[destGUID] = nil
    end

    if self.HandleClassCombatLog then
        local ok = pcall(self.HandleClassCombatLog, self, ...)
        if not ok and self.debugMode and self:Throttle("ClassCombatLogError", 5.0) then
            self:Debug("Class combat log hook error")
        end
    end
end

-- Alternative safer version if the above still has issues
function AC:COMBAT_LOG_EVENT_UNFILTERED_SAFE(event, ...)
    -- This is a safer version that doesn't rely on bit operations
    local timestamp, subevent, sourceGUID, sourceName, sourceFlags, destGUID, destName, destFlags = select(1, ...)
    
    -- Simple enemy tracking without flag checking
    if subevent and sourceGUID and sourceName then
        -- Track damage events
        if string.find(subevent, "_DAMAGE") then
            -- Enemy attacking us
            if destGUID == UnitGUID("player") then
                self.combatEnemies[sourceGUID] = {
                    name = sourceName,
                    lastSeen = GetTime(),
                    guid = sourceGUID
                }
            end
            
            -- Us attacking enemy
            if sourceGUID == UnitGUID("player") and destGUID and destName then
                self.combatEnemies[destGUID] = {
                    name = destName,
                    lastSeen = GetTime(),
                    guid = destGUID
                }
            end
        end
        
        -- Track deaths
        if subevent == "UNIT_DIED" and destGUID then
            self.combatEnemies[destGUID] = nil
        end
    end

    if self.HandleClassCombatLog then
        local ok = pcall(self.HandleClassCombatLog, self, ...)
        if not ok and self.debugMode and self:Throttle("ClassCombatLogSafeError", 5.0) then
            self:Debug("Class combat log hook error")
        end
    end
end

-- Initialize combat log event handler
function AC:InitializeCombatLogTracking()
    -- Initialize the combat enemies table
    self.combatEnemies = self.combatEnemies or {}
    self.lastCombatUpdate = self.lastCombatUpdate or 0
    
    -- Register for combat log events with error handling
    self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
    
    -- Use a protected call to handle any errors
    local success, err = pcall(function()
        -- Test if bit operations are available
        local test = bit.band(1, 1)
    end)
    
    if not success then
        self:Print("Warning: Bit operations not available, using safe combat log mode")
        -- Override with the safe version
        self.COMBAT_LOG_EVENT_UNFILTERED = self.COMBAT_LOG_EVENT_UNFILTERED_SAFE
    end
    
    -- Clean up old enemies periodically
    self:ScheduleRepeatingTimer(function()
        local now = GetTime()
        for guid, data in pairs(self.combatEnemies) do
            -- Remove enemies we haven't seen in 5 seconds
            if now - data.lastSeen > 5 then
                self.combatEnemies[guid] = nil
            end
        end
    end, 2)
end

-- Helper function to check if a GUID belongs to a group member
function AC:IsGroupMember(guid)
    if not guid then return false end
    
    -- Check raid
    for i = 1, GetNumRaidMembers() do
        if UnitGUID("raid"..i) == guid then
            return true
        end
        if UnitExists("raid"..i.."pet") and UnitGUID("raid"..i.."pet") == guid then
            return true
        end
    end
    
    -- Check party
    for i = 1, GetNumPartyMembers() do
        if UnitGUID("party"..i) == guid then
            return true
        end
        if UnitExists("party"..i.."pet") and UnitGUID("party"..i.."pet") == guid then
            return true
        end
    end
    
    -- Check player's pet
    if UnitExists("pet") and UnitGUID("pet") == guid then
        return true
    end
    
    return false
end

-- =============================================
-- COMBAT UTILITY FUNCTIONS
-- =============================================

-- Tank detection function (ENHANCED)
function AC:IsTank(unit)
    if not UnitExists(unit) then return false end
    
    -- Check for tank stances/forms
    local tankBuffs = {
        "Defensive Stance",     -- Warrior
        "Righteous Fury",       -- Paladin
        "Bear Form",            -- Druid
        "Dire Bear Form",       -- Druid
        "Frost Presence",       -- Death Knight (main tank presence)
        "Blood Presence"        -- Death Knight (also used for tanking)
    }
    
    for _, buff in ipairs(tankBuffs) do
        if self:HasBuff(unit, buff) then
            return true
        end
    end
    
    -- UnitGroupRolesAssigned doesn't exist in WotLK 3.3.5a
    -- Skip this check and rely on other tank detection methods
    
    -- Heuristic: Check if unit has significantly more health than average
    -- Tanks typically have 30-50% more health than DPS
    if UnitHealthMax(unit) > UnitHealthMax("player") * 1.3 then
        -- Additional check: see if they're the target of multiple enemies
        local targetedByEnemies = 0
        
        -- Check raid/party targets
        local numRaid = GetNumRaidMembers()
        local numParty = GetNumPartyMembers()
        
        if numRaid > 0 then
            for i = 1, numRaid do
                local raidUnit = "raid"..i.."target"
                if UnitExists(raidUnit) and UnitCanAttack("player", raidUnit) then
                    local enemyTarget = raidUnit.."target"
                    if UnitExists(enemyTarget) and UnitIsUnit(enemyTarget, unit) then
                        targetedByEnemies = targetedByEnemies + 1
                    end
                end
            end
        elseif numParty > 0 then
            for i = 1, numParty do
                local partyUnit = "party"..i.."target"
                if UnitExists(partyUnit) and UnitCanAttack("player", partyUnit) then
                    local enemyTarget = partyUnit.."target"
                    if UnitExists(enemyTarget) and UnitIsUnit(enemyTarget, unit) then
                        targetedByEnemies = targetedByEnemies + 1
                    end
                end
            end
        end
        
        -- If being targeted by 2+ enemies and has high health, probably a tank
        if targetedByEnemies >= 2 then
            return true
        end
    end
    
    -- Class-specific checks
    local _, class = UnitClass(unit)
    if class then
        -- Warriors in defensive stance
        if class == "WARRIOR" then
            -- GetShapeshiftForm() returns stance for warriors
            local stance = GetShapeshiftForm and GetShapeshiftForm() or 0
            if UnitIsUnit(unit, "player") and stance == 2 then -- Defensive stance
                return true
            end
        end
        
        -- Paladins with Righteous Fury
        if class == "PALADIN" and self:HasBuff(unit, "Righteous Fury") then
            return true
        end
        
        -- Death Knights in Frost Presence
        if class == "DEATHKNIGHT" and self:HasBuff(unit, "Frost Presence") then
            return true
        end
        
        -- Druids in bear form
        if class == "DRUID" then
            local form = GetShapeshiftForm and GetShapeshiftForm() or 0
            if UnitIsUnit(unit, "player") and form == 1 then -- Bear form
                return true
            elseif self:HasBuff(unit, "Bear Form") or self:HasBuff(unit, "Dire Bear Form") then
                return true
            end
        end
    end
    
    return false
end

-- IMPROVED: Better enemy count detection for WotLK
function AC:GetEnemyCount(range)
    -- Don't run this function too often
    if not self:Throttle("EnemyCountMain", 0.5) then 
        return self.lastEnemyCount or 1
    end
    
    local count = 0
    local processedGUIDs = {}
    range = range or 30
    
    local detailedDebug = self.debugMode and self:Throttle("EnemyCountDebug", 3.0)
    if detailedDebug then
        self:Debug("=== ENEMY COUNT START ===")
    end
    
    -- METHOD 1: Check current target
    if UnitExists("target") and UnitCanAttack("player", "target") and not UnitIsDead("target") then
        local targetGUID = UnitGUID("target")
        if targetGUID then
            count = count + 1
            processedGUIDs[targetGUID] = true
            if detailedDebug then
                self:Debug("Target: " .. (UnitName("target") or "Unknown"))
            end
        end
    end
    
    -- METHOD 2: Check focus target (WotLK has focus)
    if UnitExists("focus") and UnitCanAttack("player", "focus") and not UnitIsDead("focus") then
        local focusGUID = UnitGUID("focus")
        if focusGUID and not processedGUIDs[focusGUID] then
            count = count + 1
            processedGUIDs[focusGUID] = true
            if detailedDebug then
                self:Debug("Focus: " .. (UnitName("focus") or "Unknown"))
            end
        end
    end
    
    -- METHOD 3: Check targettarget
    if UnitExists("targettarget") and UnitCanAttack("player", "targettarget") and not UnitIsDead("targettarget") then
        local ttGUID = UnitGUID("targettarget")
        if ttGUID and not processedGUIDs[ttGUID] then
            count = count + 1
            processedGUIDs[ttGUID] = true
            if detailedDebug then
                self:Debug("TargetTarget: " .. (UnitName("targettarget") or "Unknown"))
            end
        end
    end
    
    -- METHOD 4: Check mouseover (important for WotLK)
    if UnitExists("mouseover") and UnitCanAttack("player", "mouseover") and not UnitIsDead("mouseover") then
        local mouseGUID = UnitGUID("mouseover")
        if mouseGUID and not processedGUIDs[mouseGUID] then
            count = count + 1
            processedGUIDs[mouseGUID] = true
            if detailedDebug then
                self:Debug("Mouseover: " .. (UnitName("mouseover") or "Unknown"))
            end
        end
    end
    
    -- METHOD 5: Check party/raid targets
    local numRaid = GetNumRaidMembers()
    local numParty = GetNumPartyMembers()
    
    if numRaid > 0 then
        for i = 1, numRaid do
            local unit = "raid"..i.."target"
            if UnitExists(unit) and UnitCanAttack("player", unit) and not UnitIsDead(unit) then
                local guid = UnitGUID(unit)
                if guid and not processedGUIDs[guid] then
                    count = count + 1
                    processedGUIDs[guid] = true
                    if detailedDebug then
                        self:Debug("Raid"..i.." target: " .. (UnitName(unit) or "Unknown"))
                    end
                end
            end
        end
    elseif numParty > 0 then
        for i = 1, numParty do
            local unit = "party"..i.."target"
            if UnitExists(unit) and UnitCanAttack("player", unit) and not UnitIsDead(unit) then
                local guid = UnitGUID(unit)
                if guid and not processedGUIDs[guid] then
                    count = count + 1
                    processedGUIDs[guid] = true
                    if detailedDebug then
                        self:Debug("Party"..i.." target: " .. (UnitName(unit) or "Unknown"))
                    end
                end
            end
        end
    end
    
    -- METHOD 6: Check pet targets
    if UnitExists("pet") then
        local petTarget = "pettarget"
        if UnitExists(petTarget) and UnitCanAttack("player", petTarget) and not UnitIsDead(petTarget) then
            local guid = UnitGUID(petTarget)
            if guid and not processedGUIDs[guid] then
                count = count + 1
                processedGUIDs[guid] = true
                if detailedDebug then
                    self:Debug("Pet target: " .. (UnitName(petTarget) or "Unknown"))
                end
            end
        end
    end
    
    -- METHOD 7: Combat log enemies (most important for WotLK)
    local combatLogCount = 0
    local now = GetTime()
    for guid, data in pairs(self.combatEnemies) do
        if not processedGUIDs[guid] and (now - data.lastSeen) <= 3 then
            count = count + 1
            combatLogCount = combatLogCount + 1
            processedGUIDs[guid] = true
            if detailedDebug then
                self:Debug("Combat log enemy: " .. (data.name or "Unknown"))
            end
        end
    end
    
    -- Cap at reasonable number
    count = math.min(count, 10)
    
    -- Store the count
    self.lastEnemyCount = count
    
    -- Debug output
    if detailedDebug then
        self:Debug("=== ENEMY COUNT SUMMARY ===")
        self:Debug("Total enemies: " .. count)
        self:Debug("Combat log enemies: " .. combatLogCount)
        self:Debug("Should use AoE: " .. (count >= 3 and "YES" or "NO"))
        self:Debug("===========================")
    end
    
    return count
end

-- IMPROVED: Add a specific function to check if AOE should be used
function AC:ShouldUseAOE()
    if self:IsSingleTargetMode() then
        return false
    end

    local enemyCount = self:GetEnemyCount()
    local threshold = 3  -- CHANGED: Be more conservative - only use AOE with 3+ enemies
    
    -- Check if we're in a dungeon or raid - but don't be overly aggressive
    local inInstance, instanceType = IsInInstance()
    if inInstance and (instanceType == "party" or instanceType == "raid") then
        -- Only use AOE if we actually detect multiple enemies
        return enemyCount >= threshold
    end
    
    return enemyCount >= threshold
end

function AC:GetTargetingMode()
    if self.db and self.db.profile and self.db.profile.targetingMode then
        return self.db.profile.targetingMode
    end

    return "auto"
end

function AC:IsSingleTargetMode()
    return self:GetTargetingMode() == "single"
end

function AC:GetEffectiveEnemyCount(enemyCount)
    local count = enemyCount or self:GetEnemyCount()
    if self:IsSingleTargetMode() then
        return math.min(count, 1)
    end

    return count
end

function AC:ShouldUseMultiTarget(minEnemies, enemyCount)
    return self:GetEffectiveEnemyCount(enemyCount) >= (minEnemies or 2)
end

function AC:ToggleTargetingMode()
    if not self.db or not self.db.profile then return end

    if self:GetTargetingMode() == "single" then
        self.db.profile.targetingMode = "auto"
    else
        self.db.profile.targetingMode = "single"
    end

    self:UpdateUIState()
    self:Print("Targeting mode: " .. (self:IsSingleTargetMode() and "Single Target" or "Auto"))
end

function AC:HasDebuff(unit, spellName, timeLeft)
    local name, _, _, count, _, duration, expires = UnitDebuff(unit, spellName)
    if name and (not timeLeft or (expires - GetTime()) < timeLeft) then
        return true, count, duration, expires
    end
    return false
end

function AC:DebuffTimeRemaining(unit, spellName)
    local name, _, _, count, _, duration, expires = UnitDebuff(unit, spellName)
    if name then
        return expires - GetTime()
    end
    return 0
end

function AC:HasBuff(unit, spellName, timeLeft)
    local name, _, _, count, _, duration, expires = UnitBuff(unit, spellName)
    if name and (not timeLeft or (expires - GetTime()) < timeLeft) then
        return true, count, duration, expires
    end
    return false
end

function AC:BuffTimeRemaining(unit, spellName)
    local name, _, _, count, _, duration, expires = UnitBuff(unit, spellName)
    if name then
        return expires - GetTime()
    end
    return 0
end

function AC:GetPower(powerType)
    return UnitPower("player", powerType or PowerType)
end

function AC:GetSpellCooldown(spellName)
    local start, duration = GetSpellCooldown(spellName)
    if start and duration then
        local timeLeft = start + duration - GetTime()
        return timeLeft > 0 and timeLeft or 0
    end
    return 0
end

function AC:IsUsableSpell(spellName)
    if not spellName then return false end
    
    -- Check if spell exists first
    local spellInfo = GetSpellInfo(spellName)
    if not spellInfo then
        return false  -- Spell doesn't exist
    end

    -- Trust the native usability API first (WotLK-safe). This avoids false
    -- negatives from rank/spellID mismatches in IsSpellKnown checks.
    local usable, noMana = IsUsableSpell(spellName)
    if usable and not noMana then
        return true
    end
    
    -- Check if spell is known/learned
    local spellID = select(7, GetSpellInfo(spellName))
    if spellID and spellID > 0 and not IsSpellKnown(spellID) then
        return false  -- Spell not learned
    elseif spellID == nil and not self:KnowsSpell(spellName) then
        return false
    end
    
    -- Only check if spell is usable (resources/stance/etc) - let caller handle cooldown
    if not usable or noMana then
        return false
    end
    
    -- REMOVED: Cooldown check - callers handle this separately to avoid conflicts
    return true  -- Usable (caller checks cooldown separately)
end

function AC:CastSpell(spellName, unit)
    unit = unit or "target"
    
    -- Skip if the spell doesn't exist or has no valid target
    if not spellName or (unit ~= "player" and not UnitExists(unit)) then
        return false
    end
    
    -- Only cast if the spell is usable and not on cooldown
    if self:IsUsableSpell(spellName) then
        if self:GetSpellCooldown(spellName) > 0 then
            return false
        end

        -- Use stopspelltarget to prevent error sounds (WoW API)
        if not IsCurrentSpell(spellName) then
            CastSpellByName(spellName, unit)
            return true
        end
    end
    
    return false
end

-- Check if a spell is known
function AC:KnowsSpell(spellName)
    if not spellName then return false end

    local _, rank, _, _, _, _, spellID = GetSpellInfo(spellName)
    if spellID and spellID > 0 then
        return IsSpellKnown(spellID) and true or false
    end

    for tab = 1, GetNumSpellTabs() do
        local _, _, offset, numSpells = GetSpellTabInfo(tab)
        for i = offset + 1, offset + numSpells do
            local name, bookRank = GetSpellName(i, BOOKTYPE_SPELL)
            if name == spellName then
                if not rank or rank == "" or bookRank == rank then
                    return true
                end
            end
        end
    end

    return false
end

-- Find and set target function with auto-attack
function AC:FindAndSetTarget()
    -- First try to target what the tank is targeting
    for i = 1, 4 do
        local unit = "party"..i
        if UnitExists(unit) then
            -- Use our IsTank function
            if self:IsTank(unit) then
                local tankTarget = unit.."target"
                if UnitExists(tankTarget) and UnitCanAttack("player", tankTarget) then
                    TargetUnit(tankTarget)
                    StartAttack() -- Start auto-attack immediately
                    return true
                end
            end
        end
    end
    
    -- Try to find any valid target
    for i = 1, 40 do
        local unit = "nameplate"..i
        if UnitExists(unit) and UnitCanAttack("player", unit) then
            TargetUnit(unit)
            StartAttack() -- Start auto-attack immediately
            return true
        end
    end
    
    return false
end

-- Group utility functions
if not IsInGroup then
    function IsInGroup()
        return GetNumRaidMembers() > 0 or GetNumPartyMembers() > 0
    end
end


-- =============================================
-- ENHANCED PERFORMANCE MONITORING
-- =============================================

-- Track rotation performance
AC.PerformanceMetrics = {
    rotationCalls = 0,
    successfulCasts = 0,
    failedCasts = 0,
    avgExecutionTime = 0,
    lastResetTime = GetTime(),
}

function AC:TrackRotationPerformance(startTime, success)
    local metrics = self.PerformanceMetrics
    local executionTime = GetTime() - startTime
    
    metrics.rotationCalls = metrics.rotationCalls + 1
    
    if success then
        metrics.successfulCasts = metrics.successfulCasts + 1
    else
        metrics.failedCasts = metrics.failedCasts + 1
    end
    
    -- Update average execution time
    metrics.avgExecutionTime = (metrics.avgExecutionTime + executionTime) / 2
    
    -- Reset metrics every 5 minutes
    if GetTime() - metrics.lastResetTime > 300 then
        metrics.rotationCalls = 0
        metrics.successfulCasts = 0
        metrics.failedCasts = 0
        metrics.avgExecutionTime = 0
        metrics.lastResetTime = GetTime()
    end
end

function AC:GetPerformanceReport()
    local metrics = self.PerformanceMetrics
    if metrics.rotationCalls == 0 then
        return "No performance data available"
    end
    
    local successRate = (metrics.successfulCasts / metrics.rotationCalls) * 100
    
    return string.format(
        "Rotation Performance: %.1f%% success rate, %.3fs avg execution time, %d total calls",
        successRate, metrics.avgExecutionTime, metrics.rotationCalls
    )
end

-- =============================================
-- LOGGING AND DEBUG
-- =============================================

-- Debug function for rotations
function AC:DebugRotations()
    self:Print("Debugging rotations")
    for class, specs in pairs(self.rotations) do
        print("Class: " .. class)
        for spec, func in pairs(specs) do
            print("  - Spec: " .. spec)
        end
    end
end

-- Add logging function that respects silent mode
function AC:Print(message)
    if not self.silentMode then
        print("|cFF00FF00AzeroCombat|r: " .. message)
    end
end

-- Debug logging function
function AC:Debug(message)
    if not self.silentMode and self.debugMode then
        -- Add to debug window if enabled
        if self.debugWindowEnabled then
            self:AddDebugMessage(message)
        else
            print("|cFF00FF00AzeroCombat Debug|r: " .. message)
        end
    end
end

-- =============================================
-- DEBUG WINDOW SYSTEM
-- =============================================

-- Add debug message to window
function AC:AddDebugMessage(message)
    local timestamp = date("%H:%M:%S")
    local formattedMessage = string.format("[%s] %s", timestamp, tostring(message))
    
    table.insert(self.debugMessages, formattedMessage)
    
    -- Keep only the last N messages
    if #self.debugMessages > self.maxDebugMessages then
        table.remove(self.debugMessages, 1)
    end
    
    -- Update the debug window if it exists
    if self.debugFrame and self.debugFrame:IsVisible() then
        self:UpdateDebugWindow()
    end
end

-- Create debug window
function AC:CreateDebugWindow()
    if self.debugFrame then
        self.debugFrame:Show()
        return
    end
    
    -- Create main debug frame
    local frame = CreateFrame("Frame", "AzeroCombatDebugFrame", UIParent)
    frame:SetSize(500, 400)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetClampedToScreen(true)
    frame:SetFrameStrata("DIALOG")
    
    -- Set backdrop
    frame:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = {left = 4, right = 4, top = 4, bottom = 4}
    })
    frame:SetBackdropColor(0, 0, 0, 0.9)
    frame:SetBackdropBorderColor(0.6, 0.6, 0.6, 1)
    
    -- Drag functionality
    frame:SetScript("OnDragStart", function(self)
        self:StartMoving()
    end)
    
    frame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        AC:SaveDebugWindowPosition()
    end)
    
    -- Title bar
    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", frame, "TOP", 0, -10)
    title:SetText("AzeroCombat Debug Window")
    title:SetTextColor(1, 0.8, 0)
    
    -- Close button
    local closeBtn = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    closeBtn:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -3, -3)
    closeBtn:SetScript("OnClick", function()
        AC:CloseDebugWindow()
    end)
    
    -- Clear button
    local clearBtn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    clearBtn:SetSize(60, 20)
    clearBtn:SetPoint("TOPRIGHT", closeBtn, "TOPLEFT", -5, -5)
    clearBtn:SetText("Clear")
    clearBtn:SetScript("OnClick", function()
        AC:ClearDebugMessages()
    end)
    
    -- Auto-scroll checkbox
    local autoScrollCheck = CreateFrame("CheckButton", nil, frame, "UICheckButtonTemplate")
    autoScrollCheck:SetSize(16, 16)
    autoScrollCheck:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, -35)
    autoScrollCheck:SetChecked(true)
    
    local autoScrollLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    autoScrollLabel:SetPoint("LEFT", autoScrollCheck, "RIGHT", 2, 0)
    autoScrollLabel:SetText("Auto-scroll")
    autoScrollLabel:SetTextColor(0.8, 0.8, 0.8)
    
    -- Create scroll frame
    local scrollFrame = CreateFrame("ScrollFrame", "AzeroCombatDebugScrollFrame", frame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, -55)
    scrollFrame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -30, 10)
    
    -- Create content frame
    local contentFrame = CreateFrame("Frame", nil, scrollFrame)
    contentFrame:SetSize(450, 1) -- Width matches scroll frame, height will be adjusted
    scrollFrame:SetScrollChild(contentFrame)
    
    -- Create text display
    local debugText = contentFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    debugText:SetPoint("TOPLEFT", contentFrame, "TOPLEFT", 5, -5)
    debugText:SetWidth(440)
    debugText:SetJustifyH("LEFT")
    debugText:SetJustifyV("TOP")
    debugText:SetText("Debug messages will appear here...")
    debugText:SetTextColor(0.8, 1, 0.8)
    
    -- Create invisible button for text selection
    local selectButton = CreateFrame("Button", nil, contentFrame)
    selectButton:SetAllPoints(contentFrame)
    selectButton:SetScript("OnClick", function()
        -- Create a temporary EditBox to enable text selection
        if not self.debugEditBox then
            self.debugEditBox = CreateFrame("EditBox", nil, contentFrame)
            self.debugEditBox:SetPoint("TOPLEFT", contentFrame, "TOPLEFT", 5, -5)
            self.debugEditBox:SetWidth(440)
            self.debugEditBox:SetHeight(20)
            self.debugEditBox:SetFontObject(GameFontNormalSmall)
            self.debugEditBox:SetTextColor(0.8, 1, 0.8)
            self.debugEditBox:SetAutoFocus(false)
            self.debugEditBox:SetMultiLine(true)
            self.debugEditBox:Hide()
        end
        
        -- Show EditBox, set text, and select all
        self.debugEditBox:SetText(debugText:GetText() or "")
        self.debugEditBox:Show()
        self.debugEditBox:SetFocus()
        self.debugEditBox:HighlightText()
        
        -- Hide the EditBox when it loses focus
        self.debugEditBox:SetScript("OnEditFocusLost", function()
            self.debugEditBox:Hide()
        end)
    end)
    
    -- Store references
    self.debugFrame = frame
    self.debugScrollFrame = scrollFrame
    self.debugContentFrame = contentFrame
    self.debugText = debugText
    self.debugAutoScrollCheck = autoScrollCheck
    
    -- Load saved position
    self:LoadDebugWindowPosition()
    
    -- Show the frame
    frame:Show()
    
    -- Update with current messages
    self:UpdateDebugWindow()
    
    -- Update UI state to show debug window is open
    self:UpdateUIState()
    
    self:Print("Debug window created. Drag to move, use Clear button to clear messages.")
end

-- Update debug window content
function AC:UpdateDebugWindow()
    if not self.debugFrame or not self.debugText then return end
    
    -- Join all messages with newlines
    local content = table.concat(self.debugMessages, "\n")
    
    if content == "" then
        content = "No debug messages yet..."
    end
    
    self.debugText:SetText(content)
    
    -- Keep selectable overlay text in sync when visible.
    if self.debugEditBox and self.debugEditBox:IsVisible() then
        self.debugEditBox:SetText(content)
    end
    
    -- Adjust content frame height based on text
    local textHeight = self.debugText:GetStringHeight()
    local contentHeight = math.max(textHeight + 10, self.debugScrollFrame:GetHeight())
    self.debugContentFrame:SetHeight(contentHeight)
    
    -- Auto-scroll to bottom if enabled
    if self.debugAutoScrollCheck and self.debugAutoScrollCheck:GetChecked() then
        local maxScroll = self.debugScrollFrame:GetVerticalScrollRange()
        if maxScroll > 0 then
            self.debugScrollFrame:SetVerticalScroll(maxScroll)
        end
    end
end

-- Close debug window
function AC:CloseDebugWindow()
    if self.debugFrame then
        self.debugFrame:Hide()
        self.debugWindowEnabled = false
        self.db.profile.debugWindowEnabled = false
        self:UpdateUIState()  -- Update UI state to show debug window is closed
        self:Print("Debug window closed. Messages will go to chat again.")
    end
end

-- Clear debug messages
function AC:ClearDebugMessages()
    self.debugMessages = {}
    
    -- Hide/reset selection overlay so stale text is not left on top.
    if self.debugEditBox then
        self.debugEditBox:ClearFocus()
        self.debugEditBox:SetText("")
        self.debugEditBox:Hide()
    end
    
    if self.debugFrame and self.debugFrame:IsVisible() then
        self:UpdateDebugWindow()
        if self.debugScrollFrame then
            self.debugScrollFrame:SetVerticalScroll(0)
        end
    end
    self:Print("Debug messages cleared.")
end

-- Save debug window position
function AC:SaveDebugWindowPosition()
    if not self.debugFrame then return end
    
    local point, relativeTo, relativePoint, x, y = self.debugFrame:GetPoint(1)
    
    if point and x and y then
        local relativeToName = "UIParent"
        if relativeTo and relativeTo.GetName then
            relativeToName = relativeTo:GetName() or "UIParent"
        end
        
        self.db.profile.debugWindowPosition = {
            point = point,
            relativeTo = relativeToName,
            relativePoint = relativePoint or point,
            x = math.floor(x + 0.5),
            y = math.floor(y + 0.5)
        }
        
        if self.debugMode then
            self:Print("Debug window position saved")
        end
    end
end

-- Load debug window position
function AC:LoadDebugWindowPosition()
    if not self.debugFrame then return end
    
    local pos = self.db.profile.debugWindowPosition
    if not pos or not pos.point or not pos.x or not pos.y then
        -- Default position
        self.debugFrame:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 20, -200)
        return
    end
    
    -- Clear all points first
    self.debugFrame:ClearAllPoints()
    
    -- Get the relative frame
    local relativeTo = UIParent
    if pos.relativeTo and pos.relativeTo ~= "UIParent" then
        relativeTo = _G[pos.relativeTo] or UIParent
    end
    
    -- Set the position
    local success = pcall(function()
        self.debugFrame:SetPoint(pos.point, relativeTo, pos.relativePoint or pos.point, pos.x, pos.y)
    end)
    
    if not success then
        -- Fallback to default position
        self.debugFrame:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 20, -200)
    end
end

-- Toggle debug window
function AC:ToggleDebugWindow()
    if not self.debugFrame then
        -- Create and show debug window
        self.debugWindowEnabled = true
        self.db.profile.debugWindowEnabled = true
        self:CreateDebugWindow()
        self:Print("Debug window enabled. Debug messages will appear in the window instead of chat.")
    else
        if self.debugFrame:IsVisible() then
            self:CloseDebugWindow()
        else
            self.debugWindowEnabled = true
            self.db.profile.debugWindowEnabled = true
            self.debugFrame:Show()
            self:UpdateDebugWindow()
            self:UpdateUIState()  -- Update UI state to show debug window is open
            self:Print("Debug window shown. Debug messages will appear in the window instead of chat.")
        end
    end
end

-- =============================================
-- COMPATIBILITY LAYER
-- =============================================

-- Ensure backward compatibility with existing rotation calls
function AC:EnsureBackwardCompatibility()
    -- Provide fallbacks for any missing functions
    if not self.GetTargetHealthPercent then
        function AC:GetTargetHealthPercent(unit)
            unit = unit or "target"
            if not UnitExists(unit) then return 0 end
            return UnitHealth(unit) / UnitHealthMax(unit) * 100
        end
    end
    
    if not self.GetPlayerHealthPercent then
        function AC:GetPlayerHealthPercent()
            return UnitHealth("player") / UnitHealthMax("player") * 100
        end
    end
    
    if not self.ActionThrottle then
        function AC:ActionThrottle(action, interval)
            return self:Throttle(action, interval)
        end
    end
    
    if not self.GetPlayerClass then
        function AC:GetPlayerClass()
            local _, class = UnitClass("player")
            return class
        end
    end
    
    -- Ensure class throttles exist
    if not self.ClassThrottles then
        self.ClassThrottles = {
            ROGUE = {
                poison_check = 2.0,
                stealth_check = 1.0,
                combo_point = 0.3,
                energy_check = 0.2,
                cooldown_check = 1.0,
                defensive = 0.5,
            }
        }
    end
end

-- Initialize compatibility on load
AC:EnsureBackwardCompatibility()

-- =============================================
-- UTILS.LUA VERIFICATION
-- =============================================

function AC:VerifyUtilsLoaded()
    local utilsFunctions = {
        "UseHealthPotion",
        "UseManaPotion", 
        "HasItem",
        "GetDistance",
        "UseTrinkets"
    }
    
    local missing = {}
    for _, funcName in ipairs(utilsFunctions) do
        if not self[funcName] then
            table.insert(missing, funcName)
        end
    end
    
    if #missing > 0 then
        self:Print("WARNING: Utils.lua functions missing: " .. table.concat(missing, ", "))
        self:Print("Make sure Utils.lua is listed before Core.lua in your TOC file")
        return false
    else
        self:Debug("Utils.lua functions successfully loaded")
        return true
    end
end

-- =============================================
-- FIXED GUI SYSTEM - ONLY Position Saving Changed, Everything Else Original
-- =============================================

-- =============================================
-- FIXED GUI SYSTEM - ONLY Position Saving Changed, Everything Else Original
-- =============================================

-- FIXED: Enhanced SaveFramePosition with validation - COPIED FROM CORE.LUA
function AC:SaveFramePosition()
    if not self.frame then 
        if self.debugMode then
            self:Print("Cannot save position: frame doesn't exist")
        end
        return false
    end
    
    -- Get all anchor points (frame might have multiple)
    local numPoints = self.frame:GetNumPoints()
    if numPoints == 0 then
        if self.debugMode then
            self:Print("Cannot save position: frame has no anchor points")
        end
        return false
    end
    
    -- Get the first anchor point
    local point, relativeTo, relativePoint, x, y = self.frame:GetPoint(1)
    
    -- Validate the data before saving
    if point and x and y then
        local relativeToName = "UIParent"
        if relativeTo and relativeTo.GetName then
            relativeToName = relativeTo:GetName() or "UIParent"
        end
        
        -- ONLY CHANGE: Save to AceDB instead of custom settings
        self.db.profile.framePosition = {
            point = point,
            relativeTo = relativeToName,
            relativePoint = relativePoint or point,
            x = math.floor(x + 0.5), -- Round to nearest integer
            y = math.floor(y + 0.5)  -- Round to nearest integer
        }
        
        if self.debugMode then
            self:Print(string.format("Position saved: %s->%s %s (%.0f, %.0f)", 
                point, relativeToName, relativePoint or point, x, y))
        end
        
        return true
    else
        if self.debugMode then
            self:Print("Cannot save position: invalid anchor data")
        end
        return false
    end
end

-- FIXED: Enhanced LoadFramePosition with better error handling - COPIED FROM CORE.LUA
function AC:LoadFramePosition()
    if not self.frame then 
        if self.debugMode then
            self:Print("Cannot load position: frame doesn't exist")
        end
        return false
    end
    
    -- ONLY CHANGE: Load from AceDB instead of custom settings
    if not self.db or not self.db.profile.framePosition then
        if self.debugMode then
            self:Print("No saved position found, using defaults")
        end
        return false
    end
    
    local pos = self.db.profile.framePosition
    
    -- Validate position data
    if not pos.point or not pos.x or not pos.y then
        if self.debugMode then
            self:Print("Invalid position data, using defaults")
        end
        return false
    end
    
    -- Clear all points first
    self.frame:ClearAllPoints()
    
    -- Get the relative frame
    local relativeTo = UIParent
    if pos.relativeTo and pos.relativeTo ~= "UIParent" then
        relativeTo = _G[pos.relativeTo] or UIParent
    end
    
    -- Set the position with error protection
    local success, err = pcall(function()
        self.frame:SetPoint(
            pos.point, 
            relativeTo, 
            pos.relativePoint or pos.point, 
            pos.x, 
            pos.y
        )
    end)
    
    if success then
        if self.debugMode then
            self:Print(string.format("Position loaded: %s->%s %s (%.0f, %.0f)", 
                pos.point, pos.relativeTo, pos.relativePoint or pos.point, pos.x, pos.y))
        end
        return true
    else
        if self.debugMode then
            self:Print("Failed to load position: " .. (err or "unknown error"))
        end
        -- Fallback to default position
        self.frame:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", -20, -100)
        return false
    end
end

-- FIXED: Complete UI synchronization system - COPIED EXACTLY FROM CORE.LUA
function AC:UpdateUIState()
    if not self.frame then return end
    
    -- Update all UI elements
    if self.enableBtn then
        self.enableBtn:SetText(self.enabled and "Disable" or "Enable")
    end
    
    if self.debugBtn then
        if self.debugMode then
            if self.debugWindowEnabled and self.debugFrame and self.debugFrame:IsVisible() then
                self.debugBtn:SetText("Debug: WIN")
            else
                self.debugBtn:SetText("Debug: ON")
            end
        else
            self.debugBtn:SetText("Debug")
        end
    end

    if self.modeBtn then
        self.modeBtn:SetText(self:IsSingleTargetMode() and "Mode: ST" or "Mode: Auto")
    end
    
    if self.statusText then
        self.statusText:SetText(self.enabled and "ENABLED" or "DISABLED")
        if self.enabled then
            self.statusText:SetTextColor(0, 1, 0) -- Green
        else
            self.statusText:SetTextColor(1, 0.3, 0.3) -- Red
        end
    end
    
    if self.infoText then
        local class = self:GetPlayerClass()
        local spec = self:GetPlayerSpec()
        self.infoText:SetText(class .. " - " .. spec)
    end
    
    if self.debugMode then
        self:Print("UI state updated - Enabled: " .. tostring(self.enabled) .. 
                   ", Debug: " .. tostring(self.debugMode))
    end
end

-- FIXED: Enhanced CreateUI with proper event handling - COPIED EXACTLY FROM CORE.LUA
function AC:CreateUI()
    if self.frame then 
        self:UpdateUIState()
        return 
    end
    
    -- Create main frame
    local frame = CreateFrame("Frame", "AzeroCombatFrame", UIParent)
    frame:SetSize(235, 90)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetClampedToScreen(true)
    
    -- FIXED: Better drag functionality with immediate saving - ONLY CHANGE: Use AceDB
    frame:SetScript("OnDragStart", function(self)
        self:StartMoving()
    end)
    
    frame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        -- Save position immediately and also schedule a delayed save
        AC:SaveFramePosition()
        
        -- Additional save after a short delay to ensure it's captured
        local saveFrame = CreateFrame("Frame")
        local elapsed = 0
        saveFrame:SetScript("OnUpdate", function(self, dt)
            elapsed = elapsed + dt
            if elapsed >= 0.1 then -- 100ms delay
                AC:SaveFramePosition()
                saveFrame:SetScript("OnUpdate", nil)
            end
        end)
    end)
    
    -- FIXED: Save position when frame is hidden
    frame:SetScript("OnHide", function(self)
        AC:SaveFramePosition()
    end)
    
    -- Set backdrop
    frame:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = {left = 3, right = 3, top = 3, bottom = 3}
    })
    frame:SetBackdropColor(0, 0, 0, 0.8)
    frame:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)
    
    self.frame = frame

    -- Enhanced Ground Targeting checkbox
    local egtCheck = CreateFrame("CheckButton", nil, frame, "UICheckButtonTemplate")
    egtCheck:SetSize(20, 20)
    egtCheck:SetPoint("TOPLEFT", frame, "TOPLEFT", 8, -30)
    egtCheck:SetChecked(self.db.profile.egtEnabled or false) -- Load saved state
    egtCheck:SetScript("OnClick", function(self)
        local isChecked = self:GetChecked()
        AC.db.profile.egtEnabled = isChecked -- Save state
        if isChecked then
            -- Enable EGT using .toggle on command
            SendChatMessage(".toggle on", "SAY")
            AC:Print("Enhanced Ground Targeting enabled")
        else
            -- Disable EGT using .toggle off command
            SendChatMessage(".toggle off", "SAY")
            AC:Print("Enhanced Ground Targeting disabled")
        end
    end)

    -- EGT label
    local egtLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    egtLabel:SetPoint("LEFT", egtCheck, "RIGHT", 2, 0)
    egtLabel:SetText("EGT")
    egtLabel:SetTextColor(0.8, 0.8, 0.8)

    -- Autofarm checkbox
    local autofarmCheck = CreateFrame("CheckButton", nil, frame, "UICheckButtonTemplate")
    autofarmCheck:SetSize(20, 20)
    autofarmCheck:SetPoint("TOPLEFT", egtCheck, "BOTTOMLEFT", 0, 5)
    autofarmCheck:SetChecked(self.db.profile.autofarmEnabled or false) -- Load saved state
    autofarmCheck:SetScript("OnClick", function(self)
        local isChecked = self:GetChecked()
        AC.db.profile.autofarmEnabled = isChecked -- Save state
        if isChecked then
            -- Show autofarm using /autofarm show command
            RunSlashCmd("/autofarm show")
            AC:Print("Autofarm enabled")
        else
            -- Hide autofarm using /autofarm hide command
            RunSlashCmd("/autofarm hide")
            AC:Print("Autofarm disabled")
        end
    end)

    -- Autofarm label
    local autofarmLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    autofarmLabel:SetPoint("LEFT", autofarmCheck, "RIGHT", 2, 0)
    autofarmLabel:SetText("AF")
    autofarmLabel:SetTextColor(0.8, 0.8, 0.8)

    -- Store references
    self.egtCheck = egtCheck
    self.egtLabel = egtLabel
    self.autofarmCheck = autofarmCheck
    self.autofarmLabel = autofarmLabel

    -- Title
    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    title:SetPoint("TOP", frame, "TOP", 0, -8)
    title:SetText("AzeroCombat")
    title:SetTextColor(1, 0.8, 0)
    
    -- Info text (class and spec)
    local infoText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    infoText:SetPoint("TOP", title, "BOTTOM", 0, -3)
    infoText:SetText("Loading...")
    self.infoText = infoText
    
    -- Status text
    local statusText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    statusText:SetPoint("TOP", infoText, "BOTTOM", 0, -3)
    statusText:SetText("DISABLED")
    statusText:SetTextColor(1, 0.3, 0.3)
    self.statusText = statusText

    -- FIXED: Better button positioning with proper spacing
    local buttonWidth = 50
    local buttonHeight = 18
    local buttonSpacing = 5
    local modeButtonWidth = 65
    local totalButtonWidth = (buttonWidth * 3) + modeButtonWidth + (buttonSpacing * 3)
    local startX = -(totalButtonWidth / 2) + (buttonWidth / 2)

    -- Enable/Disable button
    local enableBtn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    enableBtn:SetSize(buttonWidth, buttonHeight)
    enableBtn:SetPoint("BOTTOM", frame, "BOTTOM", startX, 8)
    enableBtn:SetText("Enable")
    enableBtn:SetScript("OnClick", function(self)
        AC.enabled = not AC.enabled
        AC:UpdateUIState()  -- FIXED: Call UpdateUIState to update status text
        AC:Print("Rotation " .. (AC.enabled and "enabled" or "disabled"))
    end)
    self.enableBtn = enableBtn
    
    -- Debug button
    local debugBtn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    debugBtn:SetSize(buttonWidth, buttonHeight)
    debugBtn:SetPoint("LEFT", enableBtn, "RIGHT", buttonSpacing, 0)
    debugBtn:SetText("Debug")
    debugBtn:SetScript("OnClick", function(self)
        AC.debugMode = not AC.debugMode
        AC:UpdateUIState()
        AC:Print("Debug " .. (AC.debugMode and "enabled" or "disabled"))
        
        -- Auto-open debug window when debug mode is enabled
        if AC.debugMode then
            AC:ToggleDebugWindow()
        else
            -- Close debug window when debug mode is disabled
            if AC.debugFrame and AC.debugFrame:IsVisible() then
                AC:CloseDebugWindow()
            end
        end
    end)
    self.debugBtn = debugBtn
    
    -- Options button
    local optBtn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    optBtn:SetSize(buttonWidth, buttonHeight)
    optBtn:SetPoint("LEFT", debugBtn, "RIGHT", buttonSpacing, 0)
    optBtn:SetText("Options")
    optBtn:SetScript("OnClick", function(self)
        AC:Print("=== AzeroCombat Options ===")
        AC:Print("/ac toggle - Enable/disable rotation")
        AC:Print("/ac debug - Toggle debug mode")
        AC:Print("/ac mode - Toggle Auto/Single Target mode")
        AC:Print("/ac show/hide - Show/hide UI")
        AC:Print("/ac spec - Force spec detection")
        AC:Print("Drag the UI to move it around")
        AC:Print("=========================")
    end)
    self.optBtn = optBtn

    local modeBtn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    modeBtn:SetSize(modeButtonWidth, buttonHeight)
    modeBtn:SetPoint("LEFT", optBtn, "RIGHT", buttonSpacing, 0)
    modeBtn:SetText("Mode: Auto")
    modeBtn:SetScript("OnClick", function(self)
        AC:ToggleTargetingMode()
    end)
    self.modeBtn = modeBtn

    -- FIXED: Load position AFTER creating all elements
    -- Give the frame a moment to fully initialize
    local loadFrame = CreateFrame("Frame")
    local elapsed = 0
    loadFrame:SetScript("OnUpdate", function(self, dt)
        elapsed = elapsed + dt
        if elapsed >= 0.05 then -- 50ms delay
            loadFrame:SetScript("OnUpdate", nil)
            
            -- Try to load saved position
            if not AC:LoadFramePosition() then
                -- Fallback to default position if loading fails
                frame:ClearAllPoints()
                frame:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", -20, -100)
                if AC.debugMode then
                    AC:Print("Using default UI position")
                end
            end
            
            -- Update UI state after positioning
            AC:UpdateUIState()
        end
    end)

    frame:Show()
    
    if self.debugMode then
        self:Print("UI created")
    end
end

-- =============================================
-- ENHANCED OnUpdate FUNCTION
-- =============================================

function AC:OnUpdate()
    if not self.enabled then return end
    
    local startTime = GetTime()
    local success = false
    
    -- Update resource state for trend analysis
    self:UpdateResourceState()
    
    -- Skip if channeling (simplified check)
    if UnitChannelInfo and UnitChannelInfo("player") then
        return
    end
    
    -- Get current combat situation
    local class = self:GetPlayerClass()
    local spec = self:GetPlayerSpec()
    local inCombat = UnitAffectingCombat("player")
    local hasTarget = UnitExists("target") and UnitCanAttack("player", "target") and not UnitIsDead("target")
    local combatPhase = self:GetCombatPhase()
    
    -- Enhanced auto-targeting
    if inCombat and not hasTarget then
        local bestTarget, priority = self:FindBestTarget()
        if bestTarget and priority > 50 then
            TargetUnit(bestTarget)
            StartAttack()
            hasTarget = true
        end
    end
    
    -- Standard auto-targeting fallback
    if inCombat and not hasTarget then
        if IsInGroup() then
            for i = 1, 4 do
                local unit = "party"..i.."target"
                if UnitExists(unit) and UnitCanAttack("player", unit) then
                    TargetUnit(unit)
                    StartAttack()
                    hasTarget = true
                    break
                end
            end
        end
        
        if not hasTarget then
            for i = 1, 40 do
                local unit = "nameplate"..i
                if UnitExists(unit) and UnitCanAttack("player", unit) and UnitAffectingCombat(unit) then
                    TargetUnit(unit)
                    StartAttack()
                    hasTarget = true
                    break
                end
            end
        end
    end
    
    -- Enhanced buff checking with class-specific intervals
    if not inCombat and self:ActionThrottle("buff_check", self:GetThrottleInterval("energy_check")) then
        local continueBuffing = true
        local buffAttemptCount = 0
        local maxBuffAttempts = 5 -- Reduced for better performance
        
        while continueBuffing and buffAttemptCount < maxBuffAttempts do
            local appliedBuff = false
            buffAttemptCount = buffAttemptCount + 1
            
            -- Class-specific buff checks with better integration
            if class == "ROGUE" and self.CheckRogueBuffs then
                appliedBuff = self:CheckRogueBuffs(spec)
            elseif class == "PALADIN" and self.CheckPaladinBuffs then
                appliedBuff = self:CheckPaladinBuffs(spec)
            elseif class == "WARRIOR" and self.CheckWarriorBuffs then
                appliedBuff = self:CheckWarriorBuffs(spec)
            elseif class == "DRUID" and self.CheckDruidBuffs then
                appliedBuff = self:CheckDruidBuffs(spec)
            elseif class == "SHAMAN" and self.CheckShamanBuffs then
                appliedBuff = self:CheckShamanBuffs(spec)
            elseif class == "DEATHKNIGHT" and self.CheckDeathKnightBuffs then
                appliedBuff = self:CheckDeathKnightBuffs(spec)
            elseif class == "WARLOCK" and self.CheckWarlockBuffs then
                appliedBuff = self:CheckWarlockBuffs(spec)
            elseif class == "HUNTER" and self.CheckHunterBuffs then
                appliedBuff = self:CheckHunterBuffs(spec)
            elseif class == "MAGE" and self.CheckMageBuffs then
                appliedBuff = self:CheckMageBuffs(spec)
            elseif class == "PRIEST" and self.CheckPriestBuffs then
                appliedBuff = self:CheckPriestBuffs(spec)
            end
            
            continueBuffing = appliedBuff
            
            -- Break early if we applied a poison (need to wait for application)
            if appliedBuff and (class == "ROGUE" or class == "WARLOCK") then
                break
            end
        end
        
        if buffAttemptCount > 1 then
            self:Debug("Applied " .. (buffAttemptCount - 1) .. " buffs in " .. class .. " buff check")
        end
    end
    
    -- Enhanced combat rotation execution
    if (inCombat or hasTarget) and hasTarget then
        -- Ensure auto-attack for melee classes
        if class == "ROGUE" or class == "WARRIOR" or class == "PALADIN" or class == "DEATHKNIGHT" then
            if not IsCurrentSpell("Attack") then
                StartAttack()
            end
        end
        
        -- Use class-specific throttling for rotations
        local rotationInterval = self:GetThrottleInterval("combo_point")
        if class == "ROGUE" or class == "DEATHKNIGHT" then
            rotationInterval = 0.3 -- Faster for energy/rune-based classes
        end
        
        if self:ActionThrottle("rotation_" .. class .. "_" .. spec, rotationInterval) then
            if self.rotations[class] and self.rotations[class][spec] then
                local rotationSuccess, errorMessage = pcall(function()
                    self.rotations[class][spec](self)
                end)
                
                if rotationSuccess then
                    success = true
                else
                    self:Debug("Rotation error for " .. class .. " " .. spec .. ": " .. tostring(errorMessage))
                end
            end
        end
    end
    
    -- Track performance metrics
    self:TrackRotationPerformance(startTime, success)
end

-- Initialize rotations for all classes and specs
function AC:InitRotations()
    -- The individual rotation modules will register themselves with this function
    -- Classes should use their own files to initialize and register their rotations
end

-- =============================================
-- ADDON INITIALIZATION (USING ACEDB FROM CORE(1))
-- =============================================

-- Set up OnInitialize (core Ace function) - ONLY CHANGE: Use AceDB like Core(1)
function AC:OnInitialize()
    -- Initialize the saved variables database using AceDB like Core(1)
    self.db = LibStub("AceDB-3.0"):New("AzeroCombatDB", defaults, true)
    
    -- Initialize silent mode (to control chat output)
    self.silentMode = false
end

-- Enhanced startup sequence for Ace3 addon - FIXED INITIALIZATION ORDER
function AC:OnEnable()
    if self.initialized then return end
    
    -- STEP 1: Ensure backward compatibility first
    self:EnsureBackwardCompatibility()
    
    -- STEP 2: Initialize core functions if they don't exist
    if not self.GetPlayerClass then
        function AC:GetPlayerClass()
            local _, class = UnitClass("player")
            return class
        end
    end
    
    if not self.Print then
        function AC:Print(message)
            if not self.silentMode then
                print("|cFF00FF00AzeroCombat|r: " .. message)
            end
        end
    end
    
    if not self.Debug then
        function AC:Debug(message)
            if not self.silentMode and self.debugMode then
                print("|cFF00FF00AzeroCombat Debug|r: " .. message)
            end
        end
    end
    
    -- STEP 3: Initialize essential properties
    self.version = self.version or "1.2"
    
    -- STEP 4: Simple error suppression for WotLK - hide error frame
    if UIErrorsFrame then
        -- Store original settings
        self.originalErrorsFrameEnabled = UIErrorsFrame:IsVisible()
        -- Hide errors
        UIErrorsFrame:Hide()
        self:Print("Error messages disabled")
    end
    
    -- STEP 5: Setup error sound suppression for all classes
    self:SilenceErrorSounds()
    
    -- STEP 6: Initialize combat log tracking for enemy detection
    self:InitializeCombatLogTracking()
    
    -- STEP 7: Initialize performance tracking
    if not self.PerformanceMetrics then
        self.PerformanceMetrics = {
            rotationCalls = 0,
            successfulCasts = 0,
            failedCasts = 0,
            avgExecutionTime = 0,
            lastResetTime = GetTime(),
        }
    end
    
    -- STEP 8: Setup enhanced spec detection (after core functions exist)
    self:SetupSpecDetection()
    
    -- STEP 9: Create debug frame (after all core functions exist)
    self:CreateUI()
	
	-- STEP 9a.5: Verify Utils.lua is loaded
    self:VerifyUtilsLoaded()
    
    -- STEP 10: Initialize class-specific rotations
    local playerClass = self:GetPlayerClass()
    if playerClass == "ROGUE" and self.InitRogueRotations then
        self:Print("Initializing Enhanced Rogue rotations")
        self:InitRogueRotations()
    elseif playerClass == "WARRIOR" and self.InitWarriorRotations then
        self:Print("Initializing Warrior rotations")
        self:InitWarriorRotations()
    elseif playerClass == "PALADIN" and self.InitPaladinRotations then
        self:Print("Initializing Paladin rotations")
        self:InitPaladinRotations()
    elseif playerClass == "DRUID" and self.InitDruidRotations then
        self:Print("Initializing Druid rotations")
        self:InitDruidRotations()
    elseif playerClass == "SHAMAN" and self.InitShamanRotations then
        self:Print("Initializing Shaman rotations")
        self:InitShamanRotations()
    elseif playerClass == "DEATHKNIGHT" and self.InitDeathKnightRotations then
        self:Print("Initializing Death Knight rotations")
        self:InitDeathKnightRotations()
    elseif playerClass == "WARLOCK" and self.InitWarlockRotations then
        self:Print("Initializing Warlock rotations")
        self:InitWarlockRotations()      
    elseif playerClass == "HUNTER" and self.InitHunterRotations then
        self:Print("Initializing Hunter rotations")
        self:InitHunterRotations()
    elseif playerClass == "MAGE" and self.InitMageRotations then
        self:Print("Initializing Mage rotations")
        self:InitMageRotations()
    elseif playerClass == "PRIEST" and self.InitPriestRotations then
        self:Print("Initializing Priest rotations")
        self:InitPriestRotations()
    else
        self:Print("No rotations found for " .. playerClass)
    end
    
    -- STEP 11: Call the main InitRotations function
    self:InitRotations()
    
    -- STEP 12: Debug: Print loaded rotations (only if debug mode)
    if self.debugMode then
        self:DebugRotations()
    end
    
    -- STEP 13: Register events and main update loop
    updateFrame:SetScript("OnUpdate", function() self:OnUpdate() end)
    
    -- STEP 14: Register for addon being loaded/disabled
    self:RegisterEvent("ADDON_LOADED", function(event, addonName)
        if addonName == AddonName then
            -- Hide error messages frame on load
            if UIErrorsFrame then
                UIErrorsFrame:Hide()
            end
        end
    end)
    
    -- Restore default settings when addon is disabled
    self:RegisterEvent("PLAYER_LOGOUT", function()
        if self.enabled then
            -- Restore error frame if we hid it
            if UIErrorsFrame and self.originalErrorsFrameEnabled then
                UIErrorsFrame:Show()
            end
        end
    end)
    
    -- Register for talent changes
    self:RegisterEvent("PLAYER_TALENT_UPDATE", function()
        -- Update both status texts when talents change
        if self.specStatusText then
            self.specStatusText:SetText("Spec: " .. self:GetPlayerClass() .. " - " .. self:GetPlayerSpec())
        end
    end)
    
    -- Register events for pet management
    self:RegisterEvent("UNIT_PET", function(event, unit)
        if unit == "player" and self.enabled then
            -- This will trigger a rotation update when pet status changes
            self:OnUpdate()
        end
    end)
    
    -- Target changed event to re-evaluate rotation
    self:RegisterEvent("PLAYER_TARGET_CHANGED", function()
        if self.enabled then
            self:OnUpdate()
        end
    end)
    
    -- Better auto-targeting on combat enter
    self:RegisterEvent("PLAYER_REGEN_DISABLED", function()
        -- This fires when entering combat
        if self.enabled and not UnitExists("target") then
            -- Try to find a target when entering combat
            self:FindAndSetTarget()
        end
    end)
    
    -- Slash commands with improved UI updates - FIXED: Added UpdateUIState call
    SLASH_AZEROCOMBAT1 = "/ac"
    SLASH_AZEROCOMBAT2 = "/azerocombat"
    SlashCmdList["AZEROCOMBAT"] = function(msg)
        if msg == "toggle" then
            self.enabled = not self.enabled
            self:UpdateUIState()  -- FIXED: Call UpdateUIState to update status text
            self:Print("Rotation " .. (self.enabled and "enabled" or "disabled"))
        elseif msg == "show" then
            self.frame:Show()
        elseif msg == "hide" then
            self.frame:Hide()
        elseif msg == "debug" then
            self.debugMode = not self.debugMode
            self:UpdateUIState()  -- FIXED: Call UpdateUIState to update debug button
            self:Print("Debug mode " .. (self.debugMode and "enabled" or "disabled"))
            self:DebugRotations()
            
            -- Auto-open debug window when debug mode is enabled via slash command
            if self.debugMode then
                self:ToggleDebugWindow()
            else
                -- Close debug window when debug mode is disabled
                if self.debugFrame and self.debugFrame:IsVisible() then
                    self:CloseDebugWindow()
                end
            end
        elseif msg == "debugwin" or msg == "debugwindow" then
            self:ToggleDebugWindow()
        elseif msg == "silent" then
            self.silentMode = not self.silentMode
            -- This message will only show when turning silent mode off
            if not self.silentMode then
                print("|cFF00FF00AzeroCombat|r: Silent mode disabled. Chat messages will be shown.")
            else
                print("|cFF00FF00AzeroCombat|r: Silent mode enabled. Chat messages will be suppressed.")
            end
        elseif msg == "mode" or msg == "targetmode" then
            self:ToggleTargetingMode()
        elseif msg == "feral" then
            local feralRole = (self.db and self.db.profile and self.db.profile.feralRoleMode) or "auto"
            self:Print("Feral role preference: " .. feralRole)
            self:Print("Use /ac feral auto | bear | cat")
        elseif msg == "feral auto" or msg == "feral bear" or msg == "feral cat" then
            local role = msg:match("^feral%s+(%w+)$")
            if role == "auto" or role == "bear" or role == "cat" then
                self.db.profile.feralRoleMode = role
                if self.druidFeralCombatRole then
                    self.druidFeralCombatRole = nil
                end
                self:Print("Feral role preference set to " .. role)
            else
                self:Print("Invalid feral role. Use /ac feral auto | bear | cat")
            end
        elseif msg == "spec" then
            self:ForceSpecDetection()
        elseif msg == "performance" or msg == "perf" then
            self:Print(self:GetPerformanceReport())
        elseif msg == "phase" then
            local phase = self:GetCombatPhase()
            self:Print("Current combat phase: " .. phase)
        elseif msg == "resources" then
            local class = self:GetPlayerClass()
            if class == "ROGUE" then
                local energy = UnitPower("player", 3)
                local maxEnergy = UnitPowerMax("player", 3)
                local cp = GetComboPoints("player", "target")
                local health = self:GetTargetHealthPercent("player")
                
                self:Print(string.format("Rogue Resources: %d/%d Energy, %d CP, %.1f%% Health", 
                          energy, maxEnergy, cp, health))
            elseif class == "DEATHKNIGHT" then
                local runicPower = UnitPower("player", 6)
                local maxRunicPower = UnitPowerMax("player", 6)
                local health = self:GetTargetHealthPercent("player")
                
                self:Print(string.format("Death Knight Resources: %d/%d Runic Power, %.1f%% Health", 
                          runicPower, maxRunicPower, health))
            elseif class == "WARRIOR" then
                local rage = UnitPower("player", 1)
                local maxRage = UnitPowerMax("player", 1)
                local health = self:GetTargetHealthPercent("player")
                
                self:Print(string.format("Warrior Resources: %d/%d Rage, %.1f%% Health", 
                          rage, maxRage, health))
            else
                local mana = UnitPower("player", 0)
                local maxMana = UnitPowerMax("player", 0)
                local health = self:GetTargetHealthPercent("player")
                
                self:Print(string.format("%s Resources: %d/%d Mana, %.1f%% Health", 
                          class, mana, maxMana, health))
            end
        elseif msg == "target" then
            if UnitExists("target") then
                local hp = self:GetTargetHealthPercent("target")
                local priority = self:GetTargetPriority("target")
                local classification = UnitClassification("target")
                
                self:Print(string.format("Target: %.1f%% HP, Priority: %d, Type: %s", 
                          hp, priority, classification or "normal"))
            else
                self:Print("No target selected")
            end
        elseif msg == "enemies" then
            local count = self:GetEnemyCount()
            local shouldAoE = self:ShouldUseAOE()
            self:Print(string.format("Enemies: %d, Should AoE: %s", count, shouldAoE and "Yes" or "No"))
        elseif msg == "throttle" then
            local class = self:GetPlayerClass()
            self:Print("Throttle intervals for " .. class .. ":")
            local intervals = self.ClassThrottles[class] or {}
            for action, interval in pairs(intervals) do
                print("  " .. action .. ": " .. interval .. "s")
            end
        elseif msg == "test" then
            self:Print("Testing rotation")
            local class = self:GetPlayerClass()
            local spec = self:GetPlayerSpec()
            
            if self.rotations[class] and self.rotations[class][spec] then
                self:Print("Found " .. spec .. " " .. class .. " rotation, running...")
                self.rotations[class][spec](self)
            else
                self:Print("Rotation not found")
                self:Print("Available rotations:")
                self:DebugRotations()
            end
        else
            print("|cFF00FF00AzeroCombat commands:|r")
            print("/ac toggle - Enable/disable rotations")
            print("/ac show - Show control panel")
            print("/ac hide - Hide control panel")
            print("/ac debug - Toggle debug mode")
            print("/ac mode - Toggle Auto/Single Target mode")
            print("/ac feral auto|bear|cat - Set feral role preference")
            print("/ac debugwin - Toggle debug window (shows debug messages in separate window)")
            print("/ac silent - Toggle silent mode (hide chat messages)")
            print("/ac spec - Force spec detection")
            print("/ac performance - Show rotation performance")
            print("/ac phase - Show current combat phase")
            print("/ac resources - Show current resources")
            print("/ac target - Show target information")
            print("/ac enemies - Show enemy count")
            print("/ac throttle - Show throttle intervals")
            print("/ac test - Test current class rotation")
        end
    end
    
    -- Restore EGT state
    if self.db.profile.egtEnabled and self.egtCheck then
        self.egtCheck:SetChecked(true)
        SendChatMessage(".toggle on", "SAY")
    end
    
    -- Restore Autofarm state
    if self.db.profile.autofarmEnabled and self.autofarmCheck then
        self.autofarmCheck:SetChecked(true)
        RunSlashCmd("/autofarm show")
    end
    
    -- Restore debug window state
    if self.db.profile.debugWindowEnabled then
        self.debugWindowEnabled = true
        self:CreateDebugWindow()
    end
    
    print("|cFF00FF00AzeroCombat Enhanced|r rotation addon loaded. Type /ac for commands.")
    print("Enhanced features: Better poison timing, performance monitoring, phase detection")
    print("|cFFFFFF00Position System:|r Using AceDB for reliable position saving")
    self.initialized = true
end

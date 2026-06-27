-- AzeroCombat: Warrior Rotations (ENHANCED - Better DPS, Threat, and Survivability)
-- INCLUDES: Smart Targeting System for WotLK 3.3.5a
-- FIXED: No more taunt spam + no defensive freezing + smart melee prioritization
-- FIXED: All cooldown checks, range validation, and freeze points eliminated
-- FIXED: Full 3.3.5a Lua 5.1 compatibility - NO Lua 5.2+ features
local AddonName, AC = ...

local S = {
    -- Attacks
    MortalStrike = "Mortal Strike", Slam = "Slam", Bloodthirst = "Bloodthirst", Whirlwind = "Whirlwind",
    HeroicStrike = "Heroic Strike", Cleave = "Cleave", Execute = "Execute", Devastate = "Devastate", 
    ShieldSlam = "Shield Slam", Revenge = "Revenge", Rend = "Rend", Overpower = "Overpower",
    SunderArmor = "Sunder Armor", HeroicThrow = "Heroic Throw", Shockwave = "Shockwave",
    ConcussionBlow = "Concussion Blow",
    ShieldBlock = "Shield Block", VictoryRush = "Victory Rush", SweepingStrikes = "Sweeping Strikes",
    
    -- Threat abilities
    Taunt = "Taunt", MockingBlow = "Mocking Blow", ChallengingShout = "Challenging Shout",
    
    -- Cooldowns
    Recklessness = "Recklessness", BloodRage = "Bloodrage", Retaliation = "Retaliation", ShieldWall = "Shield Wall", 
    LastStand = "Last Stand", EnragedRegeneration = "Enraged Regeneration", DeathWish = "Death Wish", 
    BerserkerRage = "Berserker Rage", Bladestorm = "Bladestorm", SpellReflection = "Spell Reflection",
    ShatteringThrow = "Shattering Throw", Vigilance = "Vigilance",
    
    -- Shouts
    BattleShout = "Battle Shout", CommandingShout = "Commanding Shout", DemoShout = "Demoralizing Shout",
    IntimidatingShout = "Intimidating Shout", ThunderClap = "Thunder Clap",
    
    -- Stances
    BattleStance = "Battle Stance", DefensiveStance = "Defensive Stance", BerserkerStance = "Berserker Stance",
    
    -- Utility
    Pummel = "Pummel", ShieldBash = "Shield Bash", 
    Charge = "Charge", Intercept = "Intercept", Intervene = "Intervene", Hamstring = "Hamstring", Disarm = "Disarm",
    
    -- Buffs/Debuffs
    Rampage = "Rampage", Bloodsurge = "Bloodsurge", SuddenDeath = "Sudden Death", 
    TasteForBlood = "Taste for Blood", SlamEffect = "Slam!", BloodFrenzy = "Blood Frenzy",
    EnrageEffect = "Enrage", VictoryRushBuff = "Victorious",
    
    -- Racial Abilities
    BloodFury = "Blood Fury", Berserking = "Berserking", WarStomp = "War Stomp", 
    WillOfForsaken = "Will of the Forsaken", EveryMan = "Every Man for Himself",      
    Stoneform = "Stoneform", EscapeArtist = "Escape Artist", Shadowmeld = "Shadowmeld",               
    GiftOfNaaru = "Gift of the Naaru", ArcaneTorrent = "Arcane Torrent"
}

-- FIXED: 3.3.5a Compatibility functions
local function GetGroupSize()
    if GetNumRaidMembers() > 0 then
        return GetNumRaidMembers() or 0
    else
        return GetNumPartyMembers() or 0
    end
end

local function WarriorDebug(msg)
    if AC.debugMode then
        if AC and AC.Debug then 
            AC:Debug("|cFFFF6600Warrior:|r " .. tostring(msg))
        else 
            print("|cFFFF6600Warrior:|r " .. tostring(msg))
        end
    end
end

local function TankDebug(msg)
    local _, class = UnitClass("player")
    if class == "WARRIOR" then
        WarriorDebug(msg)
    elseif AC.debugMode and AC and AC.Debug then
        local label = class == "PALADIN" and "|cFFFFD700Paladin:|r " or
                      class == "DRUID" and "|cFFFF7D0ADruid:|r " or
                      class == "DEATHKNIGHT" and "|cFFC41F3BDeathKnight:|r " or
                      "|cFFFFFFFFTank:|r "
        AC:Debug(label .. tostring(msg))
    end
end

local function QueueOnNextSwing(spellName, debugText)
    if not spellName or not AC:IsUsableSpell(spellName) or IsCurrentSpell(spellName) then
        return false
    end

    CastSpellByName(spellName, "target")
    if debugText then
        WarriorDebug(debugText)
    end
    return true
end

-- Prevent rage dumps from starving core rotational abilities.
local function ShouldQueueRageDump(rage, primaryCooldowns, minRage)
    if rage < (minRage or 70) then
        return false
    end

    if not primaryCooldowns then
        return true
    end

    for _, cd in ipairs(primaryCooldowns) do
        if cd and cd >= 0 and cd < 1.5 then
            return false
        end
    end

    return true
end

-- FIXED: Enhanced throttle with better error handling to prevent freezes
local function Throttle(key, interval)
    local classKey = "Warrior_" .. key 
    if AC and AC.Throttle then 
        return AC:Throttle(classKey, interval)
    end
    AC.warriorThrottles = AC.warriorThrottles or {}
    local currentTime = GetTime()
    if not AC.warriorThrottles[classKey] or (currentTime - AC.warriorThrottles[classKey] > interval) then
        AC.warriorThrottles[classKey] = currentTime
        return true
    end
    return false
end

local function ArmsDebugState(key, message)
    if not AC or not AC.debugMode then
        return
    end

    AC.armsDebugState = AC.armsDebugState or {}
    if AC.armsDebugState[key] ~= message then
        AC.armsDebugState[key] = message
        WarriorDebug(message)
    end
end

function AC:IsAutoTargetSwitchAllowed()
    if not self:IsTankSpec() then
        return true
    end

    return self:GetGroupSize() <= 5
end

-- REMOVED: IsWarriorTank function - replaced by Core.lua universal IsTankSpec()

-- ENHANCED: Track last taunt time and target with better initialization
AC.lastTauntTime = AC.lastTauntTime or 0
AC.lastTauntTarget = AC.lastTauntTarget or ""
AC.lastWarriorChargeCastTime = AC.lastWarriorChargeCastTime or 0

-- =============================================
-- ENHANCED SMART TARGETING SYSTEM (WotLK 3.3.5a)
-- =============================================

-- ENHANCED: Range detection functions for WotLK 3.3.5a with better error handling
function AC:IsInMeleeRange(unit, strict)
    if not UnitExists(unit) or not UnitCanAttack("player", unit) then return false end

    -- Prefer spell-based checks that respect boss hitboxes (edge-to-edge)
    -- Try a list of common melee-range warrior abilities the player may know
    local meleeSpells = {
        S.Hamstring,
        S.SunderArmor,
        S.Rend,
        S.HeroicStrike,
        S.Devastate,
        S.MortalStrike,
        S.Bloodthirst,
        S.ShieldSlam,
        S.Revenge,
    }

    local sawValidRangeResult = false
    for _, spell in ipairs(meleeSpells) do
        if self:KnowsSpell(spell) then
            local ok, inRange = pcall(IsSpellInRange, spell, unit)
            if ok and inRange ~= nil then
                sawValidRangeResult = true
                if inRange == 1 then
                    return true
                end
            end
        end
    end

    -- If we got explicit spell range results and none were in range, treat as out of range.
    if sawValidRangeResult then
        return false
    end

    -- Strict mode: don't use broad interact-distance fallbacks for cast gating.
    if strict then
        return false
    end

    -- Fallback: duel-range check (rough, center-to-center; can be wrong on big hitboxes)
    local success, result = pcall(CheckInteractDistance, unit, 3)
    return success and result or false
end

function AC:IsInTauntRange(unit)
    if not UnitExists(unit) then return false end
    
    -- FIXED: Add error handling and fallback
    local success, result = pcall(IsSpellInRange, S.Taunt, unit)
    if not success then return false end
    
    -- Taunt has 30 yard range in WotLK
    return result == 1
end

function AC:IsInHeroicThrowRange(unit)
    if not UnitExists(unit) then return false end
    
    -- FIXED: Add error handling
    local success, result = pcall(IsSpellInRange, S.HeroicThrow, unit)
    if not success then return false end
    
    -- Heroic Throw has 30 yard range in WotLK
    return result == 1
end

function AC:IsInChargeRange(unit)
    if not UnitExists(unit) then return false end
    
    -- FIXED: Add error handling
    local success, result = pcall(IsSpellInRange, S.Charge, unit)
    if not success then return false end
    
    -- Charge has 8-25 yard range in WotLK
    return result == 1
end

function AC:IsInInterveneRange(unit)
    if not UnitExists(unit) then return false end
    
    -- FIXED: Add error handling
    local success, result = pcall(IsSpellInRange, S.Intervene, unit)
    if not success then return false end
    
    -- Intervene has 25 yard range in WotLK
    return result == 1
end

function AC:IsInInterceptRange(unit)
    if not UnitExists(unit) then return false end
    
    -- FIXED: Add error handling
    local success, result = pcall(IsSpellInRange, S.Intercept, unit)
    if not success then return false end
    
    -- Intercept has 8-25 yard range in WotLK (Berserker Stance only)
    return result == 1
end

-- ENHANCED: Check available ranged abilities for Protection warriors with cooldown validation
function AC:GetAvailableRangedAbilities()
    local abilities = {}
    
    -- FIXED: Check both spell knowledge AND cooldown status
    -- Taunt (level 10+, most important)
    if UnitLevel("player") >= 10 and self:IsUsableSpell(S.Taunt) and self:GetSpellCooldown(S.Taunt) == 0 then
        abilities.taunt = true
    end
    
    -- Mocking Blow (level 14+, backup taunt)
    if UnitLevel("player") >= 14 and self:IsUsableSpell(S.MockingBlow) and self:GetSpellCooldown(S.MockingBlow) == 0 then
        abilities.mockingBlow = true
    end
    
    -- Heroic Throw (level 20+, ranged damage)
    if UnitLevel("player") >= 20 and self:IsUsableSpell(S.HeroicThrow) and self:GetSpellCooldown(S.HeroicThrow) == 0 then
        abilities.heroicThrow = true
    end
    
    -- Charge (level 4+, gap closer - but only out of combat)
    if UnitLevel("player") >= 4 and not UnitAffectingCombat("player") and self:IsUsableSpell(S.Charge) and self:GetSpellCooldown(S.Charge) == 0 then
        abilities.charge = true
    end
    
    -- Intercept (level 30+, gap closer - Berserker Stance OR Warbringer talent) 
    if UnitLevel("player") >= 30 and self:IsUsableSpell(S.Intercept) and self:GetSpellCooldown(S.Intercept) == 0 then
        local hasWarbringer = self:HasWarbringerTalent()
        if hasWarbringer or self:GetCurrentStance() == 3 then
            abilities.intercept = true
        end
    end
    
    -- Intervene (level 70+, gap closer to allies)
    if UnitLevel("player") >= 70 and self:IsUsableSpell(S.Intervene) and self:GetSpellCooldown(S.Intervene) == 0 then
        abilities.intervene = true
    end
    
    -- Challenging Shout (level 6+, AoE taunt)
    if UnitLevel("player") >= 6 and self:IsUsableSpell(S.ChallengingShout) and self:GetSpellCooldown(S.ChallengingShout) == 0 then
        abilities.challengingShout = true
    end
    
    return abilities
end

-- FIXED: Check if Thunder Clap will hit targets using proper melee range
function AC:ThunderClapInRange()
    -- Thunder Clap is centered on the player. For rotation safety, require strict melee
    -- validation on the current hostile target rather than broad nearby-unit inference.
    if not UnitExists("target") or not UnitCanAttack("player", "target") or UnitIsDeadOrGhost("target") then
        return false
    end
    return self:IsInMeleeRange("target", true)
end

-- Count hostiles physically close enough to likely be hit by Thunder Clap.
function AC:GetEnemiesInThunderClapReach(maxNameplates)
    maxNameplates = maxNameplates or 20
    local count = 0
    local processedGUIDs = {}
    local groupSize = GetNumRaidMembers() > 0 and GetNumRaidMembers() or GetNumPartyMembers()
    local unitPrefix = GetNumRaidMembers() > 0 and "raid" or "party"

    local function addUnitInReach(unit, requireCombat)
        if not UnitExists(unit) or not UnitCanAttack("player", unit) or UnitIsDeadOrGhost(unit) then
            return
        end
        if requireCombat and not UnitAffectingCombat(unit) then
            return
        end
        if not CheckInteractDistance(unit, 3) then
            return
        end

        local guid = UnitGUID(unit) or unit
        if processedGUIDs[guid] then
            return
        end

        processedGUIDs[guid] = true
        count = count + 1
    end

    addUnitInReach("target", false)
    addUnitInReach("focus", true)
    addUnitInReach("mouseover", true)

    for i = 1, groupSize do
        addUnitInReach(unitPrefix .. i .. "target", true)
    end

    for i = 1, maxNameplates do
        addUnitInReach("nameplate" .. i, true)
    end

    return count
end

-- Confirm at least one hostile is physically close enough to likely be hit by Thunder Clap.
function AC:HasEnemyInThunderClapReach(maxNameplates)
    return self:GetEnemiesInThunderClapReach(maxNameplates) >= 1
end

-- =============================================
-- ENHANCED TARGET FINDING AND SWITCHING LOGIC
-- =============================================

-- ENHANCED: Find best target with smart melee prioritization and performance optimization
function AC:FindBestWarriorTarget()
    return self:FindBestTankTarget()
end

-- FIXED: Enhanced ranged ability usage with immediate return to melee and cooldown checks
function AC:UseRangedAbilityAndReturn(ability, target)
    target = target or "target"
    if not UnitExists(target) then return false end
    
    local success = false

    local function castAttempt(spellName, unit)
        CastSpellByName(spellName, unit)
        return true
    end

    if (ability == "Taunt" or ability == "Mocking Blow") and not self:IsAutoTauntAllowed() then
        if Throttle("AutoTauntSuppressed", 2.0) then
            WarriorDebug("Skipping " .. ability .. " - auto taunt disabled for large groups")
        end
        return false
    end

    if ability == "Taunt" and self:IsUsableSpell(S.Taunt) then
        -- FIXED: Check cooldown before attempting
        if self:GetSpellCooldown(S.Taunt) > 0 then
            WarriorDebug("Taunt on cooldown, skipping")
            return false
        end
        
        -- ENHANCED: Prevent wasteful Taunt usage - only for threat emergencies
        local targetTarget = target .. "target"
        if UnitExists(targetTarget) and UnitIsFriend("player", targetTarget) and not UnitIsUnit(targetTarget, "player") then
            if self:GetGroupSize() > 5 and not self:IsRaidTauntSafeVictim(targetTarget) then
                WarriorDebug("BLOCKED raid Taunt - target is on confirmed tank victim: " .. (UnitName(targetTarget) or "Unknown"))
                return false
            end

            -- Target is attacking an ally - legitimate Taunt use
            if self:IsInTauntRange(target) then
                local targetGUID = UnitGUID(target)
                if self:ShouldSkipTankRepeatTaunt(targetGUID, targetTarget) then return false end
                if castAttempt(S.Taunt, target) then
                    self.lastTauntTime = GetTime()
                    self.lastTauntTarget = targetGUID
                    self:RecordTankTaunt(targetGUID)
                    self:MarkAsOurTarget(targetGUID)
                    self:TrackTauntedLooseMob(targetGUID, UnitName(target))
                    WarriorDebug("Used EMERGENCY Taunt - target attacking ally: " .. (UnitName(targetTarget) or "Unknown"))
                    success = true
                else
                    WarriorDebug("Taunt cast attempt failed")
                    return false
                end
            end
        else
            -- Target is not attacking anyone or attacking the player - don't waste Taunt
            WarriorDebug("BLOCKED wasteful Taunt - target not threatening allies (use Heroic Throw instead)")
            return false
        end
    elseif ability == "Heroic Throw" and self:IsUsableSpell(S.HeroicThrow) then
        -- FIXED: Check cooldown
        if self:GetSpellCooldown(S.HeroicThrow) > 0 then
            WarriorDebug("Heroic Throw on cooldown, skipping")
            return false
        end
        
        if self:IsInHeroicThrowRange(target) then
            if castAttempt(S.HeroicThrow, target) then
                self:MarkAsOurTarget(UnitGUID(target))
                WarriorDebug("Used Heroic Throw on distant target")
                success = true
            else
                WarriorDebug("Heroic Throw cast attempt failed")
                return false
            end
        end
    elseif ability == "Charge" and self:IsUsableSpell(S.Charge) then
        -- Charge is normally out-of-combat only; Warbringer allows in-combat usage.
        local hasWarbringer = self:HasWarbringerTalent()
        local inCombat = UnitAffectingCombat("player")
        if inCombat and not hasWarbringer then
            WarriorDebug("Charge blocked in combat (no Warbringer)")
            return false
        end

        if self:GetSpellCooldown(S.Charge) > 0 then
            WarriorDebug("Charge on cooldown, skipping")
            return false
        end

        if self:IsInChargeRange(target) then
            if castAttempt(S.Charge, target) then
                self:MarkWarriorChargeCast()
                self:MarkAsOurTarget(UnitGUID(target))
                WarriorDebug("Used Charge on distant target" .. (hasWarbringer and " (Warbringer)" or ""))
                success = true
            else
                WarriorDebug("Charge cast attempt failed")
                return false
            end
        end
    elseif ability == "Intercept" and self:IsUsableSpell(S.Intercept) then
        -- FIXED: Check cooldown and stance requirements
        if self:GetSpellCooldown(S.Intercept) > 0 then
            WarriorDebug("Intercept on cooldown, skipping")
            return false
        end
        
        -- Must be in Berserker Stance for Intercept (unless Warbringer talent)
        local hasWarbringer = self:HasWarbringerTalent()
        if not hasWarbringer and self:GetCurrentStance() ~= 3 then
            WarriorDebug("Not in Berserker Stance for Intercept (no Warbringer)")
            return false
        end
        
        if self:IsInInterceptRange(target) then
            if castAttempt(S.Intercept, target) then
                self:MarkAsOurTarget(UnitGUID(target))
                WarriorDebug("Used Intercept on distant target")
                success = true
            else
                WarriorDebug("Intercept cast attempt failed")
                return false
            end
        end
    elseif ability == "Mocking Blow" and self:IsUsableSpell(S.MockingBlow) then
        -- FIXED: Check cooldown
        if self:GetSpellCooldown(S.MockingBlow) > 0 then
            WarriorDebug("Mocking Blow on cooldown, skipping")
            return false
        end
        
        if self:IsInMeleeRange(target, true) then  -- Mocking Blow is melee range
            if castAttempt(S.MockingBlow, target) then
                self:MarkAsOurTarget(UnitGUID(target))
                WarriorDebug("Used Mocking Blow")
                success = true
            else
                WarriorDebug("Mocking Blow cast attempt failed")
                return false
            end
        end
    elseif ability == "Intervene" and self:IsUsableSpell(S.Intervene) then
        -- FIXED: Check cooldown
        if self:GetSpellCooldown(S.Intervene) > 0 then
            WarriorDebug("Intervene on cooldown, skipping")
            return false
        end

        local interveneUnit = self:ResolveWarriorInterveneFriendlyUnit(target)
        if interveneUnit then
            if castAttempt(S.Intervene, interveneUnit) then
                self:MarkWarriorChargeCast()
                if UnitExists("target") and UnitCanAttack("player", "target") then
                    if not IsCurrentSpell("Attack") then
                        StartAttack()
                    end
                    self:MarkAsOurTarget(UnitGUID("target"))
                end
                WarriorDebug("Used Intervene gap closer via " .. (UnitName(interveneUnit) or "Unknown"))
                success = true
            else
                WarriorDebug("Intervene cast attempt failed on " .. (UnitName(interveneUnit) or interveneUnit))
                return false
            end
        end
    end
    
    -- Intervene movement needs the hostile target preserved so follow-up threat can resume.
    if success and ability ~= "Intervene" and self:IsAutoTargetSwitchAllowed() and not self:IsInMeleeRange(target) then
        local meleeTarget = self:FindMeleeTarget()
        if meleeTarget and not UnitIsUnit(meleeTarget, target) then
            TargetUnit(meleeTarget)
            WarriorDebug("Switched back to melee target after ranged ability")
        end
    end
    
    return success
end

-- HELPER: Find any available melee target with performance optimization (FIXED: 3.3.5a compatible)
function AC:FindMeleeTarget()
    -- Quick scan for melee targets (reduced range)
    for i = 1, 15 do  -- Reduced from 40 for performance
        local unit = "nameplate" .. i
        if UnitExists(unit) and UnitCanAttack("player", unit) and 
           not UnitIsDead(unit) and self:IsInMeleeRange(unit, true) then
            return unit
        end
    end
    
    -- Check group targets with size limit (FIXED: 3.3.5a compatible)
    if IsInGroup() then
        local groupSize = math.min(GetGroupSize(), 20)  -- Cap for performance
        local unitPrefix = GetNumRaidMembers() > 0 and "raid" or "party"
        
        for i = 1, groupSize do
            local groupTarget = unitPrefix .. i .. "target"
            if UnitExists(groupTarget) and UnitCanAttack("player", groupTarget) and 
               not UnitIsDead(groupTarget) and self:IsInMeleeRange(groupTarget, true) then
                return groupTarget
            end
        end
    end
    
    return nil
end

function AC:ResolveWarriorInterveneFriendlyUnit(unit)
    if not unit or not UnitExists(unit) or UnitIsUnit(unit, "player") or UnitIsDeadOrGhost(unit) then
        return nil
    end

    local resolvedUnit = unit

    if UnitCanAttack("player", unit) then
        local victimUnit = unit .. "target"
        if not UnitExists(victimUnit) or not UnitIsFriend("player", victimUnit) or UnitIsUnit(victimUnit, "player") or
           UnitIsDeadOrGhost(victimUnit) then
            return nil
        end

        local groupSize = GetGroupSize()
        local unitPrefix = GetNumRaidMembers() > 0 and "raid" or "party"
        for i = 1, groupSize do
            local groupUnit = unitPrefix .. i
            if UnitExists(groupUnit) and UnitIsUnit(groupUnit, victimUnit) then
                resolvedUnit = groupUnit
                break
            end
        end
    elseif not UnitIsFriend("player", unit) then
        return nil
    end

    if not self:IsInInterveneRange(resolvedUnit) then
        return nil
    end

    return resolvedUnit
end

function AC:FindWarriorInterveneTarget(hostileTarget)
    if self:GetPlayerSpec() ~= "Protection" then return nil end
    if GetGroupSize() > 5 then return nil end
    if not UnitAffectingCombat("player") then return nil end
    if not self:KnowsSpell(S.Intervene) or not self:IsUsableSpell(S.Intervene) then return nil end
    if self:GetSpellCooldown(S.Intervene) > 0 then return nil end
    if not hostileTarget or not UnitExists(hostileTarget) or not UnitCanAttack("player", hostileTarget) or UnitIsDeadOrGhost(hostileTarget) then
        return nil
    end

    local groupSize = GetGroupSize()
    local unitPrefix = GetNumRaidMembers() > 0 and "raid" or "party"

    local directInterveneUnit = self:ResolveWarriorInterveneFriendlyUnit(hostileTarget)
    if directInterveneUnit then
        return directInterveneUnit
    end

    for i = 1, groupSize do
        local unit = unitPrefix .. i
        local interveneUnit = self:ResolveWarriorInterveneFriendlyUnit(unit)
        if interveneUnit then
            local unitTarget = interveneUnit .. "target"
            if UnitExists(unitTarget) and UnitIsUnit(unitTarget, hostileTarget) then
                return interveneUnit
            end
        end
    end

    return nil
end

-- =============================================
-- ENHANCED UTILITY FUNCTIONS WITH FREEZE PREVENTION
-- =============================================


-- FIXED: Enhanced trinket usage with better checks and freeze prevention
function AC:UseTrinketsFixed()
    -- FIXED: Throttle trinket attempts to prevent spam
    if not Throttle("TrinketUse", 3.0) then
        return false
    end
    
    -- Check both trinket slots (13 = top, 14 = bottom)
    for slot = 13, 14 do
        local success, itemLink = pcall(GetInventoryItemLink, "player", slot)
        if success and itemLink then
            local startSuccess, start, duration = pcall(GetInventoryItemCooldown, "player", slot)
            if startSuccess then
                local isUsable = IsUsableItem(itemLink)
                local isReady = (start == 0) or (start > 0 and GetTime() >= start + duration)
                
                if isUsable and isReady then
                    UseInventoryItem(slot)
                    local itemName = GetItemInfo(itemLink) or "Unknown"
                    WarriorDebug("Used trinket in slot " .. slot .. ": " .. itemName)
                    
                    -- Check if this trinket has a cooldown after use (active trinket)
                    local newStart, newDuration = GetInventoryItemCooldown("player", slot)
                    if newStart > 0 and newDuration > 0 then
                        -- Active trinket with cooldown - count as successful usage
                        WarriorDebug("Active trinket used with " .. newDuration .. "s cooldown")
                        return true
                    else
                        -- Passive trinket - don't count as successful usage
                        WarriorDebug("Passive trinket attempted - continuing to check other abilities")
                    end
                else
                    WarriorDebug("Trinket in slot " .. slot .. " not ready (cooldown or conditions)")
                end
            else
                WarriorDebug("Error checking trinket cooldown in slot " .. slot)
            end
        else
            WarriorDebug("No trinket equipped in slot " .. slot)
        end
    end
    
    return false
end


-- ENHANCED: Victory Rush usage with better conditions
function AC:TryVictoryRush()
    if not self:KnowsSpell(S.VictoryRush) then return false end
    
    -- Check if we have the Victory Rush buff (Victorious)
    if self:HasBuff("player", S.VictoryRushBuff) and self:IsUsableSpell(S.VictoryRush) then
        -- Use it if we're below 80% health or about to cap rage
        local health = self:GetPlayerHealthPercent()
        local rage = UnitPower("player", 1)
        
        if health < 80 or rage > 90 then
            CastSpellByName(S.VictoryRush)
            WarriorDebug("Victory Rush - free healing")
            return true
        end
    end
    
    return false
end


-- =============================================
-- ENHANCED DEFENSIVE AND COMBAT SYSTEMS
-- =============================================

-- FIXED: Smart defensive cooldown usage - NO MORE FREEZING/SPAM
function AC:UseWarriorDefensives()
    local health = self:GetPlayerHealthPercent()
    local inCombat = UnitAffectingCombat("player")
    local enemies = self:GetEnemyCount()
    local spec = self:GetPlayerSpec()
    
    if not inCombat then return false end
    
    -- Re-check defensives frequently enough to react to real burst damage.
    if not Throttle("WarriorDefensives", 1.0) then return false end
    
    if not self.defensiveAttempts then
        self.defensiveAttempts = {}
    end
    
    if not self.lastDefensiveReset or (GetTime() - self.lastDefensiveReset) > 45 then
        self.defensiveAttempts = {}
        self.lastDefensiveReset = GetTime()
        WarriorDebug("Reset defensive attempts")
    end

    local now = GetTime()
    local currentStance = self:GetCurrentStance()
    local hasShield = IsEquippedItemType("Shields")
    local hasTarget = UnitExists("target") and UnitCanAttack("player", "target") and not UnitIsDeadOrGhost("target")
    local targetClass = hasTarget and UnitClassification("target") or nil
    local activelyTanking = hasTarget and UnitExists("targettarget") and UnitIsUnit("targettarget", "player")
    local dangerousTarget = targetClass == "elite" or targetClass == "rareelite" or targetClass == "worldboss"
    local incomingDamage = self.PredictIncomingDamage and self:PredictIncomingDamage() or 0
    local underHeavyPressure = activelyTanking and (dangerousTarget or enemies >= 3 or incomingDamage >= 150)

    local function canRetry(key, retryAfter)
        local lastAttempt = self.defensiveAttempts[key]
        return not lastAttempt or (now - lastAttempt) >= retryAfter
    end

    local function markAttempt(key)
        self.defensiveAttempts[key] = now
    end

    local function shouldDelayConsumableRetry(reason)
        return reason == "attempted" or reason == "gcd" or reason == "locked" or
               reason == "blocked" or reason == "cooldown"
    end
    
    if health < 35 and canRetry("healthPotion", 20) then
        local usedPotion, reason = self:UseHealthPotion(35)
        if usedPotion then
            markAttempt("healthPotion")
            WarriorDebug("Used health potion at " .. string.format("%.0f", health) .. "% health")
            return true
        end
        if shouldDelayConsumableRetry(reason) then
            markAttempt("healthPotion")
        end
        if self.debugMode then
            WarriorDebug("Health potion unavailable: " .. tostring(reason or "none"))
        end
    end
    
    -- Last Stand is the first major survivability button for prot pressure.
    if self:KnowsSpell(S.LastStand) and self:GetSpellCooldown(S.LastStand) == 0 and canRetry("lastStand", 8) then
        if health < 30 or (spec == "Protection" and underHeavyPressure and health < 40) then
            markAttempt("lastStand")
            CastSpellByName(S.LastStand)
            WarriorDebug("Last Stand at low health / tank pressure")
            return true
        end
    end

    -- Shield Wall is the hard panic button; keep it later than Last Stand.
    if self:KnowsSpell(S.ShieldWall) and self:GetSpellCooldown(S.ShieldWall) == 0 and canRetry("shieldWall", 8) then
        if self:KnowsSpell(S.ShieldWall) and self:GetSpellCooldown(S.ShieldWall) == 0 then
            if hasShield and (health < 20 or (spec == "Protection" and underHeavyPressure and health < 30)) then
                markAttempt("shieldWall")
                self.shieldWallBlocked = false
                CastSpellByName(S.ShieldWall)
                WarriorDebug("Shield Wall at critical health / tank burst")
                return true
            else
                if spec == "Protection" then
                    local shouldLogBlocked = (not self.shieldWallBlocked) or Throttle("ShieldWallBlockedDebug", 30.0)
                    self.shieldWallBlocked = true
                    if shouldLogBlocked then
                        WarriorDebug("Shield Wall blocked: missing shield or threshold not met")
                    end
                end
            end
        end
    end
    
    -- Enraged Regeneration works best as follow-up stabilization.
    if health < 45 and canRetry("enragedRegen", 6) and self:KnowsSpell(S.EnragedRegeneration) then
        if self:KnowsSpell(S.EnragedRegeneration) then
            local isEnraged = self:HasBuff("player", S.BerserkerRage) or 
                             self:HasBuff("player", S.DeathWish) or 
                             self:HasBuff("player", S.EnrageEffect) or
                             self:HasBuff("player", S.BloodRage)
            
            if isEnraged and self:GetSpellCooldown(S.EnragedRegeneration) == 0 then
                markAttempt("enragedRegen")
                CastSpellByName(S.EnragedRegeneration)
                WarriorDebug("Enraged Regeneration")
                return true
            elseif not isEnraged and self:KnowsSpell(S.BerserkerRage) and 
                   self:GetSpellCooldown(S.BerserkerRage) == 0 and 
                   canRetry("berserkerForRegen", 4) and health < 35 then
                markAttempt("berserkerForRegen")
                CastSpellByName(S.BerserkerRage)
                WarriorDebug("Berserker Rage for Enraged Regen")
                return true
            end
        end
    end
    
    -- REMOVED: Old reactive Spell Reflection - now handled proactively in rotation interrupt priority
    
    -- Fear is a last-resort solo survival tool, not a normal tank-group button.
    if not IsInGroup() and health < 12 and enemies >= 3 and canRetry("intimidatingShout", 15) then
        if self:KnowsSpell(S.IntimidatingShout) and self:GetSpellCooldown(S.IntimidatingShout) == 0 then
            markAttempt("intimidatingShout")
            CastSpellByName(S.IntimidatingShout)
            WarriorDebug("Intimidating Shout - crowd control")
            return true
        end
    end
    
    if (health < 35 or (spec == "Protection" and underHeavyPressure and health < 45)) and canRetry("trinkets", 20) then
        if self:UseTrinketsFixed() then
            markAttempt("trinkets")
            WarriorDebug("Used defensive trinket")
            return true
        end
    end
    
    if (health < 30 or (spec == "Protection" and underHeavyPressure and health < 40)) and canRetry("defensivePotion", 20) then
        local usedPotion, reason = self:UseDefensivePotion(3)
        if usedPotion then
            markAttempt("defensivePotion")
            WarriorDebug("Used defensive potion")
            return true
        end
        if shouldDelayConsumableRetry(reason) then
            markAttempt("defensivePotion")
        end
        if self.debugMode then
            WarriorDebug("Defensive potion unavailable: " .. tostring(reason or "none"))
        end
    end
    
    return false
end

-- =============================================
-- ENHANCED SPELL REFLECTION SYSTEM
-- =============================================

-- ENHANCED: Proactive Spell Reflection system with intelligent spell detection
function AC:UseEnhancedSpellReflection()
    if not self:KnowsSpell(S.SpellReflection) or self:GetSpellCooldown(S.SpellReflection) > 0 then
        return false
    end
    
    local spec = self:GetPlayerSpec()
    local hasShield = IsEquippedItemType("Shields")
    if not hasShield then
        -- For DPS specs, never attempt reflection without a shield.
        if spec ~= "Protection" then
            return false
        end
        -- For Protection, keep a throttled debug hint only.
        if Throttle("SpellReflectNoShield", 10.0) then
            WarriorDebug("Spell Reflection blocked: no shield equipped")
        end
        return false
    end
    
    if not UnitExists("target") or not UnitCanAttack("player", "target") then
        return false
    end
    
    -- Check if target is casting a spell worth reflecting
    local spellName, _, _, _, _, endTime = UnitCastingInfo("target")
    local isChanneling = false
    
    if not spellName then
        spellName, _, _, _, _, endTime = UnitChannelInfo("target")
        isChanneling = true
    end
    
    if not spellName or not endTime then
        return false
    end
    
    local timeLeft = (endTime / 1000) - GetTime()
    local health = self:GetPlayerHealthPercent()
    
    -- High-priority dangerous spells that should ALWAYS be reflected
    local dangerousSpells = {
        -- Crowd Control (highest priority)
        "Fear", "Psychic Scream", "Howl of Terror", "Intimidating Shout",
        "Polymorph", "Hex", "Banish", "Hibernate", "Entangling Roots",
        "Cyclone", "Freezing Trap", "Sap",
        
        -- High Damage Spells
        "Fireball", "Greater Fireball", "Pyroblast", "Scorch", "Fire Blast",
        "Frostbolt", "Ice Lance", "Cone of Cold", "Blizzard",
        "Lightning Bolt", "Chain Lightning", "Lava Burst", "Lightning Strike",
        "Shadow Bolt", "Drain Soul", "Drain Life", "Shadowburn",
        "Mind Blast", "Mind Flay", "Shadow Word: Pain", "Vampiric Touch",
        "Wrath", "Starfire", "Moonfire", "Insect Swarm",
        "Holy Light", "Flash of Light", "Greater Heal", "Heal",
        
        -- Debuffs and DoTs
        "Curse of Agony", "Curse of Doom", "Corruption", "Immolate",
        "Unstable Affliction", "Haunt", "Seed of Corruption"
    }
    
    -- Check for dangerous spells (always reflect these)
    for _, dangerous in ipairs(dangerousSpells) do
        if spellName:find(dangerous) then
            -- Optimal timing: cast when 0.5-2.5s left on cast
            if timeLeft > 0.5 and timeLeft < 2.5 then
                CastSpellByName(S.SpellReflection)
                WarriorDebug("SPELL REFLECTION: " .. spellName .. " (HIGH PRIORITY)")
                return true
            -- Emergency timing for very dangerous spells
            elseif (spellName:find("Fear") or spellName:find("Polymorph") or spellName:find("Hex")) and timeLeft > 0.2 then
                CastSpellByName(S.SpellReflection)
                WarriorDebug("SPELL REFLECTION: " .. spellName .. " (EMERGENCY CC)")
                return true
            end
        end
    end
    
    -- Reflect any spell when health is low (survival mode)
    if health < 50 and timeLeft > 0.5 and timeLeft < 2.5 then
        CastSpellByName(S.SpellReflection)
        WarriorDebug("SPELL REFLECTION: " .. spellName .. " (LOW HEALTH SURVIVAL)")
        return true
    end
    
    -- Reflect any spell when health is critical (desperation mode)
    if health < 25 and timeLeft > 0.2 and timeLeft < 3.0 then
        CastSpellByName(S.SpellReflection)
        WarriorDebug("SPELL REFLECTION: " .. spellName .. " (CRITICAL HEALTH)")
        return true
    end
    
    -- Elite/Boss enemies: reflect more liberally
    local classification = UnitClassification("target")
    if (classification == "elite" or classification == "rareelite" or classification == "worldboss") then
        if health < 75 and timeLeft > 0.5 and timeLeft < 2.5 then
            CastSpellByName(S.SpellReflection)
            WarriorDebug("SPELL REFLECTION: " .. spellName .. " (ELITE/BOSS)")
            return true
        end
    end
    
    return false
end


-- ENHANCED: Smart offensive cooldown usage with better conditions
function AC:UseWarriorOffensives()
    local targetHP = self:GetTargetHealthPercent("target")
    local targetClass = UnitClassification("target")
    local spec = self:GetPlayerSpec()
    local rage = UnitPower("player", 1)
    
    -- FIXED: Throttle offensive cooldowns to prevent spam
    if not Throttle("WarriorOffensives", 5.0) then return false end
    
    -- Don't blow CDs on trivial mobs
    if targetClass == "trivial" or targetHP < 30 then
        return false
    end
    
    -- Check if it's worth using offensive CDs
    local worthIt = targetClass == "elite" or targetClass == "rareelite" or 
                   targetClass == "worldboss" or targetHP > 200000 or
                   (IsInGroup() and targetHP > 50)
    
    if not worthIt then return false end
    
    -- FIXED: Check cooldowns before attempting
    -- Recklessness (big DPS boost)
    if self:IsUsableSpell(S.Recklessness) and self:GetSpellCooldown(S.Recklessness) == 0 and Throttle("Recklessness", 180) then
        CastSpellByName(S.Recklessness)
        WarriorDebug("Recklessness - burst window")
        -- Use offensive racial
        self:UseRacialsWarrior(true, false)
        -- Use offensive trinkets
        self:UseTrinketsFixed()
        return true
    end
    
    -- Death Wish
    if self:KnowsSpell(S.DeathWish) and self:IsUsableSpell(S.DeathWish) and self:GetSpellCooldown(S.DeathWish) == 0 and Throttle("DeathWish", 120) then
        CastSpellByName(S.DeathWish)
        WarriorDebug("Death Wish - increased damage")
        return true
    end
    
    -- Arms handles Bladestorm inside its rotation so it does not delay Rend, Overpower, or Mortal Strike.
    if spec ~= "Arms" and self:KnowsSpell(S.Bladestorm) and self:IsUsableSpell(S.Bladestorm) and self:GetSpellCooldown(S.Bladestorm) == 0 and
       (UnitExists("target") and self:GetEnemiesAtLocation("target", 10) >= 2 or targetHP > 50) and Throttle("Bladestorm", 90) then
        CastSpellByName(S.Bladestorm)
        WarriorDebug("Bladestorm")
        return true
    end
    
    return false
end

-- ENHANCED: Better racial usage with cooldown checks
function AC:UseRacialsWarrior(burst, emergency) 
    local checkFrequency = (self:GetPlayerSpec() == "Protection") and 2.0 or 3.0  -- Increased throttle
    if not Throttle("WarriorRacials", checkFrequency) then return false end
    
    local _, race = UnitRace("player")
    race = string.upper(race) 
    local healthPercent = self:GetPlayerHealthPercent()
    local inCombat = UnitAffectingCombat("player")
    
    -- Offensive racials during burst
    if burst and inCombat then
        if race == "ORC" and self:IsUsableSpell(S.BloodFury) and self:GetSpellCooldown(S.BloodFury) == 0 then
            CastSpellByName(S.BloodFury)
            WarriorDebug("Racial: Blood Fury (DPS)")
            return true
        end
        if race == "TROLL" and self:IsUsableSpell(S.Berserking) and self:GetSpellCooldown(S.Berserking) == 0 then
            CastSpellByName(S.Berserking)
            WarriorDebug("Racial: Berserking (Haste)")
            return true
        end
    end
    
    -- Defensive/Emergency racials
    if emergency or healthPercent < 50 then
        if race == "DWARF" and self:IsUsableSpell(S.Stoneform) and self:GetSpellCooldown(S.Stoneform) == 0 then
            CastSpellByName(S.Stoneform)
            WarriorDebug("Racial: Stoneform (Remove debuffs)")
            return true
        end
        if race == "HUMAN" and self:IsUsableSpell(S.EveryMan) and self:GetSpellCooldown(S.EveryMan) == 0 then
            CastSpellByName(S.EveryMan)
            WarriorDebug("Racial: Every Man for Himself")
            return true
        end
        if race == "GNOME" and self:IsUsableSpell(S.EscapeArtist) and self:GetSpellCooldown(S.EscapeArtist) == 0 then
            CastSpellByName(S.EscapeArtist)
            WarriorDebug("Racial: Escape Artist")
            return true
        end
        if (race == "UNDEAD" or race == "SCOURGE") and self:IsUsableSpell(S.WillOfForsaken) and self:GetSpellCooldown(S.WillOfForsaken) == 0 then
            CastSpellByName(S.WillOfForsaken)
            WarriorDebug("Racial: Will of the Forsaken")
            return true
        end
        if race == "DRAENEI" and healthPercent < 70 and self:IsUsableSpell(S.GiftOfNaaru) and self:GetSpellCooldown(S.GiftOfNaaru) == 0 then
            CastSpellByName(S.GiftOfNaaru, "player")
            WarriorDebug("Racial: Gift of Naaru (HoT)")
            return true
        end
    end
    
    -- Utility racials in combat
    if inCombat and UnitExists("target") and UnitCanAttack("player", "target") then
        if race == "TAUREN" and UnitExists("target") and self:GetEnemiesAtLocation("target", 10) >= 2 and self:IsInMeleeRange("target") and 
           self:IsUsableSpell(S.WarStomp) and self:GetSpellCooldown(S.WarStomp) == 0 then
            CastSpellByName(S.WarStomp)
            WarriorDebug("Racial: War Stomp (AoE Stun)")
            return true
        end
        if race == "BLOODELF" and self:IsUsableSpell(S.ArcaneTorrent) and self:GetSpellCooldown(S.ArcaneTorrent) == 0 and self:IsInMeleeRange("target") then
            -- Use for rage generation or silence
            local targetCasting = UnitCastingInfo("target")
            if targetCasting or UnitPower("player", 1) < 20 then
                CastSpellByName(S.ArcaneTorrent)
                WarriorDebug("Racial: Arcane Torrent")
                return true
            end
        end
    end
    return false
end

-- =============================================
-- ENHANCED THREAT TRACKING SYSTEM
-- =============================================

-- ENHANCED: Track which enemies should be targeting us with better cleanup
AC.expectedThreatTargets = AC.expectedThreatTargets or {}

-- FIXED: Better MarkAsOurTarget function with time tracking
function AC:MarkAsOurTarget(unitGUID)
    if unitGUID then
        self.expectedThreatTargets = self.expectedThreatTargets or {}
        self.expectedThreatTargets[unitGUID] = GetTime()
        TankDebug("Marked target as ours: " .. (UnitName("target") or "Unknown"))
    end
end

-- FIXED: Clean up old threat targets with performance optimization
function AC:CleanupThreatTargets()
    if not self.expectedThreatTargets then return end
    
    local now = GetTime()
    local toRemove = {}
    
    -- Collect entries to remove
    for guid, timestamp in pairs(self.expectedThreatTargets) do
        if now - timestamp > 30 then -- Remove after 30 seconds
            table.insert(toRemove, guid)
        end
    end
    
    -- Remove collected entries
    for _, guid in ipairs(toRemove) do
        self.expectedThreatTargets[guid] = nil
    end
    
    -- FIXED: Prevent memory leaks by limiting table size
    local count = 0
    for _ in pairs(self.expectedThreatTargets) do
        count = count + 1
        if count > 50 then -- Limit to 50 entries max
            -- Clear old entries if we have too many
            self.expectedThreatTargets = {}
            break
        end
    end
end

-- =============================================
-- FIXED ENHANCED TAUNT SYSTEM WITH SMART TARGETING (3.3.5a COMPATIBLE)
-- =============================================
-- =============================================
-- STANCE AND COMBAT UTILITY FUNCTIONS
-- =============================================

-- FIXED: Enhanced buff checking with performance optimization
function AC:WarriorHasAttackPowerBuff()
    local buffsToCheck = {
        [S.BattleShout] = true, 
        ["Blessing of Might"] = true, 
        ["Greater Blessing of Might"] = true,
    }
    
    for i = 1, 32 do
        local buffName = UnitBuff("player", i)
        if not buffName then break end
        if buffsToCheck[buffName] then
            if Throttle("ConflictingBuffDebug", 10.0) then
                WarriorDebug("Found active attack power buff: " .. buffName)
            end
            return true 
        end
    end
    return false
end

function AC:WarriorHasCommandingBuff()
    local buffsToCheck = {
        [S.CommandingShout] = true,
        ["Blood Pact"] = true,
        ["Power Word: Fortitude"] = true,
        ["Prayer of Fortitude"] = true,
    }

    for i = 1, 32 do
        local buffName = UnitBuff("player", i)
        if not buffName then break end
        if buffsToCheck[buffName] then
            return true
        end
    end
    return false
end

function AC:GetWarriorGroupClassMap()
    local now = GetTime()
    if self.warriorGroupClassCache and (now - self.warriorGroupClassCache.time) < 5 then
        return self.warriorGroupClassCache.map
    end

    local classMap = {}
    local _, playerClass = UnitClass("player")
    if playerClass then
        classMap[playerClass] = true
    end

    if IsInGroup() then
        if GetNumRaidMembers() > 0 then
            for i = 1, GetNumRaidMembers() do
                local unit = "raid" .. i
                if UnitExists(unit) then
                    local _, class = UnitClass(unit)
                    if class then
                        classMap[class] = true
                    end
                end
            end
        else
            for i = 1, GetNumPartyMembers() do
                local unit = "party" .. i
                if UnitExists(unit) then
                    local _, class = UnitClass(unit)
                    if class then
                        classMap[class] = true
                    end
                end
            end
        end
    end

    self.warriorGroupClassCache = {
        time = now,
        map = classMap
    }
    return classMap
end

function AC:GetPreferredWarriorShout(spec)
    local knowsBattle = self:KnowsSpell(S.BattleShout)
    local knowsCommanding = self:KnowsSpell(S.CommandingShout)
    if not knowsBattle and not knowsCommanding then
        return nil
    end

    local hasOwnBattle = self:HasBuff("player", S.BattleShout) and true or false
    local hasOwnCommanding = self:HasBuff("player", S.CommandingShout) and true or false
    local hasAPBuff = self:WarriorHasAttackPowerBuff()
    local hasStamBuff = self:WarriorHasCommandingBuff()
    local hasExternalAP = hasAPBuff and not hasOwnBattle
    local hasExternalStam = hasStamBuff and not hasOwnCommanding

    local preferredShout = nil
    if spec == "Protection" then
        preferredShout = knowsCommanding and S.CommandingShout or (knowsBattle and S.BattleShout or nil)
    else
        preferredShout = knowsBattle and S.BattleShout or (knowsCommanding and S.CommandingShout or nil)
    end

    local preferredActive = false
    if preferredShout == S.BattleShout then
        preferredActive = hasOwnBattle
    elseif preferredShout == S.CommandingShout then
        preferredActive = hasOwnCommanding
    end

    -- Solo (or no external buff coverage): keep only the spec-preferred shout.
    if preferredShout and (not IsInGroup() or (not hasExternalAP and not hasExternalStam)) then
        if preferredActive then
            return nil
        end
        return preferredShout
    end

    -- If both categories are already covered, don't spend rage/GCD.
    if hasAPBuff and hasStamBuff then
        return nil
    end

    -- Group with external coverage: fill whichever category is currently missing.
    if knowsBattle and not hasAPBuff then
        return S.BattleShout
    end

    if knowsCommanding and not hasStamBuff then
        return S.CommandingShout
    end

    return nil
end

function AC:WarriorHasActiveAPOrStamBuff()
    return not self:GetPreferredWarriorShout(self:GetPlayerSpec())
end

function AC:GetCurrentStance()
    local stance = GetShapeshiftForm()
    return stance or 0
end

-- FIXED: Stance functions with better error handling
function AC:ForceBattleStance()
    if not self:KnowsSpell(S.BattleStance) then return false end
    local currentStance = self:GetCurrentStance()
    if currentStance == 1 then return true end
    
    -- FIXED: Check cooldown before attempting
    if self:GetSpellCooldown(S.BattleStance) == 0 then
        WarriorDebug("Casting Battle Stance")
        CastSpellByName(S.BattleStance)
        return true
    end
    return false
end

function AC:ForceDefensiveStance()
    if not self:KnowsSpell(S.DefensiveStance) then return false end
    local currentStance = self:GetCurrentStance()
    if currentStance == 2 then return true end
    
    -- FIXED: Check cooldown before attempting
    if self:GetSpellCooldown(S.DefensiveStance) == 0 then
        WarriorDebug("Casting Defensive Stance")
        CastSpellByName(S.DefensiveStance)
        return true
    end
    return false
end

function AC:ForceBerserkerStance() 
    if not self:KnowsSpell(S.BerserkerStance) then return false end
    local currentStance = self:GetCurrentStance()
    if currentStance == 3 then return true end
    
    -- FIXED: Check cooldown before attempting
    if self:GetSpellCooldown(S.BerserkerStance) == 0 then
        WarriorDebug("Casting Berserker Stance")
        CastSpellByName(S.BerserkerStance)
        return true
    end
    return false
end

function AC:TryArmsInterrupt(unit)
    unit = unit or "target"

    if not UnitExists(unit) or not UnitCanAttack("player", unit) then
        return false
    end

    local spellName, _, _, _, _, endTime, _, _, uninterruptible = UnitCastingInfo(unit)
    if not spellName or uninterruptible then
        return false
    end

    if not self:ShouldInterruptSpell(spellName) then
        return false
    end

    local currentStance = self:GetCurrentStance()
    if currentStance == 3 then
        if self:TryInterrupt(S.Pummel, unit) then
            WarriorDebug("Arms: Pummel interrupt")
            return true
        end
    end

    return false
end

function AC:TryFuryInterrupt(unit)
    unit = unit or "target"

    if not UnitExists(unit) or not UnitCanAttack("player", unit) then
        return false
    end

    local spellName, _, _, _, _, endTime, _, _, uninterruptible = UnitCastingInfo(unit)
    if not spellName or uninterruptible then
        return false
    end

    if not self:ShouldInterruptSpell(spellName) then
        return false
    end

    local currentStance = self:GetCurrentStance()
    if currentStance == 3 then
        if self:TryInterrupt(S.Pummel, unit) then
            WarriorDebug("Fury: Pummel interrupt")
            return true
        end
        return false
    end

    local timeLeft = endTime and ((endTime / 1000) - GetTime()) or 0
    if timeLeft >= 2.0 and self:KnowsSpell(S.BerserkerStance) and self:GetSpellCooldown(S.BerserkerStance) == 0 then
        CastSpellByName(S.BerserkerStance)
        WarriorDebug("Fury: Switching to Berserker for Pummel on " .. spellName)
        return true
    end
    return false
end

-- FIXED: Enhanced talent checking with error handling
function AC:HasTalentByName(talentName, cacheKey)
    if not talentName then return false end

    self.warriorTalentCache = self.warriorTalentCache or {}
    local key = cacheKey or talentName
    local now = GetTime()
    local cached = self.warriorTalentCache[key]
    if cached and (now - cached.time) < 5 then
        return cached.value
    end

    local success, numTabs = pcall(GetNumTalentTabs)
    local found = false
    if success then
        for tab = 1, numTabs do
            local tabSuccess, numTalents = pcall(GetNumTalents, tab)
            if tabSuccess then
                for talent = 1, numTalents do
                    local talentSuccess, name, _, _, _, currRank = pcall(GetTalentInfo, tab, talent)
                    if talentSuccess and name and name:find(talentName) and currRank > 0 then
                        found = true
                        break
                    end
                end
                if found then break end
            end
        end
    end

    self.warriorTalentCache[key] = {
        time = now,
        value = found
    }
    return found
end

function AC:HasWarbringerTalent()
    return self:HasTalentByName("Warbringer", "Warbringer")
end

function AC:HasJuggernautTalent()
    return self:HasTalentByName("Juggernaut", "Juggernaut")
end

function AC:MarkWarriorChargeCast()
    self.lastWarriorChargeCastTime = GetTime()
end

-- Prevent mid-charge Thunder Clap by waiting for charge movement to settle.
function AC:ShouldDelayThunderClapAfterCharge()
    local lastCharge = self.lastWarriorChargeCastTime or 0
    if lastCharge <= 0 then
        return false
    end

    local elapsed = GetTime() - lastCharge
    if elapsed > 1.4 then
        return false
    end

    -- Always block briefly after Charge starts, regardless of movement-state reporting.
    if elapsed < 0.8 then
        return true
    end

    -- Keep delaying while still moving during the tail of the charge window.
    return self:IsPlayerMoving()
end

function AC:ShouldDelayProtectionThunderClapAfterCharge()
    local lastCharge = self.lastWarriorChargeCastTime or 0
    if lastCharge <= 0 then
        return false
    end

    local elapsed = GetTime() - lastCharge
    if elapsed > 1.0 then
        return false
    end

    return self:IsPlayerMoving()
end

-- FIXED: Enhanced charge with better checks
function AC:TryCharge()
    local hasWarbringer = self:HasWarbringerTalent()
    if not self:KnowsSpell(S.Charge) then return false end
    if UnitAffectingCombat("player") and not hasWarbringer then return false end
    if not UnitExists("target") or not UnitCanAttack("player", "target") or UnitIsDeadOrGhost("target") then return false end
    local currentStance = self:GetCurrentStance()

    -- Non-Warbringer warriors must be in Battle Stance before Charge range checks are reliable.
    if not hasWarbringer and currentStance ~= 1 then
        if self:ForceBattleStance() then
            WarriorDebug("Charge setup: switching to Battle Stance")
            return true
        end
        return false
    end

    local chargeRange = IsSpellInRange(S.Charge, "target")
    if chargeRange ~= 1 then
        -- Only run melee heuristic when Charge itself is not in range.
        if self:IsInMeleeRange("target") then
            if Throttle("ChargeBlockedMelee", 2.0) then
                WarriorDebug("Charge blocked: already in melee range")
            end
            return false
        end
        if Throttle("ChargeBlockedRange", 2.0) then
            WarriorDebug("Charge blocked: out of range/LOS/min-range")
        end
        return false
    end

    if self:GetSpellCooldown(S.Charge) > 0 then
        if Throttle("ChargeBlockedCD", 2.0) then
            WarriorDebug("Charge blocked: on cooldown")
        end
        return false
    end
    
    if hasWarbringer then
        if self:IsUsableSpell(S.Charge) then
            CastSpellByName(S.Charge)
            self:MarkWarriorChargeCast()
            WarriorDebug("Attempting to Charge target (Warbringer)")
            return true
        end
    else
        if self:IsUsableSpell(S.Charge) then
            CastSpellByName(S.Charge)
            self:MarkWarriorChargeCast()
            WarriorDebug("Attempting to Charge target")
            return true
        end
    end
    return false
end

function AC:TryProtectionWarbringerCharge(target)
    target = target or "target"
    if self:GetPlayerSpec() ~= "Protection" then return false end
    if not self:HasWarbringerTalent() or not self:KnowsSpell(S.Charge) then return false end
    if not UnitExists(target) or not UnitCanAttack("player", target) or UnitIsDeadOrGhost(target) then return false end
    if self:IsInMeleeRange(target, true) then return false end
    if self:GetSpellCooldown(S.Charge) > 0 or not self:IsUsableSpell(S.Charge) then return false end
    if not self:IsInChargeRange(target) then return false end

    CastSpellByName(S.Charge, target)
    self:MarkWarriorChargeCast()
    self:MarkAsOurTarget(UnitGUID(target))
    WarriorDebug("Prot: Warbringer Charge")
    return true
end

function AC:TryProtectionInterveneGapCloser(target)
    target = target or "target"
    if self:GetPlayerSpec() ~= "Protection" then return false end
    if GetGroupSize() > 5 then return false end
    if not UnitAffectingCombat("player") then return false end
    if not UnitExists(target) or not UnitCanAttack("player", target) or UnitIsDeadOrGhost(target) then return false end
    if self:IsInMeleeRange(target, true) then return false end

    local interveneTarget = self:FindWarriorInterveneTarget(target)
    if not interveneTarget then
        if Throttle("ProtInterveneNoTarget", 2.0) then
            WarriorDebug("Prot: Intervene unavailable - no valid ally path")
        end
        return false
    end

    if self:UseRangedAbilityAndReturn("Intervene", interveneTarget) then
        WarriorDebug("Prot: Intervene gap closer via " .. (UnitName(interveneTarget) or "Unknown"))
        return true
    end

    if Throttle("ProtInterveneFailed", 2.0) then
        WarriorDebug("Prot: Intervene path found but cast failed on " .. (UnitName(interveneTarget) or interveneTarget))
    end

    return false
end

-- Arms Juggernaut combat charge (WotLK: in-combat Charge while in Battle Stance).
function AC:TryArmsCombatCharge(target)
    target = target or "target"
    if not UnitAffectingCombat("player") then return false end
    if not self:KnowsSpell(S.Charge) or not self:HasJuggernautTalent() then return false end
    if not UnitExists(target) or not UnitCanAttack("player", target) or UnitIsDeadOrGhost(target) then return false end
    if self:GetCurrentStance() ~= 1 then return false end
    if self:GetSpellCooldown(S.Charge) > 0 then return false end
    if not self:IsUsableSpell(S.Charge) then return false end
    if not self:IsInChargeRange(target) then return false end

    CastSpellByName(S.Charge, target)
    self:MarkWarriorChargeCast()
    self:MarkAsOurTarget(UnitGUID(target))
    WarriorDebug("Arms: Juggernaut Charge gap-closer")
    return true
end

function AC:ShouldMaintainArmsSunder(unit)
    unit = unit or "target"
    if not UnitExists(unit) or not UnitCanAttack("player", unit) or UnitIsDeadOrGhost(unit) then
        return false
    end
    if UnitPlayerControlled(unit) then
        return false
    end
    if not IsInGroup() then
        return false
    end

    -- Keep Sunder as a PvE utility on durable high-value targets only.
    local classification = UnitClassification(unit)
    local highValuePvETarget = classification == "elite" or classification == "rareelite" or classification == "worldboss"
    if not highValuePvETarget then
        return false
    end
    if self:GetEnemyCount() >= 2 then
        return false
    end
    if self:GetTargetHealthPercent(unit) < 60 then
        return false
    end

    if not self:KnowsSpell(S.SunderArmor) or not self:IsUsableSpell(S.SunderArmor) then
        return false
    end
    if self:GetSpellCooldown(S.SunderArmor) > 0 then
        return false
    end

    -- Expose Armor shares the same armor-debuff slot. Don't fight it.
    if self:HasDebuff(unit, "Expose Armor") then
        return false
    end

    local hasSunder, sunderCount = self:HasDebuff(unit, S.SunderArmor)
    if not hasSunder then
        return true
    end

    local stacks = sunderCount or 0
    if stacks < 5 then
        return true
    end

    return self:DebuffTimeRemaining(unit, S.SunderArmor) < 4
end

-- Solo-only burst overlay for faster open-world kill speed.
-- Kept separate from main proc priority so raid/group rotation is unaffected.
function AC:TryArmsSoloBurst(rage, nearbyEnemies, targetHP, msCooldown, overpowerReady, overpowerExpiring, suddenDeathProc, rendRemaining)
    if IsInGroup() then
        return false
    end
    if not UnitExists("target") or not UnitCanAttack("player", "target") or UnitIsDeadOrGhost("target") then
        return false
    end
    if self:GetPlayerHealthPercent() < 45 or targetHP < 25 then
        return false
    end

    local classification = UnitClassification("target") or "normal"
    if classification == "trivial" or classification == "minus" then
        return false
    end

    -- Never steal globals from urgent proc windows.
    if overpowerExpiring or suddenDeathProc then
        return false
    end

    local highValueSoloTarget = classification == "rare" or classification == "elite" or
                                classification == "rareelite" or classification == "worldboss" or
                                nearbyEnemies >= 2

    local freshTarget = targetHP >= 60
    if freshTarget and Throttle("ArmsSoloBurstTools", 20.0) then
        if self:UseTrinketsFixed() then
            WarriorDebug("Arms Solo Burst: Trinkets")
        end
        if self:UseRacialsWarrior(true, false) then
            WarriorDebug("Arms Solo Burst: Offensive racial")
        end
    end

    -- Death Wish first when available, but avoid clipping immediate core buttons.
    if highValueSoloTarget and freshTarget and self:KnowsSpell(S.DeathWish) and self:IsUsableSpell(S.DeathWish) and
       self:GetSpellCooldown(S.DeathWish) == 0 and not overpowerReady and msCooldown > 0.5 and
       Throttle("ArmsSoloDeathWish", 45) then
        CastSpellByName(S.DeathWish)
        WarriorDebug("Arms Solo Burst: Death Wish")
        return true
    end

    -- Solo bladestorming for faster quest-pack deletes, guarded behind core-proc checks.
    if highValueSoloTarget and self:KnowsSpell(S.Bladestorm) and self:IsUsableSpell(S.Bladestorm) and
       self:GetSpellCooldown(S.Bladestorm) == 0 and rage >= 25 and not overpowerReady and
       msCooldown > 1.0 and rendRemaining > 2 and Throttle("ArmsSoloBladestorm", 30) then
        CastSpellByName(S.Bladestorm)
        WarriorDebug("Arms Solo Burst: Bladestorm")
        return true
    end

    return false
end

-- FIXED: Enhanced demo shout logic with better conditions
function AC:ShouldUseDemoShout(enemies)
    if enemies < 1 then return false end
    
    local rage = UnitPower("player", 1)
    local spec = self:GetPlayerSpec()
    local minRage = (spec == "Protection") and 10 or 30
    if rage < minRage then return false end
    
    -- FIXED: Check if demo shout is already active
    if self:HasDebuff("target", S.DemoShout) then
        local timeLeft = self:DebuffTimeRemaining("target", S.DemoShout)
        if timeLeft > 2 then
            return false
        end
    end
    
    local targetClassification = UnitClassification("target")
    if spec == "Protection" then
        local targetIsDangerous = targetClassification == "elite" or targetClassification == "rare" or
                                  targetClassification == "rareelite" or targetClassification == "worldboss"
        local activelyTanking = UnitExists("targettarget") and UnitIsUnit("targettarget", "player")
        local targetInCombat = UnitExists("target") and UnitAffectingCombat("target")
        if not targetInCombat or (not activelyTanking and not targetIsDangerous and enemies < 2) then
            return false
        end
    else
        if not IsInGroup() and targetClassification ~= "elite" and targetClassification ~= "rareelite" and 
           targetClassification ~= "worldboss" then
            return false
        end
    end
    
    return true
end

function AC:ShouldMaintainProtectionThunderClap()
    if not self:KnowsSpell(S.ThunderClap) or not self:IsUsableSpell(S.ThunderClap) then return false end
    if self:GetSpellCooldown(S.ThunderClap) > 0 then return false end
    if UnitPower("player", 1) < 20 then return false end
    if not UnitExists("target") or not UnitCanAttack("player", "target") or UnitIsDeadOrGhost("target") then return false end
    if not UnitAffectingCombat("target") then return false end
    if not self:IsInMeleeRange("target", true) then return false end
    if not self:ThunderClapInRange() or not self:HasEnemyInThunderClapReach(20) then return false end

    local classification = UnitClassification("target")
    local targetIsDangerous = classification == "elite" or classification == "rare" or
                              classification == "rareelite" or classification == "worldboss"
    local activelyTanking = UnitExists("targettarget") and UnitIsUnit("targettarget", "player")
    local hasMultipleTargets = self:GetEnemiesInThunderClapReach(20) >= 2

    -- Avoid random Thunder Clap on incidental combat targets; only maintain it on real tank targets.
    if not activelyTanking and not targetIsDangerous and not hasMultipleTargets then
        return false
    end

    if self:HasDebuff("target", S.ThunderClap) and self:DebuffTimeRemaining("target", S.ThunderClap) > 3 then
        return false
    end

    return true
end

function AC:TryProtectionShockwave(nearbyEnemies, inMeleeRange, targetInCombat)
    nearbyEnemies = nearbyEnemies or 0
    if not self:KnowsSpell(S.Shockwave) or not self:IsUsableSpell(S.Shockwave) then return false end
    if self:GetSpellCooldown(S.Shockwave) > 0 or UnitPower("player", 1) < 15 then return false end
    if not UnitExists("target") or not UnitCanAttack("player", "target") or UnitIsDeadOrGhost("target") then return false end
    if not targetInCombat or not inMeleeRange then return false end
    if not self:IsInMeleeRange("target", true) then return false end

    local now = GetTime()
    if not self.lastMovementTime then
        self.lastMovementTime = now
    end

    if self:IsPlayerMoving() then
        self.lastMovementTime = now
        WarriorDebug("Prot: Shockwave blocked - moving")
        return false
    end

    local classification = UnitClassification("target")
    local targetIsDangerous = classification == "elite" or classification == "rare" or
                              classification == "rareelite" or classification == "worldboss"
    local activelyTanking = UnitExists("targettarget") and UnitIsUnit("targettarget", "player")
    local stationaryTime = now - self.lastMovementTime

    if nearbyEnemies >= 2 then
        if stationaryTime < 1.0 and nearbyEnemies < 4 then
            WarriorDebug("Prot: Positioning mobs (" .. string.format("%.1f", stationaryTime) .. "s, need 1.0s)")
            return false
        end
    elseif not activelyTanking and not targetIsDangerous then
        return false
    elseif stationaryTime < 0.5 then
        return false
    end

    CastSpellByName(S.Shockwave, "target")
    self:MarkAsOurTarget(UnitGUID("target"))
    WarriorDebug("Prot: Shockwave" .. (nearbyEnemies >= 2 and " (AoE)" or " (single target)"))
    return true
end

function AC:ManageWarriorVigilance()
    if self:GetPlayerSpec() ~= "Protection" or not self:KnowsSpell(S.Vigilance) then return false end
    if not IsInGroup() then return false end
    if not Throttle("WarriorVigilance", 8) then return false end
    if self:GetSpellCooldown(S.Vigilance) > 0 or not self:IsUsableSpell(S.Vigilance) then return false end

    self.warriorVigilance = self.warriorVigilance or {}
    local now = GetTime()
    local inRaid = GetNumRaidMembers() > 0

    local function isValidVigilanceUnit(unit)
        return UnitExists(unit) and not UnitIsDeadOrGhost(unit) and UnitIsFriend("player", unit) and
            not UnitIsUnit(unit, "player")
    end

    local function isVigilanceInRange(unit)
        local ok, range = pcall(IsSpellInRange, S.Vigilance, unit)
        return (not ok) or range == nil or range == 1
    end

    local function getGroupUnits()
        local units = {}
        if inRaid then
            for i = 1, GetNumRaidMembers() do
                units[#units + 1] = "raid" .. i
            end
        else
            for i = 1, GetNumPartyMembers() do
                units[#units + 1] = "party" .. i
            end
        end
        return units
    end

    local groupUnits = getGroupUnits()
    if #groupUnits == 0 then return false end

    local function isEligibleRaidTank(unit)
        return inRaid and isValidVigilanceUnit(unit) and self:IsTank(unit)
    end

    local function isPreferredVigilanceTarget(unit)
        if not isValidVigilanceUnit(unit) then return false end
        if not inRaid then return true end
        return isEligibleRaidTank(unit)
    end

    local function findUnitByGUID(guid)
        if not guid then return nil end
        for _, unit in ipairs(groupUnits) do
            if isPreferredVigilanceTarget(unit) and UnitGUID(unit) == guid then
                return unit
            end
        end
        return nil
    end

    -- If Vigilance is already visible on a valid group member, lock to that target.
    for _, unit in ipairs(groupUnits) do
        if isPreferredVigilanceTarget(unit) and self:HasBuff(unit, S.Vigilance) then
            self.warriorVigilance.guid = UnitGUID(unit)
            self.warriorVigilance.name = UnitName(unit)
            self.warriorVigilance.lastSeen = now
            return false
        end
    end

    -- Maintain the selected target instead of cycling through every unbuffed member.
    local trackedUnit = findUnitByGUID(self.warriorVigilance.guid)
    if trackedUnit then
        if (now - (self.warriorVigilance.lastCast or 0)) < 45 then
            return false
        end

        if isVigilanceInRange(trackedUnit) then
            CastSpellByName(S.Vigilance, trackedUnit)
            self.warriorVigilance.lastCast = now
            self.warriorVigilance.name = UnitName(trackedUnit)
            WarriorDebug("Prot: Refreshing Vigilance on " .. (UnitName(trackedUnit) or trackedUnit))
            return true
        end

        return false
    end

    local bestUnit = nil
    if inRaid then
        local raidTankUnits = {}
        for _, unit in ipairs(groupUnits) do
            if isEligibleRaidTank(unit) and isVigilanceInRange(unit) then
                raidTankUnits[#raidTankUnits + 1] = unit
            end
        end
        if #raidTankUnits == 1 then
            bestUnit = raidTankUnits[1]
        elseif #raidTankUnits > 1 then
            bestUnit = raidTankUnits[math.random(#raidTankUnits)]
        end
    else
        local bestScore = -1
        for _, unit in ipairs(groupUnits) do
            if isValidVigilanceUnit(unit) and isVigilanceInRange(unit) then
                local score = 10
                if not self:IsTankSpec(unit) then score = score + 30 end
                if UnitAffectingCombat(unit) then score = score + 10 end
                if UnitExists(unit .. "target") and UnitCanAttack("player", unit .. "target") then score = score + 10 end

                if score > bestScore then
                    bestScore = score
                    bestUnit = unit
                end
            end
        end
    end

    if bestUnit then
        CastSpellByName(S.Vigilance, bestUnit)
        self.warriorVigilance.guid = UnitGUID(bestUnit)
        self.warriorVigilance.name = UnitName(bestUnit)
        self.warriorVigilance.lastCast = now
        WarriorDebug("Prot: Vigilance on " .. (UnitName(bestUnit) or bestUnit))
        return true
    end

    return false
end

-- FIXED: Enhanced buff management with performance optimization
function AC:CheckWarriorBuffs(spec)
    local applied = false
    local level = UnitLevel("player")
    local rage = UnitPower("player", 1)
    local currentStance = self:GetCurrentStance()
    
    if not Throttle("WarriorOOCBuff", 5) then return false end
    if UnitAffectingCombat("player") then return false end

    -- Shouts
    local shoutToUse = self:GetPreferredWarriorShout(spec)
    if shoutToUse and Throttle("WarriorOOCShoutCast", 12) then
        if self:IsUsableSpell(shoutToUse) and rage >= 10 then
            CastSpellByName(shoutToUse)
            WarriorDebug("OOC Buff: " .. shoutToUse)
            applied = true
        end
    end
    
    -- FIXED: Stance management with cooldown checks
    local stanceActionTaken = false 
    local desiredStanceSpell = S.BattleStance
    local desiredStanceNum = 1
    
    if spec == "Protection" and level >= 10 then
        desiredStanceSpell = S.DefensiveStance
        desiredStanceNum = 2
    elseif spec == "Fury" and level >= 30 then
        desiredStanceSpell = S.BerserkerStance
        desiredStanceNum = 3
    end

    if currentStance ~= desiredStanceNum and self:KnowsSpell(desiredStanceSpell) then
        if self:GetSpellCooldown(desiredStanceSpell) == 0 then 
            CastSpellByName(desiredStanceSpell)
            WarriorDebug("OOC Stance: " .. desiredStanceSpell)
            stanceActionTaken = true
        end
    end

    if spec == "Protection" and self:ManageWarriorVigilance() then
        applied = true
    end
    
    return applied or stanceActionTaken 
end

-- =============================================
-- ENHANCED WARRIOR ROTATIONS WITH SMART TARGETING
-- =============================================

-- FIXED: Protection rotation with smart targeting integration and freeze prevention
function AC:ProtectionWarriorRotation()
    local rage = UnitPower("player", 1)
    local level = UnitLevel("player")
    local enemies = self:GetEnemyCount()
    local health = self:GetPlayerHealthPercent()
    local currentStance = self:GetCurrentStance()
    local inCombat = UnitAffectingCombat("player")
    local hasTarget = UnitExists("target") and UnitCanAttack("player", "target") and not UnitIsDeadOrGhost("target")
    local groupSize = self:GetGroupSize()
    local largeGroupMode = groupSize > 5

    if Throttle("ProtDebug", 3.0) then
        WarriorDebug(string.format("Prot L:%d S:%d R:%d HP:%.0f E:%d T:%s", 
                     level, currentStance, rage, health, enemies, hasTarget and "Y" or "N"))
        if largeGroupMode then
            WarriorDebug("Prot: Large-group mode - auto taunt/switch disabled")
        end
    end
    
    -- Auto-attack
    if hasTarget then StartAttack() end

    if inCombat then
        if not largeGroupMode and self:HandleTankTargeting() then return true end
        hasTarget = UnitExists("target") and UnitCanAttack("player", "target") and not UnitIsDeadOrGhost("target")
        if not hasTarget then return true end
    end

    -- Protection prefers Intervene in combat as the primary gap closer.
    if inCombat and not largeGroupMode and hasTarget and level >= 70 and self:TryProtectionInterveneGapCloser("target") then
        return true
    end

    -- Warbringer Charge is the fallback when Intervene is unavailable or on cooldown.
    if hasTarget and level >= 4 and self:TryProtectionWarbringerCharge("target") then
        return true
    end

    if inCombat and not largeGroupMode and hasTarget and not self:IsInMeleeRange("target", true) then
        local currentGUID = UnitGUID("target")
        local meleeTarget = self.FindBestTankTarget and self:FindBestTankTarget(true, true, currentGUID)
        if meleeTarget and UnitExists(meleeTarget) and not UnitIsUnit(meleeTarget, "target") then
            TargetUnit(meleeTarget)
            if not IsCurrentSpell("Attack") then
                StartAttack()
            end
            self.lastTargetSwitch = GetTime()
            self:MarkAsOurTarget(UnitGUID("target"))
            WarriorDebug("Prot: Returned to melee target after failed gap close")
            return true
        end
    end
    
    -- Out of combat charge
    if not inCombat and hasTarget and level >= 4 then
        if self:TryCharge() then return true end
    end
    
    -- Stance management
    if level >= 10 and currentStance ~= 2 then
        if self:ForceDefensiveStance() then return true end 
    elseif level < 10 and currentStance ~= 1 then
        if self:ForceBattleStance() then return true end
    end
    
    if (level >= 10 and currentStance ~= 2) or (level < 10 and currentStance ~= 1) then
        WarriorDebug("Prot: Waiting for stance")
        return true
    end

    if inCombat then
        -- FIXED: Use defensive cooldowns when needed
        if self:UseWarriorDefensives() then return true end
        
        -- ENHANCED: Proactive Spell Reflection (interrupt priority system)
        if self:UseEnhancedSpellReflection() then return true end
        
        -- Rage generation with Blood Rage
        if rage < 25 and self:IsUsableSpell(S.BloodRage) and self:GetSpellCooldown(S.BloodRage) == 0 then
            CastSpellByName(S.BloodRage)
            WarriorDebug("Prot: Blood Rage")
            rage = UnitPower("player", 1)
        end
        
        -- Use Berserker Rage for fear/charm breaks or controlled rage generation.
        -- Keep this constrained so it doesn't preempt core threat buttons on normal pulls.
        local needsEnrageSetup = health < 35 and self:KnowsSpell(S.EnragedRegeneration) and self:GetSpellCooldown(S.EnragedRegeneration) == 0
        local needsFearBreak = UnitIsFeared("player") or UnitIsCharmed("player")
        if self:IsUsableSpell(S.BerserkerRage) and self:GetSpellCooldown(S.BerserkerRage) == 0 and
           (needsFearBreak or (rage < 30 and not self:HasBuff("player", S.BloodRage)) or needsEnrageSetup) then
            CastSpellByName(S.BerserkerRage)
            WarriorDebug("Prot: Berserker Rage (offensive enrage)")
            if needsFearBreak then
                return true
            end
        end
        
        -- Enhanced interrupt system - prioritize Shield Bash, fallback to Pummel
        if UnitCastingInfo("target") then
            -- Shield Bash first (Protection preferred, silences for 6 seconds)
            if self:IsUsableSpell(S.ShieldBash) and self:GetSpellCooldown(S.ShieldBash) == 0 then
                CastSpellByName(S.ShieldBash, "target")
                WarriorDebug("Prot: Shield Bash interrupt")
                return true
            -- Pummel fallback (Berserker Stance, shorter cooldown)
            elseif self:IsUsableSpell(S.Pummel) and self:GetSpellCooldown(S.Pummel) == 0 then
                -- Switch to Berserker Stance for Pummel if needed
                local currentStance = self:GetCurrentStance()
                if currentStance ~= 3 and self:KnowsSpell(S.BerserkerStance) and self:GetSpellCooldown(S.BerserkerStance) == 0 then
                    CastSpellByName(S.BerserkerStance)
                    WarriorDebug("Prot: Switching to Berserker for Pummel")
                    return true
                elseif currentStance == 3 then
                    CastSpellByName(S.Pummel, "target")
                    WarriorDebug("Prot: Pummel interrupt")
                    -- Switch back to Defensive Stance after interrupt
                    if self:KnowsSpell(S.DefensiveStance) and self:GetSpellCooldown(S.DefensiveStance) == 0 then
                        CastSpellByName(S.DefensiveStance)
                        WarriorDebug("Prot: Back to Defensive Stance")
                    end
                    return true
                end
            end
        end
        
        -- Victory Rush for free healing
        if self:TryVictoryRush() then return true end
        
        -- Shouts
        local combatShout = self:GetPreferredWarriorShout("Protection")
        if combatShout and Throttle("ProtCombatShout", 10) then 
            if self:IsUsableSpell(combatShout) and rage >= 10 then 
                CastSpellByName(combatShout)
                WarriorDebug("Prot: " .. combatShout)
                return true 
            end
        end

        -- *** HIGH PRIORITY AoE ABILITIES (only if we have melee targets) ***
        -- INTEGRATION: Use enhanced enemy location detection for better AoE decisions
        local nearbyEnemies = self:GetEnemiesInThunderClapReach(20)
        local inMeleeRange = self:IsInMeleeRange("target", true)
        local targetInCombat = UnitExists("target") and UnitAffectingCombat("target")
        if Throttle("ProtAOEDebug", 3.0) then
            WarriorDebug("AoE Check: nearbyEnemies=" .. nearbyEnemies .. " inMelee=" .. (inMeleeRange and "Y" or "N"))
        end
        if nearbyEnemies >= 2 and inMeleeRange then
            -- Thunder Clap FIRST (highest priority for initial AoE threat)
            -- FIXED: Only use Thunderclap when in proper melee range, not just when enemies are detectable
            local canUseTC = self:IsUsableSpell(S.ThunderClap)
            local hasRage = rage >= 20
            local notThrottled = Throttle("ProtTCAoE", 0.5)
            local inRange = self:ThunderClapInRange()
            local hasTCReach = self:HasEnemyInThunderClapReach(20)
            local notOnCD = self:GetSpellCooldown(S.ThunderClap) == 0
            local delayForCharge = self:ShouldDelayProtectionThunderClapAfterCharge()
            
            if canUseTC and hasRage and notThrottled and inRange and hasTCReach and notOnCD and not delayForCharge and targetInCombat then 
                CastSpellByName(S.ThunderClap)
                self:MarkAsOurTarget(UnitGUID("target"))
                WarriorDebug("Prot: Thunder Clap (AoE threat priority)")
                return true
            elseif nearbyEnemies >= 2 and Throttle("ProtTCBlockedDebug", 3.0) then
                -- DETAILED DEBUG: Find out exactly why Thunder Clap is blocked
                local spellExists = GetSpellInfo(S.ThunderClap) ~= nil
                local spellKnown = self:KnowsSpell(S.ThunderClap)
                local cooldownTime = self:GetSpellCooldown(S.ThunderClap)
                WarriorDebug("TC blocked: usable=" .. (canUseTC and "Y" or "N") .. " rage=" .. (hasRage and "Y" or "N") .. 
                           " throttle=" .. (notThrottled and "Y" or "N") .. " range=" .. (inRange and "Y" or "N") ..
                           " reach=" .. (hasTCReach and "Y" or "N") ..
                           " cd=" .. (notOnCD and "Y" or "N") .. " chargeDelay=" .. (delayForCharge and "Y" or "N") .. 
                           " tgtCombat=" .. (targetInCombat and "Y" or "N") ..
                           " exists=" .. (spellExists and "Y" or "N") .. 
                           " known=" .. (spellKnown and "Y" or "N") .. " cdTime=" .. string.format("%.1f", cooldownTime))
            end
            
            -- Shockwave SECOND, but only when positioned and the current target is actually hittable.
            if self:TryProtectionShockwave(nearbyEnemies, inMeleeRange, targetInCombat) then return true end
        end

        local targetHP = self:GetTargetHealthPercent("target")

        -- Shield Block boosts Shield Slam damage/threat; don't let it consume the rotation tick.
        if self:IsUsableSpell(S.ShieldBlock) and rage >= 10 and self:IsUsableSpell(S.ShieldSlam) and
           self:GetSpellCooldown(S.ShieldBlock) == 0 and self:GetSpellCooldown(S.ShieldSlam) == 0 and
           Throttle("ShieldBlockProt", 5) then 
            CastSpellByName(S.ShieldBlock)
            WarriorDebug("Prot: Shield Block")
        end
        
        -- Shield Slam (high threat) - Mark target as ours
        if self:IsUsableSpell(S.ShieldSlam) and rage >= 20 then
            if self:CastSpell(S.ShieldSlam, "target") then
                self:MarkAsOurTarget(UnitGUID("target"))
                WarriorDebug("Prot: Shield Slam")
                return true
            end
        end
        
        -- Revenge (high threat, low cost) - Mark target as ours
        if self:IsUsableSpell(S.Revenge) and rage >= 5 then 
            if self:CastSpell(S.Revenge, "target") then
                self:MarkAsOurTarget(UnitGUID("target"))
                WarriorDebug("Prot: Revenge")
                return true
            end
        end

        -- Maintain the Thunder Clap attack-speed debuff on real tank targets, not random combat units.
        if nearbyEnemies < 2 and Throttle("ProtTCSingle", 0.5) and self:ShouldMaintainProtectionThunderClap() then
            CastSpellByName(S.ThunderClap)
            self:MarkAsOurTarget(UnitGUID("target"))
            WarriorDebug("Prot: Thunder Clap (single-target debuff)")
            return true
        end

        local tcReadyAndInRange = nearbyEnemies >= 2 and inMeleeRange and self:IsUsableSpell(S.ThunderClap) and rage >= 20 and
                                  self:ThunderClapInRange() and self:HasEnemyInThunderClapReach(20) and
                                  self:GetSpellCooldown(S.ThunderClap) == 0
        if not tcReadyAndInRange and self:ShouldUseDemoShout(nearbyEnemies) and self:IsUsableSpell(S.DemoShout) and
           self:GetSpellCooldown(S.DemoShout) == 0 and rage >= 10 and Throttle("DemoShoutProt", 4) then
            CastSpellByName(S.DemoShout)
            self:MarkAsOurTarget(UnitGUID("target"))
            WarriorDebug("Prot: Demo Shout")
            return true
        end

        -- Single-target Prot filler before Devastate, but only on a target we can actually hit.
        if nearbyEnemies < 2 and self:TryProtectionShockwave(nearbyEnemies, inMeleeRange, targetInCombat) then
            return true
        end

        if self:KnowsSpell(S.ConcussionBlow) and self:IsUsableSpell(S.ConcussionBlow) and
           self:GetSpellCooldown(S.ConcussionBlow) == 0 and rage >= 15 and targetInCombat and inMeleeRange then
            if self:CastSpell(S.ConcussionBlow, "target") then
                self:MarkAsOurTarget(UnitGUID("target"))
                WarriorDebug("Prot: Concussion Blow")
                return true
            end
        end
        
        -- Devastate/Sunder - Mark target as ours
        if self:KnowsSpell(S.Devastate) and self:IsUsableSpell(S.Devastate) and rage >= 15 then
            if self:CastSpell(S.Devastate, "target") then
                self:MarkAsOurTarget(UnitGUID("target"))
                WarriorDebug("Prot: Devastate")
                return true
            end
        elseif self:IsUsableSpell(S.SunderArmor) and rage >= 15 then 
            local _, _, _, sunderCount = UnitDebuff("target", S.SunderArmor)
            if ((sunderCount or 0) < 5 or self:DebuffTimeRemaining("target", S.SunderArmor) < 5) then
                if self:CastSpell(S.SunderArmor, "target") then
                    self:MarkAsOurTarget(UnitGUID("target"))
                    WarriorDebug("Prot: Sunder")
                    return true
                end
            end
        end

        -- Execute is a Protection rage dump, not a replacement for core threat buttons.
        if targetHP < 20 and self:IsUsableSpell(S.Execute) and rage >= 50 and
           self:GetSpellCooldown(S.ShieldSlam) > 1.5 and self:GetSpellCooldown(S.ThunderClap) > 1.5 then 
            CastSpellByName(S.Execute, "target")
            WarriorDebug("Prot: Execute")
            return true
        end
        
        -- Rend (only at low levels)
        if level < 20 and self:IsUsableSpell(S.Rend) and rage >= 10 and not self:HasDebuff("target", S.Rend) then
            CastSpellByName(S.Rend, "target")
            WarriorDebug("Prot: Rend")
            return true
        end
        
        -- Heroic Strike/Cleave rage dump (queued on next swing to avoid spam/starving core buttons)
        local shouldDumpProt = (rage >= 80) or ShouldQueueRageDump(
            rage,
            {self:GetSpellCooldown(S.ShieldSlam), self:GetSpellCooldown(S.ThunderClap)},
            50
        )
        if shouldDumpProt then
            if nearbyEnemies >= 2 and QueueOnNextSwing(S.Cleave, "Prot: Cleave dump") then
                return true
            elseif QueueOnNextSwing(S.HeroicStrike, "Prot: Heroic Strike dump") then
                return true
            end
        end
    end
    return false
end

-- FIXED: Arms rotation with better DPS and melee prioritization
function AC:ArmsWarriorRotation()
    local rage = UnitPower("player", 1)
    local level = UnitLevel("player")
    local enemies = self:GetEnemyCount()
    local health = self:GetPlayerHealthPercent()
    local currentStance = self:GetCurrentStance()
    local inCombat = UnitAffectingCombat("player")
    local hasTarget = UnitExists("target") and UnitCanAttack("player", "target") and not UnitIsDeadOrGhost("target")

    if Throttle("ArmsDebug", 1.0) then
        WarriorDebug(string.format("Arms L:%d S:%d R:%d HP:%.0f E:%d T:%s", 
                     level, currentStance, rage, health, enemies, hasTarget and "Y" or "N"))
    end
    
    if hasTarget then StartAttack() end
    if not inCombat and hasTarget and level >= 4 then
        if self:TryCharge() then return true end
    end

    -- Stance management
    if currentStance ~= 1 then
        if self:ForceBattleStance() then return true end
    end
    if currentStance ~= 1 then
        WarriorDebug("Arms: Waiting for Battle Stance")
        return true
    end 

    if inCombat then
        -- Find target if needed - prefer melee targets
        if not hasTarget then
            local meleeTarget = self:FindMeleeTarget()
            if meleeTarget then
                TargetUnit(meleeTarget)
                hasTarget = true
                WarriorDebug("Arms: Found melee target")
            else
                local bestTarget = self:FindBestWarriorTarget()
                if bestTarget then
                    TargetUnit(bestTarget)
                    hasTarget = true
                    WarriorDebug("Arms: Found ranged target")
                end
            end
        end
        if not hasTarget then return true end

        -- Only use melee abilities in range; try a safe gap-closer first to reduce idle time.
        if not self:IsInMeleeRange("target") then
            -- Re-check with interact distance to avoid false negatives on large hitboxes.
            local touchContact = CheckInteractDistance("target", 3)
            if touchContact then
                WarriorDebug("Arms: Melee contact fallback confirmed")
            else
            -- Juggernaut: in-combat Charge for Arms while staying leveling-safe.
            if level >= 50 and self:TryArmsCombatCharge("target") then
                return true
            end
            if level >= 30 then
                local hasWarbringer = self:HasWarbringerTalent()
                if hasWarbringer or currentStance == 3 then
                    local availableRanged = self:GetAvailableRangedAbilities()
                    if availableRanged.intercept and self:UseRangedAbilityAndReturn("Intercept", "target") then
                        WarriorDebug("Arms: Intercept gap closer" .. (hasWarbringer and " (Warbringer)" or ""))
                        return true
                    end
                end
            end
            local availableRanged = self:GetAvailableRangedAbilities()
            if availableRanged.heroicThrow and self:UseRangedAbilityAndReturn("Heroic Throw", "target") then
                WarriorDebug("Arms: Heroic Throw while out of melee")
                return true
            end
            WarriorDebug("Arms: Target out of melee range, no gap closers available")
            return false
            end
        end

        -- Arms interrupt handling: only Pummel when already in Berserker Stance.
        if self:TryArmsInterrupt("target") then return true end

        -- FIXED: Use defensive cooldowns when needed
        if self:UseWarriorDefensives() then return true end
        
        -- ENHANCED: Proactive Spell Reflection (interrupt priority system)
        if self:UseEnhancedSpellReflection() then return true end
        
        -- Rage generation
        if rage < 25 and self:IsUsableSpell(S.BloodRage) and self:GetSpellCooldown(S.BloodRage) == 0 then
            CastSpellByName(S.BloodRage)
            WarriorDebug("Arms: Blood Rage")
            rage = UnitPower("player", 1)
        end
        
        -- Berserker Rage for fear/charm or rage
        local needsFearBreak = UnitIsFeared("player") or UnitIsCharmed("player")
        if (needsFearBreak or (rage < 30 and GetSpellCooldown(S.BerserkerRage) == 0)) and 
           self:IsUsableSpell(S.BerserkerRage) and self:GetSpellCooldown(S.BerserkerRage) == 0 then 
            CastSpellByName(S.BerserkerRage)
            WarriorDebug("Arms: Berserker Rage")
            if needsFearBreak then
                return true
            end
        end
        
        -- ENHANCED: Use racial abilities for combat effectiveness
        local isEliteOrGroup = UnitClassification("target") == "elite" or IsInGroup()
        if isEliteOrGroup and Throttle("ArmsRacials", 15.0) then
            if self:UseRacialsWarrior(true, false) then
                WarriorDebug("Arms: Used offensive racial")
            end
        end
        
        -- Victory Rush
        if self:TryVictoryRush() then return true end

        local combatShout = self:GetPreferredWarriorShout("Arms")
        if combatShout and rage >= 10 and Throttle("ArmsCombatShout", 10) and self:IsUsableSpell(combatShout) then
            CastSpellByName(combatShout)
            WarriorDebug("Arms: " .. combatShout)
            return true
        end
        
        -- Retaliation/Disarm are utility tools and are intentionally not used in DPS flow.

        local targetHP = self:GetTargetHealthPercent("target")
        local nearbyEnemies = self:GetEnemiesInThunderClapReach(20)
        local msCooldown = self:GetSpellCooldown(S.MortalStrike)
        local opCooldown = self:GetSpellCooldown(S.Overpower)
        local rendRemaining = self:DebuffTimeRemaining("target", S.Rend)
        local tasteRemaining = self:BuffTimeRemaining("player", S.TasteForBlood)
        local hasTaste = self:HasBuff("player", S.TasteForBlood)
        local overpowerReady = self:IsUsableSpell(S.Overpower) and opCooldown == 0
        local overpowerExpiring = hasTaste and overpowerReady and tasteRemaining > 0 and tasteRemaining <= 2.0
        local isCleaveContext = nearbyEnemies >= 2
        local sweepingReady = isCleaveContext
            and self:KnowsSpell(S.SweepingStrikes)
            and self:IsUsableSpell(S.SweepingStrikes)
            and self:GetSpellCooldown(S.SweepingStrikes) == 0
            and rage >= 30
        local suddenDeathProc = self:HasBuff("player", S.SuddenDeath)
        local suddenDeathReady = suddenDeathProc and self:IsUsableSpell(S.Execute) and self:GetSpellCooldown(S.Execute) == 0 and rage >= 15
        local executePhase = targetHP < 20
        local procLock = overpowerReady or overpowerExpiring or suddenDeathProc or executePhase

        ArmsDebugState("CleaveContext", "Arms: Cleave context " .. (isCleaveContext and "ON" or "OFF") .. " (" .. nearbyEnemies .. " nearby)")

        if self:TryArmsSoloBurst(rage, nearbyEnemies, targetHP, msCooldown, overpowerReady, overpowerExpiring, suddenDeathProc, rendRemaining) then
            return true
        end
        
        -- Near-cap rage safety: queue dump early without consuming the GCD path.
        -- This prevents long 100-rage streaks when earlier priorities return first.
        if rage >= 85 and not procLock and Throttle("ArmsNearCapDump", 0.2) then
            if isCleaveContext then
                if not overpowerExpiring and msCooldown > 0 and QueueOnNextSwing(S.Cleave, "Arms: Cleave near-cap dump") then
                    -- Keep evaluating core priorities after queueing.
                end
            else
                if not overpowerExpiring and msCooldown > 0 and QueueOnNextSwing(S.HeroicStrike, "Arms: Heroic Strike near-cap dump") then
                    -- Keep evaluating core priorities after queueing.
                end
            end
        end
        
        -- ENHANCED: Use offensive cooldowns and trinkets with conservative throttling to avoid spam.
        local isElite = UnitClassification("target") == "elite" or UnitClassification("target") == "rareelite"
        local inGroup = IsInGroup()
        
        -- Use trinkets on elite mobs, in groups, high health targets, or proc windows.
        local wantsTrinketWindow = self:HasBuff("player", S.TasteForBlood) or isElite or inGroup or targetHP > 75
        if wantsTrinketWindow and Throttle("ArmsTrinkets", 20.0) then
            if self:UseTrinketsFixed() then
                WarriorDebug("Arms: Used trinkets")
            end
        end
        
        -- PRIORITY 1: Rend enables Taste for Blood. Keep it active before spending procs/cooldowns.
        if rendRemaining < 2.0 and self:IsUsableSpell(S.Rend) and rage >= 10 and Throttle("ArmsRendRefresh", 1.0) then
            if self:CastSpell(S.Rend, "target") then
                WarriorDebug("Arms: Rend applied/refreshed")
                return true
            end
        end

        -- Proc reliability: consume Overpower/Execute procs quickly to avoid waste.
        if overpowerExpiring and self:CastSpell(S.Overpower, "target") then
            WarriorDebug("Arms: Overpower (expiring Taste for Blood)")
            return true
        end

        if suddenDeathReady and Throttle("ArmsSDExecuteFast", 0.25) then
            local holdForOverpower = overpowerReady and rage < 20
            local holdForMS = msCooldown == 0 and rage < 30
            if not holdForOverpower and not holdForMS then
                if self:CastSpell(S.Execute, "target") then
                    WarriorDebug("Arms: Execute (Sudden Death)")
                    return true
                end
            end
        elseif suddenDeathProc and rage < 15 and Throttle("ArmsSuddenDeathPool", 3.0) then
            WarriorDebug("Arms: Pooling rage for Sudden Death (" .. rage .. ")")
        end

        if overpowerReady and rage >= 5 and self:CastSpell(S.Overpower, "target") then
            WarriorDebug("Arms: Overpower (" .. (hasTaste and "Taste for Blood" or "usable proc") .. ")")
            return true
        end

        -- Execute phase: mostly Execute; Overpower already handled above.
        if executePhase and self:IsUsableSpell(S.Execute) and self:GetSpellCooldown(S.Execute) == 0 and rage >= 15 and
           Throttle("ArmsExecutePhase", 0.25) then
            if self:CastSpell(S.Execute, "target") then
                WarriorDebug("Arms: Execute")
                return true
            end
        end

        -- Sweeping Strikes before Arms cleave burst.
        if sweepingReady and Throttle("ArmsSweepingStrikes", 0.5) then
            CastSpellByName(S.SweepingStrikes)
            WarriorDebug("Arms: Sweeping Strikes")
            return true
        end

        -- Cleave/AoE support. Bladestorm is strongest after Rend is secure and no Overpower is expiring.
        if isCleaveContext and self:IsInMeleeRange("target") then
            if self:KnowsSpell(S.ThunderClap) and self:IsUsableSpell(S.ThunderClap) and rage >= 20 and
               self:GetSpellCooldown(S.ThunderClap) == 0 and self:ThunderClapInRange() and
               self:HasEnemyInThunderClapReach(20) and
               (not overpowerExpiring) and Throttle("ArmsThunderClap", 0.5) then
                CastSpellByName(S.ThunderClap)
                WarriorDebug("Arms: Thunder Clap AoE")
                return true
            end

            if nearbyEnemies >= 3 and health > 35 and rendRemaining > 4 and not overpowerExpiring
               and not suddenDeathProc and not executePhase
               and self:KnowsSpell(S.Bladestorm) and self:IsUsableSpell(S.Bladestorm)
               and self:GetSpellCooldown(S.Bladestorm) == 0 then
                CastSpellByName(S.Bladestorm)
                WarriorDebug("Arms: Bladestorm AoE")
                return true
            end
            if ShouldQueueRageDump(rage, {self:GetSpellCooldown(S.MortalStrike), self:GetSpellCooldown(S.Overpower)}, 20)
               and QueueOnNextSwing(S.Cleave, "Arms: Cleave AoE") then
                return true
            end
        end
        
        -- Mortal Strike on cooldown for single-target damage and Blood Frenzy uptime.
        if self:KnowsSpell(S.MortalStrike) and self:IsUsableSpell(S.MortalStrike) and msCooldown == 0 and rage >= 20 then 
            CastSpellByName(S.MortalStrike, "target")
            WarriorDebug("Arms: Mortal Strike")
            return true
        end

        -- Use major cooldowns after core priority checks so burst windows do not drop procs.
        if self:UseWarriorOffensives() then return true end

        -- Group utility window: cast-time armor shred when it won't clip core Arms procs.
        if inGroup and (isElite or UnitClassification("target") == "worldboss") and targetHP > 35 and
           self:KnowsSpell(S.ShatteringThrow) and self:IsUsableSpell(S.ShatteringThrow) and
           self:GetSpellCooldown(S.ShatteringThrow) == 0 and not self:IsPlayerMoving() and
           not suddenDeathReady and not overpowerExpiring and msCooldown > 1.5 and rendRemaining > 3 and
           Throttle("ArmsShatteringThrow", 45) then
            CastSpellByName(S.ShatteringThrow, "target")
            WarriorDebug("Arms: Shattering Throw")
            return true
        end

        -- Single-target Bladestorm filler only when it will not clip core Arms buttons.
        if not isCleaveContext and health > 35 and (isElite or inGroup or targetHP > 50) and rendRemaining > 6
           and not overpowerReady and not suddenDeathProc and not executePhase
           and msCooldown > 1.5 and self:KnowsSpell(S.Bladestorm)
           and self:IsUsableSpell(S.Bladestorm) and self:GetSpellCooldown(S.Bladestorm) == 0
           and Throttle("ArmsBladestormSingle", 90) then
            CastSpellByName(S.Bladestorm)
            WarriorDebug("Arms: Bladestorm")
            return true
        end
        
        -- Slam filler only when no core button is about to become available.
        if self:KnowsSpell(S.Slam) and self:IsUsableSpell(S.Slam) and rage >= 15 and not UnitCastingInfo("player") then
            local opWindowSoon = overpowerReady or (hasTaste and opCooldown < 1.5)
            if (msCooldown > 1.5 or not self:KnowsSpell(S.MortalStrike)) and not opWindowSoon and rendRemaining > 2 then
                CastSpellByName(S.Slam, "target")
                WarriorDebug("Arms: Slam filler")
                return true
            end
        end

        -- Low-priority PvE utility: maintain Sunder only when it will not clip core Arms DPS windows.
        if rage >= 15 and not procLock and msCooldown > 1.5 and rendRemaining > 3 and
           self:ShouldMaintainArmsSunder("target") and Throttle("ArmsSunderMaintain", 1.2) then
            if self:CastSpell(S.SunderArmor, "target") then
                WarriorDebug("Arms: Sunder Armor maintenance")
                return true
            end
        end

        -- PRIORITY 5: Heroic Strike (rage dump when high rage)
        local shouldDumpArms = ShouldQueueRageDump(
            rage,
            {msCooldown, opCooldown},
            60
        ) and not procLock and not isCleaveContext
        if shouldDumpArms and QueueOnNextSwing(S.HeroicStrike, "Arms: Heroic Strike rage dump") then
            return true
        end
    end
    return false
end

-- FIXED: Fury rotation with better DPS and melee prioritization
function AC:FuryWarriorRotation()
    local rage = UnitPower("player", 1)
    local level = UnitLevel("player")
    local enemies = self:GetEnemyCount()
    local health = self:GetPlayerHealthPercent()
    local currentStance = self:GetCurrentStance()
    local inCombat = UnitAffectingCombat("player")
    local hasTarget = UnitExists("target") and UnitCanAttack("player", "target") and not UnitIsDeadOrGhost("target")

    if Throttle("FuryDebug", 1.0) then
        WarriorDebug(string.format("Fury L:%d S:%d R:%d HP:%.0f E:%d T:%s", 
                     level, currentStance, rage, health, enemies, hasTarget and "Y" or "N"))
    end
    
    if hasTarget then StartAttack() end

    -- Charge from Battle Stance
    if not inCombat and hasTarget and level >= 4 then
        if currentStance ~= 1 then
            if self:ForceBattleStance() then return true end
        end
        if currentStance == 1 and self:TryCharge() then return true end
    end

    local now = GetTime()
    self.furyRendWeavePendingUntil = self.furyRendWeavePendingUntil or 0
    self.furyRendWeaveLastAttempt = self.furyRendWeaveLastAttempt or 0
    self.furyRendWeaveTargetGUID = self.furyRendWeaveTargetGUID or nil
    if self.furyRendWeavePendingUntil <= now then
        self.furyRendWeavePendingUntil = 0
        self.furyRendWeaveTargetGUID = nil
    end

    local targetGUID = hasTarget and UnitGUID("target") or nil
    if self.furyRendWeavePendingUntil > now then
        if not hasTarget or targetGUID ~= self.furyRendWeaveTargetGUID or self:HasDebuff("target", S.Rend) then
            self.furyRendWeavePendingUntil = 0
            self.furyRendWeaveTargetGUID = nil
        end
    end

    local rendWeavePending = self.furyRendWeavePendingUntil > now and hasTarget and targetGUID == self.furyRendWeaveTargetGUID
    local preTargetHP = hasTarget and self:GetTargetHealthPercent("target") or 100
    local preNearbyEnemies = hasTarget and self:GetEnemiesInThunderClapReach(20) or 0
    local preTargetClassification = hasTarget and UnitClassification("target") or "normal"
    local inGroup = IsInGroup()
    local durableGroupTarget = preTargetClassification == "elite" or preTargetClassification == "rareelite" or
                               preTargetClassification == "worldboss"
    local preBTCooldown = self:GetSpellCooldown(S.Bloodthirst)
    local preWWCooldown = self:GetSpellCooldown(S.Whirlwind)
    local shouldStartRendWeave = inCombat and hasTarget and level >= 30 and self:KnowsSpell(S.Rend)
        and inGroup and durableGroupTarget and preNearbyEnemies < 2
        and not rendWeavePending
        and (now - self.furyRendWeaveLastAttempt) > 12
        and not self:HasDebuff("target", S.Rend)
        and preTargetHP > 25
        and rage >= 45
        and preBTCooldown > 2.0 and preWWCooldown > 2.0
        and not self:HasBuff("player", S.SlamEffect)
        and self:IsInMeleeRange("target")
        and self:IsUsableSpell(S.Rend)
        and self:GetSpellCooldown(S.Rend) == 0

    -- Stance management
    if inCombat and level >= 30 and currentStance ~= 3 and not (currentStance == 1 and (shouldStartRendWeave or rendWeavePending)) then
        if self:ForceBerserkerStance() then return true end
    elseif inCombat and level < 30 and currentStance ~= 1 then
        if self:ForceBattleStance() then return true end
    end
    
    if inCombat and ((level >= 30 and currentStance ~= 3 and not (currentStance == 1 and (shouldStartRendWeave or rendWeavePending))) or (level < 30 and currentStance ~= 1)) then
        WarriorDebug("Fury: Waiting for stance")
        return true
    end 

    if inCombat then
        -- Find target if needed - prefer melee targets
        if not hasTarget then
            local meleeTarget = self:FindMeleeTarget()
            if meleeTarget then
                TargetUnit(meleeTarget)
                hasTarget = true
                WarriorDebug("Fury: Found melee target")
            else
                local bestTarget = self:FindBestWarriorTarget()
                if bestTarget then
                    TargetUnit(bestTarget)
                    hasTarget = true
                    WarriorDebug("Fury: Found ranged target")
                end
            end
        end
        if not hasTarget then return true end

        -- ENHANCED: Intercept for gap closing, otherwise skip melee abilities if out of range
        if not self:IsInMeleeRange("target") then
            -- Re-check with interact distance to avoid false negatives on large hitboxes.
            local touchContact = CheckInteractDistance("target", 3)
            if touchContact then
                WarriorDebug("Fury: Melee contact fallback confirmed")
            else
            -- Try Intercept if available (Berserker Stance or Warbringer talent)
            if level >= 30 then
                local hasWarbringer = self:HasWarbringerTalent()
                if (hasWarbringer or currentStance == 3) then
                    local availableRanged = self:GetAvailableRangedAbilities()
                    if availableRanged.intercept and self:UseRangedAbilityAndReturn("Intercept", "target") then
                        WarriorDebug("Fury: Intercept gap closer" .. (hasWarbringer and " (Warbringer)" or ""))
                        return true
                    end
                end
            end
            local availableRanged = self:GetAvailableRangedAbilities()
            if availableRanged.heroicThrow and self:UseRangedAbilityAndReturn("Heroic Throw", "target") then
                WarriorDebug("Fury: Heroic Throw while out of melee")
                return true
            end
            WarriorDebug("Fury: Target out of melee range, no gap closers available")
            return false
            end
        end

        if self:TryFuryInterrupt("target") then return true end

        -- FIXED: Use defensive cooldowns when needed
        if self:UseWarriorDefensives() then return true end
        
        -- ENHANCED: Proactive Spell Reflection (interrupt priority system)
        if self:UseEnhancedSpellReflection() then return true end
        
        local btWindow = self:GetSpellCooldown(S.Bloodthirst)
        local wwWindow = self:GetSpellCooldown(S.Whirlwind)
        local coreSoon = (btWindow <= 1.5) or (wwWindow <= 1.5)
        local hasSlamProc = self:HasBuff("player", S.SlamEffect)
        
        -- Berserker Rage
        if self:IsUsableSpell(S.BerserkerRage) and self:GetSpellCooldown(S.BerserkerRage) == 0 then
            if UnitIsFeared("player") or UnitIsCharmed("player")
               or (rage < 25 and not coreSoon and not hasSlamProc) then 
                CastSpellByName(S.BerserkerRage)
                WarriorDebug("Fury: Berserker Rage")
                return true 
            end
        end
        
        -- Blood Rage
        if rage < 20 and not coreSoon and not hasSlamProc
           and self:IsUsableSpell(S.BloodRage) and self:GetSpellCooldown(S.BloodRage) == 0 then
            CastSpellByName(S.BloodRage)
            WarriorDebug("Fury: Blood Rage")
            return true
        end
        
        -- Victory Rush
        if self:TryVictoryRush() then return true end

        -- Rampage upkeep is core Fury maintenance in WotLK.
        if self:KnowsSpell(S.Rampage) and not self:HasBuff("player", S.Rampage) and self:IsUsableSpell(S.Rampage) and rage >= 20 then
            CastSpellByName(S.Rampage)
            WarriorDebug("Fury: Rampage upkeep")
            return true
        end

        -- Keep shout buff maintained in combat.
        local combatShout = self:GetPreferredWarriorShout("Fury")
        if combatShout and rage >= 10 and Throttle("FuryCombatShout", 10) and self:IsUsableSpell(combatShout) then
            CastSpellByName(combatShout)
            WarriorDebug("Fury: " .. combatShout)
            return true
        end

        -- Retaliation is utility and intentionally not used in DPS flow.

        -- AoE rotation - use strict local hostile detection
        local nearbyEnemies = self:GetEnemiesInThunderClapReach(20)
        local isCleaveContext = nearbyEnemies >= 2
        -- Near-cap safety: queue dump early without consuming the GCD path.
        if rage >= 85 and Throttle("FuryNearCapDump", 0.2) then
            if isCleaveContext then
                QueueOnNextSwing(S.Cleave, "Fury: Cleave near-cap dump")
            else
                QueueOnNextSwing(S.HeroicStrike, "Fury: Heroic Strike near-cap dump")
            end
        end

        if isCleaveContext and self:IsInMeleeRange("target") then 
            if self:KnowsSpell(S.Whirlwind) and self:IsUsableSpell(S.Whirlwind) and rage >= 25 then
                if self:CastSpell(S.Whirlwind, "target") then
                    WarriorDebug("Fury: Whirlwind AoE")
                    return true
                end
            end
            if ShouldQueueRageDump(rage, {self:GetSpellCooldown(S.Bloodthirst), self:GetSpellCooldown(S.Whirlwind)}, 65)
               and QueueOnNextSwing(S.Cleave, "Fury: Cleave dump") then
                return true
            end
        end
        
        -- Bloodthirst
        if self:KnowsSpell(S.Bloodthirst) and self:IsUsableSpell(S.Bloodthirst)
           and self:GetSpellCooldown(S.Bloodthirst) == 0 and rage >= 20 then 
            if self:CastSpell(S.Bloodthirst, "target") then
                WarriorDebug("Fury: Bloodthirst")
                return true
            end
        end
        
        -- Whirlwind
        if self:KnowsSpell(S.Whirlwind) and self:IsUsableSpell(S.Whirlwind)
           and self:GetSpellCooldown(S.Whirlwind) == 0 and rage >= 25 then 
            if self:CastSpell(S.Whirlwind, "target") then
                WarriorDebug("Fury: Whirlwind")
                return true
            end
        end

        -- Slam proc (after BT/WW to avoid clipping core cooldowns).
        if self:HasBuff("player", S.SlamEffect) and self:KnowsSpell(S.Slam) and self:IsUsableSpell(S.Slam)
           and Throttle("FurySlamProc", 0.35) then
            if self:CastSpell(S.Slam, "target") then
                WarriorDebug("Fury: Slam proc")
                return true
            end
        end

        -- Controlled Rend weave: commit once started to avoid stance flip-flop.
        if shouldStartRendWeave then
            self.furyRendWeavePendingUntil = now + 3.0
            self.furyRendWeaveLastAttempt = now
            self.furyRendWeaveTargetGUID = UnitGUID("target")
            rendWeavePending = true
        end

        if rendWeavePending then
            if currentStance ~= 1 then
                if Throttle("FuryRendStanceSwap", 1.5) and self:ForceBattleStance() then
                    WarriorDebug("Fury: Battle Stance for Rend weave")
                    return true
                end
            elseif self:IsUsableSpell(S.Rend) and self:GetSpellCooldown(S.Rend) == 0 and Throttle("FuryRendCast", 0.6) then
                if self:CastSpell(S.Rend, "target") then
                    self.furyRendWeavePendingUntil = 0
                    self.furyRendWeaveTargetGUID = nil
                    WarriorDebug("Fury: Rend weave")
                    return true
                end
            end
        end

        -- Use major cooldowns after core BT/WW/Slam windows.
        if self:UseWarriorOffensives() then return true end

        local targetHP = self:GetTargetHealthPercent("target")
        local btCooldown = self:GetSpellCooldown(S.Bloodthirst)
        local wwCooldown = self:GetSpellCooldown(S.Whirlwind)
        -- Execute is filler for Fury even in execute phase.
        if targetHP < 20 and self:IsUsableSpell(S.Execute) and rage >= 30 and btCooldown > 1.5 and wwCooldown > 1.5
           and not self:HasBuff("player", S.SlamEffect) then
            if self:CastSpell(S.Execute, "target") then
                WarriorDebug("Fury: Execute filler")
                return true
            end
        end
        
        -- Heroic Strike rage dump
        if ShouldQueueRageDump(rage, {btCooldown, wwCooldown}, 60)
           and QueueOnNextSwing(S.HeroicStrike, "Fury: Heroic Strike dump") then
            return true
        end
    end
    return false
end

-- Dedicated low-level warrior handling for characters with no talent points yet.
function AC:LevelingWarriorRotation()
    local level = UnitLevel("player")
    local rage = UnitPower("player", 1)
    local health = self:GetPlayerHealthPercent()
    local inCombat = UnitAffectingCombat("player")
    local hasTarget = UnitExists("target") and UnitCanAttack("player", "target") and not UnitIsDeadOrGhost("target")

    if Throttle("LevelingDebug", 2.5) then
        WarriorDebug(string.format(
            "Leveling mode: L:%d Rage:%d HP:%.0f Combat:%s Target:%s",
            level,
            rage,
            health,
            inCombat and "Y" or "N",
            hasTarget and "Y" or "N"
        ))
    end

    if not inCombat then
        if UnitExists("target") and UnitCanAttack("player", "target") and not UnitIsDeadOrGhost("target") then
            if level >= 4 and self:TryCharge() then
                return true
            end
        end

        if self:CheckWarriorBuffs("None") then
            return true
        end

        if Throttle("LevelingIdle", 3.0) then
            WarriorDebug("Leveling mode: out of combat, waiting for target or rage")
        end
        return false
    end

    if not hasTarget then
        local meleeTarget = self:FindMeleeTarget()
        if meleeTarget then
            TargetUnit(meleeTarget)
            hasTarget = true
            WarriorDebug("Leveling mode: found melee target " .. (UnitName("target") or "Unknown"))
        else
            local bestTarget = self:FindBestWarriorTarget()
            if bestTarget then
                TargetUnit(bestTarget)
                hasTarget = true
                WarriorDebug("Leveling mode: found target " .. (UnitName("target") or "Unknown"))
            end
        end
    end

    if not hasTarget then
        if Throttle("LevelingNoTarget", 3.0) then
            WarriorDebug("Leveling mode: no hostile target available")
        end
        return false
    end

    StartAttack()

    if not self:IsInMeleeRange("target") then
        if Throttle("LevelingOutOfMelee", 2.0) then
            WarriorDebug("Leveling mode: target out of melee range, waiting for swing or gap closer")
        end
        return false
    end

    if rage < 25 and self:IsUsableSpell(S.BloodRage) and self:GetSpellCooldown(S.BloodRage) == 0 then
        CastSpellByName(S.BloodRage)
        WarriorDebug("Leveling mode: Blood Rage")
        return true
    end

    if self:TryVictoryRush() then
        return true
    end

    local targetHP = self:GetTargetHealthPercent("target")
    if targetHP < 20 and level >= 24 and self:IsUsableSpell(S.Execute) and rage >= 10 then
        CastSpellByName(S.Execute, "target")
        WarriorDebug("Leveling mode: Execute")
        return true
    end

    if level >= 4 and self:DebuffTimeRemaining("target", S.Rend) < 2 and self:IsUsableSpell(S.Rend) and rage >= 10 then
        CastSpellByName(S.Rend, "target")
        WarriorDebug("Leveling mode: Rend")
        return true
    end

    if level >= 8 and self:HasBuff("player", S.TasteForBlood) and self:IsUsableSpell(S.Overpower) and rage >= 5 then
        CastSpellByName(S.Overpower, "target")
        WarriorDebug("Leveling mode: Overpower")
        return true
    end

    if ShouldQueueRageDump(rage, nil, 35) and QueueOnNextSwing(S.HeroicStrike, "Leveling mode: Heroic Strike dump") then
        return true
    end

    if Throttle("LevelingNoAction", 2.5) then
        WarriorDebug("Leveling mode: no usable action this tick")
    end

    return false
end

-- FIXED: Main rotation controller with better performance
function AC:WarriorRotation()
    local spec = self:GetPlayerSpec()
    local health = self:GetPlayerHealthPercent()
    local actionTaken = false
    local inCombat = UnitAffectingCombat("player")

    -- Characters below level 10 have no talents, so route them through the
    -- dedicated leveling handler instead of the spec-based rotations.
    if UnitLevel("player") < 10 or spec == "None" then
        return self:LevelingWarriorRotation()
    end

    -- Out of combat buffs
    if not inCombat then
        if UnitExists("target") and UnitCanAttack("player", "target") and not UnitIsDeadOrGhost("target") then
            if spec == "Protection" and self:TryProtectionWarbringerCharge("target") then return true end
            if self:TryCharge() then return true end
        end
        if self:CheckWarriorBuffs(spec) then return true end
        return false
    end
    
    -- Emergency Lifeblood (Herbalism profession ability) at 50% health
    if self:UseLifeblood() then return true end

    -- Run spec-specific rotation
    if spec == "Protection" then
        actionTaken = self:ProtectionWarriorRotation()
    elseif spec == "Arms" then
        actionTaken = self:ArmsWarriorRotation()
    elseif spec == "Fury" then
        actionTaken = self:FuryWarriorRotation()
    end

    return actionTaken
end

-- =============================================
-- INITIALIZATION AND REGISTRATION
-- =============================================

-- FIXED: Enhanced initialization with better error handling
function AC:InitWarriorRotations()
    -- FIXED: Initialize all tracking tables
    self.rotations = self.rotations or {}
    self.rotations["WARRIOR"] = {}
    self.expectedThreatTargets = self.expectedThreatTargets or {}
    self.defensiveAttempts = self.defensiveAttempts or {}
    self.lastDefensiveReset = 0
    self.lastTauntTime = 0
    self.lastTauntTarget = ""
    self.lastMovementTime = GetTime()
    self.furyRendWeavePendingUntil = 0
    self.furyRendWeaveLastAttempt = 0
    self.furyRendWeaveTargetGUID = nil
    
    -- FIXED: Register all spec rotations
    self.rotations["WARRIOR"]["Arms"] = function(s) return s:WarriorRotation() end
    self.rotations["WARRIOR"]["Fury"] = function(s) return s:WarriorRotation() end
    self.rotations["WARRIOR"]["Protection"] = function(s) return s:WarriorRotation() end
    self.rotations["WARRIOR"]["None"] = function(s) return s:WarriorRotation() end 
    
    -- FIXED: Register buff checking function
    self.CheckWarriorBuffs = AC.CheckWarriorBuffs
    
    -- FIXED: Initialize combat log tracking if available
    if self.InitCombatTracking then
        self:InitCombatTracking()
    end
    
    -- FIXED: Register for combat events to clean up tracking data
    if self.RegisterEvent then
        self:RegisterEvent("PLAYER_REGEN_ENABLED", function()
            -- Clean up tracking data when leaving combat
            if self.expectedThreatTargets then
                for guid, _ in pairs(self.expectedThreatTargets) do
                    self.expectedThreatTargets[guid] = nil
                end
            end
            if self.defensiveAttempts then
                self.defensiveAttempts = {}
            end
            self.furyRendWeavePendingUntil = 0
            self.furyRendWeaveTargetGUID = nil
            WarriorDebug("Combat ended - cleaned up tracking data")
        end)
        
        self:RegisterEvent("PLAYER_REGEN_DISABLED", function()
            -- Reset defensive attempts when entering combat
            self.defensiveAttempts = {}
            self.lastDefensiveReset = GetTime()
            WarriorDebug("Combat started - reset defensive attempts")
        end)
    end
    
    self:Print("Warrior rotations (ENHANCED WITH SMART TARGETING) initialized")
    WarriorDebug("Enhanced features: Smart melee prioritization, ranged ability gating, immediate return to melee")
    WarriorDebug("Smart targeting: Only targets distant enemies when Taunt/Heroic Throw available")
    WarriorDebug("FIXED: No taunt spam + no defensive freezing + melee-first targeting")
    WarriorDebug("FIXED: All cooldown checks, range validation, and freeze points eliminated")
    WarriorDebug("FIXED: Full 3.3.5a Lua 5.1 compatibility - NO Lua 5.2+ features")
    WarriorDebug("Taunt conditions: Emergency only (healers <20%, others <10% health)")
    WarriorDebug("Performance: Limited scanning ranges, throttled updates, memory leak protection")
end

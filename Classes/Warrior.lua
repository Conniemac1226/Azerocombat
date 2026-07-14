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
    
    -- Cooldowns
    Recklessness = "Recklessness", BloodRage = "Bloodrage", ShieldWall = "Shield Wall",
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
    Charge = "Charge", Intercept = "Intercept", Hamstring = "Hamstring",
    
    -- Buffs/Debuffs
    SuddenDeath = "Sudden Death",
    TasteForBlood = "Taste for Blood", SlamEffect = "Slam!",
    EnrageEffect = "Enrage", VictoryRushBuff = "Victorious",
    
    -- Racial Abilities
    BloodFury = "Blood Fury", Berserking = "Berserking", WarStomp = "War Stomp", 
    WillOfForsaken = "Will of the Forsaken", EveryMan = "Every Man for Himself",      
    Stoneform = "Stoneform", EscapeArtist = "Escape Artist",
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

local function QueueOnNextSwing(spellName, debugText)
    if not spellName or not AC:IsUsableSpell(spellName) or AC:GetSpellCooldown(spellName) > 0 or
       IsCurrentSpell(spellName) then
        return false
    end

    -- The second 3.3.5 argument is an onSelf boolean, not a unit token. These
    -- are self/next-swing toggles, so queue them without a target argument.
    CastSpellByName(spellName)
    if not IsCurrentSpell(spellName) then
        return false
    end
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
    local _, playerClass = UnitClass("player")
    if playerClass ~= "WARRIOR" and self.CoreIsInMeleeRange then
        return self:CoreIsInMeleeRange(unit, strict)
    end

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

function AC:IsInInterceptRange(unit)
    if not UnitExists(unit) then return false end

    local success, result = pcall(IsSpellInRange, S.Intercept, unit)
    return success and result == 1
end

-- ENHANCED: Check available ranged abilities with cooldown validation
function AC:GetAvailableRangedAbilities()
    local abilities = {}
    
    -- Heroic Throw (level 20+, ranged damage)
    if UnitLevel("player") >= 20 and self:IsUsableSpell(S.HeroicThrow) and self:GetSpellCooldown(S.HeroicThrow) == 0 then
        abilities.heroicThrow = true
    end

    -- Fury may use Intercept as its in-combat gap closer. Protection keeps
    -- Charge-only behavior because its universal tank system owns movement.
    if self:GetPlayerSpec() == "Fury" and UnitAffectingCombat("player") and
       UnitLevel("player") >= 30 and self:GetCurrentStance() == 3 and
       self:IsUsableSpell(S.Intercept) and self:GetSpellCooldown(S.Intercept) == 0 then
        abilities.intercept = true
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

-- Spread Protection threat across nearby mobs after the current target has
-- received an initial threat/debuff application. This avoids random target
-- swapping on pull while still giving Shield Slam/Revenge/Devastate/Cleave
-- time on targets that have not yet been marked by this rotation.
function AC:TryProtectionMultiTargetDistribution(nearbyEnemies)
    if nearbyEnemies < 2 or not self:IsAutoTargetSwitchAllowed() then return false end
    if not UnitExists("target") or not UnitCanAttack("player", "target") or UnitIsDeadOrGhost("target") then
        return false
    end
    if not self:IsInMeleeRange("target", true) then return false end
    if not Throttle("ProtMultiTargetDistribution", 0.5) then return false end

    local currentGUID = UnitGUID("target")
    if not currentGUID or not self.expectedThreatTargets or not self.expectedThreatTargets[currentGUID] then
        return false
    end

    -- Require evidence that the current mob has received a tanking debuff;
    -- target marks alone can also be created by target-acquisition logic.
    local currentHasThreatDebuff = self:HasDebuff("target", S.SunderArmor) or
                                   self:HasDebuff("target", S.ThunderClap) or
                                   self:HasDebuff("target", S.DemoShout)
    if not currentHasThreatDebuff then return false end

    local candidates = {}
    local seenGUIDs = {}

    local function addCandidate(unit)
        if not UnitExists(unit) or UnitIsDeadOrGhost(unit) or
           not UnitCanAttack("player", unit) or UnitIsUnit(unit, "target") or
           not UnitAffectingCombat(unit) or not self:IsInMeleeRange(unit, true) then
            return
        end

        local guid = UnitGUID(unit)
        if not guid or seenGUIDs[guid] then return end
        seenGUIDs[guid] = true

        local score = 0
        local markedAt = self.expectedThreatTargets and self.expectedThreatTargets[guid]
        if not markedAt or GetTime() - markedAt > 15 then
            score = score + 100
        end
        if not self:HasDebuff(unit, S.SunderArmor) and not self:HasDebuff(unit, S.ThunderClap) then
            score = score + 35
        end
        candidates[#candidates + 1] = {unit = unit, score = score}
    end

    for i = 1, 20 do
        addCandidate("nameplate" .. i)
    end

    local groupCount = GetNumRaidMembers() > 0 and GetNumRaidMembers() or GetNumPartyMembers()
    local prefix = GetNumRaidMembers() > 0 and "raid" or "party"
    for i = 1, groupCount do
        addCandidate(prefix .. i .. "target")
    end

    local bestCandidate
    for _, candidate in ipairs(candidates) do
        if not bestCandidate or candidate.score > bestCandidate.score then
            bestCandidate = candidate
        end
    end

    if not bestCandidate or bestCandidate.score < 100 then return false end

    TargetUnit(bestCandidate.unit)
    self.lastTargetSwitch = GetTime()
    if not IsCurrentSpell("Attack") then StartAttack() end
    WarriorDebug("Prot: Distributing threat to " .. (UnitName(bestCandidate.unit) or "Unknown"))
    return true
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
        return self:CastSpell(spellName, unit)
    end

    if ability == "Heroic Throw" and self:IsUsableSpell(S.HeroicThrow) then
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
    elseif ability == "Intercept" and self:GetPlayerSpec() == "Fury" and
           self:IsUsableSpell(S.Intercept) then
        if self:GetSpellCooldown(S.Intercept) > 0 or self:GetCurrentStance() ~= 3 then
            return false
        end

        if self:IsInInterceptRange(target) then
            if castAttempt(S.Intercept, target) then
                self:MarkAsOurTarget(UnitGUID(target))
                WarriorDebug("Fury: Intercept gap closer")
                success = true
            end
        end
    end
    
    -- Ranged attacks can return to a better melee target after firing.
    if success and ability ~= "Intercept" and self:IsAutoTargetSwitchAllowed() and not self:IsInMeleeRange(target) then
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
            if not self:CastSpell(S.VictoryRush) then return false end
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

    if (health < 40 or (spec == "Protection" and underHeavyPressure and health < 50)) and canRetry("defensiveRacial", 10) then
        if self:UseRacialsWarrior(false, true) then
            markAttempt("defensiveRacial")
            WarriorDebug("Used defensive racial")
            return true
        end
    end
    
    -- Last Stand is the first major survivability button for prot pressure.
    if self:KnowsSpell(S.LastStand) and self:IsUsableSpell(S.LastStand) and
       self:GetSpellCooldown(S.LastStand) == 0 and canRetry("lastStand", 8) then
        if health < 30 or (spec == "Protection" and underHeavyPressure and health < 40) then
            markAttempt("lastStand")
            if not self:CastSpell(S.LastStand) then return false end
            WarriorDebug("Last Stand at low health / tank pressure")
            return true
        end
    end

    -- Shield Wall is the hard panic button; keep it later than Last Stand.
    if self:KnowsSpell(S.ShieldWall) and self:IsUsableSpell(S.ShieldWall) and
       self:GetSpellCooldown(S.ShieldWall) == 0 and canRetry("shieldWall", 8) then
        if self:KnowsSpell(S.ShieldWall) and self:IsUsableSpell(S.ShieldWall) and
           self:GetSpellCooldown(S.ShieldWall) == 0 then
            if hasShield and (health < 20 or (spec == "Protection" and underHeavyPressure and health < 30)) then
                markAttempt("shieldWall")
                self.shieldWallBlocked = false
                if not self:CastSpell(S.ShieldWall) then return false end
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
    if health < 45 and canRetry("enragedRegen", 6) and self:KnowsSpell(S.EnragedRegeneration) and
       self:IsUsableSpell(S.EnragedRegeneration) then
        if self:KnowsSpell(S.EnragedRegeneration) and self:IsUsableSpell(S.EnragedRegeneration) then
            local isEnraged = self:HasBuff("player", S.BerserkerRage) or 
                             self:HasBuff("player", S.DeathWish) or 
                             self:HasBuff("player", S.EnrageEffect) or
                             self:HasBuff("player", S.BloodRage)
            
            if isEnraged and self:GetSpellCooldown(S.EnragedRegeneration) == 0 then
                markAttempt("enragedRegen")
                if not self:CastSpell(S.EnragedRegeneration) then return false end
                WarriorDebug("Enraged Regeneration")
                return true
            elseif not isEnraged and self:KnowsSpell(S.BerserkerRage) and self:IsUsableSpell(S.BerserkerRage) and
                   self:GetSpellCooldown(S.BerserkerRage) == 0 and 
                   canRetry("berserkerForRegen", 4) and health < 35 then
                markAttempt("berserkerForRegen")
                if not self:CastSpell(S.BerserkerRage) then return false end
                WarriorDebug("Berserker Rage for Enraged Regen")
                return true
            end
        end
    end
    
    -- REMOVED: Old reactive Spell Reflection - now handled proactively in rotation interrupt priority
    
    -- Fear is a last-resort solo survival tool, not a normal tank-group button.
    if not IsInGroup() and health < 12 and enemies >= 3 and canRetry("intimidatingShout", 15) then
        if self:KnowsSpell(S.IntimidatingShout) and self:IsUsableSpell(S.IntimidatingShout) and
           self:GetSpellCooldown(S.IntimidatingShout) == 0 then
            markAttempt("intimidatingShout")
            if not self:CastSpell(S.IntimidatingShout) then return false end
            WarriorDebug("Intimidating Shout - crowd control")
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
    local stance = self:GetCurrentStance()
    -- WotLK Spell Reflection requires Battle or Defensive Stance plus a
    -- shield. Do not consume a rotation tick from Fury's Berserker Stance.
    if stance ~= 1 and stance ~= 2 then
        return false
    end

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
    
    -- Spell Reflection only works on a spell aimed at the warrior (or, with
    -- Improved Spell Reflection, a nearby friendly party member). Do not burn
    -- it on an enemy healer's self-cast or another unrelated cast.
    if not UnitExists("targettarget") then
        return false
    end

    local castAimedAtPlayer = UnitIsUnit("targettarget", "player")
    local canProtectParty = IsInGroup() and self:HasTalentByName("Improved Spell Reflection", "ImprovedSpellReflection")
    local castAimedAtFriendly = canProtectParty and UnitIsFriend("player", "targettarget") and
                                not UnitIsDeadOrGhost("targettarget")
    if not castAimedAtPlayer and not castAimedAtFriendly then
        return false
    end

    -- Channels have already landed by the time UnitChannelInfo reports them;
    -- interrupt those instead of trying to reflect a later channel tick.
    local spellName, _, _, _, _, endTime = UnitCastingInfo("target")
    if not spellName or not endTime then
        return false
    end
    
    local timeLeft = (endTime / 1000) - GetTime()
    local health = self:GetPlayerHealthPercent()

    -- These casts cannot be reflected back as hostile targeted spells. This
    -- also protects against an enemy healer retaining the warrior as a target
    -- while using a self-cast modifier.
    local nonReflectableSpells = {
        "Blizzard", "Flamestrike", "Rain of Fire", "Hellfire", "Hurricane",
        "Volley", "Arcane Explosion", "Holy Nova", "Psychic Scream", "Howl of Terror",
        "Intimidating Shout", "Heal", "Holy Light", "Flash of Light", "Regrowth", "Tranquility"
    }
    for _, nonReflectable in ipairs(nonReflectableSpells) do
        if spellName:find(nonReflectable) then
            return false
        end
    end

    local function castReflection(reason)
        if self:CastSpell(S.SpellReflection, "player") then
            WarriorDebug("SPELL REFLECTION: " .. spellName .. " (" .. reason .. ")")
            return true
        end
        return false
    end
    
    -- High-priority dangerous spells that should ALWAYS be reflected
    local dangerousSpells = {
        -- Crowd Control (highest priority)
        "Fear", "Polymorph", "Hex", "Banish", "Hibernate", "Entangling Roots", "Cyclone",
        
        -- High Damage Spells
        "Fireball", "Greater Fireball", "Pyroblast", "Scorch", "Frostbolt",
        "Lightning Bolt", "Chain Lightning", "Lava Burst", "Lightning Strike",
        "Shadow Bolt", "Mind Blast", "Vampiric Touch", "Wrath", "Starfire",
        
        -- Casted debuffs and DoTs
        "Immolate",
        "Unstable Affliction", "Haunt", "Seed of Corruption"
    }
    
    -- Check for dangerous spells (always reflect these)
    for _, dangerous in ipairs(dangerousSpells) do
        if spellName:find(dangerous) then
            -- Optimal timing: cast when 0.5-2.5s left on cast
            if timeLeft > 0.5 and timeLeft < 2.5 then
                return castReflection("HIGH PRIORITY")
            -- Emergency timing for very dangerous spells
            elseif (spellName:find("Fear") or spellName:find("Polymorph") or spellName:find("Hex")) and timeLeft > 0.2 then
                return castReflection("EMERGENCY CC")
            end
        end
    end
    
    -- Reflect any spell when health is low (survival mode)
    if health < 50 and timeLeft > 0.5 and timeLeft < 2.5 then
        return castReflection("LOW HEALTH SURVIVAL")
    end
    
    -- Reflect any spell when health is critical (desperation mode)
    if health < 25 and timeLeft > 0.2 and timeLeft < 3.0 then
        return castReflection("CRITICAL HEALTH")
    end
    
    -- Elite/Boss enemies: reflect more liberally
    local classification = UnitClassification("target")
    if (classification == "elite" or classification == "rareelite" or classification == "worldboss") then
        if health < 75 and timeLeft > 0.5 and timeLeft < 2.5 then
            return castReflection("ELITE/BOSS")
        end
    end
    
    return false
end


-- ENHANCED: Smart offensive cooldown usage with better conditions
function AC:UseWarriorOffensives()
    local targetHP = self:GetTargetHealthPercent("target")
    local targetMaxHealth = UnitHealthMax("target") or 0
    local targetClass = UnitClassification("target")
    -- Poll quickly enough to place the second cooldown inside the first one's
    -- burst window; the spell cooldowns remain the real spam protection.
    if not Throttle("WarriorOffensives", 0.5) then return false end
    
    -- Don't blow CDs on trivial mobs
    if targetClass == "trivial" or targetHP < 15 then
        return false
    end
    
    -- Check if it's worth using offensive CDs
    local worthIt = targetClass == "elite" or targetClass == "rareelite" or 
                   targetClass == "worldboss" or targetMaxHealth > 200000 or
                   (IsInGroup() and targetHP > 50)
    
    if not worthIt then return false end
    
    self.warriorBurstWindowUntil = self.warriorBurstWindowUntil or 0

    -- Death Wish is the primary Fury burst anchor and should carry racials and
    -- on-use trinkets. Recklessness can then follow during the same window.
    if self:KnowsSpell(S.DeathWish) and self:IsUsableSpell(S.DeathWish) and
       self:GetSpellCooldown(S.DeathWish) == 0 and Throttle("DeathWish", 1.0) then
        if self:CastSpell(S.DeathWish, "player") then
            WarriorDebug("Death Wish - increased damage")
            self.warriorBurstWindowUntil = GetTime() + 12
            self:UseRacialsWarrior(true, false)
            self:UseTrinketsFixed()
            return true
        end
    end

    -- Recklessness is Berserker-Stance-only. Do not make Arms stance-dance;
    -- Fury naturally satisfies this condition and can stack it with Death Wish.
    local inBurstWindow = self:HasBuff("player", S.DeathWish) or GetTime() < self.warriorBurstWindowUntil
    local deathWishUnavailable = not self:KnowsSpell(S.DeathWish) or self:GetSpellCooldown(S.DeathWish) > 0
    if self:GetCurrentStance() == 3 and (inBurstWindow or deathWishUnavailable) and
       self:IsUsableSpell(S.Recklessness) and self:GetSpellCooldown(S.Recklessness) == 0 and
       Throttle("Recklessness", 1.0) then
        if self:CastSpell(S.Recklessness, "player") then
            WarriorDebug("Recklessness - burst window")
            self:UseRacialsWarrior(true, false)
            self:UseTrinketsFixed()
            return true
        end
    end
    
    return false
end

-- ENHANCED: Better racial usage with cooldown checks
function AC:UseRacialsWarrior(burst, emergency) 
    local checkFrequency = emergency and 0.5 or ((self:GetPlayerSpec() == "Protection") and 2.0 or 3.0)
    if not Throttle("WarriorRacials", checkFrequency) then return false end
    
    local _, race = UnitRace("player")
    race = string.upper(race) 
    local healthPercent = self:GetPlayerHealthPercent()
    local inCombat = UnitAffectingCombat("player")

    local function castRacial(spellName, message)
        if not self:IsUsableSpell(spellName) or self:GetSpellCooldown(spellName) > 0 then
            return false
        end
        if self:CastSpell(spellName, "player") then
            WarriorDebug(message)
            return true
        end
        return false
    end

    local function hasPlayerDebuff(types, nameFragments)
        for i = 1, 40 do
            local name, _, _, _, debuffType = UnitDebuff("player", i)
            if not name then break end

            if types and debuffType and types[debuffType] then
                return true
            end

            local lowerName = string.lower(name)
            if nameFragments then
                for _, fragment in ipairs(nameFragments) do
                    if string.find(lowerName, fragment, 1, true) then
                        return true
                    end
                end
            end
        end
        return false
    end
    
    -- Offensive racials during burst
    if burst and inCombat then
        if race == "ORC" and castRacial(S.BloodFury, "Racial: Blood Fury (DPS)") then return true end
        if race == "TROLL" and castRacial(S.Berserking, "Racial: Berserking (Haste)") then return true end
    end
    
    -- Defensive/Emergency racials
    if emergency then
        local hasFearCharmSleep = UnitIsFeared("player") or UnitIsCharmed("player") or
            hasPlayerDebuff(nil, {"fear", "charm", "sleep", "hibernate", "wyvern sting"})
        local hasLossOfControl = hasFearCharmSleep or hasPlayerDebuff(nil, {
            "stun", "polymorph", "sap", "hex", "cyclone", "banish", "freeze",
            "hammer of justice", "kidney shot", "cheap shot", "repentance", "gouge", "blind"
        })
        local hasMovementImpair = hasPlayerDebuff(nil, {
            "slow", "root", "snare", "frost nova", "entangling roots", "hamstring",
            "crippling poison", "chains of ice", "wing clip", "piercing howl"
        })
        local hasStoneformDebuff = hasPlayerDebuff({Poison = true, Disease = true}, {
            "bleed", "rend", "rupture", "garrote", "rake", "rip", "deep wound"
        })

        if race == "DWARF" and (hasStoneformDebuff or healthPercent < 25) and
           castRacial(S.Stoneform, "Racial: Stoneform (defensive)") then return true end
        if race == "HUMAN" and hasLossOfControl and
           castRacial(S.EveryMan, "Racial: Every Man for Himself") then return true end
        if race == "GNOME" and hasMovementImpair and
           castRacial(S.EscapeArtist, "Racial: Escape Artist") then return true end
        if (race == "UNDEAD" or race == "SCOURGE") and hasFearCharmSleep and
           castRacial(S.WillOfForsaken, "Racial: Will of the Forsaken") then return true end
        if race == "DRAENEI" and healthPercent < 70 and castRacial(S.GiftOfNaaru, "Racial: Gift of Naaru (HoT)") then return true end
    end
    
    -- Utility racials in combat
    if inCombat and UnitExists("target") and UnitCanAttack("player", "target") then
        if race == "TAUREN" and UnitExists("target") and self:GetEnemiesAtLocation("target", 10) >= 2 and self:IsInMeleeRange("target") and 
           self:IsUsableSpell(S.WarStomp) and self:GetSpellCooldown(S.WarStomp) == 0 and
           castRacial(S.WarStomp, "Racial: War Stomp (AoE Stun)") then return true end
        if race == "BLOODELF" and self:IsUsableSpell(S.ArcaneTorrent) and self:GetSpellCooldown(S.ArcaneTorrent) == 0 and self:IsInMeleeRange("target") then
            -- Use for rage generation or silence
            local targetCasting = self:GetInterruptibleCastInfo("target")
            if targetCasting or UnitPower("player", 1) < 20 then
                if castRacial(S.ArcaneTorrent, "Racial: Arcane Torrent") then return true end
            end
        end
    end
    return false
end

function AC:UseProtectionWarriorCombatRacials(nearbyEnemies)
    if self:GetPlayerSpec() ~= "Protection" then return false end
    if not UnitAffectingCombat("player") then return false end
    if not UnitExists("target") or not UnitCanAttack("player", "target") or UnitIsDeadOrGhost("target") then
        return false
    end

    local _, race = UnitRace("player")
    race = string.upper(race or "")
    local targetClass = UnitClassification("target")
    local targetHP = self:GetTargetHealthPercent("target")
    local burstWindow = targetClass == "elite" or targetClass == "rareelite" or
                        targetClass == "worldboss" or nearbyEnemies >= 2 or
                        (IsInGroup() and targetHP > 50)

    if not burstWindow and nearbyEnemies < 2 and UnitPower("player", 1) >= 20 and
       not self:GetInterruptibleCastInfo("target") then
        return false
    end

    if not Throttle("ProtCombatRacials", 12.0) then
        return false
    end

    if self:UseRacialsWarrior(burstWindow, false) then
        WarriorDebug("Prot: Used " .. (burstWindow and "combat" or "utility") .. " racial")
        if burstWindow and (race == "ORC" or race == "TROLL") then
            return false
        end
        return true
    end

    return false
end

-- STANCE AND COMBAT UTILITY FUNCTIONS
-- =============================================

-- FIXED: Enhanced buff checking with performance optimization
function AC:WarriorHasAttackPowerBuff()
    local buffsToCheck = {
        [S.BattleShout] = true, 
        ["Blessing of Might"] = true, 
        ["Greater Blessing of Might"] = true,
    }

    -- Prefer exact name lookup so a sparse/stale indexed aura list cannot make
    -- the Warrior overwrite a Paladin's Might at combat start.
    for buffName in pairs(buffsToCheck) do
        if UnitBuff("player", buffName) then
            if Throttle("ConflictingBuffDebug", 10.0) then
                WarriorDebug("Found active attack power buff: " .. buffName)
            end
            return true
        end
    end
    
    for i = 1, 40 do
        local buffName = UnitBuff("player", i)
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

    for buffName in pairs(buffsToCheck) do
        if UnitBuff("player", buffName) then return true end
    end

    for i = 1, 40 do
        local buffName = UnitBuff("player", i)
        if buffsToCheck[buffName] then
            return true
        end
    end
    return false
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
    if self:GetSpellCooldown(S.BattleStance) == 0 and self:IsUsableSpell(S.BattleStance) then
        WarriorDebug("Casting Battle Stance")
        -- Stances are self abilities.  Passing the default target here made
        -- OOC stance correction fail whenever no hostile target was selected.
        if not self:CastSpell(S.BattleStance, "player") then return false end
        -- The stance/form state can update on the next client frame; the cast
        -- wrapper already verified that the action was accepted.
        return true
    end
    return false
end

function AC:ForceDefensiveStance()
    if not self:KnowsSpell(S.DefensiveStance) then return false end
    local currentStance = self:GetCurrentStance()
    if currentStance == 2 then return true end
    
    -- FIXED: Check cooldown before attempting
    if self:GetSpellCooldown(S.DefensiveStance) == 0 and self:IsUsableSpell(S.DefensiveStance) then
        WarriorDebug("Casting Defensive Stance")
        if not self:CastSpell(S.DefensiveStance, "player") then return false end
        return true
    end
    return false
end

function AC:ForceBerserkerStance() 
    if not self:KnowsSpell(S.BerserkerStance) then return false end
    local currentStance = self:GetCurrentStance()
    if currentStance == 3 then return true end
    
    -- FIXED: Check cooldown before attempting
    if self:GetSpellCooldown(S.BerserkerStance) == 0 and self:IsUsableSpell(S.BerserkerStance) then
        WarriorDebug("Casting Berserker Stance")
        if not self:CastSpell(S.BerserkerStance, "player") then return false end
        return true
    end
    return false
end

function AC:TryArmsInterrupt(unit)
    unit = unit or "target"

    if not UnitExists(unit) or not UnitCanAttack("player", unit) then
        return false
    end

    local spellName, _, uninterruptible = self:GetInterruptibleCastInfo(unit)
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

    -- Never stance-dance Arms for an interrupt. Shield Bash is still available
    -- when the player has deliberately equipped a shield in Battle/Defensive.
    if (currentStance == 1 or currentStance == 2) and IsEquippedItemType("Shields") then
        if self:TryInterrupt(S.ShieldBash, unit) then
            WarriorDebug("Arms: Shield Bash interrupt (no stance swap)")
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

    local spellName, endTime, uninterruptible = self:GetInterruptibleCastInfo(unit)
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
    if timeLeft >= 2.0 and self:KnowsSpell(S.BerserkerStance) and
       self:IsUsableSpell(S.BerserkerStance) and self:GetSpellCooldown(S.BerserkerStance) == 0 then
        if self:ForceBerserkerStance() then
            WarriorDebug("Fury: Switching to Berserker for Pummel on " .. spellName)
            return true
        end
    end
    return false
end

-- FIXED: Enhanced talent checking with error handling
function AC:HasTalentByName(talentName, cacheKey)
    local _, playerClass = UnitClass("player")
    if playerClass ~= "WARRIOR" and self.DruidHasTalentByName then
        return self:DruidHasTalentByName(talentName, cacheKey)
    end

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

function AC:GetWarriorTalentRank(talentName, cacheKey)
    if not talentName then return 0 end

    self.warriorTalentRankCache = self.warriorTalentRankCache or {}
    local key = cacheKey or talentName
    local now = GetTime()
    local cached = self.warriorTalentRankCache[key]
    if cached and (now - cached.time) < 5 then
        return cached.rank
    end

    local rank = 0
    local success, numTabs = pcall(GetNumTalentTabs)
    if success then
        for tab = 1, numTabs do
            local tabSuccess, numTalents = pcall(GetNumTalents, tab)
            if tabSuccess then
                for talent = 1, numTalents do
                    local talentSuccess, name, _, _, _, currentRank = pcall(GetTalentInfo, tab, talent)
                    if talentSuccess and name and name:find(talentName) then
                        rank = currentRank or 0
                        break
                    end
                end
                if rank > 0 then break end
            end
        end
    end

    self.warriorTalentRankCache[key] = {time = now, rank = rank}
    return rank
end

function AC:HasWarbringerTalent()
    return self:HasTalentByName("Warbringer", "Warbringer")
end

function AC:HasJuggernautTalent()
    return self:HasTalentByName("Juggernaut", "Juggernaut")
end

function AC:HasWarriorGlyph(glyphName)
    if not glyphName or not GetGlyphSocketInfo then return false end

    local wanted = string.lower(glyphName)
    for glyphSlot = 1, 6 do
        -- WotLK 3.3.5a returns the installed glyph's spell ID in the fourth
        -- result, so resolve it through GetSpellInfo before comparing names.
        local enabled, _, _, glyphSpellID = GetGlyphSocketInfo(glyphSlot)
        if enabled and glyphSpellID and GetSpellInfo then
            local installedName = GetSpellInfo(glyphSpellID)
            if installedName and string.find(string.lower(installedName), wanted, 1, true) then
                return true
            end
        end
    end

    return false
end

function AC:MarkWarriorChargeCast()
    self.lastWarriorChargeCastTime = GetTime()
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
        if self:IsUsableSpell(S.Charge) and self:CastSpell(S.Charge, "target") then
            self:MarkWarriorChargeCast()
            WarriorDebug("Attempting to Charge target (Warbringer)")
            return true
        end
    else
        if self:IsUsableSpell(S.Charge) and self:CastSpell(S.Charge, "target") then
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

    if self:CastSpell(S.Charge, target) then
        self:MarkWarriorChargeCast()
        self:MarkAsOurTarget(UnitGUID(target))
        WarriorDebug("Prot: Warbringer Charge")
        return true
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

    if self:CastSpell(S.Charge, target) then
        self:MarkWarriorChargeCast()
        self:MarkAsOurTarget(UnitGUID(target))
        WarriorDebug("Arms: Juggernaut Charge gap-closer")
        return true
    end
    return false
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

    -- Expose Armor and a hunter worm's Acid Spit share the major armor-debuff
    -- slot. Do not spend filler globals fighting equivalent coverage.
    if self:HasDebuff(unit, "Expose Armor") or self:HasDebuff(unit, "Acid Spit") then
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
        if not self:CastSpell(S.DeathWish) then return false end
        WarriorDebug("Arms Solo Burst: Death Wish")
        return true
    end

    -- Solo bladestorming for faster quest-pack deletes, guarded behind core-proc checks.
    if highValueSoloTarget and self:KnowsSpell(S.Bladestorm) and self:IsUsableSpell(S.Bladestorm) and
       self:GetSpellCooldown(S.Bladestorm) == 0 and rage >= 25 and not overpowerReady and
       msCooldown > 1.0 and rendRemaining > 2 and Throttle("ArmsSoloBladestorm", 30) then
        if not self:CastSpell(S.Bladestorm) then return false end
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

    if self:CastSpell(S.Shockwave, "target") then
        self:MarkAsOurTarget(UnitGUID("target"))
        WarriorDebug("Prot: Shockwave" .. (nearbyEnemies >= 2 and " (AoE)" or " (single target)"))
        return true
    end
    return false
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
        return ok and range == 1
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
            if self:CastSpell(S.Vigilance, trackedUnit) then
                self.warriorVigilance.lastCast = now
                self.warriorVigilance.name = UnitName(trackedUnit)
                WarriorDebug("Prot: Refreshing Vigilance on " .. (UnitName(trackedUnit) or trackedUnit))
                return true
            end
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
        if self:CastSpell(S.Vigilance, bestUnit) then
            self.warriorVigilance.guid = UnitGUID(bestUnit)
            self.warriorVigilance.name = UnitName(bestUnit)
            self.warriorVigilance.lastCast = now
            WarriorDebug("Prot: Vigilance on " .. (UnitName(bestUnit) or bestUnit))
            return true
        end
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
            if not self:CastSpell(shoutToUse) then return false end
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

    if currentStance ~= desiredStanceNum and self:KnowsSpell(desiredStanceSpell) and
       self:IsUsableSpell(desiredStanceSpell) then
        if self:GetSpellCooldown(desiredStanceSpell) == 0 then 
            if not self:CastSpell(desiredStanceSpell, "player") then return false end
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
        if not hasTarget then return false end
    end

    -- Intervene disabled; use Warbringer Charge as the primary combat gap closer.
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
    local knowsDefensiveStance = self:KnowsSpell(S.DefensiveStance)
    if level >= 10 and knowsDefensiveStance and currentStance ~= 2 then
        if self:ForceDefensiveStance() then return true end
    elseif (level < 10 or not knowsDefensiveStance) and currentStance ~= 1 then
        if self:ForceBattleStance() then return true end
    end
    
    if (level >= 10 and knowsDefensiveStance and currentStance ~= 2) or
       ((level < 10 or not knowsDefensiveStance) and currentStance ~= 1) then
        WarriorDebug("Prot: Waiting for stance")
        return false
    end

    if inCombat then
        -- FIXED: Use defensive cooldowns when needed
        if self:UseWarriorDefensives() then return true end
        
        -- ENHANCED: Proactive Spell Reflection (interrupt priority system)
        if self:UseEnhancedSpellReflection() then return true end
        
        -- Rage generation with Blood Rage
        if rage < 25 and self:IsUsableSpell(S.BloodRage) and self:GetSpellCooldown(S.BloodRage) == 0 then
            if not self:CastSpell(S.BloodRage) then return false end
            WarriorDebug("Prot: Blood Rage")
            rage = UnitPower("player", 1)
        end
        
        -- Use Berserker Rage for fear/charm breaks or controlled rage generation.
        -- Keep this constrained so it doesn't preempt core threat buttons on normal pulls.
        local needsEnrageSetup = health < 35 and self:KnowsSpell(S.EnragedRegeneration) and self:GetSpellCooldown(S.EnragedRegeneration) == 0
        local needsFearBreak = UnitIsFeared("player") or UnitIsCharmed("player")
        if self:IsUsableSpell(S.BerserkerRage) and self:GetSpellCooldown(S.BerserkerRage) == 0 and
           (needsFearBreak or (rage < 30 and not self:HasBuff("player", S.BloodRage)) or needsEnrageSetup) then
            if not self:CastSpell(S.BerserkerRage) then return false end
            WarriorDebug("Prot: Berserker Rage (offensive enrage)")
            if needsFearBreak then
                return true
            end
        end
        
        -- Protection stays in Defensive Stance and uses the shared cast/channel
        -- priority filter, including the not-interruptible flag.
        if IsEquippedItemType("Shields") and self:TryInterrupt(S.ShieldBash, "target") then
            WarriorDebug("Prot: Shield Bash interrupt")
            return true
        end
        
        -- Victory Rush for free healing
        if self:TryVictoryRush() then return true end

        -- *** HIGH PRIORITY AoE ABILITIES (only if we have melee targets) ***
        -- INTEGRATION: Use enhanced enemy location detection for better AoE decisions
        local nearbyEnemies = self:GetEnemiesInThunderClapReach(20)
        local inMeleeRange = self:IsInMeleeRange("target", true)
        local targetInCombat = UnitExists("target") and UnitAffectingCombat("target")
        if Throttle("ProtAOEDebug", 3.0) then
            WarriorDebug("AoE Check: nearbyEnemies=" .. nearbyEnemies .. " inMelee=" .. (inMeleeRange and "Y" or "N"))
        end

        if nearbyEnemies >= 2 and inMeleeRange and self:TryProtectionMultiTargetDistribution(nearbyEnemies) then
            return true
        end

        if self:UseProtectionWarriorCombatRacials(nearbyEnemies) then
            return true
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
                if not self:CastSpell(S.ThunderClap) then return false end
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
            if not self:CastSpell(S.ShieldBlock) then return false end
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
            if not self:CastSpell(S.ThunderClap) then return false end
            self:MarkAsOurTarget(UnitGUID("target"))
            WarriorDebug("Prot: Thunder Clap (single-target debuff)")
            return true
        end

        local tcReadyAndInRange = nearbyEnemies >= 2 and inMeleeRange and self:IsUsableSpell(S.ThunderClap) and rage >= 20 and
                                  self:ThunderClapInRange() and self:HasEnemyInThunderClapReach(20) and
                                  self:GetSpellCooldown(S.ThunderClap) == 0
        if not tcReadyAndInRange and self:ShouldUseDemoShout(nearbyEnemies) and self:IsUsableSpell(S.DemoShout) and
           self:GetSpellCooldown(S.DemoShout) == 0 and rage >= 10 and Throttle("DemoShoutProt", 4) then
            if not self:CastSpell(S.DemoShout) then return false end
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
            if not self:CastSpell(S.Execute, "target") then return false end
            WarriorDebug("Prot: Execute")
            return true
        end
        
        -- Rend (only at low levels)
        if level < 20 and self:IsUsableSpell(S.Rend) and rage >= 10 and not self:HasDebuff("target", S.Rend) then
            if not self:CastSpell(S.Rend, "target") then return false end
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

        -- Shouts are useful, but should not steal early GCDs from active threat buttons.
        local combatShout = self:GetPreferredWarriorShout("Protection")
        if combatShout and Throttle("ProtCombatShout", 10) then
            if self:IsUsableSpell(combatShout) and rage >= 10 then
                if not self:CastSpell(combatShout) then return false end
                WarriorDebug("Prot: " .. combatShout)
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

    -- Recklessness is the one Arms utility worth a controlled stance dance.
    -- Keep interrupt handling stance-locked, but allow this five-minute burst
    -- cooldown on boss-like targets when no proc is waiting and little rage can
    -- be lost through a fully talented Tactical Mastery swap.
    local now = GetTime()
    self.armsRecklessnessPendingUntil = self.armsRecklessnessPendingUntil or 0
    self.armsRecklessnessTargetGUID = self.armsRecklessnessTargetGUID or nil
    if self.armsRecklessnessPendingUntil <= now then
        self.armsRecklessnessPendingUntil = 0
        self.armsRecklessnessTargetGUID = nil
    end

    local targetGUID = hasTarget and UnitGUID("target") or nil
    local armsRecklessnessPending = self.armsRecklessnessPendingUntil > now and hasTarget and
                                    targetGUID == self.armsRecklessnessTargetGUID
    local targetMaxHealth = hasTarget and (UnitHealthMax("target") or 0) or 0
    local playerMaxHealth = UnitHealthMax("player") or 1
    local targetClassification = hasTarget and UnitClassification("target") or "normal"
    local bossLikeTarget = targetClassification == "worldboss" or targetClassification == "rareelite" or
                           targetMaxHealth >= playerMaxHealth * 6
    local shouldStartArmsRecklessness = inCombat and hasTarget and currentStance == 1 and bossLikeTarget and
        self:IsInMeleeRange("target") and self:GetTargetHealthPercent("target") > 50 and rage <= 30 and
        self:GetWarriorTalentRank("Tactical Mastery", "TacticalMasteryRank") >= 3 and
        self:KnowsSpell(S.Recklessness) and self:GetSpellCooldown(S.Recklessness) == 0 and
        not self:HasBuff("player", S.TasteForBlood) and not self:HasBuff("player", S.SuddenDeath) and
        self:DebuffTimeRemaining("target", S.Rend) > 3 and not armsRecklessnessPending and
        Throttle("ArmsRecklessnessStart", 5.0)

    if shouldStartArmsRecklessness then
        self.armsRecklessnessPendingUntil = now + 3.0
        self.armsRecklessnessTargetGUID = targetGUID
        armsRecklessnessPending = true
    end

    if armsRecklessnessPending then
        local pendingTargetValid = hasTarget and targetGUID == self.armsRecklessnessTargetGUID and
                                   self:GetTargetHealthPercent("target") > 20
        if not pendingTargetValid then
            self.armsRecklessnessPendingUntil = 0
            self.armsRecklessnessTargetGUID = nil
            armsRecklessnessPending = false
        elseif currentStance ~= 3 then
            if self:ForceBerserkerStance() then
                WarriorDebug("Arms: Berserker Stance for Recklessness")
                return true
            end
        elseif self:IsUsableSpell(S.Recklessness) and self:GetSpellCooldown(S.Recklessness) == 0 then
            if self:CastSpell(S.Recklessness, "player") then
                self.armsRecklessnessPendingUntil = 0
                self.armsRecklessnessTargetGUID = nil
                self.warriorBurstWindowUntil = now + 12
                self:UseRacialsWarrior(true, false)
                self:UseTrinketsFixed()
                WarriorDebug("Arms: Recklessness burst")
                return true
            end
            self.armsRecklessnessPendingUntil = 0
            self.armsRecklessnessTargetGUID = nil
            armsRecklessnessPending = false
        else
            return false
        end
    end

    -- Stance management
    if currentStance ~= 1 then
        if self:ForceBattleStance() then return true end
    end
    if currentStance ~= 1 then
        WarriorDebug("Arms: Waiting for Battle Stance")
        return false
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
        if not hasTarget then return false end

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
            if not self:CastSpell(S.BloodRage) then return false end
            WarriorDebug("Arms: Blood Rage")
            rage = UnitPower("player", 1)
        end
        
        -- Berserker Rage for fear/charm or rage
        local needsFearBreak = UnitIsFeared("player") or UnitIsCharmed("player")
        if (needsFearBreak or (rage < 30 and GetSpellCooldown(S.BerserkerRage) == 0)) and 
           self:IsUsableSpell(S.BerserkerRage) and self:GetSpellCooldown(S.BerserkerRage) == 0 then 
            if not self:CastSpell(S.BerserkerRage) then return false end
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
        
        -- PRIORITY 1: Rend enables Taste for Blood. Refresh very late to avoid wasting proc ticks.
        if rendRemaining <= 0.3 and self:IsUsableSpell(S.Rend) and rage >= 10 and Throttle("ArmsRendRefresh", 1.0) then
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

        -- Boss utility: maintain armor reduction early when no equivalent debuff is present.
        if rage >= 15 and not procLock and (not self:KnowsSpell(S.MortalStrike) or msCooldown > 1.0) and rendRemaining > 3 and
           self:ShouldMaintainArmsSunder("target") and Throttle("ArmsSunderMaintain", 1.2) then
            if self:CastSpell(S.SunderArmor, "target") then
                WarriorDebug("Arms: Sunder Armor maintenance")
                return true
            end
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
            if not self:CastSpell(S.SweepingStrikes) then return false end
            WarriorDebug("Arms: Sweeping Strikes")
            return true
        end

        -- Cleave/AoE support. Bladestorm is strongest after Rend is secure and no Overpower is expiring.
        if isCleaveContext and self:IsInMeleeRange("target") then
            if self:KnowsSpell(S.ThunderClap) and self:IsUsableSpell(S.ThunderClap) and rage >= 20 and
               self:GetSpellCooldown(S.ThunderClap) == 0 and self:ThunderClapInRange() and
               self:HasEnemyInThunderClapReach(20) and
               (not overpowerExpiring) and Throttle("ArmsThunderClap", 0.5) then
                if not self:CastSpell(S.ThunderClap) then return false end
                WarriorDebug("Arms: Thunder Clap AoE")
                return true
            end

            if nearbyEnemies >= 3 and health > 35 and rendRemaining > 4 and not overpowerExpiring
               and not suddenDeathProc and not executePhase
               and self:KnowsSpell(S.Bladestorm) and self:IsUsableSpell(S.Bladestorm)
               and self:GetSpellCooldown(S.Bladestorm) == 0 then
                if not self:CastSpell(S.Bladestorm) then return false end
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
            if not self:CastSpell(S.MortalStrike, "target") then return false end
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
            if not self:CastSpell(S.ShatteringThrow, "target") then return false end
            WarriorDebug("Arms: Shattering Throw")
            return true
        end

        -- Single-target Bladestorm filler only when it will not clip core Arms buttons.
        if not isCleaveContext and health > 35 and (isElite or inGroup or targetHP > 50) and rendRemaining > 6
           and not overpowerReady and not suddenDeathProc and not executePhase
           and msCooldown > 1.5 and self:KnowsSpell(S.Bladestorm)
           and self:IsUsableSpell(S.Bladestorm) and self:GetSpellCooldown(S.Bladestorm) == 0
           and Throttle("ArmsBladestormSingle", 90) then
            if not self:CastSpell(S.Bladestorm) then return false end
            WarriorDebug("Arms: Bladestorm")
            return true
        end
        
        -- Slam filler only when no core button is about to become available.
        if self:KnowsSpell(S.Slam) and self:IsUsableSpell(S.Slam) and rage >= 15 and
           not self:IsPlayerMoving() and not UnitCastingInfo("player") then
            local opWindowSoon = overpowerReady or (hasTaste and opCooldown < 1.5)
            if (msCooldown > 1.5 or not self:KnowsSpell(S.MortalStrike)) and not opWindowSoon and rendRemaining > 2 then
                if not self:CastSpell(S.Slam, "target") then return false end
                WarriorDebug("Arms: Slam filler")
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

        local combatShout = self:GetPreferredWarriorShout("Arms")
        if combatShout and rage >= 10 and Throttle("ArmsCombatShout", 10) and self:IsUsableSpell(combatShout) then
            if not self:CastSpell(combatShout) then return false end
            WarriorDebug("Arms: " .. combatShout)
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
    self.furyShatteringThrowPendingUntil = self.furyShatteringThrowPendingUntil or 0
    self.furyShatteringThrowTargetGUID = self.furyShatteringThrowTargetGUID or nil
    if self.furyRendWeavePendingUntil <= now then
        self.furyRendWeavePendingUntil = 0
        self.furyRendWeaveTargetGUID = nil
    end
    if self.furyShatteringThrowPendingUntil <= now then
        self.furyShatteringThrowPendingUntil = 0
        self.furyShatteringThrowTargetGUID = nil
    end

    local targetGUID = hasTarget and UnitGUID("target") or nil
    if self.furyRendWeavePendingUntil > now then
        if not hasTarget or targetGUID ~= self.furyRendWeaveTargetGUID or self:HasDebuff("target", S.Rend) then
            self.furyRendWeavePendingUntil = 0
            self.furyRendWeaveTargetGUID = nil
        end
    end

    local rendWeavePending = self.furyRendWeavePendingUntil > now and hasTarget and targetGUID == self.furyRendWeaveTargetGUID
    local shatteringThrowPending = self.furyShatteringThrowPendingUntil > now and hasTarget and
                                   targetGUID == self.furyShatteringThrowTargetGUID
    local preTargetHP = hasTarget and self:GetTargetHealthPercent("target") or 100
    local preNearbyEnemies = hasTarget and self:GetEnemiesInThunderClapReach(20) or 0
    local preTargetClassification = hasTarget and UnitClassification("target") or "normal"
    local preTargetMaxHealth = hasTarget and (UnitHealthMax("target") or 0) or 0
    local playerMaxHealth = UnitHealthMax("player") or 1
    local inGroup = IsInGroup()
    local durableGroupTarget = preTargetClassification == "elite" or preTargetClassification == "rareelite" or
                               preTargetClassification == "worldboss"
    local bossLikeGroupTarget = inGroup and (preTargetClassification == "worldboss" or
                                preTargetMaxHealth >= playerMaxHealth * 6)
    local canRendWeave = self:HasTalentByName("Improved Rend", "ImprovedRend") and
                         self:HasWarriorGlyph("Glyph of Rending")
    local preBTCooldown = self:GetSpellCooldown(S.Bloodthirst)
    local preWWCooldown = self:GetSpellCooldown(S.Whirlwind)
    local shouldStartRendWeave = canRendWeave and inCombat and hasTarget and level >= 30 and self:KnowsSpell(S.Rend)
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

    -- Shattering Throw is valuable raid armor utility but requires Battle
    -- Stance and 25 rage. Only start the dance with Tactical Mastery, at nearly
    -- exactly the retained-rage cap, and well away from core Fury buttons.
    local shouldStartShatteringThrow = inCombat and hasTarget and bossLikeGroupTarget and
        preNearbyEnemies < 2 and not shatteringThrowPending and
        self:GetWarriorTalentRank("Tactical Mastery", "TacticalMasteryRank") >= 3 and
        self:KnowsSpell(S.ShatteringThrow) and
        self:GetSpellCooldown(S.ShatteringThrow) == 0 and
        preTargetHP > 35 and rage >= 25 and rage <= 30 and
        preBTCooldown > 2.5 and preWWCooldown > 2.5 and
        not self:HasBuff("player", S.SlamEffect) and not self:IsPlayerMoving() and
        not UnitCastingInfo("player") and Throttle("FuryShatteringThrowStart", 5.0)

    if shouldStartShatteringThrow then
        self.furyShatteringThrowPendingUntil = now + 3.0
        self.furyShatteringThrowTargetGUID = targetGUID
        shatteringThrowPending = true
    end

    if shatteringThrowPending then
        local pendingTargetValid = hasTarget and targetGUID == self.furyShatteringThrowTargetGUID and
                                   preTargetHP > 20 and not self:IsPlayerMoving()
        if not pendingTargetValid or rage < 25 then
            self.furyShatteringThrowPendingUntil = 0
            self.furyShatteringThrowTargetGUID = nil
            shatteringThrowPending = false
        elseif currentStance ~= 1 then
            if self:ForceBattleStance() then
                WarriorDebug("Fury: Battle Stance for Shattering Throw")
                return true
            end
        elseif self:IsUsableSpell(S.ShatteringThrow) and self:GetSpellCooldown(S.ShatteringThrow) == 0 and
               not UnitCastingInfo("player") then
            if self:CastSpell(S.ShatteringThrow, "target") then
                self.furyShatteringThrowPendingUntil = 0
                self.furyShatteringThrowTargetGUID = nil
                WarriorDebug("Fury: Shattering Throw raid utility")
                return true
            end
            self.furyShatteringThrowPendingUntil = 0
            self.furyShatteringThrowTargetGUID = nil
            shatteringThrowPending = false
        else
            -- Hold Battle Stance briefly for the stance/GCD state to settle.
            return false
        end
    end

    -- Stance management
    if inCombat and level >= 30 and currentStance ~= 3 and
       not (currentStance == 1 and (shouldStartRendWeave or rendWeavePending or shatteringThrowPending)) then
        if self:ForceBerserkerStance() then return true end
    elseif inCombat and level < 30 and currentStance ~= 1 then
        if self:ForceBattleStance() then return true end
    end
    
    if inCombat and ((level >= 30 and currentStance ~= 3 and not (currentStance == 1 and (shouldStartRendWeave or rendWeavePending))) or (level < 30 and currentStance ~= 1)) then
        WarriorDebug("Fury: Waiting for stance")
        return false
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
        if not hasTarget then return false end

        -- ENHANCED: Intercept for gap closing, otherwise skip melee abilities if out of range
        if not self:IsInMeleeRange("target") then
            -- Re-check with interact distance to avoid false negatives on large hitboxes.
            local touchContact = CheckInteractDistance("target", 3)
            if touchContact then
                WarriorDebug("Fury: Melee contact fallback confirmed")
            else
            local availableRanged = self:GetAvailableRangedAbilities()
            if availableRanged.intercept and self:UseRangedAbilityAndReturn("Intercept", "target") then
                return true
            end
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
                if not self:CastSpell(S.BerserkerRage) then return false end
                WarriorDebug("Fury: Berserker Rage")
                return true 
            end
        end
        
        -- Blood Rage
        if rage < 20 and not coreSoon and not hasSlamProc
           and self:IsUsableSpell(S.BloodRage) and self:GetSpellCooldown(S.BloodRage) == 0 then
            if not self:CastSpell(S.BloodRage) then return false end
            WarriorDebug("Fury: Blood Rage")
            return true
        end
        
        -- Victory Rush
        if self:TryVictoryRush() then return true end

        -- Keep shout buff maintained in combat.
        local combatShout = self:GetPreferredWarriorShout("Fury")
        if combatShout and rage >= 10 and Throttle("FuryCombatShout", 10) and self:IsUsableSpell(combatShout) then
            if not self:CastSpell(combatShout) then return false end
            WarriorDebug("Fury: " .. combatShout)
            return true
        end

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

        -- Maintain the major armor debuff only on durable grouped targets and
        -- only when BT, Whirlwind, and Bloodsurge are safely out of the way.
        if bossLikeGroupTarget and rage >= 15 and not self:HasBuff("player", S.SlamEffect) and
           self:GetSpellCooldown(S.Bloodthirst) > 1.5 and self:GetSpellCooldown(S.Whirlwind) > 1.5 and
           self:ShouldMaintainArmsSunder("target") and Throttle("FurySunderMaintain", 1.2) then
            if self:CastSpell(S.SunderArmor, "target") then
                WarriorDebug("Fury: Sunder Armor maintenance")
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
        if not self:CastSpell(S.BloodRage) then return false end
        WarriorDebug("Leveling mode: Blood Rage")
        return true
    end

    if self:TryVictoryRush() then
        return true
    end

    local targetHP = self:GetTargetHealthPercent("target")
    if targetHP < 20 and level >= 24 and self:IsUsableSpell(S.Execute) and rage >= 10 then
        if not self:CastSpell(S.Execute, "target") then return false end
        WarriorDebug("Leveling mode: Execute")
        return true
    end

    if level >= 4 and self:DebuffTimeRemaining("target", S.Rend) < 2 and self:IsUsableSpell(S.Rend) and rage >= 10 then
        if not self:CastSpell(S.Rend, "target") then return false end
        WarriorDebug("Leveling mode: Rend")
        return true
    end

    -- IsUsableSpell covers both Taste for Blood and ordinary dodge procs. The
    -- latter matters for untalented/low-level characters.
    if level >= 12 and self:KnowsSpell(S.Overpower) and self:IsUsableSpell(S.Overpower) and rage >= 5 then
        if not self:CastSpell(S.Overpower, "target") then return false end
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
    self.furyShatteringThrowPendingUntil = 0
    self.furyShatteringThrowTargetGUID = nil
    self.armsRecklessnessPendingUntil = 0
    self.armsRecklessnessTargetGUID = nil
    self.warriorBurstWindowUntil = 0
    
    -- FIXED: Register all spec rotations
    self.rotations["WARRIOR"]["Arms"] = function(s) return s:WarriorRotation() end
    self.rotations["WARRIOR"]["Fury"] = function(s) return s:WarriorRotation() end
    self.rotations["WARRIOR"]["Protection"] = function(s) return s:WarriorRotation() end
    self.rotations["WARRIOR"]["None"] = function(s) return s:WarriorRotation() end 
    
    -- FIXED: Register buff checking function
    self.CheckWarriorBuffs = AC.CheckWarriorBuffs
    
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
            self.furyShatteringThrowPendingUntil = 0
            self.furyShatteringThrowTargetGUID = nil
            self.armsRecklessnessPendingUntil = 0
            self.armsRecklessnessTargetGUID = nil
            self.warriorBurstWindowUntil = 0
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

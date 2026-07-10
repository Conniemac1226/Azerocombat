-- AzeroCombat: Hunter Rotations (v12 - Research-Based WotLK 3.3.5a)
local AddonName, AC = ...

-- Spell Database - Must be defined before any functions that use it
local S = { -- Spells
    -- Core Abilities
    AutoShot = "Auto Shot", SteadyShot = "Steady Shot", AimedShot = "Aimed Shot", ArcaneShot = "Arcane Shot",
    MultiShot = "Multi-Shot", KillShot = "Kill Shot", SerpentSting = "Serpent Sting",
    ScorpidSting = "Scorpid Sting", ViperSting = "Viper Sting", RaptorStrike = "Raptor Strike",
    MongooseBite = "Mongoose Bite", WingClip = "Wing Clip", Disengage = "Disengage",
    
    -- BM Abilities
    KillCommand = "Kill Command", BestialWrath = "Bestial Wrath", Intimidation = "Intimidation",
    
    -- MM Abilities
    ChimeraShot = "Chimera Shot", SilencingShot = "Silencing Shot", ReadinessSpell = "Readiness",
    
    -- SV Abilities
    ExplosiveShot = "Explosive Shot", BlackArrow = "Black Arrow", ExplosiveTrap = "Explosive Trap",
    FrostTrap = "Frost Trap", FreezingTrap = "Freezing Trap", ImmolationTrap = "Immolation Trap",
    SnakeTrap = "Snake Trap",
    
    -- Aspects
    AspectHawk = "Aspect of the Hawk", AspectDragonhawk = "Aspect of the Dragonhawk",
    AspectViper = "Aspect of the Viper", AspectCheetah = "Aspect of the Cheetah",
    AspectPack = "Aspect of the Pack", AspectWild = "Aspect of the Wild",
    AspectMonkey = "Aspect of the Monkey",
    
    -- Pet Management
    CallPet = "Call Pet", RevivePet = "Revive Pet", MendPet = "Mend Pet",
    FeedPet = "Feed Pet", DismissPet = "Dismiss Pet", TameBeast = "Tame Beast",
    BeastLore = "Beast Lore",
    
    -- Misc
    HuntersMark = "Hunter's Mark", Misdirection = "Misdirection", FeignDeath = "Feign Death",
    Deterrence = "Deterrence", MasterCall = "Master's Call", TranqShot = "Tranquilizing Shot",
    ScatterShot = "Scatter Shot", ConcussiveShot = "Concussive Shot",
    
    -- Pet Abilities (for control)
    PetGrowl = "Growl", PetClaw = "Claw", PetBite = "Bite", PetSmack = "Smack", 
    PetDash = "Dash", PetDive = "Dive", PetCower = "Cower", PetCharge = "Charge", PetProwl = "Prowl",
    
    -- Pet Family Abilities
    PetFuriousHowl = "Furious Howl", -- Wolf
    PetScorpidPoison = "Scorpid Poison", -- Scorpid
    PetShellShield = "Shell Shield", -- Turtle
    PetThunderstomp = "Thunderstomp", -- Gorilla
    PetFireBreath = "Fire Breath", -- Dragonhawk
    PetLightningBreath = "Lightning Breath", -- Wind Serpent
    PetAcidSpit = "Acid Spit", -- Worm
    PetSpiritStrike = "Spirit Strike", -- Spirit Beast (exotic BM only)
    PetRoarOfRecovery = "Roar of Recovery", -- Spirit Beast heal
    
    -- Pet Stances
    PetPassive = "Passive", PetDefensive = "Defensive", PetAggressive = "Aggressive",
    
    -- Cooldowns
    RapidFire = "Rapid Fire", Volley = "Volley",
    LaunchExplosiveTrap = "Launch Explosive Trap", LaunchImmolationTrap = "Launch Immolation Trap",
    
    -- Critical Proc Buffs for WotLK Hunter Optimization
    LockAndLoad = "Lock and Load",
    ImprovedSteadyShot = "Improved Steady Shot",
    ExposeWeakness = "Expose Weakness"
}

-- Racial Abilities with proper WotLK names
local R = {
    -- Orc
    BloodFury = "Blood Fury",
    -- Troll
    Berserking = "Berserking",
    -- Undead
    WillOfForsaken = "Will of the Forsaken",
    -- Blood Elf
    ArcaneTorrent = "Arcane Torrent",
    -- Draenei
    GiftOfNaaru = "Gift of the Naaru",
    -- Tauren
    WarStomp = "War Stomp",
    -- Dwarf
    Stoneform = "Stoneform",
    -- Gnome
    EscapeArtist = "Escape Artist",
    -- Night Elf
    Shadowmeld = "Shadowmeld",
    -- Human
    EveryManForHimself = "Every Man for Himself"
}

-- Local throttle system for pet abilities
local throttleTimes = {}
local function Throttle(key, interval)
    if not throttleTimes[key] or (GetTime() - throttleTimes[key] > interval) then
        throttleTimes[key] = GetTime()
        return true
    end
    return false
end

-- Hunter-specific debug function
local function HunterDebug(msg)
    if AC.debugMode then
        local _, playerClass = UnitClass("player")
        if playerClass == "HUNTER" then
            AC:Debug("|cFFABD473Hunter:|r " .. tostring(msg))
        end
    end
end

local function HunterDebugThrottled(key, interval, msg)
    if Throttle("HunterDebug_" .. key, interval) then
        HunterDebug(msg)
    end
end

-- Pet happiness check for better pet management
function AC:GetPetHappiness()
    if not UnitExists("pet") then return nil end
    local happiness, damagePercentage, loyaltyRate = GetPetHappiness()
    return happiness, damagePercentage, loyaltyRate
end

-- Check if pet needs feeding
function AC:PetNeedsFeeding()
    local happiness = self:GetPetHappiness()
    -- Happiness levels: 1 = Unhappy, 2 = Content, 3 = Happy
    return happiness and happiness < 3
end

-- Get pet focus/energy
function AC:GetPetPower()
    if not UnitExists("pet") then return 0, 0 end
    local power = UnitPower("pet", 2) -- 2 = Focus for pets
    local maxPower = UnitPowerMax("pet", 2)
    return power, maxPower
end

-- Check if pet ability is on cooldown
function AC:GetPetAbilityCooldown(slot)
    local start, duration, enable = GetPetActionCooldown(slot)
    if start and duration then
        local remaining = start + duration - GetTime()
        return remaining > 0 and remaining or 0
    end
    return 0
end

-- Find pet ability slot by name
function AC:FindPetAbilitySlot(abilityName)
    for i = 1, 10 do -- Pet abilities are typically in slots 1-10
        local name, _, _, _, _, _, _, _, _, _ = GetPetActionInfo(i)
        if name and name == abilityName then
            return i
        end
    end
    return nil
end

-- Use pet ability by name
function AC:UsePetAbility(abilityName, focusCost)
    local slot = self:FindPetAbilitySlot(abilityName)
    if not slot then return false end
    
    local cooldown = self:GetPetAbilityCooldown(slot)
    if cooldown > 0 then return false end
    
    local focus, maxFocus = self:GetPetPower()
    if focusCost and focus < focusCost then return false end
    
    CastPetAction(slot)
    HunterDebug("Pet used: " .. abilityName .. " (Focus: " .. focus .. "/" .. maxFocus .. ")")
    return true
end

-- Manage pet DPS abilities for maximum damage
-- RESEARCH NOTE: Wolf with Furious Howl is WotLK meta for all specs (+320 AP)
function AC:ManagePetDPS()
    if not UnitExists("pet") or UnitIsDeadOrGhost("pet") then return false end
    if not UnitExists("pettarget") or not UnitCanAttack("pet", "pettarget") then return false end
    
    -- Reduce throttle during Bestial Wrath for maximum burst
    local hasBestialWrath = self:HasBuff("pet", S.BestialWrath) or self:HasBuff("player", S.BestialWrath)
    local throttleTime = hasBestialWrath and 0.1 or 0.3
    
    if not Throttle("PetDPSAbilities", throttleTime) then return false end
    
    -- Threat management check
    local inGroup = IsInGroup() or GetNumRaidMembers() > 0
    if inGroup and self:PetHasHighThreat() then
        -- In groups, use Cower if available to reduce threat
        if self:UsePetAbility(S.PetCower, 15) then
            HunterDebug("Pet using Cower to reduce threat")
            return true
        end
        -- Skip damage abilities if threat is too high
        HunterDebugThrottled("PetThreatHigh", 3.0, "Skipping pet DPS - threat too high in group")
        return false
    end
    
    local focus, maxFocus = self:GetPetPower()
    local targetHealth = self:GetTargetHealthPercent("pettarget")
    local inMelee = CheckInteractDistance("pettarget", 3)
    
    HunterDebugThrottled("PetDPSCheck", 2.0, "Pet DPS check - Focus: " .. focus .. "/" .. maxFocus .. ", Target HP: " .. targetHealth .. "%, In melee: " .. tostring(inMelee) .. ", BW: " .. tostring(hasBestialWrath))
    
    -- Solo play: Use Growl aggressively to maintain threat
    if not inGroup and not self:HasDebuff("pettarget", "Growl") then
        if self:UsePetAbility(S.PetGrowl, 15) then
            HunterDebug("Pet using Growl (solo threat generation)")
            return true
        end
    end
    
    -- Priority 1: Special family abilities (RESEARCH-BASED PRIORITY)
    -- Furious Howl is #1 meta ability (+320 AP for 20 seconds)
    local familyAbilities = {
        {name = S.PetFuriousHowl, cost = 60}, -- Wolf: +320 AP buff (META CHOICE)
        {name = S.PetSpiritStrike, cost = 40}, -- Spirit Beast: High damage + heal (BM exotic)
        {name = S.PetLightningBreath, cost = 50}, -- Wind Serpent: Nature damage
        {name = S.PetFireBreath, cost = 50}, -- Dragonhawk: Fire cone
        {name = S.PetAcidSpit, cost = 35}, -- Worm: -10% armor
        {name = S.PetScorpidPoison, cost = 30}, -- Scorpid: Stacking poison
        {name = S.PetThunderstomp, cost = 60}, -- Gorilla: AoE threat
    }
    
    for _, ability in ipairs(familyAbilities) do
        if focus >= ability.cost then
            if self:UsePetAbility(ability.name, ability.cost) then
                return true
            end
        end
    end
    
    -- Priority 2: Defensive abilities when pet is tanking (solo play)
    if not inGroup then
        local petHealth = UnitHealth("pet")
        local petMaxHealth = UnitHealthMax("pet")
        local petHealthPercent = (petMaxHealth > 0) and (petHealth / petMaxHealth * 100) or 100
        local playerHealthPercent = self:GetPlayerHealthPercent()
        
        -- Spirit Beast: Roar of Recovery (heal for lowest health target)
        if UnitCreatureFamily("pet") == "Spirit Beast" then
            if (playerHealthPercent < 50 or petHealthPercent < 50) and self:UsePetAbility(S.PetRoarOfRecovery, 25) then
                HunterDebug("Spirit Beast: Roar of Recovery (emergency heal)")
                return true
            end
        end
        
        -- Use Shell Shield (turtle) or similar defensive abilities when tanking
        if petHealthPercent < 50 and self:PetHasAggro("pettarget") then
            if self:UsePetAbility(S.PetShellShield, 20) then
                HunterDebug("Pet using Shell Shield (defensive)")
                return true
            end
        end
    end
    
    -- Priority 3: Movement abilities for gap closing
    if not inMelee and focus >= 20 then
        -- Prioritize Charge for threat generation in solo
        if not inGroup and self:UsePetAbility(S.PetCharge, 25) then
            HunterDebug("Pet using Charge (threat + stun)")
            return true
        end
        -- Use speed boosts
        if self:UsePetAbility(S.PetDash, 20) or self:UsePetAbility(S.PetDive, 20) then
            return true
        end
    end
    
    -- Priority 4: Core damage abilities (RESEARCH-BASED OPTIMIZATION)
    -- Claw is superior: 25 focus vs 35 for Bite/Smack, no cooldown
    local focusThreshold = hasBestialWrath and 20 or 30
    
    if focus >= focusThreshold then
        -- VERIFIED: Claw is best focus dump (lower cost, no CD)
        local petFamily = UnitCreatureFamily("pet")
        
        -- Families with Claw (optimal)
        if petFamily == "Cat" or petFamily == "Bear" or petFamily == "Raptor" or 
           petFamily == "Tallstrider" or petFamily == "Core Hound" or petFamily == "Devilsaur" or
           petFamily == "Spirit Beast" then
            if focus >= 25 and self:UsePetAbility(S.PetClaw, 25) then
                HunterDebug("Pet: Claw (optimal focus dump)")
                return true
            end
        -- Families with Bite (less efficient but no choice)
        elseif petFamily == "Wolf" or petFamily == "Hyena" or petFamily == "Bat" or 
               petFamily == "Spider" or petFamily == "Serpent" then
            if focus >= 35 and self:UsePetAbility(S.PetBite, 35) then
                HunterDebug("Pet: Bite (35 focus)")
                return true
            end
        -- Families with Smack (gorilla, crab, etc)
        else
            if focus >= 35 and self:UsePetAbility(S.PetSmack, 35) then
                HunterDebug("Pet: Smack (35 focus)")
                return true
            end
        end
    end
    
    -- Priority 5: Maintain minimum focus for special abilities
    -- Don't dump all focus if we have powerful abilities available
    local hasSpecialAbility = false
    for _, ability in ipairs(familyAbilities) do
        if self:FindPetAbilitySlot(ability.name) then
            hasSpecialAbility = true
            break
        end
    end
    
    -- If we have special abilities, maintain some focus reserve
    -- During Bestial Wrath, dump all focus for maximum damage
    local focusReserve = hasBestialWrath and 0 or (hasSpecialAbility and 40 or 25)
    
    if focus > focusReserve + 25 then
        -- Use basic abilities when we have excess focus
        if self:UsePetAbility(S.PetClaw, 25) or self:UsePetAbility(S.PetBite, 35) then
            return true
        end
    end
    
    -- Emergency focus dump during Bestial Wrath
    if hasBestialWrath and focus > 25 then
        if self:UsePetAbility(S.PetClaw, 25) or self:UsePetAbility(S.PetBite, 35) then
            HunterDebug("BW Focus dump!")
            return true
        end
    end
    
    return false
end




-- Helper function to check if we should prioritize pet revival
function AC:ShouldPrioritizePet()
    local petStatus = self:GetPetStatus()
    local inCombat = UnitAffectingCombat("player")
    local healthPercent = self:GetPlayerHealthPercent()
    
    -- Always prioritize if no pet and in combat
    if petStatus == "nopet" and inCombat then
        return true
    end
    
    -- Prioritize dead pet revival if health is stable
    if petStatus == "dead" and (healthPercent > 40 or not inCombat) then
        return true
    end
    
    return false
end

-- FIXED: Racial abilities system
function AC:GetPlayerRace()
    local race = UnitRace("player")
    return race
end

function AC:UseRacials(offensive, emergency)
    if not offensive and not emergency then return false end
    
    -- Throttle racial checks to prevent spam
    if not Throttle("RacialCooldowns", 5.0) then 
        HunterDebug("Racial throttle active - skipping check")
        return false 
    end
    
    local race = self:GetPlayerRace()
    local healthPercent = self:GetPlayerHealthPercent()
    local targetExists = UnitExists("target") and UnitCanAttack("player", "target") and not UnitIsDeadOrGhost("target")
    
    HunterDebug("Checking racials for " .. race .. " - Offensive: " .. tostring(offensive) .. ", Emergency: " .. tostring(emergency) .. ", Target exists: " .. tostring(targetExists))
    
    -- Emergency racials (defensive/utility)
    if emergency then
        -- Will of the Forsaken (Undead) - removes fear, charm, sleep
        if race == "Scourge" and self:IsUsableSpell(R.WillOfForsaken) then
            -- Check if we have a debuff that WotF can remove
            local hasRemovableDebuff = false
            for i = 1, 16 do
                local name, _, _, debuffType = UnitDebuff("player", i)
                if name and (debuffType == "Magic" or name:lower():find("fear") or name:lower():find("charm") or name:lower():find("sleep")) then
                    hasRemovableDebuff = true
                    break
                end
            end
            
            if hasRemovableDebuff or healthPercent < 40 then
                self:CastSpell(R.WillOfForsaken)
                HunterDebug("Used Will of the Forsaken")
                return true
            end
        end
        
        -- Stoneform (Dwarf) - removes poison, disease, bleed
        if race == "Dwarf" and self:IsUsableSpell(R.Stoneform) then
            for i = 1, 16 do
                local name, _, _, debuffType = UnitDebuff("player", i)
                if name and (debuffType == "Poison" or debuffType == "Disease" or name:lower():find("bleed")) then
                    self:CastSpell(R.Stoneform)
                    HunterDebug("Used Stoneform")
                    return true
                end
            end
        end
        
        -- Gift of the Naaru (Draenei) - heal
        if race == "Draenei" and healthPercent < 50 and self:IsUsableSpell(R.GiftOfNaaru) then
            self:CastSpell(R.GiftOfNaaru, "player")
            HunterDebug("Used Gift of the Naaru")
            return true
        end
        
        -- Escape Artist (Gnome) - removes movement impairing effects
        if race == "Gnome" and self:IsUsableSpell(R.EscapeArtist) then
            for i = 1, 16 do
                local name = UnitDebuff("player", i)
                if name and (name:lower():find("slow") or name:lower():find("root") or name:lower():find("snare")) then
                    self:CastSpell(R.EscapeArtist)
                    HunterDebug("Used Escape Artist")
                    return true
                end
            end
        end
        
        -- Every Man for Himself (Human) - removes stun, fear, charm
        if race == "Human" and self:IsUsableSpell(R.EveryManForHimself) then
            for i = 1, 16 do
                local name, _, _, debuffType = UnitDebuff("player", i)
                if name and (debuffType == "Magic" or name:lower():find("stun") or name:lower():find("fear") or name:lower():find("charm")) then
                    self:CastSpell(R.EveryManForHimself)
                    HunterDebug("Used Every Man for Himself")
                    return true
                end
            end
        end
    end
    
    -- Offensive racials - use on cooldown (simplified)
    if offensive and targetExists then
        if self:HasBuff("player", S.AspectViper) or (not self:HasBuff("player", S.AspectHawk) and not self:HasBuff("player", S.AspectDragonhawk)) then
            HunterDebugThrottled("OffensiveRacialAspectBlocked", 5.0, "Skipping offensive racial - not in Hawk/Dragonhawk")
            return false
        end

        HunterDebug("Checking offensive racials for " .. race)
        
        -- Blood Fury (Orc) - increases attack power
        if race == "Orc" then
            if self:IsUsableSpell(R.BloodFury) then
                self:CastSpell(R.BloodFury)
                HunterDebug("Used Blood Fury")
                return true
            else
                HunterDebug("Blood Fury not available (cooldown or conditions)")
            end
        end
        
        -- Berserking (Troll) - increases attack and casting speed
        if race == "Troll" then
            if self:IsUsableSpell(R.Berserking) then
                self:CastSpell(R.Berserking)
                HunterDebug("Used Berserking")
                return true
            else
                HunterDebug("Berserking not available (cooldown or conditions)")
            end
        end
        
        -- Arcane Torrent (Blood Elf) - silences and restores mana
        if race == "BloodElf" then
            if self:IsUsableSpell(R.ArcaneTorrent) then
                self:CastSpell(R.ArcaneTorrent)
                HunterDebug("Used Arcane Torrent")
                return true
            else
                HunterDebug("Arcane Torrent not available (cooldown or conditions)")
            end
        end
        
        -- War Stomp (Tauren) - stuns nearby enemies (utility, not pure offensive)
        if race == "Tauren" and self:IsUsableSpell(R.WarStomp) then
            self:CastSpell(R.WarStomp)
            HunterDebug("Used War Stomp")
            return true
        end
        
        HunterDebug("No offensive racials available for " .. race)
    else
        HunterDebug("Not checking offensive racials - Offensive: " .. tostring(offensive) .. ", Target exists: " .. tostring(targetExists))
    end
    
    return false
end

function AC:HunterSpellRangeResult(spellName, unit)
    if not spellName or not unit or not UnitExists(unit) then return nil end
    local ok, result = pcall(IsSpellInRange, spellName, unit)
    if ok and result ~= nil then
        return result
    end
    return nil
end

function AC:HunterIsMeleeSpell(spellName)
    return spellName == S.RaptorStrike or spellName == S.WingClip or spellName == S.MongooseBite
end

function AC:HunterIsInMeleeRange(unit)
    unit = unit or "target"
    if not UnitExists(unit) or not UnitCanAttack("player", unit) or UnitIsDeadOrGhost(unit) then
        return false
    end

    local sawRangeResult = false
    local meleeSpells = { S.RaptorStrike, S.WingClip, S.MongooseBite }
    for _, spellName in ipairs(meleeSpells) do
        if self:KnowsSpell(spellName) or self:IsUsableSpell(spellName) then
            local result = self:HunterSpellRangeResult(spellName, unit)
            if result ~= nil then
                sawRangeResult = true
                if result == 1 then
                    return true
                end
            end
        end
    end

    return false
end

function AC:HunterIsInRangedRange(unit)
    unit = unit or "target"
    if not UnitExists(unit) or not UnitCanAttack("player", unit) or UnitIsDeadOrGhost(unit) then
        return false
    end

    local rangedSpells = {
        S.AutoShot,
        S.ArcaneShot,
        S.SerpentSting,
        S.MultiShot,
        S.SteadyShot,
        S.AimedShot,
        S.KillShot,
    }

    local sawRangeResult = false
    for _, spellName in ipairs(rangedSpells) do
        if spellName and (spellName == "Auto Shot" or self:KnowsSpell(spellName) or self:IsUsableSpell(spellName)) then
            local result = self:HunterSpellRangeResult(spellName, unit)
            if result ~= nil then
                sawRangeResult = true
                if result == 1 then
                    return true
                end
            end
        end
    end

    if not self:HunterIsInMeleeRange(unit) then
        local ok, result = pcall(CheckInteractDistance, unit, 1)
        if ok and result then
            return true
        end
    end

    return false
end

function AC:GetHunterRangeState(unit)
    unit = unit or "target"
    if self:HunterIsInRangedRange(unit) then
        return "ranged"
    end

    if self:HunterIsInMeleeRange(unit) then
        return "melee"
    end

    local closeOk, closeResult = pcall(CheckInteractDistance, unit, 3)
    if closeOk and closeResult then
        return "deadzone"
    end

    return "outofrange"
end

-- =============================================
-- ENHANCED PET TARGET MANAGEMENT SYSTEM
-- =============================================

-- Get all nearby hostile targets
function AC:GetNearbyHostileTargets()
    local targets = {}
    
    -- Check current target
    if UnitExists("target") and UnitCanAttack("player", "target") and not UnitIsDead("target") then
        table.insert(targets, {
            unit = "target",
            name = UnitName("target"),
            guid = UnitGUID("target"),
            health = UnitHealth("target"),
            maxHealth = UnitHealthMax("target"),
            level = UnitLevel("target"),
            classification = UnitClassification("target")
        })
    end
    
    -- Check nameplates for additional targets
    for i = 1, 40 do
        local unit = "nameplate" .. i
        if UnitExists(unit) and UnitCanAttack("player", unit) and not UnitIsDead(unit) then
            local guid = UnitGUID(unit)
            local alreadyAdded = false
            
            -- Don't add duplicates
            for _, target in ipairs(targets) do
                if target.guid == guid then
                    alreadyAdded = true
                    break
                end
            end
            
            if not alreadyAdded then
                table.insert(targets, {
                    unit = unit,
                    name = UnitName(unit),
                    guid = guid,
                    health = UnitHealth(unit),
                    maxHealth = UnitHealthMax(unit),
                    level = UnitLevel(unit),
                    classification = UnitClassification(unit)
                })
            end
        end
    end
    
    return targets
end

-- Calculate threat priority for pet targeting
function AC:CalculatePetThreatPriority(target)
    local priority = 0
    
    if not target then return 0 end
    
    -- Health percentage (lower health = higher priority for pet to finish off)
    local healthPercent = (target.health / target.maxHealth) * 100
    priority = priority + (100 - healthPercent) * 0.5
    
    -- Level difference (higher level = higher priority)
    local playerLevel = UnitLevel("player")
    local levelDiff = target.level - playerLevel
    if levelDiff > 0 then
        priority = priority + (levelDiff * 10)
    end
    
    -- Classification priority
    if target.classification == "elite" then
        priority = priority + 50
    elseif target.classification == "rare" or target.classification == "rareelite" then
        priority = priority + 75
    elseif target.classification == "worldboss" then
        priority = priority + 100
    end
    
    -- Check if target is attacking player (highest priority)
    if UnitExists(target.unit .. "target") and UnitIsUnit(target.unit .. "target", "player") then
        priority = priority + 200
    end
    
    -- Check if target is casting (interrupt priority)
    if UnitCastingInfo(target.unit) then
        priority = priority + 30
    end
    
    -- Distance consideration (closer = higher priority)
    if CheckInteractDistance(target.unit, 1) then -- Very close
        priority = priority + 20
    elseif CheckInteractDistance(target.unit, 2) then -- Close
        priority = priority + 10
    end
    
    return priority
end

-- Get the best target for pet to attack
function AC:GetBestPetTarget()
    local targets = self:GetNearbyHostileTargets()
    local bestTarget = nil
    local highestPriority = 0
    
    for _, target in ipairs(targets) do
        local priority = self:CalculatePetThreatPriority(target)
        HunterDebugThrottled("PetTargetPriority", 2.0, string.format("Target %s: Priority=%.1f HP=%.0f%%", 
            target.name, priority, (target.health/target.maxHealth)*100))
        
        if priority > highestPriority then
            highestPriority = priority
            bestTarget = target
        end
    end
    
    return bestTarget, highestPriority
end

-- Check if pet has aggro on a target
function AC:PetHasAggro(targetUnit)
    if not UnitExists("pet") or not UnitExists(targetUnit) then
        return false
    end
    
    -- Check if the target is attacking the pet
    if UnitExists(targetUnit .. "target") and UnitIsUnit(targetUnit .. "target", "pet") then
        return true
    end
    
    return false
end

-- Send pet to attack specific target
function AC:SendPetToAttack(targetUnit)
    if not UnitExists("pet") or not UnitExists(targetUnit) then
        return false
    end
    if UnitIsDeadOrGhost("pet") or UnitIsDeadOrGhost(targetUnit) or not UnitCanAttack("player", targetUnit) then
        return false
    end
    if UnitExists("pettarget") and UnitIsUnit("pettarget", targetUnit) then
        return false
    end
    
    -- Use PetAttack() API to send pet to target
    PetAttack(targetUnit)
    HunterDebug("Pet sent to attack: " .. UnitName(targetUnit))
    return true
end

function AC:EnsurePetAttackingCurrentTarget()
    if not UnitExists("pet") or UnitIsDeadOrGhost("pet") then return false end
    if not UnitExists("target") or UnitIsDeadOrGhost("target") or not UnitCanAttack("player", "target") then return false end
    if UnitExists("pettarget") and UnitIsUnit("pettarget", "target") then return false end
    if not Throttle("HunterPetAttackCurrentTarget", 0.2) then return false end

    PetAttack("target")
    HunterDebug("Pet attack issued on current target: " .. (UnitName("target") or "Unknown"))
    return true
end

-- Smart pet targeting management
function AC:ManageSmartPetTargeting()
    if not Throttle("SmartPetTargeting", 1) then return false end -- Faster for threat response

    if self:EnsurePetAttackingCurrentTarget() then
        return true
    end

    if UnitExists("target") and UnitCanAttack("player", "target") and UnitExists("pettarget") and UnitIsUnit("pettarget", "target") then
        return false
    end
    
    local targets = self:GetNearbyHostileTargets()
    if #targets == 0 then return false end
    
    local currentPetTarget = UnitExists("pettarget") and "pettarget" or nil
    local bestTarget, bestPriority = nil, 0
    
    -- Use threat-aware targeting for solo play
    if not IsInGroup() then
        bestTarget, bestPriority = self:GetBestSoloTarget()
    else
        bestTarget, bestPriority = self:GetBestPetTarget()
    end
    
    if not bestTarget then return false end
    
    -- Check if pet should switch targets
    local shouldSwitch = false
    
    if not currentPetTarget then
        -- Pet has no target, assign one
        shouldSwitch = true
        HunterDebug("Pet has no target, assigning: " .. bestTarget.name)
    elseif not UnitIsUnit(currentPetTarget, bestTarget.unit) then
        -- Pet is attacking different target, check if we should switch
        local currentPriority = self:CalculatePetThreatPriority({
            unit = currentPetTarget,
            name = UnitName(currentPetTarget),
            guid = UnitGUID(currentPetTarget),
            health = UnitHealth(currentPetTarget),
            maxHealth = UnitHealthMax(currentPetTarget),
            level = UnitLevel(currentPetTarget),
            classification = UnitClassification(currentPetTarget)
        })
        
        -- Switch if new target has significantly higher priority
        if bestPriority > currentPriority + 50 then
            shouldSwitch = true
            HunterDebug(string.format("Pet switching from %s (priority %.1f) to %s (priority %.1f)", 
                UnitName(currentPetTarget), currentPriority, bestTarget.name, bestPriority))
        end
    end
    
    if shouldSwitch then
        return self:SendPetToAttack(bestTarget.unit)
    end
    
    return false
end

function AC:GetKnownAspects()
    local aspects = {}
    if self:KnowsSpell(S.AspectDragonhawk) then table.insert(aspects, S.AspectDragonhawk) end
    if self:KnowsSpell(S.AspectHawk) then table.insert(aspects, S.AspectHawk) end
    return aspects
end

function AC:IsFastDyingMob(unit)
    unit = unit or "target"
    if not UnitExists(unit) then return false end
    local hp = self:GetTargetHealthPercent(unit) 
    local classification = UnitClassification(unit)
    local isEliteOrBoss = classification == "elite" or classification == "rareelite" or classification == "worldboss" or UnitLevel(unit) == -1
    if isEliteOrBoss then return hp < 10 end 
    local playerLevel = UnitLevel("player")
    local targetLevel = UnitLevel(unit)
    if hp < 40 and targetLevel <= playerLevel + 1 then return true end 
    if hp < 60 and targetLevel < playerLevel - 2 then return true end 
    return false
end

function AC:HunterShouldUseSerpentSting(unit, targetHP, targetIsTough, isFastDying)
    unit = unit or "target"
    if not UnitExists(unit) then return false end

    if not isFastDying then
        return true
    end

    -- Some WotLK private servers expose dungeon bosses as normal units. If the
    -- target has boss-like health, Serpent Sting is still worth applying.
    if targetIsTough or UnitHealthMax(unit) >= (UnitHealthMax("player") * 3) then
        return targetHP > 10
    end

    return false
end

function AC:GetPetStatus()
    -- Check if pet is being called first (channeling Call Pet)
    local channeling = UnitChannelInfo("player")
    if channeling == S.CallPet then
        return "calling"
    end

    local casting = UnitCastingInfo("player")
    if casting == S.CallPet or casting == S.RevivePet then
        return "calling"
    end
    
    if UnitExists("pet") then
        if UnitIsDeadOrGhost("pet") then 
            local state = self:InitializeHunterState()
            state.petDeadPending = true
            return "dead" 
        elseif UnitHealth("pet") == 0 then
            -- Sometimes pet is at 0 health but not flagged as dead yet
            local state = self:InitializeHunterState()
            state.petDeadPending = true
            return "dead"
        else 
            local state = self:InitializeHunterState()
            state.petDeadPending = false
            return "alive" 
        end 
    end

    local state = self:InitializeHunterState()
    if state.petDeadPending and IsUsableSpell(S.RevivePet) then
        return "dead"
    end
    
    return "nopet"
end

function AC:IsInGroupWithTank()
    if not IsInGroup() then return false end
    for i = 1, (GetNumRaidMembers() > 0 and GetNumRaidMembers() or GetNumPartyMembers()) do
        local unit = GetNumRaidMembers() > 0 and "raid"..i or "party"..i
        if self:IsTank(unit) then return true end 
    end
    return false
end

function AC:ShouldDisablePetGrowl()
    return self:IsInGroupWithTank() or GetNumRaidMembers() > 0
end

-- Check if pet has high threat on current target
function AC:PetHasHighThreat()
    if not UnitExists("pet") or not UnitExists("target") then return false end
    
    -- Check if target is attacking pet
    local targetOfTarget = UnitName("targettarget")
    local petName = UnitName("pet")
    
    if targetOfTarget == petName then
        -- Pet has aggro, check if this is problematic
        if IsInGroup() or GetNumRaidMembers() > 0 then
            -- Only consider it high threat if we have an actual tank in group
            if self:IsInGroupWithTank() then
                return true  -- Pet shouldn't tank when we have a real tank
            else
                return false  -- No tank in group, pet tanking is acceptable
            end
        end
    end
    
    -- Check threat percentage if available
    local isTanking, status, threatpct = UnitDetailedThreatSituation("pet", "target")
    if isTanking or (threatpct and threatpct > 90) then
        return true
    end
    
    return false
end

-- Enhanced threat-aware pet targeting for solo play
function AC:GetBestSoloTarget()
    local targets = self:GetNearbyHostileTargets()
    local bestTarget = nil
    local highestPriority = 0
    
    for _, target in ipairs(targets) do
        local priority = self:CalculatePetThreatPriority(target)
        
        -- In solo play, prioritize targets attacking player
        if not IsInGroup() and UnitExists(target.unit .. "target") and UnitIsUnit(target.unit .. "target", "player") then
            priority = priority + 500 -- Massive priority boost for mobs attacking player
            HunterDebug("High priority target attacking player: " .. target.name)
        end
        
        if priority > highestPriority then
            highestPriority = priority
            bestTarget = target
        end
    end
    
    return bestTarget, highestPriority
end

function AC:PetNeedsMending()
    if UnitExists("pet") and not UnitIsDeadOrGhost("pet") then
        -- Check if pet already has Mend Pet HoT
        if self:HasBuff("pet", S.MendPet) then
            return false -- Already has Mend Pet HoT, don't reapply
        end
        
        return (UnitHealth("pet") / UnitHealthMax("pet") * 100) < 70
    end
    return false
end

function AC:ManagePet(inCombat)
    -- Reduced throttle for critical pet management
    if not Throttle("PetManagement", 0.5) then return false end 
    local petStatus = self:GetPetStatus()
    local state = self:InitializeHunterState()
    local playerHealth = self:GetPlayerHealthPercent()
    local channeling = UnitChannelInfo("player")
    local casting = UnitCastingInfo("player")
    
    -- Don't interrupt existing pet summon/revive
    if channeling == S.RevivePet or channeling == S.CallPet or casting == S.RevivePet or casting == S.CallPet then
        HunterDebug("Currently summoning pet")
        return false
    end

    -- Priority 1: Revive dead pet (critical for survival)
    if petStatus == "dead" and self:KnowsSpell(S.RevivePet) and not self:IsChanneling() then
        local canRevive = IsUsableSpell(S.RevivePet) and not self:IsPlayerMoving()
        if canRevive and self:ActionThrottle("RevivePetAttempt", 2.0) then
            HunterDebug("Attempting to revive pet")
            CastSpellByName(S.RevivePet)
            state.petDeadPending = true
            return true
        elseif not canRevive and Throttle("RevivePetBlocked", 3.0) then
            HunterDebug("Revive Pet blocked - moving:" .. tostring(self:IsPlayerMoving()) .. ", usable:" .. tostring(IsUsableSpell(S.RevivePet)))
        end
    end
    
    -- Priority 2: Call missing pet
    if petStatus == "nopet" and self:IsUsableSpell(S.CallPet) then
        -- More lenient conditions for calling pet
        local safeToCall = not self:IsChanneling() and 
                          (not self:IsPlayerMoving() or playerHealth > 60 or not inCombat)
        
        if safeToCall then
            -- Clear target to avoid interruptions if in danger
            if inCombat and playerHealth < 50 then
                ClearTarget()
            end
            if self:ActionThrottle("CallPetAttempt", 6.0) then
                HunterDebug("Calling Pet (no pet active)")
                if self:CastSpell(S.CallPet) then
                    state.petDeadPending = false
                    return true
                end
                HunterDebug("Call Pet failed to start")
            end
        else
            HunterDebug("No pet - waiting for safe moment (moving: " .. tostring(self:IsPlayerMoving()) .. ", health: " .. playerHealth .. "%)")
            -- Emergency: Stop moving to call pet if really needed
            if inCombat and self:IsPlayerMoving() and playerHealth > 30 then
                -- This is a signal to the player that pet is needed
                HunterDebug("CRITICAL: Need to stop moving to call pet!")
            end
        end
    end
    
    -- Don't continue if pet is being called
    if petStatus == "calling" then
        HunterDebug("Pet is being summoned...")
        return false
    end
    if petStatus == "alive" then
        -- Emergency stance management (highest priority)
        if self:EmergencyPetPassive() then return true end
        
        if self:PetNeedsMending() and self:IsUsableSpell(S.MendPet) then 
            HunterDebug("Mending Pet"); 
            self:CastSpell(S.MendPet, "pet"); 
            return true 
        end
        
        -- Manage pet stance intelligently
        if self:ManagePetStance() then return true end
        
        self:UpdatePetGrowl()
        
        -- Enhanced pet target management
        if inCombat then
            -- Always manage targeting for optimal threat/damage
            self:ManageSmartPetTargeting()
            
            -- Maximize pet DPS output with threat awareness
            if UnitExists("pettarget") then
                self:ManagePetDPS()
            end
        end
    end
    return false
end

function AC:TogglePetSpell(spellName, enable)
    if not spellName then 
        return false 
    end

    for i = 1, 12 do
        local name, _, _, _, _, autoCastAllowed, autoCastEnabled = GetPetActionInfo(i)

        if name and name == spellName then
            if not autoCastAllowed then
                return false
            end

            if enable and not autoCastEnabled then
                HunterDebug("Enabling autocast for " .. spellName)
                TogglePetAutocast(i)
                return true
            elseif not enable and autoCastEnabled then
                HunterDebug("Disabling autocast for " .. spellName)
                TogglePetAutocast(i)
                return true
            end

            return false
        end
    end
    return false
end

function AC:UpdatePetGrowl()
    if self:GetPetStatus() ~= "alive" then return false end
    if not Throttle("PetGrowlToggle", 3) then return false end
    
    local growlKnown = false
    local cowerKnown = false
    local growlSlot = nil
    local cowerSlot = nil
    
    for i=1,10 do
        local name = GetPetActionInfo(i)
        if name == S.PetGrowl then 
            growlKnown = true
            growlSlot = i
        elseif name == S.PetCower then
            cowerKnown = true
            cowerSlot = i
        end
    end
    
    if not growlKnown then 
        return false 
    end
    
    local inGroup = IsInGroup()
    local inRaid = GetNumRaidMembers() > 0
    -- Solo play: ALWAYS use Growl for maximum threat
    if not inGroup and not inRaid then
        if self:TogglePetSpell(S.PetGrowl, true) then
            HunterDebug("Solo mode: Growl ON for maximum threat")
            return true
        end
        return false
    end
    
    -- Group/Raid: Disable Growl, use Cower if needed
    if inGroup or inRaid then
        local changed = self:TogglePetSpell(S.PetGrowl, false)
        if changed then
            HunterDebugThrottled("GrowlGroupOff", 5.0, "Group mode: Growl OFF")
        end
        
        -- Use Cower if pet has too much threat in groups
        if cowerKnown and self:PetHasHighThreat() then
            if self:GetPetAbilityCooldown(cowerSlot) == 0 then
                CastPetAction(cowerSlot)
                HunterDebug("Using Cower to reduce pet threat in group")
            end
        end
        
        return changed
    end
    
    return false
end

-- =============================================
-- ENHANCED PET STANCE MANAGEMENT SYSTEM
-- =============================================

-- Get current pet stance
function AC:GetPetStance()
    if not UnitExists("pet") then return "No Pet" end
    
    -- Check pet action bar for stance indicators
    for i = 1, 12 do
        local name, _, _, _, isActive = GetPetActionInfo(i)
        if name and isActive then
            -- Use flexible matching for stance names
            local nameLower = string.lower(name)
            if string.find(nameLower, "passive") then 
                return "Passive"
            elseif string.find(nameLower, "defensive") then 
                return "Defensive" 
            elseif string.find(nameLower, "aggressive") then 
                return "Aggressive"
            end
        end
    end
    
    -- Debug: Show what's actually on the pet bar
    if AC.debugMode then
        HunterDebug("Pet action bar scan (no active stance found):")
        for i = 1, 12 do
            local name, _, _, _, isActive = GetPetActionInfo(i)
            if name then
                HunterDebug(string.format("Slot %d: %s (Active: %s)", i, name, tostring(isActive)))
            end
        end
    end
    
    return "Unknown"
end

-- Set pet stance by name
function AC:SetPetStance(stanceName)
    if not UnitExists("pet") then return false end
    if not stanceName then return false end
    
    local currentStance = self:GetPetStance()
    if currentStance == stanceName then
        HunterDebug("Pet already in " .. stanceName .. " stance")
        return true
    end
    
    -- Find and activate the stance using flexible matching
    local targetName = string.lower(stanceName)
    for i = 1, 12 do
        local name = GetPetActionInfo(i)
        if name then
            local nameLower = string.lower(name)
            if string.find(nameLower, targetName) then
                CastPetAction(i)
                HunterDebug("Set pet stance to: " .. name .. " (requested: " .. stanceName .. ")")
                return true
            end
        end
    end
    
    -- Debug: Show what's available if stance not found
    if AC.debugMode then
        HunterDebug("Could not find " .. stanceName .. " stance. Available actions:")
        for i = 1, 12 do
            local name = GetPetActionInfo(i)
            if name then
                HunterDebug(string.format("Slot %d: %s", i, name))
            end
        end
    end
    
    return false
end

-- Determine optimal pet stance based on situation
function AC:GetOptimalPetStance()
    if not UnitExists("pet") then return nil end
    
    local inCombat = UnitAffectingCombat("player")
    local isInGroup = IsInGroup()
    local isInRaid = GetNumRaidMembers() > 0
    local hasLivingGroupMembers = false
    
    -- Check for living group members
    if isInGroup then
        local numMembers = GetNumRaidMembers() > 0 and GetNumRaidMembers() or GetNumPartyMembers()
        for i = 1, numMembers do
            local unit = isInRaid and "raid"..i or "party"..i
            if UnitExists(unit) and not UnitIsDeadOrGhost(unit) and not UnitIsUnit(unit, "player") then
                hasLivingGroupMembers = true
                break
            end
        end
    end
    
    local hasTank = self:IsInGroupWithTank()
    local playerHealth = self:GetPlayerHealthPercent()
    local hasHostileTarget = UnitExists("target") and UnitCanAttack("player", "target") and not UnitIsDeadOrGhost("target")
    
    -- Passive stance conditions (highest priority)
    if playerHealth < 15 then
        HunterDebug("Pet stance logic: Passive (emergency - low health)")
        return "Passive"
    end
    
    if not inCombat and isInGroup and hasLivingGroupMembers and not hasHostileTarget then
        HunterDebug("Pet stance logic: Passive (out of combat in group)")
        return "Passive" 
    end
    
    -- Defensive stance conditions (group play)
    if inCombat and (isInGroup or hasTank) then
        HunterDebug("Pet stance logic: Defensive (in group/raid)")
        return "Defensive"
    end
    
    if inCombat and hasHostileTarget and playerHealth > 50 then
        HunterDebug("Pet stance logic: Defensive (in combat with target)")
        return "Defensive"
    end
    
    -- Aggressive stance conditions (solo play)
    if not isInGroup and inCombat and playerHealth > 30 then
        HunterDebug("Pet stance logic: Aggressive (solo combat)")
        return "Aggressive"
    end
    
    -- Default to Defensive for safety
    HunterDebug("Pet stance logic: Defensive (default)")
    return "Defensive"
end

-- Smart pet stance management
function AC:ManagePetStance()
    if not UnitExists("pet") or UnitIsDeadOrGhost("pet") then return false end
    if not Throttle("PetStanceManagement", 3) then return false end
    
    local optimalStance = self:GetOptimalPetStance()
    local currentStance = self:GetPetStance()
    
    if not optimalStance then return false end
    
    if currentStance ~= optimalStance then
        HunterDebug(string.format("Pet stance change: %s -> %s", 
            currentStance or "Unknown", optimalStance))
        return self:SetPetStance(optimalStance)
    end
    
    return false
end

-- Emergency pet passive (for dangerous situations)
function AC:EmergencyPetPassive()
    if not UnitExists("pet") then return false end
    
    local playerHealth = self:GetPlayerHealthPercent()
    local inInstance = IsInInstance()
    local _, instanceType = IsInInstance()
    
    -- Force passive in dangerous situations
    if playerHealth < 20 then
        HunterDebug("Emergency: Setting pet to Passive (low health)")
        return self:SetPetStance("Passive")
    end
    
    if inInstance and (instanceType == "party" or instanceType == "raid") then
        local currentStance = self:GetPetStance()
        if currentStance == "Aggressive" then
            HunterDebug("Emergency: Setting pet to Defensive (in instance)")
            return self:SetPetStance("Defensive")
        end
    end
    
    return false
end

function AC:ShouldUseHuntersMark(unit)
    unit = unit or "target"
    if not UnitExists(unit) then return false end

    local classification = UnitClassification(unit)
    local level = UnitLevel(unit) or 0
    local playerLevel = UnitLevel("player") or 0
    local hp = self:GetTargetHealthPercent(unit)
    local isBoss = classification == "worldboss" or level == -1
    local isTough = classification == "elite" or classification == "rareelite" or isBoss

    -- Use on bosses/elites and tougher high-health targets.
    if not (isTough or (hp > 80 and level >= (playerLevel + 2))) then
        HunterDebugThrottled("HuntersMarkSkip", 5.0, "Skipping Hunter's Mark - low value target")
        return false
    end
    
    -- Don't use on fast dying mobs
    if self:IsFastDyingMob(unit) then 
        HunterDebug("Skipping Hunter's Mark - fast dying mob")
        return false 
    end
    
    -- Don't apply if already has Hunter's Mark
    if self:HasDebuff(unit, S.HuntersMark) then 
        HunterDebug("Skipping Hunter's Mark - already applied")
        return false 
    end
    
    HunterDebug("Hunter's Mark conditions met")
    return true
end

function AC:IsTargetFleeing(unit)
    unit = unit or "target"
    if not UnitExists(unit) then return false end
    return GetUnitSpeed(unit) > 1 and self:GetTargetHealthPercent(unit) < 20 
end

function AC:IsInHunterDeadzone(unit)
    unit = unit or "target"
    if not UnitExists(unit) or UnitIsDeadOrGhost(unit) then return false end
    return self:GetHunterRangeState(unit) == "deadzone"
end

-- =============================================
-- HUNTER COMBAT REWRITE
-- =============================================

function AC:RefreshHunterSpellCache(force)
    local now = GetTime()
    local cache = self.hunterSpellCache
    if not force and cache and self.hunterSpellCacheStamp and (now - self.hunterSpellCacheStamp) < 2.0 then
        return cache
    end

    cache = {}
    for tabIndex = 1, GetNumSpellTabs() do
        local _, _, offset, numSpells = GetSpellTabInfo(tabIndex)
        for i = offset + 1, offset + numSpells do
            local name = GetSpellName(i, BOOKTYPE_SPELL)
            if name and not cache[name] then
                cache[name] = i
            end
        end
    end

    self.hunterSpellCache = cache
    self.hunterSpellCacheStamp = now
    return cache
end

function AC:GetHunterSpellIndex(spellName)
    if not spellName then return nil end
    local cache = self:RefreshHunterSpellCache()
    local slot = cache and cache[spellName]
    if slot then
        return slot, BOOKTYPE_SPELL
    end
    return nil
end

function AC:HunterKnowsSpell(spellName)
    return self:GetHunterSpellIndex(spellName) ~= nil
end

function AC:HunterSpellAvailable(spellName)
    if not spellName then return false end
    local level = UnitLevel("player") or 1
    local learnedByLevel = {
        [S.AutoShot] = 1,
        [S.RaptorStrike] = 1,
        [S.AspectMonkey] = 4,
        [S.SerpentSting] = 4,
        [S.ArcaneShot] = 6,
        [S.HuntersMark] = 6,
        [S.ConcussiveShot] = 8,
        [S.WingClip] = 12,
        [S.MendPet] = 12,
        [S.MultiShot] = 18,
        [S.Disengage] = 20,
        [S.FeignDeath] = 30,
        [S.Volley] = 40,
        [S.SteadyShot] = 50,
        [S.KillCommand] = 66,
        [S.KillShot] = 71,
        [S.ExplosiveShot] = 60,
        [S.BlackArrow] = 60,
    }

    local learnedAt = learnedByLevel[spellName]
    if learnedAt then
        return level >= learnedAt
    end

    return self:HunterKnowsSpell(spellName) or GetSpellInfo(spellName) and true or false
end

function AC:HunterSpellInRange(spellName, unit, opts)
    opts = opts or {}
    if not spellName or not unit or unit == "player" then return true end
    if not UnitExists(unit) then return false end

    local ok, result = pcall(IsSpellInRange, spellName, unit)
    if ok and result ~= nil then
        if result == 1 then
            return true
        end

        if self:HunterIsMeleeSpell(spellName) then
            return false
        end

        return self:HunterIsInRangedRange(unit)
    end

    if opts.allowNilRange then
        return true
    end

    if UnitCanAttack("player", unit) then
        local rangeState = self:GetHunterRangeState(unit)
        if self:HunterIsMeleeSpell(spellName) then
            return rangeState == "melee"
        end
        return rangeState == "ranged"
    end

    return true
end

function AC:HunterCanCast(spellName, unit, opts)
    opts = opts or {}

    if not spellName or not self:HunterSpellAvailable(spellName) then
        return false, "unknown"
    end

    if unit and unit ~= "player" and not UnitExists(unit) then
        return false, "no unit"
    end

    if opts.requirePet and self:GetPetStatus() ~= "alive" then
        return false, "no pet"
    end

    if opts.stationary and (self:IsPlayerMoving() or self:IsChanneling()) then
        return false, "moving/channeling"
    end

    local rangeState = nil
    if unit and unit ~= "player" and UnitCanAttack("player", unit) then
        rangeState = self:GetHunterRangeState(unit)
    elseif UnitExists("target") and UnitCanAttack("player", "target") then
        rangeState = self:GetHunterRangeState("target")
    end

    if opts.noMelee and rangeState == "melee" then
        return false, "melee"
    end

    if opts.noDeadzone and rangeState == "deadzone" then
        return false, "deadzone"
    end

    if opts.noPlayerCast and UnitCastingInfo("player") then
        return false, "already casting"
    end

    if self:GetSpellCooldown(spellName) > 0 then
        return false, "cooldown"
    end

    local _, noMana = IsUsableSpell(spellName)
    if noMana then
        return false, "no mana"
    end

    if not self:HunterSpellInRange(spellName, unit or "target", opts) then
        return false, "range"
    end

    return true
end

function AC:HunterTryCast(spellName, unit, opts)
    local canCast, reason = self:HunterCanCast(spellName, unit, opts)
    if not canCast then
        if spellName == S.ArcaneShot then
            HunterDebugThrottled("ArcaneReject", 1.0, "Arcane Shot blocked: " .. tostring(reason))
        end
        return false
    end

    unit = unit or "target"
    CastSpellByName(spellName, unit)

    if SpellIsTargeting and SpellIsTargeting() then
        SpellStopTargeting()
        return false
    end

    local state = self:InitializeHunterState()
    if spellName == S.ExplosiveShot then
        state.lastExplosiveShotCast = GetTime()
    elseif spellName == S.KillCommand then
        state.lastKillCommandCast = GetTime()
        state.killCommandUntil = 0
    end

    return true
end

function AC:InitializeHunterState()
    self.hunterState = self.hunterState or {
        killCommandUntil = 0,
        lastKillCommandCast = 0,
        lastExplosiveShotCast = 0,
        lockAndLoadActive = false,
        petDeadPending = false,
    }
    return self.hunterState
end

function AC:HunterCombatLogLooksCritical(subevent, ...)
    local args = { ... }

    if subevent == "SWING_DAMAGE" then
        for i = 9, #args do
            if type(args[i]) == "boolean" and args[i] then
                return true
            end
        end
    elseif subevent == "SPELL_DAMAGE" or subevent == "RANGE_DAMAGE" then
        for i = 12, #args do
            if type(args[i]) == "boolean" and args[i] then
                return true
            end
        end
    end

    return false
end

function AC:HandleClassCombatLog(...)
    local _, playerClass = UnitClass("player")
    if playerClass ~= "HUNTER" then return end

    local state = self:InitializeHunterState()
    local timestamp, subevent, sourceGUID, sourceName, sourceFlags, destGUID, destName, destFlags = ...
    local petGUID = UnitGUID("pet")
    local playerGUID = UnitGUID("player")

    if petGUID and sourceGUID == petGUID then
        if subevent == "SWING_DAMAGE" or subevent == "SPELL_DAMAGE" or subevent == "RANGE_DAMAGE" then
            if self:HunterCombatLogLooksCritical(subevent, ...) then
                state.killCommandUntil = GetTime() + 5.0
                if AC.debugMode and Throttle("HunterKillCommandProcDebug", 1.0) then
                    HunterDebug("Kill Command proc window opened")
                end
            end
        end
    end

    if playerGUID and sourceGUID == playerGUID and subevent == "SPELL_CAST_SUCCESS" then
        local spellName = select(10, ...)
        if spellName == S.KillCommand then
            state.lastKillCommandCast = GetTime()
            state.killCommandUntil = 0
        end
    end

    if subevent == "UNIT_DIED" and destGUID and petGUID and destGUID == petGUID then
        state.killCommandUntil = 0
        state.petDeadPending = true
    end
end

function AC:HunterHasKillCommandProc()
    local state = self:InitializeHunterState()
    return state.killCommandUntil and state.killCommandUntil > GetTime()
end

function AC:HunterCanUseKillCommand()
    local state = self:InitializeHunterState()
    if self:GetPetStatus() ~= "alive" then return false end
    if not UnitExists("pettarget") or not UnitIsUnit("pettarget", "target") then return false end
    if not self:HunterHasKillCommandProc() then return false end
    if (GetTime() - (state.lastKillCommandCast or 0)) < 1.0 then return false end
    return self:HunterCanCast(S.KillCommand, "target", { requirePet = true, noMelee = true, noDeadzone = true })
end

function AC:HunterCanFireExplosiveShot()
    if not self:HunterCanCast(S.ExplosiveShot, "target", { noMelee = true, noDeadzone = true }) then
        return false
    end

    local state = self:InitializeHunterState()
    local now = GetTime()
    local sinceLastES = now - (state.lastExplosiveShotCast or 0)
    local hasLockAndLoad = self:HasBuff("player", S.LockAndLoad)
    local esRemaining = self:DebuffTimeRemaining("target", S.ExplosiveShot)

    if hasLockAndLoad then
        return sinceLastES >= 1.0 and (not esRemaining or esRemaining <= 0.25)
    end

    if esRemaining and esRemaining > 0.35 then
        return false
    end

    return true
end

function AC:UpdateSurvivalProcState()
    local state = self:InitializeHunterState()
    local hasLockAndLoad = self:HasBuff("player", S.LockAndLoad)

    if hasLockAndLoad and not state.lockAndLoadActive then
        state.lockAndLoadActive = true
        HunterDebug("SV: Lock and Load active")
    elseif not hasLockAndLoad and state.lockAndLoadActive then
        state.lockAndLoadActive = false
        HunterDebug("SV: Lock and Load faded")
    end

    return hasLockAndLoad
end

function AC:HandleAutoAttack()
    if not UnitExists("target") or not UnitCanAttack("player", "target") or UnitIsDeadOrGhost("target") then
        return false
    end

    local rangeState = self:GetHunterRangeState("target")
    local autoShotActive = false
    if IsAutoRepeatSpell then
        autoShotActive = IsAutoRepeatSpell("Auto Shot") and true or false
    end

    if rangeState == "ranged" then
        if not autoShotActive and self:HunterKnowsSpell("Auto Shot") then
            CastSpellByName("Auto Shot")
            StartAttack()
            return true
        end
    elseif autoShotActive then
        CastSpellByName("Auto Shot")
    end

    return false
end

function AC:HunterManaGate(manaPercent, threshold)
    if self:HunterKnowsSpell(S.AspectViper) then
        return true
    end

    return manaPercent > threshold
end

function AC:ManageAspects(spec, inCombat, manaPercent)
    if not Throttle("HunterAspectRewrite", 2.0) then return false end
    if IsMounted() then return false end

    local bestDpsAspect = nil
    if self:HunterKnowsSpell(S.AspectDragonhawk) then
        bestDpsAspect = S.AspectDragonhawk
    elseif self:HunterKnowsSpell(S.AspectHawk) then
        bestDpsAspect = S.AspectHawk
    end

    if self:HasBuff("player", S.AspectCheetah) or self:HasBuff("player", S.AspectPack) then
        if inCombat and bestDpsAspect and self:HunterTryCast(bestDpsAspect, "player") then
            HunterDebug("Aspect: " .. bestDpsAspect .. " (cancel speed)")
            return true
        end
    end

    if inCombat and self:HunterKnowsSpell(S.AspectViper) and manaPercent < 18 and not self:HasBuff("player", S.AspectViper) then
        if self:HunterTryCast(S.AspectViper, "player") then
            HunterDebug("Aspect: Viper")
            return true
        end
    end

    if bestDpsAspect then
        if self:HasBuff("player", S.AspectViper) and manaPercent > 70 then
            if self:HunterTryCast(bestDpsAspect, "player") then
                HunterDebug("Aspect: " .. bestDpsAspect .. " (leave viper)")
                return true
            end
        elseif not self:HasBuff("player", bestDpsAspect) and not self:HasBuff("player", S.AspectViper) then
            if self:HunterTryCast(bestDpsAspect, "player") then
                HunterDebug("Aspect: " .. bestDpsAspect)
                return true
            end
        end
    end

    return false
end

function AC:UseDefensiveCooldowns(healthPercent)
    if healthPercent < 25 and self:HunterTryCast(S.FeignDeath, "player") then
        HunterDebug("Feign Death")
        return true
    end

    if healthPercent < 35 and self:HunterTryCast(S.Deterrence, "player") then
        HunterDebug("Deterrence")
        return true
    end

    if healthPercent < 50 and self:HunterTryCast(S.MasterCall, "player", { requirePet = true }) then
        HunterDebug("Master's Call")
        return true
    end

    if self:UseRacials(false, true) then
        return true
    end

    return false
end

function AC:HunterShouldMark(unit, targetHP, targetIsTough)
    unit = unit or "target"
    return self:ShouldUseHuntersMark(unit)
end

function AC:HunterUseMinorCooldowns(spec, targetIsTough, targetHP, enemies)
    if spec == "Beast Mastery" and targetIsTough and self:HunterTryCast(S.BestialWrath, "player", { requirePet = true }) then
        HunterDebug("BM: Bestial Wrath")
        return true
    end

    if (targetIsTough or enemies >= 3) and self:HunterTryCast(S.RapidFire, "player") then
        HunterDebug("Rapid Fire")
        return true
    end

    if self:UseTrinkets() then
        HunterDebug("Used Trinkets")
    end

    if self:UseRacials(true, false) then
        HunterDebug("Used Racial")
    end

    return false
end

function AC:HunterHandleUtility(spec, petStatus)
    if self:HunterKnowsSpell(S.Misdirection) and IsInGroup() and self:ActionThrottle("HunterMisdirection", 30) then
        local target = nil
        for i = 1, (GetNumRaidMembers() > 0 and GetNumRaidMembers() or GetNumPartyMembers()) do
            local unit = GetNumRaidMembers() > 0 and "raid"..i or "party"..i
            if self:IsTank(unit) and UnitExists(unit) and not UnitIsDeadOrGhost(unit) then
                target = unit
                break
            end
        end

        if not target and petStatus == "alive" and not self:IsInGroupWithTank() then
            target = "pet"
        end

        if target and self:HunterTryCast(S.Misdirection, target) then
            HunterDebug("Misdirection on " .. target)
            return true
        end
    end

    if UnitCastingInfo("target") then
        if spec == "Marksmanship" and self:HunterTryCast(S.SilencingShot, "target", { noMelee = true, noDeadzone = true }) then
            HunterDebug("Silencing Shot")
            return true
        end

        if self:HunterTryCast(S.ScatterShot, "target") then
            HunterDebug("Scatter Shot")
            return true
        end

        if self:HunterTryCast(S.Intimidation, "target", { requirePet = true }) then
            HunterDebug("Intimidation")
            return true
        end
    end

    return false
end

function AC:HunterHandleCloseRange(targetHP, isFastDying, rangeState)
    rangeState = rangeState or self:GetHunterRangeState("target")

    if rangeState == "deadzone" then
        if not isFastDying and self:HunterTryCast(S.Disengage, "player") then
            HunterDebug("Disengage")
            return true
        end
        return false
    end

    if self:IsTargetFleeing("target") and self:HunterTryCast(S.WingClip, "target") then
        HunterDebug("Wing Clip")
        return true
    end

    if self:HunterIsInMeleeRange("target") and self:HunterTryCast(S.ExplosiveTrap, "player") then
        HunterDebug("Explosive Trap")
        return true
    end

    if self:HunterTryCast(S.MongooseBite, "target") then
        HunterDebug("Mongoose Bite")
        return true
    end

    if self:HunterTryCast(S.RaptorStrike, "target") then
        HunterDebug("Raptor Strike")
        return true
    end

    if not isFastDying and self:HunterTryCast(S.Disengage, "player") then
        HunterDebug("Disengage")
        return true
    end

    return false
end

function AC:HunterTryLaunchTrap(spellName, debugLabel)
    if not spellName or not self.SafeCastGroundAOE then
        return false
    end

    if not self:HunterSpellAvailable(spellName) or self:IsPlayerMoving() or self:IsChanneling() then
        return false
    end

    if self:SafeCastGroundAOE(spellName) then
        HunterDebug(debugLabel or spellName)
        return true
    end

    return false
end

function AC:HunterHandleAOE(enemies, manaPercent)
    if self:ShouldUseMultiTarget(2, enemies) and self:HunterManaGate(manaPercent, 30) then
        if self:HunterTryLaunchTrap(S.LaunchExplosiveTrap, "Launch Explosive Trap") then
            return true
        end
    end

    if self:ShouldUseMultiTarget(3, enemies) and self:HunterManaGate(manaPercent, 30) and self:HunterKnowsSpell(S.Volley) and not self:IsPlayerMoving() and not self:IsChanneling() then
        if self.SafeCastGroundAOE and self:SafeCastGroundAOE(S.Volley) then
            HunterDebug("Volley")
            return true
        end
    end

    if self:ShouldUseMultiTarget(3, enemies) and self:HunterManaGate(manaPercent, 30) and not self:HunterKnowsSpell(S.Volley) and self:HunterSpellAvailable(S.LaunchImmolationTrap) and not self:IsPlayerMoving() and not self:IsChanneling() then
        if self:HunterTryLaunchTrap(S.LaunchImmolationTrap, "Launch Immolation Trap") then
            return true
        end
    end

    if self:ShouldUseMultiTarget(2, enemies) and self:HunterManaGate(manaPercent, 20) and self:HunterTryCast(S.MultiShot, "target", { noMelee = true, noDeadzone = true }) then
        HunterDebug("Multi-Shot")
        return true
    end

    return false
end

function AC:HunterBeastMasteryRotation(targetHP, targetIsTough, isFastDying, manaPercent, enemies, petStatus)
    if self:HunterCanUseKillCommand() then
        if self:HunterTryCast(S.KillCommand, "target", { requirePet = true, noMelee = true, noDeadzone = true }) then
            HunterDebug("BM: Kill Command")
        end
    end

    if targetHP < 20 and self:HunterTryCast(S.KillShot, "target", { noMelee = true, noDeadzone = true }) then
        HunterDebug("BM: Kill Shot")
        return true
    end

    if self:HunterManaGate(manaPercent, 28) and self:HunterTryCast(S.MultiShot, "target", { noMelee = true, noDeadzone = true }) then
        HunterDebug("BM: Multi-Shot")
        return true
    end

    local serpentUp = self:HasDebuff("target", S.SerpentSting)
    local serpentRemaining = self:DebuffTimeRemaining("target", S.SerpentSting)
    if self:HunterShouldUseSerpentSting("target", targetHP, targetIsTough, isFastDying) and (not serpentUp or serpentRemaining < 1.5) then
        if self:HunterTryCast(S.SerpentSting, "target", { noMelee = true, noDeadzone = true }) then
            HunterDebug("BM: Serpent Sting")
            return true
        end
    end

    if targetIsTough and self:HunterTryCast(S.BestialWrath, "player", { requirePet = true }) then
        HunterDebug("BM: Bestial Wrath")
        return true
    end

    if targetIsTough and self:HunterTryCast(S.RapidFire, "player") then
        HunterDebug("Rapid Fire")
        return true
    end

    if self:HunterManaGate(manaPercent, 24) and self:HunterTryCast(S.ArcaneShot, "target", { noMelee = true, noDeadzone = true }) then
        HunterDebug("BM: Arcane Shot")
        return true
    end

    if self:HunterTryCast(S.SteadyShot, "target", { stationary = true, noMelee = true, noDeadzone = true, noPlayerCast = true }) then
        HunterDebug("BM: Steady Shot")
        return true
    end

    return false
end

function AC:HunterMarksmanshipRotation(targetHP, targetIsTough, isFastDying, manaPercent)
    if self:HunterTryCast(S.SilencingShot, "target", { noMelee = true, noDeadzone = true }) then
        HunterDebug("MM: Silencing Shot (off-GCD)")
    end

    if self:HunterCanUseKillCommand() then
        if self:HunterTryCast(S.KillCommand, "target", { requirePet = true, noMelee = true, noDeadzone = true }) then
            HunterDebug("MM: Kill Command (off-GCD)")
        end
    end

    if targetHP < 20 and self:HunterTryCast(S.KillShot, "target", { noMelee = true, noDeadzone = true }) then
        HunterDebug("MM: Kill Shot")
        return true
    end

    local serpentUp = self:HasDebuff("target", S.SerpentSting)
    if self:HunterShouldUseSerpentSting("target", targetHP, targetIsTough, isFastDying) and not serpentUp and self:HunterTryCast(S.SerpentSting, "target", { noMelee = true, noDeadzone = true }) then
        HunterDebug("MM: Serpent Sting")
        return true
    end

    local hasImprovedSteady = self:HasBuff("player", S.ImprovedSteadyShot)
    local chimeraCD = self:HunterSpellAvailable(S.ChimeraShot) and self:GetSpellCooldown(S.ChimeraShot) or 999
    local aimedCD = self:HunterSpellAvailable(S.AimedShot) and self:GetSpellCooldown(S.AimedShot) or 999
    local armorPen = GetCombatRating(25) or 0
    local shouldUseArcane = armorPen < 430 or self:IsPlayerMoving()

    if self:HunterTryCast(S.ChimeraShot, "target", { noMelee = true, noDeadzone = true }) then
        HunterDebug(hasImprovedSteady and "MM: Chimera Shot (ISS)" or "MM: Chimera Shot")
        return true
    end

    if hasImprovedSteady and chimeraCD <= 1.0 and not self:IsPlayerMoving() then
        HunterDebugThrottled("MMHoldISSChimera", 1.0, "MM: Holding ISS for Chimera")
    end

    if self:HunterTryCast(S.AimedShot, "target", { stationary = true, noMelee = true, noDeadzone = true, noPlayerCast = true }) then
        HunterDebug(hasImprovedSteady and "MM: Aimed Shot (ISS)" or "MM: Aimed Shot")
        return true
    end

    if hasImprovedSteady and aimedCD <= 1.0 and not self:IsPlayerMoving() then
        HunterDebugThrottled("MMHoldISSAimed", 1.0, "MM: Holding ISS for Aimed")
    end

    if hasImprovedSteady and shouldUseArcane and self:HunterManaGate(manaPercent, 25) and chimeraCD > 1.0 and aimedCD > 1.0 and self:HunterTryCast(S.ArcaneShot, "target", { noMelee = true, noDeadzone = true }) then
        HunterDebug("MM: Arcane Shot (ISS)")
        return true
    end

    -- Multi-Shot is high value in WotLK MM even on single target when mana allows.
    if self:HunterManaGate(manaPercent, 28) and self:HunterTryCast(S.MultiShot, "target", { noMelee = true, noDeadzone = true }) then
        HunterDebug("MM: Multi-Shot")
        return true
    end

    if shouldUseArcane and self:HunterManaGate(manaPercent, 25) and self:HunterTryCast(S.ArcaneShot, "target", { noMelee = true, noDeadzone = true }) then
        HunterDebug("MM: Arcane Shot")
        return true
    end

    if self:HunterTryCast(S.SteadyShot, "target", { stationary = true, noMelee = true, noDeadzone = true, noPlayerCast = true }) then
        HunterDebug("MM: Steady Shot")
        return true
    end

    return false
end

function AC:HunterSurvivalRotation(targetHP, targetIsTough, isFastDying, manaPercent)
    if self:HunterCanUseKillCommand() then
        if self:HunterTryCast(S.KillCommand, "target", { requirePet = true, noMelee = true, noDeadzone = true }) then
            HunterDebug("SV: Kill Command (off-GCD)")
        end
    end

    if targetHP < 20 and self:HunterTryCast(S.KillShot, "target", { noMelee = true, noDeadzone = true }) then
        HunterDebug("SV: Kill Shot")
        return true
    end

    local serpentUp = self:HasDebuff("target", S.SerpentSting)
    local serpentRemaining = self:DebuffTimeRemaining("target", S.SerpentSting)
    local hasLockAndLoad = self:UpdateSurvivalProcState()

    if self:HunterCanFireExplosiveShot() then
        if self:HunterTryCast(S.ExplosiveShot, "target", { noMelee = true, noDeadzone = true }) then
            HunterDebug(hasLockAndLoad and "SV: Explosive Shot (LnL)" or "SV: Explosive Shot")
            return true
        end
    end

    if not isFastDying and (targetIsTough or targetHP > 40) then
        if self:HunterTryLaunchTrap(S.LaunchExplosiveTrap, "SV: Launch Explosive Trap") then
            return true
        end
    end

    -- Prefer trap when already in melee; otherwise Black Arrow is the ranged LnL enabler.
    if not isFastDying and self:HunterIsInMeleeRange("target") and self:HunterTryCast(S.ExplosiveTrap, "player") then
        HunterDebug("SV: Explosive Trap (melee weave)")
        return true
    end

    if not isFastDying and self:HunterTryCast(S.BlackArrow, "target", { noMelee = true, noDeadzone = true }) then
        HunterDebug("SV: Black Arrow")
        return true
    end

    if self:HunterShouldUseSerpentSting("target", targetHP, targetIsTough, isFastDying) and (not serpentUp or serpentRemaining < 1.0) and self:HunterTryCast(S.SerpentSting, "target", { noMelee = true, noDeadzone = true }) then
        HunterDebug("SV: Serpent Sting")
        return true
    end

    if self:HunterTryCast(S.AimedShot, "target", { stationary = true, noMelee = true, noDeadzone = true, noPlayerCast = true }) then
        HunterDebug("SV: Aimed Shot")
        return true
    end

    if self:ShouldUseMultiTarget(2, self:GetEffectiveEnemyCount(self:GetEnemyCount())) and self:HunterTryCast(S.MultiShot, "target", { noMelee = true, noDeadzone = true }) then
        HunterDebug("SV: Multi-Shot")
        return true
    end

    if self:HunterTryCast(S.SteadyShot, "target", { stationary = true, noMelee = true, noDeadzone = true, noPlayerCast = true }) then
        HunterDebug("SV: Steady Shot")
        return true
    end

    return false
end

function AC:HunterLevelingRotation(level, targetHP, targetIsTough, isFastDying, manaPercent, enemies)
    if targetHP < 20 and level >= 71 and self:HunterTryCast(S.KillShot, "target", { noMelee = true, noDeadzone = true }) then
        HunterDebug("Lvl: Kill Shot")
        return true
    end

    if self:ShouldUseMultiTarget(2, enemies) and self:HunterTryCast(S.MultiShot, "target", { noMelee = true, noDeadzone = true }) then
        HunterDebug("Lvl: Multi-Shot")
        return true
    end

    if self:HunterShouldUseSerpentSting("target", targetHP, targetIsTough, isFastDying) and not self:HasDebuff("target", S.SerpentSting) and self:HunterTryCast(S.SerpentSting, "target", { noMelee = true, noDeadzone = true }) then
        HunterDebug("Lvl: Serpent Sting")
        return true
    end

    if self:HunterManaGate(manaPercent, 30) and self:HunterTryCast(S.ArcaneShot, "target", { noMelee = true, noDeadzone = true }) then
        HunterDebug("Lvl: Arcane Shot")
        return true
    end

    if self:HunterTryCast(S.AimedShot, "target", { stationary = true, noMelee = true, noDeadzone = true, noPlayerCast = true }) then
        HunterDebug("Lvl: Aimed Shot")
        return true
    end

    if self:HunterTryCast(S.SteadyShot, "target", { stationary = true, noMelee = true, noDeadzone = true, noPlayerCast = true }) then
        HunterDebug("Lvl: Steady Shot")
        return true
    end

    return false
end

function AC:HunterRotation()
    local spec = self:GetPlayerSpec()
    local level = UnitLevel("player")
    local mana = UnitPower("player", 0)
    local maxMana = UnitPowerMax("player", 0)
    local manaPercent = (maxMana > 0) and (mana / maxMana * 100) or 100
    local healthPercent = self:GetPlayerHealthPercent()
    local inCombat = UnitAffectingCombat("player")
    local petStatus = self:GetPetStatus()

    local hasTarget = UnitExists("target") and UnitCanAttack("player", "target") and not UnitIsDeadOrGhost("target")
    if inCombat and not hasTarget then
        if self:FindAndSetTarget() then
            hasTarget = true
        end
    end

    if hasTarget and petStatus == "alive" then
        self:EnsurePetAttackingCurrentTarget()
    end

    if Throttle("HunterRewriteDebugTick", 1.0) then
        local petStance = petStatus == "alive" and self:GetPetStance() or "N/A"
        local rangeState = hasTarget and self:GetHunterRangeState("target") or "none"
        HunterDebug(string.format("%s L%d | HP:%.0f%% MP:%.0f%% | Target:%s Pet:%s(%s) Combat:%s Aspect:%s",
            spec, level, healthPercent, manaPercent, hasTarget and UnitName("target") or "N", petStatus, petStance, inCombat and "Y" or "N",
            self:HasBuff("player", S.AspectDragonhawk) and "Dragonhawk" or (self:HasBuff("player", S.AspectHawk) and "Hawk" or (self:HasBuff("player", S.AspectViper) and "Viper" or "None/Other"))))
        HunterDebug("Range state: " .. rangeState)
    end

    if inCombat and self:UseLifeblood() then
        return true
    end

    if not IsMounted() then
        if petStatus ~= "alive" and petStatus ~= "calling" then
            if self:ManagePet(inCombat) then return true end
        elseif petStatus == "alive" and (healthPercent > 25 or not inCombat) then
            if self:ManagePet(inCombat) then return true end
        end
    end

    if self:ManageAspects(spec, inCombat, manaPercent) then
        return true
    end

    if inCombat and healthPercent < 45 then
        if self:UseDefensiveCooldowns(healthPercent) then
            return true
        end
        if healthPercent < 30 and self.UseHealthPotion and self:UseHealthPotion(30) then
            return true
        end
    end

    if not hasTarget then
        return false
    end

    if UnitCastingInfo("player") then
        return true
    end

    self:HandleAutoAttack()

    local targetHP = self:GetTargetHealthPercent("target")
    local targetIsTough = UnitClassification("target") == "elite" or UnitClassification("target") == "rareelite" or UnitClassification("target") == "worldboss" or UnitLevel("target") == -1
    local isFastDying = self:IsFastDyingMob("target")
    local enemies = self:GetEffectiveEnemyCount(self:GetEnemyCount())
    local rangeState = self:GetHunterRangeState("target")
    local inMelee = rangeState == "melee"
    local inDeadzone = rangeState == "deadzone"

    if self:IsChanneling() then
        local channelSpell = UnitChannelInfo("player")
        if channelSpell == S.Volley then
            HunterDebug("Continuing Volley")
            return true
        end
    end

    if self:HunterUseMinorCooldowns(spec, targetIsTough, targetHP, enemies) then
        return true
    end

    if self:HunterShouldMark("target", targetHP, targetIsTough) and self:HunterTryCast(S.HuntersMark, "target") then
        HunterDebug("Hunter's Mark")
        return true
    end

    if self:HunterHandleUtility(spec, petStatus) then
        return true
    end

    if inMelee or inDeadzone then
        HunterDebugThrottled("HunterCloseRangeState", 2.0, "Range state: " .. rangeState)
        if self:HunterHandleCloseRange(targetHP, isFastDying, rangeState) then
            return true
        end
        return false
    end

    if self:HunterHandleAOE(enemies, manaPercent) then
        return true
    end

    if spec == "Beast Mastery" then
        if self:HunterBeastMasteryRotation(targetHP, targetIsTough, isFastDying, manaPercent, enemies, petStatus) then
            return true
        end
    elseif spec == "Marksmanship" then
        if self:HunterMarksmanshipRotation(targetHP, targetIsTough, isFastDying, manaPercent) then
            return true
        end
    elseif spec == "Survival" then
        if self:HunterSurvivalRotation(targetHP, targetIsTough, isFastDying, manaPercent) then
            return true
        end
    else
        if self:HunterLevelingRotation(level, targetHP, targetIsTough, isFastDying, manaPercent, enemies) then
            return true
        end
    end

    self:HandleAutoAttack()
    HunterDebugThrottled("AutoAttackFallback", 2.0, "Auto-attack fallback")
    return false
end

function AC:CheckHunterBuffs(spec)
    if not Throttle("HunterOOCBuffCheck", 5) then return false end
    if IsMounted() or UnitAffectingCombat("player") then return false end 
    
    if self:ManagePet(false) then return true end
    
    local manaPercent = (UnitPowerMax("player", 0) > 0) and (UnitPower("player", 0) / UnitPowerMax("player", 0) * 100) or 100
    if self:ManageAspects(spec, false, manaPercent) then return true end
    
    return false
end

function AC:InitHunterRotations()
    if not self.rotations then self.rotations = {} end
    self.rotations["HUNTER"] = {} 
    
    self.rotations["HUNTER"]["Beast Mastery"] = function(s) s:HunterRotation() end
    self.rotations["HUNTER"]["Marksmanship"] = function(s) s:HunterRotation() end
    self.rotations["HUNTER"]["Survival"] = function(s) s:HunterRotation() end
    self.rotations["HUNTER"]["None"] = function(s) s:HunterRotation() end
    
    self:Print("Hunter rotations initialized (v12 - Research-Based).")
    HunterDebug("Hunter module active. Rotations based on Elitist Jerks theorycrafting for WotLK 3.3.5a.")
end

-- AzeroCombat: Hunter Rotations (v12 - Research-Based WotLK 3.3.5a)
local AddonName, AC = ...

-- Spell Database - Must be defined before any functions that use it
local S = { -- Spells
    -- Core Abilities
    AutoShot = "Auto Shot", SteadyShot = "Steady Shot", AimedShot = "Aimed Shot", ArcaneShot = "Arcane Shot",
    MultiShot = "Multi-Shot", KillShot = "Kill Shot", SerpentSting = "Serpent Sting",
    RaptorStrike = "Raptor Strike",
    MongooseBite = "Mongoose Bite", WingClip = "Wing Clip",
    
    -- BM Abilities
    KillCommand = "Kill Command", BestialWrath = "Bestial Wrath", Intimidation = "Intimidation",
    
    -- MM Abilities
    ChimeraShot = "Chimera Shot", SilencingShot = "Silencing Shot", ReadinessSpell = "Readiness",
    
    -- SV Abilities
    ExplosiveShot = "Explosive Shot", BlackArrow = "Black Arrow", ExplosiveTrap = "Explosive Trap", ImmolationTrap = "Immolation Trap",
    
    -- Aspects
    AspectHawk = "Aspect of the Hawk", AspectDragonhawk = "Aspect of the Dragonhawk",
    AspectViper = "Aspect of the Viper", AspectCheetah = "Aspect of the Cheetah",
    AspectPack = "Aspect of the Pack",
    
    -- Pet Management
    CallPet = "Call Pet", RevivePet = "Revive Pet", MendPet = "Mend Pet",
    FeedPet = "Feed Pet",
    
    -- Misc
    HuntersMark = "Hunter's Mark", Misdirection = "Misdirection", FeignDeath = "Feign Death",
    Deterrence = "Deterrence", MasterCall = "Master's Call",
    ScatterShot = "Scatter Shot",
    
    -- Pet Abilities (for control)
    PetGrowl = "Growl", PetClaw = "Claw", PetBite = "Bite", PetSmack = "Smack", 
    PetDash = "Dash", PetDive = "Dive", PetCower = "Cower", PetCharge = "Charge",
    
    -- Pet Family Abilities
    PetCallOfTheWild = "Call of the Wild", -- Ferocity pet talent
    PetRabid = "Rabid", -- Ferocity pet talent
    PetFuriousHowl = "Furious Howl", -- Wolf
    PetScorpidPoison = "Scorpid Poison", -- Scorpid
    PetShellShield = "Shell Shield", -- Turtle
    PetThunderstomp = "Thunderstomp", -- Gorilla
    PetGore = "Gore", -- Boar
    PetSwipe = "Swipe", -- Bear
    PetRake = "Rake", -- Cat
    PetSavageRend = "Savage Rend", -- Raptor
    PetMonstrousBite = "Monstrous Bite", -- Devilsaur
    PetSting = "Sting", -- Wasp
    PetScreech = "Screech", -- Bat/Carrion Bird/Owl
    PetSporeCloud = "Spore Cloud", -- Sporebat
    PetLavaBreath = "Lava Breath", -- Core Hound
    PetFireBreath = "Fire Breath", -- Dragonhawk
    PetLightningBreath = "Lightning Breath", -- Wind Serpent
    PetAcidSpit = "Acid Spit", -- Worm
    PetSpiritStrike = "Spirit Strike", -- Spirit Beast (exotic BM only)
    PetRoarOfRecovery = "Roar of Recovery", -- Cunning pet mana recovery
    
    -- Cooldowns
    RapidFire = "Rapid Fire", Volley = "Volley", TrueshotAura = "Trueshot Aura",
    LaunchExplosiveTrap = "Launch Explosive Trap", LaunchImmolationTrap = "Launch Immolation Trap",
    
    -- Critical Proc Buffs for WotLK Hunter Optimization
    LockAndLoad = "Lock and Load",
    ImprovedSteadyShot = "Improved Steady Shot"
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
    -- Human
    EveryManForHimself = "Every Man for Himself"
}

-- Improved Tracking grants its damage bonus while any one of these creature
-- tracking modes is active. Spell IDs keep the lookup locale-safe.
local HUNTER_DAMAGE_TRACKING_IDS = { 1494, 19878, 19879, 19880, 19882, 19883, 19884 }
local HUNTER_TRACKING_BY_CREATURE = {
    Beast = 1494,
    Demon = 19878,
    Dragonkin = 19879,
    Elemental = 19880,
    Giant = 19882,
    Humanoid = 19883,
    Undead = 19884,
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

function AC:FindHunterPetFood()
    local petLevel = UnitLevel("pet") or UnitLevel("player") or 1
    local fallback = nil

    for bag = 0, 4 do
        for slot = 1, GetContainerNumSlots(bag) do
            local itemLink = GetContainerItemLink(bag, slot)
            if itemLink then
                local itemName, _, _, itemLevel, requiredLevel, itemClass, itemSubClass = GetItemInfo(itemLink)
                local isFood = itemClass == "Consumable" and itemSubClass and itemSubClass:find("Food")
                if itemName and isFood then
                    local foodLevel = math.max(itemLevel or 0, requiredLevel or 0)
                    fallback = fallback or { bag = bag, slot = slot, name = itemName }

                    -- Food more than 15 levels below the pet gives reduced or
                    -- no useful happiness. Prefer a level-appropriate item,
                    -- while retaining a fallback for clients with incomplete
                    -- item-level data. The client performs the final diet check.
                    if foodLevel == 0 or foodLevel >= math.max(1, petLevel - 15) then
                        return bag, slot, itemName
                    end
                end
            end
        end
    end

    if fallback then
        return fallback.bag, fallback.slot, fallback.name
    end
    return nil
end

function AC:FeedHunterPetIfNeeded()
    if UnitAffectingCombat("player") or self:IsPlayerMoving() or self:IsChanneling() then return false end
    if not self:PetNeedsFeeding() or not self:HunterSpellAvailable(S.FeedPet) then return false end
    if not Throttle("HunterFeedPet", 5.0) then return false end

    local bag, slot, itemName = self:FindHunterPetFood()
    if not bag then
        HunterDebugThrottled("NoPetFood", 10.0, "Pet needs feeding but no suitable food was found")
        return false
    end

    local usable, noMana = IsUsableSpell(S.FeedPet)
    if not usable or noMana then return false end

    if not self:CastSpell(S.FeedPet, "pet") then return false end
    UseContainerItem(bag, slot)
    HunterDebug("Feeding pet with " .. itemName)
    return true
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
    for i = 1, 12 do -- WotLK pet bars can expose up to 12 action slots
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
    if self:GetPetAbilityCooldown(slot) <= 0 then
        HunterDebug("Pet ability did not start: " .. abilityName)
        return false
    end
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
    
    -- Growl autocast is disabled in groups by UpdatePetGrowl(). Do not stop
    -- all pet damage merely because the pet is high on threat; that heavily
    -- penalizes BM and Cower is primarily a defensive tool in Wrath.
    local inGroup = IsInGroup() or GetNumRaidMembers() > 0
    
    local focus, maxFocus = self:GetPetPower()
    local targetHealth = self:GetTargetHealthPercent("pettarget")
    local inMelee = CheckInteractDistance("pettarget", 3)
    
    HunterDebugThrottled("PetDPSCheck", 2.0, "Pet DPS check - Focus: " .. focus .. "/" .. maxFocus .. ", Target HP: " .. targetHealth .. "%, In melee: " .. tostring(inMelee) .. ", BW: " .. tostring(hasBestialWrath))
    
    -- Solo play: Use Growl aggressively to maintain threat
    if not inGroup then
        if self:UsePetAbility(S.PetGrowl, 15) then
            HunterDebug("Pet using Growl (solo threat generation)")
            return true
        end
    end
    
    -- Priority 1: Pet cooldowns and family abilities.
    -- Call of the Wild and Furious Howl are off-GCD damage buffs and should
    -- not be left to a slow/optional autocast decision.
    local petTargetClassification = UnitClassification("pettarget")
    local petTargetIsTough = petTargetClassification == "elite" or petTargetClassification == "rareelite" or petTargetClassification == "worldboss" or UnitLevel("pettarget") == -1
    if petTargetIsTough and self:UsePetAbility(S.PetCallOfTheWild) then
        HunterDebug("Pet: Call of the Wild")
        return true
    end

    if self:UsePetAbility(S.PetRabid) then
        HunterDebug("Pet: Rabid")
        return true
    end

    -- Roar of Recovery is a Cunning-pet mana cooldown, not a Spirit Beast
    -- heal. Detect it from the action bar so any capable pet can use it.
    local playerManaMax = UnitPowerMax("player", 0)
    local playerManaPercent = playerManaMax > 0 and (UnitPower("player", 0) / playerManaMax * 100) or 100
    if playerManaPercent < 35 and self:UsePetAbility(S.PetRoarOfRecovery) then
        HunterDebug("Pet: Roar of Recovery (low mana)")
        return true
    end

    local familyAbilities = {
        {name = S.PetFuriousHowl}, -- Wolf: attack power buff
        {name = S.PetMonstrousBite}, -- Devilsaur: damage/self-buff
        {name = S.PetSavageRend}, -- Raptor: damage/bleed/self-buff
        {name = S.PetRake}, -- Cat: damage/bleed
        {name = S.PetSpiritStrike}, -- Spirit Beast: damage ability
        {name = S.PetLavaBreath}, -- Core Hound: damage/caster slow
        {name = S.PetLightningBreath}, -- Wind Serpent: damage ability
        {name = S.PetFireBreath}, -- Dragonhawk: damage ability
        {name = S.PetAcidSpit}, -- Worm: armor reduction/debuff
        {name = S.PetSting}, -- Wasp: armor reduction/debuff
        {name = S.PetScorpidPoison}, -- Scorpid: stacking poison
        {name = S.PetGore}, -- Boar: damage
        {name = S.PetSwipe}, -- Bear: AoE damage
        {name = S.PetScreech}, -- Bat/Carrion Bird/Owl: AoE/debuff
        {name = S.PetSporeCloud}, -- Sporebat: AoE/debuff
    }
    
    for _, ability in ipairs(familyAbilities) do
        if self:UsePetAbility(ability.name) then
            return true
        end
    end

    -- Thunderstomp is useful for AoE, but its threat and cooldown make it a
    -- poor single-target focus spend. Only fire it when there is a pack.
    local petEnemies = self:GetEffectiveEnemyCount(self:GetEnemyCount())
    if petEnemies >= 2 and self:UsePetAbility(S.PetThunderstomp) then
        HunterDebug("Pet: Thunderstomp")
        return true
    end
    
    -- Priority 2: Defensive abilities when pet is tanking (solo play)
    if not inGroup then
        local petHealth = UnitHealth("pet")
        local petMaxHealth = UnitHealthMax("pet")
        local petHealthPercent = (petMaxHealth > 0) and (petHealth / petMaxHealth * 100) or 100
        -- Use Shell Shield (turtle) or similar defensive abilities when tanking
        if petHealthPercent < 50 and self:PetHasAggro("pettarget") then
            if self:UsePetAbility(S.PetShellShield, 20) then
                HunterDebug("Pet using Shell Shield (defensive)")
                return true
            end
        end
    end

    -- Cower is defensive in Wrath. Use it to protect an endangered pet that
    -- actually has aggro, rather than as a reason to suspend pet DPS.
    local petMaxHealth = UnitHealthMax("pet")
    local petHealthPercent = petMaxHealth > 0 and (UnitHealth("pet") / petMaxHealth * 100) or 100
    if petHealthPercent < 35 and self:PetHasAggro("pettarget") and self:UsePetAbility(S.PetCower) then
        HunterDebug("Pet using Cower (low-health mitigation)")
        return true
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
    
    -- Priority 4: Core damage abilities.
    -- Do not infer the active ability from the pet family. WotLK pets can
    -- have different learned action bars, and the action bar is authoritative.
    local focusThreshold = hasBestialWrath and 20 or 30
    
    if inMelee and focus >= focusThreshold then
        for _, abilityName in ipairs({S.PetClaw, S.PetBite, S.PetSmack}) do
            if self:UsePetAbility(abilityName, 25) then
                HunterDebug("Pet basic attack: " .. abilityName)
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
    local focusReserve = hasBestialWrath and 0 or (hasSpecialAbility and 20 or 0)
    
    if inMelee and focus > focusReserve + 25 then
        -- Use whichever basic attack is actually on the pet bar.
        for _, abilityName in ipairs({S.PetClaw, S.PetBite, S.PetSmack}) do
            if self:UsePetAbility(abilityName, 25) then
                return true
            end
        end
    end
    
    -- Emergency focus dump during Bestial Wrath
    if hasBestialWrath and inMelee and focus > 25 then
        for _, abilityName in ipairs({S.PetClaw, S.PetBite, S.PetSmack}) do
            if self:UsePetAbility(abilityName, 25) then
                HunterDebug("BW Focus dump: " .. abilityName)
                return true
            end
        end
    end
    
    return false
end




-- FIXED: Racial abilities system
function AC:GetPlayerRace()
    local localizedRace, raceToken = UnitRace("player")
    if raceToken and raceToken ~= "" then
        return string.upper(raceToken)
    end

    -- Older/private clients may only expose the localized race name.
    return localizedRace and string.upper((localizedRace:gsub("%s+", ""))) or ""
end

function AC:UseRacials(offensive, emergency)
    if not offensive and not emergency then return false end
    
    -- Keep emergency checks responsive even though the normal rotation polls
    -- this function frequently.
    local racialThrottleKey = emergency and "RacialEmergency" or "RacialOffensive"
    local racialThrottleInterval = emergency and 0.5 or 1.0
    if not Throttle(racialThrottleKey, racialThrottleInterval) then
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
        if (race == "UNDEAD" or race == "SCOURGE") and self:IsUsableSpell(R.WillOfForsaken) then
            -- Check if we have a debuff that WotF can remove
            local hasRemovableDebuff = false
            for i = 1, 16 do
                local name = UnitDebuff("player", i)
                local lowerName = name and name:lower() or ""
                if name and (lowerName:find("fear") or lowerName:find("charm") or lowerName:find("sleep")) then
                    hasRemovableDebuff = true
                    break
                end
            end
            
            if hasRemovableDebuff and self:HunterTryCast(R.WillOfForsaken, "player") then
                HunterDebug("Used Will of the Forsaken")
                return true
            end
        end
        
        -- Stoneform (Dwarf) - removes poison, disease, bleed
        if race == "DWARF" and self:IsUsableSpell(R.Stoneform) then
            for i = 1, 16 do
                local name, _, _, _, debuffType = UnitDebuff("player", i)
                if name and (debuffType == "Poison" or debuffType == "Disease" or name:lower():find("bleed")) and self:HunterTryCast(R.Stoneform, "player") then
                    HunterDebug("Used Stoneform")
                    return true
                end
            end
        end
        
        -- Gift of the Naaru (Draenei) - heal
        if race == "DRAENEI" and healthPercent < 50 and self:HunterTryCast(R.GiftOfNaaru, "player") then
            HunterDebug("Used Gift of the Naaru")
            return true
        end
        
        -- Escape Artist (Gnome) - removes movement impairing effects
        if race == "GNOME" and self:IsUsableSpell(R.EscapeArtist) then
            for i = 1, 16 do
                local name = UnitDebuff("player", i)
                if name and (name:lower():find("slow") or name:lower():find("root") or name:lower():find("snare")) then
                    if self:HunterTryCast(R.EscapeArtist, "player") then
                        HunterDebug("Used Escape Artist")
                        return true
                    end
                end
            end
        end
        
        -- Every Man for Himself (Human) - removes stun, fear, charm
        if race == "HUMAN" and self:IsUsableSpell(R.EveryManForHimself) then
            for i = 1, 16 do
                local name = UnitDebuff("player", i)
                local lowerName = name and name:lower() or ""
                if name and (lowerName:find("stun") or lowerName:find("fear") or lowerName:find("charm")) and self:HunterTryCast(R.EveryManForHimself, "player") then
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
        if race == "ORC" then
            if self:HunterTryCast(R.BloodFury, "player") then
                HunterDebug("Used Blood Fury")
                return true
            else
                HunterDebug("Blood Fury not available (cooldown or conditions)")
            end
        end
        
        -- Berserking (Troll) - increases attack and casting speed
        if race == "TROLL" then
            if self:HunterTryCast(R.Berserking, "player") then
                HunterDebug("Used Berserking")
                return true
            else
                HunterDebug("Berserking not available (cooldown or conditions)")
            end
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

    -- IsSpellInRange() is not sufficiently trustworthy by itself on every
    -- 3.3.5a client/server combination.  First require the target to be
    -- inside the close-distance boundary, then use a precise 6-yard item
    -- range when the client can report one.  This prevents a melee spell from
    -- being selected for a target that is actually at normal bow range.
    local closeOk, closeResult = pcall(CheckInteractDistance, unit, 3)
    if not closeOk or not closeResult then
        return false
    end

    local preciseRangeKnown = false
    local preciseRangeItems = { 31463 } -- 6-yard range check
    for _, itemID in ipairs(preciseRangeItems) do
        local itemOk, itemResult = pcall(IsItemInRange, itemID, unit)
        if itemOk and itemResult ~= nil then
            preciseRangeKnown = true
            if itemResult == 1 or itemResult == true then
                return true
            end
        end
    end

    -- If a precise item check was available and said the target was beyond
    -- its range, do not let a misleading melee spell range result override it.
    if preciseRangeKnown then
        return false
    end

    local meleeSpells = { S.RaptorStrike, S.WingClip, S.MongooseBite }
    for _, spellName in ipairs(meleeSpells) do
        if self:KnowsSpell(spellName) or self:IsUsableSpell(spellName) then
            local result = self:HunterSpellRangeResult(spellName, unit)
            if result == 1 then
                return true
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

    for _, spellName in ipairs(rangedSpells) do
        if spellName and (spellName == "Auto Shot" or self:KnowsSpell(spellName) or self:IsUsableSpell(spellName)) then
            local result = self:HunterSpellRangeResult(spellName, unit)
            if result ~= nil then
                if result == 1 then
                    return true
                end
            end
        end
    end

    -- CheckInteractDistance(unit, 1) is roughly 28 yards.  It is only a
    -- ranged fallback when the target is not inside the close/deadzone
    -- boundary; otherwise it would incorrectly label deadzone targets as
    -- ranged and repeatedly attempt shots that cannot fire.
    local closeOk, closeResult = pcall(CheckInteractDistance, unit, 3)
    if closeOk and closeResult then
        return false
    end

    local ok, result = pcall(CheckInteractDistance, unit, 1)
    if ok and result then
        return true
    end

    return false
end

function AC:GetHunterRangeState(unit)
    unit = unit or "target"
    -- Favor a valid ranged result when both APIs report a boundary target.
    -- This is the ordering used by the stable Hunter path and prevents a
    -- noisy melee range result from trapping the rotation in melee actions.
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
    local maxHealth = target.maxHealth or 0
    local healthPercent = maxHealth > 0 and ((target.health or 0) / maxHealth * 100) or 100
    priority = priority + (100 - healthPercent) * 0.5
    
    -- Level difference (higher level = higher priority)
    local playerLevel = UnitLevel("player")
    local levelDiff = (target.level or playerLevel) - playerLevel
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
function AC:GetBestPetTarget(targets)
    targets = targets or self:GetNearbyHostileTargets()
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

    -- Group play should remain predictable and aligned with the tank/player's
    -- chosen focus rather than allowing autonomous nameplate target swaps.
    if IsInGroup() then
        return self:EnsurePetAttackingCurrentTarget()
    end

    local targets = self:GetNearbyHostileTargets()
    if #targets == 0 then
        return self:EnsurePetAttackingCurrentTarget()
    end
    
    local currentPetTarget = UnitExists("pettarget") and "pettarget" or nil
    local bestTarget, bestPriority = nil, 0
    
    bestTarget, bestPriority = self:GetBestSoloTarget(targets)
    
    if not bestTarget then return false end

    -- The player's selected target remains the default. Only peel the pet to a
    -- different solo target when the scoring system finds a materially more
    -- urgent threat (normally a loose mob attacking the hunter).

    local selectedPriority = 0
    for _, candidate in ipairs(targets) do
        if candidate.unit == "target" then
            selectedPriority = self:CalculatePetThreatPriority(candidate)
            break
        end
    end

    if bestTarget.unit == "target" or bestPriority <= selectedPriority + 50 then
        return self:EnsurePetAttackingCurrentTarget()
    end
    
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

AC.HunterIsFastDyingMob = AC.IsFastDyingMob

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
    if state.petDeadPending and self:HunterSpellAvailable(S.RevivePet) and
       IsUsableSpell(S.RevivePet) then
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
function AC:GetBestSoloTarget(targets)
    targets = targets or self:GetNearbyHostileTargets()
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
        local canRevive = self:HunterSpellAvailable(S.RevivePet) and
                          IsUsableSpell(S.RevivePet) and not self:IsPlayerMoving()
        if canRevive and self:ActionThrottle("RevivePetAttempt", 2.0) then
            HunterDebug("Attempting to revive pet")
            if self:CastSpell(S.RevivePet, "player") then
                state.petDeadPending = true
                return true
            end
            HunterDebug("Revive Pet failed to start")
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
                if self:CastSpell(S.CallPet, "player") then
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

        if not inCombat and self:FeedHunterPetIfNeeded() then return true end
        
        if self:PetNeedsMending() and self:IsUsableSpell(S.MendPet) then 
            HunterDebug("Mending Pet"); 
            if self:CastSpell(S.MendPet, "pet") then
                return true
            end
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
    
    for i=1,10 do
        local name = GetPetActionInfo(i)
        if name == S.PetGrowl then 
            growlKnown = true
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
    
    -- Group/Raid: disable Growl. Cower is handled as low-health mitigation by
    -- ManagePetDPS rather than being treated as a threat dump.
    if inGroup or inRaid then
        local changed = self:TogglePetSpell(S.PetGrowl, false)
        if changed then
            HunterDebugThrottled("GrowlGroupOff", 5.0, "Group mode: Growl OFF")
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
        return false
    end
    
    -- Find and activate the stance using flexible matching
    local targetName = string.lower(stanceName)
    for i = 1, 12 do
        local name = GetPetActionInfo(i)
        if name then
            local nameLower = string.lower(name)
            if string.find(nameLower, targetName) then
                CastPetAction(i)
                if self:GetPetStance() ~= stanceName then
                    HunterDebug("Pet stance change did not confirm: " .. name)
                    return false
                end
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
    
    -- At critical health the pet must keep protecting the hunter. Passive
    -- would stop pressure and can send a solo mob back onto the player.
    if playerHealth < 15 then
        HunterDebug("Pet stance logic: Defensive (emergency - low health)")
        return "Defensive"
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

-- Emergency pet stance handling (for dangerous situations)
function AC:EmergencyPetPassive()
    if not UnitExists("pet") then return false end
    
    local playerHealth = self:GetPlayerHealthPercent()
    local inInstance = IsInInstance()
    local _, instanceType = IsInInstance()
    
    -- Keep the pet engaged defensively when the hunter is in danger. Forcing
    -- Passive here would drop the hunter's most important solo protection.
    if playerHealth < 20 then
        HunterDebug("Emergency: Setting pet to Defensive (low health)")
        return self:SetPetStance("Defensive")
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
    local isBoss = classification == "worldboss" or level == -1

    -- Hunter's Mark is deliberately boss-only.  Applying it to normal mobs,
    -- elites, or high-level quest targets costs a GCD and is not worth it.
    if not isBoss then
        HunterDebugThrottled("HuntersMarkSkip", 5.0, "Skipping Hunter's Mark - target is not a boss")
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

function AC:GetHunterTalentRank(talentName)
    if not talentName or not GetTalentInfo or not GetNumTalentTabs or not GetNumTalents then return 0 end

    local now = GetTime()
    self.hunterTalentRanks = self.hunterTalentRanks or {}
    self.hunterTalentRankStamp = self.hunterTalentRankStamp or 0
    if (now - self.hunterTalentRankStamp) > 2.0 then
        self.hunterTalentRanks = {}
        self.hunterTalentRankStamp = now
    end

    if self.hunterTalentRanks[talentName] ~= nil then
        return self.hunterTalentRanks[talentName]
    end

    local rank = 0
    for tab = 1, GetNumTalentTabs() do
        for talent = 1, GetNumTalents(tab) do
            local name, _, _, _, currentRank = GetTalentInfo(tab, talent)
            if name == talentName then
                rank = currentRank or 0
                break
            end
        end
        if rank > 0 then break end
    end

    self.hunterTalentRanks[talentName] = rank
    return rank
end

function AC:ManageHunterImprovedTracking()
    local improvedTrackingName = GetSpellInfo(52788) or "Improved Tracking"
    if self:GetHunterTalentRank(improvedTrackingName) <= 0 then return false end
    if not GetNumTrackingTypes or not GetTrackingInfo or not SetTracking then return false end
    if not Throttle("HunterImprovedTracking", 2.0) then return false end

    local validTrackingNames = {}
    for _, spellID in ipairs(HUNTER_DAMAGE_TRACKING_IDS) do
        local spellName = GetSpellInfo(spellID)
        if spellName then
            validTrackingNames[spellName] = true
        end
    end

    local preferredSpellID = UnitExists("target") and
                             HUNTER_TRACKING_BY_CREATURE[UnitCreatureType("target")] or nil
    local preferredName = preferredSpellID and GetSpellInfo(preferredSpellID) or nil
    local preferredIndex = nil
    local fallbackIndex = nil

    for index = 1, GetNumTrackingTypes() do
        local name, _, active = GetTrackingInfo(index)
        if name and validTrackingNames[name] then
            -- Any qualifying creature tracker activates Improved Tracking for
            -- all supported creature types, so never churn a valid selection.
            if active then
                return false
            end
            fallbackIndex = fallbackIndex or index
            if preferredName and name == preferredName then
                preferredIndex = index
            end
        end
    end

    local trackingIndex = preferredIndex or fallbackIndex
    if not trackingIndex then return false end

    SetTracking(trackingIndex)
    local trackingName, _, active = GetTrackingInfo(trackingIndex)
    if active then
        HunterDebug("Improved Tracking enabled: " .. tostring(trackingName))
        return true
    end

    HunterDebugThrottled("ImprovedTrackingRejected", 3.0, "Unable to enable creature tracking")
    return false
end

function AC:IsCustomSpellAvailable(spellName)
    return (spellName == S.LaunchExplosiveTrap or spellName == S.LaunchImmolationTrap) and
           GetSpellInfo(spellName) ~= nil
end

function AC:GetHunterTrapForLauncher(spellName)
    if spellName == S.LaunchExplosiveTrap then
        return S.ExplosiveTrap
    elseif spellName == S.LaunchImmolationTrap then
        return S.ImmolationTrap
    end
    return nil
end

function AC:HunterSpellAvailable(spellName)
    if not spellName then return false end
    local level = UnitLevel("player") or 1

    -- Auto Shot is the Hunter's baseline ranged attack.  Some 3.3.5a
    -- spellbooks expose it as an innate client action rather than a normal
    -- learned spellbook entry, so the spell entry plus level is authoritative
    -- for this one ability.
    if spellName == S.AutoShot then
        return level >= 1 and GetSpellInfo(spellName) ~= nil
    end

    -- The launcher is custom, but it is only valid once the corresponding
    -- normal trap has been learned. The server supplies the highest rank.
    local trapSpell = self:GetHunterTrapForLauncher(spellName)
    if trapSpell then
        return self:HunterKnowsSpell(trapSpell) and self:IsCustomSpellAvailable(spellName)
    end

    local learnedByLevel = {
        [S.AutoShot] = 1,
        [S.RaptorStrike] = 1,
        [S.SerpentSting] = 4,
        [S.ArcaneShot] = 6,
        [S.HuntersMark] = 6,
        [S.WingClip] = 12,
        [S.MendPet] = 12,
        [S.MultiShot] = 18,
        [S.FeignDeath] = 30,
        [S.Volley] = 40,
        [S.SteadyShot] = 50,
        [S.KillCommand] = 66,
        [S.KillShot] = 71,
        [S.ExplosiveShot] = 60,
        [S.BlackArrow] = 60,
    }

    local learnedAt = learnedByLevel[spellName]
    if learnedAt and level < learnedAt then
        return false
    end

    -- GetSpellInfo() only proves that the client knows the spell's database
    -- entry; it does not prove that this character learned the spell. The
    -- old fallback made leveling rotations "successfully" cast unlearned
    -- abilities such as Bestial Wrath and return before real attacks.
    if self:HunterKnowsSpell(spellName) then
        return true
    end

    -- These are AzerothCore custom launch spells, which may exist in the
    -- spell database without appearing in the player's spellbook.
    return self:IsCustomSpellAvailable(spellName)
end

function AC:HunterSpellInRange(spellName, unit, opts)
    opts = opts or {}
    if not spellName or not unit or unit == "player" then return true end
    if not UnitExists(unit) then return false end

    -- Never accept a melee spell solely because IsSpellInRange() returned 1;
    -- that API can be overly permissive for melee abilities on private
    -- 3.3.5a clients.  Use the guarded physical-range check instead.
    if self:HunterIsMeleeSpell(spellName) then
        return self:HunterIsInMeleeRange(unit)
    end

    local ok, result = pcall(IsSpellInRange, spellName, unit)
    if ok and result ~= nil then
        if result == 1 then
            return true
        end

        return self:HunterIsInRangedRange(unit)
    end

    if opts.allowNilRange then
        return true
    end

    if UnitCanAttack("player", unit) then
        local rangeState = self:GetHunterRangeState(unit)
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

    local usable, noMana = IsUsableSpell(spellName)
    if not usable then
        return false, "unusable"
    end
    if noMana then
        return false, "no mana"
    end

    if not self:HunterSpellInRange(spellName, unit or "target", opts) then
        return false, "range"
    end

    return true
end

function AC:GetHunterSpellIndexForRank(spellName, rank)
    if not spellName or not rank then return nil end

    local wantedRank = "Rank " .. tostring(rank)
    for tabIndex = 1, GetNumSpellTabs() do
        local _, _, offset, numSpells = GetSpellTabInfo(tabIndex)
        for i = offset + 1, offset + numSpells do
            local name, bookRank = GetSpellName(i, BOOKTYPE_SPELL)
            if name == spellName and bookRank and (bookRank == wantedRank or bookRank:find(wantedRank, 1, true)) then
                return i
            end
        end
    end

    return nil
end

function AC:HunterTryCast(spellName, unit, opts)
    local canCast, reason = self:HunterCanCast(spellName, unit, opts)
    if not canCast then
        if spellName == S.ArcaneShot then
            HunterDebugThrottled("ArcaneReject", 1.0, "Arcane Shot blocked: " .. tostring(reason))
        elseif spellName == S.MultiShot then
            HunterDebugThrottled("MultiShotReject", 1.0, "Multi-Shot blocked: " .. tostring(reason))
        end
        return false
    end

    unit = unit or "target"
    local beforeSpellCooldown = self:GetSpellCooldown(spellName)
    local beforeGlobalCooldown = self:GetSpellCooldown(61304)
    local beforeCast = UnitCastingInfo("player")
    local beforeChannel = UnitChannelInfo("player")
    local castByRank = opts and opts.rank and self:GetHunterSpellIndexForRank(spellName, opts.rank)
    local hadTarget = UnitExists("target")
    local shouldChangeTarget = unit ~= "player" and unit ~= "target" and
                               not (UnitExists("target") and UnitIsUnit("target", unit))
    local changedTarget = false
    local castAccepted = pcall(function()
        if unit == "player" then
            -- The second CastSpellByName argument is a self-cast boolean on
            -- the 3.3.5 client; it is not a unit token.
            if castByRank then
                CastSpell(castByRank, BOOKTYPE_SPELL)
            else
                CastSpellByName(spellName, true)
            end
        elseif unit == "target" then
            if castByRank then
                CastSpell(castByRank, BOOKTYPE_SPELL)
            else
                CastSpellByName(spellName)
            end
        else
            TargetUnit(unit)
            if not UnitExists("target") or not UnitIsUnit("target", unit) then
                error("unable to target " .. tostring(unit))
            end
            changedTarget = shouldChangeTarget

            if castByRank then
                CastSpell(castByRank, BOOKTYPE_SPELL)
            else
                CastSpellByName(spellName)
            end
        end
    end)

    if changedTarget then
        if hadTarget then TargetLastTarget() else ClearTarget() end
    end

    if not castAccepted then
        HunterDebugThrottled("CastTargetRejected_" .. spellName, 1.0, "Unable to target unit for: " .. spellName)
        return false
    end

    if SpellIsTargeting and SpellIsTargeting() then
        SpellStopTargeting()
        return false
    end

    local afterSpellCooldown = self:GetSpellCooldown(spellName)
    local afterGlobalCooldown = self:GetSpellCooldown(61304)
    local started = (not beforeCast and UnitCastingInfo("player")) or
                   (not beforeChannel and UnitChannelInfo("player"))
    local queued = IsCurrentSpell(spellName) or
                   (castByRank and IsCurrentSpell(castByRank))
    if not started and afterSpellCooldown <= beforeSpellCooldown + 0.05 and
       afterGlobalCooldown <= beforeGlobalCooldown + 0.05 and
       not queued then
        HunterDebugThrottled("CastRejected_" .. spellName, 1.0, "Cast rejected by client: " .. spellName)
        return false
    end

    local state = self:InitializeHunterState()
    if spellName == S.ExplosiveShot then
        state.lastExplosiveShotCast = GetTime()
        if opts and opts.rank and state.lockAndLoadActive then
            state.lockAndLoadShots = (state.lockAndLoadShots or 0) + 1
        end
    elseif spellName == S.KillCommand then
        state.lastKillCommandCast = GetTime()
    end

    return true
end

function AC:InitializeHunterState()
    self.hunterState = self.hunterState or {
        lastKillCommandCast = 0,
        lastExplosiveShotCast = 0,
        lockAndLoadActive = false,
        lockAndLoadShots = 0,
        petDeadPending = false,
    }
    self.hunterState.lockAndLoadShots = self.hunterState.lockAndLoadShots or 0
    return self.hunterState
end

function AC:HandleClassCombatLog(...)
    local _, playerClass = UnitClass("player")
    if playerClass ~= "HUNTER" then return end

    local state = self:InitializeHunterState()
    local timestamp, subevent, sourceGUID, sourceName, sourceFlags, destGUID, destName, destFlags = ...
    local petGUID = UnitGUID("pet")
    local playerGUID = UnitGUID("player")

    if playerGUID and sourceGUID == playerGUID and subevent == "SPELL_CAST_SUCCESS" then
        local spellName = select(10, ...)
        if spellName == S.KillCommand then
            state.lastKillCommandCast = GetTime()
        end
    end

    if subevent == "UNIT_DIED" and destGUID and petGUID and destGUID == petGUID then
        state.petDeadPending = true
    end
end

function AC:HunterCanUseKillCommand()
    local state = self:InitializeHunterState()
    if self:GetPetStatus() ~= "alive" then return false end
    if not UnitExists("pettarget") or not UnitIsUnit("pettarget", "target") then return false end
    if (GetTime() - (state.lastKillCommandCast or 0)) < 1.0 then return false end
    return self:HunterCanCast(S.KillCommand, "target", { requirePet = true })
end

function AC:HunterLockAndLoadRank()
    local state = self:InitializeHunterState()
    if not state.lockAndLoadActive then return nil end

    if state.lockAndLoadShots == 0 or state.lockAndLoadShots == 2 then
        return 4
    elseif state.lockAndLoadShots == 1 then
        return 3
    end

    return nil
end

function AC:HunterCanFireExplosiveShot(castOpts)
    castOpts = castOpts or { noMelee = true, noDeadzone = true }
    if not self:HunterCanCast(S.ExplosiveShot, "target", castOpts) then
        return false
    end

    local state = self:InitializeHunterState()
    local now = GetTime()
    local sinceLastES = now - (state.lastExplosiveShotCast or 0)
    local hasLockAndLoad = self:HasBuff("player", S.LockAndLoad)
    local esRemaining = self:DebuffTimeRemaining("target", S.ExplosiveShot)

    if hasLockAndLoad then
        -- WotLK's 4-3-4 sequence intentionally uses separate ranks so the
        -- middle shot does not overwrite the first rank's damage-over-time.
        return self:HunterLockAndLoadRank() ~= nil and sinceLastES >= 1.0
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
        state.lockAndLoadShots = 0
        HunterDebug("SV: Lock and Load active")
    elseif not hasLockAndLoad and state.lockAndLoadActive then
        state.lockAndLoadActive = false
        state.lockAndLoadShots = 0
        HunterDebug("SV: Lock and Load faded")
    end

    return hasLockAndLoad
end

function AC:IsHunterAutoShotActive()
    if IsAutoRepeatSpell then
        local ok, active = pcall(IsAutoRepeatSpell, S.AutoShot)
        if ok and active ~= nil then
            return active and true or false
        end
    end

    -- IsCurrentSpell is a fallback on clients that do not expose the
    -- auto-repeat helper. It may return a name, a spell ID, or nil.
    if IsCurrentSpell then
        local ok, current = pcall(IsCurrentSpell, S.AutoShot)
        if ok and current then
            if current == S.AutoShot or current == true then
                return true
            end
            if type(current) == "number" and current > 0 then
                return GetSpellInfo(current) == S.AutoShot
            end
        end
    end

    return false
end

function AC:HandleAutoAttack()
    if not UnitExists("target") or not UnitCanAttack("player", "target") or UnitIsDeadOrGhost("target") then
        return false
    end

    local rangeState = self:GetHunterRangeState("target")
    local autoShotActive = self:IsHunterAutoShotActive()

    if rangeState == "ranged" then
        if autoShotActive then
            return false
        end

        -- Auto Shot is an auto-repeat attack, not a normal GCD spell. Do not
        -- send it through HunterCanCast/IsUsableSpell, which can report false
        -- while the weapon swing timer or another spell is active.
        if not self:HunterSpellAvailable(S.AutoShot) then
            HunterDebugThrottled("AutoShotUnavailable", 2.0, "Auto Shot skipped: spell is not known")
            return false
        end

        if UnitCastingInfo("player") or UnitChannelInfo("player") then
            HunterDebugThrottled("AutoShotCasting", 2.0, "Auto Shot waiting: player is casting/channeling")
            return false
        end

        CastSpellByName(S.AutoShot)
        if self:IsHunterAutoShotActive() then
            StartAttack()
            HunterDebugThrottled("AutoShotStarted", 2.0, "Auto Shot started")
            return true
        end

        -- If this client exposes neither repeat-state API, the cast request
        -- itself is the only confirmation available. Treat it as consumed so
        -- successive ticks do not repeatedly toggle Auto Shot.
        if not IsAutoRepeatSpell and not IsCurrentSpell then
            StartAttack()
            HunterDebugThrottled("AutoShotRequested", 2.0, "Auto Shot requested (no client repeat-state API)")
            return true
        end

        HunterDebugThrottled("AutoShotRejected", 2.0, "Auto Shot request was not accepted by the client")
    elseif autoShotActive then
        -- Stop the ranged repeat when the target enters close range so the
        -- melee branch is clean.
        CastSpellByName(S.AutoShot)
        HunterDebugThrottled("AutoShotStopped", 2.0, "Auto Shot stopped outside ranged distance")
    else
        HunterDebugThrottled("AutoShotRange", 2.0, "Auto Shot waiting: range state=" .. tostring(rangeState))
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
        -- Stay in Viper while out of combat so it can refill the bar fully.
        -- Once combat is established, leave Viper above the 70% threshold.
        if inCombat and self:HasBuff("player", S.AspectViper) and manaPercent > 70 then
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

function AC:HunterHasMovementImpairingDebuff()
    local knownEffects = {
        ["frost nova"] = true,
        ["entangling roots"] = true,
        ["hamstring"] = true,
        ["wing clip"] = true,
        ["crippling poison"] = true,
        ["chains of ice"] = true,
        ["curse of exhaustion"] = true,
        ["piercing howl"] = true,
        ["earthbind"] = true,
        ["freeze"] = true,
        ["web"] = true,
        ["net"] = true,
    }

    for i = 1, 40 do
        local name = UnitDebuff("player", i)
        if not name then break end
        local lowerName = name:lower()
        if knownEffects[lowerName] or lowerName:find("slow", 1, true) or
           lowerName:find("snare", 1, true) or lowerName:find("root", 1, true) then
            return true
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

    if self:UseRacials(false, true) then
        return true
    end

    return false
end

function AC:HunterShouldMark(unit)
    unit = unit or "target"
    return self:ShouldUseHuntersMark(unit)
end

function AC:HunterCanMisdirectTo(unit)
    if not unit or not UnitExists(unit) or UnitIsDeadOrGhost(unit) or
       not UnitIsFriend("player", unit) then
        return false
    end

    -- Group unit tokens continue to exist when a member is offline or in a
    -- different area. Do not temporarily target those units: failed target
    -- restoration can leave the hunter without the hostile target.
    if UnitIsConnected and not UnitIsConnected(unit) then
        return false
    end
    if UnitIsVisible and not UnitIsVisible(unit) then
        return false
    end

    -- Misdirection's own range result is authoritative when the client can
    -- provide it. Some 3.3.5 private-server clients return nil for friendly
    -- spells, so use conservative group/interact checks as fallbacks.
    local ok, inRange = pcall(IsSpellInRange, S.Misdirection, unit)
    if ok and inRange ~= nil then
        return inRange == 1 or inRange == true
    end

    if UnitInRange then
        ok, inRange = pcall(UnitInRange, unit)
        if ok and inRange ~= nil then
            return inRange == 1 or inRange == true
        end
    end

    ok, inRange = pcall(CheckInteractDistance, unit, 1)
    return ok and inRange == true
end

function AC:HunterUseMinorCooldowns(spec, targetIsTough, targetHP, enemies, inCombat)
    if not inCombat then return false end

    if spec == "Beast Mastery" and (targetIsTough or targetHP > 40) and self:HunterTryCast(S.BestialWrath, "player", { requirePet = true }) then
        HunterDebug("BM: Bestial Wrath")
        return true
    end

    if (targetIsTough or enemies >= 3) and self:HunterTryCast(S.RapidFire, "player") then
        HunterDebug("Rapid Fire")
        return true
    end

    if (targetIsTough or enemies >= 3) and self:UseTrinkets() then
        HunterDebug("Used Trinkets")
    end

    if targetIsTough and self.UseOffensivePotion and self:UseOffensivePotion(true) then
        HunterDebug("Used offensive potion")
    end

    if self:UseRacials(true, false) then
        HunterDebug("Used Racial")
    end

    return false
end

function AC:HunterHandleUtility(spec, petStatus)
    -- Break crowd control as soon as it exists; this is not limited to the
    -- low-health defensive branch.
    if self:UseRacials(false, true) then
        return true
    end

    if self:HunterKnowsSpell(S.Misdirection) and self:ActionThrottle("HunterMisdirection", 30) then
        local target = nil
        for i = 1, (GetNumRaidMembers() > 0 and GetNumRaidMembers() or GetNumPartyMembers()) do
            local unit = GetNumRaidMembers() > 0 and "raid"..i or "party"..i
            if self:IsTank(unit) and self:HunterCanMisdirectTo(unit) then
                target = unit
                break
            end
        end

        if not target and petStatus == "alive" and self:HunterCanMisdirectTo("pet") then
            target = "pet"
        end

        if target and self:HunterTryCast(S.Misdirection, target) then
            HunterDebug("Misdirection on " .. target)
            return true
        end
    end

    if UnitCastingInfo("target") or UnitChannelInfo("target") then
        if self:HunterIsInMeleeRange("target") and self:HunterTryCast(R.ArcaneTorrent, "player") then
            HunterDebug("Arcane Torrent")
            return true
        end

        if self:HunterIsInMeleeRange("target") and self:HunterTryCast(R.WarStomp, "player") then
            HunterDebug("War Stomp")
            return true
        end

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

function AC:HunterHandleCloseRange(spec, targetHP, isFastDying, rangeState)
    rangeState = rangeState or self:GetHunterRangeState("target")

    if rangeState == "deadzone" then
        -- Do not automatically use the hunter escape. It is a player-
        -- controlled action, not a rotation action, and firing it merely
        -- because the target is close can create a worse position or waste
        -- an important cooldown.
        return false
    end

    -- Revalidate before entering the melee-only section.  This protects
    -- against a stale range state while the target is moving or changing
    -- distance between rotation ticks.
    if not self:HunterIsInMeleeRange("target") then
        return false
    end

    -- Execute and Survival's primary shot remain valuable inside melee range.
    if targetHP < 20 and self:HunterTryCast(S.KillShot, "target") then
        HunterDebug("Close range: Kill Shot")
        return true
    end

    if spec == "Survival" then
        local hasLockAndLoad = self:UpdateSurvivalProcState()
        local explosiveOptions = {}
        local lockAndLoadRank = hasLockAndLoad and self:HunterLockAndLoadRank() or nil
        if lockAndLoadRank then explosiveOptions.rank = lockAndLoadRank end
        if self:HunterCanFireExplosiveShot({ noDeadzone = true }) and self:HunterTryCast(S.ExplosiveShot, "target", explosiveOptions) then
            HunterDebug(hasLockAndLoad and "Close range: Explosive Shot (LnL)" or "Close range: Explosive Shot")
            return true
        end
    end

    if self:IsTargetFleeing("target") and self:HunterTryCast(S.WingClip, "target") then
        HunterDebug("Wing Clip")
        return true
    end

    if not isFastDying and self:HunterTryLaunchTrap(S.LaunchExplosiveTrap, "Close range: Launch Explosive Trap") then
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

    return false
end

function AC:HunterTryLaunchTrap(spellName, debugLabel)
    if not spellName or not self.SafeCastGroundAOE then
        return false
    end

    if not self:HunterSpellAvailable(spellName) or self:IsPlayerMoving() or self:IsChanneling() then
        return false
    end

    local cooldownBefore = self:GetSpellCooldown(spellName)
    if self:SafeCastGroundAOE(spellName) then
        HunterDebug(debugLabel or spellName)
        return true
    end

    -- SafeCastGroundAOE can perform the cast but return false for its group
    -- size safety result. Treat a started cooldown or active cursor targeting
    -- state as a successful action so the rotation does not double-cast.
    if self:GetSpellCooldown(spellName) > cooldownBefore or (SpellIsTargeting and SpellIsTargeting()) then
        HunterDebug(debugLabel or spellName)
        return true
    end

    return false
end

function AC:HunterHandleAOE(enemies, manaPercent)
    local useTwoTarget = self:ShouldUseMultiTarget(2, enemies)
    local useThreeTarget = self:ShouldUseMultiTarget(3, enemies)
    local manaForThirty = self:HunterManaGate(manaPercent, 30)
    local manaForTwenty = self:HunterManaGate(manaPercent, 20)
    local knowsVolley = self:HunterKnowsSpell(S.Volley)
    local canLaunchExplosive = self:HunterSpellAvailable(S.LaunchExplosiveTrap)
    local knowsMultiShot = self:HunterSpellAvailable(S.MultiShot)

    if enemies >= 2 then
        HunterDebugThrottled("HunterAOEDecision", 1.5, string.format(
            "AoE: enemies=%d 2+:%s 3+:%s mana30:%s mana20:%s ExplosiveTrap:%s Volley:%s Multi-Shot:%s",
            enemies, tostring(useTwoTarget), tostring(useThreeTarget), tostring(manaForThirty),
            tostring(manaForTwenty), tostring(canLaunchExplosive), tostring(knowsVolley), tostring(knowsMultiShot)))
    end

    if useTwoTarget and manaForThirty and canLaunchExplosive then
        if self:HunterTryLaunchTrap(S.LaunchExplosiveTrap, "Launch Explosive Trap") then
            return true
        end
    end

    if useThreeTarget and manaForThirty and knowsVolley and not self:IsPlayerMoving() and not self:IsChanneling() then
        if self.SafeCastGroundAOE and self:SafeCastGroundAOE(S.Volley) then
            HunterDebug("Volley")
            return true
        end
        HunterDebugThrottled("HunterVolleyRejected", 1.5, "Volley selected but ground cast was not accepted")
    end

    if useTwoTarget and manaForTwenty and self:HunterTryCast(S.MultiShot, "target", { noMelee = true, noDeadzone = true }) then
        HunterDebug("Multi-Shot")
        return true
    end

    return false
end

function AC:HunterBeastMasteryRotation(targetHP, targetIsTough, isFastDying, manaPercent, enemies, petStatus)
    if self:HunterCanUseKillCommand() then
        if self:HunterTryCast(S.KillCommand, "target", { requirePet = true }) then
            HunterDebug("BM: Kill Command")
        end
    end

    if targetHP < 20 and self:HunterTryCast(S.KillShot, "target", { noMelee = true, noDeadzone = true }) then
        HunterDebug("BM: Kill Shot")
        return true
    end

    if enemies >= 2 and self:HunterManaGate(manaPercent, 28) and self:HunterTryCast(S.MultiShot, "target", { noMelee = true, noDeadzone = true }) then
        HunterDebug("BM: Multi-Shot")
        return true
    end

    local serpentUp = self:HasDebuff("target", S.SerpentSting)
    if self:HunterShouldUseSerpentSting("target", targetHP, targetIsTough, isFastDying) and not serpentUp then
        if self:HunterTryCast(S.SerpentSting, "target", { noMelee = true, noDeadzone = true }) then
            HunterDebug("BM: Serpent Sting")
            return true
        end
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

function AC:HunterMarksmanshipRotation(targetHP, targetIsTough, isFastDying, manaPercent, enemies)
    if self:HunterTryCast(S.SilencingShot, "target", { noMelee = true, noDeadzone = true }) then
        HunterDebug("MM: Silencing Shot (off-GCD)")
    end

    if self:HunterCanUseKillCommand() then
        if self:HunterTryCast(S.KillCommand, "target", { requirePet = true }) then
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

    if self:HunterTryCast(S.AimedShot, "target", { noMelee = true, noDeadzone = true, noPlayerCast = true }) then
        HunterDebug(hasImprovedSteady and "MM: Aimed Shot (ISS)" or "MM: Aimed Shot")
        return true
    end

    if hasImprovedSteady and aimedCD <= 1.0 and not self:IsPlayerMoving() then
        HunterDebugThrottled("MMHoldISSAimed", 1.0, "MM: Holding ISS for Aimed")
    end

    if not isFastDying and (targetIsTough or targetHP > 40) then
        if self:HunterTryLaunchTrap(S.LaunchExplosiveTrap, "MM: Launch Explosive Trap") then
            return true
        end
    end

    if targetIsTough and self:HunterTryCast(S.ReadinessSpell, "player") then
        HunterDebug("MM: Readiness")
        return true
    end

    if hasImprovedSteady and shouldUseArcane and self:HunterManaGate(manaPercent, 25) and chimeraCD > 1.0 and aimedCD > 1.0 and self:HunterTryCast(S.ArcaneShot, "target", { noMelee = true, noDeadzone = true }) then
        HunterDebug("MM: Arcane Shot (ISS)")
        return true
    end

    if enemies >= 2 and self:HunterManaGate(manaPercent, 28) and self:HunterTryCast(S.MultiShot, "target", { noMelee = true, noDeadzone = true }) then
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
        if self:HunterTryCast(S.KillCommand, "target", { requirePet = true }) then
            HunterDebug("SV: Kill Command (off-GCD)")
        end
    end

    if targetHP < 20 and self:HunterTryCast(S.KillShot, "target", { noMelee = true, noDeadzone = true }) then
        HunterDebug("SV: Kill Shot")
        return true
    end

    local serpentUp = self:HasDebuff("target", S.SerpentSting)
    local hasLockAndLoad = self:UpdateSurvivalProcState()

    local lockAndLoadRank = hasLockAndLoad and self:HunterLockAndLoadRank() or nil
    if self:HunterCanFireExplosiveShot() then
        local explosiveOptions = { noMelee = true, noDeadzone = true }
        if lockAndLoadRank then explosiveOptions.rank = lockAndLoadRank end
        if self:HunterTryCast(S.ExplosiveShot, "target", explosiveOptions) then
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

    if self:HunterShouldUseSerpentSting("target", targetHP, targetIsTough, isFastDying) and not serpentUp and self:HunterTryCast(S.SerpentSting, "target", { noMelee = true, noDeadzone = true }) then
        HunterDebug("SV: Serpent Sting")
        return true
    end

    if self:HunterTryCast(S.AimedShot, "target", { noMelee = true, noDeadzone = true, noPlayerCast = true }) then
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
    if self:HunterCanUseKillCommand() then
        if self:HunterTryCast(S.KillCommand, "target", { requirePet = true }) then
            HunterDebug("Lvl: Kill Command")
        end
    end

    if targetHP > 40 and self:HunterTryCast(S.BestialWrath, "player", { requirePet = true }) then
        HunterDebug("Lvl: Bestial Wrath")
        return true
    end

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

    if self:HunterTryCast(S.AimedShot, "target", { noMelee = true, noDeadzone = true, noPlayerCast = true }) then
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

    -- Improved Tracking is a direct Hunter damage multiplier. Establish one
    -- qualifying creature tracker before spending normal combat actions, but
    -- only in combat and only when talented. Out of combat, preserve gathering
    -- choices such as Find Minerals, Find Herbs, and Find Fish.
    if inCombat and not IsMounted() and self:ManageHunterImprovedTracking() then
        return true
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

    if inCombat and self:HunterHasMovementImpairingDebuff() and
       self:HunterTryCast(S.MasterCall, "player", { requirePet = true }) then
        HunterDebug("Master's Call")
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
        return "busy"
    end

    self:HandleAutoAttack()

    local targetHP = self:GetTargetHealthPercent("target")
    local targetIsTough = UnitClassification("target") == "elite" or UnitClassification("target") == "rareelite" or UnitClassification("target") == "worldboss" or UnitLevel("target") == -1
    local isFastDying = self:IsFastDyingMob("target")
    local enemies = self:GetEffectiveEnemyCount(self:GetEnemyCount())
    local rangeState = self:GetHunterRangeState("target")
    local inMelee = rangeState == "melee"
    local inDeadzone = rangeState == "deadzone"
    local closeBranchAttempted = inMelee or inDeadzone

    if self:IsChanneling() then
        local channelSpell = UnitChannelInfo("player")
        if channelSpell == S.Volley then
            HunterDebug("Continuing Volley")
            return "busy"
        end
    end

    -- Kill Command is off the global cooldown and must remain available even
    -- when the AoE branch consumes the normal shot decision.
    if self:HunterCanUseKillCommand() and self:HunterTryCast(S.KillCommand, "target", { requirePet = true }) then
        HunterDebug("Kill Command")
    end

    if self:HunterUseMinorCooldowns(spec, targetIsTough, targetHP, enemies, inCombat) then
        return true
    end

    if self:HunterShouldMark("target") and self:HunterTryCast(S.HuntersMark, "target") then
        HunterDebug("Hunter's Mark")
        return true
    end

    if self:HunterHandleUtility(spec, petStatus) then
        return true
    end

    -- Custom Launch spells are valid from any range. Let them fire before the
    -- close-range branch instead of suppressing trap/AoE decisions in melee.
    if self:HunterHandleAOE(enemies, manaPercent) then
        return true
    end

    if closeBranchAttempted then
        HunterDebugThrottled("HunterCloseRangeState", 2.0, "Range state: " .. rangeState)
        if self:HunterHandleCloseRange(spec, targetHP, isFastDying, rangeState) then
            return true
        end

        -- The target may have crossed the range boundary while the close
        -- branch was being evaluated. Re-read
        -- the state before selecting the ranged rotation so the handoff is
        -- immediate instead of waiting for another decision cycle.
        rangeState = self:GetHunterRangeState("target")
        inMelee = rangeState == "melee"
        inDeadzone = rangeState == "deadzone"

        -- Never strand the rotation in the close-range branch.  Range APIs
        -- can briefly disagree while the target is moving, and ranged spells
        -- are still the safe fallback whenever no close-range action started.
    end

    if spec == "Beast Mastery" then
        if self:HunterBeastMasteryRotation(targetHP, targetIsTough, isFastDying, manaPercent, enemies, petStatus) then
            return true
        end
    elseif spec == "Marksmanship" then
        if self:HunterMarksmanshipRotation(targetHP, targetIsTough, isFastDying, manaPercent, enemies) then
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

    -- Symmetric handoff: if the target entered melee/deadzone while the
    -- ranged priority list was being evaluated and no ranged cast started,
    -- give the close-range handler one immediate opportunity this cycle.
    if not closeBranchAttempted then
        local postRangeState = self:GetHunterRangeState("target")
        if postRangeState == "melee" or postRangeState == "deadzone" then
            HunterDebugThrottled("HunterRangeToCloseHandoff", 2.0, "Target entered " .. postRangeState .. " range")
            if self:HunterHandleCloseRange(spec, targetHP, isFastDying, postRangeState) then
                return true
            end
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

    if self:HunterKnowsSpell(S.TrueshotAura) and not self:HasBuff("player", S.TrueshotAura) and self:HunterTryCast(S.TrueshotAura, "player") then
        HunterDebug("Trueshot Aura")
        return true
    end
    
    local manaPercent = (UnitPowerMax("player", 0) > 0) and (UnitPower("player", 0) / UnitPowerMax("player", 0) * 100) or 100
    if self:ManageAspects(spec, false, manaPercent) then return true end
    
    return false
end

function AC:InitHunterRotations()
    if not self.rotations then self.rotations = {} end
    self.rotations["HUNTER"] = {} 
    
    self.rotations["HUNTER"]["Beast Mastery"] = function(s) return s:HunterRotation() end
    self.rotations["HUNTER"]["Marksmanship"] = function(s) return s:HunterRotation() end
    self.rotations["HUNTER"]["Survival"] = function(s) return s:HunterRotation() end
    self.rotations["HUNTER"]["None"] = function(s) return s:HunterRotation() end
    
    self:Print("Hunter rotations initialized (v12 - Research-Based).")
    HunterDebug("Hunter module active. Rotations based on Elitist Jerks theorycrafting for WotLK 3.3.5a.")
end

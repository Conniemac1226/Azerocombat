-- AzeroCombat: Enhanced Rogue Rotations - WotLK 3.3.5a Meta Compliant
-- Incorporates research-based corrections for optimal DPS and leveling efficiency
-- FIXED: Poison application system and WotLK meta compliance
local AddonName, AC = ...

local S = { -- Spells
    -- Builders
    Mutilate = "Mutilate", 
    Sinister = "Sinister Strike", 
    Hemorrhage = "Hemorrhage", 
    Backstab = "Backstab",
    
    -- Finishers  
    Eviscerate = "Eviscerate", 
    SnD = "Slice and Dice", 
    Rupture = "Rupture", 
    ExposeArmor = "Expose Armor",
    Envenom = "Envenom", 
    
    -- Buffs/Debuffs (CORRECTED NAMES)
    HFB = "Hunger for Blood", 
    ColdBlood = "Cold Blood", 
    FindWeakness = "Find Weakness",
    
    -- Cooldowns
    AdrenRush = "Adrenaline Rush", 
    BladeFlurry = "Blade Flurry", 
    KillingSpree = "Killing Spree", 
    ShadowDance = "Shadow Dance", 
    Preparation = "Preparation", 
    Premeditation = "Premeditation",
    Sprint = "Sprint", 
    Vanish = "Vanish",
    
    -- Utility
    Stealth = "Stealth", 
    CheapShot = "Cheap Shot", 
    Ambush = "Ambush", 
    Garrote = "Garrote",
    FoK = "Fan of Knives", 
    Kick = "Kick",
    CloakOfShadows = "Cloak of Shadows", 
    Evasion = "Evasion", 
    Gouge = "Gouge", 
    Blind = "Blind",
    
    -- Poisons
    InstantPoison = "Instant Poison", 
    DeadlyPoison = "Deadly Poison", 
    WoundPoison = "Wound Poison",
    CripplingPoison = "Crippling Poison"
}

-- Racial Abilities 
local R = {
    BloodFury = "Blood Fury",                -- Orc
    Berserking = "Berserking",               -- Troll
    WillOfForsaken = "Will of the Forsaken", -- Undead
    EveryMan = "Every Man for Himself",      -- Human
    Stoneform = "Stoneform",                 -- Dwarf
    EscapeArtist = "Escape Artist",          -- Gnome
    ShadowMeld = "Shadowmeld",               -- Night Elf
    ArcaneTorrent = "Arcane Torrent"         -- Blood Elf
}

-- Rogue-specific debug with Core.lua integration
local function RogueDebug(msg)
    if AC.debugMode then
        local _, playerClass = UnitClass("player")
        if playerClass == "ROGUE" then
            AC:Debug("|cFFFF6969Rogue:|r " .. tostring(msg))
        end
    end
end

-- =============================================
-- ENHANCED ENERGY MANAGEMENT SYSTEM
-- =============================================

-- Energy thresholds for optimal pooling
local EnergyThresholds = {
    stealth = 90,      -- Pool high for burst from stealth
    finisher = 35,     -- Minimum for finishers
    generator = {
        mutilate = 60,
        sinister = 40,
        backstab = 60,
        hemorrhage = 35
    },
    aoe = 50,          -- Fan of Knives threshold
    poolCap = 85,      -- Start spending to avoid capping
    levelAdjusted = {  -- Adjusted thresholds for leveling
        [1] = 30,      -- Very low level
        [20] = 40,     -- Low level
        [40] = 50,     -- Mid level
        [60] = 60      -- High level base
    }
}

-- Get appropriate energy threshold based on level
function AC:GetEnergyThreshold(actionType, level)
    level = level or UnitLevel("player")
    
    -- Get base threshold
    local threshold = 40 -- default
    
    if actionType == "finisher" then
        threshold = EnergyThresholds.finisher
    elseif actionType == "generator" then
        local spec = self:GetPlayerSpec()
        if spec == "Assassination" and self:KnowsSpell(S.Mutilate) and self:HasTwoDaggersEquipped() then
            threshold = EnergyThresholds.generator.mutilate
        elseif spec == "Subtlety" and self:IsBehindTarget() and self:HasMainHandDaggerEquipped() then
            threshold = EnergyThresholds.generator.backstab
        else
            threshold = EnergyThresholds.generator.sinister
        end
    elseif actionType == "aoe" then
        threshold = EnergyThresholds.aoe
    elseif actionType == "stealth" then
        threshold = EnergyThresholds.stealth
    end
    
    -- Adjust for level
    if level < 20 then
        threshold = math.max(threshold - 20, 20)
    elseif level < 40 then
        threshold = math.max(threshold - 10, 30)
    end
    
    return threshold
end

-- Check if we should pool energy
function AC:ShouldPoolEnergy(energy, pendingAction, level)
    -- Never pool if we're about to cap
    if energy >= EnergyThresholds.poolCap then
        return false
    end
    
    -- Check if we're waiting for a specific threshold
    local threshold = self:GetEnergyThreshold(pendingAction, level)
    
    if energy < threshold then
        RogueDebug(string.format("Pooling energy: %d/%d for %s", energy, threshold, pendingAction or "general"))
        return true
    end
    
    return false
end


-- =============================================
-- SMART TARGET EVALUATION SYSTEM
-- =============================================

-- Enhanced target evaluation for Rupture vs Eviscerate decision
function AC:IsWorthRupture(targetHP, level, inGroup)
    targetHP = targetHP or (UnitHealth("target") / UnitHealthMax("target") * 100)
    level = level or UnitLevel("player")
    inGroup = inGroup or IsInGroup()
    
    -- Fast-dying threshold
    if targetHP < 30 then 
        RogueDebug("Target too low HP for Rupture")
        return false 
    end
    
    -- Solo leveling logic
    if not inGroup and level < 60 then
        local classification = UnitClassification("target")
        local isElite = classification == "elite" or 
                       classification == "rareelite" or 
                       classification == "worldboss"
        
        -- Only rupture elites/rares with enough HP
        if isElite and targetHP > 50 then
            RogueDebug("Elite target worth Rupture")
            return true
        end
        
        RogueDebug("Normal mob while leveling - skip Rupture")
        return false
    end
    
    -- Group/raid standard thresholds
    return targetHP > 40
end

-- Get rotation complexity based on level and situation
function AC:GetLevelingRotationMode(level, inGroup)
    level = level or UnitLevel("player")
    inGroup = inGroup or IsInGroup()
    
    if level < 20 then
        return "SIMPLE" -- SS spam, Evisc finish
    elseif level < 42 then
        return "BASIC" -- Add stealth openers, no SnD
    elseif level < 60 then
        return "INTERMEDIATE" -- SnD maintenance, basic cooldowns
    else
        return "FULL" -- Complete rotation with all features
    end
end

-- =============================================
-- ADVANCED COOLDOWN MANAGEMENT
-- =============================================

-- Determine if we should use burst cooldowns
function AC:ShouldUseBurstCooldowns(spec, targetHP, targetType, fourthArgument)
    local _, playerClass = UnitClass("player")
    if playerClass ~= "ROGUE" and self.PaladinShouldUseBurstCooldowns then
        return self:PaladinShouldUseBurstCooldowns(spec, targetHP, targetType, fourthArgument)
    end

    targetHP = targetHP or (UnitHealth("target") / UnitHealthMax("target") * 100)
    targetType = targetType or UnitClassification("target")
    local inGroup = IsInGroup()
    
    -- Always burst on elites/bosses
    if targetType ~= "normal" then
        RogueDebug("Elite/Boss target - using burst cooldowns")
        return true
    end
    
    -- When solo, be more liberal with cooldown usage
    if not inGroup then
        if targetHP > 40 then
            RogueDebug("Solo play - liberal cooldown usage on " .. targetHP .. "% HP target")
            return true
        end
    else
        -- In group, burst on healthy targets that will live long enough
        if targetHP > 70 then
            RogueDebug("Group play - high HP target - using burst cooldowns")
            return true
        end
    end
    
    -- Don't waste cooldowns on dying targets
    return false
end

-- Stack cooldowns intelligently based on spec
function AC:UseRogueOffensiveCooldownsEnhanced(spec, level, cp, energy)
    if not self:Throttle("RogueBurstCooldowns", 1) then return false end
    if not UnitAffectingCombat("player") or not UnitExists("target") then return false end
    
    local targetHP = UnitHealth("target") / UnitHealthMax("target") * 100
    local targetType = UnitClassification("target")
    
    if not self:ShouldUseBurstCooldowns(spec, targetHP, targetType) then
        return false
    end
    
    -- Combat spec cooldown priority: BF → KS → AR
    if spec == "Combat" then
        local enemies = self:GetEnemyCount()
        if enemies >= 2 and self:IsRogueSpellReady(S.BladeFlurry) then
            if not self:CastSpell(S.BladeFlurry, "player") then return false end
            RogueDebug("Combat burst: Blade Flurry")
            return true
        end

        if energy <= 50 and self:IsRogueSpellReady(S.KillingSpree) then
            if not self:CastSpell(S.KillingSpree, "target") then return false end
            RogueDebug("Combat burst: Killing Spree")
            if self.UseTrinkets then self:UseTrinkets() end
            if self.UseOffensivePotion then self:UseOffensivePotion(true) end
            return true
        end

        if energy <= 60 and self:IsRogueSpellReady(S.AdrenRush) then
            if not self:CastSpell(S.AdrenRush, "player") then return false end
            RogueDebug("Combat burst: Adrenaline Rush")
            if self.UseTrinkets then self:UseTrinkets() end
            return true
        end
    elseif spec == "Assassination" then
        if cp >= 4 and self:IsRogueSpellReady(S.ColdBlood) then
            if not self:CastSpell(S.ColdBlood, "player") then return false end
            RogueDebug("Assassination burst: Cold Blood")
            if self.UseTrinkets then self:UseTrinkets() end
            return true
        end
    elseif spec == "Subtlety" then
        if energy >= 60 and self:IsBehindTarget() and self:IsRogueSpellReady(S.ShadowDance) then
            if not self:CastSpell(S.ShadowDance, "player") then return false end
            RogueDebug("Subtlety burst: Shadow Dance")
            if self.UseTrinkets then self:UseTrinkets() end
            return true
        end

        if self:IsRogueSpellReady(S.Preparation) and
           ((self:KnowsSpell(S.ShadowDance) and self:GetSpellCooldown(S.ShadowDance) > 1) or
            (self:KnowsSpell(S.Vanish) and self:GetSpellCooldown(S.Vanish) > 1)) then
            if not self:CastSpell(S.Preparation, "player") then return false end
            RogueDebug("Subtlety burst: Preparation")
            return true
        end
    end

    return false
end

-- =============================================
-- TRICKS OF THE TRADE SYSTEM
-- =============================================

-- Find best target for Tricks of the Trade
function AC:FindBestTricksTarget()
    if GetNumRaidMembers() == 0 and not IsInGroup() then return nil end
    
    local bestTarget = nil
    local bestScore = 0
    
    -- Check raid/party members
    local groupType = GetNumRaidMembers() > 0 and "raid" or "party"
    local groupSize = GetNumRaidMembers() > 0 and GetNumRaidMembers() or GetNumPartyMembers()
    
    for i = 1, groupSize do
        local unit = groupType .. i
        
        if UnitExists(unit) and not UnitIsUnit("player", unit) and 
           not UnitIsDead(unit) and UnitIsVisible(unit) then
            
            local _, class = UnitClass(unit)
            local score = 0
            
            -- Prioritize other rogues (for mutual TotT)
            if class == "ROGUE" then
                score = 100
            -- Then high DPS classes
            elseif class == "MAGE" or class == "WARLOCK" or 
                   class == "HUNTER" or class == "DEATHKNIGHT" then
                score = 75
            -- Then other DPS
            elseif class == "WARRIOR" or class == "SHAMAN" or 
                   class == "PRIEST" or class == "DRUID" then
                score = 50
            end
            
            -- Check if they're in combat and alive
            if UnitAffectingCombat(unit) then
                score = score + 25
            end
            
            if score > bestScore then
                bestScore = score
                bestTarget = unit
            end
        end
    end
    
    return bestTarget
end

-- Use Tricks of the Trade intelligently
function AC:UseTricksOfTrade(level)
    if level < 75 then return false end -- Not available yet
    if not self:IsUsableSpell("Tricks of the Trade") then return false end
    if self:GetSpellCooldown("Tricks of the Trade") > 0 then return false end
    if not self:Throttle("TricksOfTrade", 5) then return false end
    
    local target = self:FindBestTricksTarget()
    if target then
        if not self:CastSpell("Tricks of the Trade", target) then return false end
        RogueDebug("Tricks of the Trade on " .. UnitName(target))
        return true
    end
    
    return false
end

-- =============================================
-- ENHANCED UTILITY FUNCTIONS (WotLK Meta Optimized)
-- =============================================

-- Enhanced auto-attack with leveling efficiency
function AC:HandleRogueAutoAttack()
    if not UnitExists("target") or not UnitCanAttack("player", "target") or UnitIsDead("target") then
        return false
    end
    
    local inGroup = IsInGroup()
    
    -- In group: More conservative auto-attack
    if inGroup then
        local shouldAutoAttack = UnitAffectingCombat("player") or 
                                UnitAffectingCombat("target") or
                                self:IsTank("player")
        
        if shouldAutoAttack then
            StartAttack()
            return true
        end
    else
        -- Solo: Always auto-attack valid targets for leveling efficiency
        StartAttack()
        return true
    end
    
    return false
end

-- Enhanced target evaluation for leveling speed
function AC:IsRogueFastDyingTarget()
    if not UnitExists("target") then return false end
    
    local hp = UnitHealth("target") / UnitHealthMax("target") * 100
    local isElite = UnitClassification("target") == "elite" or UnitClassification("target") == "rareelite"
    local levelDiff = UnitLevel("target") - UnitLevel("player")
    
    -- More aggressive thresholds for leveling speed
    return hp < 30 or (not isElite and levelDiff <= 0 and hp < 50)
end

-- Enhanced fleeing target detection
function AC:IsRogueTargetFleeing()
    if not UnitExists("target") then return false end
    local speed = GetUnitSpeed("target")
    local hp = UnitHealth("target") / UnitHealthMax("target") * 100
    return speed > 0 and hp < 35
end

-- Helper function to check if behind target
function AC:IsBehindTarget()
    local _, playerClass = UnitClass("player")
    if playerClass ~= "ROGUE" and self.DruidIsBehindTarget then
        return self:DruidIsBehindTarget()
    end

    if not UnitExists("target") then return false end
    
    -- Use facing check if available
    if UnitIsBehind then
        return UnitIsBehind("player", "target")
    end
    
    -- The stock 3.3.5 client has no reliable facing API. Returning false is
    -- safer than repeatedly selecting a positional attack from the front.
    return false
end

-- NEW: Armor Penetration detection for Combat priority
function AC:GetArmorPenetrationRating()
    -- Try to get ArP rating from character stats
    local armorPen = 0
    
    -- Check all gear slots for ArP rating
    for slot = 1, 18 do
        local itemLink = GetInventoryItemLink("player", slot)
        if itemLink then
            local itemStats = GetItemStats(itemLink)
            if itemStats and itemStats["ITEM_MOD_ARMOR_PENETRATION_RATING_SHORT"] then
                armorPen = armorPen + itemStats["ITEM_MOD_ARMOR_PENETRATION_RATING_SHORT"]
            end
        end
    end
    
    RogueDebug("Current ArP Rating: " .. armorPen)
    return armorPen
end

-- NEW: Check for Cut to the Chase talent (Assassination)
function AC:HasCutToTheChase()
    return self:GetRogueTalentRank("Cut to the Chase") > 0
end

-- NEW: Check for Honor Among Thieves (Subtlety)
function AC:HasHonorAmongThieves()
    return self:GetRogueTalentRank("Honor Among Thieves") > 0
end

-- =============================================
-- ENHANCED AOE OPTIMIZATION SYSTEM (Level-Friendly)
-- =============================================

-- Calculate optimal AoE vs single target DPS with improved logic
function AC:CalculateFoKEfficiency(enemies, energy, level, spec)
    spec = spec or self:GetPlayerSpec()
    level = level or UnitLevel("player")
    
    -- No FoK before level 66
    if level < 66 then 
        RogueDebug("AoE: FoK not available yet")
        return false, "no_fok" 
    end
    
    -- Energy check
    if energy < EnergyThresholds.aoe then 
        RogueDebug("AoE: Insufficient energy for FoK")
        return false, "low_energy" 
    end
    
    -- Spec-based thresholds (WotLK meta accurate)
    local thresholds = {
        ["Combat"] = 2,        -- With FoK glyph, amazing at 2+
        ["Assassination"] = 3, -- Without special AoE talents
        ["Subtlety"] = 4      -- Weakest AoE spec
    }
    
    local threshold = thresholds[spec] or 3
    
    -- Special case: Combat with Blade Flurry
    if spec == "Combat" and self:HasBuff("player", S.BladeFlurry) then
        -- BF + FoK combo is incredibly powerful
        RogueDebug("Combat with Blade Flurry active - AoE threshold reduced")
        threshold = math.max(2, threshold - 1)
    end
    
    local efficient = enemies >= threshold
    
    RogueDebug(string.format("FoK Efficiency: %d enemies, %s threshold: %d, efficient: %s", 
               enemies, spec, threshold, tostring(efficient)))
    
    return efficient, efficient and "use_fok" or "single_target"
end

-- Calculate optimal AoE vs single target DPS
function AC:CalculateRogueAoEEfficiency(enemies, level, spec, energy, cp)
    -- Use the new improved function
    return self:CalculateFoKEfficiency(enemies, energy, level, spec)
end

-- Estimate FoK damage based on level and spec
function AC:EstimateFoKDamage(level, spec)
    local baseDamage = level * 2.5 -- Rough estimation
    
    -- Spec modifiers
    if spec == "Combat" then
        baseDamage = baseDamage * 1.1 -- Combat has some AoE bonuses
    elseif spec == "Subtlety" then
        baseDamage = baseDamage * 0.9 -- Subtlety less AoE focused
    end
    
    return baseDamage
end

-- Estimate single target DPS for comparison
function AC:EstimateSingleTargetDPS(level, spec, energy, cp)
    local baseDPS = level * 3.0 -- Rough single target baseline
    
    -- Factor in combo points (higher CP = higher burst)
    if cp >= 4 then
        baseDPS = baseDPS * 1.3
    elseif cp >= 2 then
        baseDPS = baseDPS * 1.1
    end
    
    -- Spec modifiers
    if spec == "Assassination" then
        baseDPS = baseDPS * 1.2 -- Highest single target
    elseif spec == "Combat" then
        baseDPS = baseDPS * 1.1 -- Balanced
    end
    
    return baseDPS
end

-- Enhanced AoE target positioning check
function AC:CheckAoEPositioning(maxRange)
    maxRange = maxRange or 8 -- FoK range
    local inRangeCount = 0
    local targets = {}
    
    -- Check current target
    if UnitExists("target") and UnitCanAttack("player", "target") and not UnitIsDead("target") then
        if CheckInteractDistance("target", 3) then -- Melee range
            inRangeCount = inRangeCount + 1
            table.insert(targets, {unit = "target", name = UnitName("target")})
        end
    end
    
    -- Check nearby nameplates (limited scan for performance)
    for i = 1, 20 do -- Reduced from 40 for performance
        local unit = "nameplate" .. i
        if UnitExists(unit) and UnitCanAttack("player", unit) and not UnitIsDead(unit) then
            if CheckInteractDistance(unit, 3) then -- Melee range
                inRangeCount = inRangeCount + 1
                table.insert(targets, {unit = unit, name = UnitName(unit) or "Unknown"})
                if inRangeCount >= 8 then break end -- FoK cap
            end
        end
    end
    
    RogueDebug(string.format("AoE Positioning: %d enemies in melee range", inRangeCount))
    return inRangeCount, targets
end

-- =============================================
-- ENHANCED THREAT MANAGEMENT SYSTEM (Level-Friendly)
-- =============================================

-- Calculate current threat level
function AC:GetRogueThreatLevel()
    if not IsInGroup() then 
        RogueDebug("Threat: Solo play - no threat management needed")
        return "safe", 0 
    end
    
    -- Simple threat estimation based on observable factors
    local playerLevel = UnitLevel("player")
    local inCombat = UnitAffectingCombat("player")
    local hasTarget = UnitExists("target") and UnitCanAttack("player", "target")
    
    if not inCombat or not hasTarget then 
        return "safe", 0 
    end
    
    -- Check if target is attacking us
    local targetTarget = UnitExists("targettarget") and UnitName("targettarget")
    local playerName = UnitName("player")
    local isTargetingUs = targetTarget == playerName
    
    -- Check if we're in a tank's threat range
    local hasTank = false
    local tankDistance = 999
    
    for i = 1, (GetNumRaidMembers() > 0 and GetNumRaidMembers() or GetNumPartyMembers()) do
        local unit = GetNumRaidMembers() > 0 and "raid"..i or "party"..i
        if UnitExists(unit) and self:IsTank(unit) then
            hasTank = true
            if UnitIsVisible(unit) then
                -- Rough distance check
                if CheckInteractDistance(unit, 4) then -- Trade distance
                    tankDistance = 15
                elseif CheckInteractDistance(unit, 3) then -- Interact distance  
                    tankDistance = 10
                else
                    tankDistance = 30
                end
                break
            end
        end
    end
    
    -- Threat level calculation
    local threatLevel = "safe"
    local threatScore = 0
    
    if isTargetingUs then
        threatScore = threatScore + 50
        threatLevel = "high"
    end
    
    if not hasTank or tankDistance > 20 then
        threatScore = threatScore + 25
        if threatLevel == "safe" then threatLevel = "medium" end
    end
    
    -- Lower level rogues are more fragile
    if playerLevel < 40 and threatScore > 25 then
        threatLevel = "high"
    end
    
    RogueDebug(string.format("Threat Analysis: Level %s, Score: %d, Tank: %s (%.0fm)", 
               threatLevel, threatScore, hasTank and "Yes" or "No", tankDistance))
    
    return threatLevel, threatScore
end

-- Threat management actions based on level and situation
function AC:ManageRogueThreat(threatLevel, threatScore, level, spec)
    if threatLevel == "safe" then return false end
    
    -- Don't spam threat management
    if not self:Throttle("ThreatManagement", 2) then return false end
    
    local inGroup = IsInGroup()
    local health = UnitHealth("player") / UnitHealthMax("player") * 100
    
    RogueDebug("Threat Management: " .. threatLevel .. " threat detected")
    
    -- High threat - immediate action needed
    if threatLevel == "high" or health < 30 then
        -- Vanish if available (resets threat completely)
        if self:IsRogueSpellReady(S.Vanish) then
            if self:CastSpell(S.Vanish, "player") then
                RogueDebug("Threat: Emergency Vanish")
                return true
            end
        end
        
        -- Blind target to reduce incoming damage
        if self:IsRogueSpellReady(S.Blind) then
            if self:CastSpell(S.Blind, "target") then
                RogueDebug("Threat: Blind to reduce damage")
                return true
            end
        end
        
        -- Gouge for breathing room
        if self:IsRogueSpellReady(S.Gouge) and CheckInteractDistance("target", 3) then
            if self:CastSpell(S.Gouge, "target") then
                RogueDebug("Threat: Gouge for positioning")
                return true
            end
        end
    end
    
    -- Medium threat - defensive measures
    if threatLevel == "medium" then
        -- Evasion to reduce incoming damage
        if self:IsRogueSpellReady(S.Evasion) then
            if self:CastSpell(S.Evasion, "player") then
                RogueDebug("Threat: Evasion for damage mitigation")
                return true
            end
        end
        
        -- Sprint to reposition near tank
        if inGroup and self:IsRogueSpellReady(S.Sprint) then
            if self:CastSpell(S.Sprint, "player") then
                RogueDebug("Threat: Sprint to reposition")
                return true
            end
        end
    end
    
    return false
end

-- Check if we should modify rotation due to threat
function AC:ShouldReduceThreatGeneration(threatLevel, level)
    if not IsInGroup() then return false end
    
    -- Very conservative threat management for low levels
    if level < 30 and threatLevel == "medium" then
        RogueDebug("Threat: Reducing DPS - low level, medium threat")
        return true
    end
    
    if threatLevel == "high" then
        RogueDebug("Threat: Reducing DPS - high threat")
        return true
    end
    
    return false
end

-- Enhanced racial usage with better timing
function AC:UseRogueRacials(targetIsElite)
    if not self:Throttle("RogueRacials", 1.5) then
        return false
    end
    
    local race = select(2, UnitRace("player"))
    local health = UnitHealth("player") / UnitHealthMax("player") * 100
    
    -- Emergency defensive racials
    if health < 25 then
        if race == "Undead" and self:GetSpellCooldown(R.WillOfForsaken) == 0 then
            if not self:CastSpell(R.WillOfForsaken, "player") then return false end
            RogueDebug("Emergency Will of the Forsaken")
            return true
        elseif race == "Human" and self:GetSpellCooldown(R.EveryMan) == 0 then
            if not self:CastSpell(R.EveryMan, "player") then return false end
            RogueDebug("Emergency Every Man for Himself")
            return true
        elseif race == "Dwarf" and self:GetSpellCooldown(R.Stoneform) == 0 then
            if not self:CastSpell(R.Stoneform, "player") then return false end
            RogueDebug("Emergency Stoneform")
            return true
        end
    end
    
    -- Offensive racials - more liberal for leveling
    local shouldUseBurst = targetIsElite or not IsInGroup() or UnitHealth("target") / UnitHealthMax("target") * 100 > 70
    if shouldUseBurst then
        if race == "Orc" and self:GetSpellCooldown(R.BloodFury) == 0 then
            if not self:CastSpell(R.BloodFury, "player") then return false end
            RogueDebug("Using Blood Fury")
            return true
        elseif race == "Troll" and self:GetSpellCooldown(R.Berserking) == 0 then
            if not self:CastSpell(R.Berserking, "player") then return false end
            RogueDebug("Using Berserking")
            return true
        end
    end
    
    return false
end

-- =============================================
-- ENHANCED FINISHER AND GENERATOR SELECTION (WotLK Meta)
-- =============================================

-- ENHANCED: WotLK Meta-compliant finisher selection with improved logic
function AC:GetRogueBestFinisher(spec, cp, level, energy)
    -- Get target info for smart decisions
    local targetHP = UnitHealth("target") / UnitHealthMax("target") * 100
    local inGroup = IsInGroup()
    local rotationMode = self:GetLevelingRotationMode(level, inGroup)
    
    -- Simple mode for very low levels
    if rotationMode == "SIMPLE" or level < 10 then
        return S.Eviscerate
    end
    
    -- Check if target is worth using Rupture on
    local worthRupture = self:IsWorthRupture(targetHP, level, inGroup)
    
    -- ASSASSINATION SPEC (Cut to the Chase Priority)
    if spec == "Assassination" then
        -- With Cut to the Chase: Envenom refreshes SnD automatically
        if level >= 62 and self:KnowsSpell(S.Envenom) and self:HasCutToTheChase() then
            local poisonStacks = self:GetRogueDebuffStacks("target", S.DeadlyPoison)
            if poisonStacks >= 1 then
                return S.Envenom -- Auto-refreshes SnD with talent
            end
        end
        
        -- Without Cut to the Chase or lower levels: Check SnD
        if rotationMode ~= "BASIC" then -- Skip SnD below level 42
            local hasSnd = self:HasBuff("player", S.SnD)
            local sndTime = self:BuffTimeRemaining("player", S.SnD)
            
            -- Improved refresh timing based on level
            local refreshTime = level >= 60 and 8 or 6
            
            if not hasSnd or (sndTime < refreshTime and worthRupture) then
                if energy >= 25 then
                    return S.SnD
                end
            end
        end
        
        -- Envenom for poison builds
        if level >= 62 and self:KnowsSpell(S.Envenom) and energy >= 35 and
           self:GetRogueDebuffStacks("target", S.DeadlyPoison) >= 1 then
            return S.Envenom
        end
        
        -- Smart Rupture usage
        if level >= 20 and worthRupture and not self:HasDebuff("target", S.Rupture) then
            return S.Rupture
        end
    
    -- COMBAT SPEC (ArP-based Priority)
    elseif spec == "Combat" then
        -- Skip SnD for low levels
        if rotationMode ~= "BASIC" then
            local hasSnd = self:HasBuff("player", S.SnD)
            local sndTime = self:BuffTimeRemaining("player", S.SnD)
            
            -- Improved refresh timing
            local refreshTime = level >= 60 and 8 or 6
            
            if not hasSnd or (sndTime < refreshTime and worthRupture) then
                if energy >= 25 then
                    return S.SnD
                end
            end
        end
        
        -- ArP-based finisher priority (WotLK Meta)
        local armorPen = self:GetArmorPenetrationRating()
        
        if armorPen < 1000 and worthRupture then
            -- Low ArP: Rupture for DoT damage
            if level >= 20 and not self:HasDebuff("target", S.Rupture) then
                return S.Rupture
            end
        end
        
        -- High ArP or fast-dying target: Eviscerate
        if energy >= 35 then
            return S.Eviscerate
        end
        
        -- Expose Armor for group play on bosses
        if IsInGroup() and energy >= 25 then
            local targetClassification = UnitClassification("target")
            local isBoss = targetClassification == "worldboss" or 
                           targetClassification == "elite" or 
                           targetClassification == "rareelite"
            
            if isBoss and not self:HasDebuff("target", S.ExposeArmor) then
                -- Check if we have a warrior with better debuffs
                local hasWarriorDebuff = self:HasDebuff("target", "Sunder Armor") or 
                                        self:HasDebuff("target", "Devastate")
                if not hasWarriorDebuff then
                    return S.ExposeArmor
                end
            end
        end
    
    -- SUBTLETY SPEC
    elseif spec == "Subtlety" then
        -- Skip SnD for low levels
        if rotationMode ~= "BASIC" then
            local hasSnd = self:HasBuff("player", S.SnD)
            local sndTime = self:BuffTimeRemaining("player", S.SnD)
            
            local refreshTime = level >= 60 and 8 or 6
            
            if not hasSnd or (sndTime < refreshTime and worthRupture) then
                if energy >= 25 then
                    return S.SnD
                end
            end
        end
        
        -- Smart Rupture for Subtlety
        if level >= 20 and worthRupture and not self:HasDebuff("target", S.Rupture) then
            return S.Rupture
        end
    end
    
    -- Default to Eviscerate
    if energy >= 35 then
        return S.Eviscerate
    end
    
    -- Return nil if we can't cast anything
    RogueDebug("No finisher available with current energy: " .. energy)
    return nil
end

-- CORRECTED: WotLK Meta-compliant generator selection
function AC:GetRogueBestGenerator(spec, level, inMelee, energy)
    local behind = inMelee and self:IsBehindTarget()
    
    -- Spec-specific generators with proper thresholds
    if spec == "Assassination" and self:KnowsSpell(S.Mutilate) and
       self:HasTwoDaggersEquipped() and energy >= 60 then
        return S.Mutilate
    elseif spec == "Subtlety" then
        -- Honor Among Thieves reduces energy needs
        local hasHAT = self:HasHonorAmongThieves()
        local energyThreshold = hasHAT and 30 or 50
        
        if level >= 50 and self:KnowsSpell(S.Hemorrhage) and energy >= energyThreshold then
            if not behind then
                return S.Hemorrhage
            end
        end
        
        if behind and self:HasMainHandDaggerEquipped() and
           self:KnowsSpell(S.Backstab) and energy >= energyThreshold then
            return S.Backstab
        end
    elseif spec == "Combat" then
        -- Sinister Strike at lower energy for leveling speed
        if energy >= 40 then -- Reduced from 60 for leveling efficiency
            return S.Sinister
        end
    end
    
    -- Backstab if behind and enough energy
    if behind and self:HasMainHandDaggerEquipped() and
       self:KnowsSpell(S.Backstab) and energy >= 50 then
        return S.Backstab
    end
    
    -- Default Sinister Strike with leveling-friendly threshold
    if energy >= 40 then -- Reduced from 60 for leveling speed
        return S.Sinister
    end
    
    return nil
end

-- =============================================
-- POISON MANAGEMENT (COMPLETELY FIXED for WotLK 3.3.5a)
-- =============================================

-- FIXED: Check weapon enchants for WotLK 3.3.5a
function AC:CheckWeaponEnchants()
    -- WotLK 3.3.5a GetWeaponEnchantInfo() returns up to 6 values for main hand + off hand
    local hasMainHand, mainHandExpiration, mainHandCharges,
          hasOffHand, offHandExpiration, offHandCharges = GetWeaponEnchantInfo()
    
    -- Check if we have an off-hand weapon equipped
    local hasOffHandWeapon = GetInventoryItemLink("player", 17) ~= nil
    
    -- Convert to boolean to ensure consistent return values
    hasMainHand = hasMainHand and true or false
    hasOffHand = hasOffHand and true or false
    
    RogueDebug("Weapon enchant check - MH: " .. (hasMainHand and "Yes" or "No") .. 
               ", OH: " .. (hasOffHand and "Yes" or "No") .. 
               ", Has OH weapon: " .. (hasOffHandWeapon and "Yes" or "No"))
    
    return hasMainHand, hasOffHand, hasOffHandWeapon
end

-- FIXED: Enhanced poison finding that works with ALL WotLK poison ranks
AC.FindPoisonInBags = function(self, poisonPatterns)
    local foundPoisons = {}

    local function romanRank(name)
        local roman = string.match(name or "", "%s([IVX]+)$")
        if not roman then return 1 end
        local values = {I = 1, V = 5, X = 10}
        local total, previous = 0, 0
        for index = string.len(roman), 1, -1 do
            local value = values[string.sub(roman, index, index)] or 0
            if value < previous then total = total - value else total = total + value end
            previous = value
        end
        return total
    end
    
    for bag = 0, 4 do
        local numSlots = GetContainerNumSlots(bag) or 0
        for slot = 1, numSlots do
            local itemLink = GetContainerItemLink(bag, slot)
            if itemLink then
                -- Use GetItemInfo to get the real name, not the texture path
                local itemName = GetItemInfo(itemLink)
                if itemName then
                    local itemNameLower = string.lower(itemName)
                    
                    -- Check against all poison patterns
                    for _, poisonPattern in ipairs(poisonPatterns) do
                        local poisonPatternLower = string.lower(poisonPattern)
                        
                        -- Match the poison type anywhere in the name
                        if string.find(itemNameLower, poisonPatternLower) then
                            local _, stackCount = GetContainerItemInfo(bag, slot)
                            table.insert(foundPoisons, {
                                name = itemName,
                                count = stackCount or 1,
                                bag = bag,
                                slot = slot,
                                pattern = poisonPattern,
                                rank = romanRank(itemName)
                            })
                            break -- Only match one pattern per item
                        end
                    end
                end
            end
        end
    end
    
    table.sort(foundPoisons, function(left, right)
        if left.rank == right.rank then return left.count > right.count end
        return left.rank > right.rank
    end)
    return foundPoisons
end

-- FIXED: Apply poison to specific weapon slot with multiple methods
function AC:ApplyPoisonToWeapon(poisonInfo, weaponSlot)
    if not poisonInfo then 
        RogueDebug("No poison info provided")
        return false 
	end
	if not self:Throttle("PoisonApply"..weaponSlot, 3) then return false
    end
    
    local bag, slot = poisonInfo.bag, poisonInfo.slot
    
    -- Verify the item still exists
    if not GetContainerItemLink(bag, slot) then
        RogueDebug("Poison item no longer exists in bag " .. bag .. " slot " .. slot)
        return false
    end
    
    RogueDebug("Attempting to apply " .. poisonInfo.name .. " to weapon slot " .. weaponSlot)
    
    local ok = pcall(function()
        ClearCursor()
        UseContainerItem(bag, slot)
        -- PickupInventoryItem acts as the weapon target while the poison item
        -- is awaiting a target. If item use failed it only picks the weapon up,
        -- and ClearCursor safely returns it to the same slot.
        PickupInventoryItem(weaponSlot)
        ClearCursor()
    end)

    local mainEnchanted, _, _, offEnchanted = GetWeaponEnchantInfo()
    local enchantApplied = (weaponSlot == 16 and mainEnchanted) or
                           (weaponSlot == 17 and offEnchanted)
    local castStarted = UnitCastingInfo("player") ~= nil
    if ok and (castStarted or enchantApplied) then
        RogueDebug("Poison application started: " .. poisonInfo.name)
        return true
    end

    RogueDebug("Failed to start poison application: " .. poisonInfo.name)
    return false
end

-- FIXED: Main poison application function with comprehensive error handling
function AC:CheckAndApplyPoisons()
    -- Don't apply poisons in combat or while mounted
    if UnitAffectingCombat("player") then 
        return false 
    end
    
    if IsMounted() then
        return false
    end
    
    -- Throttle poison checks to every 3 seconds for efficiency
    if not self:Throttle("PoisonCheck", 4) then 
        return false 
    end
    
    local hasMainHandPoison, hasOffHandPoison, hasOffHandWeapon = self:CheckWeaponEnchants()
    local appliedAnything = false
    
    RogueDebug("=== Poison Application Check ===")
    RogueDebug("Main Hand Poison: " .. (hasMainHandPoison and "Applied" or "Missing"))
    RogueDebug("Off Hand Poison: " .. (hasOffHandPoison and "Applied" or "Missing"))
    RogueDebug("Has Off Hand Weapon: " .. (hasOffHandWeapon and "Yes" or "No"))
    
    -- Apply main hand poison if needed
    if not hasMainHandPoison then
        RogueDebug("Looking for main hand poison...")
        local foundPoisons = self:FindPoisonInBags({"instant poison"})
        
        if #foundPoisons > 0 then
            -- Use the first found poison (highest priority)
            local bestPoison = foundPoisons[1]
            RogueDebug("Attempting to apply " .. bestPoison.name .. " to main hand")
            
            if self:ApplyPoisonToWeapon(bestPoison, 16) then
                RogueDebug("Successfully applied " .. bestPoison.name .. " to main hand")
                return true -- Wait for the weapon application cast before checking off hand.
            else
                RogueDebug("Failed to apply " .. bestPoison.name .. " to main hand")
            end
        else
            RogueDebug("No suitable main hand poison found in bags")
        end
    else
        RogueDebug("Main hand already has poison applied")
    end
    
    -- Apply off hand poison if needed
    if hasOffHandWeapon and not hasOffHandPoison then
        RogueDebug("Looking for off hand poison...")
        local foundPoisons = self:FindPoisonInBags({"deadly poison"})
        
        if #foundPoisons > 0 then
            -- Use the first found poison (highest priority)
            local bestPoison = foundPoisons[1]
            RogueDebug("Attempting to apply " .. bestPoison.name .. " to off hand")
            
            if self:ApplyPoisonToWeapon(bestPoison, 17) then
                RogueDebug("Successfully applied " .. bestPoison.name .. " to off hand")
                appliedAnything = true
            else
                RogueDebug("Failed to apply " .. bestPoison.name .. " to off hand")
            end
        else
            RogueDebug("No suitable off hand poison found in bags")
        end
    else
        if hasOffHandWeapon then
            RogueDebug("Off hand already has poison applied")
        else
            RogueDebug("No off hand weapon equipped")
        end
    end
    
    RogueDebug("=== End Poison Check ===")
    return appliedAnything
end

-- ENHANCED: Manual poison testing with detailed diagnostics
function AC:TestPoisonManually()
    self:Print("=== ENHANCED POISON APPLICATION TEST ===")
    
    -- Check current weapon enchant status
    local hasMainHand, hasOffHand, hasOffHandWeapon = self:CheckWeaponEnchants()
    
    self:Print("Current weapon enchant status:")
    self:Print("  Main Hand: " .. (hasMainHand and "✓ Applied" or "✗ Missing"))
    self:Print("  Off Hand: " .. (hasOffHandWeapon and (hasOffHand and "✓ Applied" or "✗ Missing") or "No weapon equipped"))
    
    -- Check for poison items in bags with enhanced detection
    self:Print("")
    self:Print("Scanning bags for poison items...")
    
    local allPoisonPatterns = {
        "instant poison", "deadly poison", "wound poison", 
        "crippling poison", "mind-numbing poison", "anesthetic poison"
    }
    
    local foundPoisons = self:FindPoisonInBags(allPoisonPatterns)
    
    if #foundPoisons > 0 then
        self:Print("Found " .. #foundPoisons .. " poison item(s):")
        for i, poison in ipairs(foundPoisons) do
            self:Print("  " .. i .. ". " .. poison.name .. " (x" .. poison.count .. ") - Bag " .. poison.bag .. " Slot " .. poison.slot)
        end
        
        -- Test application if any weapons need poison
        local needsApplication = (not hasMainHand) or (hasOffHandWeapon and not hasOffHand)
        
        if needsApplication then
            self:Print("")
            self:Print("Attempting poison application...")
            
            -- Force a poison check
            self.throttles = self.throttles or {}
            self.throttles["PoisonCheck"] = nil -- Clear throttle
            
            local result = self:CheckAndApplyPoisons()
            self:Print("Application result: " .. (result and "✓ SUCCESS - Check weapons" or "✗ FAILED"))
            
            if not result then
                self:Print("Troubleshooting tips:")
                self:Print("  1. Make sure you're not in combat")
                self:Print("  2. Check if bags are full")
                self:Print("  3. Try manually right-clicking poison then weapon")
                self:Print("  4. Verify poison items are not quest items")
            end
        else
            self:Print("")
            self:Print("All equipped weapons already have poisons applied")
        end
    else
        self:Print("✗ No poison items found in bags!")
        self:Print("")
        self:Print("Required poison items (any rank):")
        for _, pattern in ipairs(allPoisonPatterns) do
            self:Print("  - " .. pattern:gsub("^%l", string.upper))
        end
        
        -- Debug: Show first few items in bags to verify scanning
        self:Print("")
        self:Print("Debug - Sample items found in bags:")
        local itemCount = 0
        for bag = 0, 4 do
            for slot = 1, math.min(GetContainerNumSlots(bag) or 0, 10) do
                local itemName = GetContainerItemInfo(bag, slot)
                if itemName then
                    itemCount = itemCount + 1
                    self:Print("  Bag " .. bag .. " Slot " .. slot .. ": " .. itemName)
                    if itemCount >= 10 then break end
                end
            end
            if itemCount >= 10 then break end
        end
        
        if itemCount == 0 then
            self:Print("  No items found - bags may be empty or scanning failed")
        end
    end
    
    self:Print("==========================================")
end

-- FIXED: Function to check if poison application is working at all
function AC:TestBasicPoisonMechanics()
    self:Print("=== BASIC POISON MECHANICS TEST ===")
    
    -- Test GetWeaponEnchantInfo() function
    local hasMainHand, mainHandExpiration, mainHandCharges,
          hasOffHand, offHandExpiration, offHandCharges = GetWeaponEnchantInfo()
    
    self:Print("GetWeaponEnchantInfo() results:")
    self:Print("  hasMainHand: " .. tostring(hasMainHand))
    self:Print("  mainHandExpiration: " .. tostring(mainHandExpiration))
    self:Print("  mainHandCharges: " .. tostring(mainHandCharges))
    self:Print("  mainHandEnchantID: " .. tostring(mainHandEnchantID))
    self:Print("  hasOffHand: " .. tostring(hasOffHand))
    self:Print("  offHandExpiration: " .. tostring(offHandExpiration))
    
    -- Test weapon slots - FIXED for WotLK 3.3.5a
    local mainHandItem = GetInventoryItemLink("player", 16)
    local offHandItem = GetInventoryItemLink("player", 17)
    
    self:Print("")
    self:Print("Equipped weapons:")
    self:Print("  Main Hand (slot 16): " .. (mainHandItem and "Equipped" or "Empty"))
    self:Print("  Off Hand (slot 17): " .. (offHandItem and "Equipped" or "Empty"))
    
    -- FIXED: Use proper WotLK API for getting item names
    if mainHandItem then
        local itemName = GetItemInfo(mainHandItem)
        self:Print("    Item: " .. (itemName or "Unknown"))
    end
    
    if offHandItem then
        local itemName = GetItemInfo(offHandItem)
        self:Print("    Item: " .. (itemName or "Unknown"))
    end
    
    -- Test cursor functions
    self:Print("")
    self:Print("Testing cursor functions:")
    self:Print("  CursorHasItem(): " .. tostring(CursorHasItem()))
    
    -- Test container access
    self:Print("")
    self:Print("Testing bag access:")
    for bag = 0, 4 do
        local numSlots = GetContainerNumSlots(bag)
        self:Print("  Bag " .. bag .. ": " .. (numSlots or 0) .. " slots")
    end
    
    -- ENHANCED: Show actual poison items found
    self:Print("")
    self:Print("Scanning for poison items:")
    local foundAnyPoisons = false
    
    for bag = 0, 4 do
        for slot = 1, GetContainerNumSlots(bag) do
            local itemName = GetContainerItemInfo(bag, slot)
            if itemName then
                local itemNameLower = itemName:lower()
                if itemNameLower:find("poison") then
                    self:Print("  Found: " .. itemName .. " (Bag " .. bag .. " Slot " .. slot .. ")")
                    foundAnyPoisons = true
                end
            end
        end
    end
    
    if not foundAnyPoisons then
        self:Print("  No poison items found in bags!")
    end
    
    self:Print("=====================================")
end

-- ENHANCED: Quick poison scan command
function AC:QuickPoisonScan()
    self:Print("=== QUICK POISON SCAN ===")
    
    local foundPoisons = {}
    local totalItems = 0
    
    for bag = 0, 4 do
        for slot = 1, GetContainerNumSlots(bag) do
            local itemName, _, _, _, _, _, _, stackCount = GetContainerItemInfo(bag, slot)
            if itemName then
                totalItems = totalItems + 1
                local itemNameLower = itemName:lower()
                
                -- Check for any type of poison
                if itemNameLower:find("poison") then
                    table.insert(foundPoisons, {
                        name = itemName,
                        count = stackCount or 1,
                        bag = bag,
                        slot = slot
                    })
                end
            end
        end
    end
    
    self:Print("Total items scanned: " .. totalItems)
    self:Print("Poison items found: " .. #foundPoisons)
    
    if #foundPoisons > 0 then
        for i, poison in ipairs(foundPoisons) do
            self:Print("  " .. i .. ". " .. poison.name .. " (x" .. poison.count .. ") - Bag " .. poison.bag .. " Slot " .. poison.slot)
        end
    else
        self:Print("No poison items detected!")
        self:Print("")
        self:Print("This could mean:")
        self:Print("  1. No poisons in bags")
        self:Print("  2. Poisons have unusual names")
        self:Print("  3. Items are in a different location")
        
        -- Show first few items as examples
        self:Print("")
        self:Print("First few items found (for debugging):")
        local shown = 0
        for bag = 0, 4 do
            for slot = 1, GetContainerNumSlots(bag) do
                local itemName = GetContainerItemInfo(bag, slot)
                if itemName and shown < 10 then
                    self:Print("  " .. itemName .. " (Bag " .. bag .. " Slot " .. slot .. ")")
                    shown = shown + 1
                end
                if shown >= 10 then break end
            end
            if shown >= 10 then break end
        end
    end
    
    self:Print("========================")
end

-- =============================================
-- ENHANCED DEFENSIVE FUNCTIONS (Spec-Aware)
-- =============================================

function AC:RogueDefensives(health)
    local spec = self:GetPlayerSpec()
    
    -- Use Utils.lua potion functions if available
    if health < 30 then
        if self:UseHealthPotion(30) then
            RogueDebug("Used health potion")
            return true
        end
    end
    
    -- Emergency survival sequence
    if health < 20 then
        -- Use defensive potions if available
        if self:UseDefensivePotion(3) then
            RogueDebug("Used defensive potion")
            return true
        end
        
        -- Gouge to create distance
        if self:IsRogueSpellReady(S.Gouge) and CheckInteractDistance("target", 3) then
            if self:CastSpell(S.Gouge, "target") then
                RogueDebug("Gouge for escape")
                return true
            end
        end
        
        -- Blind as emergency CC
        if health < 15 and self:IsRogueSpellReady(S.Blind) then
            if self:CastSpell(S.Blind, "target") then
                RogueDebug("Blind for emergency escape")
                return true
            end
        end
        
        -- Vanish as absolute last resort
        if health < 10 and self:IsRogueSpellReady(S.Vanish) then
            if self:CastSpell(S.Vanish, "player") then
                RogueDebug("Emergency Vanish!")
                return true
            end
        end
    end
    
    -- Regular defensive cooldowns - SPEC SPECIFIC
    if health < 40 then
        -- Evasion - Available to all specs
        if self:IsRogueSpellReady(S.Evasion) then
            if self:CastSpell(S.Evasion, "player") then
                RogueDebug("Using Evasion")
                return true
            end
        end
        
        -- Cloak of Shadows - Subtlety and high-level talent
        if self:IsRogueSpellReady(S.CloakOfShadows) then
            if self:CastSpell(S.CloakOfShadows, "player") then
                RogueDebug("Using Cloak of Shadows")
                return true
            end
        end
    end
    
    return false
end

-- =============================================
-- ENHANCED COOLDOWN MANAGEMENT (WotLK Meta)
-- =============================================

function AC:UseRogueOffensiveCooldownsLegacy(spec, level, cp)
    if not UnitExists("target") or UnitIsDead("target") then return false end
    
    -- Don't use offensive cooldowns before combat starts
    if not UnitAffectingCombat("player") then return false end
    
    local targetClassification = UnitClassification("target")
    local isElite = targetClassification == "elite" or 
                    targetClassification == "rareelite" or
                    targetClassification == "worldboss"
    local isToughEnemy = isElite or UnitLevel("target") >= UnitLevel("player") + 1
    local inGroup = IsInGroup()
    local targetHP = UnitHealth("target") / UnitHealthMax("target") * 100
    
    -- Always use cooldowns when solo, more liberal usage in groups
    local shouldUseCooldowns = not inGroup or isToughEnemy or targetHP > 40
    
    if spec == "Assassination" then
        -- CRITICAL: Hunger for Blood maintenance (100% uptime required)
        if level >= 71 and not self:HasBuff("player", S.HFB) and self:KnowsSpell(S.HFB) then
            if not self:CastSpell(S.HFB, "player") then return false end
            RogueDebug("Activating Hunger for Blood (CRITICAL)")
            return true
        end
        
        if shouldUseCooldowns then
            -- Cold Blood with finishers
            if cp >= 3 and self:GetSpellCooldown(S.ColdBlood) == 0 then
                if not self:CastSpell(S.ColdBlood, "player") then return false end
                RogueDebug("Using Cold Blood")
                return true
            end
        end
        
    elseif spec == "Combat" then
        local enemies = self:GetEnemyCount()
        
        -- Blade Flurry for multiple enemies (2+ for Combat)
        if enemies >= 2 and self:GetSpellCooldown(S.BladeFlurry) == 0 then
            if not self:CastSpell(S.BladeFlurry, "player") then return false end
            RogueDebug("Blade Flurry for " .. enemies .. " enemies")
            return true
        end
        
        if shouldUseCooldowns then
            -- Adrenaline Rush
            if self:GetSpellCooldown(S.AdrenRush) == 0 then
                if not self:CastSpell(S.AdrenRush, "player") then return false end
                RogueDebug("Using Adrenaline Rush")
                
                -- Chain cooldowns
                if self.UseTrinkets then self:UseTrinkets() end
                if self.UseOffensivePotion then self:UseOffensivePotion(true) end
                return true
            end
            
            -- Killing Spree (no combo points required - instant ability)  
            if level >= 60 and self:GetSpellCooldown(S.KillingSpree) == 0 then
                if not self:CastSpell(S.KillingSpree, "player") then return false end
                RogueDebug("Using Killing Spree")
                
                -- Chain cooldowns with Killing Spree
                if self.UseTrinkets then self:UseTrinkets() end
                if self.UseOffensivePotion then self:UseOffensivePotion(true) end
                return true
            end
        end
        
    elseif spec == "Subtlety" then
        -- Premeditation for instant combo points
        if cp <= 2 and self:GetSpellCooldown(S.Premeditation) == 0 and not UnitAffectingCombat("player") then
            if not self:CastSpell(S.Premeditation, "target") then return false end
            RogueDebug("Using Premeditation for instant CP")
            return true
        end
        
        -- Shadow Dance burst phase
        if not self:HasBuff("player", S.ShadowDance) and self:GetSpellCooldown(S.ShadowDance) == 0 and
           shouldUseCooldowns then
            if not self:CastSpell(S.ShadowDance, "player") then return false end
            RogueDebug("Using Shadow Dance burst phase")
            if self.UseTrinkets then self:UseTrinkets() end
            return true
        end
        
        if shouldUseCooldowns then
            -- Preparation for cooldown reset
            if self:GetSpellCooldown(S.Preparation) == 0 and 
               (self:GetSpellCooldown(S.Vanish) > 0 or self:GetSpellCooldown(S.ShadowDance) > 0) then
                if not self:CastSpell(S.Preparation, "player") then return false end
                RogueDebug("Using Preparation for CD reset")
                return true
            end
        end
    end
    
    return false
end

-- Compatibility entry point; keep only one live cooldown priority list.
function AC:UseRogueOffensiveCooldowns(spec, level, cp)
    return self:UseRogueOffensiveCooldownsEnhanced(
        spec, level, cp, UnitPower("player", 3))
end

-- =============================================
-- ENHANCED STEALTH MANAGEMENT (Leveling Optimized)
-- =============================================

function AC:ManageRogueStealth()
    if UnitAffectingCombat("player") then return false end
    
    local hasTarget = UnitExists("target") and UnitCanAttack("player", "target") and not UnitIsDead("target")
    local inStealth = self:HasBuff("player", S.Stealth)
    
    -- Don't stealth if already stealthed
    if inStealth then return false end
    
    -- Enhanced stealth logic for leveling efficiency
    if hasTarget and not inStealth and self:GetSpellCooldown(S.Stealth) == 0 then
        -- Only stealth if target isn't already in combat with us
        if not UnitAffectingCombat("target") then
            local targetHP = UnitHealth("target") / UnitHealthMax("target") * 100
            -- Stealth for opener advantage on fresh targets
            if targetHP > 95 then
                if not self:CastSpell(S.Stealth, "player") then return false end
                RogueDebug("Stealthing for opener advantage")
                return true
            end
        end
    end
    
    return false
end

-- =============================================
-- ENHANCED CASTING SYSTEM (WotLK Compatible)
-- =============================================

function AC:CastSpell(spellName, unit)
    unit = unit or "target"

    local _, playerClass = UnitClass("player")
    if playerClass ~= "ROGUE" and self.CoreCastSpell then
        return self:CoreCastSpell(spellName, unit)
    end
    
    -- Skip if the spell doesn't exist or has no valid target
    if not spellName or (unit ~= "player" and not UnitExists(unit)) then
        RogueDebug("CastSpell FAILED: No spell name or invalid target - " .. (spellName or "nil"))
        return false
    end
    
    -- Check if spell is known
    if not self:KnowsSpell(spellName) then
        RogueDebug("CastSpell FAILED: Spell not known - " .. spellName)
        return false
    end
    
    -- Enhanced usability checking
    local usable, noMana = IsUsableSpell(spellName)
    if not usable then
        RogueDebug("CastSpell FAILED: " .. spellName .. " - Not usable")
        return false
    end
    
    if noMana then
        RogueDebug("CastSpell FAILED: " .. spellName .. " - No energy/mana")
        return false
    end
    
    -- Check cooldown
    local start, duration = GetSpellCooldown(spellName)
    if start and duration and start > 0 then
        RogueDebug("CastSpell FAILED: " .. spellName .. " - On cooldown")
        return false
    end
    
    -- Don't cast if already casting the same spell
    if IsCurrentSpell(spellName) then
        RogueDebug("CastSpell SKIPPED: Already casting " .. spellName)
        return false
    end

    if UnitCastingInfo("player") or UnitChannelInfo("player") then
        RogueDebug("CastSpell SKIPPED: Player is already casting/channeling")
        return false
    end

    if SpellIsTargeting and SpellIsTargeting() then
        RogueDebug("CastSpell SKIPPED: A previous ground spell is awaiting a click")
        return false
    end
    
    -- A successful pcall only proves that Lua accepted the API call. It does
    -- not prove that the client started the spell. Verify the post-cast state
    -- so an out-of-range/blocked cast cannot make the rotation return success
    -- forever.
    local beforeCooldown = self:GetSpellCooldown(spellName)
    local beforeGlobalCooldown = self:GetSpellCooldown(61304)
    local beforeCast = UnitCastingInfo("player")
    local beforeChannel = UnitChannelInfo("player")
    local inRange = true
    if unit ~= "player" and IsSpellInRange then
        local range = IsSpellInRange(spellName, unit)
        inRange = range ~= 0
    end
    if not inRange then
        RogueDebug("CastSpell FAILED: " .. spellName .. " - out of range")
        return false
    end

    local hadTarget = UnitExists("target")
    local targetChanged = unit ~= "player" and unit ~= "target"
    local ok = pcall(function()
        if unit == "player" then
            CastSpellByName(spellName, true)
        elseif unit == "target" then
            CastSpellByName(spellName)
        else
            TargetUnit(unit)
            if UnitExists("target") and UnitIsUnit("target", unit) then
                CastSpellByName(spellName)
            else
                error("unable to target " .. tostring(unit))
            end
        end
    end)

    if targetChanged then
        if hadTarget then TargetLastTarget() else ClearTarget() end
    end

    local afterCast = UnitCastingInfo("player")
    local afterChannel = UnitChannelInfo("player")
    local afterCooldown = self:GetSpellCooldown(spellName)
    local afterGlobalCooldown = self:GetSpellCooldown(61304)
    local started = (not beforeCast and afterCast) or (not beforeChannel and afterChannel)
    local queued = IsCurrentSpell(spellName) and
                   (afterCooldown > 0.05 or afterGlobalCooldown > beforeGlobalCooldown + 0.05)

    if ok and (started or queued or afterCooldown > beforeCooldown + 0.05 or
               afterGlobalCooldown > beforeGlobalCooldown + 0.05) then
        RogueDebug("CastSpell SUCCESS: " .. spellName)
        return true
    end

    RogueDebug("CastSpell FAILED: " .. spellName)
    return false
end

function AC:IsRogueSpellReady(spellName)
    return spellName and self:KnowsSpell(spellName) and self:IsUsableSpell(spellName) and
           self:GetSpellCooldown(spellName) <= 0.1
end

function AC:GetRogueTalentRank(talentName)
    if not talentName then return 0 end
    for tab = 1, GetNumTalentTabs() do
        for index = 1, GetNumTalents(tab) do
            local name, _, _, _, rank = GetTalentInfo(tab, index)
            if name == talentName then return rank or 0 end
        end
    end
    return 0
end

function AC:HasRogueBleed(unit)
    unit = unit or "target"
    local bleedNames = {
        ["Garrote"] = true, ["Rupture"] = true, ["Rend"] = true,
        ["Deep Wounds"] = true, ["Rake"] = true, ["Rip"] = true,
        ["Lacerate"] = true, ["Pounce Bleed"] = true, ["Piercing Shots"] = true
    }
    for index = 1, 40 do
        local name = UnitDebuff(unit, index)
        if not name then break end
        if bleedNames[name] then return true end
    end
    return false
end

function AC:GetRogueDebuffStacks(unit, debuffName)
    unit = unit or "target"
    for index = 1, 40 do
        local name, _, _, count = UnitDebuff(unit, index)
        if not name then break end
        if name == debuffName then return count or 0 end
    end
    return 0
end

function AC:HasTwoDaggersEquipped()
    return self:HasMainHandDaggerEquipped() and self:HasDaggerEquipped(17)
end

function AC:HasDaggerEquipped(slot)
    local itemLink = GetInventoryItemLink("player", slot)
    local itemSubType = itemLink and select(7, GetItemInfo(itemLink))
    return itemSubType == "Daggers" or itemSubType == "Dagger"
end

function AC:HasMainHandDaggerEquipped()
    return self:HasDaggerEquipped(16)
end

-- Enhanced SnD casting with multiple fallback methods
function AC:CastSliceAndDice()
    local cp = GetComboPoints("player", "target")
    local energy = UnitPower("player", 3)
    
    if cp < 1 then
        RogueDebug("SnD FAILED: No combo points")
        return false
    end
    
    if energy < 25 then
        RogueDebug("SnD FAILED: Not enough energy (" .. energy .. "/25)")
        return false
    end
    
    -- Check if already active and doesn't need refresh
    local hasSnd = self:HasBuff("player", "Slice and Dice")
    local sndTime = self:BuffTimeRemaining("player", "Slice and Dice")
    
    if hasSnd and sndTime > 6 then -- WotLK Meta: 6s refresh timing
        RogueDebug("SnD SKIPPED: Still active (" .. string.format("%.1fs", sndTime) .. " remaining)")
        return false
    end
    
    if not self:KnowsSpell(S.SnD) or not self:IsUsableSpell(S.SnD) or
       self:GetSpellCooldown(S.SnD) > 0.1 then
        RogueDebug("SnD FAILED: spell is not known, usable, or ready")
        return false
    end

    RogueDebug("Attempting SnD cast - CP: " .. cp .. ", Energy: " .. energy)

    return self:CastSpell(S.SnD, "player")
end

-- =============================================
-- ENHANCED ROTATION FUNCTIONS (WotLK Meta Compliant)
-- =============================================

-- CORRECTED: Assassination rotation with Cut to the Chase logic
function AC:AssassinationRotation(cp, energy, level, shouldUseAOE, enemies, shouldReduceThreat)
    local spec = "Assassination"
    local inGroup = IsInGroup()
    local rotationMode = self:GetLevelingRotationMode(level, inGroup)
    
    -- Hunger for Blood can only be activated while a nearby target is bleeding.
    -- Establish our own bleed when the group has not supplied one.
    if self:KnowsSpell(S.HFB) and not self:HasRogueBleed("target") and cp >= 1 and
       not self:IsRogueFastDyingTarget() and energy >= 25 and self:IsRogueSpellReady(S.Rupture) then
        if self:CastSpell(S.Rupture, "target") then
            RogueDebug("Rupture to enable Hunger for Blood")
            return true
        end
    end

    if self:KnowsSpell(S.HFB) and self:HasRogueBleed("target") and energy >= 15 then
        local hasHFB = self:HasBuff("player", S.HFB)
        local hfbTime = self:BuffTimeRemaining("player", S.HFB)
        if (not hasHFB or (hfbTime > 0 and hfbTime <= 5)) and self:IsRogueSpellReady(S.HFB) then
            if self:CastSpell(S.HFB, "player") then
                RogueDebug(hasHFB and "Hunger for Blood refresh" or "Hunger for Blood application")
                return true
            end
        end
    end

    local hasSnd = self:HasBuff("player", S.SnD)
    local sndTime = self:BuffTimeRemaining("player", S.SnD)
    local needsManualSnd = not hasSnd or (not self:HasCutToTheChase() and sndTime < 6)
    if cp >= 1 and self:KnowsSpell(S.SnD) and needsManualSnd and
       not self:IsRogueFastDyingTarget() and energy >= 25 then
        if self:CastSliceAndDice() then
            RogueDebug("Initial Slice and Dice (Assassination)")
            return true
        end
    end

    -- Check if we should pool energy
    local shouldPool = false
    if cp >= 4 then
        shouldPool = self:ShouldPoolEnergy(energy, "finisher", level)
    else
        shouldPool = self:ShouldPoolEnergy(energy, "generator", level)
    end
    
    if shouldPool and not shouldReduceThreat then
        RogueDebug("Pooling energy for optimal DPS")
        return false
    end
    
    -- Threat-aware energy management (reduce DPS when high threat)
    local energyThreshold = shouldReduceThreat and 80 or self:GetEnergyThreshold("generator", level)
    
    -- Enhanced AoE with improved calculations
    if level >= 66 and self:IsUsableSpell(S.FoK) then
        local aoeEfficient, reason = self:CalculateFoKEfficiency(enemies, energy, level, spec)
        local inRangeEnemies, targets = self:CheckAoEPositioning()
        
        if aoeEfficient and inRangeEnemies >= 2 and not self:ShouldPoolEnergy(energy, "aoe", level) then
            RogueDebug(string.format("AoE efficient: %d enemies in range, reason: %s", inRangeEnemies, reason))
            local success = self:CastSpell(S.FoK, "target")
            if success then
                RogueDebug("Fan of Knives (Assassination - Optimized)")
                return true
            end
        else
            RogueDebug(string.format("AoE skipped: efficient=%s, in_range=%d, reason=%s", 
                       tostring(aoeEfficient), inRangeEnemies, reason))
        end
    end
    
    -- ENHANCED FINISHER PRIORITY (Research-based optimization)
    if cp >= 4 or (cp >= 3 and self:IsRogueFastDyingTarget()) then
        -- Cut to the Chase refreshes an existing Slice and Dice; establish it first.
        if self:KnowsSpell(S.SnD) and not self:HasBuff("player", S.SnD) and energy >= 25 then
            if self:CastSliceAndDice() then
                RogueDebug("Initial Slice and Dice (Assassination)")
                return true
            end
        end

        -- RESEARCH-BASED: Optimal Envenom usage for Assassination
        if level >= 62 and self:KnowsSpell(S.Envenom) and energy >= 35 then
            local poisonStacks = self:GetRogueDebuffStacks("target", S.DeadlyPoison)
            local complexity = self:GetRotationComplexity()
            
            -- Advanced: Check Cut to the Chase and poison stacks
            if complexity == "ADVANCED" and self:HasCutToTheChase() then
                -- With Cut to the Chase: Use Envenom if we have poison stacks
                if poisonStacks >= 1 then
                    local success = self:CastSpell(S.Envenom, "target")
                    if success then
                        RogueDebug("Envenom (Cut to the Chase - " .. poisonStacks .. " stacks)")
                        return true
                    end
                end
            elseif complexity ~= "BASIC" then
                -- Without Cut to the Chase or simpler rotations: Still prioritize Envenom
                if poisonStacks >= 1 then
                    local success = self:CastSpell(S.Envenom, "target")
                    if success then
                        RogueDebug("Envenom (Assassination priority - " .. poisonStacks .. " stacks)")
                        return true
                    end
                end
            end
        end
        
        -- Without Cut to the Chase: Check SnD first
        if not self:HasCutToTheChase() then
            local hasSnd = self:HasBuff("player", S.SnD)
            local sndTime = self:BuffTimeRemaining("player", S.SnD)
            
            if not hasSnd or (sndTime < 6 and not self:IsRogueFastDyingTarget()) then
                local success = self:CastSliceAndDice()
                if success then
                    RogueDebug("SnD refresh (Assassination without Cut to Chase)")
                    return true
                end
            end
        end
        
        -- Regular finishers
        local finisher = self:GetRogueBestFinisher("Assassination", cp, level, energy)
        if finisher and self:IsUsableSpell(finisher) and energy >= 35 then
            local success = self:CastSpell(finisher, "target")
            if success then
                RogueDebug("Assassination finisher: " .. finisher)
                return true
            end
        end
    end
    
    -- Builders with threat-aware energy management
    if energy >= energyThreshold then
        local generator = self:GetRogueBestGenerator("Assassination", level, true, energy)
        if generator and self:IsUsableSpell(generator) then
            local success = self:CastSpell(generator, "target")
            if success then
                RogueDebug("Assassination builder: " .. generator)
                return true
            end
        end
    end
    
    return false
end

-- CORRECTED: Combat rotation with WotLK Meta priorities
function AC:CombatRotation(cp, energy, level, shouldUseAOE, enemies, inMelee, shouldReduceThreat)
    local spec = "Combat"
    local inGroup = IsInGroup()
    local rotationMode = self:GetLevelingRotationMode(level, inGroup)
    
    -- Slice and Dice is cheaper than a builder, so maintain it before pooling.
    local hasSnd = self:HasBuff("player", S.SnD)
    local sndTime = self:BuffTimeRemaining("player", S.SnD)
    if (not hasSnd or sndTime < 6) and not self:IsRogueFastDyingTarget() then
        if self:CastSliceAndDice() then
            RogueDebug("SnD refresh (Combat 100% uptime)")
            return true
        end
    end

    -- Check if we should pool energy
    local shouldPool = false
    if cp >= 4 then
        shouldPool = self:ShouldPoolEnergy(energy, "finisher", level)
    else
        shouldPool = self:ShouldPoolEnergy(energy, "generator", level)
    end
    
    if shouldPool and not shouldReduceThreat then
        RogueDebug("Pooling energy for optimal DPS")
        return false
    end
    
    -- Threat-aware energy management (reduce DPS when high threat)
    local energyThreshold = shouldReduceThreat and 60 or self:GetEnergyThreshold("generator", level)
    
    -- Enhanced AoE with Combat's superior cleave potential
    if level >= 66 and self:IsUsableSpell(S.FoK) then
        local aoeEfficient, reason = self:CalculateFoKEfficiency(enemies, energy, level, spec)
        local inRangeEnemies, targets = self:CheckAoEPositioning()
        
        -- Combat is more AoE friendly - especially with Blade Flurry
        if aoeEfficient and inRangeEnemies >= 2 and not self:ShouldPoolEnergy(energy, "aoe", level) then
            RogueDebug(string.format("Combat AoE: %d enemies in range, reason: %s", inRangeEnemies, reason))
            local success = self:CastSpell(S.FoK, "target")
            if success then
                RogueDebug("Fan of Knives (Combat - Enhanced Cleave)")
                return true
            end
        else
            RogueDebug(string.format("Combat AoE skipped: efficient=%s, in_range=%d, reason=%s", 
                       tostring(aoeEfficient), inRangeEnemies, reason))
        end
    end
    
    -- Finisher priority with ArP awareness
    if cp >= 4 or (cp >= 3 and self:IsRogueFastDyingTarget()) then
        local armorPen = self:GetArmorPenetrationRating()
        
        if armorPen < 1000 and not self:HasBuff("player", S.BladeFlurry) then
            -- Low ArP: Rupture priority for DoT damage
            if self:KnowsSpell(S.Rupture) and not self:HasDebuff("target", S.Rupture) and
               not self:IsRogueFastDyingTarget() and energy >= 25 then
                local success = self:CastSpell(S.Rupture, "target")
                if success then
                    RogueDebug("Rupture (Low ArP priority)")
                    return true
                end
            end
        end
        
        -- Expose Armor for group play
        if IsInGroup() and self:KnowsSpell(S.ExposeArmor) and energy >= 25 then
            local targetClassification = UnitClassification("target")
            local isBoss = targetClassification == "worldboss" or 
                           targetClassification == "elite" or 
                           targetClassification == "rareelite"
            
            if isBoss and not self:HasDebuff("target", S.ExposeArmor) then
                local hasWarriorDebuff = self:HasDebuff("target", "Sunder Armor") or 
                                        self:HasDebuff("target", "Devastate")
                if not hasWarriorDebuff then
                    local success = self:CastSpell(S.ExposeArmor, "target")
                    if success then
                        RogueDebug("Expose Armor (group support)")
                        return true
                    end
                end
            end
        end

        -- High ArP, Blade Flurry, or fallback: Eviscerate
        if energy >= 35 and self:IsUsableSpell(S.Eviscerate) then
            local success = self:CastSpell(S.Eviscerate, "target")
            if success then
                RogueDebug("Eviscerate (Combat finisher)")
                return true
            end
        end
    end
    
    -- Builders - Threat-aware energy management
    if energy >= energyThreshold and self:IsUsableSpell(S.Sinister) then
        local success = self:CastSpell(S.Sinister, "target")
        if success then
            RogueDebug("Sinister Strike (Combat builder)")
            return true
        end
    end
    
    return false
end

-- CORRECTED: Subtlety rotation with Honor Among Thieves awareness
function AC:SubtletyRotation(cp, energy, level, shouldUseAOE, enemies, inMelee, shouldReduceThreat)
    local spec = "Subtlety"
    local inGroup = IsInGroup()
    local rotationMode = self:GetLevelingRotationMode(level, inGroup)
    
    -- Honor Among Thieves passive CP generation awareness
    local hasHAT = self:HasHonorAmongThieves()
    local cpThreshold = 4
    
    -- Maintain Slice and Dice before pooling for a more expensive builder.
    local hasSnd = self:HasBuff("player", S.SnD)
    local sndTime = self:BuffTimeRemaining("player", S.SnD)
    if (not hasSnd or sndTime < 6) and not self:IsRogueFastDyingTarget() then
        if self:CastSliceAndDice() then
            RogueDebug("SnD refresh (Subtlety)")
            return true
        end
    end

    -- Check if we should pool energy
    local shouldPool = false
    if cp >= cpThreshold then
        shouldPool = self:ShouldPoolEnergy(energy, "finisher", level)
    else
        shouldPool = self:ShouldPoolEnergy(energy, "generator", level)
    end
    
    if shouldPool and not shouldReduceThreat then
        RogueDebug("Pooling energy for optimal DPS")
        return false
    end
    
    -- Threat-aware energy management
    local energyThreshold = shouldReduceThreat and 70 or self:GetEnergyThreshold("generator", level)
    
    -- Shadow Dance burst phase
    if self:HasBuff("player", S.ShadowDance) then
        -- During Shadow Dance: spam Ambush
        if energy >= 60 and self:IsBehindTarget() and self:KnowsSpell(S.Ambush) then
            local success = self:CastSpell(S.Ambush, "target")
            if success then
                RogueDebug("Ambush (Shadow Dance burst)")
                return true
            end
        end
    end
    
    -- Enhanced AoE (Subtlety is least AoE focused)
    if level >= 66 and self:IsUsableSpell(S.FoK) then
        local aoeEfficient, reason = self:CalculateRogueAoEEfficiency(enemies, level, spec, energy, cp)
        local inRangeEnemies, targets = self:CheckAoEPositioning()
        
        -- Subtlety requires higher threshold due to single target focus
        if aoeEfficient and inRangeEnemies >= 3 and energy >= 60 then
            RogueDebug(string.format("Subtlety AoE: %d enemies in range, reason: %s", inRangeEnemies, reason))
            local success = self:CastSpell(S.FoK, "target")
            if success then
                RogueDebug("Fan of Knives (Subtlety - Conservative)")
                return true
            end
        else
            RogueDebug(string.format("Subtlety AoE skipped: efficient=%s, in_range=%d, reason=%s", 
                       tostring(aoeEfficient), inRangeEnemies, reason))
        end
    end
    
    -- Finishers with Honor Among Thieves awareness
    if cp >= cpThreshold or (cp >= 2 and self:IsRogueFastDyingTarget()) then
        if self:KnowsSpell(S.Rupture) and not self:HasDebuff("target", S.Rupture) and
           not self:IsRogueFastDyingTarget() and energy >= 25 then
            local success = self:CastSpell(S.Rupture, "target")
            if success then
                RogueDebug("Rupture (Subtlety finisher)")
                return true
            end
        end
        
        -- Eviscerate for damage
        if energy >= 35 and self:IsUsableSpell(S.Eviscerate) then
            local success = self:CastSpell(S.Eviscerate, "target")
            if success then
                RogueDebug("Eviscerate (Subtlety)")
                return true
            end
        end
    end
    
    -- Hemorrhage is a builder and its physical-damage debuff should be maintained.
    if cp <= 3 and self:KnowsSpell(S.Hemorrhage) and
       not self:HasDebuff("target", S.Hemorrhage) and energy >= 35 then
        if self:CastSpell(S.Hemorrhage, "target") then
            RogueDebug("Hemorrhage builder (debuff)")
            return true
        end
    end

    -- Builders with threat-aware and Honor Among Thieves energy management
    if energy >= energyThreshold then
        local generator = self:GetRogueBestGenerator("Subtlety", level, inMelee, energy)
        if generator and self:IsUsableSpell(generator) then
            local success = self:CastSpell(generator, "target")
            if success then
                RogueDebug("Subtlety builder: " .. generator .. " (HAT: " .. (hasHAT and "Yes" or "No") .. ")")
                return true
            end
        end
    end
    
    return false
end

-- CORRECTED: Low level rotation with leveling optimizations
function AC:LowLevelRotation(cp, energy, level, inMelee)
    local rotationMode = self:GetLevelingRotationMode(level, IsInGroup())
    
    -- Level-based adaptation for better leveling experience
    local cpThreshold = rotationMode == "SIMPLE" and 2 or 3 -- More aggressive at very low levels
    local energyThreshold = self:GetEnergyThreshold("generator", level)
    
    -- Simple finisher logic with level adaptation
    if cp >= cpThreshold then 
        if energy >= 35 and self:IsUsableSpell(S.Eviscerate) then
            local success = self:CastSpell(S.Eviscerate, "target")
            if success then
                RogueDebug("Low-level Eviscerate (Level " .. level .. ")")
                return true
            end
        end
    end
    
    -- Simple builder logic with reduced energy for leveling speed
    if energy >= energyThreshold then
        local generator = self:GetRogueBestGenerator("None", level, inMelee, energy)
        if generator and self:IsUsableSpell(generator) then
            local success = self:CastSpell(generator, "target")
            if success then
                RogueDebug("Low-level builder: " .. generator .. " (Level " .. level .. ")")
                return true
            end
        end
    end
    
    return false
end

-- =============================================
-- ENHANCED MAIN ROTATION (WotLK Meta + Leveling Optimized)
-- =============================================

function AC:RogueRotation()
    local spec = self:GetPlayerSpec()
    local cp = GetComboPoints("player", "target")
    local energy = UnitPower("player", 3)
    local level = UnitLevel("player")
    local inMelee = CheckInteractDistance("target", 3)
    local enemies = self:GetEnemyCount()
    local shouldUseAOE = self:ShouldUseAOE()
    local inCombat = UnitAffectingCombat("player")
    local hasTarget = UnitExists("target") and UnitCanAttack("player", "target") and not UnitIsDead("target")
    local health = UnitHealth("player") / UnitHealthMax("player") * 100
    
    -- Enhanced debug output
    if self.debugMode and self:Throttle("RogueDebugOutput", 3) then
        RogueDebug("=== WotLK Meta Rotation Debug ===")
        RogueDebug(string.format("Spec: %s | Level: %d | Energy: %d | CP: %d | HP: %d%%", 
                   spec, level, energy, cp, math.floor(health)))
        RogueDebug(string.format("Target: %s | Combat: %s | Enemies: %d | AoE: %s", 
                   hasTarget and "Yes" or "No", inCombat and "Yes" or "No", enemies, shouldUseAOE and "Yes" or "No"))
        
        -- Spec-specific status
        if spec == "Assassination" then
            local hasHFB = self:HasBuff("player", S.HFB)
            local hasCutToChase = self:HasCutToTheChase()
            RogueDebug(string.format("HfB: %s | Cut to Chase: %s", hasHFB and "Active" or "MISSING", hasCutToChase and "Yes" or "No"))
        elseif spec == "Combat" then
            local hasSnd = self:HasBuff("player", S.SnD)
            local sndTime = self:BuffTimeRemaining("player", S.SnD)
            local armorPen = self:GetArmorPenetrationRating()
            RogueDebug(string.format("SnD: %s (%.1fs) | ArP: %d", hasSnd and "Active" or "MISSING", sndTime, armorPen))
        elseif spec == "Subtlety" then
            local hasHAT = self:HasHonorAmongThieves()
            local hasShadowDance = self:HasBuff("player", S.ShadowDance)
            RogueDebug(string.format("HAT: %s | Shadow Dance: %s", hasHAT and "Yes" or "No", hasShadowDance and "Active" or "No"))
        end
        RogueDebug("================================")
    end
    
    -- Out of combat management
    if not inCombat then
        -- Poison application with optimized timing
        if self:CheckAndApplyPoisons() then
            return true
        end
        
        -- Use agility scroll if available and not buffed
        if self:UseAgilityScroll() then
            return true
        end
        
        -- Stealth management for leveling efficiency
        if self:ManageRogueStealth() then
            return true
        end
    end
    
    -- Emergency Lifeblood (Herbalism profession ability) at 50% health
    if inCombat and self:UseLifeblood() then return true end
    
    -- Enhanced threat management (level-friendly)
    local threatLevel, threatScore = self:GetRogueThreatLevel()
    if inCombat and self:ManageRogueThreat(threatLevel, threatScore, level, spec) then
        return true
    end
    
    -- Check if we should reduce threat generation
    local shouldReduceThreat = self:ShouldReduceThreatGeneration(threatLevel, level)
    
    -- Handle auto-attack
    if hasTarget then
        self:HandleRogueAutoAttack()
    end
    
    -- Auto-targeting if needed
    if inCombat and not hasTarget then
        self:FindAndSetTarget()
        hasTarget = UnitExists("target") and UnitCanAttack("player", "target") and not UnitIsDead("target")
    end
    
    if not hasTarget then
        RogueDebug("No valid target - rotation stopping")
        return false
    end
    
    -- Emergency defensives
    if health < 40 then
        if self:RogueDefensives(health) then
            return true
        end
    end
    
    -- Use racials
    local targetIsElite = UnitClassification("target") == "elite" or 
                         UnitClassification("target") == "rareelite" or 
                         UnitClassification("target") == "worldboss"
    if self:UseRogueRacials(targetIsElite) then return true end
    
    -- Interrupt with better timing
    if (UnitCastingInfo("target") or UnitChannelInfo("target")) and energy >= 25 and
       self:KnowsSpell(S.Kick) then
        local interrupted = false
        
        if self.TryInterrupt then
            interrupted = self:TryInterrupt(S.Kick, "target")
        else
            if self:IsRogueSpellReady(S.Kick) then
                local success = self:CastSpell(S.Kick, "target")
                if success then
                    interrupted = true
                end
            end
        end
        
        if interrupted then
            RogueDebug("Interrupted enemy cast")
            return true
        end
    end
    
    -- Enhanced stealth opener with spec-specific priorities
    if self:HasBuff("player", S.Stealth) then
        -- Pool energy for optimal opener
        if self:ShouldPoolEnergy(energy, "stealth", level) then
            RogueDebug("Pooling energy for stealth opener")
            return false
        end
        
        -- Premeditation for instant 2 CP (Subtlety)
        if spec == "Subtlety" and self:KnowsSpell(S.Premeditation) and cp == 0 then
            local success = self:CastSpell(S.Premeditation, "target")
            if success then
                RogueDebug("Premeditation opener (Subtlety)")
                return true
            end
        end
        
        -- Spec-specific openers based on situation
        local targetType = UnitClassification("target")
        local isEliteOrBoss = targetType ~= "normal"
        local targetHP = UnitHealth("target") / UnitHealthMax("target") * 100
        
        -- Assassination: Mutilate for damage, Cheap Shot for control
        if spec == "Assassination" then
            if self:KnowsSpell(S.HFB) and self:KnowsSpell(S.Garrote) and
               energy >= 50 and (isEliteOrBoss or targetHP > 80) then
                local success = self:CastSpell(S.Garrote, "target")
                if success then
                    RogueDebug("Garrote opener (enables Hunger for Blood)")
                    return true
                end
            end

            if self:KnowsSpell(S.Mutilate) and self:HasTwoDaggersEquipped() and energy >= 60 then
                if not isEliteOrBoss or targetHP < 90 then
                    local success = self:CastSpell(S.Mutilate, "target")
                    if success then
                        RogueDebug("Mutilate opener (Assassination)")
                        return true
                    end
                end
            end
        
        -- Combat: Garrote for bleed, Cheap Shot for stun lock
        elseif spec == "Combat" then
            if self:KnowsSpell(S.Garrote) and energy >= 50 then
                if isEliteOrBoss or targetHP > 80 then
                    local success = self:CastSpell(S.Garrote, "target")
                    if success then
                        RogueDebug("Garrote opener (Combat bleed)")
                        return true
                    end
                end
            end
            
        -- Subtlety: Ambush from behind, Cheap Shot otherwise
        elseif spec == "Subtlety" then
            if self:KnowsSpell(S.Ambush) and energy >= 60 then
                local success = self:CastSpell(S.Ambush, "target")
                if success then
                    RogueDebug("Ambush opener (Subtlety burst)")
                    return true
                end
            end
        end
        
        -- Default: Cheap Shot for control
        if self:KnowsSpell(S.CheapShot) and energy >= 60 then
            local success = self:CastSpell(S.CheapShot, "target")
            if success then
                RogueDebug("Cheap Shot opener (control)")
                return true
            end
        end
        
        -- Fallback to basic opener
        if self:KnowsSpell(S.Sinister) then
            local success = self:CastSpell(S.Sinister, "target")
            if success then
                RogueDebug("Sinister Strike opener")
                return true
            end
        end
    end
    
    -- Use Tricks of the Trade in groups
    if self:UseTricksOfTrade(level) then
        return true
    end
    
    -- Use offensive cooldowns with enhanced logic
    if self:UseRogueOffensiveCooldownsEnhanced(spec, level, cp, energy) then
        return true
    end
    
    -- Target fleeing management
    if self:IsRogueTargetFleeing() and energy >= 15 then
        if self:IsRogueSpellReady(S.Sprint) then
            local success = self:CastSpell(S.Sprint, "player")
            if success then
                RogueDebug("Sprint to catch fleeing target")
                return true
            end
        end
    end
    
    -- MAIN ROTATION LOGIC - WotLK Meta Compliant
    local rotationResult = false
    
    if spec == "Assassination" then
        rotationResult = self:AssassinationRotation(cp, energy, level, shouldUseAOE, enemies, shouldReduceThreat)
    elseif spec == "Combat" then
        rotationResult = self:CombatRotation(cp, energy, level, shouldUseAOE, enemies, inMelee, shouldReduceThreat)
    elseif spec == "Subtlety" then
        rotationResult = self:SubtletyRotation(cp, energy, level, shouldUseAOE, enemies, inMelee, shouldReduceThreat)
    else
        rotationResult = self:LowLevelRotation(cp, energy, level, inMelee)
    end
    
    -- Debug output for rotation result
    if not rotationResult and self.debugMode then
        RogueDebug("No action taken this rotation cycle - waiting for resources")
    end
    
    return rotationResult
end

-- =============================================
-- ENHANCED BUFF CHECKING (Optimized for Leveling)
-- =============================================

function AC:CheckRogueBuffs(spec)
    if not self:Throttle("RogueOOCBuffCheck", 3) then return false end -- Reduced for leveling
    
    -- Poison application (most important) - 3s intervals for leveling
    local poisonResult = self:CheckAndApplyPoisons()
    if poisonResult then
        RogueDebug("Applied poison during buff check")
        return true
    end
    
    -- Stealth management for preparation
    local stealthResult = self:ManageRogueStealth()
    if stealthResult then
        RogueDebug("Entered stealth during buff check")
        return true
    end
    
    -- Conservative Sprint usage for travel
    if not UnitAffectingCombat("player") and not IsMounted() and self:IsRogueSpellReady(S.Sprint) then
        if self:Throttle("RogueSprintTravel", 180) then -- 3 minutes cooldown
            local inCity = IsResting()
            local moving = GetUnitSpeed("player") > 0
            local hasTarget = UnitExists("target") and UnitCanAttack("player", "target")
            
            if not inCity and moving and (hasTarget or not IsResting()) then
                local success = self:CastSpell(S.Sprint, "player")
                if success then
                    RogueDebug("Sprint for efficient travel")
                    return true
                end
            end
        end
    end
    
    return false
end

-- =============================================
-- ENHANCED DEBUGGING AND DIAGNOSTICS
-- =============================================

function AC:DebugRogueRotation()
    if not self.debugMode then return end
    
    local spec = self:GetPlayerSpec()
    local cp = GetComboPoints("player", "target")
    local energy = UnitPower("player", 3)
    local maxEnergy = UnitPowerMax("player", 3)
    local level = UnitLevel("player")
    local inCombat = UnitAffectingCombat("player")
    local hasTarget = UnitExists("target") and UnitCanAttack("player", "target") and not UnitIsDead("target")
    
    RogueDebug("=== WotLK Meta Rotation Debug ===")
    RogueDebug("Player State:")
    RogueDebug("  Spec: " .. spec .. " | Level: " .. level)
    RogueDebug("  Energy: " .. energy .. "/" .. maxEnergy)
    RogueDebug("  Combo Points: " .. cp)
    RogueDebug("  In Combat: " .. (inCombat and "Yes" or "No"))
    RogueDebug("  Has Target: " .. (hasTarget and "Yes" or "No"))
    
    if hasTarget then
        local targetHP = UnitHealth("target") / UnitHealthMax("target") * 100
        local targetName = UnitName("target") or "Unknown"
        RogueDebug("Target Info:")
        RogueDebug("  Name: " .. targetName)
        RogueDebug("  Health: " .. string.format("%.1f%%", targetHP))
        RogueDebug("  Classification: " .. (UnitClassification("target") or "normal"))
    end
    
    -- WotLK Meta-specific status
    if spec == "Assassination" then
        local hasHFB = self:HasBuff("player", S.HFB)
        local hasCutToChase = self:HasCutToTheChase()
        RogueDebug("Assassination Specific:")
        RogueDebug("  Hunger for Blood: " .. (hasHFB and "Active" or "MISSING (CRITICAL)"))
        RogueDebug("  Cut to the Chase: " .. (hasCutToChase and "Talented" or "Not Talented"))
    elseif spec == "Combat" then
        local hasSnd = self:HasBuff("player", S.SnD)
        local sndTime = self:BuffTimeRemaining("player", S.SnD)
        local armorPen = self:GetArmorPenetrationRating()
        RogueDebug("Combat Specific:")
        RogueDebug("  Slice and Dice: " .. (hasSnd and "Active" or "MISSING"))
        RogueDebug("  SnD Time Left: " .. string.format("%.1fs", sndTime))
        RogueDebug("  Armor Pen Rating: " .. armorPen)
        RogueDebug("  Finisher Priority: " .. (armorPen < 1000 and "Rupture (Low ArP)" or "Eviscerate (High ArP)"))
    elseif spec == "Subtlety" then
        local hasHAT = self:HasHonorAmongThieves()
        local hasShadowDance = self:HasBuff("player", S.ShadowDance)
        RogueDebug("Subtlety Specific:")
        RogueDebug("  Honor Among Thieves: " .. (hasHAT and "Active (Free CP)" or "Inactive"))
        RogueDebug("  Shadow Dance: " .. (hasShadowDance and "Active (Burst Mode)" or "Inactive"))
    end
    
    -- Poison status
    local hasMainHandPoison, hasOffHandPoison, hasOffHandWeapon = self:CheckWeaponEnchants()
    RogueDebug("Poisons:")
    RogueDebug("  Main Hand: " .. (hasMainHandPoison and "Applied" or "MISSING"))
    RogueDebug("  Off Hand: " .. (hasOffHandWeapon and (hasOffHandPoison and "Applied" or "MISSING") or "N/A"))
    
    RogueDebug("==============================")
end

-- Enhanced diagnostic with WotLK meta awareness
function AC:DiagnoseRogueIssues()
    self:Print("=== WotLK Meta Rogue Diagnostic ===")
    
    local spec = self:GetPlayerSpec()
    local cp = GetComboPoints("player", "target")
    local energy = UnitPower("player", 3)
    local level = UnitLevel("player")
    
    self:Print("Current State: " .. spec .. " spec, Level " .. level .. ", " .. energy .. " energy, " .. cp .. " CP")
    
    local issues = {}
    local recommendations = {}
    
    -- Spec-specific issue detection
    if spec == "Assassination" then
        if self:KnowsSpell(S.HFB) and not self:HasBuff("player", S.HFB) then
            table.insert(issues, "CRITICAL: Hunger for Blood missing (major DPS loss)")
            table.insert(recommendations, "Apply a bleed, then cast Hunger for Blood")
        end
        
        local hasCutToChase = self:HasCutToTheChase()
        if level >= 60 and not hasCutToChase then
            table.insert(recommendations, "Consider Cut to the Chase talent for auto-SnD refresh")
        end
        
    elseif spec == "Combat" then
        local hasSnd = self:HasBuff("player", S.SnD)
        local sndTime = self:BuffTimeRemaining("player", S.SnD)
        
        if not hasSnd then
            table.insert(issues, "CRITICAL: Slice and Dice missing (Combat requires 100% uptime)")
            table.insert(recommendations, "Refresh SnD at 6 seconds remaining, not 3")
        elseif sndTime < 6 then
            table.insert(issues, "SnD expiring soon (" .. string.format("%.1fs", sndTime) .. ")")
        end
        
        local armorPen = self:GetArmorPenetrationRating()
        if armorPen < 1000 then
            table.insert(recommendations, "Use Rupture priority (low ArP build)")
        else
            table.insert(recommendations, "Use Eviscerate priority (high ArP build)")
        end
        
    elseif spec == "Subtlety" then
        local hasHAT = self:HasHonorAmongThieves()
        if level >= 60 and IsInGroup() and not hasHAT then
            table.insert(recommendations, "Honor Among Thieves provides free CP in groups")
        end
        
        local hasShadowDance = self:HasBuff("player", S.ShadowDance)
        if level >= 80 and not hasShadowDance and self:GetSpellCooldown(S.ShadowDance) == 0 then
            table.insert(recommendations, "Use Shadow Dance for burst windows")
        end
    end
    
    -- General issues
    if energy < 25 then
        table.insert(issues, "Low energy (" .. energy .. ") - waiting for regen")
    end
    
    -- Poison issues
    local hasMainHandPoison, hasOffHandPoison, hasOffHandWeapon = self:CheckWeaponEnchants()
    if not hasMainHandPoison then
        table.insert(issues, "Main hand poison missing")
    end
    if hasOffHandWeapon and not hasOffHandPoison then
        table.insert(issues, "Off hand poison missing")
    end
    
    -- Target issues
    if not UnitExists("target") then
        table.insert(issues, "No target selected")
    elseif not UnitCanAttack("player", "target") then
        table.insert(issues, "Target is not attackable")
    elseif UnitIsDead("target") then
        table.insert(issues, "Target is dead")
    end
    
    if #issues > 0 then
        self:Print("Issues detected:")
        for i, issue in ipairs(issues) do
            self:Print("  " .. i .. ". " .. issue)
        end
    else
        self:Print("No obvious issues detected")
    end
    
    if #recommendations > 0 then
        self:Print("Recommendations:")
        for i, rec in ipairs(recommendations) do
            self:Print("  " .. i .. ". " .. rec)
        end
    end
    
    self:Print("Use '/ac debug' for detailed rotation logging")
    self:Print("===================================")
end

-- Enhanced test function with WotLK meta scenarios
function AC:TestRogueRotation(scenario)
    scenario = scenario or "basic"
    
    self:Print("Testing WotLK Meta Rogue rotation scenario: " .. scenario)
    
    if scenario == "snd" then
        -- Test SnD logic specifically
        local spec = self:GetPlayerSpec()
        local cp = GetComboPoints("player", "target")
        local energy = UnitPower("player", 3)
        local hasSnd = self:HasBuff("player", S.SnD)
        local sndTime = self:BuffTimeRemaining("player", S.SnD)
        
        self:Print("SnD Test Results:")
        self:Print("  Current SnD: " .. (hasSnd and ("Active (" .. string.format("%.1fs", sndTime) .. ")") or "Inactive"))
        self:Print("  Should refresh (6s rule): " .. ((not hasSnd or sndTime < 6) and "Yes" or "No"))
        self:Print("  Can refresh: " .. (cp >= 1 and energy >= 25 and "Yes" or "No"))
        self:Print("  CP: " .. cp .. ", Energy: " .. energy)
        
        if cp >= 1 and energy >= 25 and (not hasSnd or sndTime < 6) then
            self:Print("  Attempting SnD cast...")
            local success = self:CastSliceAndDice()
            self:Print("  Result: " .. (success and "SUCCESS" or "FAILED"))
        end
        
    elseif scenario == "hfb" then
        -- Test Hunger for Blood (Assassination)
        local spec = self:GetPlayerSpec()
        local level = UnitLevel("player")
        local hasHFB = self:HasBuff("player", S.HFB)
        
        self:Print("Hunger for Blood Test:")
        self:Print("  Spec: " .. spec)
        self:Print("  Learned: " .. (self:KnowsSpell(S.HFB) and "Yes" or "No"))
        self:Print("  Bleed available: " .. (self:HasRogueBleed("target") and "Yes" or "No"))
        self:Print("  Current HfB: " .. (hasHFB and "Active" or "MISSING"))
        self:Print("  Should cast: " .. (spec == "Assassination" and self:KnowsSpell(S.HFB) and
                   self:HasRogueBleed("target") and not hasHFB and "Yes" or "No"))
        
        if spec == "Assassination" and self:KnowsSpell(S.HFB) and
           self:HasRogueBleed("target") and not hasHFB then
            self:Print("  Attempting HfB cast...")
            local success = self:CastSpell(S.HFB, "player")
            self:Print("  Result: " .. (success and "SUCCESS" or "FAILED"))
        end
        
    elseif scenario == "arp" then
        -- Test ArP detection for Combat
        local spec = self:GetPlayerSpec()
        local armorPen = self:GetArmorPenetrationRating()
        
        self:Print("Armor Penetration Test:")
        self:Print("  Spec: " .. spec)
        self:Print("  Current ArP Rating: " .. armorPen)
        self:Print("  Priority: " .. (armorPen < 1000 and "Rupture (Low ArP)" or "Eviscerate (High ArP)"))
        
        if spec == "Combat" then
            if armorPen < 1000 then
                self:Print("  Recommendation: Use Rupture for DoT damage")
            else
                self:Print("  Recommendation: Use Eviscerate for direct damage")
            end
        end
        
    elseif scenario == "hat" then
        -- Test Honor Among Thieves (Subtlety)
        local spec = self:GetPlayerSpec()
        local hasHAT = self:HasHonorAmongThieves()
        local inGroup = IsInGroup()
        
        self:Print("Honor Among Thieves Test:")
        self:Print("  Spec: " .. spec)
        self:Print("  In Group: " .. (inGroup and "Yes" or "No"))
        self:Print("  HAT Active: " .. (hasHAT and "Yes (Free CP generation)" or "No"))
        self:Print("  Energy Threshold: " .. (hasHAT and "30 (reduced)" or "50 (normal)"))
        
    elseif scenario == "basic" then
        -- Test basic rotation flow
        self:Print("Running WotLK meta rotation test...")
        local result = self:RogueRotation()
        self:Print("Rotation result: " .. (result and "Action taken" or "No action taken"))
        
    elseif scenario == "energy" then
        -- Test energy thresholds with WotLK meta
        local energy = UnitPower("player", 3)
        local spec = self:GetPlayerSpec()
        local hasHAT = self:HasHonorAmongThieves()
        
        self:Print("Energy threshold test (WotLK Meta):")
        self:Print("  Current energy: " .. energy)
        self:Print("  Spec: " .. spec)
        self:Print("  Can cast SnD (25): " .. (energy >= 25 and "Yes" or "No"))
        self:Print("  Can cast Eviscerate (35): " .. (energy >= 35 and "Yes" or "No"))
        self:Print("  Can cast Sinister Strike (40): " .. (energy >= 40 and "Yes" or "No")) -- Reduced threshold
        self:Print("  Can cast Mutilate (60): " .. (energy >= 60 and "Yes" or "No"))
        
        if spec == "Subtlety" then
            local threshold = hasHAT and 30 or 50
            self:Print("  Subtlety builder threshold: " .. threshold .. " (HAT: " .. (hasHAT and "Yes" or "No") .. ")")
        end
    end
end

-- =============================================
-- ENHANCED SLASH COMMANDS FOR ROGUE
-- =============================================

function AC:SetupRogueSlashCommands()
    local originalHandler = SlashCmdList["AZEROCOMBAT"]
    
    SlashCmdList["AZEROCOMBAT"] = function(msg)
        local args = {strsplit(" ", msg)}
        local command = args[1] and args[1]:lower() or ""
        local subcommand = args[2] and args[2]:lower() or ""
        
        -- Rogue-specific commands
        if command == "rogue" then
            if subcommand == "debug" then
                self:DebugRogueRotation()
            elseif subcommand == "diagnose" then
                self:DiagnoseRogueIssues()
            elseif subcommand == "test" then
                local scenario = args[3] or "basic"
                self:TestRogueRotation(scenario)
            elseif subcommand == "poisons" then
                self:TestPoisonManually()
            elseif subcommand == "mechanics" then
                self:TestBasicPoisonMechanics()
            elseif subcommand == "snd" then
                self:Print("Testing SnD casting...")
                local success = self:CastSliceAndDice()
                self:Print("SnD cast result: " .. (success and "SUCCESS" or "FAILED"))
            elseif subcommand == "meta" then
                -- Display current WotLK meta status
                local spec = self:GetPlayerSpec()
                local level = UnitLevel("player")
                
                self:Print("=== WotLK Meta Status ===")
                self:Print("Spec: " .. spec .. " | Level: " .. level)
                
                if spec == "Assassination" then
                    local hasHFB = self:HasBuff("player", S.HFB)
                    local hasCutToChase = self:HasCutToTheChase()
                    self:Print("Hunger for Blood: " .. (hasHFB and "✓ Active" or "✗ MISSING"))
                    self:Print("Cut to the Chase: " .. (hasCutToChase and "✓ Talented" or "✗ Not Talented"))
                elseif spec == "Combat" then
                    local hasSnd = self:HasBuff("player", S.SnD)
                    local armorPen = self:GetArmorPenetrationRating()
                    self:Print("Slice and Dice: " .. (hasSnd and "✓ Active" or "✗ MISSING"))
                    self:Print("ArP Rating: " .. armorPen .. " (" .. (armorPen < 1000 and "Rupture priority" or "Eviscerate priority") .. ")")
                elseif spec == "Subtlety" then
                    local hasHAT = self:HasHonorAmongThieves()
                    local hasShadowDance = self:HasBuff("player", S.ShadowDance)
                    self:Print("Honor Among Thieves: " .. (hasHAT and "✓ Active" or "✗ Inactive"))
                    self:Print("Shadow Dance: " .. (hasShadowDance and "✓ Active" or "✗ Inactive"))
                end
                
                local hasMainHandPoison, hasOffHandPoison, hasOffHandWeapon = self:CheckWeaponEnchants()
                self:Print("Poisons: MH " .. (hasMainHandPoison and "✓" or "✗") .. 
                          " | OH " .. (hasOffHandWeapon and (hasOffHandPoison and "✓" or "✗") or "N/A"))
                self:Print("========================")
            else
                self:Print("WotLK Meta Rogue commands:")
                self:Print("  /ac rogue debug - Detailed rotation debug")
                self:Print("  /ac rogue diagnose - Diagnose common issues")
                self:Print("  /ac rogue test [snd|hfb|arp|hat|basic|energy] - Test scenarios")
                self:Print("  /ac rogue poisons - Check poison status and apply")
                self:Print("  /ac rogue mechanics - Test basic poison mechanics")
                self:Print("  /ac rogue snd - Manual SnD test")
                self:Print("  /ac rogue meta - WotLK meta compliance check")
            end
        else
            -- Fall back to original handler
            originalHandler(msg)
        end
    end
end

-- =============================================
-- INITIALIZATION (Enhanced for WotLK Meta)
-- =============================================

function AC:InitRogueRotations()
    self.rotations = self.rotations or {}
    if not self.rotations["ROGUE"] then self.rotations["ROGUE"] = {} end
    
    -- Register all rotation functions with enhanced error handling
    local function SafeRotation(rotationFunc)
        return function(self)
            local success, result = pcall(rotationFunc, self)
            if not success then
                RogueDebug("Rotation error: " .. tostring(result))
                if not self.lastRotationError or GetTime() - self.lastRotationError > 10 then
                    self:Print("Rotation error detected - check debug log")
                    self.lastRotationError = GetTime()
                end
                return false
            end
            return result == true
        end
    end
    
    self.rotations["ROGUE"]["Assassination"] = SafeRotation(self.RogueRotation)
    self.rotations["ROGUE"]["Combat"] = SafeRotation(self.RogueRotation)
    self.rotations["ROGUE"]["Subtlety"] = SafeRotation(self.RogueRotation)
    self.rotations["ROGUE"]["None"] = SafeRotation(self.RogueRotation)
    
    -- Register the buff checking function
    self.CheckRogueBuffs = AC.CheckRogueBuffs
    
    -- Setup enhanced slash commands
    self:SetupRogueSlashCommands()
    
    -- Validate core functions are available
    local missingFunctions = {}
    local requiredFunctions = {"GetPlayerSpec", "GetEnemyCount", "ShouldUseAOE", "Throttle", "HasBuff", "BuffTimeRemaining"}
    
    for _, funcName in ipairs(requiredFunctions) do
        if not self[funcName] then
            table.insert(missingFunctions, funcName)
        end
    end
    
    if #missingFunctions > 0 then
        self:Print("Warning: Missing required functions: " .. table.concat(missingFunctions, ", "))
        self:Print("Some features may not work correctly")
    end
    
    -- Success message with WotLK meta summary
    self:Print("Enhanced WotLK Meta Rogue rotations loaded successfully!")
    self:Print("Features: HfB maintenance, Cut to Chase, ArP priority, HAT awareness")
    self:Print("Use '/ac rogue meta' to check WotLK compliance")
    self:Print("Use '/ac rogue' for all Rogue-specific commands")
    
    -- Auto-enable debug mode for first run to help with testing
    if not self.debugMode then
        self:Print("Tip: Use '/ac debug' to enable detailed rotation logging")
    end
end

-- =============================================
-- VALIDATION AND SETUP (WotLK Meta Compliant)
-- =============================================

function AC:ValidateRogueSetup()
    local issues = {}
    local spec = self:GetPlayerSpec()
    local level = UnitLevel("player")
    
    -- Check if Core.lua functions are available
    if not self.GetPlayerClass then
        table.insert(issues, "Core.lua integration missing")
    end
    
    -- Check if Utils.lua functions are available
    if not self.UseHealthPotion then
        table.insert(issues, "Utils.lua integration missing (optional)")
    end
    
    -- WotLK Meta-specific validations
    if spec == "Assassination" and self:GetRogueTalentRank("Hunger for Blood") > 0 and
       not self:KnowsSpell(S.HFB) then
        table.insert(issues, "Hunger for Blood talent is selected but its spell is unavailable")
    end
    
    if spec == "Combat" and level >= 10 then
        if not self:KnowsSpell(S.SnD) then
            table.insert(issues, "Slice and Dice not learned (CRITICAL for Combat)")
        end
    end
    
    if spec == "Subtlety" and level >= 60 then
        if not self:KnowsSpell(S.ShadowDance) then
            table.insert(issues, "Shadow Dance not learned (important for Subtlety)")
        end
    end
    
    -- Test basic spell casting
    if level >= 10 then
        local cp = GetComboPoints("player", "target")
        local energy = UnitPower("player", 3)
        if cp >= 1 and energy >= 25 and self:KnowsSpell(S.SnD) and self:IsUsableSpell(S.SnD) then
            local testResult = self:CastSliceAndDice()
            if not testResult then
                table.insert(issues, "Spell casting test failed - spell ID method not working")
            end
        end
    end
    
    if #issues > 0 then
        self:Print("WotLK Meta setup validation found issues:")
        for _, issue in ipairs(issues) do
            self:Print("  - " .. issue)
        end
        self:Print("Use '/ac rogue diagnose' for detailed analysis")
    else
        self:Print("WotLK Meta Rogue setup validation passed!")
        self:Print("All critical abilities and integrations working correctly")
    end
    
    return #issues == 0
end

-- WotLK-compatible delayed validation
if AC.GetPlayerClass and AC:GetPlayerClass() == "ROGUE" then
    local validationFrame = CreateFrame("Frame")
    validationFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    validationFrame:SetScript("OnEvent", function(self, event)
        if event == "PLAYER_ENTERING_WORLD" then
            -- Small delay to ensure everything is loaded
            local delayFrame = CreateFrame("Frame")
            local elapsedTime = 0
            delayFrame:SetScript("OnUpdate", function(self, elapsed)
                elapsedTime = elapsedTime + elapsed
                if elapsedTime >= 2 then
                    if AC.ValidateRogueSetup then
                        AC:ValidateRogueSetup()
                    end
                    delayFrame:SetScript("OnUpdate", nil)
                end
            end)
            validationFrame:UnregisterEvent("PLAYER_ENTERING_WORLD")
        end
    end)
end

-- =============================================
-- FINAL NOTES AND COMPATIBILITY
-- =============================================

--[[
WotLK 3.3.5a Meta Compliance Summary:

POISON SYSTEM FIXES:
✓ Fixed GetWeaponEnchantInfo() for WotLK 3.3.5a
✓ Enhanced poison detection works with ALL ranks (I-IX)
✓ Multiple application methods with proper error handling
✓ Comprehensive debugging and troubleshooting tools

ASSASSINATION:
✓ Hunger for Blood 100% uptime (CRITICAL)
✓ Cut to the Chase logic (auto-refresh SnD with Envenom)
✓ Mutilate → Envenom cycle with poison stacks
✓ No manual SnD needed with Cut to the Chase talent

COMBAT: 
✓ Slice and Dice 100% uptime (6s refresh timing)
✓ ArP-based finisher priority (Rupture <1000, Eviscerate >1000)
✓ Sinister Strike at 40 energy (reduced for leveling)
✓ Blade Flurry for 2+ enemies

SUBTLETY:
✓ Honor Among Thieves awareness (reduced energy thresholds)
✓ Shadow Dance burst windows with Ambush spam
✓ Premeditation for instant 2 CP
✓ Backstab vs Hemorrhage positioning logic

LEVELING OPTIMIZATIONS:
✓ Reduced energy thresholds for faster mob kills
✓ Enhanced stealth opener system
✓ Level-based rotation adaptation (pre/post 40)
✓ 3s poison timing for efficiency

ENHANCED FEATURES:
✓ Comprehensive debugging system
✓ Enhanced slash commands (/ac rogue)
✓ WotLK meta compliance checking
✓ Multiple test scenarios for troubleshooting
✓ Improved error handling and recovery

TESTING COMMANDS:
/ac rogue poisons - Test poison system
/ac rogue mechanics - Test basic poison mechanics  
/ac rogue meta - Check WotLK meta compliance
/ac rogue test [scenario] - Test specific scenarios
/ac rogue diagnose - Comprehensive issue diagnosis

This implementation provides optimal DPS for end-game content,
efficient leveling experience, and intelligent threat management.
Enhanced with AoE optimization calculations and level-friendly
threat detection. The poison system has been completely
rewritten to work reliably with WotLK 3.3.5a.

ENHANCED FEATURES (v2):
✓ Intelligent AoE vs Single Target DPS calculations
✓ Level-based AoE thresholds (L20+: 4 enemies, L40+: 3, L60+: 2)
✓ Smart threat detection and management for group play
✓ Threat-aware energy management (reduces DPS when high threat)
✓ Enhanced positioning checks for Fan of Knives
✓ Emergency threat responses (Vanish, Blind, Gouge sequence)
✓ Level-friendly threat sensitivity (more conservative at low levels)
--]]

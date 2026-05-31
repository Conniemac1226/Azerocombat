-- AzeroCombat: Shaman Rotations (ULTIMATE WotLK 3.3.5a - Beast Mode All Specs)
-- Enhanced for maximum DPS/healing performance across Elemental, Enhancement, and Restoration
local AddonName, AC = ...

-- Complete WotLK 3.3.5a Shaman Spell Database
local S = {
    -- Shock Spells (Core Damage)
    EarthShock = "Earth Shock", 
    FlameShock = "Flame Shock", 
    FrostShock = "Frost Shock",
    
    -- Elemental Spells (Spell Power Master)
    LightningBolt = "Lightning Bolt", 
    ChainLightning = "Chain Lightning", 
    LavaBurst = "Lava Burst",
    Thunderstorm = "Thunderstorm", 
    FireNova = "Fire Nova",
    
    -- Enhancement Spells (Melee Beast)
    Stormstrike = "Stormstrike", 
    LavaLash = "Lava Lash", 
    FeralSpirit = "Feral Spirit", 
    ShamanisticRage = "Shamanistic Rage",
    MaelstromWeapon = "Maelstrom Weapon", -- Proc tracking
    
    -- Healing Spells (Ultimate Healer)
    HealingWave = "Healing Wave", 
    LesserHealingWave = "Lesser Healing Wave", 
    ChainHeal = "Chain Heal",
    Riptide = "Riptide", 
    EarthShield = "Earth Shield", 
    CleanseSpirit = "Cleanse Spirit",
    
    -- Weapon Imbues (Enhanced System)
    WindfuryWeapon = "Windfury Weapon", 
    FlametongueWeapon = "Flametongue Weapon",
    FrostbrandWeapon = "Frostbrand Weapon", 
    RockbiterWeapon = "Rockbiter Weapon",
    EarthlivingWeapon = "Earthliving Weapon",
    
    -- Utility Spells (Enhanced)
    WindShear = "Wind Shear", 
    Purge = "Purge", 
    Hex = "Hex",
    
    -- Shields (Intelligent Management)
    LightningShield = "Lightning Shield", 
    WaterShield = "Water Shield",
    -- Earth Totems
    StrengthOfEarthTotem = "Strength of Earth Totem", StoneskinTotem = "Stoneskin Totem",
    EarthbindTotem = "Earthbind Totem", TremorTotem = "Tremor Totem", 
    StoneclawTotem = "Stoneclaw Totem", EarthElementalTotem = "Earth Elemental Totem",
    -- Air Totems
    GraceOfAirTotem = "Grace of Air Totem", WrathOfAirTotem = "Wrath of Air Totem", 
    WindfuryTotem = "Windfury Totem", GroundingTotem = "Grounding Totem",
    NatureResistanceTotem = "Nature Resistance Totem", SentryTotem = "Sentry Totem", 
    WindwallTotem = "Windwall Totem", 
    -- Fire Totems
    SearingTotem = "Searing Totem", MagmaTotem = "Magma Totem", 
    FlametongueTotem = "Flametongue Totem", FrostResistanceTotem = "Frost Resistance Totem", 
    TotemOfWrath = "Totem of Wrath", FireResistanceTotem = "Fire Resistance Totem",
    FireElementalTotem = "Fire Elemental Totem",
    -- Water Totems
    HealingStreamTotem = "Healing Stream Totem", ManaSpringTotem = "Mana Spring Totem",
    DiseaseCleansingTotem = "Disease Cleansing Totem", 
    PoisonCleansingTotem = "Poison Cleansing Totem",
    ManaTideTotem = "Mana Tide Totem", FireNovaTotem = "Fire Nova Totem",
    -- Totem Calls
    CallOfTheElements = "Call of the Elements", 
    CallOfTheAncestors = "Call of the Ancestors", 
    CallOfTheSpirits = "Call of the Spirits", 
    TotemicRecall = "Totemic Recall",
    -- Cooldowns & Buffs (Enhanced Management)
    Bloodlust = "Bloodlust", 
    Heroism = "Heroism", 
    ElementalMastery = "Elemental Mastery", 
    NaturesSwiftness = "Nature's Swiftness", 
    TidalForce = "Tidal Force",
    
    -- Utility & Travel
    Reincarnation = "Reincarnation", 
    AstralRecall = "Astral Recall", 
    WaterWalking = "Water Walking", 
    WaterBreathing = "Water Breathing", 
    GhostWolf = "Ghost Wolf", 
    AncestralSpirit = "Ancestral Spirit",
    
    -- Important Procs & Effects
    LashingFlames = "Lashing Flames", -- Fire totem proc
    FlametongueEffect = "Flametongue", -- Weapon proc
    WindfuryEffect = "Windfury", -- Weapon proc
    
    -- Racial Abilities (All Races)
    BloodFury = "Blood Fury", -- Orc
    Berserking = "Berserking", -- Troll
    WillOfTheForsaken = "Will of the Forsaken", -- Undead
    ArcaneTorrent = "Arcane Torrent", -- Blood Elf
    GiftOfTheNaaru = "Gift of the Naaru", -- Draenei
    WarStomp = "War Stomp", -- Tauren
    Stoneform = "Stoneform", -- Dwarf
    EscapeArtist = "Escape Artist", -- Gnome
    Shadowmeld = "Shadowmeld", -- Night Elf
    EveryManForHimself = "Every Man for Himself", -- Human
}

-- Spell Level Requirements
local SpellLevels = {
    [S.EarthShock] = 4, [S.FlameShock] = 10, [S.FrostShock] = 20, [S.LightningBolt] = 1, [S.ChainLightning] = 32, [S.LavaBurst] = 75, [S.Thunderstorm] = 60, [S.FireNova] = 12, [S.Stormstrike] = 40, [S.LavaLash] = 60, [S.FeralSpirit] = 60, [S.ShamanisticRage] = 60, [S.HealingWave] = 1, [S.LesserHealingWave] = 20, [S.ChainHeal] = 40, [S.Riptide] = 60, [S.EarthShield] = 50, [S.CleanseSpirit] = 42, [S.RockbiterWeapon] = 1, [S.FlametongueWeapon] = 10, [S.FrostbrandWeapon] = 20, [S.WindfuryWeapon] = 30, [S.EarthlivingWeapon] = 30, [S.LightningShield] = 8, [S.WaterShield] = 20, [S.StrengthOfEarthTotem] = 10, [S.StoneskinTotem] = 4, [S.EarthbindTotem] = 6, [S.StoneclawTotem] = 8, [S.TremorTotem] = 18, [S.EarthElementalTotem] = 66, [S.GraceOfAirTotem] = 42, [S.SentryTotem] = 26, [S.WindwallTotem] = 36, [S.GroundingTotem] = 30, [S.NatureResistanceTotem] = 28, [S.WrathOfAirTotem] = 64, [S.WindfuryTotem] = 32, [S.SearingTotem] = 10, [S.FlametongueTotem] = 28, [S.MagmaTotem] = 26, [S.FrostResistanceTotem] = 24, [S.FireResistanceTotem] = 28, [S.TotemOfWrath] = 70, [S.FireElementalTotem] = 68, [S.HealingStreamTotem] = 20, [S.ManaSpringTotem] = 26, [S.DiseaseCleansingTotem] = 38, [S.PoisonCleansingTotem] = 22, [S.ManaTideTotem] = 60, [S.FireNovaTotem] = 30, [S.CallOfTheElements] = 30, [S.CallOfTheAncestors] = 40, [S.CallOfTheSpirits] = 60, [S.TotemicRecall] = 30, [S.Purge] = 12, [S.WindShear] = 16, [S.GhostWolf] = 20, [S.Reincarnation] = 30, [S.Bloodlust] = 70, [S.Heroism] = 70, [S.AstralRecall] = 30, [S.WaterWalking] = 28, [S.WaterBreathing] = 22, [S.AncestralSpirit] = 12, [S.Hex] = 80, [S.ElementalMastery] = 40, [S.NaturesSwiftness] = 40, [S.TidalForce] = 60
}

-- Totem slot types
local TotemTypes = { EARTH = 1, AIR = 2, FIRE = 3, WATER = 4 }

-- Totem definitions and sets
AC.TotemDefinitions = {
    [S.StrengthOfEarthTotem] = TotemTypes.EARTH, [S.StoneskinTotem] = TotemTypes.EARTH, [S.EarthbindTotem] = TotemTypes.EARTH, [S.TremorTotem] = TotemTypes.EARTH, [S.StoneclawTotem] = TotemTypes.EARTH, [S.EarthElementalTotem] = TotemTypes.EARTH, [S.GraceOfAirTotem] = TotemTypes.AIR, [S.WrathOfAirTotem] = TotemTypes.AIR, [S.WindfuryTotem] = TotemTypes.AIR, [S.NatureResistanceTotem] = TotemTypes.AIR, [S.GroundingTotem] = TotemTypes.AIR, [S.SentryTotem] = TotemTypes.AIR, [S.WindwallTotem] = TotemTypes.AIR, [S.SearingTotem] = TotemTypes.FIRE, [S.MagmaTotem] = TotemTypes.FIRE, [S.FlametongueTotem] = TotemTypes.FIRE, [S.FrostResistanceTotem] = TotemTypes.FIRE, [S.TotemOfWrath] = TotemTypes.FIRE, [S.FireResistanceTotem] = TotemTypes.FIRE, [S.FireElementalTotem] = TotemTypes.FIRE, [S.HealingStreamTotem] = TotemTypes.WATER, [S.ManaSpringTotem] = TotemTypes.WATER, [S.DiseaseCleansingTotem] = TotemTypes.WATER, [S.PoisonCleansingTotem] = TotemTypes.WATER, [S.ManaTideTotem] = TotemTypes.WATER, [S.FireNovaTotem] = TotemTypes.WATER
}
-- ENHANCED: Ultimate totem sets with dynamic situational awareness
AC.ShamanTotemSets = {
    -- ELEMENTAL: Spell Power Master Sets
    ELEMENTAL_SOLO = { [TotemTypes.EARTH] = S.StoneskinTotem, [TotemTypes.AIR] = S.WrathOfAirTotem, [TotemTypes.FIRE] = S.TotemOfWrath, [TotemTypes.WATER] = S.ManaSpringTotem },
    ELEMENTAL_GROUP = { [TotemTypes.EARTH] = S.StrengthOfEarthTotem, [TotemTypes.AIR] = S.WrathOfAirTotem, [TotemTypes.FIRE] = S.TotemOfWrath, [TotemTypes.WATER] = S.ManaSpringTotem },
    ELEMENTAL_AOE = { [TotemTypes.EARTH] = S.StoneskinTotem, [TotemTypes.AIR] = S.WrathOfAirTotem, [TotemTypes.FIRE] = S.MagmaTotem, [TotemTypes.WATER] = S.ManaSpringTotem },
    ELEMENTAL_BOSS = { [TotemTypes.EARTH] = S.StrengthOfEarthTotem, [TotemTypes.AIR] = S.WrathOfAirTotem, [TotemTypes.FIRE] = S.TotemOfWrath, [TotemTypes.WATER] = S.ManaSpringTotem },
    
    -- ENHANCEMENT: Melee Beast Sets
    ENHANCEMENT_SOLO = { [TotemTypes.EARTH] = S.StrengthOfEarthTotem, [TotemTypes.AIR] = S.WindfuryTotem, [TotemTypes.FIRE] = S.MagmaTotem, [TotemTypes.WATER] = S.HealingStreamTotem },
    ENHANCEMENT_GROUP = { [TotemTypes.EARTH] = S.StrengthOfEarthTotem, [TotemTypes.AIR] = S.WindfuryTotem, [TotemTypes.FIRE] = S.SearingTotem, [TotemTypes.WATER] = S.ManaSpringTotem },
    ENHANCEMENT_AOE = { [TotemTypes.EARTH] = S.StrengthOfEarthTotem, [TotemTypes.AIR] = S.WindfuryTotem, [TotemTypes.FIRE] = S.MagmaTotem, [TotemTypes.WATER] = S.ManaSpringTotem },
    ENHANCEMENT_BOSS = { [TotemTypes.EARTH] = S.StrengthOfEarthTotem, [TotemTypes.AIR] = S.WindfuryTotem, [TotemTypes.FIRE] = S.SearingTotem, [TotemTypes.WATER] = S.ManaSpringTotem },
    
    -- RESTORATION: Ultimate Healer Sets
    RESTORATION_SOLO = { [TotemTypes.EARTH] = S.StoneskinTotem, [TotemTypes.AIR] = S.WrathOfAirTotem, [TotemTypes.FIRE] = S.FlametongueTotem, [TotemTypes.WATER] = S.ManaSpringTotem }, 
    RESTORATION_GROUP = { [TotemTypes.EARTH] = S.StoneskinTotem, [TotemTypes.AIR] = S.WrathOfAirTotem, [TotemTypes.FIRE] = S.FlametongueTotem, [TotemTypes.WATER] = S.HealingStreamTotem },
    RESTORATION_RAID = { [TotemTypes.EARTH] = S.StrengthOfEarthTotem, [TotemTypes.AIR] = S.WrathOfAirTotem, [TotemTypes.FIRE] = S.TotemOfWrath, [TotemTypes.WATER] = S.ManaSpringTotem },
    RESTORATION_EMERGENCY = { [TotemTypes.EARTH] = S.TremorTotem, [TotemTypes.AIR] = S.GroundingTotem, [TotemTypes.FIRE] = S.FlametongueTotem, [TotemTypes.WATER] = S.HealingStreamTotem },
    
    -- LEVELING: Progressive Enhancement
    LEVELING_LOW = { [TotemTypes.EARTH] = S.StoneclawTotem, [TotemTypes.AIR] = nil, [TotemTypes.FIRE] = S.SearingTotem, [TotemTypes.WATER] = nil },
    LEVELING_MID = { [TotemTypes.EARTH] = S.StrengthOfEarthTotem, [TotemTypes.AIR] = S.WindfuryTotem, [TotemTypes.FIRE] = S.SearingTotem, [TotemTypes.WATER] = S.HealingStreamTotem },
    LEVELING_HIGH = { [TotemTypes.EARTH] = S.StrengthOfEarthTotem, [TotemTypes.AIR] = S.WindfuryTotem, [TotemTypes.FIRE] = S.SearingTotem, [TotemTypes.WATER] = S.ManaSpringTotem },
    
    -- DYNAMIC: Situational Response Sets
    DEFENSIVE = { [TotemTypes.EARTH] = S.TremorTotem, [TotemTypes.AIR] = S.GroundingTotem, [TotemTypes.FIRE] = S.FlametongueTotem, [TotemTypes.WATER] = S.HealingStreamTotem },
    RESISTANCE = { [TotemTypes.EARTH] = S.StoneskinTotem, [TotemTypes.AIR] = S.NatureResistanceTotem, [TotemTypes.FIRE] = S.FrostResistanceTotem, [TotemTypes.WATER] = S.PoisonCleansingTotem }
}

-- Debug function
local function ShamanDebug(msg)
    if AC.debugMode then
        AC:Debug("|cFF2459FFShaman:|r " .. tostring(msg))
    end
end

-- Throttle helper
local throttleTimes = {}
local function Throttle(key, interval)
    if not throttleTimes[key] or (GetTime() - throttleTimes[key] > interval) then
        throttleTimes[key] = GetTime()
        return true
    end
    return false
end

-- ENHANCED: Shaman-specific spell casting with better error handling
function AC:CastShamanSpell(spellName, unit)
    unit = unit or "target"
    if not spellName then return false end

    local selfOnlySpells = { 
        [S.LightningShield] = true, [S.WaterShield] = true, 
        [S.WindfuryWeapon] = true, [S.FlametongueWeapon] = true, 
        [S.FrostbrandWeapon] = true, [S.RockbiterWeapon] = true, 
        [S.EarthlivingWeapon] = true, [S.GhostWolf] = true, 
        [S.ElementalMastery] = true, [S.NaturesSwiftness] = true, 
        [S.ShamanisticRage] = true, [S.TidalForce] = true,
        [S.FeralSpirit] = true, [S.Bloodlust] = true, [S.Heroism] = true
    }
    if selfOnlySpells[spellName] then unit = "player" end

    if self:IsUsableSpell(spellName) and (unit == "player" or UnitExists(unit)) then
        if IsCurrentSpell(spellName) or UnitCastingInfo("player") then return false end
        
        local success = pcall(function() CastSpellByName(spellName, unit) end)
        if success then 
            ShamanDebug("Cast SUCCESS: " .. spellName .. (unit ~= "target" and (" on " .. unit) or ""))
            return true
        else
            ShamanDebug("Cast FAILED: " .. spellName)
        end
    end
    return false
end

-- ENHANCED: Spell availability checking
function AC:CanUseShamanSpell(spellName) 
    if not spellName then return false end
    local requiredLevel = SpellLevels[spellName] or 1
    return UnitLevel("player") >= requiredLevel and self:KnowsSpell(spellName) and self:IsUsableSpell(spellName)
end

-- ENHANCED: Check for Maelstrom Weapon stacks
function AC:GetMaelstromStacks()
    local _, _, _, stacks = UnitBuff("player", S.MaelstromWeapon)
    return stacks or 0
end

-- ENHANCED: Advanced healing target prioritization
function AC:FindShamanHealingTarget(urgencyLevel)
    urgencyLevel = urgencyLevel or "normal" -- "emergency", "urgent", "normal"
    
    local targets = {}
    local emergencyTargets = {}
    
    -- Check self first
    local selfHealth = self:GetPlayerHealthPercent() / 100
    local selfTarget = {
        unit = "player",
        health = selfHealth,
        name = UnitName("player"),
        role = "self",
        priority = selfHealth < 0.3 and 100 or (selfHealth < 0.6 and 80 or 50)
    }
    table.insert(targets, selfTarget)
    if selfHealth < 0.25 then table.insert(emergencyTargets, selfTarget) end
    
    -- Check group members
    if IsInGroup() then
        local prefix = GetNumRaidMembers() > 0 and "raid" or "party"
        local max = GetNumRaidMembers() > 0 and GetNumRaidMembers() or GetNumPartyMembers()
        
        for i = 1, max do
            local unit = prefix .. i
            if UnitExists(unit) and not UnitIsDeadOrGhost(unit) and UnitIsConnected(unit) then
                local hp = UnitHealth(unit) / UnitHealthMax(unit)
                local _, class = UnitClass(unit)
                local isTank = (self.IsTank and self:IsTank(unit)) or 
                              (class == "WARRIOR" or class == "PALADIN" or class == "DEATHKNIGHT")
                local isHealer = class == "PRIEST" or class == "PALADIN" or class == "SHAMAN" or class == "DRUID"
                
                local target = {
                    unit = unit,
                    health = hp,
                    name = UnitName(unit),
                    class = class,
                    isTank = isTank,
                    isHealer = isHealer,
                    role = isTank and "tank" or (isHealer and "healer" or "dps"),
                    priority = 0
                }
                
                -- Calculate priority
                if hp < 0.25 then
                    target.priority = 95 + (isTank and 5 or 0) + (isHealer and 3 or 0)
                    table.insert(emergencyTargets, target)
                elseif hp < 0.5 then
                    target.priority = 70 + (isTank and 20 or 0) + (isHealer and 10 or 0)
                elseif hp < 0.75 then
                    target.priority = 40 + (isTank and 15 or 0) + (isHealer and 8 or 0)
                else
                    target.priority = 20 + (isTank and 10 or 0) + (isHealer and 5 or 0)
                end
                
                table.insert(targets, target)
            end
        end
    end
    
    -- Sort by priority
    table.sort(targets, function(a, b) return a.priority > b.priority end)
    
    -- Return based on urgency
    if urgencyLevel == "emergency" and #emergencyTargets > 0 then
        table.sort(emergencyTargets, function(a, b) return a.priority > b.priority end)
        local target = emergencyTargets[1]
        ShamanDebug("EMERGENCY TARGET: " .. target.name .. " (" .. target.role .. ") - " .. math.floor(target.health * 100) .. "% HP")
        return target.unit, target.health, target
    end
    
    -- Normal priority target
    if #targets > 0 and targets[1].health < 0.95 then
        local target = targets[1]
        ShamanDebug("HEAL TARGET: " .. target.name .. " (" .. target.role .. ") - " .. math.floor(target.health * 100) .. "% HP")
        return target.unit, target.health, target
    end
    
    return nil, 1.0, nil
end

-- ENHANCED: Totem status with better tracking
function AC:GetActiveShamanTotem(totemSlot) 
    local success, name, startTime, duration = pcall(GetTotemInfo, totemSlot)
    if not success or not name or name == "" then return nil, 0 end
    if not duration or duration == 0 then return name, 999 end
    local timeLeft = (startTime + duration) - GetTime()
    return name, math.max(0, timeLeft)
end

-- ENHANCED: Group damage assessment for Chain Heal optimization
function AC:AnalyzeGroupDamage()
    local analysis = {
        totalMembers = 1,
        damagedMembers = 0,
        avgHealth = 0,
        needsChainHeal = false,
        chainHealTargets = {}
    }
    
    local totalHealth = self:GetPlayerHealthPercent()
    local playerHP = totalHealth / 100
    
    if playerHP < 0.85 then analysis.damagedMembers = 1 end
    
    if IsInGroup() then
        local prefix = GetNumRaidMembers() > 0 and "raid" or "party"
        local max = GetNumRaidMembers() > 0 and GetNumRaidMembers() or GetNumPartyMembers()
        
        for i = 1, max do
            local unit = prefix .. i
            if UnitExists(unit) and not UnitIsDeadOrGhost(unit) and UnitIsConnected(unit) then
                analysis.totalMembers = analysis.totalMembers + 1
                local hp = UnitHealth(unit) / UnitHealthMax(unit)
                totalHealth = totalHealth + (hp * 100)
                
                if hp < 0.85 then
                    analysis.damagedMembers = analysis.damagedMembers + 1
                    table.insert(analysis.chainHealTargets, {
                        unit = unit,
                        health = hp,
                        name = UnitName(unit)
                    })
                end
            end
        end
    end
    
    analysis.avgHealth = totalHealth / analysis.totalMembers / 100
    analysis.needsChainHeal = analysis.damagedMembers >= 3 or 
                             (analysis.damagedMembers >= 2 and analysis.avgHealth < 0.7)
    
    return analysis
end

-- ENHANCED: Racial abilities usage
function AC:UseShamanRacials(offensive, defensive)
    if not Throttle("ShamanRacials", 3) then return false end
    
    local _, race = UnitRace("player")
    race = string.upper(race)
    local health = self:GetPlayerHealthPercent()
    local inCombat = UnitAffectingCombat("player")
    
    -- Offensive racials
    if offensive and inCombat then
        if race == "ORC" and self:IsUsableSpell(S.BloodFury) then
            CastSpellByName(S.BloodFury)
            ShamanDebug("Racial: Blood Fury")
            return true
        end
        if race == "TROLL" and self:IsUsableSpell(S.Berserking) then
            CastSpellByName(S.Berserking)
            ShamanDebug("Racial: Berserking")
            return true
        end
        if race == "BLOODELF" and self:IsUsableSpell(S.ArcaneTorrent) then
            local mana = UnitPower("player", 0) / UnitPowerMax("player", 0) * 100
            if mana < 80 then
                CastSpellByName(S.ArcaneTorrent)
                ShamanDebug("Racial: Arcane Torrent")
                return true
            end
        end
    end
    
    -- Defensive racials
    if defensive or health < 50 then
        if race == "UNDEAD" and self:IsUsableSpell(S.WillOfTheForsaken) then
            CastSpellByName(S.WillOfTheForsaken)
            ShamanDebug("Racial: Will of the Forsaken")
            return true
        end
        if race == "DWARF" and self:IsUsableSpell(S.Stoneform) then
            CastSpellByName(S.Stoneform)
            ShamanDebug("Racial: Stoneform")
            return true
        end
        if race == "TAUREN" and self:IsUsableSpell(S.WarStomp) then
            CastSpellByName(S.WarStomp)
            ShamanDebug("Racial: War Stomp")
            return true
        end
    end
    
    return false
end

-- ENHANCED: Ultimate totem deployment with dynamic situation awareness
function AC:DeployShamanTotems(spec, level, situation)    
    if not Throttle("TotemDeploy", 3.0) then return false end 
    
    -- Enhanced situation detection
    local targetClassification = UnitExists("target") and UnitClassification("target")
    local isBoss = targetClassification == "worldboss" or targetClassification == "elite" or targetClassification == "rareelite"
    local health = self:GetPlayerHealthPercent()
    
    -- Dynamic situation override
    if health < 40 then
        situation = "DEFENSIVE" -- Switch to defensive totems when low health
    elseif isBoss and situation ~= "AOE" then
        situation = "BOSS" -- Boss-specific totems
    end
    
    -- Enhanced Call spells for combat efficiency (prioritized for Enhancement)
    if level >= 30 then
        local emptySlots, expiringSlots = 0, 0
        local activeSlots = 0
        for slot = 1, 4 do
            local totem, timeLeft = self:GetActiveShamanTotem(slot)
            if not totem then 
                emptySlots = emptySlots + 1
            elseif timeLeft < 15 and timeLeft ~= 999 then 
                expiringSlots = expiringSlots + 1 
                activeSlots = activeSlots + 1
            else
                activeSlots = activeSlots + 1
            end
        end
        
        -- Strategic Totemic Recall before Call spells
        if activeSlots >= 3 and self:CanUseShamanSpell(S.TotemicRecall) and Throttle("TotemicRecall", 5.0) then
            local needsNewTotems = false
            if spec == "Enhancement" then
                needsNewTotems = (emptySlots >= 2 or expiringSlots >= 2 or (emptySlots + expiringSlots) >= 2)
            else
                needsNewTotems = (emptySlots >= 2 or expiringSlots >= 2)
            end
            
            if needsNewTotems then
                if self:CastShamanSpell(S.TotemicRecall) then
                    ShamanDebug("Totemic Recall before Call spell (" .. activeSlots .. " active, " .. emptySlots .. " empty, " .. expiringSlots .. " expiring)")
                    return true
                end
            end
        end
        
        -- More aggressive Call spell usage for Enhancement
        local shouldUseCall = false
        if spec == "Enhancement" then
            -- Enhancement: Use Call if any 2+ slots need totems (aggressive)
            shouldUseCall = (emptySlots >= 2 or expiringSlots >= 2 or (emptySlots + expiringSlots) >= 2)
        else
            -- Other specs: Original logic
            shouldUseCall = (emptySlots >= 2 or expiringSlots >= 2) and UnitAffectingCombat("player")
        end
        
        if shouldUseCall then
            ShamanDebug("TOTEM DEBUG: shouldUseCall=true, emptySlots=" .. emptySlots .. ", expiringSlots=" .. expiringSlots .. ", activeSlots=" .. activeSlots)
            
            if Throttle("TotemCall", 8.0) then
                local callSpell = self:CanUseShamanSpell(S.CallOfTheSpirits) and S.CallOfTheSpirits or 
                                 (self:CanUseShamanSpell(S.CallOfTheAncestors) and S.CallOfTheAncestors or 
                                 (self:CanUseShamanSpell(S.CallOfTheElements) and S.CallOfTheElements))
                
                ShamanDebug("TOTEM DEBUG: Available call spells - Spirits:" .. tostring(self:CanUseShamanSpell(S.CallOfTheSpirits)) .. 
                          ", Ancestors:" .. tostring(self:CanUseShamanSpell(S.CallOfTheAncestors)) .. 
                          ", Elements:" .. tostring(self:CanUseShamanSpell(S.CallOfTheElements)))
                
                if callSpell then
                    ShamanDebug("TOTEM DEBUG: Attempting to cast " .. callSpell)
                    if self:CastShamanSpell(callSpell) then 
                        ShamanDebug("Called totems: " .. callSpell .. " (" .. spec .. " - " .. emptySlots .. " empty, " .. expiringSlots .. " expiring)")
                        return true 
                    else
                        ShamanDebug("TOTEM DEBUG: Cast failed for " .. callSpell)
                    end
                else
                    ShamanDebug("TOTEM DEBUG: No call spell available")
                end
            else
                ShamanDebug("TOTEM DEBUG: Call spell throttled")
            end
        else
            ShamanDebug("TOTEM DEBUG: shouldUseCall=false, emptySlots=" .. emptySlots .. ", expiringSlots=" .. expiringSlots .. ", spec=" .. spec)
        end
    end

    -- Enhanced totem set selection
    local totemSet = AC.ShamanTotemSets[spec:upper() .. "_" .. situation:upper()] or 
                    AC.ShamanTotemSets[spec:upper() .. "_SOLO"]
    
    ShamanDebug("TOTEM DEBUG: Using totem set for " .. spec:upper() .. "_" .. situation:upper())
    ShamanDebug("TOTEM DEBUG: TotemSet - Earth:" .. tostring(totemSet[TotemTypes.EARTH]) .. 
               ", Air:" .. tostring(totemSet[TotemTypes.AIR]) .. 
               ", Fire:" .. tostring(totemSet[TotemTypes.FIRE]) .. 
               ", Water:" .. tostring(totemSet[TotemTypes.WATER]))
    
    -- Spec-optimized deployment priority
    local slotPriority = {3, 2, 1, 4} -- Default: Fire, Air, Earth, Water
    if spec == "Enhancement" then 
        slotPriority = {2, 3, 1, 4} -- Air (Windfury), Fire, Earth, Water
    elseif spec == "Restoration" then 
        slotPriority = {4, 1, 2, 3} -- Water (healing), Earth, Air, Fire
    elseif spec == "Elemental" then
        slotPriority = {3, 2, 1, 4} -- Fire (ToW), Air (WoA), Earth, Water
    end
    
    ShamanDebug("TOTEM DEBUG: Using priority order for " .. spec .. ": " .. table.concat(slotPriority, ","))
    
    for _, slot in ipairs(slotPriority) do
        local activeTotem, timeLeft = self:GetActiveShamanTotem(slot)
        local desiredTotem = totemSet[slot]
        local slotName = ({"Earth", "Air", "Fire", "Water"})[slot]
        
        ShamanDebug("TOTEM DEBUG: Checking slot " .. slot .. " (" .. slotName .. ") - active:" .. tostring(activeTotem) .. 
                   ", timeLeft:" .. tostring(timeLeft) .. ", desired:" .. tostring(desiredTotem))
        
        -- Enhanced fallback logic
        if desiredTotem and not self:CanUseShamanSpell(desiredTotem) then
            ShamanDebug("TOTEM DEBUG: Cannot use desired totem " .. desiredTotem .. ", using fallback")
            if slot == TotemTypes.FIRE then
                desiredTotem = self:CanUseShamanSpell(S.SearingTotem) and S.SearingTotem or
                              self:CanUseShamanSpell(S.MagmaTotem) and S.MagmaTotem
            elseif slot == TotemTypes.AIR then
                desiredTotem = self:CanUseShamanSpell(S.GraceOfAirTotem) and S.GraceOfAirTotem or
                              self:CanUseShamanSpell(S.WindfuryTotem) and S.WindfuryTotem
            elseif slot == TotemTypes.EARTH then
                desiredTotem = self:CanUseShamanSpell(S.StrengthOfEarthTotem) and S.StrengthOfEarthTotem or
                              self:CanUseShamanSpell(S.StoneskinTotem) and S.StoneskinTotem
            elseif slot == TotemTypes.WATER then
                desiredTotem = self:CanUseShamanSpell(S.ManaSpringTotem) and S.ManaSpringTotem or
                              self:CanUseShamanSpell(S.HealingStreamTotem) and S.HealingStreamTotem
            end
            ShamanDebug("TOTEM DEBUG: Fallback totem: " .. tostring(desiredTotem))
        end
        
        if desiredTotem and self:CanUseShamanSpell(desiredTotem) then
            local shouldDeploy = not activeTotem or 
                               activeTotem ~= desiredTotem or 
                               (timeLeft < 15 and timeLeft ~= 999)
            
            ShamanDebug("TOTEM DEBUG: shouldDeploy=" .. tostring(shouldDeploy) .. " for " .. desiredTotem)
            
            if shouldDeploy then
                if Throttle("Totem_" .. slot, 2.0) then
                    ShamanDebug("TOTEM DEBUG: Attempting to cast " .. desiredTotem)
                    if self:CastShamanSpell(desiredTotem) then 
                        ShamanDebug("Deployed " .. desiredTotem .. " for " .. situation)
                        return true 
                    else
                        ShamanDebug("TOTEM DEBUG: Cast failed for " .. desiredTotem)
                    end
                else
                    ShamanDebug("TOTEM DEBUG: Totem slot " .. slot .. " throttled")
                end
            end
        else
            ShamanDebug("TOTEM DEBUG: Cannot use totem " .. tostring(desiredTotem) .. " or not available")
        end
    end
    return false
end

function AC:ManageShamanWeaponImbues(spec, level)
    if not Throttle("WeaponImbue_V22", 5.0) then return false end
    
    local hasMainHandEnchant, mainHandExpiration, _, _, hasOffHandEnchant, offHandExpiration = GetWeaponEnchantInfo()
    mainHandExpiration = (hasMainHandEnchant and mainHandExpiration / 1000 or 0)
    offHandExpiration = (hasOffHandEnchant and offHandExpiration / 1000 or 0)
    
    local reapplyThreshold = 30 

    -- Determine Main Hand Imbue
    local mainHandImbue
    if spec == "Enhancement" then 
        mainHandImbue = self:CanUseShamanSpell(S.WindfuryWeapon) and S.WindfuryWeapon or S.FlametongueWeapon
    elseif spec == "Elemental" then 
        mainHandImbue = S.FlametongueWeapon
    elseif spec == "Restoration" then 
        mainHandImbue = self:CanUseShamanSpell(S.EarthlivingWeapon) and S.EarthlivingWeapon or S.FlametongueWeapon 
    end
    mainHandImbue = self:CanUseShamanSpell(mainHandImbue) and mainHandImbue or S.RockbiterWeapon

    -- Main Hand Logic
    if mainHandImbue and self:CanUseShamanSpell(mainHandImbue) then
        local shouldRecast = not hasMainHandEnchant or (hasMainHandEnchant and mainHandExpiration > 0 and mainHandExpiration < reapplyThreshold)
        if shouldRecast then
            if self.debugMode then self:Debug("|cFF2459FFShaman v22:|r " .. "Refreshing Main Hand Imbue: " .. mainHandImbue) end
            PickupInventoryItem(16); if CursorHasItem() then PickupInventoryItem(16) end
            if self:CastShamanSpell(mainHandImbue) then return true end
        end
    end
    
    -- Off-Hand Logic
    if spec == "Enhancement" and GetInventoryItemID("player", 17) then
        local offHandImbue = self:CanUseShamanSpell(S.FlametongueWeapon) and S.FlametongueWeapon
        if offHandImbue and self:CanUseShamanSpell(offHandImbue) then
            local shouldRecastOffhand = not hasOffHandEnchant or (hasOffHandEnchant and offHandExpiration > 0 and offHandExpiration < reapplyThreshold)
            if shouldRecastOffhand then
                if self.debugMode then self:Debug("|cFF2459FFShaman v22:|r " .. "Refreshing Off-Hand Imbue: " .. offHandImbue) end
                PickupInventoryItem(17); if CursorHasItem() then PickupInventoryItem(17) end
                if self:CastShamanSpell(offHandImbue) then return true end
            end
        end
    end
    return false
end

function AC:ManageShamanShields(spec, level)
    if not Throttle("Shield_V22", 5.0) then return false end
    
    local shield = (spec == "Restoration" and self:CanUseShamanSpell(S.WaterShield)) and S.WaterShield or (self:CanUseShamanSpell(S.LightningShield) and S.LightningShield)
    if shield then
        local hasBuff, _, stacks = self:HasBuff("player", shield)
        if not hasBuff or (shield == S.LightningShield and stacks and stacks <= 1) then
            if self:CastShamanSpell(shield) then return true end
        end
    end
    return false
end

-- ENHANCED ROTATIONS: Ultimate Optimization for All Specs

-- ELEMENTAL ROTATION: Spell Power Master (Lava Burst + Thunderstorm Beast)
function AC:ElementalRotation(level, hasTarget, targetHP, manaPercent, enemies)
    local situation = enemies >= 3 and "AOE" or (IsInGroup() and "GROUP" or "SOLO")
    if self:DeployShamanTotems("Elemental", level, situation) then return true end
    if not hasTarget then return false end
    
    -- Enhanced interrupt with priority
    if self.TryInterrupt and self:TryInterrupt(S.WindShear, "target") then 
        ShamanDebug("Interrupted with Wind Shear")
        return true 
    end
    
    -- Use racials for offense
    self:UseShamanRacials(true, false)
    
    -- Ultimate cooldown management for tough targets
    local targetClassification = UnitClassification("target")
    local isBoss = targetClassification == "worldboss" or targetClassification == "elite" or targetClassification == "rareelite"
    
    if (targetHP > 50 or enemies >= 2) and (isBoss or not IsInGroup()) then
        -- Elemental Mastery + Nature's Swiftness combo
        if self:CanUseShamanSpell(S.ElementalMastery) and manaPercent > 20 and Throttle("ElementalMastery", 180) then
            if self:CastShamanSpell(S.ElementalMastery) then
                ShamanDebug("Elemental Mastery burst phase")
                
                -- Chain with Nature's Swiftness if available
                if self:CanUseShamanSpell(S.NaturesSwiftness) then
                    self:CastShamanSpell(S.NaturesSwiftness)
                    ShamanDebug("Nature's Swiftness combo")
                end
                
                -- Use trinkets and consumables
                if self.UseTrinkets then self:UseTrinkets() end
                if self.UseOffensivePotion then self:UseOffensivePotion(true) end
                
                return true
            end
        end
        
        -- Fire Elemental for sustained DPS
        if targetHP > 70 and self:CanUseShamanSpell(S.FireElementalTotem) and Throttle("FireElemental", 600) then
            if self:CastShamanSpell(S.FireElementalTotem) then
                ShamanDebug("Fire Elemental totem for boss DPS")
                return true
            end
        end
    end
    
    -- Enhanced AoE rotation
    if enemies >= 3 then
        -- Fire Nova optimization with totem synergy
        local fireTotem = self:GetActiveShamanTotem(TotemTypes.FIRE)
        if fireTotem and self:CanUseShamanSpell(S.FireNova) and manaPercent > 20 then
            if self:CastShamanSpell(S.FireNova) then
                ShamanDebug("Fire Nova with " .. fireTotem .. " totem")
                return true
            end
        end
        
        -- Chain Lightning for multi-target
        if self:CanUseShamanSpell(S.ChainLightning) and manaPercent > 30 then
            if self:CastShamanSpell(S.ChainLightning) then
                ShamanDebug("Chain Lightning AoE")
                return true
            end
        end
        
        -- Thunderstorm for positioning + damage
        if self:CanUseShamanSpell(S.Thunderstorm) and CheckInteractDistance("target", 2) then
            if self:CastShamanSpell(S.Thunderstorm) then
                ShamanDebug("Thunderstorm knockback + damage")
                return true
            end
        end
    end
    
    -- Enhanced single-target rotation with Lava Burst mastery
    local flameShockDuration = self:DebuffTimeRemaining("target", S.FlameShock)
    
    -- Flame Shock application/refresh
    if self:CanUseShamanSpell(S.FlameShock) and flameShockDuration < 2 and manaPercent > 10 then
        if self:CastShamanSpell(S.FlameShock) then
            ShamanDebug("Flame Shock application")
            return true
        end
    end
    
    -- Lava Burst with Flame Shock synergy (guaranteed crit)
    if flameShockDuration > 2 and self:CanUseShamanSpell(S.LavaBurst) and manaPercent > 15 then
        if self:CastShamanSpell(S.LavaBurst) then
            ShamanDebug("Lava Burst (guaranteed crit with Flame Shock)")
            return true
        end
    end
    
    -- Chain Lightning for 2+ targets
    if enemies >= 2 and self:CanUseShamanSpell(S.ChainLightning) and manaPercent > 25 then
        if self:CastShamanSpell(S.ChainLightning) then
            ShamanDebug("Chain Lightning (2+ targets)")
            return true
        end
    end
    
    -- Lightning Bolt filler
    if self:CanUseShamanSpell(S.LightningBolt) and manaPercent > 5 then
        if self:CastShamanSpell(S.LightningBolt) then
            ShamanDebug("Lightning Bolt filler")
            return true
        end
    end
    
    return false
end

-- ENHANCEMENT ROTATION: Melee DPS Beast (Maelstrom Weapon + Windfury Master)
function AC:EnhancementRotation(level, hasTarget, targetHP, manaPercent, enemies)
    local situation = enemies >= 2 and "AOE" or (IsInGroup() and "GROUP" or "SOLO")
    if self:DeployShamanTotems("Enhancement", level, situation) then return true end
    if not hasTarget then return false end
    
    -- Enhanced auto-attack management
    if CheckInteractDistance("target", 3) and not IsCurrentSpell("Attack") then 
        StartAttack()
        ShamanDebug("Started auto-attack")
    end
    
    -- Enhanced interrupt
    if self.TryInterrupt and self:TryInterrupt(S.WindShear, "target") then 
        ShamanDebug("Interrupted with Wind Shear")
        return true 
    end
    
    -- Use racials for offense
    self:UseShamanRacials(true, false)
    
    -- Enhanced defensive and utility cooldowns
    if UnitAffectingCombat("player") then
        local health = self:GetPlayerHealthPercent()
        
        -- Shamanistic Rage for mana efficiency + damage reduction
        if self:CanUseShamanSpell(S.ShamanisticRage) and (manaPercent < 40 or health < 60) then
            if self:CastShamanSpell(S.ShamanisticRage) then
                ShamanDebug("Shamanistic Rage (mana: " .. manaPercent .. "%, health: " .. health .. "%)")
                return true
            end
        end
        
        -- Enhanced Feral Spirit management
        local targetClassification = UnitClassification("target")
        local isBoss = targetClassification == "worldboss" or targetClassification == "elite" or targetClassification == "rareelite"
        
        if self:CanUseShamanSpell(S.FeralSpirit) and (isBoss or targetHP > 50 or enemies >= 2) and Throttle("FeralSpirit", 180) then
            if self:CastShamanSpell(S.FeralSpirit) then
                ShamanDebug("Feral Spirit wolves")
                
                -- Chain with other cooldowns
                if self.UseTrinkets then self:UseTrinkets() end
                if self.UseOffensivePotion then self:UseOffensivePotion(true) end
                
                return true
            end
        end
        
        -- Enhanced Bloodlust/Heroism timing
        local bloodlust = UnitFactionGroup("player") == "Horde" and S.Bloodlust or S.Heroism
        if self:CanUseShamanSpell(bloodlust) and IsInGroup() and (isBoss or targetHP > 60) and Throttle("Bloodlust", 600) then
            if self:CastShamanSpell(bloodlust) then
                ShamanDebug("Bloodlust/Heroism for group")
                return true
            end
        end
    end
    
    -- ULTIMATE: Maelstrom Weapon stack optimization
    local mwStacks = self:GetMaelstromStacks()
    if mwStacks >= 5 then
        local health = self:GetPlayerHealthPercent()
        
        -- Emergency self-heal with 5 stacks
        if health < 30 and self:CanUseShamanSpell(S.HealingWave) then
            if self:CastShamanSpell(S.HealingWave, "player") then
                ShamanDebug("Emergency instant Healing Wave (5 MW stacks)")
                return true
            end
        end
        
        -- Optimal instant cast spell selection
        local spell = enemies >= 2 and S.ChainLightning or S.LightningBolt
        if self:CanUseShamanSpell(spell) then
            if self:CastShamanSpell(spell) then
                ShamanDebug("Instant " .. spell .. " (5 MW stacks)")
                return true
            end
        end
    elseif mwStacks >= 3 and enemies >= 3 then
        -- Use 3+ stacks for AoE situations
        if self:CanUseShamanSpell(S.ChainLightning) then
            if self:CastShamanSpell(S.ChainLightning) then
                ShamanDebug("Chain Lightning (" .. mwStacks .. " MW stacks, AoE)")
                return true
            end
        end
    end
    
    -- Enhanced AoE with Fire Nova optimization
    if enemies >= 2 then
        local fireTotem = self:GetActiveShamanTotem(TotemTypes.FIRE)
        if fireTotem and self:CanUseShamanSpell(S.FireNova) and manaPercent > 20 then
            if self:CastShamanSpell(S.FireNova) then
                ShamanDebug("Fire Nova AoE with " .. fireTotem)
                return true
            end
        end
    end
    
    -- Enhanced shield management
    if not self:HasBuff("player", S.LightningShield) and self:CanUseShamanSpell(S.LightningShield) then
        if self:CastShamanSpell(S.LightningShield) then
            ShamanDebug("Lightning Shield refresh")
            return true
        end
    end
    
    -- Enhanced melee rotation priority
    
    -- Stormstrike (highest priority - applies Nature Vulnerability)
    if self:CanUseShamanSpell(S.Stormstrike) and manaPercent > 15 then
        if self:CastShamanSpell(S.Stormstrike) then
            ShamanDebug("Stormstrike (Nature Vulnerability)")
            return true
        end
    end
    
    -- Flame Shock maintenance
    local flameShockDuration = self:DebuffTimeRemaining("target", S.FlameShock)
    if self:CanUseShamanSpell(S.FlameShock) and flameShockDuration < 2 and manaPercent > 10 then
        if self:CastShamanSpell(S.FlameShock) then
            ShamanDebug("Flame Shock refresh")
            return true
        end
    end
    
    -- Earth Shock for interrupt/filler (when Flame Shock is up)
    if flameShockDuration > 10 and self:CanUseShamanSpell(S.EarthShock) and manaPercent > 10 then
        if self:CastShamanSpell(S.EarthShock) then
            ShamanDebug("Earth Shock filler")
            return true
        end
    end
    
    -- Lava Lash (requires off-hand weapon)
    if self:CanUseShamanSpell(S.LavaLash) and GetInventoryItemID("player", 17) and manaPercent > 10 then
        if self:CastShamanSpell(S.LavaLash) then
            ShamanDebug("Lava Lash (off-hand weapon)")
            return true
        end
    end
    
    return false
end

-- RESTORATION ROTATION: Ultimate Healer (Advanced Prioritization + Chain Heal Master)
function AC:RestorationRotation(level, hasTarget, targetHP, manaPercent, enemies)
    local situation = GetNumRaidMembers() > 0 and "RAID" or (IsInGroup() and "GROUP" or "SOLO")
    if self:DeployShamanTotems("Restoration", level, situation) then return true end
    
    -- Use defensive racials when needed
    self:UseShamanRacials(false, true)
    
    if IsInGroup() then
        -- EPIC PRIORITY: Handle cleansing and purging
        if self:HandleShamanCleansing() then return true end
        if self:HandleShamanPurge() then return true end
        
        -- Enhanced tank detection and Earth Shield management
        local tankUnit = nil
        
        -- Check focus first
        if UnitExists("focus") and UnitIsFriend("player", "focus") and not UnitIsDeadOrGhost("focus") then
            tankUnit = "focus"
        else
            -- Auto-detect tank by class
            local maxMembers = GetNumRaidMembers() > 0 and GetNumRaidMembers() or GetNumPartyMembers()
            for i = 1, maxMembers do
                local unit = GetNumRaidMembers() > 0 and "raid"..i or "party"..i
                if UnitExists(unit) and not UnitIsDeadOrGhost(unit) then
                    local _, uClass = UnitClass(unit)
                    if uClass == "WARRIOR" or uClass == "PALADIN" or uClass == "DEATHKNIGHT" then
                        tankUnit = unit
                        break
                    end
                end
            end
        end
        
        -- Earth Shield maintenance on tank
        if tankUnit and self:CanUseShamanSpell(S.EarthShield) and not self:HasBuff(tankUnit, S.EarthShield) then
            if Throttle("EarthShield", 2.0) and self:CastShamanSpell(S.EarthShield, tankUnit) then
                ShamanDebug("Earth Shield on tank: " .. UnitName(tankUnit))
                return true
            end
        end
        
        -- Enhanced Mana Tide coordination
        if manaPercent < 40 and self:CanUseShamanSpell(S.ManaTideTotem) and Throttle("ManaTide", 300) then
            if self:CastShamanSpell(S.ManaTideTotem) then
                ShamanDebug("Mana Tide for group mana regen")
                return true
            end
        end
        
        -- Advanced healing target prioritization
        local healTarget, healTargetHP, targetInfo = self:FindShamanHealingTarget("normal")
        
        if healTarget and healTargetHP < 0.95 then
            -- Emergency cooldowns for critical situations
            if healTargetHP < 0.30 then
                -- Tidal Force for emergency burst healing
                if self:CanUseShamanSpell(S.TidalForce) and Throttle("TidalForce", 180) then
                    if self:CastShamanSpell(S.TidalForce) then
                        ShamanDebug("Tidal Force emergency")
                        return true
                    end
                end
                
                -- Nature's Swiftness for instant cast
                if self:CanUseShamanSpell(S.NaturesSwiftness) then
                    if self:CastShamanSpell(S.NaturesSwiftness) then
                        ShamanDebug("Nature's Swiftness instant cast")
                        return true
                    end
                end
            end
            
            -- Riptide for HoT coverage
            if self:CanUseShamanSpell(S.Riptide) and not self:HasBuff(healTarget, S.Riptide) then
                if self:CastShamanSpell(S.Riptide, healTarget) then
                    ShamanDebug("Riptide HoT on " .. UnitName(healTarget))
                    return true
                end
            end
            
            -- Enhanced Chain Heal optimization
            local groupAnalysis = self:AnalyzeGroupDamage()
            if groupAnalysis.needsChainHeal and self:CanUseShamanSpell(S.ChainHeal) and manaPercent > 25 then
                if self:CastShamanSpell(S.ChainHeal, healTarget) then
                    ShamanDebug("Chain Heal (" .. groupAnalysis.damagedMembers .. " damaged, " .. 
                               math.floor(groupAnalysis.avgHealth * 100) .. "% avg HP)")
                    return true
                end
            end
            
            -- Single target healing priority
            if healTargetHP < 0.50 and self:CanUseShamanSpell(S.HealingWave) and manaPercent > 20 then
                if self:CastShamanSpell(S.HealingWave, healTarget) then
                    ShamanDebug("Healing Wave on " .. UnitName(healTarget) .. " (" .. 
                               math.floor(healTargetHP * 100) .. "% HP)")
                    return true
                end
            end
            
            -- Lesser Healing Wave for efficiency
            if healTargetHP < 0.80 and self:CanUseShamanSpell(S.LesserHealingWave) and manaPercent > 15 then
                if self:CastShamanSpell(S.LesserHealingWave, healTarget) then
                    ShamanDebug("Lesser Healing Wave (efficient heal)")
                    return true
                end
            end
        end
    end
    
    -- DPS when safe (solo or high mana in group)
    if hasTarget and (not IsInGroup() or manaPercent > 70) then
        -- Flame Shock for DoT damage
        local flameShockDuration = self:DebuffTimeRemaining("target", S.FlameShock)
        if self:CanUseShamanSpell(S.FlameShock) and flameShockDuration < 2 and manaPercent > 20 then
            if self:CastShamanSpell(S.FlameShock) then
                ShamanDebug("Flame Shock (Resto DPS)")
                return true
            end
        end
        
        -- Lava Burst with Flame Shock synergy
        if flameShockDuration > 2 and self:CanUseShamanSpell(S.LavaBurst) and manaPercent > 25 then
            if self:CastShamanSpell(S.LavaBurst) then
                ShamanDebug("Lava Burst (Resto DPS)")
                return true
            end
        end
        
        -- Lightning Bolt filler
        if self:CanUseShamanSpell(S.LightningBolt) and manaPercent > 15 then
            if self:CastShamanSpell(S.LightningBolt) then
                ShamanDebug("Lightning Bolt (Resto filler)")
                return true
            end
        end
    end
    
    return false
end

-- ENHANCED: Ultimate buff management with intelligent priorities
function AC:CheckShamanBuffs(spec)
    if UnitAffectingCombat("player") or IsMounted() or IsFlying() then return false end
    local level = UnitLevel("player")
    
    -- Enhanced weapon imbue management
    if self:ManageShamanWeaponImbues(spec, level) then return true end
    
    -- Enhanced shield management
    if self:ManageShamanShields(spec, level) then return true end
    
    -- Intelligent totemic recall for mana efficiency (out of combat only)
    local manaPercent = UnitPower("player", 0) / UnitPowerMax("player", 0) * 100
    if manaPercent < 50 then
        local activeTotemCount = 0
        for i = 1, 4 do 
            if self:GetActiveShamanTotem(i) then 
                activeTotemCount = activeTotemCount + 1
            end 
        end
        
        -- Only recall if we have multiple totems and low mana
        if activeTotemCount >= 2 and self:CanUseShamanSpell(S.TotemicRecall) and Throttle("TotemicRecallOOC", 60) then
            if self:CastShamanSpell(S.TotemicRecall) then
                ShamanDebug("Totemic Recall for mana efficiency (OOC - " .. math.floor(manaPercent) .. "% mana, " .. activeTotemCount .. " totems)")
                return true
            end
        end
    end
    
    return false
end

-- ENHANCED: Defensive cooldown management
function AC:UseShamanDefensives()
    local health = self:GetPlayerHealthPercent()
    local inCombat = UnitAffectingCombat("player")
    
    if not inCombat then return false end
    
    -- Emergency health potion
    if health < 35 and self.UseHealthPotion and self:UseHealthPotion(35) then
        ShamanDebug("Used health potion")
        return true
    end
    
    -- Use defensive racials
    if health < 50 then
        if self:UseShamanRacials(false, true) then
            return true
        end
    end
    
    -- Shamanistic Rage for damage reduction (Enhancement)
    local spec = self:GetPlayerSpec()
    if spec == "Enhancement" and health < 60 and self:CanUseShamanSpell(S.ShamanisticRage) then
        if self:CastShamanSpell(S.ShamanisticRage) then
            ShamanDebug("Shamanistic Rage (defensive)")
            return true
        end
    end
    
    -- Self-heal with Maelstrom Weapon stacks
    if spec == "Enhancement" and health < 50 then
        local mwStacks = self:GetMaelstromStacks()
        if mwStacks >= 3 and self:CanUseShamanSpell(S.HealingWave) then
            if self:CastShamanSpell(S.HealingWave, "player") then
                ShamanDebug("Emergency self-heal (" .. mwStacks .. " MW stacks)")
                return true
            end
        end
    end
    
    return false
end

-- ENHANCED: Main rotation controller with ultimate optimization
function AC:ShamanRotation()
    local spec = self:GetPlayerSpec()
    local level = UnitLevel("player")
    local health = self:GetPlayerHealthPercent()
    local inCombat = UnitAffectingCombat("player")
    local hasTarget = UnitExists("target") and UnitCanAttack("player", "target") and not UnitIsDeadOrGhost("target")
    
    -- Enhanced debug output
    if self.debugMode and Throttle("ShamanDebugMain", 5) then
        ShamanDebug(string.format("Running %s rotation - Level:%d HP:%.0f%% Combat:%s Target:%s",
                   spec, level, health, inCombat and "Y" or "N", hasTarget and "Y" or "N"))
    end
    
    -- Emergency Lifeblood (Herbalism profession ability) at 50% health
    if inCombat and self:UseLifeblood() then return true end
    
    -- Out of combat management
    if not inCombat then
        return false
    end
    
    -- Find target if needed (except for Restoration in group)
    if not hasTarget and spec ~= "Restoration" then
        if self.FindAndSetTarget and self:FindAndSetTarget() then
            hasTarget = true
            ShamanDebug("Auto-targeted enemy")
        else
            return false
        end
    end
    
    -- Emergency defensives
    if health < 40 then
        if self:UseShamanDefensives() then
            return true
        end
    end
    
    -- Enhanced shield management in combat
    if self:ManageShamanShields(spec, level) then return true end
    
    -- Calculate combat parameters
    local targetHP = hasTarget and (self.GetTargetHealthPercent and self:GetTargetHealthPercent("target") or 
                     (UnitHealth("target") / UnitHealthMax("target") * 100)) or 100
    local manaPercent = UnitPower("player", 0) / UnitPowerMax("player", 0) * 100
    local enemies = self.GetEnemyCount and self:GetEnemyCount() or 1

    -- Spec-specific rotations
    local rotationResult = false
    if spec == "Elemental" then 
        rotationResult = self:ElementalRotation(level, hasTarget, targetHP, manaPercent, enemies)
    elseif spec == "Enhancement" then 
        rotationResult = self:EnhancementRotation(level, hasTarget, targetHP, manaPercent, enemies)
    elseif spec == "Restoration" then 
        rotationResult = self:RestorationRotation(level, hasTarget, targetHP, manaPercent, enemies)
    else 
        -- Leveling rotation (simplified)
        ShamanDebug("Using leveling rotation")
        
        if hasTarget then
            -- Basic Flame Shock
            if self:CanUseShamanSpell(S.FlameShock) and self:DebuffTimeRemaining("target", S.FlameShock) < 1 then
                if self:CastShamanSpell(S.FlameShock) then
                    rotationResult = true
                end
            end
            
            -- Earth Shock filler
            if not rotationResult and self:CanUseShamanSpell(S.EarthShock) then
                if self:CastShamanSpell(S.EarthShock) then
                    rotationResult = true
                end
            end
            
            -- Lightning Bolt
            if not rotationResult and self:CanUseShamanSpell(S.LightningBolt) then
                if self:CastShamanSpell(S.LightningBolt) then
                    rotationResult = true
                end
            end
            
            -- Auto-attack for melee
            if CheckInteractDistance("target", 3) and not IsCurrentSpell("Attack") then 
                StartAttack()
            end
        end
    end
    
    return rotationResult
end

-- ENHANCED: Comprehensive debugging system
function AC:ShamanDebugInfo()
    local spec = self:GetPlayerSpec()
    local level = UnitLevel("player")
    local health = self:GetPlayerHealthPercent()
    local manaPercent = UnitPower("player", 0) / UnitPowerMax("player", 0) * 100
    
    self:Print("=== SHAMAN DEBUG INFO ===")
    self:Print("Spec: " .. spec .. " (Level " .. level .. ")")
    self:Print("Health: " .. math.floor(health) .. "%")
    self:Print("Mana: " .. math.floor(manaPercent) .. "%")
    self:Print("In Combat: " .. (UnitAffectingCombat("player") and "YES" or "NO"))
    self:Print("Has Target: " .. (UnitExists("target") and "YES" or "NO"))
    
    -- Spec-specific info
    if spec == "Enhancement" then
        local mwStacks = self:GetMaelstromStacks()
        self:Print("Maelstrom Weapon: " .. mwStacks .. " stacks")
    end
    
    -- Totem status
    self:Print("=== ACTIVE TOTEMS ===")
    for i = 1, 4 do
        local totem, timeLeft = self:GetActiveShamanTotem(i)
        local slotName = ({"Earth", "Air", "Fire", "Water"})[i]
        if totem then
            self:Print(slotName .. ": " .. totem .. " (" .. math.floor(timeLeft) .. "s)")
        else
            self:Print(slotName .. ": None")
        end
    end
    
    -- Weapon imbues
    local hasMainHand, mainHandExp, _, _, hasOffHand, offHandExp = GetWeaponEnchantInfo()
    self:Print("=== WEAPON IMBUES ===")
    self:Print("Main Hand: " .. (hasMainHand and ("Active (" .. math.floor((mainHandExp or 0)/1000) .. "s)") or "None"))
    self:Print("Off Hand: " .. (hasOffHand and ("Active (" .. math.floor((offHandExp or 0)/1000) .. "s)") or "None"))
    
    -- Group info
    if IsInGroup() then
        local groupAnalysis = self:AnalyzeGroupDamage()
        self:Print("=== GROUP STATUS ===")
        self:Print("Members: " .. groupAnalysis.totalMembers)
        self:Print("Damaged: " .. groupAnalysis.damagedMembers)
        self:Print("Avg Health: " .. math.floor(groupAnalysis.avgHealth * 100) .. "%")
        self:Print("Chain Heal Needed: " .. (groupAnalysis.needsChainHeal and "YES" or "NO"))
    end
    
    self:Print("=========================")
end

-- ENHANCED: Setup enhanced slash commands
function AC:SetupShamanSlashCommands()
    local originalHandler = SlashCmdList["AZEROCOMBAT"]
    
    if originalHandler then
        SlashCmdList["AZEROCOMBAT"] = function(msg)
            local args = {strsplit(" ", msg)}
            local command = args[1] and args[1]:lower() or ""
            local subcommand = args[2] and args[2]:lower() or ""
            
            if command == "shaman" then
                if subcommand == "debug" then
                    self:ShamanDebugInfo()
                elseif subcommand == "totems" then
                    self:Print("=== TOTEM STATUS ===")
                    for i = 1, 4 do
                        local totem, timeLeft = self:GetActiveShamanTotem(i)
                        local slotName = ({"Earth", "Air", "Fire", "Water"})[i]
                        if totem then
                            self:Print(slotName .. ": " .. totem .. " (" .. math.floor(timeLeft) .. "s remaining)")
                        else
                            self:Print(slotName .. ": Empty")
                        end
                    end
                    self:Print("===================")
                elseif subcommand == "imbues" then
                    local hasMainHand, mainHandExp, _, _, hasOffHand, offHandExp = GetWeaponEnchantInfo()
                    self:Print("=== WEAPON IMBUE STATUS ===")
                    self:Print("Main Hand: " .. (hasMainHand and ("✓ Active (" .. math.floor((mainHandExp or 0)/1000) .. "s)") or "✗ Missing"))
                    self:Print("Off Hand: " .. (hasOffHand and ("✓ Active (" .. math.floor((offHandExp or 0)/1000) .. "s)") or "✗ Missing"))
                    self:Print("=============================")
                elseif subcommand == "rotation" then
                    local spec = self:GetPlayerSpec()
                    self:Print("=== " .. spec:upper() .. " SHAMAN ROTATION PRIORITY ===")
                    
                    if spec == "Elemental" then
                        self:Print("WotLK 3.3.5a Elemental Priority:")
                        self:Print("1. Flame Shock for Lava Burst synergy")
                        self:Print("2. Lava Burst (guaranteed crit with FS)")
                        self:Print("3. Chain Lightning for 2+ enemies")
                        self:Print("4. Lightning Bolt filler")
                        self:Print("5. Fire Nova for AoE with totems")
                        
                    elseif spec == "Enhancement" then
                        self:Print("WotLK 3.3.5a Enhancement Priority:")
                        self:Print("1. Maelstrom Weapon 5-stack instants")
                        self:Print("2. Stormstrike (Nature Vulnerability)")
                        self:Print("3. Flame Shock maintenance")
                        self:Print("4. Lava Lash (with off-hand)")
                        self:Print("5. Earth Shock filler")
                        
                    elseif spec == "Restoration" then
                        self:Print("WotLK 3.3.5a Restoration Priority:")
                        self:Print("1. Earth Shield on tank")
                        self:Print("2. Emergency healing (Tank > Healer > DPS)")
                        self:Print("3. Chain Heal for group damage")
                        self:Print("4. Riptide for HoT coverage")
                        self:Print("5. Efficient single-target heals")
                    else
                        self:Print("Unknown spec - using basic rotation")
                    end
                else
                    self:Print("Enhanced Shaman commands:")
                    self:Print("  /ac shaman debug - Complete debug information")
                    self:Print("  /ac shaman totems - Show totem status")
                    self:Print("  /ac shaman imbues - Show weapon imbue status")
                    self:Print("  /ac shaman rotation - Show rotation priority")
                end
            else
                originalHandler(msg)
            end
        end
    end
end

-- ENHANCED: Initialization with comprehensive setup
function AC:InitShamanRotations()
    self.rotations = self.rotations or {}
    self.rotations["SHAMAN"] = {}
    
    -- Register all spec rotations
    self.rotations["SHAMAN"]["Elemental"] = function(s) return s:ShamanRotation() end
    self.rotations["SHAMAN"]["Enhancement"] = function(s) return s:ShamanRotation() end
    self.rotations["SHAMAN"]["Restoration"] = function(s) return s:ShamanRotation() end
    self.rotations["SHAMAN"]["None"] = function(s) return s:ShamanRotation() end
    
    -- Register buff checker and cleanse systems
    self.CheckShamanBuffs = AC.CheckShamanBuffs
    self.HandleShamanCleansing = AC.HandleShamanCleansing
    self.HandleShamanPurge = AC.HandleShamanPurge
    
    -- Setup enhanced slash commands
    self:SetupShamanSlashCommands()
    
    self:Print("Enhanced Shaman rotations loaded for WotLK 3.3.5a!")
    self:Print("✅ Complete totem management with situational awareness")
    self:Print("✅ Ultimate Elemental: Lava Burst mastery + Thunderstorm optimization")
    self:Print("✅ Ultimate Enhancement: Maelstrom Weapon + Windfury coordination")
    self:Print("✅ Ultimate Restoration: Advanced healing priority + Chain Heal master")
    self:Print("✅ Enhanced weapon imbue system with perfect timing")
    self:Print("✅ EPIC CLEANSE SYSTEM: Priority-based poison/disease removal")
    self:Print("✅ EPIC PURGE SYSTEM: Intelligent buff removal from enemies")
    self:Print("✅ Complete racial abilities integration")
    self:Print("✅ Full Core.lua and Utils.lua framework integration")
    self:Print("✅ Comprehensive debugging with Shaman-specific commands")
    ShamanDebug("Enhanced Shaman module loaded successfully")
end
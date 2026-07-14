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
    CureToxins = "Cure Toxins",
    
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
    ManaTideTotem = "Mana Tide Totem",
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
    TidalWaves = "Tidal Waves",
    
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

-- GetTotemInfo uses Fire=1, Earth=2, Water=3, Air=4 in the 3.3.5 client.
-- Keep the symbolic constants here so every set and status check uses the API order.
local TotemTypes = {
    FIRE = FIRE_TOTEM_SLOT or 1,
    EARTH = EARTH_TOTEM_SLOT or 2,
    WATER = WATER_TOTEM_SLOT or 3,
    AIR = AIR_TOTEM_SLOT or 4
}
local TotemSlotNames = {
    [TotemTypes.FIRE] = "Fire",
    [TotemTypes.EARTH] = "Earth",
    [TotemTypes.WATER] = "Water",
    [TotemTypes.AIR] = "Air"
}

-- Totem definitions and sets
AC.TotemDefinitions = {
    [S.StrengthOfEarthTotem] = TotemTypes.EARTH, [S.StoneskinTotem] = TotemTypes.EARTH, [S.EarthbindTotem] = TotemTypes.EARTH, [S.TremorTotem] = TotemTypes.EARTH, [S.StoneclawTotem] = TotemTypes.EARTH, [S.EarthElementalTotem] = TotemTypes.EARTH, [S.GraceOfAirTotem] = TotemTypes.AIR, [S.WrathOfAirTotem] = TotemTypes.AIR, [S.WindfuryTotem] = TotemTypes.AIR, [S.NatureResistanceTotem] = TotemTypes.AIR, [S.GroundingTotem] = TotemTypes.AIR, [S.SentryTotem] = TotemTypes.AIR, [S.WindwallTotem] = TotemTypes.AIR, [S.SearingTotem] = TotemTypes.FIRE, [S.MagmaTotem] = TotemTypes.FIRE, [S.FlametongueTotem] = TotemTypes.FIRE, [S.FrostResistanceTotem] = TotemTypes.FIRE, [S.TotemOfWrath] = TotemTypes.FIRE, [S.FireResistanceTotem] = TotemTypes.FIRE, [S.FireElementalTotem] = TotemTypes.FIRE, [S.HealingStreamTotem] = TotemTypes.WATER, [S.ManaSpringTotem] = TotemTypes.WATER, [S.DiseaseCleansingTotem] = TotemTypes.WATER, [S.PoisonCleansingTotem] = TotemTypes.WATER, [S.ManaTideTotem] = TotemTypes.WATER
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
    ENHANCEMENT_GROUP = { [TotemTypes.EARTH] = S.StrengthOfEarthTotem, [TotemTypes.AIR] = S.WindfuryTotem, [TotemTypes.FIRE] = S.MagmaTotem, [TotemTypes.WATER] = S.ManaSpringTotem },
    ENHANCEMENT_AOE = { [TotemTypes.EARTH] = S.StrengthOfEarthTotem, [TotemTypes.AIR] = S.WindfuryTotem, [TotemTypes.FIRE] = S.MagmaTotem, [TotemTypes.WATER] = S.ManaSpringTotem },
    ENHANCEMENT_BOSS = { [TotemTypes.EARTH] = S.StrengthOfEarthTotem, [TotemTypes.AIR] = S.WindfuryTotem, [TotemTypes.FIRE] = S.MagmaTotem, [TotemTypes.WATER] = S.ManaSpringTotem },
    
    -- RESTORATION: Ultimate Healer Sets
    RESTORATION_SOLO = { [TotemTypes.EARTH] = S.StoneskinTotem, [TotemTypes.AIR] = S.WrathOfAirTotem, [TotemTypes.FIRE] = S.FlametongueTotem, [TotemTypes.WATER] = S.ManaSpringTotem }, 
    RESTORATION_GROUP = { [TotemTypes.EARTH] = S.StoneskinTotem, [TotemTypes.AIR] = S.WrathOfAirTotem, [TotemTypes.FIRE] = S.FlametongueTotem, [TotemTypes.WATER] = S.HealingStreamTotem },
    RESTORATION_RAID = { [TotemTypes.EARTH] = S.StrengthOfEarthTotem, [TotemTypes.AIR] = S.WrathOfAirTotem, [TotemTypes.FIRE] = S.FlametongueTotem, [TotemTypes.WATER] = S.ManaSpringTotem },
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
local ShamanSelfOnlySpells
function AC:CastShamanSpell(spellName, unit)
    unit = unit or "target"
    if not spellName then return false end

    ShamanSelfOnlySpells = ShamanSelfOnlySpells or {
        [S.LightningShield] = true, [S.WaterShield] = true, 
        [S.WindfuryWeapon] = true, [S.FlametongueWeapon] = true, 
        [S.FrostbrandWeapon] = true, [S.RockbiterWeapon] = true, 
        [S.EarthlivingWeapon] = true, [S.GhostWolf] = true, 
        [S.ElementalMastery] = true, [S.NaturesSwiftness] = true,
        [S.ShamanisticRage] = true, [S.TidalForce] = true,
        [S.FeralSpirit] = true, [S.Bloodlust] = true, [S.Heroism] = true,
        [S.Thunderstorm] = true, [S.FireNova] = true,
        [S.StrengthOfEarthTotem] = true, [S.StoneskinTotem] = true,
        [S.EarthbindTotem] = true, [S.TremorTotem] = true,
        [S.StoneclawTotem] = true, [S.EarthElementalTotem] = true,
        [S.GraceOfAirTotem] = true, [S.WrathOfAirTotem] = true,
        [S.WindfuryTotem] = true, [S.GroundingTotem] = true,
        [S.NatureResistanceTotem] = true, [S.SentryTotem] = true,
        [S.WindwallTotem] = true, [S.SearingTotem] = true,
        [S.MagmaTotem] = true, [S.FlametongueTotem] = true,
        [S.FrostResistanceTotem] = true, [S.TotemOfWrath] = true,
        [S.FireResistanceTotem] = true, [S.FireElementalTotem] = true,
        [S.HealingStreamTotem] = true, [S.ManaSpringTotem] = true,
        [S.DiseaseCleansingTotem] = true, [S.PoisonCleansingTotem] = true,
        [S.ManaTideTotem] = true, [S.CallOfTheElements] = true,
        [S.CallOfTheAncestors] = true, [S.CallOfTheSpirits] = true,
        [S.TotemicRecall] = true
    }
    if ShamanSelfOnlySpells[spellName] then unit = "player" end

    if self:IsUsableSpell(spellName) and (unit == "player" or UnitExists(unit)) then
        if IsCurrentSpell(spellName) or UnitCastingInfo("player") then return false end
        if self:GetSpellCooldown(spellName) > 0.1 then return false end

        if self:CastSpell(spellName, unit) then
            ShamanDebug("Cast SUCCESS: " .. spellName .. (unit ~= "target" and (" on " .. unit) or ""))
            return true
        end
        ShamanDebug("Cast FAILED: " .. spellName)
    end
    return false
end

-- ENHANCED: Spell availability checking
function AC:CanUseShamanSpell(spellName)
    if not spellName then return false end
    -- The spellbook is the source of truth. Talent spells can be learned at
    -- different levels depending on the player's build, so a static level gate
    -- must never suppress an ability the character actually knows.
    return self:KnowsSpell(spellName) and self:IsUsableSpell(spellName)
end

function AC:IsShamanSpellReady(spellName)
    return self:CanUseShamanSpell(spellName) and self:GetSpellCooldown(spellName) <= 0.1
end

-- ENHANCED: Check for Maelstrom Weapon stacks
function AC:GetMaelstromStacks()
    local _, _, _, stacks = UnitBuff("player", S.MaelstromWeapon)
    return stacks or 0
end

function AC:GetShamanGroupUnits()
    local units = {}
    local raidCount = GetNumRaidMembers()
    if raidCount > 0 then
        for i = 1, raidCount do table.insert(units, "raid" .. i) end
    else
        table.insert(units, "player")
        for i = 1, GetNumPartyMembers() do table.insert(units, "party" .. i) end
    end
    return units
end

function AC:IsShamanFriendlyUnitReachable(unit)
    if not UnitExists(unit) or UnitIsDeadOrGhost(unit) or not UnitIsConnected(unit) or
       not UnitIsFriend("player", unit) then
        return false
    end
    if UnitIsVisible and not UnitIsVisible(unit) then return false end

    local rangeSpell = self:KnowsSpell(S.HealingWave) and S.HealingWave or
                       (self:KnowsSpell(S.LesserHealingWave) and S.LesserHealingWave)
    if rangeSpell and IsSpellInRange then
        local ok, inRange = pcall(IsSpellInRange, rangeSpell, unit)
        if ok and inRange == 0 then return false end
    end
    return true
end

function AC:IsShamanTankCandidate(unit)
    if not self:IsShamanFriendlyUnitReachable(unit) then return false end
    local tankAuras = {"Defensive Stance", "Righteous Fury", "Bear Form", "Dire Bear Form", "Frost Presence"}
    for _, aura in ipairs(tankAuras) do
        if self:HasBuff(unit, aura) then return true end
    end

    local enemy = unit .. "target"
    if UnitExists(enemy) and UnitCanAttack("player", enemy) then
        local enemyTarget = enemy .. "target"
        if UnitExists(enemyTarget) and UnitIsUnit(enemyTarget, unit) then return true end
        if UnitDetailedThreatSituation then
            local ok, status = pcall(UnitDetailedThreatSituation, unit, enemy)
            if ok and status and status >= 2 then return true end
        end
    end
    return false
end

function AC:FindShamanTankUnit()
    if self:IsShamanFriendlyUnitReachable("focus") then
        -- A friendly focus is an explicit player choice and is therefore a
        -- better Earth Shield anchor than any class-based guess.
        return "focus"
    end
    for _, unit in ipairs(self:GetShamanGroupUnits()) do
        if self:IsShamanTankCandidate(unit) then
            return unit
        end
    end
    return nil
end

-- Health deficit is the primary healing rule. Tank status only breaks close
-- ties; being a warrior, paladin, or death knight is not proof of tanking.
function AC:FindShamanHealingTarget(urgencyLevel)
    urgencyLevel = urgencyLevel or "normal"
    local targets = {}

    for _, unit in ipairs(self:GetShamanGroupUnits()) do
        if self:IsShamanFriendlyUnitReachable(unit) then
            local maxHealth = UnitHealthMax(unit)
            if maxHealth and maxHealth > 0 then
                local hp = UnitHealth(unit) / maxHealth
                local isTank = self:IsShamanTankCandidate(unit)
                local deficit = 1 - hp
                local priority = deficit * 1000 + (isTank and 35 or 0)
                if hp < 0.30 then priority = priority + 250 end
                table.insert(targets, {
                    unit = unit,
                    health = hp,
                    name = UnitName(unit) or unit,
                    isTank = isTank,
                    role = isTank and "tank" or (UnitIsUnit(unit, "player") and "self" or "ally"),
                    priority = priority
                })
            end
        end
    end

    table.sort(targets, function(a, b) return a.priority > b.priority end)
    local target = targets[1]
    if not target then return nil, 1.0, nil end
    if urgencyLevel == "emergency" and target.health >= 0.35 then return nil, 1.0, nil end

    local healThreshold = target.isTank and 0.93 or 0.90
    if target.health >= healThreshold then return nil, target.health, target end
    return target.unit, target.health, target
end

-- ENHANCED: Totem status with better tracking
function AC:GetActiveShamanTotem(totemSlot)
    local success, _, name, startTime, duration = pcall(GetTotemInfo, totemSlot)
    if not success or type(name) ~= "string" or name == "" then return nil, 0 end
    if type(duration) ~= "number" or duration <= 0 then return nil, 0 end
    if type(startTime) ~= "number" then return name, 999 end
    local timeLeft = (startTime + duration) - GetTime()
    return name, math.max(0, timeLeft)
end

-- ENHANCED: Group damage assessment for Chain Heal optimization
function AC:AnalyzeGroupDamage()
    local analysis = {
        totalMembers = 0,
        damagedMembers = 0,
        avgHealth = 0,
        needsChainHeal = false,
        chainHealTargets = {}
    }

    local totalHealth = 0
    for _, unit in ipairs(self:GetShamanGroupUnits()) do
        if self:IsShamanFriendlyUnitReachable(unit) then
            local maxHealth = UnitHealthMax(unit)
            if maxHealth and maxHealth > 0 then
                local hp = UnitHealth(unit) / maxHealth
                analysis.totalMembers = analysis.totalMembers + 1
                totalHealth = totalHealth + hp
                if hp < 0.85 then
                    analysis.damagedMembers = analysis.damagedMembers + 1
                    table.insert(analysis.chainHealTargets, {
                        unit = unit,
                        health = hp,
                        name = UnitName(unit) or unit
                    })
                end
            end
        end
    end

    table.sort(analysis.chainHealTargets, function(a, b) return a.health < b.health end)
    analysis.avgHealth = analysis.totalMembers > 0 and totalHealth / analysis.totalMembers or 1
    analysis.needsChainHeal = analysis.damagedMembers >= 3 or
                             (analysis.damagedMembers >= 2 and analysis.avgHealth < 0.7)
    
    return analysis
end

function AC:HandleShamanCleansing()
    local _, playerClass = UnitClass("player")
    if playerClass ~= "SHAMAN" then return false end

    local cleanseSpell = self:KnowsSpell(S.CleanseSpirit) and S.CleanseSpirit or
                         (self:KnowsSpell(S.CureToxins) and S.CureToxins)
    if not cleanseSpell or not self:IsShamanSpellReady(cleanseSpell) then return false end

    for _, unit in ipairs(self:GetShamanGroupUnits()) do
        if self:IsShamanFriendlyUnitReachable(unit) then
            for index = 1, 40 do
                local name, _, _, debuffType = UnitDebuff(unit, index)
                if not name then break end
                local canRemove = debuffType == "Poison" or debuffType == "Disease" or
                                  (cleanseSpell == S.CleanseSpirit and debuffType == "Curse")
                if canRemove then
                    if self:CastShamanSpell(cleanseSpell, unit) then
                        ShamanDebug("Cleansed " .. (UnitName(unit) or unit) .. ": " .. name)
                        return true
                    end
                    break
                end
            end
        end
    end
    return false
end

function AC:HandleShamanPurge()
    local _, playerClass = UnitClass("player")
    if playerClass ~= "SHAMAN" or not UnitExists("target") or
       not UnitCanAttack("player", "target") then
        return false
    end
    if not self:CanUseShamanSpell(S.Purge) then return false end

    for index = 1, 40 do
        local name, _, _, _, _, _, _, isStealable = UnitBuff("target", index)
        if not name then break end
        if isStealable and self:CastShamanSpell(S.Purge, "target") then
            ShamanDebug("Purged " .. name)
            return true
        end
    end
    return false
end

function AC:IsShamanBossTarget(unit)
    unit = unit or "target"
    if not UnitExists(unit) then return false end
    local classification = UnitClassification(unit)
    local level = UnitLevel(unit)
    return classification == "worldboss" or level == -1
end

function AC:GetShamanGroupManaPressure()
    local lowManaUsers, manaUsers = 0, 0
    for _, unit in ipairs(self:GetShamanGroupUnits()) do
        if UnitExists(unit) and not UnitIsDeadOrGhost(unit) and UnitPowerMax(unit, 0) > 0 then
            manaUsers = manaUsers + 1
            if UnitPower(unit, 0) / UnitPowerMax(unit, 0) < 0.45 then
                lowManaUsers = lowManaUsers + 1
            end
        end
    end
    return lowManaUsers, manaUsers
end

-- ENHANCED: Racial abilities usage
function AC:UseShamanRacials(offensive, defensive)
    if not Throttle("ShamanRacials", 3) then return false end
    
    local _, race = UnitRace("player")
    race = string.upper(race)
    local health = self:GetPlayerHealthPercent()
    local inCombat = UnitAffectingCombat("player")

    local function castRacial(spellName, message)
        if self:CastShamanSpell(spellName, "player") then
            ShamanDebug(message)
            return true
        end
        return false
    end
    
    -- Offensive racials
    if offensive and inCombat then
        if race == "ORC" and castRacial(S.BloodFury, "Racial: Blood Fury") then return true end
        if race == "TROLL" and castRacial(S.Berserking, "Racial: Berserking") then return true end
        if race == "BLOODELF" and self:IsUsableSpell(S.ArcaneTorrent) then
            local mana = UnitPower("player", 0) / UnitPowerMax("player", 0) * 100
            if mana < 80 then
                if castRacial(S.ArcaneTorrent, "Racial: Arcane Torrent") then return true end
            end
        end
    end
    
    -- Defensive racials
    if defensive or health < 50 then
        if race == "UNDEAD" and castRacial(S.WillOfTheForsaken, "Racial: Will of the Forsaken") then return true end
        if race == "DWARF" and castRacial(S.Stoneform, "Racial: Stoneform") then return true end
        if race == "TAUREN" and castRacial(S.WarStomp, "Racial: War Stomp") then return true end
    end
    
    return false
end

local function ShamanTotemNameMatches(activeName, spellName)
    return activeName and spellName and
           (activeName == spellName or string.find(activeName, spellName, 1, true) == 1)
end

function AC:DeployShamanTotems(spec, level, situation)
    if not Throttle("TotemDeploy", 1.0) then return false end

    if self:IsShamanBossTarget("target") and situation ~= "AOE" then situation = "BOSS" end
    local setKey = spec:upper() .. "_" .. situation:upper()
    local totemSet = AC.ShamanTotemSets[setKey] or AC.ShamanTotemSets[spec:upper() .. "_SOLO"]
    if not totemSet then
        local bracket = level < 20 and "LOW" or (level < 40 and "MID" or "HIGH")
        totemSet = AC.ShamanTotemSets["LEVELING_" .. bracket]
    end

    local targetClose = UnitExists("target") and CheckInteractDistance("target", 2)
    if spec == "Elemental" and situation == "AOE" and not targetClose then
        totemSet = {
            [TotemTypes.EARTH] = totemSet[TotemTypes.EARTH],
            [TotemTypes.AIR] = totemSet[TotemTypes.AIR],
            [TotemTypes.FIRE] = S.TotemOfWrath,
            [TotemTypes.WATER] = totemSet[TotemTypes.WATER]
        }
    elseif spec == "Enhancement" and level < 60 then
        totemSet = {
            [TotemTypes.EARTH] = totemSet[TotemTypes.EARTH],
            [TotemTypes.AIR] = totemSet[TotemTypes.AIR],
            [TotemTypes.FIRE] = S.SearingTotem,
            [TotemTypes.WATER] = totemSet[TotemTypes.WATER]
        }
    end

    local protectedTotems = {
        [S.FireElementalTotem] = true,
        [S.EarthElementalTotem] = true,
        [S.ManaTideTotem] = true
    }
    local emptySlots, hasProtectedTotem = 0, false
    for slot = 1, 4 do
        local activeTotem, timeLeft = self:GetActiveShamanTotem(slot)
        if not activeTotem then emptySlots = emptySlots + 1 end
        local trackedUntil = self.shamanProtectedTotemUntil and self.shamanProtectedTotemUntil[slot] or 0
        local graceUntil = self.shamanProtectedTotemGraceUntil and self.shamanProtectedTotemGraceUntil[slot] or 0
        if trackedUntil > GetTime() and (activeTotem or graceUntil > GetTime()) then
            hasProtectedTotem = true
        end
        for protectedName in pairs(protectedTotems) do
            if ShamanTotemNameMatches(activeTotem, protectedName) and timeLeft > 1 then
                hasProtectedTotem = true
            end
        end
    end

    -- Call spells use the player's saved multicast set. They are efficient for
    -- an empty field; individual checks below correct any preset mismatch.
    if level >= 30 and emptySlots >= 3 and not hasProtectedTotem then
        local callSpell = self:IsShamanSpellReady(S.CallOfTheElements) and S.CallOfTheElements or
                         (self:IsShamanSpellReady(S.CallOfTheAncestors) and S.CallOfTheAncestors or
                         (self:IsShamanSpellReady(S.CallOfTheSpirits) and S.CallOfTheSpirits))
        if callSpell and self:CastShamanSpell(callSpell) then
            ShamanDebug("Called saved totem set with " .. callSpell)
            return true
        end
    end

    local slotPriority = {TotemTypes.FIRE, TotemTypes.AIR, TotemTypes.EARTH, TotemTypes.WATER}
    if spec == "Enhancement" then
        slotPriority = {TotemTypes.FIRE, TotemTypes.EARTH, TotemTypes.AIR, TotemTypes.WATER}
    elseif spec == "Restoration" then
        slotPriority = {TotemTypes.WATER, TotemTypes.AIR, TotemTypes.EARTH, TotemTypes.FIRE}
    end

    local fallbacks = {
        [TotemTypes.FIRE] = {S.SearingTotem, S.MagmaTotem},
        [TotemTypes.EARTH] = {S.StrengthOfEarthTotem, S.StoneskinTotem, S.StoneclawTotem},
        [TotemTypes.WATER] = {S.ManaSpringTotem, S.HealingStreamTotem},
        [TotemTypes.AIR] = {S.WrathOfAirTotem, S.WindfuryTotem, S.GraceOfAirTotem}
    }

    for _, slot in ipairs(slotPriority) do
        local activeTotem, timeLeft = self:GetActiveShamanTotem(slot)
        local trackedUntil = self.shamanProtectedTotemUntil and self.shamanProtectedTotemUntil[slot] or 0
        local graceUntil = self.shamanProtectedTotemGraceUntil and self.shamanProtectedTotemGraceUntil[slot] or 0
        local protectedActive = trackedUntil > GetTime() and (activeTotem or graceUntil > GetTime())
        for protectedName in pairs(protectedTotems) do
            if ShamanTotemNameMatches(activeTotem, protectedName) and timeLeft > 1 then
                protectedActive = true
                break
            end
        end

        if not protectedActive then
            local desiredTotem = totemSet[slot]
            if desiredTotem and not self:KnowsSpell(desiredTotem) then
                desiredTotem = nil
                for _, fallback in ipairs(fallbacks[slot]) do
                    if self:KnowsSpell(fallback) then desiredTotem = fallback break end
                end
            end

            local shouldDeploy = desiredTotem and
                                 (not activeTotem or not ShamanTotemNameMatches(activeTotem, desiredTotem) or
                                  (timeLeft > 0 and timeLeft < 12))
            if shouldDeploy and self:IsShamanSpellReady(desiredTotem) and
               self:CastShamanSpell(desiredTotem) then
                ShamanDebug("Deployed " .. desiredTotem .. " (" .. TotemSlotNames[slot] .. ", " .. situation .. ")")
                return true
            end
        end
    end
    return false
end

function AC:ApplyShamanWeaponImbue(spellName, inventorySlot)
    if not self:IsShamanSpellReady(spellName) or UnitCastingInfo("player") or UnitChannelInfo("player") then
        return false
    end
    if not GetInventoryItemID("player", inventorySlot) then return false end

    -- Weapon imbues open a spell-target cursor; /use 16 or /use 17 selects the
    -- intended equipped weapon. Picking the item up first merely moves it and
    -- was the reason the old off-hand path never applied Flametongue correctly.
    local castOK = pcall(CastSpellByName, spellName)
    if not castOK then return false end
    local useOK = pcall(UseInventoryItem, inventorySlot)
    if SpellIsTargeting and SpellIsTargeting() then SpellStopTargeting() end
    if CursorHasItem and CursorHasItem() then ClearCursor() end
    return useOK
end

function AC:ManageShamanWeaponImbues(spec, level)
    if not Throttle("WeaponImbue", 2.0) then return false end

    local hasMainHandEnchant, mainHandExpiration, _, _, hasOffHandEnchant, offHandExpiration = GetWeaponEnchantInfo()
    mainHandExpiration = hasMainHandEnchant and (mainHandExpiration or 0) / 1000 or 0
    offHandExpiration = hasOffHandEnchant and (offHandExpiration or 0) / 1000 or 0
    local reapplyThreshold = 60

    if self.shamanImbueSpec ~= spec then
        self.shamanImbueSpec = spec
        self.shamanVerifiedImbueSlots = {}
    end
    self.shamanVerifiedImbueSlots = self.shamanVerifiedImbueSlots or {}

    local mainHandImbue
    if spec == "Enhancement" then
        mainHandImbue = self:KnowsSpell(S.WindfuryWeapon) and S.WindfuryWeapon or S.FlametongueWeapon
    elseif spec == "Elemental" then
        mainHandImbue = S.FlametongueWeapon
    elseif spec == "Restoration" then
        mainHandImbue = self:KnowsSpell(S.EarthlivingWeapon) and S.EarthlivingWeapon or S.FlametongueWeapon
    else
        mainHandImbue = level >= 30 and self:KnowsSpell(S.WindfuryWeapon) and S.WindfuryWeapon or S.RockbiterWeapon
    end
    if not self:KnowsSpell(mainHandImbue) then
        mainHandImbue = self:KnowsSpell(S.RockbiterWeapon) and S.RockbiterWeapon or nil
    end

    local refreshMain = mainHandImbue and (not self.shamanVerifiedImbueSlots[16] or
                        not hasMainHandEnchant or (mainHandExpiration > 0 and mainHandExpiration < reapplyThreshold))
    if refreshMain and self:ApplyShamanWeaponImbue(mainHandImbue, 16) then
        self.shamanVerifiedImbueSlots[16] = true
        ShamanDebug("Applied " .. mainHandImbue .. " to main hand")
        return true
    end

    local hasOffHandWeapon = spec == "Enhancement" and GetInventoryItemID("player", 17) and
                             (not OffhandHasWeapon or OffhandHasWeapon())
    if hasOffHandWeapon and self:KnowsSpell(S.FlametongueWeapon) then
        local refreshOff = not self.shamanVerifiedImbueSlots[17] or not hasOffHandEnchant or
                           (offHandExpiration > 0 and offHandExpiration < reapplyThreshold)
        if refreshOff and self:ApplyShamanWeaponImbue(S.FlametongueWeapon, 17) then
            self.shamanVerifiedImbueSlots[17] = true
            ShamanDebug("Applied Flametongue Weapon to off hand")
            return true
        end
    end
    return false
end

function AC:ManageShamanShields(spec, level)
    if not Throttle("ShamanShield", 2.0) then return false end

    local wantsWaterShield = spec == "Restoration" or spec == "Elemental"
    local shield = wantsWaterShield and self:KnowsSpell(S.WaterShield) and S.WaterShield or
                   (self:KnowsSpell(S.LightningShield) and S.LightningShield)
    if shield then
        local hasBuff, _, stacks = self:HasBuff("player", shield)
        if not hasBuff or (shield == S.LightningShield and stacks and stacks <= 1) then
            if self:CastShamanSpell(shield) then return true end
        end
    end
    return false
end

-- ENHANCED ROTATIONS: Ultimate Optimization for All Specs

function AC:ElementalRotation(level, hasTarget, targetHP, manaPercent, enemies)
    if not hasTarget then return false end

    if self.TryInterrupt and self:TryInterrupt(S.WindShear, "target") then
        ShamanDebug("Interrupted with Wind Shear")
        return true
    end

    local targetClassification = UnitClassification("target")
    local isElite = targetClassification == "worldboss" or targetClassification == "elite" or
                    targetClassification == "rareelite"
    local isBoss = self:IsShamanBossTarget("target")
    local meaningfulTarget = isBoss or (isElite and targetHP > 60) or (enemies >= 3 and targetHP > 50)

    if isBoss and targetHP > 80 and self:IsShamanSpellReady(S.FireElementalTotem) and
       self:CastShamanSpell(S.FireElementalTotem) then
        self.shamanProtectedTotemUntil = self.shamanProtectedTotemUntil or {}
        self.shamanProtectedTotemGraceUntil = self.shamanProtectedTotemGraceUntil or {}
        self.shamanProtectedTotemUntil[TotemTypes.FIRE] = GetTime() + 120
        self.shamanProtectedTotemGraceUntil[TotemTypes.FIRE] = GetTime() + 3
        ShamanDebug("Fire Elemental for sustained boss damage")
        return true
    end

    local situation = enemies >= 3 and "AOE" or (IsInGroup() and "GROUP" or "SOLO")
    if self:DeployShamanTotems("Elemental", level, situation) then return true end

    local flameShockDuration = self:DebuffTimeRemaining("target", S.FlameShock)
    local targetWillLive = isElite or targetHP > 18
    if targetWillLive and self:IsShamanSpellReady(S.FlameShock) and flameShockDuration < 2.5 and
       self:CastShamanSpell(S.FlameShock) then
        ShamanDebug("Flame Shock for Lava Burst")
        return true
    end

    if meaningfulTarget and self:IsShamanSpellReady(S.ElementalMastery) and
       self:CastShamanSpell(S.ElementalMastery) then
        ShamanDebug("Elemental Mastery burst")
        if self.UseTrinkets then self:UseTrinkets() end
        if isBoss and self.UseOffensivePotion then self:UseOffensivePotion(true) end
        return true
    end

    if meaningfulTarget and self:UseShamanRacials(true, false) then return true end

    local isMoving = self:IsPlayerMoving()
    local fireTotem = self:GetActiveShamanTotem(TotemTypes.FIRE)
    local targetClose = CheckInteractDistance("target", 2)

    if enemies >= 3 and targetClose and fireTotem and self:IsShamanSpellReady(S.FireNova) and
       self:CastShamanSpell(S.FireNova) then
        ShamanDebug("Fire Nova on " .. enemies .. " nearby enemies")
        return true
    end

    -- Thunderstorm is excellent mana recovery, but an unglyphed knockback can
    -- scatter a tank's pull. Use it offensively only while solo, or for mana
    -- when no enemy is close enough to be displaced.
    local safeThunderstorm = (not IsInGroup() and enemies >= 2 and targetClose) or
                             (manaPercent < 35 and not targetClose)
    if safeThunderstorm and self:IsShamanSpellReady(S.Thunderstorm) and
       self:CastShamanSpell(S.Thunderstorm) then
        ShamanDebug("Thunderstorm for " .. (manaPercent < 35 and "mana" or "solo AoE"))
        return true
    end

    if isMoving then
        if flameShockDuration > 4 and targetHP > 10 and self:IsShamanSpellReady(S.EarthShock) and
           self:CastShamanSpell(S.EarthShock) then
            ShamanDebug("Earth Shock while moving")
            return true
        end
        return false
    end

    if flameShockDuration > 2.5 and self:IsShamanSpellReady(S.LavaBurst) and
       self:CastShamanSpell(S.LavaBurst) then
        ShamanDebug("Lava Burst with Flame Shock active")
        return true
    end

    if enemies >= 2 and manaPercent > 15 and self:IsShamanSpellReady(S.ChainLightning) and
       self:CastShamanSpell(S.ChainLightning) then
        ShamanDebug("Chain Lightning cleave")
        return true
    end

    if self:IsShamanSpellReady(S.LightningBolt) and self:CastShamanSpell(S.LightningBolt) then
        ShamanDebug("Lightning Bolt filler")
        return true
    end

    return false
end

function AC:EnhancementRotation(level, hasTarget, targetHP, manaPercent, enemies)
    if not hasTarget then return false end

    if not IsCurrentSpell("Attack") then
        StartAttack()
    end

    if self.TryInterrupt and self:TryInterrupt(S.WindShear, "target") then
        ShamanDebug("Interrupted with Wind Shear")
        return true
    end

    local classification = UnitClassification("target")
    local isElite = classification == "worldboss" or classification == "elite" or
                    classification == "rareelite"
    local isBoss = self:IsShamanBossTarget("target")
    local meaningfulTarget = isBoss or (isElite and targetHP > 55) or (enemies >= 3 and targetHP > 45)
    local health = self:GetPlayerHealthPercent()

    if isBoss and targetHP > 80 and self:IsShamanSpellReady(S.FireElementalTotem) and
       self:CastShamanSpell(S.FireElementalTotem) then
        self.shamanProtectedTotemUntil = self.shamanProtectedTotemUntil or {}
        self.shamanProtectedTotemGraceUntil = self.shamanProtectedTotemGraceUntil or {}
        self.shamanProtectedTotemUntil[TotemTypes.FIRE] = GetTime() + 120
        self.shamanProtectedTotemGraceUntil[TotemTypes.FIRE] = GetTime() + 3
        ShamanDebug("Fire Elemental for sustained boss damage")
        return true
    end

    local situation = enemies >= 2 and "AOE" or (IsInGroup() and "GROUP" or "SOLO")
    if self:DeployShamanTotems("Enhancement", level, situation) then return true end

    if meaningfulTarget and self:IsShamanSpellReady(S.FeralSpirit) and
       self:CastShamanSpell(S.FeralSpirit) then
        ShamanDebug("Feral Spirit on a durable target")
        if self.UseTrinkets then self:UseTrinkets() end
        if isBoss and self.UseOffensivePotion then self:UseOffensivePotion(true) end
        return true
    end

    if meaningfulTarget and self:UseShamanRacials(true, false) then return true end

    local mwStacks = self:GetMaelstromStacks()
    local fireTotem = self:GetActiveShamanTotem(TotemTypes.FIRE)
    local targetClose = CheckInteractDistance("target", 2)

    if enemies >= 3 and targetClose and fireTotem and self:IsShamanSpellReady(S.FireNova) and
       self:CastShamanSpell(S.FireNova) then
        ShamanDebug("Fire Nova AoE")
        return true
    end

    if mwStacks >= 5 then
        if health < 35 and self:IsShamanSpellReady(S.HealingWave) and
           self:CastShamanSpell(S.HealingWave, "player") then
            ShamanDebug("Instant emergency Healing Wave at 5 Maelstrom")
            return true
        end
        local maelstromSpell = enemies >= 2 and S.ChainLightning or S.LightningBolt
        if self:IsShamanSpellReady(maelstromSpell) and self:CastShamanSpell(maelstromSpell) then
            ShamanDebug("Instant " .. maelstromSpell .. " at 5 Maelstrom")
            return true
        end
    end

    if self:IsShamanSpellReady(S.Stormstrike) and self:CastShamanSpell(S.Stormstrike) then
        ShamanDebug("Stormstrike")
        return true
    end

    if self:IsShamanSpellReady(S.ShamanisticRage) and (manaPercent < 70 or health < 65) and
       self:CastShamanSpell(S.ShamanisticRage) then
        ShamanDebug("Shamanistic Rage for sustain")
        return true
    end

    local flameShockDuration = self:DebuffTimeRemaining("target", S.FlameShock)
    local targetWillLive = isElite or targetHP > 20
    if targetWillLive and flameShockDuration < 2.5 and self:IsShamanSpellReady(S.FlameShock) and
       self:CastShamanSpell(S.FlameShock) then
        ShamanDebug("Flame Shock maintenance")
        return true
    end

    if flameShockDuration > 4.5 and self:IsShamanSpellReady(S.EarthShock) and
       self:CastShamanSpell(S.EarthShock) then
        ShamanDebug("Earth Shock filler")
        return true
    end

    if enemies >= 2 and targetClose and fireTotem and self:IsShamanSpellReady(S.FireNova) and
       self:CastShamanSpell(S.FireNova) then
        ShamanDebug("Fire Nova cleave")
        return true
    end

    local hasOffHandWeapon = GetInventoryItemID("player", 17) and
                             (not OffhandHasWeapon or OffhandHasWeapon())
    if hasOffHandWeapon and self:IsShamanSpellReady(S.LavaLash) and
       self:CastShamanSpell(S.LavaLash) then
        ShamanDebug("Lava Lash filler")
        return true
    end

    return false
end

function AC:RestorationRotation(level, hasTarget, targetHP, manaPercent, enemies)
    local situation = GetNumRaidMembers() > 0 and "RAID" or (IsInGroup() and "GROUP" or "SOLO")

    local healTarget, healTargetHP, targetInfo = self:FindShamanHealingTarget("normal")
    local groupAnalysis = self:AnalyzeGroupDamage()
    local isMoving = self:IsPlayerMoving()

    -- Consume Nature's Swiftness immediately. Letting another instant spell
    -- take this branch would waste the emergency cooldown.
    if healTarget and self:HasBuff("player", S.NaturesSwiftness) and
       self:IsShamanSpellReady(S.HealingWave) and self:CastShamanSpell(S.HealingWave, healTarget) then
        ShamanDebug("Nature's Swiftness Healing Wave on " .. (UnitName(healTarget) or healTarget))
        return true
    end

    if healTarget and healTargetHP < 0.35 then
        if self:IsShamanSpellReady(S.NaturesSwiftness) and self:CastShamanSpell(S.NaturesSwiftness) then
            ShamanDebug("Nature's Swiftness for critical healing")
            return true
        end
        if self:IsShamanSpellReady(S.TidalForce) and self:CastShamanSpell(S.TidalForce) then
            ShamanDebug("Tidal Force for critical healing")
            return true
        end
        if self:IsShamanSpellReady(S.Riptide) and self:CastShamanSpell(S.Riptide, healTarget) then
            ShamanDebug("Emergency Riptide on " .. (UnitName(healTarget) or healTarget))
            return true
        end
        if not isMoving and self:IsShamanSpellReady(S.LesserHealingWave) and
           self:CastShamanSpell(S.LesserHealingWave, healTarget) then
            ShamanDebug("Emergency Lesser Healing Wave")
            return true
        end
        if not isMoving and self:IsShamanSpellReady(S.HealingWave) and
           self:CastShamanSpell(S.HealingWave, healTarget) then
            ShamanDebug("Emergency Healing Wave")
            return true
        end
    end

    if hasTarget and self.TryInterrupt and self:TryInterrupt(S.WindShear, "target") then
        ShamanDebug("Interrupted with Wind Shear")
        return true
    end

    local tankUnit = IsInGroup() and self:FindShamanTankUnit() or "player"
    if tankUnit and self:IsShamanSpellReady(S.EarthShield) then
        local hasEarthShield, charges = self:HasBuff(tankUnit, S.EarthShield)
        if (not hasEarthShield or (charges and charges <= 1)) and
           self:CastShamanSpell(S.EarthShield, tankUnit) then
            ShamanDebug("Earth Shield on " .. (UnitName(tankUnit) or tankUnit))
            return true
        end
    end

    if healTarget then
        local hasRiptide = self:HasBuff(healTarget, S.Riptide)
        if not hasRiptide and self:IsShamanSpellReady(S.Riptide) and
           self:CastShamanSpell(S.Riptide, healTarget) then
            ShamanDebug("Riptide on " .. (UnitName(healTarget) or healTarget))
            return true
        end

        if groupAnalysis.needsChainHeal and not isMoving and self:IsShamanSpellReady(S.ChainHeal) then
            local chainTarget = groupAnalysis.chainHealTargets[1] and
                                groupAnalysis.chainHealTargets[1].unit or healTarget
            if self:CastShamanSpell(S.ChainHeal, chainTarget) then
                ShamanDebug("Chain Heal for " .. groupAnalysis.damagedMembers .. " injured allies")
                return true
            end
        end

        local hasTidalWaves = self:HasBuff("player", S.TidalWaves)
        if healTargetHP < 0.60 and not isMoving and hasTidalWaves and
           self:IsShamanSpellReady(S.HealingWave) and self:CastShamanSpell(S.HealingWave, healTarget) then
            ShamanDebug("Tidal Waves Healing Wave")
            return true
        end
        if healTargetHP < 0.78 and not isMoving and self:IsShamanSpellReady(S.LesserHealingWave) and
           self:CastShamanSpell(S.LesserHealingWave, healTarget) then
            ShamanDebug("Lesser Healing Wave spot heal")
            return true
        end
        if healTargetHP < 0.60 and not isMoving and self:IsShamanSpellReady(S.HealingWave) and
           self:CastShamanSpell(S.HealingWave, healTarget) then
            ShamanDebug("Healing Wave large heal")
            return true
        end
    end

    if self:ManageShamanShields("Restoration", level) then return true end

    local lowManaUsers = self:GetShamanGroupManaPressure()
    if IsInGroup() and (manaPercent < 55 or lowManaUsers >= 2) and
       self:IsShamanSpellReady(S.ManaTideTotem) and self:CastShamanSpell(S.ManaTideTotem) then
        self.shamanProtectedTotemUntil = self.shamanProtectedTotemUntil or {}
        self.shamanProtectedTotemGraceUntil = self.shamanProtectedTotemGraceUntil or {}
        self.shamanProtectedTotemUntil[TotemTypes.WATER] = GetTime() + 12
        self.shamanProtectedTotemGraceUntil[TotemTypes.WATER] = GetTime() + 3
        ShamanDebug("Mana Tide for group mana pressure")
        return true
    end

    -- Utility and setup are intentionally below urgent healing.
    if self:HandleShamanCleansing() then return true end
    if manaPercent > 45 and hasTarget and self:HandleShamanPurge() then return true end
    if self:DeployShamanTotems("Restoration", level, situation) then return true end

    if self:GetPlayerHealthPercent() < 45 and self:UseShamanRacials(false, true) then return true end

    local safeToDPS = not healTarget and groupAnalysis.damagedMembers == 0 and
                      (not IsInGroup() or manaPercent > 75)
    if hasTarget and safeToDPS then
        local flameShockDuration = self:DebuffTimeRemaining("target", S.FlameShock)
        local targetWillLive = self:IsShamanBossTarget("target") or targetHP > 20
        if targetWillLive and flameShockDuration < 2.5 and self:IsShamanSpellReady(S.FlameShock) and
           self:CastShamanSpell(S.FlameShock) then
            ShamanDebug("Flame Shock during healing downtime")
            return true
        end
        if not isMoving and flameShockDuration > 2.5 and self:IsShamanSpellReady(S.LavaBurst) and
           self:CastShamanSpell(S.LavaBurst) then
            ShamanDebug("Lava Burst during healing downtime")
            return true
        end
        if not isMoving and self:IsShamanSpellReady(S.LightningBolt) and
           self:CastShamanSpell(S.LightningBolt) then
            ShamanDebug("Lightning Bolt during healing downtime")
            return true
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
        if activeTotemCount >= 2 and self:IsShamanSpellReady(S.TotemicRecall) then
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
    if spec == "Enhancement" and health < 60 and self:IsShamanSpellReady(S.ShamanisticRage) then
        if self:CastShamanSpell(S.ShamanisticRage) then
            ShamanDebug("Shamanistic Rage (defensive)")
            return true
        end
    end
    
    -- Self-heal with Maelstrom Weapon stacks
    if spec == "Enhancement" and health < 40 then
        local mwStacks = self:GetMaelstromStacks()
        if mwStacks >= 5 and self:IsShamanSpellReady(S.HealingWave) then
            if self:CastShamanSpell(S.HealingWave, "player") then
                ShamanDebug("Emergency self-heal (" .. mwStacks .. " MW stacks)")
                return true
            end
        end
    end

    if spec ~= "Restoration" and health < 30 then
        if self:HasBuff("player", S.NaturesSwiftness) and self:IsShamanSpellReady(S.HealingWave) and
           self:CastShamanSpell(S.HealingWave, "player") then
            ShamanDebug("Instant emergency self-heal")
            return true
        end
        if self:IsShamanSpellReady(S.NaturesSwiftness) and self:CastShamanSpell(S.NaturesSwiftness) then
            ShamanDebug("Nature's Swiftness for self-healing")
            return true
        end
        if not self:IsPlayerMoving() and self:IsShamanSpellReady(S.LesserHealingWave) and
           self:CastShamanSpell(S.LesserHealingWave, "player") then
            ShamanDebug("Emergency Lesser Healing Wave")
            return true
        end
        if not IsInGroup() and self:IsShamanSpellReady(S.StoneclawTotem) and
           self:CastShamanSpell(S.StoneclawTotem) then
            ShamanDebug("Stoneclaw Totem for solo survival")
            return true
        end
    end
    
    return false
end

function AC:ShamanLevelingRotation(level, hasTarget, targetHP, manaPercent, enemies)
    if not hasTarget then return false end
    if not IsCurrentSpell("Attack") then StartAttack() end

    if self.TryInterrupt and self:TryInterrupt(S.WindShear, "target") then return true end

    local classification = UnitClassification("target")
    local durableTarget = classification == "elite" or classification == "rareelite" or
                          classification == "worldboss" or enemies >= 2
    if (durableTarget or IsInGroup()) and self:DeployShamanTotems("Leveling", level, "SOLO") then
        return true
    end

    local close = CheckInteractDistance("target", 3)
    local flameShockDuration = self:DebuffTimeRemaining("target", S.FlameShock)
    local mwStacks = self:GetMaelstromStacks()
    if mwStacks >= 5 then
        local spell = enemies >= 2 and S.ChainLightning or S.LightningBolt
        if self:IsShamanSpellReady(spell) and self:CastShamanSpell(spell) then return true end
    end

    if close and self:IsShamanSpellReady(S.Stormstrike) and self:CastShamanSpell(S.Stormstrike) then
        return true
    end
    if (durableTarget or targetHP > 25) and flameShockDuration < 2.5 and
       self:IsShamanSpellReady(S.FlameShock) and self:CastShamanSpell(S.FlameShock) then
        return true
    end
    if flameShockDuration > 4.5 and self:IsShamanSpellReady(S.EarthShock) and
       self:CastShamanSpell(S.EarthShock) then
        return true
    end
    if close and self:IsShamanSpellReady(S.LavaLash) and self:CastShamanSpell(S.LavaLash) then
        return true
    end

    local fireTotem = self:GetActiveShamanTotem(TotemTypes.FIRE)
    if close and enemies >= 2 and fireTotem and self:IsShamanSpellReady(S.FireNova) and
       self:CastShamanSpell(S.FireNova) then
        return true
    end

    -- Once the mob reaches melee, preserve weapon swings and mana instead of
    -- hard-casting Lightning Bolt through the auto-attack cycle.
    if not close and manaPercent > 10 and not self:IsPlayerMoving() and
       self:IsShamanSpellReady(S.LightningBolt) and self:CastShamanSpell(S.LightningBolt) then
        return true
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
    
    -- Emergency defensives
    if health < 40 then
        if self:UseShamanDefensives() then
            return true
        end
    end

    -- Find target if needed (except for Restoration, which must keep healing
    -- even when no hostile target is selected).
    if not hasTarget and spec ~= "Restoration" then
        if self.FindAndSetTarget and self:FindAndSetTarget() then
            hasTarget = UnitExists("target") and UnitCanAttack("player", "target") and
                        not UnitIsDeadOrGhost("target")
            ShamanDebug("Auto-targeted enemy")
        end
        if not hasTarget then return false end
    end
    
    -- Calculate combat parameters
    local targetHP = hasTarget and (self.GetTargetHealthPercent and self:GetTargetHealthPercent("target") or 
                     (UnitHealth("target") / UnitHealthMax("target") * 100)) or 100
    local manaPercent = UnitPower("player", 0) / UnitPowerMax("player", 0) * 100
    local enemies = self.GetEnemyCount and self:GetEnemyCount() or 1

    -- Do not spend the interrupt window refreshing a shield. Restoration owns
    -- this check inside its triage flow so a missing Water Shield cannot delay
    -- an emergency heal.
    local interruptibleCast = hasTarget and self.GetInterruptibleCastInfo and
                              self:GetInterruptibleCastInfo("target")
    if spec ~= "Restoration" and not interruptibleCast and
       self:ManageShamanShields(spec, level) then
        return true
    end

    -- Spec-specific rotations
    local rotationResult = false
    if spec == "Elemental" then 
        rotationResult = self:ElementalRotation(level, hasTarget, targetHP, manaPercent, enemies)
    elseif spec == "Enhancement" then 
        rotationResult = self:EnhancementRotation(level, hasTarget, targetHP, manaPercent, enemies)
    elseif spec == "Restoration" then 
        rotationResult = self:RestorationRotation(level, hasTarget, targetHP, manaPercent, enemies)
    else
        rotationResult = self:ShamanLevelingRotation(level, hasTarget, targetHP, manaPercent, enemies)
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
        local slotName = TotemSlotNames[i]
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
                        local slotName = TotemSlotNames[i]
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
                        self:Print("1. Wind Shear and boss cooldowns")
                        self:Print("2. Flame Shock > Lava Burst")
                        self:Print("3. Fire Nova / Chain Lightning for AoE")
                        self:Print("4. Lightning Bolt filler")
                        self:Print("5. Safe movement shocks and Thunderstorm")
                        
                    elseif spec == "Enhancement" then
                        self:Print("WotLK 3.3.5a Enhancement Priority:")
                        self:Print("1. Fire Elemental / Feral Spirit on durable targets")
                        self:Print("2. Fire Nova AoE / Maelstrom 5-stack instants")
                        self:Print("3. Stormstrike and Shamanistic Rage")
                        self:Print("4. Flame Shock > Earth Shock")
                        self:Print("5. Fire Nova cleave > Lava Lash filler")
                        
                    elseif spec == "Restoration" then
                        self:Print("WotLK 3.3.5a Restoration Priority:")
                        self:Print("1. Critical healing and Wind Shear")
                        self:Print("2. Earth Shield tank maintenance")
                        self:Print("3. Riptide / Chain Heal for Tidal Waves")
                        self:Print("4. Tidal Waves single-target healing")
                        self:Print("5. Mana Tide, cleanse, totems, then safe DPS")
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

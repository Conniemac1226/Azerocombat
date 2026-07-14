-- AzeroCombat: Paladin Rotations (WotLK 3.3.5a RESEARCH-BASED CORRECTION)
local AddonName, AC = ...

-- =============================================
-- COMPLETELY RESEARCHED WOTLK 3.3.5A SPELL DATA
-- =============================================

-- FIXED: Spells table with ACTUAL WotLK 3.3.5a spell names
local S = {
    -- Seals (baseline abilities)
    SealRighteousness = "Seal of Righteousness",    -- Level 1 (first seal)
    SealLight = "Seal of Light",                    -- Level 20
    SealWisdom = "Seal of Wisdom",                  -- Level 30
    SealJustice = "Seal of Justice",                -- Level 16
    SealCommand = "Seal of Command",                -- Level 20 (talent)
    SealVengeance = "Seal of Vengeance",            -- Level 64 (Alliance)
    SealCorruption = "Seal of Corruption",          -- Level 66 (Horde)
    
    -- WotLK Judgement spells - can be cast with any active seal
    JudgementOfLight = "Judgement of Light",        -- Level 4 - healing effect
    JudgementOfWisdom = "Judgement of Wisdom",      -- Level 12 - mana effect  
    JudgementOfJustice = "Judgement of Justice",    -- Level 28 - slow/snare effect
    
    -- Basic baseline attacks (CORRECTED)
    Exorcism = "Exorcism",                          -- Level 20
    Consecration = "Consecration",                  -- Level 20 (baseline)
    HammerOfWrath = "Hammer of Wrath",              -- Level 44 (baseline)
    
    -- TALENT-ONLY ATTACKS (CORRECTED)
    CrusaderStrike = "Crusader Strike",             -- RETRIBUTION TALENT - Level 50 requirement
    
    -- Protection abilities (mostly talents)
    HammerOfRighteous = "Hammer of the Righteous", -- HIGH-TIER PROTECTION TALENT
    ShieldOfRighteous = "Shield of Righteousness", -- Level 75
    AvengersShield = "Avenger's Shield",            -- HIGH-TIER PROTECTION TALENT
    RighteousDefense = "Righteous Defense",         -- Level 10 (baseline)
    HandOfReckoning = "Hand of Reckoning",          -- Level 16 (baseline)
    HolyShield = "Holy Shield",                     -- PROTECTION TALENT
    RighteousFury = "Righteous Fury",               -- Level 16 (baseline)
    SacredShield = "Sacred Shield",                 -- Level 80
    
    -- Retribution abilities (talents)
    DivineStorm = "Divine Storm",                   -- Level 60 (Ret talent)
    
    -- Holy abilities
    HolyShock = "Holy Shock",                       -- Level 40 (Holy talent)
    FlashOfLight = "Flash of Light",                -- Level 20 (baseline)
    HolyLight = "Holy Light",                       -- Level 1 (baseline)
    BeaconOfLight = "Beacon of Light",              -- Holy talent
    LayOnHands = "Lay on Hands",                    -- Level 14 (baseline)
    
    -- AoE abilities
    HolyWrath = "Holy Wrath",                       -- Level 50 (baseline)
    
    -- Utility (baseline)
    DivineShield = "Divine Shield",                 -- Level 34
    DivineProtection = "Divine Protection",         -- Level 6
    HandOfProtection = "Hand of Protection",        -- Level 10
    HandOfFreedom = "Hand of Freedom",              -- Level 12
    HandOfSalvation = "Hand of Salvation",          -- Level 26
    HandOfSacrifice = "Hand of Sacrifice",          -- Level 46
    DivineSacrifice = "Divine Sacrifice",           -- PROTECTION TALENT
    HammerOfJustice = "Hammer of Justice",          -- Level 16
    Purify = "Purify",                              -- Level 8
    Cleanse = "Cleanse",                            -- Level 42
    TurnEvil = "Turn Evil",                         -- Level 24
    
    -- Cooldowns
    AvengingWrath = "Avenging Wrath",               -- Level 70
    DivinePlea = "Divine Plea",                     -- Level 71
    DivineFavor = "Divine Favor",                   -- Holy talent
    DivineIllumination = "Divine Illumination",     -- Holy talent
    AuraMastery = "Aura Mastery",                   -- Holy talent
    
    -- Procs and Buffs
    ArtOfWar = "The Art of War",                    -- Retribution talent proc buff
    InfusionOfLight = "Infusion of Light",          -- Holy talent proc buff
    JudgementsOfThePure = "Judgements of the Pure", -- Holy talent buff
    
    -- Blessings (baseline)
    BlessingOfMight = "Blessing of Might",          -- Level 4
    BlessingOfWisdom = "Blessing of Wisdom",        -- Level 14
    BlessingOfKings = "Blessing of Kings",          -- Level 20
    BlessingOfSanctuary = "Blessing of Sanctuary",  -- PROTECTION TALENT
    
    -- Greater Blessings (baseline at higher levels)
    GreaterBlessingOfMight = "Greater Blessing of Might",      -- Level 52
    GreaterBlessingOfWisdom = "Greater Blessing of Wisdom",    -- Level 54
    GreaterBlessingOfKings = "Greater Blessing of Kings",      -- Level 60
    GreaterBlessingOfSanctuary = "Greater Blessing of Sanctuary",
    
    -- Auras (baseline)
    DevotionAura = "Devotion Aura",                 -- Level 1
    RetributionAura = "Retribution Aura",           -- Level 16
    ConcentrationAura = "Concentration Aura",       -- Level 22
    CrusaderAura = "Crusader Aura",                 -- Level 62
    FireResistanceAura = "Fire Resistance Aura",    -- Level 28
    FrostResistanceAura = "Frost Resistance Aura",  -- Level 32
    ShadowResistanceAura = "Shadow Resistance Aura",-- Level 36
}

-- FIXED: ACTUAL spell level requirements (research-based)
local SpellLevels = {
    -- Seals
    [S.SealRighteousness] = 1,
    [S.SealJustice] = 16,
    [S.SealLight] = 20,
    [S.SealCommand] = 20, -- Talent, but often taken by this level if Ret
    [S.SealVengeance] = 64,
    [S.SealCorruption] = 66,
    [S.SealWisdom] = 30,
    
    -- Judgement spells
    [S.JudgementOfLight] = 4,
    [S.JudgementOfWisdom] = 12,
    [S.JudgementOfJustice] = 28,
    
    -- Baseline attacks
    [S.Exorcism] = 20,                  
    [S.Consecration] = 20,
    [S.HammerOfWrath] = 44,
    [S.HolyWrath] = 50,
    
    -- TALENTS (Updated to actual minimum character level to acquire)
    [S.CrusaderStrike] = 50,           -- RETRIBUTION TALENT (Requires 41 points in Retribution)
    [S.HammerOfRighteous] = 50,        -- PROTECTION TALENT (Requires 41 points in Protection)
    [S.AvengersShield] = 40,           -- PROTECTION TALENT (Requires 31 points in Protection)
    [S.HolyShield] = 30,               -- PROTECTION TALENT (Requires 21 points in Protection)
    [S.DivineStorm] = 60,              -- RETRIBUTION TALENT (Requires 51 points in Retribution)
    [S.HolyShock] = 40,                -- HOLY TALENT (Requires 31 points in Holy)
    [S.BeaconOfLight] = 60,            -- HOLY TALENT (Requires 51 points in Holy)
    
    -- High level abilities
    [S.ShieldOfRighteous] = 75,
    [S.AvengingWrath] = 70,
    [S.DivinePlea] = 71,
    [S.SacredShield] = 80,
    
    -- Baseline utility
    [S.FlashOfLight] = 20,
    [S.HolyLight] = 1,
    [S.DivineProtection] = 6,
    [S.Purify] = 8,
    [S.RighteousDefense] = 10,
    [S.HandOfProtection] = 10,
    [S.HandOfFreedom] = 12,
    [S.LayOnHands] = 14,
    [S.HammerOfJustice] = 16,
    [S.RighteousFury] = 16,
    [S.HandOfReckoning] = 16,
    [S.TurnEvil] = 24,
    [S.HandOfSalvation] = 26,
    [S.DivineShield] = 34,
    [S.DivineSacrifice] = 30,
    [S.Cleanse] = 42,
    [S.HandOfSacrifice] = 46,
    [S.DivineFavor] = 30,
    [S.DivineIllumination] = 50,
    [S.AuraMastery] = 20,
    
    -- Blessings
    [S.BlessingOfMight] = 4,
    [S.BlessingOfWisdom] = 14,
    [S.BlessingOfKings] = 20,
    [S.BlessingOfSanctuary] = 30,
    [S.GreaterBlessingOfMight] = 52,
    [S.GreaterBlessingOfWisdom] = 54,
    [S.GreaterBlessingOfKings] = 60,
    [S.GreaterBlessingOfSanctuary] = 60,
    
    -- Auras
    [S.DevotionAura] = 1,
    [S.RetributionAura] = 16,
    [S.ConcentrationAura] = 22,
    [S.FireResistanceAura] = 28,
    [S.FrostResistanceAura] = 32,
    [S.ShadowResistanceAura] = 36,
    [S.CrusaderAura] = 62,
}

-- WotLK party-unit aura queries are most reliable when buffs are scanned by
-- index. Keep blessing recognition in one place so the maintenance and cast
-- paths cannot disagree about whether a unit is already blessed.
local BlessingTypes = {
    [S.BlessingOfMight] = "Might",
    [S.GreaterBlessingOfMight] = "Might",
    [S.BlessingOfWisdom] = "Wisdom",
    [S.GreaterBlessingOfWisdom] = "Wisdom",
    [S.BlessingOfKings] = "Kings",
    [S.GreaterBlessingOfKings] = "Kings",
    [S.BlessingOfSanctuary] = "Sanctuary",
    [S.GreaterBlessingOfSanctuary] = "Sanctuary",
}

local PaladinDebug

local function GetUnitBlessing(unit)
    if not unit or not UnitExists(unit) then return nil, nil end

    for i = 1, 40 do
        local buffName = UnitBuff(unit, i)
        local blessingType = BlessingTypes[buffName]
        if blessingType then
            return buffName, blessingType
        end
    end

    return nil, nil
end

local function UnitHasBuffByScan(unit, wantedBuff)
    if not unit or not wantedBuff or not UnitExists(unit) then return false end

    -- Name lookup is the most direct path on 3.3.5; retain the full scan for
    -- private-server clients that do not support named party aura queries.
    local directName = UnitBuff(unit, wantedBuff)
    if directName == wantedBuff then return true end

    for i = 1, 40 do
        local buffName = UnitBuff(unit, i)
        if buffName == wantedBuff then return true end
    end

    return false
end

local PaladinAuras = {
    [S.DevotionAura] = true,
    [S.RetributionAura] = true,
    [S.ConcentrationAura] = true,
    [S.FireResistanceAura] = true,
    [S.FrostResistanceAura] = true,
    [S.ShadowResistanceAura] = true,
    [S.CrusaderAura] = true,
}

local function GetPlayerPaladinAura()
    local ownAura = nil
    local casterlessAura = nil
    local activeAuras = {}
    for i = 1, 40 do
        local buffName, _, _, _, _, _, _, caster = UnitBuff("player", i)
        if PaladinAuras[buffName] then
            activeAuras[buffName] = true
            if caster == "player" or (caster and UnitExists(caster) and UnitIsUnit(caster, "player")) then
                ownAura = ownAura or buffName
            end
            -- Some private-server clients omit the caster field. Preserve a
            -- usable fallback without mistaking a known ally aura for ours.
            if not caster then casterlessAura = casterlessAura or buffName end
        end
    end
    return ownAura or casterlessAura, activeAuras
end

-- FIXED: Debug function with correct class label
PaladinDebug = function(msg)
    if AC.debugMode then
        AC:Debug("|cFFFFD700Paladin:|r " .. tostring(msg))
    end
end

-- =============================================
-- MOVEMENT DETECTION SYSTEM (NEW)
-- =============================================

-- Function to check if player is moving (WotLK 3.3.5 compatible)
function AC:IsPlayerMoving()
    -- Use GetUnitSpeed which is available in WotLK 3.3.5
    local speed = GetUnitSpeed and GetUnitSpeed("player") or 0
    return speed > 0
end

-- Enhanced movement detection with caching to reduce API calls
AC.movementCache = {
    isMoving = false,
    lastCheck = 0,
    checkInterval = 0.1 -- Check every 100ms
}

function AC:IsPlayerMovingCached()
    local now = GetTime()
    if now - self.movementCache.lastCheck >= self.movementCache.checkInterval then
        self.movementCache.isMoving = self:IsPlayerMoving()
        self.movementCache.lastCheck = now
    end
    return self.movementCache.isMoving
end

-- =============================================
-- HELPER FUNCTIONS
-- =============================================

-- Get spell index from spellbook (properly handles rank)
function AC:GetSpellIndex(spellName)
    if not spellName then return nil end
    
    local maxSpells = 500
    for tabIndex = 1, GetNumSpellTabs() do
        local _, _, offset, numSpells = GetSpellTabInfo(tabIndex)
        for i = offset + 1, offset + numSpells do
            local name, rank = GetSpellName(i, BOOKTYPE_SPELL)
            if name == spellName then
                return i, BOOKTYPE_SPELL
            end
        end
    end
    return nil
end

-- Cast a blessing on a specific unit without relying on the unsupported
-- CastSpell return value or on ambiguous character names.
function AC:CastBlessingOnUnit(spellName, unit)
    if not spellName or not unit or not UnitExists(unit) then
        PaladinDebug("Invalid blessing target: " .. (unit or "nil"))
        return false
    end

    if not self:CanUsePaladinSpell(spellName) or not self:IsUsableSpell(spellName) or
       self:GetSpellCooldown(spellName) > 0.1 then
        PaladinDebug("Skipping unknown/unusable blessing: " .. spellName)
        return false
    end

    -- Do not let a stale ground-target cursor make a blessing appear cast.
    if SpellIsTargeting and SpellIsTargeting() then
        PaladinDebug("Skipping blessing while another spell is awaiting a target")
        return false
    end

    if unit ~= "player" and unit ~= "target" then
        local rangeResult = IsSpellInRange(spellName, unit)
        if rangeResult == 0 then
            PaladinDebug("SKIPPED " .. spellName .. " - " .. unit .. " is out of range")
            return false
        end
    end
    
    local existingBlessing, existingType = GetUnitBlessing(unit)
    local requestedType = BlessingTypes[spellName]
    if existingBlessing and (existingBlessing == spellName or existingType == requestedType) then
        PaladinDebug((UnitName(unit) or unit) .. " already has " .. existingBlessing .. ", skipping")
        return false
    end
    if requestedType == "Might" and UnitHasBuffByScan(unit, "Battle Shout") then
        PaladinDebug((UnitName(unit) or unit) .. " has Battle Shout; skipping conflicting " .. spellName)
        return false
    end
    
    -- Skip range check for self
    if unit ~= "player" then
        -- Check range (30 yards for blessings)
        if IsSpellInRange(spellName, unit) ~= 1 then
            PaladinDebug(spellName .. " out of range for " .. (UnitName(unit) or unit))
            return false
        end
    end
    
    -- Check if we're casting or on GCD
    if UnitCastingInfo("player") or UnitChannelInfo("player") then
        PaladinDebug("Currently casting, cannot bless")
        return false
    end
    
    -- THE REAL WORKING METHOD FOR WOTLK
    -- Get spell info
    local spellIndex, bookType = self:GetSpellIndex(spellName)
    if not spellIndex then
        PaladinDebug("ERROR: Can't find spell " .. spellName)
        return false
    end
    
    local unitName = UnitName(unit) or unit
    PaladinDebug("Attempting to bless " .. unitName .. " (" .. unit .. ") with " .. spellName)
    
    -- Check if unit is actually in our party/raid
    local inGroup = false
    if unit == "player" then
        inGroup = true
    elseif string.find(unit, "party") then
        local partyNum = tonumber(string.match(unit, "(%d+)"))
        if partyNum and partyNum <= GetNumPartyMembers() then
            inGroup = true
        end
    elseif string.find(unit, "raid") then
        local raidNum = tonumber(string.match(unit, "(%d+)"))
        if raidNum and raidNum <= GetNumRaidMembers() then
            inGroup = true
        end
    end
    
    if not inGroup then
        PaladinDebug("ERROR: " .. unit .. " is not in group!")
        return false
    end
    
    local hadOriginalTarget = UnitExists("target")
    local targetWasUnit = hadOriginalTarget and UnitIsUnit("target", unit)
    if not targetWasUnit then TargetUnit(unit) end

    if not UnitExists("target") or not UnitIsUnit("target", unit) then
        PaladinDebug("ERROR: Cannot target " .. unitName .. " for " .. spellName)
        return false
    end

    local beforeSpellCooldown = self:GetSpellCooldown(spellName)
    local beforeGlobalCooldown = self:GetSpellCooldown(61304)
    CastSpell(spellIndex, bookType)

    if SpellIsTargeting and SpellIsTargeting() then
        SpellTargetUnit(unit)
    end

    local castConfirmed = UnitCastingInfo("player") or UnitChannelInfo("player") or
                          self:GetSpellCooldown(spellName) > beforeSpellCooldown + 0.05 or
                          self:GetSpellCooldown(61304) > beforeGlobalCooldown + 0.05

    if not targetWasUnit then
        if hadOriginalTarget then TargetLastTarget() else ClearTarget() end
    end

    if not castConfirmed then
        PaladinDebug("Blessing cast did not start: " .. spellName .. " on " .. unitName)
        return false
    end

    self.paladinLastSuccessfulCast = self.paladinLastSuccessfulCast or {}
    self.paladinLastSuccessfulCast[spellName] = GetTime()
    PaladinDebug("Cast " .. spellName .. " on " .. unitName)
    return true
end


-- =============================================
-- BURST COOLDOWN LOGIC
-- =============================================

-- Determine when to use burst cooldowns
function AC:ShouldUseBurstCooldowns(hasTarget, targetHP, enemies, inCombat)
    if not hasTarget or not inCombat then return false end
    
    local isElite = UnitClassification("target") == "elite" or UnitClassification("target") == "worldboss" or UnitClassification("target") == "rareelite"
    
    -- Use burst cooldowns for:
    -- 1. Elite/boss enemies (always worth it)
    if isElite then return true end
    
    -- 2. Multiple enemies (3+ for AoE value)
    if enemies >= 3 then return true end
    
    -- 3. Long fights that have actually lasted at least 10 seconds.
    if targetHP > 60 and self:GetCombatTime() >= 10 then
        return true
    end
    
    return false
end

AC.PaladinShouldUseBurstCooldowns = AC.ShouldUseBurstCooldowns

-- =============================================
-- UTILITY COOLDOWN MANAGEMENT
-- =============================================

-- Use utility cooldowns (Hand of Freedom, Hand of Protection)
function AC:UseUtilityCooldowns()
    if not UnitAffectingCombat("player") then return false end
    
    local playerHealth = UnitHealth("player") / UnitHealthMax("player") * 100
    local spec = self:GetPlayerSpec()
    
    -- Hand of Freedom for movement impairing effects
    if self:CanUsePaladinSpell(S.HandOfFreedom) and self:IsUsableSpell(S.HandOfFreedom) then
        -- Check for slowing debuffs (basic check)
        for i = 1, 16 do
            local name = UnitDebuff("player", i)
            if not name then break end
            if name:find("Slow") or name:find("Root") or name:find("Snare") or
               name:find("Frost Nova") or name:find("Entangling Roots") or
               name:find("Hamstring") or name:find("Crippling Poison") or
               name:find("Chains of Ice") then
                if self:CastPaladinSpell(S.HandOfFreedom, "player") then
                    PaladinDebug("Used Hand of Freedom (movement impaired)")
                    return true
                end
            end
        end
    end
    
    -- Hand of Protection for physical debuffs when low health
    if spec ~= "Protection" and playerHealth < 40 and self:CanUsePaladinSpell(S.HandOfProtection) and self:IsUsableSpell(S.HandOfProtection) then
        -- Check for physical debuffs
        for i = 1, 16 do
            local name = UnitDebuff("player", i)
            if not name then break end
            if name:find("Bleed") or name:find("Rend") or name:find("Garrote") or
               name:find("Rupture") or name:find("Deep Wound") then
                if self:CastPaladinSpell(S.HandOfProtection, "player") then
                    PaladinDebug("Used Hand of Protection (physical debuff)")
                    return true
                end
            end
        end
    end
    
    return false
end

function AC:GetPaladinHealingTarget()
    local _, playerClass = UnitClass("player")
    if playerClass ~= "PALADIN" then return nil, 1 end

    local tankUnit = self:GetPaladinTankUnit()
    local bestUnit, bestHealth, bestScore = "player", 1, -1
    local units = {"player"}
    local prefix = GetNumRaidMembers() > 0 and "raid" or "party"
    local count = GetNumRaidMembers() > 0 and GetNumRaidMembers() or GetNumPartyMembers()
    for i = 1, count do
        table.insert(units, prefix .. i)
    end

    for _, unit in ipairs(units) do
        if UnitExists(unit) and UnitIsFriend("player", unit) and
           not UnitIsDeadOrGhost(unit) and UnitIsConnected(unit) then
            local maxHealth = UnitHealthMax(unit)
            if maxHealth and maxHealth > 0 then
                local health = UnitHealth(unit) / maxHealth
                local inRange = unit == "player" or not self:CanUsePaladinSpell(S.HolyLight) or
                                IsSpellInRange(S.HolyLight, unit) == 1
                local score = (1 - health) * 100
                if health < 0.95 and tankUnit and UnitIsUnit(unit, tankUnit) then
                    score = score + 8
                end
                if inRange and score > bestScore then
                    bestUnit, bestHealth = unit, health
                    bestScore = score
                end
            end
        end
    end
    return bestUnit, bestHealth
end

function AC:GetPaladinTankUnit()
    if UnitExists("focus") and UnitIsFriend("player", "focus") and
       not UnitIsDeadOrGhost("focus") then
        return "focus"
    end

    for i = 1, 5 do
        local unit = "maintank" .. i
        if UnitExists(unit) and not UnitIsDeadOrGhost(unit) and UnitIsConnected(unit) then
            return unit
        end
    end

    local prefix = GetNumRaidMembers() > 0 and "raid" or "party"
    local count = GetNumRaidMembers() > 0 and GetNumRaidMembers() or GetNumPartyMembers()
    local bestUnit, bestHealth = nil, 0
    for i = 1, count do
        local unit = prefix .. i
        if UnitExists(unit) and not UnitIsDeadOrGhost(unit) and UnitIsConnected(unit) then
            local hasTankBuff = self:HasBuff(unit, S.RighteousFury) or
                                self:HasBuff(unit, "Frost Presence") or
                                self:HasBuff(unit, "Bear Form") or
                                self:HasBuff(unit, "Dire Bear Form")
            local maxHealth = UnitHealthMax(unit) or 0
            if hasTankBuff then return unit end
            if maxHealth > bestHealth then
                bestUnit, bestHealth = unit, maxHealth
            end
        end
    end
    return bestUnit
end

function AC:PaladinEmergencyTriage()
    local target, health = self:GetPaladinHealingTarget()
    if not target or health >= 0.35 then return false end

    if health < 0.15 and self:CastPaladinSpellEmergency(S.LayOnHands, target) then
        return true
    end
    if health < 0.25 and self:IsPaladinSpellReady(S.DivineFavor) and
       self:CastPaladinSpell(S.DivineFavor, "player") then
        return true
    end
    if health < 0.35 and self:CastPaladinSpellEmergency(S.HolyShock, target) then
        return true
    end
    return self:CastPaladinSpellEmergency(S.FlashOfLight, target)
end

function AC:PaladinSmartHeal()
    local target, health = self:GetPaladinHealingTarget()
    if not target or health >= 0.92 then return false end

    if self:IsPlayerMovingCached() then
        if self:CastPaladinSpell(S.HolyShock, target) then return true end
        if self:HasBuff("player", S.InfusionOfLight) then
            return self:CastPaladinSpell(S.FlashOfLight, target)
        end
        return false
    end
    if health < 0.55 and self:CastPaladinSpell(S.HolyShock, target) then
        return true
    end
    if health < 0.70 and self:IsPaladinSpellReady(S.DivineIllumination) and
       self:CastPaladinSpell(S.DivineIllumination, "player") then
        return true
    end
    if health < 0.82 and self:CastPaladinSpell(S.HolyLight, target) then
        return true
    end
    return self:CastPaladinSpell(S.FlashOfLight, target)
end

-- Preserve leveling momentum without turning Ret/Prot into full-time healers.
-- Out of combat this tops up meaningful damage; in combat it only consumes a
-- free Art of War proc when health is genuinely low.
function AC:PaladinLevelingRecovery(spec, inCombat, healthPercent, manaPercent)
    if spec == "Holy" then return false end

    if inCombat then
        if healthPercent < 55 and self:HasArtOfWarProc() and
           self:CastPaladinSpell(S.FlashOfLight, "player") then
            PaladinDebug("Used Art of War for emergency self-healing")
            return true
        end
        return false
    end

    if healthPercent >= 70 or manaPercent < 35 then return false end

    if self:CanUsePaladinSpell(S.FlashOfLight) and
       self:CastPaladinSpell(S.FlashOfLight, "player") then
        PaladinDebug("Recovered health between pulls with Flash of Light")
        return true
    end
    if self:CanUsePaladinSpell(S.HolyLight) and
       self:CastPaladinSpell(S.HolyLight, "player") then
        PaladinDebug("Recovered health between pulls with Holy Light")
        return true
    end

    return false
end

function AC:MaintainHolyPaladinBuffs(manaPercent)
    local tankUnit = self:GetPaladinTankUnit()
    local _, lowestHealth = self:GetPaladinHealingTarget()
    if lowestHealth < 0.55 then return false end

    if tankUnit and self:CanUsePaladinSpell(S.BeaconOfLight) and
       (not self:HasBuff(tankUnit, S.BeaconOfLight) or
        self:BuffTimeRemaining(tankUnit, S.BeaconOfLight) < 5) then
        if self:CastPaladinSpell(S.BeaconOfLight, tankUnit) then return true end
    end

    if tankUnit and self:CanUsePaladinSpell(S.SacredShield) and
       (not self:HasBuff(tankUnit, S.SacredShield) or
        self:BuffTimeRemaining(tankUnit, S.SacredShield) < 4) then
        if self:CastPaladinSpell(S.SacredShield, tankUnit) then return true end
    end

    if UnitExists("target") and UnitCanAttack("player", "target") and
       (not self:HasBuff("player", S.JudgementsOfThePure) or
        self:BuffTimeRemaining("player", S.JudgementsOfThePure) < 5) and
       self:Throttle("HolyJudgementMaintenance", 20) then
        if self:CastJudgement() then return true end
    end

    if manaPercent < 60 and lowestHealth > 0.75 and
       self:IsPaladinSpellReady(S.DivinePlea) and
       not self:HasBuff("player", S.DivinePlea) then
        return self:CastPaladinSpell(S.DivinePlea, "player")
    end

    return false
end

-- =============================================
-- ENHANCED SPELL CASTING WITH MOVEMENT CHECK AND DEBUG OVERRIDE
-- =============================================

-- FIXED: Override CastSpell specifically for Paladin spells to include movement check
function AC:CastPaladinSpell(spellName, unit)
    unit = unit or "target"
    
    -- Skip if the spell doesn't exist or has no valid target
    if not spellName or (unit ~= "player" and not UnitExists(unit)) then
        PaladinDebug("FAILED to cast " .. (spellName or "unknown") .. " - invalid spell or target")
        return false
    end

    local now = GetTime()
    if self.paladinSpellSkipUntil and self.paladinSpellSkipUntil[spellName] and
       self.paladinSpellSkipUntil[spellName] > now then
        return false
    end

    -- Every branch, including blessings, must use the learned/usable gate.
    -- Otherwise an unlearned blessing can return success after a harmless
    -- CastSpellByName call and stall the rotation.
    if not self:CanUsePaladinSpell(spellName) or not self:IsUsableSpell(spellName) or
       self:GetSpellCooldown(spellName) > 0.1 then
        PaladinDebug("SKIPPED " .. spellName .. " - spell is not known, usable, or ready")
        return false
    end

    if SpellIsTargeting and SpellIsTargeting() then
        PaladinDebug("SKIPPED " .. spellName .. " - another spell is awaiting a target")
        return false
    end

    if unit ~= "player" and unit ~= "target" and IsSpellInRange(spellName, unit) == 0 then
        PaladinDebug("SKIPPED " .. spellName .. " - " .. unit .. " is out of range")
        return false
    end
    
    -- Special handling for blessings on party/raid members
    if spellName:find("Blessing") and unit ~= "player" and unit ~= "target" then
        return self:CastBlessingOnUnit(spellName, unit)
    end
    
    -- REMOVED: Consecration is not ground-targeted in WotLK
    local groundTargetedSpells = {
        -- Consecration removed - it's cast at player location
    }
    
    if groundTargetedSpells[spellName] then
        if self:IsPlayerMovingCached() then
            PaladinDebug("SKIPPED " .. spellName .. " - player is moving (will cast when stopped)")
            return false
        end
    end
    
    -- Check if spell is usable (this handles cooldown, mana, etc.)
    if not self:IsUsableSpell(spellName) then
        PaladinDebug("SKIPPED " .. spellName .. " - spell not usable (cooldown/mana/conditions not met)")
        return false
    end
    
    -- Double-check cooldown explicitly to prevent spam
    local cooldownRemaining = self:GetSpellCooldown(spellName)
    if cooldownRemaining > 0.1 then  -- Allow small tolerance for GCD
        -- Don't spam the log with cooldown messages
        return false
    end
    
    -- FIXED: Bypass the core CastSpell function that might have incorrect debug labels
    -- Do our own spell casting with proper Paladin debug messages
    
    -- Check if already casting (but be more specific)
    local currentCastingSpellName = UnitCastingInfo("player") -- Simplified, WotLK returns more args
    if currentCastingSpellName and currentCastingSpellName == spellName then
        PaladinDebug("SKIPPED " .. spellName .. " - already casting this spell")
        return false
    end
    
    -- Check for any current spell casting that would be interrupted
    if currentCastingSpellName then
        PaladinDebug("SKIPPED " .. spellName .. " - currently casting " .. currentCastingSpellName)
        return false
    end
    
    local beforeSpellCooldown = self:GetSpellCooldown(spellName)
    local beforeGlobalCooldown = self:GetSpellCooldown(61304)
    local beforeCast = UnitCastingInfo("player")
    local beforeChannel = UnitChannelInfo("player")

    -- Actually cast the spell using the WoW API directly
    local castTargetName = UnitName(unit) or unit
    if unit == "target" then
        CastSpellByName(spellName) -- Implicitly casts on current target
    else
        -- CastSpellByName has no unit argument in 3.3.5. Explicitly target
        -- self as well as party members; otherwise Holy Shock can damage the
        -- hostile target instead of healing the player.
        local hadOriginalTarget = UnitExists("target")
        local targetWasUnit = hadOriginalTarget and UnitIsUnit("target", unit)
        if not targetWasUnit then TargetUnit(unit) end

        if not UnitExists("target") or not UnitIsUnit("target", unit) then
            if not targetWasUnit then
                if hadOriginalTarget then TargetLastTarget() else ClearTarget() end
            end
            PaladinDebug("FAILED to target " .. unit .. " for spell cast")
            return false
        end

        CastSpellByName(spellName)
        if SpellIsTargeting and SpellIsTargeting() then SpellTargetUnit(unit) end

        if not targetWasUnit then
            if hadOriginalTarget then TargetLastTarget() else ClearTarget() end
        end
    end

    local afterSpellCooldown = self:GetSpellCooldown(spellName)
    local afterGlobalCooldown = self:GetSpellCooldown(61304)
    local started = (not beforeCast and UnitCastingInfo("player")) or
                   (not beforeChannel and UnitChannelInfo("player"))
    if not started and afterSpellCooldown <= beforeSpellCooldown + 0.05 and
       afterGlobalCooldown <= beforeGlobalCooldown + 0.05 and
       not (SpellIsTargeting and SpellIsTargeting()) then
        PaladinDebug("Cast rejected by client: " .. spellName)
        self.paladinSpellSkipUntil = self.paladinSpellSkipUntil or {}
        self.paladinSpellSkipUntil[spellName] = GetTime() + 0.25
        return false
    end

    self.paladinLastSuccessfulCast = self.paladinLastSuccessfulCast or {}
    self.paladinLastSuccessfulCast[spellName] = GetTime()
    if unit == "target" then
        PaladinDebug("Cast " .. spellName)
    else
        PaladinDebug("Cast " .. spellName .. " on " .. castTargetName)
    end

    return true
end

-- FIXED: Override for emergency spells to ensure they always use Paladin debug
function AC:CastPaladinSpellEmergency(spellName, unit)
    unit = unit or "player"
    
    if not spellName then
        return false
    end

    if unit ~= "player" and not UnitExists(unit) then
        return false
    end

    if not self:CanUsePaladinSpell(spellName) or not self:IsUsableSpell(spellName) or
       self:GetSpellCooldown(spellName) > 0.1 then
        PaladinDebug("EMERGENCY skipped " .. spellName .. " - spell is not known, usable, or ready")
        return false
    end

    if SpellIsTargeting and SpellIsTargeting() then
        PaladinDebug("EMERGENCY skipped " .. spellName .. " - another spell is awaiting a target")
        return false
    end


    if unit ~= "player" and unit ~= "target" and IsSpellInRange(spellName, unit) == 0 then
        return false
    end
    
    local beforeSpellCooldown = self:GetSpellCooldown(spellName)
    local beforeGlobalCooldown = self:GetSpellCooldown(61304)
    local beforeCast = UnitCastingInfo("player")
    local beforeChannel = UnitChannelInfo("player")

    -- For emergencies, keep validation minimal but still target the requested
    -- unit explicitly. Self-heals must not become offensive Holy Shock casts.
    local hadTarget = UnitExists("target")
    local targetWasUnit = hadTarget and UnitIsUnit("target", unit)
    if unit ~= "target" and not targetWasUnit then TargetUnit(unit) end

    if unit ~= "target" and (not UnitExists("target") or not UnitIsUnit("target", unit)) then
        if not targetWasUnit then
            if hadTarget then TargetLastTarget() else ClearTarget() end
        end
        PaladinDebug("EMERGENCY failed to target " .. unit .. " for " .. spellName)
        return false
    end

    CastSpellByName(spellName)
    if SpellIsTargeting and SpellIsTargeting() then SpellTargetUnit(unit) end

    if unit ~= "target" and not targetWasUnit then
        if hadTarget then TargetLastTarget() else ClearTarget() end
    end

    local afterSpellCooldown = self:GetSpellCooldown(spellName)
    local afterGlobalCooldown = self:GetSpellCooldown(61304)
    local started = (not beforeCast and UnitCastingInfo("player")) or
                   (not beforeChannel and UnitChannelInfo("player"))
    if not started and afterSpellCooldown <= beforeSpellCooldown + 0.05 and
       afterGlobalCooldown <= beforeGlobalCooldown + 0.05 and
       not (SpellIsTargeting and SpellIsTargeting()) then
        PaladinDebug("EMERGENCY cast did not start: " .. spellName)
        return false
    end

    PaladinDebug("EMERGENCY: Cast " .. spellName .. ( (unit and unit ~= "target" and unit ~= "player") and (" on " .. unit) or (unit == "player" and " (on self)" or "")))
    return true
end

-- =============================================
-- FIXED SPELL CHECKING FUNCTIONS
-- =============================================

-- Check if we can actually use a spell (level + talent check)
function AC:CanUsePaladinSpell(spellName)
    if not spellName then return false end
    
    -- Check level requirement
    local requiredLevel = SpellLevels[spellName] or 1
    local playerLevel = UnitLevel("player")
    
    if playerLevel < requiredLevel and requiredLevel ~= 999 then -- Allow 999 for talent check
        -- PaladinDebug("Cannot use " .. spellName .. " - requires level " .. requiredLevel .. " (current: " .. playerLevel .. ")")
        return false
    end
    
    -- CRITICAL: For talents (level set to actual min level but originally marked 999), check if spell is actually known
    -- We rely on KnowsSpell for all, as even baseline spells need to be learned from trainer.
    if not self:KnowsSpell(spellName) then
        -- PaladinDebug("Cannot use " .. spellName .. " - spell not known (or talent not learned)")
        return false
    end
    
    return true
end

-- =============================================
-- RETRIBUTION PROC AND ENHANCEMENT SYSTEM
-- =============================================

-- Check for Art of War proc (instant Exorcism/Flash of Light)
function AC:HasArtOfWarProc()
    return self:HasBuff("player", S.ArtOfWar)
end

-- Check for T10 2-piece set bonus (Lightsworn Battlegear)
function AC:HasT10TwoSet()
    local setPieces = 0
    for _, slot in ipairs({1, 3, 5, 7, 10}) do
        local itemLink = GetInventoryItemLink("player", slot)
        local itemName = itemLink and GetItemInfo(itemLink)
        if itemName and string.find(itemName, "Lightsworn") then
            setPieces = setPieces + 1
        end
    end
    return setPieces >= 2
end

-- =============================================
-- ENHANCED SEAL AND JUDGEMENT SYSTEM
-- =============================================

-- Get current active seal
function AC:GetActiveSeal()
    local seals = {
        S.SealRighteousness, S.SealCommand, S.SealLight, 
        S.SealWisdom, S.SealJustice, S.SealVengeance, S.SealCorruption
    }
    for _, sealName in ipairs(seals) do
        if sealName and self:HasBuff("player", sealName) then -- Added nil check for sealName
            return sealName
        end
    end
    return nil
end

-- FIXED: Enhanced seal management that works at ALL levels
function AC:GetBestAvailableSeal(spec, level, manaPercent, combatContext, enemies)
    local factionSeal = UnitFactionGroup("player") == "Horde" and S.SealCorruption or S.SealVengeance
    enemies = enemies or 1

    if spec == "Retribution" then
        -- For multiple enemies (3+), use Seal of Command for cleave damage
        if enemies >= 3 and self:CanUsePaladinSpell(S.SealCommand) then 
            return S.SealCommand 
        end
        -- For single target or 2 enemies, faction seals are superior DPS
        if self:CanUsePaladinSpell(factionSeal) then return factionSeal end
        if self:CanUsePaladinSpell(S.SealCommand) then return S.SealCommand end
        if self:CanUsePaladinSpell(S.SealRighteousness) then return S.SealRighteousness end
    elseif spec == "Protection" then
        -- Low-mana fallback: Wisdom keeps Protection stable before later mana-return tools are available.
        if manaPercent < 40 and self:CanUsePaladinSpell(S.SealWisdom) then
            return S.SealWisdom
        end
        -- Seal of Command is the best snap-threat seal for short multi-target pulls if talented.
        if enemies >= 3 and self:CanUsePaladinSpell(S.SealCommand) then
            return S.SealCommand
        end
        if self:CanUsePaladinSpell(factionSeal) then return factionSeal end
        if self:CanUsePaladinSpell(S.SealRighteousness) then return S.SealRighteousness end
    elseif spec == "Holy" then
        if manaPercent < 80 and self:CanUsePaladinSpell(S.SealWisdom) then return S.SealWisdom end
        if self:CanUsePaladinSpell(S.SealLight) then return S.SealLight end
        if self:CanUsePaladinSpell(S.SealRighteousness) then return S.SealRighteousness end -- For some damage if needed
    else -- Leveling or "None" spec
        if self:CanUsePaladinSpell(S.SealCommand) then return S.SealCommand end -- If talented early
        if self:CanUsePaladinSpell(factionSeal) then return factionSeal end
        if manaPercent < 70 and self:CanUsePaladinSpell(S.SealWisdom) then return S.SealWisdom end
        if self:CanUsePaladinSpell(S.SealRighteousness) then return S.SealRighteousness end
        if self:CanUsePaladinSpell(S.SealLight) then return S.SealLight end
        if self:CanUsePaladinSpell(S.SealJustice) then return S.SealJustice end
    end
    
    -- Absolute fallback if no specific conditions met but player knows SoR
    if self:CanUsePaladinSpell(S.SealRighteousness) then return S.SealRighteousness end
    return nil -- Should ideally always find SoR if level 1+
end

-- SIMPLIFIED: WotLK judgement system - any judgement works with any seal
function AC:CastJudgement()
    local hasTarget = UnitExists("target") and UnitCanAttack("player", "target") and not UnitIsDeadOrGhost("target")
    if not hasTarget then return false end
    
    local level = UnitLevel("player")
    local manaPercent = (UnitPower("player", 0) / UnitPowerMax("player", 0)) * 100
    local spec = self:GetPlayerSpec()
    
    if level < 4 then return false end
    
    -- Simple priority: Wisdom for mana, Light for survivability, Justice for CC
    local bestJudgement = nil
    
    if spec == "Protection" or spec == "Holy" then
        -- Tanks and healers prioritize mana efficiency and survivability
        if manaPercent < 70 and level >= 12 and self:CanUsePaladinSpell(S.JudgementOfWisdom) then
            bestJudgement = S.JudgementOfWisdom
        elseif self:CanUsePaladinSpell(S.JudgementOfLight) then
            bestJudgement = S.JudgementOfLight
        end
    else
        -- DPS specs prioritize Light for survivability, then Wisdom for mana
        if self:CanUsePaladinSpell(S.JudgementOfLight) then
            bestJudgement = S.JudgementOfLight
        elseif manaPercent < 60 and level >= 12 and self:CanUsePaladinSpell(S.JudgementOfWisdom) then
            bestJudgement = S.JudgementOfWisdom
        end
    end
    
    -- Fallback to any available judgement
    if not bestJudgement then
        if self:CanUsePaladinSpell(S.JudgementOfLight) then
            bestJudgement = S.JudgementOfLight
        elseif level >= 12 and self:CanUsePaladinSpell(S.JudgementOfWisdom) then
            bestJudgement = S.JudgementOfWisdom
        elseif level >= 28 and self:CanUsePaladinSpell(S.JudgementOfJustice) then
            bestJudgement = S.JudgementOfJustice
        end
    end
    
    if bestJudgement and self:IsPaladinSpellReady(bestJudgement) then
        if self:CastPaladinSpell(bestJudgement, "target") then
            return true
        end
    end
    
    return false
end

function AC:GetJudgementDebugStatus()
    local judgements = {S.JudgementOfWisdom, S.JudgementOfLight, S.JudgementOfJustice}
    local parts = {}
    for _, judgement in ipairs(judgements) do
        if judgement then
            local known = self:CanUsePaladinSpell(judgement)
            local usable = known and self:IsUsableSpell(judgement)
            local cd = known and self:GetSpellCooldown(judgement) or -1
            table.insert(parts, string.format("%s K:%s U:%s CD:%.1f", judgement, tostring(known), tostring(usable), cd))
        end
    end
    return table.concat(parts, " | ")
end

function AC:IsPaladinSpellReady(spellName)
    if not spellName then return false end

    local now = GetTime()
    if self.paladinSpellSkipUntil and self.paladinSpellSkipUntil[spellName] and
       self.paladinSpellSkipUntil[spellName] > now then
        return false
    end

    if self.paladinLastSuccessfulCast and self.paladinLastSuccessfulCast[spellName] then
        local recentLockout = spellName == S.HolyShield and 6.0 or
                              spellName == S.AvengingWrath and 10.0 or
                              spellName == S.DivineProtection and 3.0 or
                              spellName == S.SacredShield and 3.0 or 0
        if recentLockout > 0 and (now - self.paladinLastSuccessfulCast[spellName]) < recentLockout then
            return false
        end
    end

    return self:CanUsePaladinSpell(spellName) and self:IsUsableSpell(spellName) and
           self:GetSpellCooldown(spellName) <= 0.1
end

function AC:TemporarilySkipPaladinSpell(spellName)
    if not spellName then return end
    self.paladinSpellSkipUntil = self.paladinSpellSkipUntil or {}

    local cooldown = self:GetSpellCooldown(spellName)
    local skipFor = cooldown > 0 and math.min(cooldown, 2.0) or 0.75
    self.paladinSpellSkipUntil[spellName] = GetTime() + skipFor
end

-- WotLK Paladin pulling priority
function AC:PaladinPull()
    local hasTarget = UnitExists("target") and UnitCanAttack("player", "target") and not UnitIsDeadOrGhost("target")
    local level = UnitLevel("player")
    local spec = self:GetPlayerSpec()
    if not hasTarget then return false end
    if UnitAffectingCombat("target") and UnitIsUnit("targettarget", "player") then return false end -- Already pulled
    
    local manaPercent = (UnitPower("player", 0) / UnitPowerMax("player", 0)) * 100
    
    -- Priority 1: Avenger's Shield is the default Protection pull for snap multi-target threat.
    if spec == "Protection" and self:IsPaladinSpellReady(S.AvengersShield) then
        if self:CastPaladinSpell(S.AvengersShield, "target") then
            PaladinDebug("Pulling with Avenger's Shield")
            return true
        end
    end

    -- Pre-pull mitigation fallback when Avenger's Shield is unavailable.
    if spec == "Protection" and self:IsPaladinSpellReady(S.HolyShield) and
       not self:HasBuff("player", S.HolyShield) then
        if self:CastPaladinSpell(S.HolyShield, "player") then
            PaladinDebug("Pre-pull Holy Shield")
            return true
        end
    end

    -- Priority 2: Exorcism if safely out of melee; do not hard cast into incoming swings.
    if spec == "Protection" and level >= 20 and manaPercent > 60 and not CheckInteractDistance("target", 3) and
       self:IsPaladinSpellReady(S.Exorcism) then
        if self:CastPaladinSpell(S.Exorcism, "target") then
            PaladinDebug("Pulling with safe-range Exorcism")
            return true
        end
    end

    -- Priority 3: Hand of Reckoning can add pull damage when the target is not already on us.
    if spec == "Protection" and self:CanUsePaladinSpell(S.HandOfReckoning) and
       self:IsUsableSpell(S.HandOfReckoning) and self:GetSpellCooldown(S.HandOfReckoning) == 0 and
       (not UnitExists("targettarget") or not UnitIsUnit("targettarget", "player")) then
        if self:CastPaladinSpell(S.HandOfReckoning, "target") then
            PaladinDebug("Pulling with Hand of Reckoning")
            return true
        end
    end
    
    -- Priority 4: Judgement (all specs, reliable - 10s cooldown)
    if level >= 4 then
        if self:CastJudgement() then
            PaladinDebug("Pulling with Judgement")
            return true
        end
    end
    
    -- Priority 5: Exorcism fallback for non-Protection or when no other pull tools exist.
    if level >= 20 and manaPercent > 60 and self:CanUsePaladinSpell(S.Exorcism) and 
       self:IsUsableSpell(S.Exorcism) and self:GetSpellCooldown(S.Exorcism) == 0 then
        if self:CastPaladinSpell(S.Exorcism, "target") then
            PaladinDebug("Pulling with Exorcism")
            return true
        end
    end
    
    -- Fallback: Ranged weapon for very low levels
    if level < 4 then
        if GetInventoryItemID("player", 18) then 
            if not IsCurrentSpell("Auto Shot") and self:KnowsSpell("Auto Shot") and
               self:IsUsableSpell("Auto Shot") then
                if self:CastSpell("Auto Shot", "target") then
                    PaladinDebug("Pulling with ranged weapon")
                    return true
                end
            end
        end
    end
    
    return false
end

-- REMOVED: GetActiveJudgement function - not needed with simplified system

-- ENHANCED: Debug test to check seal availability by level
function AC:TestSealAvailability()
    local level = UnitLevel("player")
    self:Print("=== SEAL AVAILABILITY TEST (Level " .. level .. ") ===")
    local sealsByLevel = {
        {seal = S.SealRighteousness, requiredLevel = SpellLevels[S.SealRighteousness]},
        {seal = S.SealJustice, requiredLevel = SpellLevels[S.SealJustice]},
        {seal = S.SealLight, requiredLevel = SpellLevels[S.SealLight]},
        {seal = S.SealCommand, requiredLevel = SpellLevels[S.SealCommand]}, -- Talent, effective level varies
        {seal = S.SealVengeance, requiredLevel = SpellLevels[S.SealVengeance]},
        {seal = S.SealCorruption, requiredLevel = SpellLevels[S.SealCorruption]},
        {seal = S.SealWisdom, requiredLevel = SpellLevels[S.SealWisdom]},
    }
    
    for _, sealData in ipairs(sealsByLevel) do
        local canUse = self:CanUsePaladinSpell(sealData.seal)
        self:Print(string.format("  %s %s (Req Lvl %d)", (canUse and "✓" or "✗"), sealData.seal, sealData.requiredLevel))
    end
    
    local spec = self:GetPlayerSpec()
    local manaPercent = (UnitPower("player", 0) / UnitPowerMax("player", 0)) * 100
    local bestSeal = self:GetBestAvailableSeal(spec, level, manaPercent, "debug", 1)
    self:Print("Best seal for " .. spec .. " spec: " .. (bestSeal or "NONE"))
    self:Print("Currently active seal: " .. (self:GetActiveSeal() or "None"))
    self:Print("================================================")
end

function AC:IsCurrentTargetDemonOrUndead()
    if not UnitExists("target") then return false end
    local creatureType = UnitCreatureType("target")
    return creatureType == "Demon" or creatureType == "Undead"
end

function AC:GetProtectionSixSecondAbility(enemies)
    if not UnitExists("target") or not UnitCanAttack("player", "target") then
        return nil, nil
    end

    local first = enemies >= 2 and S.HammerOfRighteous or S.ShieldOfRighteous
    local second = enemies >= 2 and S.ShieldOfRighteous or S.HammerOfRighteous

    if self:IsPaladinSpellReady(first) then
        return first, "target"
    end
    if self:IsPaladinSpellReady(second) then
        return second, "target"
    end

    return nil, nil
end

function AC:IsProtectionSixSecondSpell(spellName)
    return spellName == S.HammerOfRighteous or spellName == S.ShieldOfRighteous
end

function AC:IsProtectionNineSecondSpell(spellName)
    return spellName == S.HolyShield or spellName == S.Consecration or
           spellName == "CAST_JUDGEMENT"
end

function AC:GetProtectionNineSecondAbility(level, manaPercent, enemies, targetHP)
    if self:IsPaladinSpellReady(S.HolyShield) then
        local hsTime = self:HasBuff("player", S.HolyShield) and self:BuffTimeRemaining("player", S.HolyShield) or 0
        if hsTime < 2.0 then
            return S.HolyShield, "player"
        end
    end

    if targetHP < 20 and self:IsPaladinSpellReady(S.HammerOfWrath) then
        return S.HammerOfWrath, "target"
    end

    if enemies >= 3 and self:IsCurrentTargetDemonOrUndead() and
       self:IsPaladinSpellReady(S.HolyWrath) then
        return S.HolyWrath, "player"
    end

    local judgementToUse = nil
    if manaPercent < 60 and level >= 12 and self:CanUsePaladinSpell(S.JudgementOfWisdom) then
        judgementToUse = S.JudgementOfWisdom
    elseif level >= 12 and self:CanUsePaladinSpell(S.JudgementOfWisdom) then
        judgementToUse = S.JudgementOfWisdom
    elseif level >= 4 and self:CanUsePaladinSpell(S.JudgementOfLight) then
        judgementToUse = S.JudgementOfLight
    elseif level >= 28 and self:CanUsePaladinSpell(S.JudgementOfJustice) then
        judgementToUse = S.JudgementOfJustice
    end

    -- Judgement is a core 969 beat. Only let Consecration jump ahead for real AoE.
    if enemies < 3 and judgementToUse and self:IsPaladinSpellReady(judgementToUse) then
        return "CAST_JUDGEMENT", nil
    end

    if self:IsPaladinSpellReady(S.Consecration) and (enemies >= 2 or manaPercent > 35) then
        return S.Consecration, "player"
    end

    if judgementToUse and self:IsPaladinSpellReady(judgementToUse) then
        return "CAST_JUDGEMENT", nil
    end

    -- Keep Avenger's Shield situational in combat so its bounce does not pull
    -- unrelated packs or break crowd control on a routine single target.
    if (enemies >= 2 or UnitCastingInfo("target") or UnitChannelInfo("target")) and
       self:IsPaladinSpellReady(S.AvengersShield) then
        return S.AvengersShield, "target"
    end

    return nil, nil
end

function AC:GetProtectionFallbackAbility(level, manaPercent, enemies, targetHP)
    local ability, unit = self:GetProtectionSixSecondAbility(enemies)
    if ability then return ability, unit end

    ability, unit = self:GetProtectionNineSecondAbility(level, manaPercent, enemies, targetHP)
    if ability then return ability, unit end

    if self:IsPaladinSpellReady(S.Exorcism) and manaPercent > 40 and self:IsCurrentTargetDemonOrUndead() then
        return S.Exorcism, "target"
    end

    return nil, nil
end

-- ENHANCED: Research-based Protection rotation with smart threat and defensive management
function AC:Protection969Rotation(level, mana, manaPercent, enemies, hasTarget)
    -- Initialize threat tracking variables for universal system
    self.expectedThreatTargets = self.expectedThreatTargets or {}
    self.lastTauntTime = self.lastTauntTime or 0
    self.lastTauntTarget = self.lastTauntTarget or ""
    
    local playerHealth = UnitHealth("player") / UnitHealthMax("player") * 100
    local targetHP = hasTarget and (UnitHealth("target") / UnitHealthMax("target") * 100) or 100
    
    -- CRITICAL: Emergency defensive cooldowns (highest priority)
    if playerHealth < 15 then
        -- Do not auto-bubble while actively tanking; immunity can drop mob targeting.
        if self:IsPaladinSpellReady(S.LayOnHands) then
            return S.LayOnHands, "player"
        elseif self:IsPaladinSpellReady(S.DivineProtection) then
            return S.DivineProtection, "player"
        end
    elseif playerHealth < 25 then
        -- Critical tier: Divine Protection and racials
        if self:IsPaladinSpellReady(S.DivineProtection) then
            return S.DivineProtection, "player"
        end
    elseif playerHealth < 40 then
        -- Tank preventive tier: Use Divine Protection proactively
        if self:IsPaladinSpellReady(S.DivineProtection) then
            return S.DivineProtection, "player"
        end
    end
    
    -- CRITICAL: Righteous Fury uptime (80% threat increase - MANDATORY)
    if level >= 16 and self:CanUsePaladinSpell(S.RighteousFury) and not self:HasBuff("player", S.RighteousFury) then
        return S.RighteousFury, "player"
    end

    if level >= 71 and self:IsPaladinSpellReady(S.DivinePlea) and
       not self:HasBuff("player", S.DivinePlea) and manaPercent < 85 then
        return S.DivinePlea, "player"
    end

    if self:IsPaladinSpellReady(S.SacredShield) and
       (not self:HasBuff("player", S.SacredShield)) and self:Throttle("ProtectionSacredShield", 20) then
        return S.SacredShield, "player"
    end

    local targetCast = hasTarget and (UnitCastingInfo("target") or UnitChannelInfo("target"))
    if targetCast and self:ShouldInterruptSpell(targetCast) and
       self:IsPaladinSpellReady(S.HammerOfJustice) then
        return S.HammerOfJustice, "target"
    end

    if not hasTarget then
        return nil, nil
    end

    if self:ShouldUseBurstCooldowns(hasTarget, targetHP, enemies, UnitAffectingCombat("player")) and
       playerHealth > 55 and self:IsPaladinSpellReady(S.AvengingWrath) and
       not self:HasDebuff("player", "Forbearance") then
        return S.AvengingWrath, "player"
    end

    -- True 969 alternation when possible, with fallback for leveling or broken cooldown states.
    self.paladin969NextBucket = self.paladin969NextBucket or "six"
    local ability, targetUnit
    if self.paladin969NextBucket == "six" then
        ability, targetUnit = self:GetProtectionSixSecondAbility(enemies)
        if ability then return ability, targetUnit end
        ability, targetUnit = self:GetProtectionNineSecondAbility(level, manaPercent, enemies, targetHP)
        if ability then return ability, targetUnit end
    else
        ability, targetUnit = self:GetProtectionNineSecondAbility(level, manaPercent, enemies, targetHP)
        if ability then return ability, targetUnit end
        ability, targetUnit = self:GetProtectionSixSecondAbility(enemies)
        if ability then return ability, targetUnit end
    end

    return self:GetProtectionFallbackAbility(level, manaPercent, enemies, targetHP)
end

-- UPDATED: Combat rotation that prioritizes judgement usage and uses new CastPaladinSpell function
function AC:PaladinCombatRotation(spec, level, hasTarget, targetHP, manaPercent, enemies, inCombat)
    if spec == "Protection" then
        if self:HandleTankTargeting() then return true end

        local ability, targetUnit = self:Protection969Rotation(level, UnitPower("player",0), manaPercent, enemies, hasTarget)
        if ability then
            if ability == "CAST_JUDGEMENT" then
                if self:CastJudgement() then 
                    self.paladin969NextBucket = "six"
                    PaladinDebug("969: Cast Judgement")
                    return true 
                elseif self:Throttle("ProtectionJudgementFailDebug", 1.0) then
                    PaladinDebug("969: Judgement selected but failed | " .. self:GetJudgementDebugStatus())
                end
            elseif self:CastPaladinSpell(ability, targetUnit or "target") then -- Default to target if targetUnit is nil
                if self:IsProtectionSixSecondSpell(ability) then
                    self.paladin969NextBucket = "nine"
                elseif self:IsProtectionNineSecondSpell(ability) then
                    self.paladin969NextBucket = "six"
                end
                PaladinDebug("969: Cast " .. ability)
                return true
            else
                self:TemporarilySkipPaladinSpell(ability)
                if self:Throttle("ProtectionCastFailDebug_" .. tostring(ability), 1.0) then
                    local unit = targetUnit or "target"
                    local validTarget = unit == "player" or (UnitExists(unit) and UnitCanAttack("player", unit))
                    local rangeInfo = "n/a"
                    if unit ~= "player" and UnitExists(unit) then
                        local ok, inRange = pcall(IsSpellInRange, ability, unit)
                        rangeInfo = ok and tostring(inRange) or "err"
                    end
                    PaladinDebug(string.format("969: Selected %s but cast failed | unit:%s valid:%s usable:%s cd:%.1f range:%s",
                        tostring(ability), tostring(unit), tostring(validTarget), tostring(self:IsUsableSpell(ability)),
                        self:GetSpellCooldown(ability), rangeInfo))
                end

                local fallbackAbility, fallbackUnit = self:GetProtectionFallbackAbility(level, manaPercent, enemies, targetHP)
                if fallbackAbility and fallbackAbility ~= ability then
                    if fallbackAbility == "CAST_JUDGEMENT" then
                        if self:CastJudgement() then
                            self.paladin969NextBucket = "six"
                            PaladinDebug("969: Fallback cast Judgement")
                            return true
                        end
                    elseif self:CastPaladinSpell(fallbackAbility, fallbackUnit or "target") then
                        if self:IsProtectionSixSecondSpell(fallbackAbility) then
                            self.paladin969NextBucket = "nine"
                        elseif self:IsProtectionNineSecondSpell(fallbackAbility) then
                            self.paladin969NextBucket = "six"
                        end
                        PaladinDebug("969: Fallback cast " .. fallbackAbility)
                        return true
                    end
                end
            end
        end
    elseif spec == "Retribution" then
        local hasT10Set = self:HasT10TwoSet()
        local hasArtOfWar = self:HasArtOfWarProc()

        -- Align wings, trinkets, and racials on meaningful targets.
        if self:ShouldUseBurstCooldowns(hasTarget, targetHP, enemies, inCombat) then
            if self:CanUsePaladinSpell(S.AvengingWrath) and self:IsUsableSpell(S.AvengingWrath) then
                if self:CastPaladinSpell(S.AvengingWrath, "player") then return true end
            end
            if self:UseTrinkets() then
                PaladinDebug("Used offensive trinket for burst")
                return true
            end
            if self:UsePaladinRacials(true) then -- true = offensive usage
                return true
            end
        end

        if manaPercent < 45 and self:IsPaladinSpellReady(S.DivinePlea) and
           not self:HasBuff("player", S.DivinePlea) then
            if self:CastPaladinSpell(S.DivinePlea, "player") then return true end
        end

        local function castReady(spellName, unit)
            return self:CanUsePaladinSpell(spellName) and self:IsUsableSpell(spellName) and
                   self:CastPaladinSpell(spellName, unit or "target")
        end
        local function castConsecration()
            if manaPercent <= 20 or not self:CanUsePaladinSpell(S.Consecration) or
               not self:IsUsableSpell(S.Consecration) then return false end
            if enemies >= 2 or CheckInteractDistance("target", 3) then
                return self:CastPaladinSpell(S.Consecration, "player")
            end
            return false
        end
        local function castHolyWrath()
            return self:IsCurrentTargetDemonOrUndead() and castReady(S.HolyWrath, "player")
        end
        local function castExecute()
            return targetHP < 20 and castReady(S.HammerOfWrath, "target")
        end
        local function castArtOfWar()
            return hasArtOfWar and manaPercent > 15 and castReady(S.Exorcism, "target")
        end

        -- T10's Divine Storm reset is only prioritized when two real set pieces are equipped.
        if hasT10Set and castReady(S.DivineStorm) then return true end

        if enemies >= 3 then
            if castReady(S.DivineStorm) then return true end
            if castConsecration() then return true end
            if castHolyWrath() then return true end
            if castReady(S.CrusaderStrike) then return true end
            if castExecute() then return true end
            if self:CastJudgement() then return true end
            if castArtOfWar() then return true end
        else
            if self:CastJudgement() then return true end
            if castExecute() then return true end
            if castReady(S.CrusaderStrike) then return true end
            if castConsecration() then return true end
            if castReady(S.DivineStorm) then return true end
            if castArtOfWar() then return true end
            if castHolyWrath() then return true end
        end

    elseif spec == "Holy" then -- SMART HEALING ENHANCED HOLY PALADIN
        if self:PaladinEmergencyTriage() then return true end
        if self:MaintainHolyPaladinBuffs(manaPercent) then return true end
        if self:PaladinSmartHeal() then return true end
        
        -- PRIORITY 3: Offensive Holy when not healing
        if self:CanUsePaladinSpell(S.HolyShock) and self:IsUsableSpell(S.HolyShock) then -- Damage Holy Shock
            if self:CastPaladinSpell(S.HolyShock, "target") then return true end
        end
        if self:CastJudgement() then return true end
        if self:CanUsePaladinSpell(S.Exorcism) and self:IsUsableSpell(S.Exorcism) and manaPercent > 25 then
            if self:CastPaladinSpell(S.Exorcism, "target") then return true end
        end
        -- Holy only spends healing mana on Consecration when the AoE value is
        -- real and the mana pool is healthy.
        if enemies >= 3 and manaPercent > 80 and self:CanUsePaladinSpell(S.Consecration) and
           self:IsUsableSpell(S.Consecration) then
             if self:CastPaladinSpell(S.Consecration, "player") then return true end
        end
        
    else -- Leveling / "None" spec
        if self:CastJudgement() then return true end -- Prioritize Judgement
        if targetHP < 20 and self:CanUsePaladinSpell(S.HammerOfWrath) and self:IsUsableSpell(S.HammerOfWrath) then
            if self:CastPaladinSpell(S.HammerOfWrath, "target") then return true end
        end
        if self:CanUsePaladinSpell(S.Exorcism) and self:IsUsableSpell(S.Exorcism) and manaPercent > 20 then
            if self:CastPaladinSpell(S.Exorcism, "target") then return true end
        end
        if enemies >= 2 and manaPercent > 45 and self:CanUsePaladinSpell(S.Consecration) and
           self:IsUsableSpell(S.Consecration) then
            if self:CastPaladinSpell(S.Consecration, "player") then return true end
        end
    end
    
    return false
end

-- UPDATED: Main rotation to include pulling logic and use new movement detection
function AC:PaladinRotation()
    -- CRITICAL: Minimal throttling for responsive rotation
    if not self:Throttle("PaladinGlobalRotation", 0.2) then
        return false -- Very fast checking for maximum DPS
    end
    
    -- Don't interrupt casts
    if UnitCastingInfo("player") or UnitChannelInfo("player") then
        return false
    end
    
    local spec = self:GetPlayerSpec()
    local level = UnitLevel("player")
    local mana = UnitPower("player", 0)
    local manaMax = UnitPowerMax("player", 0)
    local manaPercent = (manaMax > 0) and (mana / manaMax * 100) or 100 -- Handle division by zero if manaMax is 0
    local health = UnitHealth("player") / UnitHealthMax("player") * 100
    
    local enemies = self:GetEnemyCount()
    local inCombat = UnitAffectingCombat("player")
    local hasTarget = UnitExists("target") and UnitCanAttack("player", "target") and not UnitIsDeadOrGhost("target")
    
    if self.debugMode and self:Throttle("PaladinDebugOutput", 5) then -- Increased throttle to reduce spam
        local isMoving = self:IsPlayerMovingCached()
        local consecReady = self:CanUsePaladinSpell(S.Consecration) and self:IsUsableSpell(S.Consecration) and self:GetSpellCooldown(S.Consecration) == 0
        local hotrReady = self:CanUsePaladinSpell(S.HammerOfRighteous) and self:IsUsableSpell(S.HammerOfRighteous) and self:GetSpellCooldown(S.HammerOfRighteous) == 0
        local judgementCD = self:GetSpellCooldown(S.JudgementOfLight)
        PaladinDebug(string.format("L%d %s|HP:%.0f%% MP:%.0f%%|E:%d|Judge:%.1fs HotR:%s Consec:%s", 
                     level, spec, health, manaPercent, enemies, judgementCD, hotrReady and "RDY" or "CD", consecReady and "RDY" or "CD"))
    end
    
    if hasTarget and not IsCurrentSpell("Attack") then StartAttack() end
    
    -- Emergency Lifeblood (Herbalism profession ability) at 50% health
    if inCombat and self:UseLifeblood() then return true end
    
    if inCombat and not hasTarget then
        if self:FindAndSetTarget() then
             hasTarget = UnitExists("target") and UnitCanAttack("player", "target") and not UnitIsDeadOrGhost("target")
        end
    end
    
    -- Enhanced emergency response system
    if health < 30 then
        -- Use health potions in emergency
        if self.UseHealthPotion and self:UseHealthPotion(30) then
            PaladinDebug("Used health potion at " .. string.format("%.0f", health) .. "% health")
            return true
        end
        
        -- Use defensive trinkets and racials in emergency
        if self:UseTrinkets() then
            PaladinDebug("Used defensive trinket")
            return true
        end
        if self:UsePaladinRacials(false) then
            return true
        end
        
        -- Emergency healing and protection
        if health < 15 then
            if spec == "Protection" and self:CanUsePaladinSpell(S.LayOnHands) and self:IsUsableSpell(S.LayOnHands) then
                if self:CastPaladinSpellEmergency(S.LayOnHands, "player") then return true end
            elseif spec ~= "Protection" and self:CanUsePaladinSpell(S.DivineShield) and self:IsUsableSpell(S.DivineShield) then
                if self:CastPaladinSpellEmergency(S.DivineShield, "player") then return true end
            elseif self:CanUsePaladinSpell(S.LayOnHands) and self:IsUsableSpell(S.LayOnHands) then
                if self:CastPaladinSpellEmergency(S.LayOnHands, "player") then return true end
            end
        elseif health < 25 then
            if self:CanUsePaladinSpell(S.DivineProtection) and self:IsUsableSpell(S.DivineProtection) then
                if self:CastPaladinSpellEmergency(S.DivineProtection, "player") then return true end
            end
        end
    end
    
    if spec == "Protection" and level >= 16 and self:CanUsePaladinSpell(S.RighteousFury) and
       not self:HasBuff("player", S.RighteousFury) then
        if self:CastPaladinSpell(S.RighteousFury, "player") then
            PaladinDebug("Applied Righteous Fury")
            return true
        end
    end

    if self:PaladinLevelingRecovery(spec, inCombat, health, manaPercent) then return true end

    -- A healer must remain functional when no hostile target is selected. This
    -- is common immediately after a tank pulls or while the last mob dies.
    if spec == "Holy" then
        if inCombat then
            if self:PaladinEmergencyTriage() then return true end
            if self:MaintainHolyPaladinBuffs(manaPercent) then return true end
            if self:PaladinSmartHeal() then return true end
            if not hasTarget then return false end
        elseif manaPercent > 30 then
            if self:PaladinSmartHeal() then return true end
            if self:MaintainHolyPaladinBuffs(manaPercent) then return true end
        end
    end

    -- Normal blessing maintenance is out of combat; combat GCDs belong to the rotation.
    if not inCombat and self:CheckPaladinBuffs(spec) then return true end
    
    if not inCombat then
        -- OOC Buffs (Auras, Seals)
        
        -- Enhanced aura management system
        if self:ManagePaladinAuras(spec) then return true end
        
        -- Mana efficiency management (for seal switching)
        if self:ManageManaEfficiency(spec, manaPercent, inCombat) then return true end
        
        local activeSealOOC = self:GetActiveSeal()
        local oocEnemies = hasTarget and math.max(enemies, 1) or 1
        local bestSealOOC = self:GetBestAvailableSeal(spec, level, manaPercent, "ooc", oocEnemies)
        if (not activeSealOOC or ((spec == "Protection" or spec == "Retribution") and
            bestSealOOC and activeSealOOC ~= bestSealOOC)) and
           self:Throttle("SealCheckOOC", 10) then
            local bestSeal = bestSealOOC
            if bestSeal and self:CanUsePaladinSpell(bestSeal) then
                if self:CastPaladinSpell(bestSeal, "player") then 
                    PaladinDebug("Applied seal out of combat: " .. bestSeal)
                    return true 
                end
            end
        end
        
        if hasTarget and not UnitAffectingCombat("target") then
            if self:PaladinPull() then return true end
        end
        return false -- End OOC logic
    end
    
    -- In Combat
    if hasTarget and inCombat then
        -- Ensure an appropriate Seal is active. Switch Prot seals only for meaningful context changes.
        local activeSeal = self:GetActiveSeal()
        local bestSeal = self:GetBestAvailableSeal(spec, level, manaPercent, "COMBAT", enemies)
        local shouldSwitchSeal = false
        if not activeSeal then
            shouldSwitchSeal = true
        elseif spec == "Protection" and bestSeal and activeSeal ~= bestSeal then
            shouldSwitchSeal = (bestSeal == S.SealCommand and enemies >= 3) or
                               ((bestSeal == S.SealVengeance or bestSeal == S.SealCorruption) and enemies <= 2)
        elseif spec == "Retribution" and bestSeal and activeSeal ~= bestSeal then
            shouldSwitchSeal = (bestSeal == S.SealCommand and enemies >= 3) or
                               ((bestSeal == S.SealVengeance or bestSeal == S.SealCorruption) and enemies <= 2)
        end

        if shouldSwitchSeal and self:Throttle("SealCheck", 5) then
            if bestSeal and self:CanUsePaladinSpell(bestSeal) then
                if self:CastPaladinSpell(bestSeal, "player") then
                    PaladinDebug("Applied " .. bestSeal .. (activeSeal and (" replacing " .. activeSeal) or " (was missing)"))
                    return true
                end
            end
        end

        -- Enhanced in-combat management systems
        -- Utility cooldowns (Hand of Freedom/Protection)
        if self:UseUtilityCooldowns() then return true end
        
        -- Aura management (situational switching during combat)
        if self:ManagePaladinAuras(spec) then return true end
        
        -- Mana efficiency management (seal switching during combat)
        if self:ManageManaEfficiency(spec, manaPercent, inCombat) then return true end

        local targetMaxHealth = UnitHealthMax("target")
        local targetHP = targetMaxHealth > 0 and (UnitHealth("target") / targetMaxHealth * 100) or 100

        -- Main DPS rotation FIRST - tanks need to be beasts with excellent DPS
        local rotationResult = self:PaladinCombatRotation(spec, level, hasTarget, targetHP, manaPercent, enemies, inCombat)
        if rotationResult then return true end
        
        return false
    end
    
    return false
end

-- =============================================
-- FIXED BLESSING MANAGEMENT FOR PARTY MEMBERS
-- =============================================

function AC:HasAnyBlessing(unit)
    local blessingName, blessingType = GetUnitBlessing(unit)
    return blessingName ~= nil, blessingName, blessingType
end

function AC:GetPaladinBlessingRole(unit)
    if not UnitExists(unit) then return "HYBRID" end

    local _, class = UnitClass(unit)
    if UnitIsUnit(unit, "player") then
        local spec = self:GetPlayerSpec()
        if spec == "Protection" then return "TANK" end
        if spec == "Retribution" then return "PHYSICAL" end
        if spec == "Holy" then return "HEALER" end
    end

    -- WotLK cannot inspect another unit's specialization synchronously. Use
    -- explicit raid assignment and visible tank state instead of accidentally
    -- reusing the player's own spec for every party member.
    if GetPartyAssignment and GetPartyAssignment("MAINTANK", unit) then return "TANK" end
    if UnitExists("focus") and UnitIsUnit(unit, "focus") then return "TANK" end

    local tankBuffs = {"Defensive Stance", S.RighteousFury, "Bear Form", "Dire Bear Form", "Frost Presence"}
    for _, buffName in ipairs(tankBuffs) do
        if UnitHasBuffByScan(unit, buffName) then return "TANK" end
    end

    if class == "WARRIOR" or class == "ROGUE" or class == "HUNTER" or class == "DEATHKNIGHT" then
        return "PHYSICAL"
    end
    if class == "PRIEST" then return "HEALER" end
    if class == "MAGE" or class == "WARLOCK" then return "CASTER" end
    return "HYBRID"
end

function AC:GetBestBlessingForUnit(unit, level)
    if not UnitExists(unit) then return nil end
    local _, class = UnitClass(unit)
    if not class then return nil end

    local _, existingType = GetUnitBlessing(unit)
    local hasBattleShout = UnitHasBuffByScan(unit, "Battle Shout")

    -- Check if we have reagents for Greater Blessings
    local symbolOfKings = GetItemCount("Symbol of Kings") > 0 or GetItemCount(21177) > 0
    local function bestRank(greaterBlessing, regularBlessing)
        if symbolOfKings and self:CanUsePaladinSpell(greaterBlessing) then return greaterBlessing end
        return regularBlessing
    end

    local bMight = bestRank(S.GreaterBlessingOfMight, S.BlessingOfMight)
    local bWisdom = bestRank(S.GreaterBlessingOfWisdom, S.BlessingOfWisdom)
    local bKings = bestRank(S.GreaterBlessingOfKings, S.BlessingOfKings)
    local bSanctuary = bestRank(S.GreaterBlessingOfSanctuary, S.BlessingOfSanctuary)

    -- Build a priority list based on class/role
    local priorities = {}
    local role = self:GetPaladinBlessingRole(unit)

    if role == "TANK" then
        priorities = {bSanctuary, bKings, bMight, bWisdom}
    elseif role == "PHYSICAL" then
        priorities = {bMight, bKings, bWisdom}
    elseif role == "CASTER" then
        priorities = {bKings, bWisdom, bMight}
    elseif role == "HEALER" then
        priorities = {bWisdom, bKings, bMight}
    else
        priorities = {bKings, bMight, bWisdom}
    end
    
    -- Try each blessing in priority order, skipping ones they already have
    for _, blessing in ipairs(priorities) do
        if self:CanUsePaladinSpell(blessing) then
            -- Check if they already have this type of blessing
            if BlessingTypes[blessing] == existingType then
                PaladinDebug("Skipping " .. blessing .. " for " .. UnitName(unit) .. " - already has that type")
            elseif BlessingTypes[blessing] == "Might" and hasBattleShout then
                PaladinDebug("Skipping " .. blessing .. " for " .. UnitName(unit) .. " - Battle Shout covers attack power")
            else
                return blessing
            end
        end
    end
    
    -- If they have all blessing types, return nil (nothing we can give)
    PaladinDebug("No suitable blessing for " .. UnitName(unit) .. " - they have all types")
    return nil
end

function AC:CheckPaladinBuffs(spec, force) -- This is primarily for OOC party buffing
    if not force and not self:Throttle("PaladinPartyBuffCheck", 3) then return false end
    if UnitAffectingCombat("player") then return false end
    if UnitChannelInfo("player") or UnitCastingInfo("player") then return false end
    
    -- Check if on GCD
    local gcdStart, gcdDuration = GetSpellCooldown("61304") -- GCD reference spell
    if gcdStart and gcdDuration and gcdDuration > 0 then
        local gcdRemaining = gcdStart + gcdDuration - GetTime()
        if gcdRemaining > 0.1 then
            return false -- Still on GCD, wait
        end
    end
    
    local level = UnitLevel("player")
    local manaMax = UnitPowerMax("player", 0)
    local manaPercent = (manaMax > 0) and (UnitPower("player", 0) / manaMax * 100) or 100
    if manaPercent < 30 then return false end -- Lowered mana requirement for more frequent blessing
    
    -- Check blessing reagents
    local hasSymbolOfKings = GetItemCount("Symbol of Kings") > 0 or GetItemCount(21177) > 0
    
    if level >= 60 and not hasSymbolOfKings then
        if self:Throttle("ReagentWarning", 30) then
            PaladinDebug("WARNING: No Symbol of Kings - using basic blessings only")
        end
    end

    -- Build priority list: healers/tanks first, then DPS, then self
    local unitsToBuff = {}
    local selfUnit = {unit = "player", priority = (spec == "Protection" and 1 or 5)}
    
    if GetNumPartyMembers() > 0 then
        for i = 1, GetNumPartyMembers() do
            local unit = "party"..i
            if UnitExists(unit) then
                local role = 3 -- Default DPS priority
                local blessingRole = self:GetPaladinBlessingRole(unit)
                if blessingRole == "HEALER" then role = 1 end
                if blessingRole == "TANK" then role = 2 end
                table.insert(unitsToBuff, {unit = unit, priority = role})
            end
        end
    elseif GetNumRaidMembers() > 0 then
        -- In raids, only buff our group to avoid spam
        local playerGroup = 0
        for i = 1, GetNumRaidMembers() do
            if UnitIsUnit("raid"..i, "player") then
                playerGroup = select(3, GetRaidRosterInfo(i))
                break
            end
        end
        for i = 1, GetNumRaidMembers() do
            local _, _, group = GetRaidRosterInfo(i)
            if group == playerGroup then
                local unit = "raid"..i
                if UnitExists(unit) and not UnitIsUnit(unit, "player") then
                    local blessingRole = self:GetPaladinBlessingRole(unit)
                    local priority = blessingRole == "HEALER" and 1 or (blessingRole == "TANK" and 2 or 3)
                    table.insert(unitsToBuff, {unit = unit, priority = priority})
                end
            end
        end
    end
    
    -- Add self at the end
    table.insert(unitsToBuff, selfUnit)
    
    -- Sort by priority (1 = highest, 5 = lowest)
    table.sort(unitsToBuff, function(a, b) return a.priority < b.priority end)

    for _, unitData in ipairs(unitsToBuff) do
        local unit = unitData.unit
        if UnitExists(unit) and UnitIsConnected(unit) and not UnitIsDeadOrGhost(unit) then
            -- Check range properly for blessings (30 yards)
            local inRange = false
            if unit == "player" then
                inRange = true
            else
                -- Try to check with a known blessing spell
                local rangeCheckSpell = self:KnowsSpell(S.BlessingOfMight) and S.BlessingOfMight or
                                       self:KnowsSpell(S.BlessingOfWisdom) and S.BlessingOfWisdom or
                                       self:KnowsSpell(S.BlessingOfKings) and S.BlessingOfKings
                if rangeCheckSpell then
                    inRange = IsSpellInRange(rangeCheckSpell, unit) == 1
                else
                    -- Fallback to interact distance
                    inRange = CheckInteractDistance(unit, 4) -- 28 yards
                end
            end
            
            if inRange then
                local hasBlessingAlready, _ = self:HasAnyBlessing(unit)
                if spec == "Protection" and unit == "player" and
                   self:CanUsePaladinSpell(S.BlessingOfSanctuary) and
                   not UnitHasBuffByScan("player", S.BlessingOfSanctuary) and
                   not UnitHasBuffByScan("player", S.GreaterBlessingOfSanctuary) then
                    local sanctuary = (level >= 60 and (GetItemCount("Symbol of Kings") > 0 or GetItemCount(21177) > 0) and
                                       self:CanUsePaladinSpell(S.GreaterBlessingOfSanctuary)) and
                                       S.GreaterBlessingOfSanctuary or S.BlessingOfSanctuary
                    if self:IsUsableSpell(sanctuary) and self:CastBlessingOnUnit(sanctuary, unit) then
                        PaladinDebug("Applied Protection self blessing: " .. sanctuary)
                        return true
                    end
                end
                if not hasBlessingAlready then
                    local bestBlessingForUnit = self:GetBestBlessingForUnit(unit, level)
                    if bestBlessingForUnit and self:CanUsePaladinSpell(bestBlessingForUnit) then
                    -- Check if spell is actually usable (includes reagent check)
                    if self:IsUsableSpell(bestBlessingForUnit) then
                        -- Use our improved blessing function
                        if self:CastBlessingOnUnit(bestBlessingForUnit, unit) then
                            -- Schedule verification
                            local verifyFrame = CreateFrame("Frame")
                            verifyFrame.elapsed = 0
                            verifyFrame.unit = unit
                            verifyFrame.blessing = bestBlessingForUnit
                            verifyFrame:SetScript("OnUpdate", function(frame, elapsed)
                                frame.elapsed = frame.elapsed + elapsed
                                if frame.elapsed > 1.5 then  -- Wait a bit longer
                                    -- Check for ANY blessing, not just the specific one
                                    local hasAnyBless, blessName = AC:HasAnyBlessing(frame.unit)
                                    if hasAnyBless then
                                        PaladinDebug("✓ Blessing confirmed on " .. (UnitName(frame.unit) or frame.unit) .. ": " .. (blessName or "unknown"))
                                    else
                                        -- List all buffs on the unit for debugging
                                        PaladinDebug("✗ NO blessing detected on " .. (UnitName(frame.unit) or frame.unit) .. " after 1.5s")
                                        PaladinDebug("  Current buffs on " .. (UnitName(frame.unit) or frame.unit) .. ":")
                                        for i = 1, 40 do
                                            local buffName = UnitBuff(frame.unit, i)
                                            if buffName then
                                                PaladinDebug("    - " .. buffName)
                                            end
                                        end
                                    end
                                    frame:SetScript("OnUpdate", nil)
                                end
                            end)
                            return true -- Only buff one person per cycle to avoid spam
                        else
                            PaladinDebug("Failed to cast " .. bestBlessingForUnit .. " on " .. (UnitName(unit) or unit))
                            -- Don't return here - continue checking other party members
                        end
                    else
                        PaladinDebug("Blessing " .. bestBlessingForUnit .. " not usable - checking for fallback")
                        -- Try fallback to regular blessing if Greater fails (likely no reagents)
                        if bestBlessingForUnit:find("Greater") then
                            local fallbackBlessing = bestBlessingForUnit:gsub("Greater ", "")
                            if self:CanUsePaladinSpell(fallbackBlessing) and self:IsUsableSpell(fallbackBlessing) then
                                if self:CastBlessingOnUnit(fallbackBlessing, unit) then
                                    PaladinDebug("Applied " .. fallbackBlessing .. " to " .. (UnitName(unit) or unit) .. " (fallback - no reagents)")
                                    return true -- Only buff one person per cycle
                                else
                                    PaladinDebug("FAILED to cast fallback " .. fallbackBlessing .. " on " .. (UnitName(unit) or unit))
                                end
                            else
                                PaladinDebug("Fallback blessing " .. fallbackBlessing .. " also not usable")
                            end
                        end
                    end
                end
                end -- End of hasBlessingAlready check
            else
                -- Unit is out of range
                if self:Throttle("BlessingRangeWarning_" .. unit, 30) then
                    PaladinDebug((UnitName(unit) or unit) .. " is out of range for blessings")
                end
            end -- End of inRange check
        end
    end
    return false
end

-- =============================================
-- AURA MANAGEMENT SYSTEM
-- =============================================

-- Get best aura for current situation
function AC:GetBestAura(spec, inGroup, inCombat, enemies)
    local level = UnitLevel("player")
    
    -- Protection: Prioritize survivability
    if spec == "Protection" then
        -- Devotion Aura is the safe default for tanking, especially when improved.
        if self:CanUsePaladinSpell(S.DevotionAura) then
            return S.DevotionAura
        end
        if level >= 16 and self:CanUsePaladinSpell(S.RetributionAura) then
            return S.RetributionAura
        end
    
    -- Holy: Prioritize mana efficiency and casting
    elseif spec == "Holy" then
        -- Concentration Aura remains useful between pulls and avoids spending a
        -- healing GCD to correct the aura after combat begins.
        if level >= 22 and self:CanUsePaladinSpell(S.ConcentrationAura) then
            return S.ConcentrationAura
        end
        -- Devotion Aura as fallback
        if self:CanUsePaladinSpell(S.DevotionAura) then
            return S.DevotionAura
        end
    
    -- Retribution: Prioritize damage
    elseif spec == "Retribution" then
        if level >= 16 and self:CanUsePaladinSpell(S.RetributionAura) then
            return S.RetributionAura
        end
        -- Devotion Aura as fallback
        if self:CanUsePaladinSpell(S.DevotionAura) then
            return S.DevotionAura
        end
    end
    
    -- Default fallback
    if self:CanUsePaladinSpell(S.DevotionAura) then
        return S.DevotionAura
    end
    
    return nil
end

-- Manage aura uptime
function AC:ManagePaladinAuras(spec)
    if not self:Throttle("PaladinAuraManagement", 10) then return false end -- Increased throttle
    
    local inGroup = (GetNumPartyMembers() > 0 or GetNumRaidMembers() > 0)
    local inCombat = UnitAffectingCombat("player")
    local enemies = self:GetEnemyCount()
    
    local currentAura, activeAuras = GetPlayerPaladinAura()
    local hasAnyAura = currentAura ~= nil
    local bestAura = self:GetBestAura(spec, inGroup, inCombat, enemies)

    -- Do not duplicate the same aura when another paladin already supplies it.
    if bestAura and activeAuras[bestAura] then return false end

    -- Only switch auras if we have none or the spec's normal aura is wrong.
    if not hasAnyAura then
        if bestAura and self:CastPaladinSpell(bestAura, "player") then
            PaladinDebug("Activated " .. bestAura .. " (no aura was active)")
            return true
        end
    else
        if bestAura and currentAura ~= bestAura then
            -- Preserve deliberate travel/resistance choices. Otherwise Ret and
            -- Holy should not remain in Devotion Aura for an entire encounter.
            if currentAura == S.FireResistanceAura or currentAura == S.FrostResistanceAura or
               currentAura == S.ShadowResistanceAura or
               (currentAura == S.CrusaderAura and IsMounted and IsMounted()) then
                return false
            end
            if self:CastPaladinSpell(bestAura, "player") then
                PaladinDebug("Switched from " .. currentAura .. " to " .. bestAura)
                return true
            end
        end
    end
    
    return false
end

-- REMOVED: ManagePaladinThreat function - replaced by Core.lua universal system

-- =============================================
-- MANA EFFICIENCY SYSTEM
-- =============================================

-- SIMPLIFIED: Mana efficiency with less seal switching (seals last 30 minutes)
function AC:ManageManaEfficiency(spec, manaPercent, inCombat)
    if not self:Throttle("PaladinManaEfficiency", 15) then return false end -- Reduced frequency
    
    local level = UnitLevel("player")
    local hasTarget = UnitExists("target") and UnitCanAttack("player", "target")
    
    -- Use mana potions when critically low
    if manaPercent < 25 then
        if self.UseManaPotion and self:UseManaPotion(25) then
            PaladinDebug("Used mana potion at " .. string.format("%.0f", manaPercent) .. "% mana")
            return true
        end
    end
    
    -- Avoid fighting the Protection threat seal logic in combat; use Divine Plea/Judgement instead.
    if spec == "Protection" and inCombat and manaPercent < 40 and level >= 30 then
        if self:CanUsePaladinSpell(S.SealWisdom) and not self:HasBuff("player", S.SealWisdom) then
            if self:CastPaladinSpell(S.SealWisdom, "player") then
                PaladinDebug("Protection mana sustain: switched to Seal of Wisdom")
                return true
            end
        end
    end

    if spec == "Protection" and not inCombat and manaPercent < 20 and level >= 30 then
        if self:CanUsePaladinSpell(S.SealWisdom) and not self:HasBuff("player", S.SealWisdom) then
            if self:CastPaladinSpell(S.SealWisdom, "player") then
                PaladinDebug("Emergency switch to Seal of Wisdom (low mana)")
                return true
            end
        end
    end
    
    return false
end

-- =============================================
-- RACIAL ABILITIES (SIMPLIFIED)
-- =============================================

local R = {
    GiftOfNaaru = "Gift of the Naaru", 
    WarStomp = "War Stomp",          
    EveryMan = "Every Man for Himself", 
    Stoneform = "Stoneform",          
    BloodFury = "Blood Fury",         
    Berserking = "Berserking",        
    ArcaneTorrent = "Arcane Torrent"  
}

function AC:UsePaladinRacials(offensiveUsage) -- offensiveUsage determines if we want offensive or defensive racials
    offensiveUsage = offensiveUsage or false
    if not self:Throttle("PaladinRacialsUsage", 3) then return false end -- Reduced throttle for better responsiveness
    
    local race = select(2, UnitRace("player"))
    local healthPercent = UnitHealth("player") / UnitHealthMax("player") * 100
    local inCombat = UnitAffectingCombat("player")
    local enemies = self:GetEnemyCount()

    -- Offensive Racials (use during burst phases)
    if inCombat and offensiveUsage then
        if race == "Orc" and self:CanUsePaladinSpell(R.BloodFury) and self:IsUsableSpell(R.BloodFury) then
            if self:CastPaladinSpell(R.BloodFury, "player") then 
                PaladinDebug("Used Blood Fury (offensive)")
                return true 
            end
        elseif race == "Troll" and self:CanUsePaladinSpell(R.Berserking) and self:IsUsableSpell(R.Berserking) then
            if self:CastPaladinSpell(R.Berserking, "player") then 
                PaladinDebug("Used Berserking (offensive)")
                return true 
            end
        elseif race == "BloodElf" and self:CanUsePaladinSpell(R.ArcaneTorrent) and self:IsUsableSpell(R.ArcaneTorrent) and CheckInteractDistance("target", 3) then
            if self:CastPaladinSpell(R.ArcaneTorrent, "player") then 
                PaladinDebug("Used Arcane Torrent (silence + mana)")
                return true 
            end
        end
    end

    -- Defensive/Utility Racials (use when needed)
    if not offensiveUsage then
        -- Emergency defensive racials
        if healthPercent < 30 or (inCombat and (UnitIsFeared("player") or UnitIsCharmed("player"))) then
            if race == "Dwarf" and self:CanUsePaladinSpell(R.Stoneform) and self:IsUsableSpell(R.Stoneform) then
                if self:CastPaladinSpellEmergency(R.Stoneform, "player") then 
                    PaladinDebug("Used Stoneform (defensive)")
                    return true 
                end
            elseif race == "Human" and self:CanUsePaladinSpell(R.EveryMan) and self:IsUsableSpell(R.EveryMan) then
                if self:CastPaladinSpellEmergency(R.EveryMan, "player") then 
                    PaladinDebug("Used Every Man for Himself (defensive)")
                    return true 
                end
            elseif race == "Draenei" and self:CanUsePaladinSpell(R.GiftOfNaaru) and self:IsUsableSpell(R.GiftOfNaaru) and healthPercent < 60 then
                if self:CastPaladinSpellEmergency(R.GiftOfNaaru, "player") then 
                    PaladinDebug("Used Gift of the Naaru (healing)")
                    return true 
                end
            end
        end
        
        -- AoE stun for crowd control
        if inCombat and race == "Tauren" and enemies >= 2 and self:CanUsePaladinSpell(R.WarStomp) and self:IsUsableSpell(R.WarStomp) and CheckInteractDistance("target", 3) then
            if self:CastPaladinSpell(R.WarStomp, "player") then 
                PaladinDebug("Used War Stomp (AoE stun)")
                return true 
            end
        end
    end
    
    return false
end
-- (The rest of the Paladin.lua file remains the same as provided by the user)
-- ...
-- =============================================
-- TESTING AND VALIDATION FUNCTIONS
-- =============================================

-- Add the missing GetBestAvailableAttack function that was referenced in test
function AC:GetBestAvailableAttack(spec, level, manaPercent, enemies)
    -- Priority-based attack selection
    if spec == "Protection" then
        if enemies >= 1 and self:CanUsePaladinSpell(S.HammerOfRighteous) then -- HotR is good ST too if talented
            return S.HammerOfRighteous
        elseif self:CanUsePaladinSpell(S.ShieldOfRighteous) then
            return S.ShieldOfRighteous
        elseif self:CanUsePaladinSpell(S.AvengersShield) then
            return S.AvengersShield
        end
    elseif spec == "Retribution" then
        if enemies >= 3 and self:CanUsePaladinSpell(S.DivineStorm) then
            return S.DivineStorm
        elseif self:CanUsePaladinSpell(S.CrusaderStrike) then
            return S.CrusaderStrike
        end
    elseif spec == "Holy" then
        if self:CanUsePaladinSpell(S.HolyShock) then
            return S.HolyShock
        end
    end
    
    -- Fallback attacks available to all specs
    if level >= 4 then -- Judgement should always be considered
        return "CAST_JUDGEMENT" -- Signal to use CastJudgement
    end
    if self:CanUsePaladinSpell(S.Exorcism) and manaPercent > 30 then -- Lowered mana req slightly
        return S.Exorcism
    end
    
    return nil -- Auto-attack only
end

-- ENHANCED: Test function to validate movement detection
function AC:TestPaladinMovement()
    self:Print("=== PALADIN MOVEMENT TEST ===")
    local isMoving = self:IsPlayerMoving()
    local isMovingCached = self:IsPlayerMovingCached()
    local speed = GetUnitSpeed and GetUnitSpeed("player") or "N/A"
    self:Print("IsPlayerMoving(): " .. tostring(isMoving) .. ", Cached: " .. tostring(isMovingCached) .. ", Speed: " .. tostring(speed))
    if UnitExists("target") and UnitCanAttack("player", "target") then
        self:Print("Testing Consecration cast...")
        local result = self:CastPaladinSpell(S.Consecration, "player")
        self:Print("  Consecration cast result: " .. tostring(result) .. (isMoving and " (Expected: false due to movement)" or " (Expected: depends on CD/mana)"))
    else self:Print("Need a valid target to test Consecration") end
    self:Print("==============================")
end

-- Test function for the judgement spell system
function AC:TestPaladinSpells()
    local level = UnitLevel("player")
    self:Print("=== PALADIN SPELL TEST (Level " .. level .. ") ===")
    local judgementSpells = {S.JudgementOfLight, S.JudgementOfWisdom, S.JudgementOfJustice}
    self:Print("Judgements:")
    for _, spell in ipairs(judgementSpells) do 
        if spell then 
            self:Print(string.format("  %s: K=%s, U=%s, CD=%.1f", spell, tostring(self:KnowsSpell(spell)), tostring(self:CanUsePaladinSpell(spell)), self:GetSpellCooldown(spell))) 
        end 
    end
    local sealSpells = {S.SealRighteousness, S.SealLight, S.SealWisdom, S.SealJustice, S.SealCommand, S.SealVengeance, S.SealCorruption}
    self:Print("Seals:")
    for _, spell in ipairs(sealSpells) do if spell then self:Print(string.format("  %s: K=%s, U=%s", spell, tostring(self:KnowsSpell(spell)), tostring(self:CanUsePaladinSpell(spell)))) end end
    self:Print("Active Seal: " .. (self:GetActiveSeal() or "None"))
    self:Print("Best Attack: " .. (self:GetBestAvailableAttack(self:GetPlayerSpec(), level, 100, 1) or "Auto-attack"))
    self:Print("Blessing Logic: PhysDPS->Might, Casters->Kings, Healers->Wisdom, Hybrids->Kings")
    if GetNumPartyMembers() > 0 or GetNumRaidMembers() > 0 then self:Print("In group - check /ac paladin party for details") else self:Print("Not in group for party blessing test.") end
    self:Print("===========================================")
end

-- Validation function
function AC:ValidatePaladinSetup()
    local issues = {}
    local level = UnitLevel("player")
    if level >= 4 and not self:KnowsSpell(S.JudgementOfLight) then table.insert(issues, "Judgement of Light not learned (L4+)") end
    if level >= 12 and not self:KnowsSpell(S.JudgementOfWisdom) then table.insert(issues, "Judgement of Wisdom not learned (L12+)") end
    if level >= 20 and not self:KnowsSpell(S.Exorcism) then table.insert(issues, "Exorcism not learned (L20+)") end
    if level >= 20 and not self:KnowsSpell(S.Consecration) then table.insert(issues, "Consecration not learned (L20+)") end
    if not pcall(function() return self:CanUsePaladinSpell(S.Exorcism) end) then table.insert(issues, "CanUsePaladinSpell check failed") end
    if not pcall(function() return self:IsPlayerMoving() end) then table.insert(issues, "IsPlayerMoving check failed") end
    
    if #issues > 0 then self:Print("Paladin validation issues:"); for _, issue in ipairs(issues) do self:Print("  - " .. issue) end
    else self:Print("Paladin setup validation passed!") end
    return #issues == 0
end


-- =============================================
-- ENHANCED SLASH COMMANDS
-- =============================================

function AC:SetupPaladinSlashCommands()
    local originalHandler = SlashCmdList["AZEROCOMBAT"]
    SlashCmdList["AZEROCOMBAT"] = function(msg) -- Ensure this redefinition is safe and chains if originalHandler is used
        local args = {strsplit(" ", msg)}
        local command = args[1] and args[1]:lower() or ""
        local subcommand = args[2] and args[2]:lower() or ""
        
        if command == "paladin" then
            if subcommand == "test" then self:TestPaladinSpells()
            elseif subcommand == "seals" then self:TestSealAvailability()
            elseif subcommand == "movement" or subcommand == "move" then self:TestPaladinMovement()
            elseif subcommand == "debug" then
                local spec, lvl, mp = self:GetPlayerSpec(), UnitLevel("player"), (UnitPowerMax("player",0)>0 and math.floor(UnitPower("player",0)/UnitPowerMax("player",0)*100) or 100)
                self:Print(string.format("PALADIN DEBUG | Lvl:%d Spec:%s MP:%d%% Moving:%s Seal:%s Blessing:%s", lvl, spec, mp, tostring(self:IsPlayerMovingCached()), self:GetActiveSeal() or "N", self:HasAnyBlessing("player") and "Y" or "N"))
                self:Print(" Target: " .. (UnitExists("target") and UnitName("target") or "None"))
            elseif subcommand == "rotation" then self:Print("Rotation Test: " .. (self:PaladinRotation() and "Action" or "No Action"))
            elseif subcommand == "judgement" then 
                if not UnitExists("target") then self:Print("Need target for Judgement test."); return; end
                self:Print("Judgement Test: " .. (self:CastJudgement() and "OK" or "Fail"))
            elseif subcommand == "bless" then
                self:Print("Forcing blessing check...")
                local result = self:CheckPaladinBuffs(self:GetPlayerSpec(), true)
                self:Print("Blessing Test: " .. (result and "Applied blessing to someone" or "Everyone has blessings or all out of range"))
            elseif subcommand == "party" then
                self:Print("PARTY BLESSING STATUS:")
                local inGroup = GetNumPartyMembers() > 0 or GetNumRaidMembers() > 0
                self:Print(" InGroup: " .. tostring(inGroup))
                if inGroup then
                    for i = 1, math.max(GetNumPartyMembers(), GetNumRaidMembers()) do
                        local unit = GetNumRaidMembers() > 0 and "raid"..i or "party"..i
                        if UnitExists(unit) then
                             local name, class, hB, b, bestB, iR, conn, dead = UnitName(unit) or unit, select(2,UnitClass(unit)), self:HasAnyBlessing(unit), "None", self:GetBestBlessingForUnit(unit, UnitLevel("player")), CheckInteractDistance(unit,4) or UnitInRange(unit), UnitIsConnected(unit), UnitIsDeadOrGhost(unit)
                             if hB then _, b = self:HasAnyBlessing(unit) end
                             self:Print(string.format("  %s(%s) C:%s D:%s R:%s | Has:%s(%s) Best:%s", name, class or "?",tostring(conn),tostring(dead),tostring(iR),tostring(hB),b or "N",bestB or "N"))
                        end
                    end
                end
            elseif subcommand == "validate" then self:ValidatePaladinSetup()
            elseif subcommand == "reagents" then
                local symbolOfKings = GetItemCount(21177)
                self:Print("BLESSING REAGENTS:")
                self:Print(" Symbol of Kings: " .. symbolOfKings)
                self:Print(" Can use Greater Blessings: " .. tostring(symbolOfKings > 0))
            elseif subcommand == "testbless" then
                -- Test blessing on target
                if not UnitExists("target") then
                    self:Print("No target selected")
                    return
                end
                local targetName = UnitName("target")
                self:Print("Testing blessing on " .. targetName)
                
                -- Try different blessing methods
                local testBlessing = self:CanUsePaladinSpell(S.BlessingOfWisdom) and S.BlessingOfWisdom or S.BlessingOfMight
                
                -- Method 1: Direct CastBlessingOnUnit
                if self:CastBlessingOnUnit(testBlessing, "target") then
                    self:Print("SUCCESS: Cast " .. testBlessing .. " using CastBlessingOnUnit")
                else
                    self:Print("FAILED: CastBlessingOnUnit method")
                end
                
                -- Check after delay
                local checkFrame = CreateFrame("Frame")
                checkFrame.elapsed = 0
                checkFrame:SetScript("OnUpdate", function(frame, elapsed)
                    frame.elapsed = frame.elapsed + elapsed
                    if frame.elapsed > 1.5 then
                        if AC:HasBuff("target", testBlessing) then
                            AC:Print("✓ Blessing confirmed on target!")
                        else
                            AC:Print("✗ Blessing NOT detected on target after 1.5s")
                        end
                        frame:SetScript("OnUpdate", nil)
                    end
                end)
            else self:Print("Paladin: test, seals, movement, debug, rotation, judgement, bless, party, validate, reagents, testbless") end
        else
            if originalHandler then originalHandler(msg) else AC:Print("Original /ac handler not found for: " .. msg) end
        end
    end
end

-- =============================================
-- INITIALIZATION
-- =============================================

function AC:InitPaladinRotations()
    self.rotations = self.rotations or {}
    if not self.rotations["PALADIN"] then self.rotations["PALADIN"] = {} end
    
    self.rotations["PALADIN"]["Holy"] = function(s) s:PaladinRotation() end
    self.rotations["PALADIN"]["Protection"] = function(s) s:PaladinRotation() end
    self.rotations["PALADIN"]["Retribution"] = function(s) s:PaladinRotation() end
    self.rotations["PALADIN"]["None"] = function(s) s:PaladinRotation() end
    
    self.CheckPaladinBuffs = AC.CheckPaladinBuffs -- Ensure it's assigned for core to call if needed
    
    self:Print("Paladin WotLK 3.3.5a rotations initialized")
end

-- =============================================
-- FINAL SETUP
-- =============================================
AC:SetupPaladinSlashCommands()

if AC.GetPlayerClass and AC:GetPlayerClass() == "PALADIN" then
    local validationFrame = CreateFrame("Frame")
    validationFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    validationFrame:SetScript("OnEvent", function(self, event)
        if event == "PLAYER_ENTERING_WORLD" then
            -- Reverted to WotLK compatible timer method
            local delayFrame = CreateFrame("Frame")
            local elapsedTime = 0
            delayFrame:SetScript("OnUpdate", function(self_delay, elapsed) -- Renamed 'self' to 'self_delay' to avoid conflict
                elapsedTime = elapsedTime + elapsed
                if elapsedTime >= 3 then -- 3 second delay
                    if AC.ValidatePaladinSetup then 
                        AC:ValidatePaladinSetup() 
                    end
                    delayFrame:SetScript("OnUpdate", nil) -- Stop the update script
                end
            end)
            validationFrame:UnregisterEvent("PLAYER_ENTERING_WORLD") -- Unregister after first fire
        end
    end)
end

-- AzeroCombat: Death Knight Rotations (COMPLETE REWRITE - WotLK 3.3.5a Research-Based)
-- Fully optimized based on WotLK 3.3.5a guide research for AzerothCore
local AddonName, AC = ...

local S = {
    -- Blood Abilities (Tank Focus)
    BloodStrike = "Blood Strike",
    BloodBoil = "Blood Boil", 
    HeartStrike = "Heart Strike",
    DeathStrike = "Death Strike",
    RuneTap = "Rune Tap",
    VampiricBlood = "Vampiric Blood",
    DancingRuneWeapon = "Dancing Rune Weapon",
    BloodTap = "Blood Tap",
    MarkOfBlood = "Mark of Blood",
    Hysteria = "Hysteria",
    
    -- Frost Abilities (DPS Focus)
    IcyTouch = "Icy Touch",
    FrostStrike = "Frost Strike",
    Obliterate = "Obliterate",
    HowlingBlast = "Howling Blast",
    UnbreakableArmor = "Unbreakable Armor",
    MindFreeze = "Mind Freeze",
    Strangulate = "Strangulate",
    ChainsOfIce = "Chains of Ice",
    
    -- Unholy Abilities (DPS/Pet Focus)
    PlagueStrike = "Plague Strike",
    DeathCoil = "Death Coil",
    ScourgeStrike = "Scourge Strike",
    DeathAndDecay = "Death and Decay",
    SummonGargoyle = "Summon Gargoyle",
    ArmyOfTheDead = "Army of the Dead",
    BoneShield = "Bone Shield",
    AntiMagicShell = "Anti-Magic Shell",
    
    -- Shared Abilities
    DeathGrip = "Death Grip",
    DarkCommand = "Dark Command",
    DeathPact = "Death Pact",
    IceboundFortitude = "Icebound Fortitude",
    EmpowerRuneWeapon = "Empower Rune Weapon",
    BloodPresence = "Blood Presence",
    FrostPresence = "Frost Presence",
    UnholyPresence = "Unholy Presence",
    RaiseDead = "Raise Dead",
    HornOfWinter = "Horn of Winter",
    Pestilence = "Pestilence",
    RuneStrike = "Rune Strike",
    
    -- Diseases
    BloodPlague = "Blood Plague",
    FrostFever = "Frost Fever",
    
    -- Procs & Buffs
    RimeProc = "Freezing Fog",
    KillingMachine = "Killing Machine",
    Rime = "Rime",
    
    -- Additional important procs
    SuddenDoom = "Sudden Doom",
    
    -- Racials
    BloodFury = "Blood Fury",
    Berserking = "Berserking",
    ArcaneTorrent = "Arcane Torrent",
    WillOfTheForsaken = "Will of the Forsaken",
    Stoneform = "Stoneform",
    GiftOfTheNaaru = "Gift of the Naaru",
    WarStomp = "War Stomp",
}

-- Debug function
local function DeathKnightDebug(msg)
    if AC.debugMode then
        AC:Debug("|cFFC41F3BDeathKnight:|r " .. tostring(msg))
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

-- =============================================
-- RESEARCH-BASED RUNE MANAGEMENT SYSTEM
-- =============================================

function AC:GetRuneInfo(runeSlot)
    local start, duration, runeReady = GetRuneCooldown(runeSlot)
    local runeType = GetRuneType(runeSlot)
    local timeLeft = runeReady and 0 or math.max(0, (start or 0) + (duration or 0) - GetTime())
    return runeType, runeReady, timeLeft
end

function AC:GetRuneCount(runeType)
    local count = 0
    for i = 1, 6 do
        local currentRuneType, runeReady = self:GetRuneInfo(i)
        if runeReady and (currentRuneType == runeType or runeType == 0) then
            count = count + 1
        end
    end
    return count
end

function AC:GetBloodRunes() return self:GetRuneCount(1) end
function AC:GetFrostRunes() return self:GetRuneCount(2) end
function AC:GetUnholyRunes() return self:GetRuneCount(3) end
function AC:GetDeathRunes() return self:GetRuneCount(4) end
function AC:GetTotalRunes() return self:GetRuneCount(0) end

-- Get available runes (ready to use)
function AC:GetAvailableRunes()
    local count = 0
    for i = 1, 6 do
        local _, runeReady = self:GetRuneInfo(i)
        if runeReady then
            count = count + 1
        end
    end
    return count
end

function AC:HasRuneFor(runeType)
    return self:GetRuneCount(runeType) > 0 or self:GetDeathRunes() > 0
end

function AC:HasRunesForFUAbility()
    local frost = self:GetFrostRunes()
    local unholy = self:GetUnholyRunes()
    local death = self:GetDeathRunes()
    return frost + unholy + death >= 2 and frost + death >= 1 and unholy + death >= 1
end

-- RESEARCH-BASED: Smart rune pooling
function AC:ShouldPoolRunes(nextAbility)
    local totalRunes = self:GetTotalRunes()
    
    -- Never pool if we have 4+ runes (waste prevention)
    if totalRunes >= 4 then return false end
    
    -- Never pool if we have 0 runes 
    if totalRunes == 0 then return false end
    
    -- Pool for high-priority abilities
    if nextAbility == "Obliterate" or nextAbility == "ScourgeStrike" then
        local frostRunes = self:GetFrostRunes()
        local unholyRunes = self:GetUnholyRunes()
        local deathRunes = self:GetDeathRunes()
        
        -- Need F+U runes or 2 death runes
        if (frostRunes == 0 or unholyRunes == 0) and deathRunes < 2 then
            return totalRunes >= 2 -- Only pool if we have some runes
        end
    end
    
    return false
end

-- =============================================
-- RESEARCH-BASED PRESENCE MANAGEMENT
-- =============================================

function AC:GetCurrentPresence()
    if self:HasBuff("player", S.BloodPresence) then return "Blood"
    elseif self:HasBuff("player", S.FrostPresence) then return "Frost"
    elseif self:HasBuff("player", S.UnholyPresence) then return "Unholy"
    else return "None" end
end

function AC:SwitchToPresence(presence)
    local currentPresence = self:GetCurrentPresence()
    if currentPresence == presence then return false end
    
    if presence == "Blood" and self:IsUsableSpell(S.BloodPresence) then
        if not self:CastSpell(S.BloodPresence, "player") then return false end
        DeathKnightDebug("Switching to Blood Presence")
        return true
    elseif presence == "Frost" and self:IsUsableSpell(S.FrostPresence) then
        if not self:CastSpell(S.FrostPresence, "player") then return false end
        DeathKnightDebug("Switching to Frost Presence")
        return true
    elseif presence == "Unholy" and self:IsUsableSpell(S.UnholyPresence) then
        if not self:CastSpell(S.UnholyPresence, "player") then return false end
        DeathKnightDebug("Switching to Unholy Presence")
        return true
    end
    return false
end

-- =============================================
-- RESEARCH-BASED DISEASE MANAGEMENT
-- =============================================

function AC:BothDiseasesUp(unit)
    unit = unit or "target"
    local hasBloodPlague = self:HasDebuff(unit, S.BloodPlague)
    local hasFrostFever = self:HasDebuff(unit, S.FrostFever)
    return hasBloodPlague and hasFrostFever
end

function AC:ShouldRefreshDiseases(unit)
    unit = unit or "target"
    if not UnitExists(unit) or UnitIsDeadOrGhost(unit) then return false end
    
    local targetHP = self:GetTargetHealthPercent(unit)
    local complexity = self:GetRotationComplexity()
    
    -- Leveling-friendly: Always apply diseases for basic rotations
    if complexity == "BASIC" or complexity == "SIMPLE" then
        if not self:HasDebuff(unit, S.FrostFever) then return "IcyTouch" end
        if not self:HasDebuff(unit, S.BloodPlague) then return "PlagueStrike" end
        return false
    end
    
    -- Do not spend two runes refreshing diseases on a target about to die.
    if targetHP < 20 then return false end
    
    local bloodTime = self:DebuffTimeRemaining(unit, S.BloodPlague) or 0
    local frostTime = self:DebuffTimeRemaining(unit, S.FrostFever) or 0
    
    -- WotLK has no Pandemic carry-over. Refresh only at expiry instead of
    -- clipping several ticks from both diseases.
    if not self:HasDebuff(unit, S.FrostFever) then
        return "IcyTouch"
    elseif not self:HasDebuff(unit, S.BloodPlague) then
        return "PlagueStrike"
    end
    
    if frostTime <= 0.3 then
        return "IcyTouch"
    elseif bloodTime <= 0.3 then
        return "PlagueStrike"
    end
    
    return false
end


function AC:ShouldSpreadDeathKnightDiseases(unit)
    unit = unit or "target"
    if not self:ShouldUseMultiTarget(2) or not self:BothDiseasesUp(unit) then return false end
    local guid = UnitGUID(unit)
    if not guid then return false end
    self.dkDiseaseSpreadTimes = self.dkDiseaseSpreadTimes or {}
    return GetTime() - (self.dkDiseaseSpreadTimes[guid] or 0) >= 12
end

function AC:MarkDeathKnightDiseasesSpread(unit)
    local guid = UnitGUID(unit or "target")
    if not guid then return end
    self.dkDiseaseSpreadTimes = self.dkDiseaseSpreadTimes or {}
    self.dkDiseaseSpreadTimes[guid] = GetTime()
end

function AC:CastDeathKnightGroundAOE(spellName)
    if self:IsChanneling() or self:IsPlayerMoving() or not self:IsUsableSpell(spellName) then
        return false
    end
    return self:SafeCastGroundAOE(spellName)
end

-- =============================================
-- ENHANCED UNHOLY ROTATION WITH GARGOYLE
-- =============================================

function AC:UnholyGargoyleBurstRotation()
    -- Talent/learned-spell gates make this safe for leveling Unholy builds too.
    if not self:ShouldUseAdvancedFeatures() then
        return false
    end
    
    local combatPhase = self:GetCombatPhase()
    local hasGargoyle = self:IsSpellAvailableAndKnown(S.SummonGargoyle)
    local hasERW = self:IsSpellAvailableAndKnown(S.EmpowerRuneWeapon, 55)
    
    -- Only in opener or burst phase
    if combatPhase ~= self.CombatPhases.OPENER and combatPhase ~= self.CombatPhases.BURST then
        return false
    end
    
    if not hasGargoyle then return false end

    local classification = UnitClassification("target")
    local worthyTarget = classification == "elite" or classification == "rareelite" or
                         classification == "worldboss" or UnitHealth("target") > 100000
    if not worthyTarget then return false end
    
    -- Check if we have both diseases up (prerequisite)
    if not self:BothDiseasesUp("target") then return false end
    
    if not self:HasTrackedProc("GargoyleBurst") then
        -- Start the Gargoyle burst sequence
        if self:IsUsableSpell(S.SummonGargoyle) and self:GetSpellCooldown(S.SummonGargoyle) == 0 then
            if not self:CastSpell(S.SummonGargoyle, "target") then return false end
            self:TrackProc("GargoyleBurst", 30) -- Track the burst window
            DeathKnightDebug("UNHOLY: Starting Gargoyle Burst Sequence")
            return true
        end
    end
    
    -- If gargoyle is active, use ERW immediately
    if self:HasTrackedProc("GargoyleBurst") and self:GetProcTimeRemaining("GargoyleBurst") > 25 then
        if hasERW and self:IsUsableSpell(S.EmpowerRuneWeapon) then
            if not self:CastSpell(S.EmpowerRuneWeapon, "player") then return false end
            DeathKnightDebug("UNHOLY: Empower Rune Weapon during Gargoyle")
            return true
        end
    end
    
    return false
end

-- =============================================
-- RESEARCH-BASED BLOOD DK ROTATION (TANK)
-- =============================================

function AC:BloodDeathKnightRotation()
    -- Initialize threat tracking variables for universal system
    self.expectedThreatTargets = self.expectedThreatTargets or {}
    self.lastTauntTime = self.lastTauntTime or 0
    self.lastTauntTarget = self.lastTauntTarget or ""
    
    local runicPower = UnitPower("player", 6)
    local health = self:GetPlayerHealthPercent()
    local enemies = self:GetEnemyCount()
    local hasTarget = UnitExists("target") and UnitCanAttack("player", "target") and not UnitIsDeadOrGhost("target")
    
    local tankMode = IsInGroup() and self:KnowsSpell(S.FrostPresence)
    local desiredPresence = tankMode and "Frost" or "Blood"
    if self:GetCurrentPresence() ~= desiredPresence then
        if self:SwitchToPresence(desiredPresence) then
            DeathKnightDebug("BLOOD: Switching to " .. desiredPresence .. " Presence")
            return true
        end
    end
    
    if not hasTarget then return false end
    StartAttack()

    if tankMode and self:HandleTankTargeting() then return true end
    
    -- Emergency defensives
    if health < 30 then
        if self:KnowsSpell(S.VampiricBlood) and self:IsUsableSpell(S.VampiricBlood) then
            if not self:CastSpell(S.VampiricBlood, "player") then return false end
            DeathKnightDebug("BLOOD: Vampiric Blood (emergency)")
            return true
        end
        if self:IsUsableSpell(S.IceboundFortitude) then
            if not self:CastSpell(S.IceboundFortitude, "player") then return false end
            DeathKnightDebug("BLOOD: Emergency Icebound Fortitude")
            return true
        end
        if UnitExists("pet") and self:IsUsableSpell(S.DeathPact) then
            if not self:CastSpell(S.DeathPact, "player") then return false end
            DeathKnightDebug("BLOOD: Emergency Death Pact")
            return true
        end
    end

    if health < 65 and self:HasRuneFor(1) and self:IsUsableSpell(S.RuneTap) then
        if not self:CastSpell(S.RuneTap, "player") then return false end
        DeathKnightDebug("BLOOD: Rune Tap")
        return true
    end
    
    -- Maintain both diseases without clipping their final ticks.
    local hasBloodPlague = self:HasDebuff("target", S.BloodPlague)
    local hasFrostFever = self:HasDebuff("target", S.FrostFever)
    local refreshDisease = self:ShouldRefreshDiseases("target")
    
    -- Refresh diseases using the shared disease timing helper.
    if refreshDisease == "IcyTouch" and self:HasRuneFor(2) and self:IsUsableSpell(S.IcyTouch) then
        if not self:CastSpell(S.IcyTouch, "target") then return false end
        DeathKnightDebug("BLOOD: Icy Touch (disease refresh)")
        return true
    end
    
    if refreshDisease == "PlagueStrike" and self:HasRuneFor(3) and self:IsUsableSpell(S.PlagueStrike) then
        if not self:CastSpell(S.PlagueStrike, "target") then return false end
        DeathKnightDebug("BLOOD: Plague Strike (disease refresh)")
        return true
    end
    
    -- Apply/refresh Frost Fever first (Icy Touch = massive threat)
    if not hasFrostFever and self:HasRuneFor(2) and self:IsUsableSpell(S.IcyTouch) then
        if not self:CastSpell(S.IcyTouch, "target") then return false end
        DeathKnightDebug("BLOOD: Icy Touch (MASSIVE THREAT)")
        return true
    end
    
    -- Apply Blood Plague  
    if not hasBloodPlague and self:HasRuneFor(3) and self:IsUsableSpell(S.PlagueStrike) then
        if not self:CastSpell(S.PlagueStrike, "target") then return false end
        DeathKnightDebug("BLOOD: Plague Strike (Blood Plague)")
        return true
    end

    -- Rune Strike is reactive and only queues after a dodge/parry. Queue it
    -- promptly so a normal rune ability does not consume the next decision first.
    if tankMode and runicPower >= 20 and self:IsUsableSpell(S.RuneStrike) then
        if not self:CastSpell(S.RuneStrike, "target") then return false end
        DeathKnightDebug("BLOOD: Rune Strike (threat)")
        return true
    end
    
    -- AoE: Spread diseases to multiple targets
    if self:ShouldUseMultiTarget(3, enemies) and hasBloodPlague and hasFrostFever then
        if self:ShouldSpreadDeathKnightDiseases("target") and self:IsUsableSpell(S.Pestilence) then
            if not self:CastSpell(S.Pestilence, "target") then return false end
            self:MarkDeathKnightDiseasesSpread("target")
            DeathKnightDebug("BLOOD: Pestilence (spread diseases)")
            return true
        end
        
        -- Death and Decay for AoE threat establishment
        if self:CastDeathKnightGroundAOE(S.DeathAndDecay) then
            DeathKnightDebug("BLOOD: Death and Decay (AoE threat)")
            return true
        end
        
        -- Blood Boil for AoE with diseases
        if self:HasRuneFor(1) and self:IsUsableSpell(S.BloodBoil) then
            if not self:CastSpell(S.BloodBoil, "player") then return false end
            DeathKnightDebug("BLOOD: Blood Boil (AoE)")
            return true
        end
    end
    
    -- Death Strike for healing (priority when low health)
    if health < 70 and self:IsUsableSpell(S.DeathStrike) then
        if self:HasRunesForFUAbility() then
            if not self:CastSpell(S.DeathStrike, "target") then return false end
            DeathKnightDebug("BLOOD: Death Strike (heal + threat)")
            return true
        end
    end
    
    -- RESEARCH: Optimal threat rotation IT-PS-HS-DS pattern
    -- Heart Strike with diseases = excellent threat
    if hasBloodPlague and hasFrostFever and self:HasRuneFor(1) then
        if self:KnowsSpell(S.HeartStrike) and self:IsUsableSpell(S.HeartStrike) then
            if not self:CastSpell(S.HeartStrike, "target") then return false end
            DeathKnightDebug("BLOOD: Heart Strike (main threat)")
            return true
        end
    end
    
    -- Blood Strike as blood rune filler
    if self:HasRuneFor(1) and self:IsUsableSpell(S.BloodStrike) then
        if not self:CastSpell(S.BloodStrike, "target") then return false end
        DeathKnightDebug("BLOOD: Blood Strike")
        return true
    end
    
    -- Sudden Doom makes Death Coil free, so consume it even below 40 RP.
    if self:HasBuff("player", S.SuddenDoom) and self:IsUsableSpell(S.DeathCoil) then
        if not self:CastSpell(S.DeathCoil, "target") then return false end
        DeathKnightDebug("BLOOD: Death Coil (Sudden Doom)")
        return true
    end

    -- Death Coil cannot heal a living DK unless Lichborne is active.
    if runicPower >= 40 and self:IsUsableSpell(S.DeathCoil) then
        if not self:CastSpell(S.DeathCoil, "target") then return false end
        DeathKnightDebug("BLOOD: Death Coil")
        return true
    end
    
    -- Resource generation when runes are down
    if runicPower < 30 and self:IsUsableSpell(S.HornOfWinter) then
        if not self:CastSpell(S.HornOfWinter, "player") then return false end
        DeathKnightDebug("BLOOD: Horn of Winter (RP generation)")
        return true
    end
    
    return false
end

-- =============================================
-- RESEARCH-BASED FROST DK ROTATION (DPS)
-- =============================================

function AC:FrostDeathKnightRotation()
    local runicPower = UnitPower("player", 6)
    local health = self:GetPlayerHealthPercent()
    local enemies = self:GetEnemyCount()
    local hasTarget = UnitExists("target") and UnitCanAttack("player", "target") and not UnitIsDeadOrGhost("target")
    
    -- Blood Presence's 15% damage bonus is the standard Frost DPS presence.
    if self:GetCurrentPresence() ~= "Blood" then
        if self:SwitchToPresence("Blood") then
            DeathKnightDebug("FROST: Switching to Blood Presence")
            return true
        end
    end
    
    if not hasTarget then return false end
    StartAttack()
    
    -- Emergency defensives
    if health < 30 then
        if self:IsUsableSpell(S.IceboundFortitude) then
            if not self:CastSpell(S.IceboundFortitude, "player") then return false end
            DeathKnightDebug("FROST: Emergency Icebound Fortitude")
            return true
        end
    end
    
    -- RESEARCH: Disease priority - ALWAYS maintain both diseases first
    local hasBloodPlague = self:HasDebuff("target", S.BloodPlague)
    local hasFrostFever = self:HasDebuff("target", S.FrostFever)
    
    -- Apply/refresh diseases using the shared disease timing helper.
    local refreshDisease = self:ShouldRefreshDiseases("target")
    if refreshDisease == "IcyTouch" and self:HasRuneFor(2) and self:IsUsableSpell(S.IcyTouch) then
        if not self:CastSpell(S.IcyTouch, "target") then return false end
        DeathKnightDebug("FROST: Icy Touch (disease refresh)")
        return true
    end
    
    if refreshDisease == "PlagueStrike" and self:HasRuneFor(3) and self:IsUsableSpell(S.PlagueStrike) then
        if not self:CastSpell(S.PlagueStrike, "target") then return false end
        DeathKnightDebug("FROST: Plague Strike (disease refresh)")
        return true
    end
    
    -- Apply Icy Touch first (Frost Fever)
    if not hasFrostFever and self:HasRuneFor(2) and self:IsUsableSpell(S.IcyTouch) then
        if not self:CastSpell(S.IcyTouch, "target") then return false end
        DeathKnightDebug("FROST: Icy Touch (Frost Fever)")
        return true
    end
    
    -- Apply Plague Strike second (Blood Plague)
    if not hasBloodPlague and self:HasRuneFor(3) and self:IsUsableSpell(S.PlagueStrike) then
        if not self:CastSpell(S.PlagueStrike, "target") then return false end
        DeathKnightDebug("FROST: Plague Strike (Blood Plague)")
        return true
    end
    
    local hasRime = self:HasBuff("player", S.RimeProc) or self:HasBuff("player", S.Rime)
    local hasKillingMachine = self:HasBuff("player", S.KillingMachine)
    local useAOE = self:ShouldUseMultiTarget(3, enemies)

    -- Killing Machine only affects Icy Touch, Howling Blast and Frost Strike;
    -- it does not increase Obliterate's critical chance in WotLK.
    if useAOE and hasKillingMachine and hasRime and self:IsUsableSpell(S.HowlingBlast) then
        if not self:CastSpell(S.HowlingBlast, "target") then return false end
        DeathKnightDebug("FROST: Howling Blast (Rime + Killing Machine)")
        return true
    end
    if hasKillingMachine and runicPower >= 40 and self:IsUsableSpell(S.FrostStrike) then
        if not self:CastSpell(S.FrostStrike, "target") then return false end
        DeathKnightDebug("FROST: Frost Strike (Killing Machine)")
        return true
    end
    if hasRime and self:IsUsableSpell(S.HowlingBlast) then
        if not self:CastSpell(S.HowlingBlast, "target") then return false end
        DeathKnightDebug("FROST: Howling Blast (Rime)")
        return true
    end

    -- Avoid capping RP before spending another pair of runes.
    if runicPower >= 90 and self:IsUsableSpell(S.FrostStrike) then
        if not self:CastSpell(S.FrostStrike, "target") then return false end
        DeathKnightDebug("FROST: Frost Strike (RP cap prevention)")
        return true
    end

    -- AoE rotation (3+ enemies)
    if useAOE then
        -- Spread diseases first
        if self:ShouldSpreadDeathKnightDiseases("target") and self:IsUsableSpell(S.Pestilence) then
            if not self:CastSpell(S.Pestilence, "target") then return false end
            self:MarkDeathKnightDiseasesSpread("target")
            DeathKnightDebug("FROST: Pestilence (spread diseases)")
            return true
        end
        
        -- Howling Blast for AoE (even without Rime in AoE situations)
        if self:HasRuneFor(2) and self:IsUsableSpell(S.HowlingBlast) then
            if not self:CastSpell(S.HowlingBlast, "target") then return false end
            DeathKnightDebug("FROST: Howling Blast (AoE)")
            return true
        end
        
        -- Death and Decay for sustained AoE
        if self:CastDeathKnightGroundAOE(S.DeathAndDecay) then
            DeathKnightDebug("FROST: Death and Decay (AoE)")
            return true
        end

        if self:GetBloodRunes() > 0 and self:IsUsableSpell(S.BloodBoil) then
            if not self:CastSpell(S.BloodBoil, "player") then return false end
            DeathKnightDebug("FROST: Blood Boil (AoE)")
            return true
        end
    end
    
    -- RESEARCH: Optimal single target rotation (diseases > obliterate spam > blood strike)
    if not useAOE then
        -- RULE: Use Frost and Unholy runes on Obliterate (highest DPS)
        if hasBloodPlague and hasFrostFever and self:KnowsSpell(S.Obliterate) and self:IsUsableSpell(S.Obliterate) then
            if self:HasRunesForFUAbility() then
                if not self:CastSpell(S.Obliterate, "target") then return false end
                DeathKnightDebug("FROST: Obliterate (main DPS)")
                return true
            end
        end
        
        -- Blood Strike for death rune conversion and rune usage priority
        if self:GetBloodRunes() > 0 and self:IsUsableSpell(S.BloodStrike) then
            if not self:CastSpell(S.BloodStrike, "target") then return false end
            DeathKnightDebug("FROST: Blood Strike (death rune conversion)")
            return true
        end
    end
    
    -- RESEARCH: Frost Strike priority for runic power (main RP spender)
    if runicPower >= 40 and self:IsUsableSpell(S.FrostStrike) then
        if not self:CastSpell(S.FrostStrike, "target") then return false end
        DeathKnightDebug("FROST: Frost Strike")
        return true
    end
    
    -- Death Coil is only a fallback when Frost Strike is unavailable/unlearned.
    if runicPower >= 40 and self:IsUsableSpell(S.DeathCoil) then
        if not self:CastSpell(S.DeathCoil, "target") then return false end
        DeathKnightDebug("FROST: Death Coil")
        return true
    end
    
    -- Resource generation when all runes are down
    if runicPower < 30 and self:IsUsableSpell(S.HornOfWinter) then
        if not self:CastSpell(S.HornOfWinter, "player") then return false end
        DeathKnightDebug("FROST: Horn of Winter (RP generation)")
        return true
    end
    
    return false
end

-- =============================================
-- RESEARCH-BASED UNHOLY DK ROTATION (DPS)
-- =============================================

function AC:UnholyDeathKnightRotation()
    local runicPower = UnitPower("player", 6)
    local health = self:GetPlayerHealthPercent()
    local enemies = self:GetEnemyCount()
    local hasTarget = UnitExists("target") and UnitCanAttack("player", "target") and not UnitIsDeadOrGhost("target")
    
    -- Standard Scourge Strike builds use Blood Presence.
    if self:GetCurrentPresence() ~= "Blood" then
        if self:SwitchToPresence("Blood") then
            DeathKnightDebug("UNHOLY: Switching to Blood Presence")
            return true
        end
    end
    
    if not hasTarget then return false end
    StartAttack()
    
    -- Pet summoning priority
    if not UnitExists("pet") and self:KnowsSpell(S.RaiseDead) and self:IsUsableSpell(S.RaiseDead) then
        if not self:CastSpell(S.RaiseDead, "player") then return false end
        DeathKnightDebug("UNHOLY: Raise Dead (pet)")
        return true
    end

    if UnitExists("pet") and not UnitIsDeadOrGhost("pet") and
       (not UnitExists("pettarget") or not UnitIsUnit("pettarget", "target")) and PetAttack then
        PetAttack("target")
    end
    
    -- Emergency defensives
    if health < 30 then
        if self:KnowsSpell(S.BoneShield) and self:IsUsableSpell(S.BoneShield) and not self:HasBuff("player", S.BoneShield) then
            if not self:CastSpell(S.BoneShield, "player") then return false end
            DeathKnightDebug("UNHOLY: Bone Shield (emergency)")
            return true
        end
        if self:KnowsSpell(S.AntiMagicShell) and self:IsUsableSpell(S.AntiMagicShell) then
            if not self:CastSpell(S.AntiMagicShell, "player") then return false end
            DeathKnightDebug("UNHOLY: Anti-Magic Shell (emergency)")
            return true
        end
        if self:IsUsableSpell(S.IceboundFortitude) then
            if not self:CastSpell(S.IceboundFortitude, "player") then return false end
            DeathKnightDebug("UNHOLY: Emergency Icebound Fortitude")
            return true
        end
    end
    
    -- RESEARCH CRITICAL: Maintain Bone Shield buff for survivability
    if self:KnowsSpell(S.BoneShield) and not self:HasBuff("player", S.BoneShield) and self:IsUsableSpell(S.BoneShield) then
        if not self:CastSpell(S.BoneShield, "player") then return false end
        DeathKnightDebug("UNHOLY: Bone Shield (maintain)")
        return true
    end
    
    -- ENHANCED: Gargoyle burst sequence for advanced players
    if self:UnholyGargoyleBurstRotation() then
        return true
    end
    
    local useCleave = self:ShouldUseMultiTarget(2, enemies)
    local useAOE = self:ShouldUseMultiTarget(3, enemies)

    -- AoE rotation
    if useCleave then
        -- RESEARCH: Diseases first, then spread with Pestilence
        local hasBloodPlague = self:HasDebuff("target", S.BloodPlague)
        local hasFrostFever = self:HasDebuff("target", S.FrostFever)
        local refreshDisease = self:ShouldRefreshDiseases("target")
        
        -- Apply diseases to primary target
        if refreshDisease == "PlagueStrike" and self:HasRuneFor(3) and self:IsUsableSpell(S.PlagueStrike) then
            if not self:CastSpell(S.PlagueStrike, "target") then return false end
            DeathKnightDebug("UNHOLY: Plague Strike (AoE disease refresh)")
            return true
        end
        
        if refreshDisease == "IcyTouch" and self:HasRuneFor(2) and self:IsUsableSpell(S.IcyTouch) then
            if not self:CastSpell(S.IcyTouch, "target") then return false end
            DeathKnightDebug("UNHOLY: Icy Touch (AoE disease refresh)")
            return true
        end
        
        if not hasFrostFever and self:HasRuneFor(2) and self:IsUsableSpell(S.IcyTouch) then
            if not self:CastSpell(S.IcyTouch, "target") then return false end
            DeathKnightDebug("UNHOLY: Icy Touch (AoE setup)")
            return true
        end
        
        if not hasBloodPlague and self:HasRuneFor(3) and self:IsUsableSpell(S.PlagueStrike) then
            if not self:CastSpell(S.PlagueStrike, "target") then return false end
            DeathKnightDebug("UNHOLY: Plague Strike (AoE setup)")
            return true
        end
        
        -- Spread diseases with Pestilence
        if self:ShouldSpreadDeathKnightDiseases("target") and self:IsUsableSpell(S.Pestilence) then
            if not self:CastSpell(S.Pestilence, "target") then return false end
            self:MarkDeathKnightDiseasesSpread("target")
            DeathKnightDebug("UNHOLY: Pestilence (spread diseases)")
            return true
        end
        
        -- Death and Decay for AoE damage
        if useAOE and self:CastDeathKnightGroundAOE(S.DeathAndDecay) then
            DeathKnightDebug("UNHOLY: Death and Decay (AoE)")
            return true
        end
        
        -- Corpse Explosion remains manual because the living combat target is
        -- not a valid corpse and 3.3.5 offers no reliable corpse unit scan.
    end
    
    -- RESEARCH: Optimal Unholy Single Target Rotation
    -- Pattern: PS > IT > BS > BS > SS > DC > SS > SS > SS > DC > DC > SS > BS > BS > SS > DC
    local hasBloodPlague = self:HasDebuff("target", S.BloodPlague)
    local hasFrostFever = self:HasDebuff("target", S.FrostFever)
    local refreshDisease = self:ShouldRefreshDiseases("target")
    
    -- STEP 1: Establish diseases (PS > IT)
    if refreshDisease == "PlagueStrike" and self:HasRuneFor(3) and self:IsUsableSpell(S.PlagueStrike) then
        if not self:CastSpell(S.PlagueStrike, "target") then return false end
        DeathKnightDebug("UNHOLY: Plague Strike (disease refresh)")
        return true
    end
    
    if refreshDisease == "IcyTouch" and self:HasRuneFor(2) and self:IsUsableSpell(S.IcyTouch) then
        if not self:CastSpell(S.IcyTouch, "target") then return false end
        DeathKnightDebug("UNHOLY: Icy Touch (disease refresh)")
        return true
    end
    
    if not hasBloodPlague and self:HasRuneFor(3) and self:IsUsableSpell(S.PlagueStrike) then
        if not self:CastSpell(S.PlagueStrike, "target") then return false end
        DeathKnightDebug("UNHOLY: Plague Strike (disease priority)")
        return true
    end
    
    if not hasFrostFever and self:HasRuneFor(2) and self:IsUsableSpell(S.IcyTouch) then
        if not self:CastSpell(S.IcyTouch, "target") then return false end
        DeathKnightDebug("UNHOLY: Icy Touch (disease priority)")
        return true
    end
    
    -- STEP 2: Use 2 Blood Strikes in a row for Death Rune conversion (BS > BS)
    -- This creates Death Runes for Scourge Strike usage
    if self:GetBloodRunes() > 0 and self:IsUsableSpell(S.BloodStrike) then
        if not self:CastSpell(S.BloodStrike, "target") then return false end
        DeathKnightDebug("UNHOLY: Blood Strike (death rune conversion)")
        return true
    end
    
    -- STEP 3: Scourge Strike (main DPS ability) - requires both diseases
    if hasBloodPlague and hasFrostFever and self:KnowsSpell(S.ScourgeStrike) and self:IsUsableSpell(S.ScourgeStrike) then
        if self:HasRunesForFUAbility() then
            if not self:CastSpell(S.ScourgeStrike, "target") then return false end
            DeathKnightDebug("UNHOLY: Scourge Strike (main DPS)")
            return true
        end
    end
    
    -- STEP 4: Death Coil management (smart targeting)
    -- RESEARCH: "Remember, when u have a ready rune, USE IT ASAP, even tho u are runic power capped"
    -- But use Death Coil to maintain reasonable RP levels and heal pet
    if runicPower >= 60 or (runicPower >= 40 and self:GetAvailableRunes() == 0) then
        local targetUnit = "target"
        
        -- Smart Death Coil targeting
        if UnitExists("pet") then
            local petMaxHealth = UnitHealthMax("pet") or 0
            local petHP = petMaxHealth > 0 and (UnitHealth("pet") / petMaxHealth) * 100 or 100
            if petHP < 70 then
                targetUnit = "pet"
            end
        end
        
        if self:IsUsableSpell(S.DeathCoil) then
            if not self:CastSpell(S.DeathCoil, targetUnit) then return false end
            DeathKnightDebug("UNHOLY: Death Coil (" .. targetUnit .. ")")
            return true
        end
    end
    
    -- Resource generation and fallbacks
    if runicPower < 30 and self:IsUsableSpell(S.HornOfWinter) then
        if not self:CastSpell(S.HornOfWinter, "player") then return false end
        DeathKnightDebug("UNHOLY: Horn of Winter (RP generation)")
        return true
    end
    
    return false
end

-- =============================================
-- LEVELING ROTATION (SIMPLIFIED)
-- =============================================

function AC:DeathKnightLevelingRotation()
    local level = UnitLevel("player")
    local runicPower = UnitPower("player", 6)
    local health = self:GetPlayerHealthPercent()
    local hasTarget = UnitExists("target") and UnitCanAttack("player", "target") and not UnitIsDeadOrGhost("target")
    
    if not hasTarget then return false end
    StartAttack()
    
    -- Use Blood Presence for DPS while leveling
    if self:GetCurrentPresence() ~= "Blood" and health > 50 then
        if self:SwitchToPresence("Blood") then return true end
    end
    
    -- Emergency healing
    if health < 50 and self:IsUsableSpell(S.DeathStrike) and 
       self:HasRunesForFUAbility() then
        if not self:CastSpell(S.DeathStrike, "target") then return false end
        return true
    end
    
    -- Interrupt casters
    if self:TryInterrupt(S.MindFreeze, "target") then return true end
    
    -- Enhanced disease management for leveling
    local targetHP = self:GetTargetHealthPercent("target")
    if targetHP > 40 then  -- Apply to more targets
        if not self:HasDebuff("target", S.FrostFever) and self:HasRuneFor(2) and
           self:IsUsableSpell(S.IcyTouch) then
            if not self:CastSpell(S.IcyTouch, "target") then return false end
            DeathKnightDebug("LEVELING: Icy Touch (disease)")
            return true
        end
        if not self:HasDebuff("target", S.BloodPlague) and self:HasRuneFor(3) and
           self:IsUsableSpell(S.PlagueStrike) then
            if not self:CastSpell(S.PlagueStrike, "target") then return false end
            DeathKnightDebug("LEVELING: Plague Strike (disease)")
            return true
        end
    end
    
    -- Enhanced leveling priorities by level
    if level >= 60 and self:BothDiseasesUp("target") and self:IsUsableSpell(S.ScourgeStrike) and
       self:HasRunesForFUAbility() then
        if not self:CastSpell(S.ScourgeStrike, "target") then return false end
        DeathKnightDebug("LEVELING: Scourge Strike (60+)")
        return true
    end
    
    if level >= 56 and self:IsUsableSpell(S.Obliterate) and
       self:HasRunesForFUAbility() then
        if not self:CastSpell(S.Obliterate, "target") then return false end
        DeathKnightDebug("LEVELING: Obliterate (56+)")
        return true
    end
    
    -- Heart Strike for Blood spec leveling
    if level >= 60 and self:KnowsSpell(S.HeartStrike) and self:IsUsableSpell(S.HeartStrike) and
       self:GetBloodRunes() > 0 and self:BothDiseasesUp("target") then
        if not self:CastSpell(S.HeartStrike, "target") then return false end
        DeathKnightDebug("LEVELING: Heart Strike (60+)")
        return true
    end
    
    -- Blood Strike is not available on every leveling build/rank; gate it
    -- like every other ability instead of assuming it is learned.
    if self:GetBloodRunes() > 0 and self:IsUsableSpell(S.BloodStrike) then
        if not self:CastSpell(S.BloodStrike, "target") then return false end
        DeathKnightDebug("LEVELING: Blood Strike (death runes)")
        return true
    end
    
    -- Rune Strike for tanks
    if runicPower >= 20 and level >= 56 and self:IsUsableSpell(S.RuneStrike) then
        if not self:CastSpell(S.RuneStrike, "target") then return false end
        DeathKnightDebug("LEVELING: Rune Strike (tank)")
        return true
    end

    -- Frost Strike for leveling DPS
    if level >= 55 and runicPower >= 40 and self:IsUsableSpell(S.FrostStrike) then
        if not self:CastSpell(S.FrostStrike, "target") then return false end
        DeathKnightDebug("LEVELING: Frost Strike (RP)")
        return true
    end

    if runicPower >= 40 and self:IsUsableSpell(S.DeathCoil) then
        if not self:CastSpell(S.DeathCoil, "target") then return false end
        DeathKnightDebug("LEVELING: Death Coil")
        return true
    end
    
    -- Resource generation
    if runicPower < 30 and self:IsUsableSpell(S.HornOfWinter) then
        if not self:CastSpell(S.HornOfWinter, "player") then return false end
        return true
    end
    
    return false
end

-- =============================================
-- RESEARCH-BASED BUFF MANAGEMENT
-- =============================================

function AC:CheckDeathKnightBuffs()
    local spec = self:GetPlayerSpec()
    local inCombat = UnitAffectingCombat("player")
    
    -- Combat buffs (can be applied in combat)
    
    -- Bone Shield (Unholy) - CRITICAL defensive buff
    if spec == "Unholy" then
        local hasBoneShield, boneShieldStacks = self:HasBuff("player", S.BoneShield)
        boneShieldStacks = boneShieldStacks or 0
        if not hasBoneShield or boneShieldStacks <= 2 then
            if self:IsUsableSpell(S.BoneShield) then
                if not self:CastSpell(S.BoneShield, "player") then return false end
                DeathKnightDebug("AUTO-BUFF: Bone Shield (" .. boneShieldStacks .. " stacks)")
                return true
            end
        end
    end
    
    -- Out of combat buffs only
    if inCombat then return false end

    if spec == "Unholy" and not IsMounted() and not UnitExists("pet") and
       self:IsUsableSpell(S.RaiseDead) then
        if not self:CastSpell(S.RaiseDead, "player") then return false end
        DeathKnightDebug("AUTO-BUFF: Raise Dead")
        return true
    end
    
    -- Horn of Winter (attack power buff + RP generation)
    local hasAttackPowerBuff = self:HasBuff("player", S.HornOfWinter) or
                              self:HasBuff("player", "Strength of Earth Totem")
    
    if not hasAttackPowerBuff and self:IsUsableSpell(S.HornOfWinter) then
        if not self:CastSpell(S.HornOfWinter, "player") then return false end
        DeathKnightDebug("AUTO-BUFF: Horn of Winter")
        return true
    end
    
    -- RESEARCH-BASED: Optimal presence for each spec (situational)
    local optimalPresence = "Blood" -- Default
    if spec == "Blood" then
        -- Blood tanks: Frost for threat, Blood for solo healing
        optimalPresence = IsInGroup() and "Frost" or "Blood"
    elseif spec == "Frost" then
        optimalPresence = "Blood"
    elseif spec == "Unholy" then
        optimalPresence = "Blood"
    end
    
    if self:GetCurrentPresence() ~= optimalPresence then
        if self:SwitchToPresence(optimalPresence) then
            DeathKnightDebug("AUTO-BUFF: Optimal presence (" .. optimalPresence .. ")")
            return true
        end
    end
    
    return false
end

-- =============================================
-- ENHANCED AUTO-TARGETING SYSTEM
-- =============================================

function AC:DeathKnightAutoTarget()
    if not Throttle("DKAutoTarget", 0.5) then return false end
    if self:GetGroupSize() > 5 then return false end
    
    -- Don't change target if we have a valid one
    if UnitExists("target") and UnitCanAttack("player", "target") and not UnitIsDeadOrGhost("target") then
        return false
    end
    
    local bestTarget = nil
    local bestPriority = 0
    local playerLevel = UnitLevel("player")
    
    -- Priority targeting system
    local function evaluateTarget(unit)
        if not UnitExists(unit) or not UnitCanAttack("player", unit) or UnitIsDeadOrGhost(unit) then
            return 0
        end
        
        local priority = 0
        local unitLevel = UnitLevel(unit)
        local classification = UnitClassification(unit)
        local distance = CheckInteractDistance(unit, 3) and 5 or 25
        local isCasting = UnitCastingInfo(unit) ~= nil
        
        -- Level-appropriate targets
        if unitLevel > 0 and math.abs(unitLevel - playerLevel) <= 5 then
            priority = priority + 10
        elseif unitLevel == -1 then -- Boss
            priority = priority + 15
        end
        
        -- Classification priority
        if classification == "worldboss" then priority = priority + 20
        elseif classification == "rareelite" then priority = priority + 15
        elseif classification == "elite" then priority = priority + 10
        elseif classification == "rare" then priority = priority + 8
        end
        
        -- Casting priority (interrupt targets)
        if isCasting then priority = priority + 25 end
        
        -- Distance preference (closer is better)
        if distance <= 5 then priority = priority + 5
        elseif distance <= 15 then priority = priority + 3
        elseif distance > 30 then priority = priority - 10 end
        
        -- Attacking group members priority
        if IsInGroup() then
            local targetTarget = unit .. "target"
            if UnitExists(targetTarget) and UnitIsFriend("player", targetTarget) then
                local _, class = UnitClass(targetTarget)
                if class == "PRIEST" or class == "PALADIN" or class == "SHAMAN" or class == "DRUID" then
                    priority = priority + 30 -- Attacking healers!
                else
                    priority = priority + 15 -- Attacking group members
                end
            end
        end
        
        return priority
    end
    
    -- Check nameplates
    for i = 1, 40 do
        local unit = "nameplate" .. i
        local priority = evaluateTarget(unit)
        if priority > bestPriority then
            bestTarget = unit
            bestPriority = priority
        end
    end
    
    -- Target and start combat
    if bestTarget then
        TargetUnit(bestTarget)
        StartAttack()
        DeathKnightDebug("AUTO-TARGET: " .. (UnitName("target") or "Unknown") .. " (Priority: " .. bestPriority .. ")")
        return true
    end
    
    return false
end

-- =============================================
-- COMPREHENSIVE INTERRUPT SYSTEM
-- =============================================

function AC:DeathKnightAutoInterrupt()
    if not Throttle("DKInterrupt", 0.3) then return false end
    
    local function tryInterrupt(unit, interruptSpell)
        if UnitExists(unit) and UnitCanAttack("player", unit) then
            local currentSpell, _, uninterruptible = self:GetInterruptibleCastInfo(unit)

            if currentSpell and not uninterruptible and self:ShouldInterruptSpell(currentSpell) and
               self:IsUsableSpell(interruptSpell) then
                local inRange = IsSpellInRange and IsSpellInRange(interruptSpell, unit) or 1
                if inRange == nil or inRange == 1 then
                    if self:CastSpell(interruptSpell, unit) then
                        DeathKnightDebug("AUTO-INTERRUPT: " .. currentSpell .. " with " .. interruptSpell)
                        return true
                    end
                end
            end
        end
        return false
    end
    
    -- Try interrupts in order of preference
    local interruptSpells = {S.MindFreeze, S.Strangulate}
    
    -- Check current target first
    for _, spell in ipairs(interruptSpells) do
        if tryInterrupt("target", spell) then return true end
    end
    
    if self:GetGroupSize() <= 5 then
        -- Check focus target
        for _, spell in ipairs(interruptSpells) do
            if tryInterrupt("focus", spell) then return true end
        end

        -- Check nearby enemies casting without permanently changing targets.
        for i = 1, 40 do
            local unit = "nameplate" .. i
            for _, spell in ipairs(interruptSpells) do
                if tryInterrupt(unit, spell) then return true end
            end
        end
    end
    
    return false
end

-- =============================================
-- ADVANCED UTILITY USAGE
-- =============================================

function AC:DeathKnightAutoUtility()
    if not Throttle("DKUtility", 1.0) then return false end
    
    local health = self:GetPlayerHealthPercent()
    local inCombat = UnitAffectingCombat("player")
    
    -- Emergency health management
    if health < 35 and inCombat then
        -- Icebound Fortitude
        if self:IsUsableSpell(S.IceboundFortitude) then
            if self:CastSpell(S.IceboundFortitude, "player") then
                DeathKnightDebug("AUTO-UTILITY: Emergency Icebound Fortitude")
                return true
            end
        end

        if health < 25 and UnitExists("pet") and self:IsUsableSpell(S.DeathPact) then
            if self:CastSpell(S.DeathPact, "player") then
                DeathKnightDebug("AUTO-UTILITY: Emergency Death Pact")
                return true
            end
        end

        -- Use health potion if available
        if self.UseHealthPotion and self:UseHealthPotion(35) then
            DeathKnightDebug("AUTO-UTILITY: Emergency health potion")
            return true
        end
    end
    
    -- Anti-Magic Shell against spell damage
    if inCombat and health < 60 and self:IsUsableSpell(S.AntiMagicShell) then
        if UnitCastingInfo("target") or UnitChannelInfo("target") then
            if self:CastSpell(S.AntiMagicShell, "player") then
                DeathKnightDebug("AUTO-UTILITY: Anti-Magic Shell")
                return true
            end
        end
    end

    -- Death Grip for pulling/positioning. Never auto-grip in raid-sized groups.
    if inCombat and self:GetGroupSize() <= 5 and UnitExists("target") and UnitCanAttack("player", "target") then
        local distance = CheckInteractDistance("target", 3) and 5 or 25
        local isCasting = UnitCastingInfo("target") ~= nil

        if distance > 15 and distance <= 30 and self:IsUsableSpell(S.DeathGrip) and
           (isCasting or UnitClassification("target") == "rare" or UnitClassification("target") == "elite") then
            if self:CastSpell(S.DeathGrip, "target") then
                DeathKnightDebug("AUTO-UTILITY: Death Grip pull")
                return true
            end
        end
    end
    
    -- Mark of Blood on tough single targets
    if inCombat and UnitExists("target") and self:GetEnemyCount() <= 2 and self:IsUsableSpell(S.MarkOfBlood) then
        local classification = UnitClassification("target")
        local targetHP = self:GetTargetHealthPercent("target")
        
        if not self:HasDebuff("target", S.MarkOfBlood) and targetHP > 70 and
           (classification == "elite" or classification == "rareelite" or classification == "worldboss") then
            if self:CastSpell(S.MarkOfBlood, "target") then
                DeathKnightDebug("AUTO-UTILITY: Mark of Blood")
                return true
            end
        end
    end
    
    return false
end

-- =============================================
-- RACIAL ABILITIES
-- =============================================

function AC:UseDeathKnightRacials(offensive, defensive)
    if not Throttle("DKRacials", 3) then return false end
    
    local _, race = UnitRace("player")
    race = string.upper(race)
    local health = self:GetPlayerHealthPercent()
    local inCombat = UnitAffectingCombat("player")

    local fearControl = false
    local fearEffects = {
        ["Fear"] = true, ["Psychic Scream"] = true, ["Howl of Terror"] = true,
        ["Seduction"] = true, ["Repentance"] = true, ["Wyvern Sting"] = true,
    }
    for i = 1, 40 do
        local name = UnitDebuff("player", i)
        if not name then break end
        if fearEffects[name] then fearControl = true break end
    end

    local function castRacial(spellName, message)
        if self:CastSpell(spellName, "player") then
            DeathKnightDebug(message)
            return true
        end
        return false
    end
    
    -- Offensive racials
    if offensive and inCombat then
        if race == "ORC" and castRacial(S.BloodFury, "Racial: Blood Fury") then return true end
        if race == "TROLL" and castRacial(S.Berserking, "Racial: Berserking") then return true end
        if race == "BLOODELF" and UnitPower("player", 6) < 70 and
           castRacial(S.ArcaneTorrent, "Racial: Arcane Torrent") then return true end
    end
    
    -- Defensive racials
    if defensive or health < 50 or fearControl then
        if (race == "SCOURGE" or race == "UNDEAD") and fearControl and
           castRacial(S.WillOfTheForsaken, "Racial: Will of the Forsaken") then return true end
        if race == "DWARF" and health < 35 and castRacial(S.Stoneform, "Racial: Stoneform") then return true end
        if race == "DRAENEI" and health < 40 and castRacial(S.GiftOfTheNaaru, "Racial: Gift of the Naaru") then return true end
        if race == "TAUREN" and health < 35 and self:GetEnemyCount() >= 2 and CheckInteractDistance("target", 3) and
           self:IsUsableSpell(S.WarStomp) and castRacial(S.WarStomp, "Racial: War Stomp") then return true end
    end
    
    return false
end

-- =============================================
-- COOLDOWNS AND TRINKETS
-- =============================================

function AC:UseDeathKnightCooldowns()
    if not Throttle("DKCooldowns", 0.2) then return false end

    local spec = self:GetPlayerSpec()
    local inCombat = UnitAffectingCombat("player")
    local hasTarget = UnitExists("target") and UnitCanAttack("player", "target") and not UnitIsDeadOrGhost("target")
    
    if not inCombat or not hasTarget then return false end
    
    local targetClass = UnitClassification("target")
    local isElite = targetClass == "elite" or targetClass == "rareelite" or targetClass == "worldboss" or UnitLevel("target") == -1
    
    local worthyTarget = isElite or UnitHealth("target") > 100000
    local rotationReady = self:BothDiseasesUp("target")

    -- Wait until diseases are established before starting burst buffs.
    if worthyTarget and rotationReady then
        if self:UseTrinkets() then
            DeathKnightDebug("Used Trinkets")
            return true
        end
    end
    
    -- Use offensive racials
    if worthyTarget and rotationReady then
        if self:UseDeathKnightRacials(true, false) then
            DeathKnightDebug("Used Offensive Racial")
            return true
        end
    end
    
    -- Major cooldowns for each spec
    if spec == "Blood" then
        -- Dancing Rune Weapon for threat/damage
        if worthyTarget and rotationReady and self:IsUsableSpell(S.DancingRuneWeapon) then
            if self:CastSpell(S.DancingRuneWeapon, "target") then
                DeathKnightDebug("Dancing Rune Weapon (Blood)")
                return true
            end
        end
    elseif spec == "Frost" then
        -- Unbreakable Armor for damage/survivability
        if worthyTarget and rotationReady and self:KnowsSpell(S.UnbreakableArmor) and
           self:GetSpellCooldown(S.UnbreakableArmor) == 0 and not self:HasRuneFor(2) and
           self:IsUsableSpell(S.BloodTap) then
            if self:CastSpell(S.BloodTap, "player") then
                DeathKnightDebug("Blood Tap for Unbreakable Armor")
                return true
            end
        end
        if worthyTarget and rotationReady and self:IsUsableSpell(S.UnbreakableArmor) then
            if self:CastSpell(S.UnbreakableArmor, "player") then
                DeathKnightDebug("Unbreakable Armor (Frost)")
                return true
            end
        end

        if worthyTarget and rotationReady and not UnitExists("pet") and self:IsUsableSpell(S.RaiseDead) then
            if self:CastSpell(S.RaiseDead, "player") then
                DeathKnightDebug("Raise Dead (Frost cooldown)")
                return true
            end
        end

        if worthyTarget and rotationReady and self:GetAvailableRunes() <= 1 and
           UnitPower("player", 6) < 60 and self:IsUsableSpell(S.EmpowerRuneWeapon) then
            if self:CastSpell(S.EmpowerRuneWeapon, "player") then
                DeathKnightDebug("Empower Rune Weapon (Frost)")
                return true
            end
        end
    elseif spec == "Unholy" then
        -- Gargoyle is sequenced inside the Unholy rotation after diseases and
        -- burst buffs are established.
    end
    
    return false
end

-- =============================================
-- MAIN ROTATION CONTROLLER
-- =============================================

function AC:DeathKnightRotation()
    local spec = self:GetPlayerSpec()
    local level = UnitLevel("player")
    local inCombat = UnitAffectingCombat("player")
    local hasTarget = UnitExists("target") and UnitCanAttack("player", "target") and not UnitIsDeadOrGhost("target")
    
    -- PRIORITY 1: AUTOMATIC FEATURES (ALWAYS ACTIVE)
    
    -- Auto-interrupting (highest priority in combat)
    if inCombat and self:DeathKnightAutoInterrupt() then return true end

    -- Auto-buffing (works in and out of combat)
    if self:CheckDeathKnightBuffs() then return true end
    
    -- Emergency Lifeblood (Herbalism profession ability) at 50% health
    if inCombat and self:UseLifeblood() then return true end
    
    -- Auto-utility usage
    if inCombat and self:DeathKnightAutoUtility() then return true end
    
    -- Auto-targeting when no valid target
    if not hasTarget and self:DeathKnightAutoTarget() then 
        hasTarget = UnitExists("target") and UnitCanAttack("player", "target") and not UnitIsDeadOrGhost("target")
        if hasTarget then
            DeathKnightDebug("AUTO: Found and targeted enemy")
        end
    end
    
    -- PRIORITY 2: OUT OF COMBAT ACTIONS
    if not inCombat then
        -- Auto-pulling logic
        if hasTarget and not UnitAffectingCombat("target") then
            local distance = CheckInteractDistance("target", 3) and 5 or 25
            
            -- Death Grip for distant enemies
            if self:GetGroupSize() <= 5 and distance > 15 and distance <= 30 and self:IsUsableSpell(S.DeathGrip) then
                if self:CastSpell(S.DeathGrip, "target") then
                    DeathKnightDebug("AUTO-PULL: Death Grip")
                    return true
                end
            end
            
            -- Icy Touch for standard pulling
            if self:HasRuneFor(2) and self:IsUsableSpell(S.IcyTouch) then
                if self:CastSpell(S.IcyTouch, "target") then
                    StartAttack()
                    DeathKnightDebug("AUTO-PULL: Icy Touch")
                    return true
                end
            end
            
            -- Plague Strike as backup pull
            if self:HasRuneFor(3) and self:IsUsableSpell(S.PlagueStrike) then
                if self:CastSpell(S.PlagueStrike, "target") then
                    StartAttack()
                    DeathKnightDebug("AUTO-PULL: Plague Strike")
                    return true
                end
            end
            
            -- Blood Strike as last resort
            if self:GetBloodRunes() > 0 and self:IsUsableSpell(S.BloodStrike) then
                if self:CastSpell(S.BloodStrike, "target") then
                    StartAttack()
                    DeathKnightDebug("AUTO-PULL: Blood Strike")
                    return true
                end
            end
        end
        
        return false
    end
    
    -- PRIORITY 3: COMBAT ROTATIONS
    
    -- Use racial abilities when in combat (integrated into cooldowns)
    -- self:UseDeathKnightRacials(true, false) -- Now handled in cooldowns function
    
    -- Use trinkets during combat on appropriate targets
    if self:UseDeathKnightCooldowns() then return true end
    
    -- Route to appropriate spec rotation with level checks
    if level < 80 and (not spec or spec == "None") then
        -- Use leveling rotation for low level unspecced characters
        return self:DeathKnightLevelingRotation()
    elseif spec == "Blood" then
        return self:BloodDeathKnightRotation()
    elseif spec == "Frost" then
        return self:FrostDeathKnightRotation()
    elseif spec == "Unholy" then
        return self:UnholyDeathKnightRotation()
    else
        -- Use leveling rotation for unspecced characters
        return self:DeathKnightLevelingRotation()
    end
end

-- =============================================
-- INITIALIZATION
-- =============================================

function AC:InitDeathKnightRotations()
    self.rotations = self.rotations or {}
    self.rotations["DEATHKNIGHT"] = {}
    
    -- Register spec-specific rotations
    self.rotations["DEATHKNIGHT"]["Blood"] = function(s) return s:BloodDeathKnightRotation() end
    self.rotations["DEATHKNIGHT"]["Frost"] = function(s) return s:FrostDeathKnightRotation() end
    self.rotations["DEATHKNIGHT"]["Unholy"] = function(s) return s:UnholyDeathKnightRotation() end
    self.rotations["DEATHKNIGHT"]["None"] = function(s) return s:DeathKnightLevelingRotation() end
    
    -- Register utility functions
    self.CheckDeathKnightBuffs = AC.CheckDeathKnightBuffs
    self.DeathKnightAutoTarget = AC.DeathKnightAutoTarget
    self.DeathKnightAutoInterrupt = AC.DeathKnightAutoInterrupt
    self.DeathKnightAutoUtility = AC.DeathKnightAutoUtility
    
    -- Success message
    self:Print("|cFF00FF96Death Knight|r rotations initialized - |cFFFFD700COMPLETE RESEARCH-BASED WotLK 3.3.5a|r")
    DeathKnightDebug("|cFF00FF96=== COMPLETE DEATH KNIGHT REWRITE ===|r")
    DeathKnightDebug("|cFFFF6B6BBlood:|r Research-based tanking with Frost Presence (CRITICAL FIX)")
    DeathKnightDebug("|cFF87CEEBFrost:|r RIME/Killing Machine optimization + Blood Presence for DPS")
    DeathKnightDebug("|cFF8B4513Unholy:|r Disease mastery + smart Death Coil + Blood Presence for DPS")
    DeathKnightDebug("|cFFFFD700Mechanics:|r Expiry-aware diseases, proper presence usage, rune pooling")
    DeathKnightDebug("|cFF32CD32Features:|r Auto-targeting, interrupting, utility, buff management")
    DeathKnightDebug("|cFFDDA0DDSources:|r Warmane, Icy Veins, Wowhead WotLK 3.3.5a guides")
end

-- AzeroCombat: Priest Rotations (ULTIMATE WotLK 3.3.5a - Beast Healer & Shadow DPS Master)
-- Optimized for amazing auto-healing in groups and maximum DPS performance
local AddonName, AC = ...

local S = { -- Complete WotLK 3.3.5a Priest Spell Database
    -- Core Damage & Utility
    Smite = "Smite",
    MindBlast = "Mind Blast",
    ShadowWordPain = "Shadow Word: Pain",
    ShadowWordDeath = "Shadow Word: Death",
    HolyFire = "Holy Fire",
    MindFlay = "Mind Flay",
    Shoot = "Shoot", -- Wand
    MindSpike = "Mind Spike", -- WotLK 3.3.5a
    
    -- Shadow Spec (DPS Beast)
    DevouringPlague = "Devouring Plague",
    VampiricTouch = "Vampiric Touch",
    VampiricEmbrace = "Vampiric Embrace",
    Shadowform = "Shadowform",
    Dispersion = "Dispersion",
    MindSear = "Mind Sear",
    Shadowfiend = "Shadowfiend",
    Silence = "Silence",
    ShadowWordDeath = "Shadow Word: Death",
    PsychicHorror = "Psychic Horror", -- Shadow talent
    
    -- Discipline Spec (Shield Master & Smite Healer)
    Penance = "Penance",
    PowerInfusion = "Power Infusion",
    PainSuppression = "Pain Suppression",
    PowerWordBarrier = "Power Word: Barrier",
    BorrowedTime = "Borrowed Time", -- Disc talent effect
    GraceDebuff = "Grace", -- Disc mastery
    Aspiration = "Aspiration", -- Disc talent
    
    -- Holy Spec (Group Heal Master)
    CircleOfHealing = "Circle of Healing",
    PrayerOfMending = "Prayer of Mending",
    GuardianSpirit = "Guardian Spirit",
    DivineHymn = "Divine Hymn",
    HolyNova = "Holy Nova",
    Lightwell = "Lightwell",
    EmpoweredHealing = "Empowered Healing", -- Holy talent
    SpiritOfRedemption = "Spirit of Redemption", -- Holy talent
    
    -- Healing Spells (All Specs)
    PowerWordShield = "Power Word: Shield",
    Renew = "Renew",
    FlashHeal = "Flash Heal",
    Heal = "Heal",
    GreaterHeal = "Greater Heal",
    PrayerOfHealing = "Prayer of Healing",
    BindingHeal = "Binding Heal",
    DesperatePrayer = "Desperate Prayer",
    Sanctuary = "Sanctuary", -- Area effect from CoH
    
    -- Buff Spells
    PowerWordFortitude = "Power Word: Fortitude",
    PrayerOfFortitude = "Prayer of Fortitude",
    InnerFire = "Inner Fire",
    InnerWill = "Inner Will", -- WotLK alternative to Inner Fire
    DivineSpirit = "Divine Spirit",
    PrayerOfSpirit = "Prayer of Spirit",
    ShadowProtection = "Shadow Protection",
    PrayerOfShadowProtection = "Prayer of Shadow Protection",
    FearWard = "Fear Ward",
    
    -- Utility & Control
    DispelMagic = "Dispel Magic",
    CureDisease = "Cure Disease",
    AbolishDisease = "Abolish Disease",
    ShackleUndead = "Shackle Undead",
    MindSoothe = "Mind Soothe",
    MindControl = "Mind Control",
    PsychicScream = "Psychic Scream",
    Fade = "Fade",
    Levitate = "Levitate",
    Resurrection = "Resurrection",
    HymnOfHope = "Hymn of Hope",
    MassDispel = "Mass Dispel", -- Group dispel
    
    -- Important Debuffs/Buffs
    WeakenedSoulDebuff = "Weakened Soul",
    ShadowWeavingDebuff = "Shadow Weaving",
    EmpoweredShadowBuff = "Empowered Shadow",
    SurgeOfLightBuff = "Surge of Light",
    SerendipityBuff = "Serendipity",
    SpiritOfRedemptionBuff = "Spirit of Redemption",
    
    -- Racial Abilities (All Races)
    SymbolOfHope = "Symbol of Hope", -- Draenei
    Shadowmeld = "Shadowmeld", -- Night Elf
    WillOfTheForsaken = "Will of the Forsaken", -- Undead
    Berserking = "Berserking", -- Troll
    ArcaneTorrent = "Arcane Torrent", -- Blood Elf
    EveryManForHimself = "Every Man for Himself", -- Human
    Stoneform = "Stoneform", -- Dwarf
    GiftOfTheNaaru = "Gift of the Naaru", -- Draenei
    WarStomp = "War Stomp", -- Tauren
}

-- Debug function
local function PriestDebug(msg)
    if AC.debugMode then
        AC:Debug("|cFFFFFFFFPriest:|r " .. tostring(msg))
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

-- UTILITY FUNCTIONS

function AC:IsFastDyingMob(unit)
    if not unit or not UnitExists(unit) then return false end
    local hp = UnitHealth(unit)
    local maxHp = UnitHealthMax(unit)
    local hpPercent = (hp / maxHp) * 100
    return hpPercent < 20 or hp < 10000
end

function AC:ActionThrottle(action, interval)
    return Throttle(action, interval)
end

function AC:GetEnemyCountInRange(range)
    -- Use base GetEnemyCount but could be enhanced for range
    return self:GetEnemyCount()
end

-- ULTIMATE: Advanced healing target prioritization system
function AC:FindPriestHealingTarget(urgencyLevel)
    urgencyLevel = urgencyLevel or "normal" -- "emergency", "urgent", "normal", "maintenance"
    
    local targets = {}
    local emergencyTargets = {}
    local tankTargets = {}
    local healerTargets = {}
    local dpsTargets = {}
    
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
                local isTank = self:IsTank(unit)
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
                
                -- Calculate priority based on role and health
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
                
                -- Sort into role-based lists
                if isTank then
                    table.insert(tankTargets, target)
                elseif isHealer then
                    table.insert(healerTargets, target)
                else
                    table.insert(dpsTargets, target)
                end
            end
        end
    end
    
    -- Sort targets by priority (highest first)
    table.sort(targets, function(a, b) return a.priority > b.priority end)
    
    -- Return based on urgency level
    if urgencyLevel == "emergency" and #emergencyTargets > 0 then
        table.sort(emergencyTargets, function(a, b) return a.priority > b.priority end)
        local target = emergencyTargets[1]
        PriestDebug("EMERGENCY TARGET: " .. target.name .. " (" .. target.role .. ") - " .. math.floor(target.health * 100) .. "% HP")
        return target.unit, target.health, target
    elseif urgencyLevel == "tank" and #tankTargets > 0 then
        table.sort(tankTargets, function(a, b) return a.health < b.health end)
        local target = tankTargets[1]
        if target.health < 0.85 then
            PriestDebug("TANK TARGET: " .. target.name .. " - " .. math.floor(target.health * 100) .. "% HP")
            return target.unit, target.health, target
        end
    end
    
    -- Normal priority target
    if #targets > 0 and targets[1].health < 0.95 then
        local target = targets[1]
        PriestDebug("HEAL TARGET: " .. target.name .. " (" .. target.role .. ") - " .. math.floor(target.health * 100) .. "% HP | Priority: " .. target.priority)
        return target.unit, target.health, target
    end
    
    return nil, 1.0, nil
end

-- ULTIMATE: Advanced group damage assessment
function AC:AnalyzeGroupHealth()
    local analysis = {
        totalMembers = 1, -- Include self
        lowHealth = 0,     -- < 70%
        criticalHealth = 0, -- < 40%
        emergencyHealth = 0, -- < 25%
        avgHealth = 0,
        tankHealth = 1.0,
        healerHealth = 1.0,
        needsAOE = false,
        needsEmergencyAOE = false,
        healthDistribution = {}
    }
    
    local totalHealthPercent = self:GetPlayerHealthPercent()
    local selfHP = totalHealthPercent / 100
    
    if selfHP < 0.70 then analysis.lowHealth = analysis.lowHealth + 1 end
    if selfHP < 0.40 then analysis.criticalHealth = analysis.criticalHealth + 1 end
    if selfHP < 0.25 then analysis.emergencyHealth = analysis.emergencyHealth + 1 end
    
    -- Check group members
    if IsInGroup() then
        local prefix = GetNumRaidMembers() > 0 and "raid" or "party"
        local max = GetNumRaidMembers() > 0 and GetNumRaidMembers() or GetNumPartyMembers()
        
        for i = 1, max do
            local unit = prefix .. i
            if UnitExists(unit) and not UnitIsDeadOrGhost(unit) and UnitIsConnected(unit) then
                analysis.totalMembers = analysis.totalMembers + 1
                local hp = UnitHealth(unit) / UnitHealthMax(unit)
                local hpPercent = hp * 100
                totalHealthPercent = totalHealthPercent + hpPercent
                
                -- Track role-specific health
                local _, class = UnitClass(unit)
                if self:IsTank(unit) then
                    analysis.tankHealth = math.min(analysis.tankHealth, hp)
                elseif class == "PRIEST" or class == "PALADIN" or class == "SHAMAN" or class == "DRUID" then
                    analysis.healerHealth = math.min(analysis.healerHealth, hp)
                end
                
                -- Count health levels
                if hp < 0.70 then analysis.lowHealth = analysis.lowHealth + 1 end
                if hp < 0.40 then analysis.criticalHealth = analysis.criticalHealth + 1 end
                if hp < 0.25 then analysis.emergencyHealth = analysis.emergencyHealth + 1 end
                
                table.insert(analysis.healthDistribution, hp)
            end
        end
    end
    
    analysis.avgHealth = totalHealthPercent / analysis.totalMembers / 100
    
    -- Determine AoE needs
    local lowHealthRatio = analysis.lowHealth / analysis.totalMembers
    local criticalRatio = analysis.criticalHealth / analysis.totalMembers
    
    analysis.needsAOE = lowHealthRatio >= 0.5 or analysis.lowHealth >= 3
    analysis.needsEmergencyAOE = criticalRatio >= 0.4 or analysis.criticalHealth >= 2 or analysis.emergencyHealth >= 1
    
    return analysis
end

-- Simplified function for backward compatibility
function AC:GroupNeedsAOEHealing()
    local analysis = self:AnalyzeGroupHealth()
    return analysis.needsAOE
end

-- ULTIMATE: Advanced dispel priority system
function AC:AnalyzeDispelNeeds(unit)
    if not UnitExists(unit) then return false, nil, nil, 0 end
    
    local dispellableDebuffs = {}
    local highestPriority = 0
    local urgentDispel = false
    
    -- Comprehensive dispel priority database
    local dispelPriorities = {
        -- Emergency dispels (95-100 priority)
        ["Fear"] = 100,
        ["Polymorph"] = 100,
        ["Banish"] = 100,
        ["Cyclone"] = 95,
        ["Freezing Trap"] = 95,
        ["Mind Control"] = 100,
        
        -- High priority dispels (80-94 priority)
        ["Hammer of Justice"] = 90,
        ["Entangling Roots"] = 85,
        ["Frost Nova"] = 85,
        ["Slow"] = 80,
        ["Curse of Tongues"] = 85,
        ["Curse of Elements"] = 90,
        ["Faerie Fire"] = 80,
        
        -- Moderate priority dispels (60-79 priority)
        ["Curse of Agony"] = 70,
        ["Corruption"] = 65,
        ["Immolate"] = 65,
        ["Moonfire"] = 60,
        ["Insect Swarm"] = 60,
        
        -- Disease dispels (70-85 priority)
        ["Devouring Plague"] = 85,
        ["Abolish Disease"] = 75,
        ["Diseases"] = 70, -- Generic disease
        
        -- Magic debuffs (varies)
        ["Magic"] = 50, -- Base magic debuff priority
    }
    
    local i = 1
    while true do
        local name, icon, count, debuffType, duration, expirationTime, source, isStealable, nameplateShowPersonal, spellId = UnitDebuff(unit, i)
        if not name then break end
        
        -- Check if dispellable
        local canDispel = false
        local priority = 0
        
        if debuffType == "Magic" and self:KnowsSpell(S.DispelMagic) then
            canDispel = true
            priority = dispelPriorities[name] or dispelPriorities["Magic"] or 50
        elseif debuffType == "Disease" and (self:KnowsSpell(S.CureDisease) or self:KnowsSpell(S.AbolishDisease)) then
            canDispel = true
            priority = dispelPriorities[name] or dispelPriorities["Diseases"] or 70
        end
        
        if canDispel then
            -- Increase priority based on target role
            local _, class = UnitClass(unit)
            if self:IsTank(unit) then
                priority = priority + 15
            elseif class == "PRIEST" or class == "PALADIN" or class == "SHAMAN" or class == "DRUID" then
                priority = priority + 10
            end
            
            -- Increase priority if target is low health
            local hp = UnitHealth(unit) / UnitHealthMax(unit)
            if hp < 0.5 then priority = priority + 10 end
            if hp < 0.3 then priority = priority + 20 end
            
            local debuffInfo = {
                name = name,
                type = debuffType,
                priority = priority,
                timeLeft = expirationTime - GetTime(),
                stacks = count or 1
            }
            
            table.insert(dispellableDebuffs, debuffInfo)
            
            if priority > highestPriority then
                highestPriority = priority
            end
            
            if priority >= 90 then
                urgentDispel = true
            end
        end
        
        i = i + 1
    end
    
    -- Sort by priority
    table.sort(dispellableDebuffs, function(a, b) return a.priority > b.priority end)
    
    local hasDispellable = #dispellableDebuffs > 0
    local topDebuff = hasDispellable and dispellableDebuffs[1] or nil
    
    return hasDispellable, topDebuff, urgentDispel, highestPriority
end

-- Simplified function for backward compatibility
function AC:NeedsDispel(unit)
    local hasDispellable, topDebuff, urgentDispel, priority = self:AnalyzeDispelNeeds(unit)
    return hasDispellable, topDebuff and topDebuff.name or nil, urgentDispel
end

-- ENHANCED: Racial abilities
function AC:UsePriestRacials(offensive, defensive)
    if not Throttle("PriestRacials", 3) then return false end
    
    local _, race = UnitRace("player")
    race = string.upper(race)
    local health = self:GetPlayerHealthPercent()
    local inCombat = UnitAffectingCombat("player")
    
    -- Offensive racials
    if offensive and inCombat then
        if race == "TROLL" and self:IsUsableSpell(S.Berserking) then
            CastSpellByName(S.Berserking)
            PriestDebug("Racial: Berserking")
            return true
        end
        if race == "BLOODELF" and self:IsUsableSpell(S.ArcaneTorrent) then
            local mana = UnitPower("player", 0) / UnitPowerMax("player", 0) * 100
            if mana < 80 then
                CastSpellByName(S.ArcaneTorrent)
                PriestDebug("Racial: Arcane Torrent")
                return true
            end
        end
    end
    
    -- Defensive racials
    if defensive or health < 50 then
        if race == "UNDEAD" and self:IsUsableSpell(S.WillOfTheForsaken) then
            CastSpellByName(S.WillOfTheForsaken)
            PriestDebug("Racial: Will of the Forsaken")
            return true
        end
        if race == "DWARF" and self:IsUsableSpell(S.Stoneform) then
            CastSpellByName(S.Stoneform)
            PriestDebug("Racial: Stoneform")
            return true
        end
        if race == "HUMAN" and self:IsUsableSpell(S.EveryManForHimself) then
            CastSpellByName(S.EveryManForHimself)
            PriestDebug("Racial: Every Man for Himself")
            return true
        end
        if race == "NIGHTELF" and self:IsUsableSpell(S.Shadowmeld) then
            CastSpellByName(S.Shadowmeld)
            PriestDebug("Racial: Shadowmeld")
            return true
        end
    end
    
    -- Mana racials
    if race == "DRAENEI" and self:IsUsableSpell(S.SymbolOfHope) then
        local mana = UnitPower("player", 0) / UnitPowerMax("player", 0) * 100
        if mana < 50 then
            CastSpellByName(S.SymbolOfHope)
            PriestDebug("Racial: Symbol of Hope")
            return true
        end
    end
    
    return false
end

-- ENHANCED: Smart defensive cooldown usage
function AC:UsePriestDefensives()
    local health = self:GetPlayerHealthPercent()
    local inCombat = UnitAffectingCombat("player")
    
    if not inCombat then return false end
    
    -- Emergency health potion
    if health < 35 and self:UseHealthPotion(35) then
        PriestDebug("Used health potion")
        return true
    end
    
    -- Power Word: Shield
    if health < 70 and self:IsUsableSpell(S.PowerWordShield) and 
       not self:HasDebuff("player", "Weakened Soul") then
        CastSpellByName(S.PowerWordShield, "player")
        PriestDebug("Power Word: Shield (self)")
        return true
    end
    
    -- Desperate Prayer
    if health < 40 and self:IsUsableSpell(S.DesperatePrayer) then
        CastSpellByName(S.DesperatePrayer)
        PriestDebug("Desperate Prayer")
        return true
    end
    
    -- Fade
    if health < 60 and self:GetEnemyCount() > 1 and self:IsUsableSpell(S.Fade) then
        CastSpellByName(S.Fade)
        PriestDebug("Fade")
        return true
    end
    
    -- Psychic Scream
    if health < 30 and self:GetEnemyCount() >= 2 and self:IsUsableSpell(S.PsychicScream) then
        CastSpellByName(S.PsychicScream)
        PriestDebug("Psychic Scream")
        return true
    end
    
    -- Dispersion (Shadow)
    if health < 25 and self:IsUsableSpell(S.Dispersion) then
        CastSpellByName(S.Dispersion)
        PriestDebug("Dispersion")
        return true
    end
    
    -- Use defensive trinkets
    if health < 45 and self:UseTrinkets() then
        PriestDebug("Used defensive trinket")
        return true
    end
    
    return false
end

-- ENHANCED: Smart offensive cooldown usage
function AC:UsePriestOffensives(spec)
    local targetHP = self:GetTargetHealthPercent("target")
    local targetClass = UnitClassification("target")
    
    -- Don't blow CDs on trivial mobs
    if targetClass == "trivial" or targetHP < 30 then
        return false
    end
    
    -- Check if worth using CDs
    local worthIt = targetClass == "elite" or targetClass == "rareelite" or 
                   targetClass == "worldboss" or UnitHealth("target") > 100000 or
                   (IsInGroup() and targetHP > 50)
    
    if not worthIt then return false end
    
    -- Shadow
    if spec == "Shadow" then
        -- Shadowfiend
        if self:IsUsableSpell(S.Shadowfiend) and Throttle("Shadowfiend", 300) then
            CastSpellByName(S.Shadowfiend, "target")
            PriestDebug("Shadowfiend")
            if self.UseTrinkets then self:UseTrinkets() end
            if self.UseOffensivePotion then self:UseOffensivePotion(true) end
            return true
        end
        
        -- Power Infusion
        if self:IsUsableSpell(S.PowerInfusion) and Throttle("PowerInfusion", 120) then
            CastSpellByName(S.PowerInfusion, "player")
            PriestDebug("Power Infusion")
            return true
        end
    end
    
    -- Discipline offensive PI
    if spec == "Discipline" and self:IsUsableSpell(S.PowerInfusion) and 
       Throttle("PowerInfusionDisc", 120) then
        CastSpellByName(S.PowerInfusion, "player")
        PriestDebug("Power Infusion (Disc)")
        return true
    end
    
    return false
end

-- BUFF MANAGEMENT
function AC:CheckPriestBuffs()
    if not Throttle("PriestBuffsOOC", 10) then return false end
    if UnitAffectingCombat("player") then return false end
    
    -- Inner Fire
    if self:IsUsableSpell(S.InnerFire) and not self:HasBuff("player", S.InnerFire) then
        CastSpellByName(S.InnerFire)
        PriestDebug("Buffing: Inner Fire")
        return true
    end
    
    -- Fortitude
    local fortSpell = self:KnowsSpell(S.PrayerOfFortitude) and S.PrayerOfFortitude or S.PowerWordFortitude
    if self:IsUsableSpell(fortSpell) then
        if not self:HasBuff("player", S.PowerWordFortitude) and 
           not self:HasBuff("player", S.PrayerOfFortitude) then
            CastSpellByName(fortSpell, "player")
            PriestDebug("Buffing: " .. fortSpell)
            return true
        end
    end
    
    -- Divine Spirit
    local spiritSpell = self:KnowsSpell(S.PrayerOfSpirit) and S.PrayerOfSpirit or S.DivineSpirit
    if self:IsUsableSpell(spiritSpell) then
        if not self:HasBuff("player", S.DivineSpirit) and 
           not self:HasBuff("player", S.PrayerOfSpirit) then
            CastSpellByName(spiritSpell, "player")
            PriestDebug("Buffing: " .. spiritSpell)
            return true
        end
    end
    
    -- Shadow Protection (situational)
    local shadowSpell = self:KnowsSpell(S.PrayerOfShadowProtection) and 
                       S.PrayerOfShadowProtection or S.ShadowProtection
    if self:IsUsableSpell(shadowSpell) and IsInInstance() then
        if not self:HasBuff("player", S.ShadowProtection) and 
           not self:HasBuff("player", S.PrayerOfShadowProtection) then
            CastSpellByName(shadowSpell, "player")
            PriestDebug("Buffing: " .. shadowSpell)
            return true
        end
    end
    
    return false
end

-- ENHANCED SHADOW PRIEST ROTATION WITH DOT MANAGEMENT
function AC:ShadowPriestRotation()
    local mana = UnitPower("player", 0)
    local maxMana = UnitPowerMax("player", 0)
    local manaPercent = (maxMana > 0) and (mana/maxMana*100) or 100
    local health = self:GetPlayerHealthPercent()
    local enemies = self:GetEnemyCount()
    local hasTarget = UnitExists("target") and UnitCanAttack("player", "target") and not UnitIsDeadOrGhost("target")
    local complexity = self:GetRotationComplexity()
    
    -- Shadowform check (required for Shadow)
    if not self:HasBuff("player", S.Shadowform) and self:IsUsableSpell(S.Shadowform) then
        CastSpellByName(S.Shadowform)
        PriestDebug("Shadow: Entering Shadowform")
        return true
    end
    
    if not hasTarget then
        local bestTarget = self:FindBestTarget()
        if bestTarget then
            TargetUnit(bestTarget)
            hasTarget = true
        else
            return false
        end
    end
    
    -- Defensive cooldowns
    if self:UsePriestDefensives() then return true end
    
    -- Mana management
    if manaPercent < 30 and self:UseManaPotion(30) then
        PriestDebug("Used mana potion")
        return true
    end
    
    if manaPercent < 20 and self:IsUsableSpell(S.Dispersion) then
        CastSpellByName(S.Dispersion)
        PriestDebug("Shadow: Dispersion for mana")
        return true
    end
    
    local targetHP = self:GetTargetHealthPercent("target")
    local isFastDying = self:IsFastDyingMob("target")
    
    -- Offensive cooldowns
    if self:UsePriestOffensives("Shadow") then return true end
    
    -- Interrupt with Silence
    if UnitCastingInfo("target") and self:IsUsableSpell(S.Silence) then
        CastSpellByName(S.Silence, "target")
        PriestDebug("Shadow: Silence interrupt")
        return true
    end
    
    -- Shadow Word: Death execute
    if targetHP < 25 and self:IsUsableSpell(S.ShadowWordDeath) then
        CastSpellByName(S.ShadowWordDeath, "target")
        PriestDebug("Shadow: Shadow Word: Death")
        return true
    end
    
    -- AoE rotation
    if enemies >= 4 and manaPercent > 30 then
        -- Mind Sear spam
        if self:IsUsableSpell(S.MindSear) and not UnitChannelInfo("player") then
            CastSpellByName(S.MindSear, "target")
            PriestDebug("Shadow: Mind Sear (AoE)")
            return true
        end
    end
    
    -- ENHANCED DOT MANAGEMENT WITH PANDEMIC TIMING
    local function shouldRefreshShadowDot(debuffName, baseDuration)
        if not self:HasDebuff("target", debuffName) then
            return true -- Missing DoT
        end
        
        -- Only use pandemic for advanced rotations
        if complexity == "ADVANCED" or complexity == "MODERATE" then
            local timeRemaining = self:DebuffTimeRemaining("target", debuffName)
            local pandemicThreshold = baseDuration * 0.3 -- 30% rule
            return timeRemaining <= pandemicThreshold
        end
        
        -- Simple refresh for basic rotations (current behavior)
        return self:DebuffTimeRemaining("target", debuffName) < 3
    end
    
    -- RESEARCH-BASED: Optimal Shadow DoT Priority
    if not isFastDying then
        -- Priority 1: Vampiric Touch (15s base, provides healing and shadow embrace)
        if shouldRefreshShadowDot(S.VampiricTouch, 15) and self:IsUsableSpell(S.VampiricTouch) then
            CastSpellByName(S.VampiricTouch, "target")
            PriestDebug("Shadow: Vampiric Touch (pandemic-aware)")
            return true
        end
        
        -- Priority 2: Shadow Word: Pain (18s base, core DoT)
        if shouldRefreshShadowDot(S.ShadowWordPain, 18) and self:IsUsableSpell(S.ShadowWordPain) then
            CastSpellByName(S.ShadowWordPain, "target")
            PriestDebug("Shadow: Shadow Word: Pain (pandemic-aware)")
            return true
        end
        
        -- Priority 3: Devouring Plague (24s base, high damage)
        if shouldRefreshShadowDot(S.DevouringPlague, 24) and self:IsUsableSpell(S.DevouringPlague) then
            CastSpellByName(S.DevouringPlague, "target")
            PriestDebug("Shadow: Devouring Plague (pandemic-aware)")
            return true
        end
    end
    
    -- Mind Blast on cooldown
    if self:IsUsableSpell(S.MindBlast) and manaPercent > 10 then
        CastSpellByName(S.MindBlast, "target")
        PriestDebug("Shadow: Mind Blast")
        return true
    end
    
    -- Mind Flay filler
    if self:IsUsableSpell(S.MindFlay) and manaPercent > 5 then
        if not UnitChannelInfo("player") then
            CastSpellByName(S.MindFlay, "target")
            PriestDebug("Shadow: Mind Flay")
            return true
        end
    end
    
    -- Wand if OOM
    if manaPercent < 5 and not IsAutoRepeatSpell(S.Shoot) then
        CastSpellByName(S.Shoot, "target")
        PriestDebug("Shadow: Wanding")
        return true
    end
    
    return false
end

-- ULTIMATE DISCIPLINE ROTATION (Shield Master & Smite Healer)
function AC:DisciplinePriestRotation()
    local mana = UnitPower("player", 0)
    local maxMana = UnitPowerMax("player", 0)
    local manaPercent = (maxMana > 0) and (mana/maxMana*100) or 100
    local health = self:GetPlayerHealthPercent()
    local hasTarget = UnitExists("target") and UnitCanAttack("player", "target") and not UnitIsDeadOrGhost("target")
    local combatPhase = self:GetCombatPhase()
    local groupHealth = self:AnalyzeGroupHealth()
    
    PriestDebug("DISC: Mana " .. math.floor(manaPercent) .. "% | Group: " .. groupHealth.totalMembers .. " members | Low HP: " .. groupHealth.lowHealth .. " | Critical: " .. groupHealth.criticalHealth)
    
    -- SMART HEALING PRIORITY 0: EMERGENCY TRIAGE OVERRIDE
    -- If anyone is critically injured, emergency triage takes absolute priority
    if self:EmergencyTriage() then return true end
    
    -- PRIORITY 1: EMERGENCY RESPONSE
    if self:UsePriestDefensives() then return true end
    
    -- EPIC PRIORITY 1.5: Maintain combat buffs
    if self:CheckPriestCombatBuffs() then return true end
    
    -- PRIORITY 2: MANA MANAGEMENT
    if manaPercent < 30 and self:UseManaPotion(30) then
        PriestDebug("DISC: Mana potion used")
        return true
    end
    
    -- PRIORITY 3: MASS DISPELLING (Disc specialty)
    if self:ActionThrottle("MassDispelCheck", 2) and self:IsUsableSpell(S.MassDispel) then
        local dispelCount = 0
        local units = {"player"}
        
        if IsInGroup() then
            local prefix = GetNumRaidMembers() > 0 and "raid" or "party"
            local max = GetNumRaidMembers() > 0 and GetNumRaidMembers() or GetNumPartyMembers()
            for i = 1, max do
                table.insert(units, prefix .. i)
            end
        end
        
        for _, unit in ipairs(units) do
            if UnitExists(unit) then
                local hasDispellable, topDebuff, urgentDispel, priority = self:AnalyzeDispelNeeds(unit)
                if hasDispellable and priority >= 80 then
                    dispelCount = dispelCount + 1
                end
            end
        end
        
        -- Use Mass Dispel if 2+ people need urgent dispelling
        if dispelCount >= 2 then
            CastSpellByName(S.MassDispel)
            PriestDebug("DISC: Mass Dispel (" .. dispelCount .. " targets)")
            return true
        end
    end
    
    -- PRIORITY 4: INDIVIDUAL DISPELLING
    if self:ActionThrottle("DispelCheck", 0.5) then
        local units = {"player"}
        if IsInGroup() then
            local prefix = GetNumRaidMembers() > 0 and "raid" or "party"
            local max = GetNumRaidMembers() > 0 and GetNumRaidMembers() or GetNumPartyMembers()
            for i = 1, max do
                table.insert(units, prefix .. i)
            end
        end
        
        -- Sort units by priority (tanks/healers first)
        table.sort(units, function(a, b)
            if a == "player" then return true end
            if b == "player" then return false end
            local aTank = self:IsTank(a)
            local bTank = self:IsTank(b)
            if aTank ~= bTank then return aTank end
            local _, aClass = UnitClass(a)
            local _, bClass = UnitClass(b)
            local aHealer = aClass == "PRIEST" or aClass == "PALADIN" or aClass == "SHAMAN" or aClass == "DRUID"
            local bHealer = bClass == "PRIEST" or bClass == "PALADIN" or bClass == "SHAMAN" or bClass == "DRUID"
            return aHealer and not bHealer
        end)
        
        for _, unit in ipairs(units) do
            if UnitExists(unit) then
                local hasDispellable, topDebuff, urgentDispel, priority = self:AnalyzeDispelNeeds(unit)
                if hasDispellable and (urgentDispel or priority >= 70 or UnitIsUnit(unit, "player")) then
                    if topDebuff.type == "Magic" and self:IsUsableSpell(S.DispelMagic) then
                        CastSpellByName(S.DispelMagic, unit)
                        PriestDebug("DISC: Dispel Magic on " .. UnitName(unit) .. " (" .. topDebuff.name .. ")")
                        return true
                    elseif topDebuff.type == "Disease" and self:IsUsableSpell(S.CureDisease) then
                        CastSpellByName(S.CureDisease, unit)
                        PriestDebug("DISC: Cure Disease on " .. UnitName(unit) .. " (" .. topDebuff.name .. ")")
                        return true
                    end
                end
            end
        end
    end
    
    -- PRIORITY 5: EMERGENCY HEALING & COOLDOWNS
    local emergencyTarget, emergencyHealth, emergencyInfo = self:FindPriestHealingTarget("emergency")
    if emergencyTarget and emergencyHealth < 0.25 then
        -- Pain Suppression (ULTIMATE emergency cooldown)
        if self:IsUsableSpell(S.PainSuppression) and Throttle("PainSuppression", 180) then
            CastSpellByName(S.PainSuppression, emergencyTarget)
            PriestDebug("DISC EMERGENCY: Pain Suppression on " .. UnitName(emergencyTarget))
            return true
        end
        
        -- Power Word: Shield (instant protection)
        if not self:HasDebuff(emergencyTarget, S.WeakenedSoulDebuff) and self:IsUsableSpell(S.PowerWordShield) then
            CastSpellByName(S.PowerWordShield, emergencyTarget)
            PriestDebug("DISC EMERGENCY: PW:Shield on " .. UnitName(emergencyTarget))
            return true
        end
        
        -- Penance (fast, powerful heal)
        if self:IsUsableSpell(S.Penance) then
            CastSpellByName(S.Penance, emergencyTarget)
            PriestDebug("DISC EMERGENCY: Penance heal on " .. UnitName(emergencyTarget))
            return true
        end
        
        -- Flash Heal (backup emergency)
        if self:IsUsableSpell(S.FlashHeal) then
            CastSpellByName(S.FlashHeal, emergencyTarget)
            PriestDebug("DISC EMERGENCY: Flash Heal on " .. UnitName(emergencyTarget))
            return true
        end
    end
    
    -- PRIORITY 6: PROACTIVE TANK SHIELDING (Disc specialty)
    local tankTarget, tankHealth, tankInfo = self:FindPriestHealingTarget("tank")
    if tankTarget and not self:HasDebuff(tankTarget, S.WeakenedSoulDebuff) and 
       self:IsUsableSpell(S.PowerWordShield) and Throttle("ProactiveTankShield", 8) then
        CastSpellByName(S.PowerWordShield, tankTarget)
        PriestDebug("DISC PROACTIVE: PW:Shield on tank " .. UnitName(tankTarget))
        return true
    end
    
    -- PRIORITY 7: GROUP EMERGENCY HEALING
    if groupHealth.needsEmergencyAOE then
        -- Power Word: Barrier (Disc AOE damage reduction)
        if self:IsUsableSpell(S.PowerWordBarrier) and Throttle("PowerWordBarrier", 180) then
            if self.SafeCastGroundAOE then
                self:SafeCastGroundAOE(S.PowerWordBarrier)
            else
                CastSpellByName(S.PowerWordBarrier)
            end
            PriestDebug("DISC EMERGENCY: Power Word: Barrier")
            return true
        end
        
        -- Prayer of Healing (group heal)
        if self:IsUsableSpell(S.PrayerOfHealing) and manaPercent > 30 then
            CastSpellByName(S.PrayerOfHealing)
            PriestDebug("DISC EMERGENCY: Prayer of Healing")
            return true
        end
    end
    
    -- SMART HEALING PRIORITY 8: INTELLIGENT HEALING ALGORITHM
    -- Use advanced smart healing system for optimal spell selection
    if self:SmartHeal() then return true end
    
    -- PRIORITY 8.5: FALLBACK TO LEGACY HEALING ROTATION
    local healTarget, healTargetHealth, healInfo = self:FindPriestHealingTarget("normal")
    if healTarget and healTargetHealth < 0.95 then
        
        -- Prayer of Mending (efficient bouncing heal)
        if healTargetHealth < 0.80 and self:IsUsableSpell(S.PrayerOfMending) and 
           Throttle("PrayerOfMending", 8) then
            CastSpellByName(S.PrayerOfMending, healTarget)
            PriestDebug("DISC: Prayer of Mending on " .. UnitName(healTarget))
            return true
        end
        
        -- Penance (main healing spell)
        if healTargetHealth < 0.70 and self:IsUsableSpell(S.Penance) then
            CastSpellByName(S.Penance, healTarget)
            PriestDebug("DISC: Penance heal on " .. UnitName(healTarget))
            return true
        end
        
        -- Power Word: Shield for damage prevention
        if healTargetHealth < 0.85 and not self:HasDebuff(healTarget, S.WeakenedSoulDebuff) and 
           self:IsUsableSpell(S.PowerWordShield) then
            CastSpellByName(S.PowerWordShield, healTarget)
            PriestDebug("DISC: PW:Shield on " .. UnitName(healTarget))
            return true
        end
        
        -- Flash Heal for quick healing
        if healTargetHealth < 0.60 and self:IsUsableSpell(S.FlashHeal) then
            CastSpellByName(S.FlashHeal, healTarget)
            PriestDebug("DISC: Flash Heal on " .. UnitName(healTarget))
            return true
        end
        
        -- Greater Heal for efficient big heals
        if healTargetHealth < 0.70 and manaPercent > 40 and self:IsUsableSpell(S.GreaterHeal) then
            if not UnitCastingInfo("player") then
                CastSpellByName(S.GreaterHeal, healTarget)
                PriestDebug("DISC: Greater Heal on " .. UnitName(healTarget))
                return true
            end
        end
    end
    
    -- PRIORITY 9: GROUP HEALING
    if groupHealth.needsAOE and manaPercent > 35 then
        if self:IsUsableSpell(S.PrayerOfHealing) then
            CastSpellByName(S.PrayerOfHealing)
            PriestDebug("DISC: Prayer of Healing (group damage)")
            return true
        end
    end
    
    -- PRIORITY 10: OFFENSIVE ABILITIES (When healing not needed)
    if hasTarget and (not healTarget or healTargetHealth > 0.90) and groupHealth.avgHealth > 0.85 and manaPercent > 50 then
        
        -- Offensive cooldowns
        if self:UsePriestOffensives("Discipline") then return true end
        
        -- Offensive Penance (excellent damage)
        if self:IsUsableSpell(S.Penance) then
            CastSpellByName(S.Penance, "target")
            PriestDebug("DISC: Offensive Penance")
            return true
        end
        
        -- Holy Fire (DoT + direct damage)
        if not self:HasDebuff("target", S.HolyFire) and self:IsUsableSpell(S.HolyFire) then
            CastSpellByName(S.HolyFire, "target")
            PriestDebug("DISC: Holy Fire")
            return true
        end
        
        -- Shadow Word: Pain (DoT)
        if self:DebuffTimeRemaining("target", S.ShadowWordPain) < 3 and 
           self:IsUsableSpell(S.ShadowWordPain) and not self:IsFastDyingMob("target") then
            CastSpellByName(S.ShadowWordPain, "target")
            PriestDebug("DISC: Shadow Word: Pain")
            return true
        end
        
        -- Smite (main damage filler)
        if self:IsUsableSpell(S.Smite) and not UnitCastingInfo("player") then
            CastSpellByName(S.Smite, "target")
            PriestDebug("DISC: Smite")
            return true
        end
    end
    
    return false
end

-- ULTIMATE HOLY ROTATION (Group Heal Master & AOE Heal Beast)
function AC:HolyPriestRotation()
    local mana = UnitPower("player", 0)
    local maxMana = UnitPowerMax("player", 0)
    local manaPercent = (maxMana > 0) and (mana/maxMana*100) or 100
    local health = self:GetPlayerHealthPercent()
    local hasTarget = UnitExists("target") and UnitCanAttack("player", "target") and not UnitIsDeadOrGhost("target")
    local combatPhase = self:GetCombatPhase()
    local groupHealth = self:AnalyzeGroupHealth()
    
    PriestDebug("HOLY: Mana " .. math.floor(manaPercent) .. "% | Group: " .. groupHealth.totalMembers .. " members | Avg HP: " .. math.floor(groupHealth.avgHealth * 100) .. "% | Emergency: " .. groupHealth.emergencyHealth)
    
    -- SMART HEALING PRIORITY 0: EMERGENCY TRIAGE OVERRIDE
    -- Emergency triage has absolute priority for Holy priests
    if self:EmergencyTriage() then return true end
    
    -- PRIORITY 1: EMERGENCY RESPONSE
    if self:UsePriestDefensives() then return true end
    
    -- EPIC PRIORITY 1.5: Maintain combat buffs
    if self:CheckPriestCombatBuffs() then return true end
    
    -- PRIORITY 2: MANA MANAGEMENT (Holy specialty)
    if manaPercent < 30 and self:UseManaPotion(30) then
        PriestDebug("HOLY: Mana potion used")
        return true
    end
    
    -- Hymn of Hope for group mana (Holy specialty)
    if manaPercent < 20 and self:IsUsableSpell(S.HymnOfHope) and Throttle("HymnOfHope", 360) then
        if not UnitChannelInfo("player") then
            CastSpellByName(S.HymnOfHope)
            PriestDebug("HOLY: Hymn of Hope (group mana)")
            return true
        end
    end
    
    -- PRIORITY 3: DISPELLING
    if self:ActionThrottle("DispelCheckHoly", 0.5) then
        local units = {"player"}
        if IsInGroup() then
            local prefix = GetNumRaidMembers() > 0 and "raid" or "party"
            local max = GetNumRaidMembers() > 0 and GetNumRaidMembers() or GetNumPartyMembers()
            for i = 1, max do
                table.insert(units, prefix .. i)
            end
        end
        
        for _, unit in ipairs(units) do
            if UnitExists(unit) then
                local hasDispellable, topDebuff, urgentDispel, priority = self:AnalyzeDispelNeeds(unit)
                local unitHP = UnitHealth(unit) / UnitHealthMax(unit)
                
                if hasDispellable and (urgentDispel or priority >= 75 or unitHP < 0.70) then
                    if topDebuff.type == "Magic" and self:IsUsableSpell(S.DispelMagic) then
                        CastSpellByName(S.DispelMagic, unit)
                        PriestDebug("HOLY: Dispel Magic on " .. UnitName(unit) .. " (" .. topDebuff.name .. ")")
                        return true
                    elseif topDebuff.type == "Disease" and self:IsUsableSpell(S.AbolishDisease) then
                        CastSpellByName(S.AbolishDisease, unit)
                        PriestDebug("HOLY: Abolish Disease on " .. UnitName(unit) .. " (" .. topDebuff.name .. ")")
                        return true
                    end
                end
            end
        end
    end
    
    -- PRIORITY 4: EMERGENCY HEALING & ULTIMATE COOLDOWNS
    local emergencyTarget, emergencyHealth, emergencyInfo = self:FindPriestHealingTarget("emergency")
    if emergencyTarget and emergencyHealth < 0.20 then
        -- Guardian Spirit (ULTIMATE emergency - prevents death)
        if self:IsUsableSpell(S.GuardianSpirit) and Throttle("GuardianSpirit", 180) then
            CastSpellByName(S.GuardianSpirit, emergencyTarget)
            PriestDebug("HOLY ULTIMATE: Guardian Spirit on " .. UnitName(emergencyTarget) .. " (DEATH PREVENTION!)")
            return true
        end
        
        -- Surge of Light proc (instant Flash Heal)
        if self:HasBuff("player", S.SurgeOfLightBuff) and self:IsUsableSpell(S.FlashHeal) then
            CastSpellByName(S.FlashHeal, emergencyTarget)
            PriestDebug("HOLY EMERGENCY: Flash Heal with Surge of Light on " .. UnitName(emergencyTarget))
            return true
        end
        
        -- Flash Heal (fast emergency heal)
        if self:IsUsableSpell(S.FlashHeal) then
            CastSpellByName(S.FlashHeal, emergencyTarget)
            PriestDebug("HOLY EMERGENCY: Flash Heal on " .. UnitName(emergencyTarget))
            return true
        end
    end
    
    -- PRIORITY 5: GROUP EMERGENCY HEALING (Holy specialty)
    if groupHealth.needsEmergencyAOE or groupHealth.emergencyHealth >= 2 then
        -- Divine Hymn (ULTIMATE group heal)
        if self:IsUsableSpell(S.DivineHymn) and Throttle("DivineHymn", 480) then
            if not UnitChannelInfo("player") then
                CastSpellByName(S.DivineHymn)
                PriestDebug("HOLY ULTIMATE: Divine Hymn (GROUP EMERGENCY!)")
                return true
            end
        end
        
        -- Circle of Healing (instant group heal)
        if self:IsUsableSpell(S.CircleOfHealing) then
            local target = emergencyTarget or "player"
            CastSpellByName(S.CircleOfHealing, target)
            PriestDebug("HOLY EMERGENCY: Circle of Healing (group emergency)")
            return true
        end
        
        -- Prayer of Healing (group heal)
        if self:IsUsableSpell(S.PrayerOfHealing) and manaPercent > 25 then
            CastSpellByName(S.PrayerOfHealing)
            PriestDebug("HOLY EMERGENCY: Prayer of Healing")
            return true
        end
    end
    
    -- PRIORITY 6: RENEW BLANKET STRATEGY (Holy specialty)
    if self:ActionThrottle("RenewBlanket", 1) and manaPercent > 40 then
        local renewTargets = {}
        local units = {"player"}
        
        if IsInGroup() then
            local prefix = GetNumRaidMembers() > 0 and "raid" or "party"
            local max = GetNumRaidMembers() > 0 and GetNumRaidMembers() or GetNumPartyMembers()
            for i = 1, max do
                table.insert(units, prefix .. i)
            end
        end
        
        for _, unit in ipairs(units) do
            if UnitExists(unit) and not UnitIsDeadOrGhost(unit) then
                local hp = UnitHealth(unit) / UnitHealthMax(unit)
                if hp < 0.95 and not self:HasBuff(unit, S.Renew) then
                    table.insert(renewTargets, {unit = unit, health = hp})
                end
            end
        end
        
        -- Sort by lowest health first
        table.sort(renewTargets, function(a, b) return a.health < b.health end)
        
        -- Apply Renew to lowest health target without it
        if #renewTargets > 0 and self:IsUsableSpell(S.Renew) then
            local target = renewTargets[1]
            CastSpellByName(S.Renew, target.unit)
            PriestDebug("HOLY: Renew blanket on " .. UnitName(target.unit) .. " (" .. math.floor(target.health * 100) .. "% HP)")
            return true
        end
    end
    
    -- SMART HEALING PRIORITY 7: INTELLIGENT HEALING ALGORITHM
    -- Use advanced smart healing system for optimal spell selection
    if self:SmartHeal() then return true end
    
    -- PRIORITY 7.5: FALLBACK TO LEGACY HEALING ROTATION
    local healTarget, healTargetHealth, healInfo = self:FindPriestHealingTarget("normal")
    if healTarget and healTargetHealth < 0.90 then
        
        -- Circle of Healing (instant, powerful)
        if healTargetHealth < 0.75 and self:IsUsableSpell(S.CircleOfHealing) then
            CastSpellByName(S.CircleOfHealing, healTarget)
            PriestDebug("HOLY: Circle of Healing on " .. UnitName(healTarget))
            return true
        end
        
        -- Prayer of Mending (efficient bouncing heal)
        if healTargetHealth < 0.80 and self:IsUsableSpell(S.PrayerOfMending) and 
           Throttle("PrayerOfMendingHoly", 8) then
            CastSpellByName(S.PrayerOfMending, healTarget)
            PriestDebug("HOLY: Prayer of Mending on " .. UnitName(healTarget))
            return true
        end
        
        -- Flash Heal for quick response
        if healTargetHealth < 0.60 and self:IsUsableSpell(S.FlashHeal) then
            CastSpellByName(S.FlashHeal, healTarget)
            PriestDebug("HOLY: Flash Heal on " .. UnitName(healTarget))
            return true
        end
        
        -- Greater Heal with Serendipity optimization
        if healTargetHealth < 0.70 and manaPercent > 30 and self:IsUsableSpell(S.GreaterHeal) then
            local _, _, _, serendipityStacks = self:HasBuff("player", S.SerendipityBuff)
            if serendipityStacks and serendipityStacks >= 2 then
                if not UnitCastingInfo("player") then
                    CastSpellByName(S.GreaterHeal, healTarget)
                    PriestDebug("HOLY: Greater Heal with Serendipity (" .. serendipityStacks .. " stacks) on " .. UnitName(healTarget))
                    return true
                end
            elseif healTargetHealth < 0.55 then
                if not UnitCastingInfo("player") then
                    CastSpellByName(S.GreaterHeal, healTarget)
                    PriestDebug("HOLY: Greater Heal on " .. UnitName(healTarget))
                    return true
                end
            end
        end
        
        -- Binding Heal (heal self + target)
        if healTargetHealth < 0.75 and self:GetPlayerHealthPercent() < 80 and 
           self:IsUsableSpell(S.BindingHeal) then
            CastSpellByName(S.BindingHeal, healTarget)
            PriestDebug("HOLY: Binding Heal (self + " .. UnitName(healTarget) .. ")")
            return true
        end
    end
    
    -- PRIORITY 8: GROUP HEALING (Holy excels at this)
    if groupHealth.needsAOE and manaPercent > 30 then
        -- Circle of Healing first (instant)
        if self:IsUsableSpell(S.CircleOfHealing) then
            local target = healTarget or "player"
            CastSpellByName(S.CircleOfHealing, target)
            PriestDebug("HOLY: Circle of Healing (group damage)")
            return true
        end
        
        -- Prayer of Healing (powerful group heal)
        if self:IsUsableSpell(S.PrayerOfHealing) and manaPercent > 35 then
            CastSpellByName(S.PrayerOfHealing)
            PriestDebug("HOLY: Prayer of Healing (group damage)")
            return true
        end
        
        -- Holy Nova (if enemies nearby)
        if self:GetEnemyCount() > 0 and self:IsUsableSpell(S.HolyNova) then
            CastSpellByName(S.HolyNova)
            PriestDebug("HOLY: Holy Nova (heal + damage)")
            return true
        end
    end
    
    -- PRIORITY 9: LIGHTWELL MAINTENANCE
    if self:IsUsableSpell(S.Lightwell) and Throttle("LightwellCheck", 30) and IsInGroup() then
        -- Place Lightwell if in group and don't have one
        CastSpellByName(S.Lightwell)
        PriestDebug("HOLY: Lightwell placed")
        return true
    end
    
    -- PRIORITY 10: OFFENSIVE ABILITIES (When healing not needed)
    if hasTarget and groupHealth.avgHealth > 0.90 and manaPercent > 60 then
        
        -- Offensive cooldowns
        if self:UsePriestOffensives("Holy") then return true end
        
        -- Holy Fire (main damage + DoT)
        if not self:HasDebuff("target", S.HolyFire) and self:IsUsableSpell(S.HolyFire) then
            CastSpellByName(S.HolyFire, "target")
            PriestDebug("HOLY: Holy Fire")
            return true
        end
        
        -- Shadow Word: Pain (DoT)
        if self:DebuffTimeRemaining("target", S.ShadowWordPain) < 3 and 
           self:IsUsableSpell(S.ShadowWordPain) and not self:IsFastDyingMob("target") then
            CastSpellByName(S.ShadowWordPain, "target")
            PriestDebug("HOLY: Shadow Word: Pain")
            return true
        end
        
        -- Smite (damage filler)
        if self:IsUsableSpell(S.Smite) and not UnitCastingInfo("player") then
            CastSpellByName(S.Smite, "target")
            PriestDebug("HOLY: Smite")
            return true
        end
    end
    
    return false
end

-- MAIN PRIEST ROTATION
function AC:PriestRotation()
    local spec = self:GetPlayerSpec()
    local level = UnitLevel("player")
    local inCombat = UnitAffectingCombat("player")
    local hasTarget = UnitExists("target") and UnitCanAttack("player", "target") and not UnitIsDeadOrGhost("target")
    
    -- Emergency Lifeblood (Herbalism profession ability) at 50% health
    if inCombat and self:UseLifeblood() then return true end
    
    -- Out of combat
    if not inCombat then
        -- Buffs (includes group buffing)
        if self:CheckPriestBuffs() then return true end
        
        -- Combat rebuffing (for group members who lost buffs)
        if IsInGroup() and self:CheckPriestCombatBuffs() then return true end
        
        -- Pull
        if hasTarget and not UnitAffectingCombat("target") then
            -- Shadow pulls with SW:P
            if spec == "Shadow" then
                if not self:HasBuff("player", S.Shadowform) and self:IsUsableSpell(S.Shadowform) then
                    CastSpellByName(S.Shadowform)
                    return true
                end
                if self:IsUsableSpell(S.ShadowWordPain) then
                    CastSpellByName(S.ShadowWordPain, "target")
                    return true
                end
            else
                -- Holy/Disc pull with Holy Fire or Smite
                if self:IsUsableSpell(S.HolyFire) then
                    CastSpellByName(S.HolyFire, "target")
                    return true
                elseif self:IsUsableSpell(S.Smite) then
                    CastSpellByName(S.Smite, "target")
                    return true
                end
            end
        end
        
        return false
    end
    
    -- In combat - check for racials
    self:UsePriestRacials(true, false)
    
    -- Spec dispatch
    if spec == "Shadow" then
        return self:ShadowPriestRotation()
    elseif spec == "Discipline" then
        return self:DisciplinePriestRotation()
    elseif spec == "Holy" then
        return self:HolyPriestRotation()
    else
        -- Leveling rotation
        local mana = UnitPower("player", 0)
        local maxMana = UnitPowerMax("player", 0)
        local manaPercent = (maxMana > 0) and (mana/maxMana*100) or 100
        
        -- Basic self preservation
        if self:GetPlayerHealthPercent() < 70 and self:IsUsableSpell(S.PowerWordShield) and
           not self:HasDebuff("player", "Weakened Soul") then
            CastSpellByName(S.PowerWordShield, "player")
            PriestDebug("Leveling: PW:Shield")
            return true
        end
        
        if self:GetPlayerHealthPercent() < 50 and self:IsUsableSpell(S.FlashHeal) then
            CastSpellByName(S.FlashHeal, "player")
            PriestDebug("Leveling: Flash Heal")
            return true
        end
        
        -- Basic DPS
        if hasTarget then
            if self:DebuffTimeRemaining("target", S.ShadowWordPain) < 3 and 
               self:IsUsableSpell(S.ShadowWordPain) and not self:IsFastDyingMob("target") then
                CastSpellByName(S.ShadowWordPain, "target")
                PriestDebug("Leveling: SW:Pain")
                return true
            end
            
            if self:IsUsableSpell(S.MindBlast) and manaPercent > 20 then
                CastSpellByName(S.MindBlast, "target")
                PriestDebug("Leveling: Mind Blast")
                return true
            end
            
            if level >= 20 and self:IsUsableSpell(S.MindFlay) and manaPercent > 15 then
                if not UnitChannelInfo("player") then
                    CastSpellByName(S.MindFlay, "target")
                    PriestDebug("Leveling: Mind Flay")
                    return true
                end
            end
            
            if self:IsUsableSpell(S.Smite) and manaPercent > 10 then
                if not UnitCastingInfo("player") then
                    CastSpellByName(S.Smite, "target")
                    PriestDebug("Leveling: Smite")
                    return true
                end
            end
            
            -- Wand if low mana
            if manaPercent < 20 and not IsAutoRepeatSpell(S.Shoot) then
                CastSpellByName(S.Shoot, "target")
                PriestDebug("Leveling: Wand")
                return true
            end
        end
    end
    
    return false
end

-- INITIALIZATION
function AC:InitPriestRotations()
    self.rotations = self.rotations or {}
    self.rotations["PRIEST"] = {}
    
    self.rotations["PRIEST"]["Discipline"] = function(s) return s:PriestRotation() end
    self.rotations["PRIEST"]["Holy"] = function(s) return s:PriestRotation() end
    self.rotations["PRIEST"]["Shadow"] = function(s) return s:PriestRotation() end
    self.rotations["PRIEST"]["None"] = function(s) return s:PriestRotation() end
    
    self.CheckPriestBuffs = AC.CheckPriestBuffs
    self.CheckPriestGroupBuffs = AC.CheckPriestGroupBuffs
    self.CheckPriestCombatBuffs = AC.CheckPriestCombatBuffs
    
    self:Print("Priest rotations (ULTIMATE WotLK 3.3.5a) initialized - BEAST HEALER + SHADOW DPS!")
    PriestDebug("ULTIMATE FEATURES:")
    PriestDebug("+ Discipline: Shield Master - Proactive damage prevention & Smite healing")
    PriestDebug("+ Holy: Group Heal Beast - AOE healing mastery & Renew blankets")
    PriestDebug("+ Shadow: DPS Monster - DoT management & Mind Flay optimization")
    PriestDebug("+ Advanced: Smart healing priority, emergency response, dispel mastery")
    PriestDebug("+ Group AI: Tank priority, healer protection, role-based healing")
    PriestDebug("+ EPIC BUFFING: Fortitude, Divine Spirit, Shadow Protection, Fear Ward")
    PriestDebug("+ EPIC REBUFFING: Combat buff maintenance for group members")
    PriestDebug("+ Utility: All racials, potions, trinkets, cooldown optimization")
end
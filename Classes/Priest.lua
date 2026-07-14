-- AzeroCombat: WotLK 3.3.5a Priest rotations
-- Shadow DPS, Discipline absorbs/triage, Holy raid healing, and leveling support
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
    
    -- Shadow Spec (DPS Beast)
    DevouringPlague = "Devouring Plague",
    VampiricTouch = "Vampiric Touch",
    VampiricEmbrace = "Vampiric Embrace",
    Shadowform = "Shadowform",
    Dispersion = "Dispersion",
    MindSear = "Mind Sear",
    Shadowfiend = "Shadowfiend",
    Silence = "Silence",
    PsychicHorror = "Psychic Horror", -- Shadow talent

    -- Discipline Spec (absorbs, mitigation, and triage)
    Penance = "Penance",
    InnerFocus = "Inner Focus",
    PowerInfusion = "Power Infusion",
    PainSuppression = "Pain Suppression",
    BorrowedTime = "Borrowed Time", -- Disc talent effect
    GraceDebuff = "Grace", -- Disc talent effect
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
    
    -- Buff Spells
    PowerWordFortitude = "Power Word: Fortitude",
    PrayerOfFortitude = "Prayer of Fortitude",
    InnerFire = "Inner Fire",
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
    SurgeOfLightBuff = "Surge of Light",
    SerendipityBuff = "Serendipity",
    SpiritOfRedemptionBuff = "Spirit of Redemption",
    
    -- Racial Abilities (All Races)
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
    local _, playerClass = UnitClass("player")
    if playerClass == "DRUID" and self.DruidIsFastDyingMob then
        return self:DruidIsFastDyingMob(unit)
    elseif playerClass == "HUNTER" and self.HunterIsFastDyingMob then
        return self:HunterIsFastDyingMob(unit)
    elseif playerClass == "WARLOCK" and self.WarlockIsFastDyingMob then
        return self:WarlockIsFastDyingMob(unit)
    end

    if not unit or not UnitExists(unit) then return false end
    local hp = UnitHealth(unit)
    local maxHp = UnitHealthMax(unit)
    if not maxHp or maxHp <= 0 then return true end
    local hpPercent = (hp / maxHp) * 100
    return hpPercent < 20 or hp < 10000
end

local function PriestUnitInHealingRange(unit)
    if not unit or not UnitExists(unit) then return false end
    if UnitIsUnit(unit, "player") then return true end
    if not IsSpellInRange then return true end

    local inRange = IsSpellInRange(S.FlashHeal, unit)
    if inRange ~= nil then return inRange == 1 end
    inRange = IsSpellInRange(S.PowerWordShield, unit)
    if inRange ~= nil then return inRange == 1 end
    return true
end

function AC:EmergencyTriage()
    local _, playerClass = UnitClass("player")
    if playerClass == "PALADIN" and self.PaladinEmergencyTriage then
        return self:PaladinEmergencyTriage()
    end
    if playerClass ~= "PRIEST" then return false end

    local target, health = self:FindPriestHealingTarget("emergency")
    if not target or health >= 0.30 then return false end

    local spec = self:GetPlayerSpec()
    if (spec == "Holy" and health < 0.20) or
       (spec == "Discipline" and health < 0.25) then
        if spec == "Holy" and self:IsUsableSpell(S.GuardianSpirit) and
           self:CastSpell(S.GuardianSpirit, target) then
            PriestDebug("Emergency: Guardian Spirit on " .. UnitName(target))
            return true
        elseif spec == "Discipline" and self:IsUsableSpell(S.PainSuppression) and
               self:CastSpell(S.PainSuppression, target) then
            PriestDebug("Emergency: Pain Suppression on " .. UnitName(target))
            return true
        end
    end

    if not self:HasDebuff(target, S.WeakenedSoulDebuff) and
       self:IsUsableSpell(S.PowerWordShield) and
       self:CastSpell(S.PowerWordShield, target) then
        return true
    end
    if health < 0.25 and self:IsUsableSpell(S.Penance) and
       self:CastSpell(S.Penance, target) then
        return true
    end
    return self:IsUsableSpell(S.FlashHeal) and self:CastSpell(S.FlashHeal, target)
end

function AC:SmartHeal()
    local _, playerClass = UnitClass("player")
    if playerClass == "PALADIN" and self.PaladinSmartHeal then
        return self:PaladinSmartHeal()
    end
    if playerClass ~= "PRIEST" then return false end

    local target, health = self:FindPriestHealingTarget("normal")
    if not target or health >= 0.90 then return false end

    local spec = self:GetPlayerSpec()
    local playerHealth = self:GetPlayerHealthPercent() / 100

    if target ~= "player" and health < 0.72 and playerHealth < 0.75 and
       self:IsUsableSpell(S.BindingHeal) and self:CastSpell(S.BindingHeal, target) then
        return true
    end

    if spec == "Discipline" then
        if health < 0.72 and self:IsUsableSpell(S.Penance) and
           self:CastSpell(S.Penance, target) then
            return true
        end
        if health < 0.88 and not self:HasDebuff(target, S.WeakenedSoulDebuff) and
           self:IsUsableSpell(S.PowerWordShield) and self:CastSpell(S.PowerWordShield, target) then
            return true
        end
        if health < 0.45 and self:IsUsableSpell(S.FlashHeal) and
           self:CastSpell(S.FlashHeal, target) then
            return true
        end
        if health < 0.68 and self:IsUsableSpell(S.GreaterHeal) and
           self:CastSpell(S.GreaterHeal, target) then
            return true
        end
    else
        if self:HasBuff("player", S.SurgeOfLightBuff) and health < 0.90 and
           self:IsUsableSpell(S.FlashHeal) and self:CastSpell(S.FlashHeal, target) then
            return true
        end
        if health >= 0.60 and health < 0.85 and self:IsUsableSpell(S.PrayerOfMending) and
           Throttle("PriestSmartPoM", 8) and self:CastSpell(S.PrayerOfMending, target) then
            return true
        end
        if health >= 0.65 and health < 0.85 and self:IsUsableSpell(S.Renew) and
           not self:HasBuff(target, S.Renew) and self:CastSpell(S.Renew, target) then
            return true
        end
        if health < 0.45 and self:IsUsableSpell(S.FlashHeal) and
           self:CastSpell(S.FlashHeal, target) then
            return true
        end
        if health < 0.68 and self:IsUsableSpell(S.GreaterHeal) and
           self:CastSpell(S.GreaterHeal, target) then
            return true
        end
    end

    return false
end

function AC:CheckPriestCombatBuffs()
    local _, playerClass = UnitClass("player")
    if playerClass ~= "PRIEST" then return false end
    -- Combat buff maintenance is intentionally conservative.  The normal
    -- defensive and healing priorities handle shields and emergency globals.
    return false
end

function AC:ActionThrottle(action, interval)
    if self.CoreActionThrottle then
        return self:CoreActionThrottle(action, interval)
    end
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
        priority = (1 - selfHealth) * 200 + 2
    }
    table.insert(targets, selfTarget)
    if selfHealth < 0.25 then table.insert(emergencyTargets, selfTarget) end
    
    -- Check group members
    if IsInGroup() then
        local prefix = GetNumRaidMembers() > 0 and "raid" or "party"
        local max = GetNumRaidMembers() > 0 and GetNumRaidMembers() or GetNumPartyMembers()
        
        for i = 1, max do
            local unit = prefix .. i
            if UnitExists(unit) and not UnitIsUnit(unit, "player") and PriestUnitInHealingRange(unit) and
               not UnitIsDeadOrGhost(unit) and UnitIsConnected(unit) then
                local maxHealth = UnitHealthMax(unit)
                local hp = maxHealth > 0 and UnitHealth(unit) / maxHealth or 0
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
                
                -- Missing health is the primary signal; role bonuses break
                -- close calls without allowing a healthy unit to hide a
                -- genuinely injured group member.
                target.priority = (1 - hp) * 200 +
                                  (isTank and 15 or 0) +
                                  (isHealer and 5 or 0)
                if hp < 0.25 then table.insert(emergencyTargets, target) end
                
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
            if UnitExists(unit) and not UnitIsUnit(unit, "player") and
               not UnitIsDeadOrGhost(unit) and UnitIsConnected(unit) then
                analysis.totalMembers = analysis.totalMembers + 1
                local maxHealth = UnitHealthMax(unit)
                local hp = maxHealth > 0 and UnitHealth(unit) / maxHealth or 0
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
    
    analysis.needsAOE = analysis.totalMembers >= 3 and
                        (lowHealthRatio >= 0.5 or analysis.lowHealth >= 3)
    analysis.needsEmergencyAOE = analysis.totalMembers >= 3 and
                                 (criticalRatio >= 0.4 or analysis.criticalHealth >= 3 or
                                  analysis.emergencyHealth >= 2)
    
    return analysis
end

-- Simplified function for backward compatibility
function AC:GroupNeedsAOEHealing()
    local analysis = self:AnalyzeGroupHealth()
    return analysis.needsAOE
end

-- Prayer of Healing and Circle of Healing affect the selected unit's party.
-- Pick an injured member of the raid subgroup with the largest total deficit.
function AC:FindPriestGroupHealTarget(threshold)
    threshold = threshold or 0.85
    local raidCount = GetNumRaidMembers()

    if raidCount > 0 then
        local groups = {}
        for i = 1, raidCount do
            local unit = "raid" .. i
            if UnitExists(unit) and PriestUnitInHealingRange(unit) and
               not UnitIsDeadOrGhost(unit) and UnitIsConnected(unit) then
                local _, _, subgroup = GetRaidRosterInfo(i)
                subgroup = subgroup or 1
                groups[subgroup] = groups[subgroup] or {count = 0, deficit = 0, unit = unit, health = 1}

                local maxHealth = UnitHealthMax(unit)
                local hp = maxHealth > 0 and UnitHealth(unit) / maxHealth or 0
                if hp < threshold then
                    groups[subgroup].count = groups[subgroup].count + 1
                    groups[subgroup].deficit = groups[subgroup].deficit + (1 - hp)
                    if hp < groups[subgroup].health then
                        groups[subgroup].unit = unit
                        groups[subgroup].health = hp
                    end
                end
            end
        end

        local best, bestScore
        for _, group in pairs(groups) do
            local score = group.count * 10 + group.deficit
            if not bestScore or score > bestScore then
                best, bestScore = group, score
            end
        end
        if best and best.count > 0 then return best.unit, best.count end
        return nil, 0
    end

    local bestUnit, bestHealth, injured = "player", 1, 0
    local units = {"player"}
    for i = 1, GetNumPartyMembers() do units[#units + 1] = "party" .. i end
    for _, unit in ipairs(units) do
        if UnitExists(unit) and PriestUnitInHealingRange(unit) and
           not UnitIsDeadOrGhost(unit) and UnitIsConnected(unit) then
            local maxHealth = UnitHealthMax(unit)
            local hp = maxHealth > 0 and UnitHealth(unit) / maxHealth or 0
            if hp < threshold then
                injured = injured + 1
                if hp < bestHealth then
                    bestUnit, bestHealth = unit, hp
                end
            end
        end
    end
    return injured > 0 and bestUnit or nil, injured
end

function AC:FindPriestTankUnit()
    local prefix = GetNumRaidMembers() > 0 and "raid" or "party"
    local count = GetNumRaidMembers() > 0 and GetNumRaidMembers() or GetNumPartyMembers()
    for i = 1, count do
        local unit = prefix .. i
        if UnitExists(unit) and PriestUnitInHealingRange(unit) and
           not UnitIsDeadOrGhost(unit) and UnitIsConnected(unit) and
           self:IsTank(unit) then
            return unit
        end
    end
    return nil
end

function AC:FindPriestShieldTarget()
    local raidCount = GetNumRaidMembers()
    local units = {"player"}
    local prefix = raidCount > 0 and "raid" or "party"
    local count = raidCount > 0 and raidCount or GetNumPartyMembers()
    for i = 1, count do
        local unit = prefix .. i
        if not UnitIsUnit(unit, "player") then units[#units + 1] = unit end
    end

    local bestUnit, bestPriority
    for _, unit in ipairs(units) do
        if UnitExists(unit) and PriestUnitInHealingRange(unit) and
           not UnitIsDeadOrGhost(unit) and UnitIsConnected(unit) and
           not self:HasDebuff(unit, S.WeakenedSoulDebuff) then
            local maxHealth = UnitHealthMax(unit)
            local hp = maxHealth > 0 and UnitHealth(unit) / maxHealth or 0
            local tank = self:IsTank(unit)
            local eligible = tank or hp < 0.92 or raidCount > 5
            if eligible then
                local priority = (1 - hp) * 100 + (tank and 30 or 0)
                if not bestPriority or priority > bestPriority then
                    bestUnit, bestPriority = unit, priority
                end
            end
        end
    end
    return bestUnit
end

-- ULTIMATE: Advanced dispel priority system
function AC:AnalyzeDispelNeeds(unit)
    if not UnitExists(unit) or not PriestUnitInHealingRange(unit) then
        return false, nil, nil, 0
    end
    
    local dispellableDebuffs = {}
    local highestPriority = 0
    local urgentDispel = false
    
    -- Comprehensive dispel priority database
    local dispelPriorities = {
        -- Emergency dispels (95-100 priority)
        ["Fear"] = 100,
        ["Polymorph"] = 100,
        ["Banish"] = 100,
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
    while i <= 40 do
        -- WotLK returns rank and icon before count. Keeping these positions
        -- exact is required or debuffType is read as the stack count.
        local name, _, _, count, debuffType, duration, expirationTime = UnitDebuff(unit, i)
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
            local maxHealth = UnitHealthMax(unit)
            local hp = maxHealth > 0 and UnitHealth(unit) / maxHealth or 0
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

function AC:TryPriestPriorityDispel(minPriority)
    minPriority = minPriority or 90
    local units = {"player"}
    local prefix = GetNumRaidMembers() > 0 and "raid" or "party"
    local count = GetNumRaidMembers() > 0 and GetNumRaidMembers() or GetNumPartyMembers()
    for i = 1, count do
        local unit = prefix .. i
        if not UnitIsUnit(unit, "player") then units[#units + 1] = unit end
    end

    local bestUnit, bestDebuff, bestPriority
    for _, unit in ipairs(units) do
        local hasDispel, debuff, _, priority = self:AnalyzeDispelNeeds(unit)
        if hasDispel and priority >= minPriority and
           (not bestPriority or priority > bestPriority) then
            bestUnit, bestDebuff, bestPriority = unit, debuff, priority
        end
    end
    if not bestUnit then return false end

    if bestDebuff.type == "Magic" and self:IsUsableSpell(S.DispelMagic) then
        if self:CastSpell(S.DispelMagic, bestUnit) then
            PriestDebug("Priority dispel on " .. UnitName(bestUnit) .. ": " .. bestDebuff.name)
            return true
        end
    elseif bestDebuff.type == "Disease" then
        local spell = self:IsUsableSpell(S.AbolishDisease) and S.AbolishDisease or S.CureDisease
        if self:IsUsableSpell(spell) and self:CastSpell(spell, bestUnit) then
            PriestDebug("Priority disease removal on " .. UnitName(bestUnit) .. ": " .. bestDebuff.name)
            return true
        end
    end
    return false
end

-- ENHANCED: Racial abilities
function AC:UsePriestRacials(offensive, defensive)
    if not Throttle("PriestRacials", 3) then return false end
    
    local _, race = UnitRace("player")
    race = string.upper(race)
    local health = self:GetPlayerHealthPercent()
    local inCombat = UnitAffectingCombat("player")

    local fearCharmSleep = {
        ["Fear"] = true, ["Psychic Scream"] = true, ["Howl of Terror"] = true,
        ["Seduction"] = true, ["Repentance"] = true, ["Wyvern Sting"] = true,
    }
    local generalControl = {
        ["Polymorph"] = true, ["Hammer of Justice"] = true, ["Cheap Shot"] = true,
        ["Kidney Shot"] = true, ["Sap"] = true, ["Blind"] = true,
        ["Freezing Trap"] = true, ["Intimidation"] = true,
    }
    local hasFearControl, hasGeneralControl = false, false
    for i = 1, 40 do
        local name = UnitDebuff("player", i)
        if not name then break end
        if fearCharmSleep[name] then hasFearControl = true end
        if fearCharmSleep[name] or generalControl[name] then hasGeneralControl = true end
    end

    local function castRacial(spellName, message)
        if self:CastSpell(spellName, "player") then
            PriestDebug(message)
            return true
        end
        return false
    end
    
    -- Offensive racials
    local classification = UnitExists("target") and UnitClassification("target") or nil
    local worthyTarget = classification == "elite" or classification == "rareelite" or
                         classification == "worldboss" or
                         (UnitExists("target") and UnitHealth("target") > 100000)
    if offensive and inCombat and worthyTarget then
        if race == "TROLL" and castRacial(S.Berserking, "Racial: Berserking") then return true end
        if race == "BLOODELF" and self:IsUsableSpell(S.ArcaneTorrent) then
            local mana = UnitPower("player", 0) / UnitPowerMax("player", 0) * 100
            if mana < 50 then
                if castRacial(S.ArcaneTorrent, "Racial: Arcane Torrent") then return true end
            end
        end
    end
    
    -- Defensive racials
    if defensive or health < 50 then
        if (race == "SCOURGE" or race == "UNDEAD") and hasFearControl and
           castRacial(S.WillOfTheForsaken, "Racial: Will of the Forsaken") then return true end
        if race == "DWARF" and health < 40 and
           castRacial(S.Stoneform, "Racial: Stoneform") then return true end
        if race == "HUMAN" and hasGeneralControl and
           castRacial(S.EveryManForHimself, "Racial: Every Man for Himself") then return true end
        if race == "DRAENEI" and health < 45 and
           castRacial(S.GiftOfTheNaaru, "Racial: Gift of the Naaru") then return true end
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
        if not self:CastSpell(S.PowerWordShield, "player") then return false end
        PriestDebug("Power Word: Shield (self)")
        return true
    end
    
    -- Desperate Prayer
    if health < 40 and self:IsUsableSpell(S.DesperatePrayer) then
        if not self:CastSpell(S.DesperatePrayer) then return false end
        PriestDebug("Desperate Prayer")
        return true
    end
    
    -- Fade only helps with threat; do not waste it merely because enemies exist.
    local threat = UnitExists("target") and UnitThreatSituation and
                   UnitThreatSituation("player", "target") or nil
    if IsInGroup() and threat and threat >= 2 and self:IsUsableSpell(S.Fade) then
        if not self:CastSpell(S.Fade) then return false end
        PriestDebug("Fade (high threat)")
        return true
    end
    
    -- Psychic Scream
    local inInstance = IsInInstance()
    if health < 30 and self:GetEnemyCount() >= 2 and (not IsInGroup() or not inInstance) and
       self:IsUsableSpell(S.PsychicScream) then
        if not self:CastSpell(S.PsychicScream) then return false end
        PriestDebug("Psychic Scream")
        return true
    end
    
    -- Dispersion (Shadow)
    if health < 25 and self:IsUsableSpell(S.Dispersion) then
        if not self:CastSpell(S.Dispersion) then return false end
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

-- Mana cooldowns are useful to every Priest spec. Shadowfiend is preferred
-- early enough to restore meaningful mana; Hymn is reserved for safe windows.
function AC:UsePriestManaCooldowns(groupHealth)
    local maxMana = UnitPowerMax("player", 0)
    if maxMana <= 0 then return false end

    local manaPercent = UnitPower("player", 0) / maxMana * 100
    local validEnemy = UnitExists("target") and UnitCanAttack("player", "target") and
                       not UnitIsDeadOrGhost("target")

    if manaPercent < 65 and validEnemy and self:IsUsableSpell(S.Shadowfiend) and
       self:CastSpell(S.Shadowfiend, "target") then
        PriestDebug("Shadowfiend for mana")
        return true
    end

    local safeToChannel = not self:IsPlayerMoving() and
                          (not groupHealth or groupHealth.criticalHealth == 0)
    if manaPercent < 20 and safeToChannel and self:IsUsableSpell(S.HymnOfHope) and
       self:CastSpell(S.HymnOfHope, "player") then
        PriestDebug("Hymn of Hope for mana")
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

    if spec == "Shadow" and self:IsUsableSpell(S.Shadowfiend) and
       self:CastSpell(S.Shadowfiend, "target") then
        PriestDebug("Shadowfiend (damage cooldown)")
        if self.UseTrinkets then self:UseTrinkets() end
        if (targetClass == "worldboss" or UnitHealth("target") > 500000) and
           self.UseOffensivePotion then
            self:UseOffensivePotion(true)
        end
        return true
    end
    
    -- Discipline offensive PI
    if spec == "Discipline" and self:IsUsableSpell(S.PowerInfusion) and 
       Throttle("PowerInfusionDisc", 120) then
        if not self:CastSpell(S.PowerInfusion, "player") then return false end
        PriestDebug("Power Infusion (Disc)")
        return true
    end
    
    return false
end

-- BUFF MANAGEMENT
function AC:CheckPriestBuffs()
    if UnitAffectingCombat("player") then return false end
    
    -- Inner Fire
    if not self:HasBuff("player", S.InnerFire) and self:IsUsableSpell(S.InnerFire) then
        if not self:CastSpell(S.InnerFire, "player") then return false end
        PriestDebug("Buffing: Inner Fire")
        return true
    end
    
    -- Fortitude
    local fortSpell = IsInGroup() and self:IsUsableSpell(S.PrayerOfFortitude) and
                      S.PrayerOfFortitude or S.PowerWordFortitude
    if not self:HasBuff("player", S.PowerWordFortitude) and
       not self:HasBuff("player", S.PrayerOfFortitude) then
        if self:IsUsableSpell(fortSpell) then
            if not self:CastSpell(fortSpell, "player") then return false end
            PriestDebug("Buffing: " .. fortSpell)
            return true
        end
    end
    
    -- Divine Spirit
    local spiritSpell = IsInGroup() and self:IsUsableSpell(S.PrayerOfSpirit) and
                        S.PrayerOfSpirit or S.DivineSpirit
    if not self:HasBuff("player", S.DivineSpirit) and
       not self:HasBuff("player", S.PrayerOfSpirit) then
        if self:IsUsableSpell(spiritSpell) then
            if not self:CastSpell(spiritSpell, "player") then return false end
            PriestDebug("Buffing: " .. spiritSpell)
            return true
        end
    end
    
    -- Shadow Protection (situational)
    local shadowSpell = IsInGroup() and self:IsUsableSpell(S.PrayerOfShadowProtection) and
                        S.PrayerOfShadowProtection or S.ShadowProtection
    if IsInInstance() and not self:HasBuff("player", S.ShadowProtection) and
       not self:HasBuff("player", S.PrayerOfShadowProtection) then
        if self:IsUsableSpell(shadowSpell) then
            if not self:CastSpell(shadowSpell, "player") then return false end
            PriestDebug("Buffing: " .. shadowSpell)
            return true
        end
    end
    
    return false
end

function AC:CheckPriestGroupBuffs()
    return self:CheckPriestBuffs()
end

-- ENHANCED SHADOW PRIEST ROTATION WITH DOT MANAGEMENT
function AC:ShadowPriestRotation()
    local mana = UnitPower("player", 0)
    local maxMana = UnitPowerMax("player", 0)
    local manaPercent = (maxMana > 0) and (mana/maxMana*100) or 100
    local health = self:GetPlayerHealthPercent()
    local enemies = self:GetEnemyCount()
    local hasTarget = UnitExists("target") and UnitCanAttack("player", "target") and not UnitIsDeadOrGhost("target")
    
    -- Shadowform check (required for Shadow)
    if not self:HasBuff("player", S.Shadowform) and self:IsUsableSpell(S.Shadowform) then
        if not self:CastSpell(S.Shadowform) then return false end
        PriestDebug("Shadow: Entering Shadowform")
        return true
    end

    -- Maintain Vampiric Embrace for passive self/group healing.
    if self:IsUsableSpell(S.VampiricEmbrace) and not self:HasBuff("player", S.VampiricEmbrace) then
        if not self:CastSpell(S.VampiricEmbrace, "player") then return false end
        PriestDebug("Shadow: Vampiric Embrace")
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

    if self:UsePriestManaCooldowns() then return true end
    
    -- Mana management
    if manaPercent < 30 and self:UseManaPotion(30) then
        PriestDebug("Used mana potion")
        return true
    end
    
    if manaPercent < 20 and self:IsUsableSpell(S.Dispersion) then
        if not self:CastSpell(S.Dispersion) then return false end
        PriestDebug("Shadow: Dispersion for mana")
        return true
    end
    
    local targetHP = self:GetTargetHealthPercent("target")
    local isFastDying = self:IsFastDyingMob("target")
    local isMoving = self:IsPlayerMoving()
    
    -- Interrupt with Silence using the shared priority filter
    if self.TryInterrupt and self:TryInterrupt(S.Silence, "target") then
        PriestDebug("Shadow: Silence interrupt")
        return true
    end

    -- Psychic Horror fallback when Silence is unavailable and the target is still casting.
    local targetClassification = UnitClassification("target")
    if (UnitCastingInfo("target") or UnitChannelInfo("target")) and
       self:IsUsableSpell(S.PsychicHorror) and
       (not self:KnowsSpell(S.Silence) or self:GetSpellCooldown(S.Silence) > 0) and
       targetClassification ~= "worldboss" then
        if not self:CastSpell(S.PsychicHorror, "target") then return false end
        PriestDebug("Shadow: Psychic Horror control")
        return true
    end

    if self:ActionThrottle("ShadowPriorityDispel", 0.5) and
       self:TryPriestPriorityDispel(90) then
        return true
    end

    -- While moving, skip casted filler and only spend globals on instant or execute tools.
    if isMoving then
        if not isFastDying and not self:HasDebuff("target", S.DevouringPlague) and
           self:IsUsableSpell(S.DevouringPlague) and self:CastSpell(S.DevouringPlague, "target") then
            PriestDebug("Shadow: Devouring Plague (moving)")
            return true
        end

        if not isFastDying and not self:HasDebuff("target", S.ShadowWordPain) and
           self:IsUsableSpell(S.ShadowWordPain) then
            local hasWeaving, weavingStacks = self:HasBuff("player", S.ShadowWeavingDebuff)
            if (not hasWeaving or (weavingStacks or 0) >= 5) and
               self:CastSpell(S.ShadowWordPain, "target") then
                PriestDebug("Shadow: Shadow Word: Pain (moving)")
                return true
            end
        end

        if targetHP < 35 and health > 45 and self:IsUsableSpell(S.ShadowWordDeath) then
            if not self:CastSpell(S.ShadowWordDeath, "target") then return false end
            PriestDebug("Shadow: Shadow Word: Death (moving)")
            return true
        end

        return false
    end

    -- Glyph of Shadow Word: Death improves the execute range, but avoid lethal backlash.
    if targetHP < 35 and health > 45 and self:IsUsableSpell(S.ShadowWordDeath) then
        if not self:CastSpell(S.ShadowWordDeath, "target") then return false end
        PriestDebug("Shadow: Shadow Word: Death")
        return true
    end
    
    -- AoE rotation
    if self:ShouldUseMultiTarget(4, enemies) and manaPercent > 30 then
        -- Mind Sear spam
        if self:IsUsableSpell(S.MindSear) and not UnitChannelInfo("player") then
            if not self:CastSpell(S.MindSear, "target") then return false end
            PriestDebug("Shadow: Mind Sear (AoE)")
            return true
        end
    end
    
    -- WotLK has no Pandemic carry-over. VT is started just before expiry so
    -- it lands after the final tick; instant DP is allowed to expire.
    if not isFastDying then
        local vtRemaining = self:DebuffTimeRemaining("target", S.VampiricTouch)
        if (vtRemaining == 0 or vtRemaining <= 1.5) and self:IsUsableSpell(S.VampiricTouch) then
            if not self:CastSpell(S.VampiricTouch, "target") then return false end
            PriestDebug("Shadow: Vampiric Touch")
            return true
        end

        local dpRemaining = self:DebuffTimeRemaining("target", S.DevouringPlague)
        if dpRemaining == 0 and self:IsUsableSpell(S.DevouringPlague) then
            if not self:CastSpell(S.DevouringPlague, "target") then return false end
            PriestDebug("Shadow: Devouring Plague")
            return true
        end

        -- Pain and Suffering rolls SW:P indefinitely. Apply it at five Shadow
        -- Weaving stacks when that talent buff is active; otherwise apply it
        -- normally for leveling/hybrid builds.
        if not self:HasDebuff("target", S.ShadowWordPain) and self:IsUsableSpell(S.ShadowWordPain) then
            local hasWeaving, weavingStacks = self:HasBuff("player", S.ShadowWeavingDebuff)
            if not hasWeaving or (weavingStacks or 0) >= 5 then
                if not self:CastSpell(S.ShadowWordPain, "target") then return false end
                PriestDebug("Shadow: Shadow Word: Pain")
                return true
            end
        end
    end

    -- Use long cooldowns after the opener DoTs are established.
    if self:UsePriestOffensives("Shadow") then return true end
    
    -- Mind Blast on cooldown
    if self:IsUsableSpell(S.MindBlast) and self:GetSpellCooldown(S.MindBlast) == 0 and manaPercent > 10 then
        if not self:CastSpell(S.MindBlast, "target") then return false end
        PriestDebug("Shadow: Mind Blast")
        return true
    end
    
    -- Mind Flay filler
    if self:IsUsableSpell(S.MindFlay) and manaPercent > 5 then
        if not UnitChannelInfo("player") then
            if not self:CastSpell(S.MindFlay, "target") then return false end
            PriestDebug("Shadow: Mind Flay")
            return true
        end
    end
    
    -- Wand if OOM
    if manaPercent < 5 and self:KnowsSpell(S.Shoot) and self:IsUsableSpell(S.Shoot) and
       not IsAutoRepeatSpell(S.Shoot) then
        if not self:CastSpell(S.Shoot, "target") then return false end
        PriestDebug("Shadow: Wanding")
        return true
    end
    
    return false
end

-- DISCIPLINE ROTATION (absorbs, mitigation, and triage)
function AC:DisciplinePriestRotation()
    local mana = UnitPower("player", 0)
    local maxMana = UnitPowerMax("player", 0)
    local manaPercent = (maxMana > 0) and (mana/maxMana*100) or 100
    local hasTarget = UnitExists("target") and UnitCanAttack("player", "target") and not UnitIsDeadOrGhost("target")
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
    if self:UsePriestManaCooldowns(groupHealth) then return true end

    if manaPercent < 30 and self:UseManaPotion(30) then
        PriestDebug("DISC: Mana potion used")
        return true
    end
    
    -- Mass Dispel remains manual: without encounter-specific coordinates an
    -- automatic ground placement can miss allies or leave a targeting cursor.
    -- PRIORITY 3: INDIVIDUAL DISPELLING
    if self:ActionThrottle("DispelCheck", 0.5) then
        local units = {"player"}
        if IsInGroup() then
            local prefix = GetNumRaidMembers() > 0 and "raid" or "party"
            local max = GetNumRaidMembers() > 0 and GetNumRaidMembers() or GetNumPartyMembers()
            for i = 1, max do
                local unit = prefix .. i
                if not UnitIsUnit(unit, "player") then table.insert(units, unit) end
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
                        if not self:CastSpell(S.DispelMagic, unit) then return false end
                        PriestDebug("DISC: Dispel Magic on " .. UnitName(unit) .. " (" .. topDebuff.name .. ")")
                        return true
                    elseif topDebuff.type == "Disease" then
                        local diseaseSpell = self:IsUsableSpell(S.AbolishDisease) and
                                             S.AbolishDisease or S.CureDisease
                        if self:IsUsableSpell(diseaseSpell) and self:CastSpell(diseaseSpell, unit) then
                            PriestDebug("DISC: " .. diseaseSpell .. " on " .. UnitName(unit) .. " (" .. topDebuff.name .. ")")
                            return true
                        end
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
            if not self:CastSpell(S.PainSuppression, emergencyTarget) then return false end
            PriestDebug("DISC EMERGENCY: Pain Suppression on " .. UnitName(emergencyTarget))
            return true
        end
        
        -- Power Word: Shield (instant protection)
        if not self:HasDebuff(emergencyTarget, S.WeakenedSoulDebuff) and self:IsUsableSpell(S.PowerWordShield) then
            if not self:CastSpell(S.PowerWordShield, emergencyTarget) then return false end
            PriestDebug("DISC EMERGENCY: PW:Shield on " .. UnitName(emergencyTarget))
            return true
        end
        
        -- Penance (fast, powerful heal)
        if self:IsUsableSpell(S.Penance) then
            if not self:CastSpell(S.Penance, emergencyTarget) then return false end
            PriestDebug("DISC EMERGENCY: Penance heal on " .. UnitName(emergencyTarget))
            return true
        end
        
        -- Flash Heal (backup emergency)
        if self:IsUsableSpell(S.FlashHeal) then
            if not self:CastSpell(S.FlashHeal, emergencyTarget) then return false end
            PriestDebug("DISC EMERGENCY: Flash Heal on " .. UnitName(emergencyTarget))
            return true
        end
    end

    -- PRIORITY 6: Keep Prayer of Mending and a shield on the active tank.
    local priorityHealTarget, priorityHealHealth = self:FindPriestHealingTarget("normal")
    local needsDirectHeal = priorityHealTarget and priorityHealHealth < 0.70
    local tankTarget = self:FindPriestTankUnit()
    if not needsDirectHeal and tankTarget and self:IsUsableSpell(S.PrayerOfMending) and
       not self:HasBuff(tankTarget, S.PrayerOfMending) and
       self:CastSpell(S.PrayerOfMending, tankTarget) then
        PriestDebug("DISC PROACTIVE: Prayer of Mending on tank " .. UnitName(tankTarget))
        return true
    end

    if not needsDirectHeal and tankTarget and not self:HasDebuff(tankTarget, S.WeakenedSoulDebuff) and
       self:IsUsableSpell(S.PowerWordShield) and Throttle("ProactiveTankShield", 8) then
        if not self:CastSpell(S.PowerWordShield, tankTarget) then return false end
        PriestDebug("DISC PROACTIVE: PW:Shield on tank " .. UnitName(tankTarget))
        return true
    end

    -- Raid Discipline gameplay is shield-centric. Blanket shields in raids,
    -- while five-player/solo play only shields tanks or actually injured units.
    local needsRawHeal = needsDirectHeal and
                         self:HasDebuff(priorityHealTarget, S.WeakenedSoulDebuff)
    if not needsRawHeal and manaPercent > 50 and self:IsUsableSpell(S.PowerWordShield) and
       self:ActionThrottle("DisciplineShieldScan", 0.2) then
        local shieldTarget = self:FindPriestShieldTarget()
        if shieldTarget and self:CastSpell(S.PowerWordShield, shieldTarget) then
            PriestDebug("DISC: PW:Shield on " .. UnitName(shieldTarget))
            return true
        end
    end
    
    -- PRIORITY 7: GROUP EMERGENCY HEALING
    if groupHealth.needsEmergencyAOE then
        -- Prayer of Healing (group heal)
        if self:IsUsableSpell(S.PrayerOfHealing) and manaPercent > 30 then
            local groupTarget, injured = self:FindPriestGroupHealTarget(0.75)
            if injured >= 2 and self:CastSpell(S.PrayerOfHealing, groupTarget) then
                PriestDebug("DISC EMERGENCY: Prayer of Healing (" .. injured .. " injured)")
                return true
            end
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
            if not self:CastSpell(S.PrayerOfMending, healTarget) then return false end
            PriestDebug("DISC: Prayer of Mending on " .. UnitName(healTarget))
            return true
        end
        
        -- Penance (main healing spell)
        if healTargetHealth < 0.70 and self:IsUsableSpell(S.Penance) then
            if not self:CastSpell(S.Penance, healTarget) then return false end
            PriestDebug("DISC: Penance heal on " .. UnitName(healTarget))
            return true
        end
        
        -- Power Word: Shield for damage prevention
        if healTargetHealth < 0.85 and not self:HasDebuff(healTarget, S.WeakenedSoulDebuff) and 
           self:IsUsableSpell(S.PowerWordShield) then
            if not self:CastSpell(S.PowerWordShield, healTarget) then return false end
            PriestDebug("DISC: PW:Shield on " .. UnitName(healTarget))
            return true
        end
        
        -- Flash Heal for quick healing
        if healTargetHealth < 0.60 and self:IsUsableSpell(S.FlashHeal) then
            if not self:CastSpell(S.FlashHeal, healTarget) then return false end
            PriestDebug("DISC: Flash Heal on " .. UnitName(healTarget))
            return true
        end
        
        -- Greater Heal for efficient big heals
        if healTargetHealth < 0.70 and manaPercent > 40 and self:IsUsableSpell(S.GreaterHeal) then
            if not UnitCastingInfo("player") then
                if not self:CastSpell(S.GreaterHeal, healTarget) then return false end
                PriestDebug("DISC: Greater Heal on " .. UnitName(healTarget))
                return true
            end
        end
    end
    
    -- PRIORITY 9: GROUP HEALING
    if groupHealth.needsAOE and manaPercent > 35 then
        if self:IsUsableSpell(S.PrayerOfHealing) then
            local groupTarget, injured = self:FindPriestGroupHealTarget(0.80)
            if injured >= 3 and self:CastSpell(S.PrayerOfHealing, groupTarget) then
                PriestDebug("DISC: Prayer of Healing (" .. injured .. " injured)")
                return true
            end
        end
    end
    
    -- PRIORITY 10: OFFENSIVE ABILITIES (When healing not needed)
    if hasTarget and (not healTarget or healTargetHealth > 0.90) and groupHealth.avgHealth > 0.85 and manaPercent > 50 then
        
        -- Offensive cooldowns
        if self:UsePriestOffensives("Discipline") then return true end
        
        -- Offensive Penance (excellent damage)
        if self:IsUsableSpell(S.Penance) then
            if not self:CastSpell(S.Penance, "target") then return false end
            PriestDebug("DISC: Offensive Penance")
            return true
        end
        
        -- Holy Fire (DoT + direct damage)
        if not self:HasDebuff("target", S.HolyFire) and self:IsUsableSpell(S.HolyFire) then
            if not self:CastSpell(S.HolyFire, "target") then return false end
            PriestDebug("DISC: Holy Fire")
            return true
        end
        
        -- Shadow Word: Pain (DoT)
        if not self:HasDebuff("target", S.ShadowWordPain) and
           self:IsUsableSpell(S.ShadowWordPain) and not self:IsFastDyingMob("target") then
            if not self:CastSpell(S.ShadowWordPain, "target") then return false end
            PriestDebug("DISC: Shadow Word: Pain")
            return true
        end
        
        -- Smite (main damage filler)
        if self:IsUsableSpell(S.Smite) and not UnitCastingInfo("player") then
            if not self:CastSpell(S.Smite, "target") then return false end
            PriestDebug("DISC: Smite")
            return true
        end
    end
    
    return false
end

-- HOLY ROTATION (group and raid healing)
function AC:HolyPriestRotation()
    local mana = UnitPower("player", 0)
    local maxMana = UnitPowerMax("player", 0)
    local manaPercent = (maxMana > 0) and (mana/maxMana*100) or 100
    local hasTarget = UnitExists("target") and UnitCanAttack("player", "target") and not UnitIsDeadOrGhost("target")
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
    if self:UsePriestManaCooldowns(groupHealth) then return true end

    if manaPercent < 30 and self:UseManaPotion(30) then
        PriestDebug("HOLY: Mana potion used")
        return true
    end
    
    -- PRIORITY 3: DISPELLING
    if self:ActionThrottle("DispelCheckHoly", 0.5) then
        local units = {"player"}
        if IsInGroup() then
            local prefix = GetNumRaidMembers() > 0 and "raid" or "party"
            local max = GetNumRaidMembers() > 0 and GetNumRaidMembers() or GetNumPartyMembers()
            for i = 1, max do
                local unit = prefix .. i
                if not UnitIsUnit(unit, "player") then table.insert(units, unit) end
            end
        end
        
        for _, unit in ipairs(units) do
            if UnitExists(unit) then
                local hasDispellable, topDebuff, urgentDispel, priority = self:AnalyzeDispelNeeds(unit)
                local unitMaxHealth = UnitHealthMax(unit)
                local unitHP = unitMaxHealth > 0 and UnitHealth(unit) / unitMaxHealth or 0
                
                if hasDispellable and (urgentDispel or priority >= 75 or unitHP < 0.70) then
                    if topDebuff.type == "Magic" and self:IsUsableSpell(S.DispelMagic) then
                        if not self:CastSpell(S.DispelMagic, unit) then return false end
                        PriestDebug("HOLY: Dispel Magic on " .. UnitName(unit) .. " (" .. topDebuff.name .. ")")
                        return true
                    elseif topDebuff.type == "Disease" then
                        local diseaseSpell = self:IsUsableSpell(S.AbolishDisease) and
                                             S.AbolishDisease or S.CureDisease
                        if self:IsUsableSpell(diseaseSpell) and self:CastSpell(diseaseSpell, unit) then
                            PriestDebug("HOLY: " .. diseaseSpell .. " on " .. UnitName(unit) .. " (" .. topDebuff.name .. ")")
                            return true
                        end
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
            if not self:CastSpell(S.GuardianSpirit, emergencyTarget) then return false end
            PriestDebug("HOLY ULTIMATE: Guardian Spirit on " .. UnitName(emergencyTarget) .. " (DEATH PREVENTION!)")
            return true
        end
        
        -- Surge of Light proc (instant Flash Heal)
        if self:HasBuff("player", S.SurgeOfLightBuff) and self:IsUsableSpell(S.FlashHeal) then
            if not self:CastSpell(S.FlashHeal, emergencyTarget) then return false end
            PriestDebug("HOLY EMERGENCY: Flash Heal with Surge of Light on " .. UnitName(emergencyTarget))
            return true
        end
        
        -- Flash Heal (fast emergency heal)
        if self:IsUsableSpell(S.FlashHeal) then
            if not self:CastSpell(S.FlashHeal, emergencyTarget) then return false end
            PriestDebug("HOLY EMERGENCY: Flash Heal on " .. UnitName(emergencyTarget))
            return true
        end
    end
    
    -- PRIORITY 5: GROUP EMERGENCY HEALING (Holy specialty)
    if groupHealth.needsEmergencyAOE or groupHealth.emergencyHealth >= 2 then
        if self:IsUsableSpell(S.InnerFocus) and self:CastSpell(S.InnerFocus, "player") then
            PriestDebug("HOLY: Inner Focus for emergency group healing")
            return true
        end

        -- Divine Hymn (ULTIMATE group heal)
        if not self:IsPlayerMoving() and self:IsUsableSpell(S.DivineHymn) and Throttle("DivineHymn", 480) then
            if not UnitChannelInfo("player") then
                if not self:CastSpell(S.DivineHymn) then return false end
                PriestDebug("HOLY ULTIMATE: Divine Hymn (GROUP EMERGENCY!)")
                return true
            end
        end
        
        -- Circle of Healing (instant group heal)
        if self:IsUsableSpell(S.CircleOfHealing) then
            local target, injured = self:FindPriestGroupHealTarget(0.80)
            if injured >= 2 and self:CastSpell(S.CircleOfHealing, target) then
                PriestDebug("HOLY EMERGENCY: Circle of Healing (" .. injured .. " injured)")
                return true
            end
        end
        
        -- Prayer of Healing (group heal)
        if self:IsUsableSpell(S.PrayerOfHealing) and manaPercent > 25 then
            local target, injured = self:FindPriestGroupHealTarget(0.75)
            if injured >= 2 and self:CastSpell(S.PrayerOfHealing, target) then
                PriestDebug("HOLY EMERGENCY: Prayer of Healing (" .. injured .. " injured)")
                return true
            end
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
                local unit = prefix .. i
                if not UnitIsUnit(unit, "player") then table.insert(units, unit) end
            end
        end
        
        for _, unit in ipairs(units) do
            if UnitExists(unit) and not UnitIsDeadOrGhost(unit) then
                local unitMaxHealth = UnitHealthMax(unit)
                local hp = unitMaxHealth > 0 and UnitHealth(unit) / unitMaxHealth or 0
                if hp >= 0.60 and hp < 0.85 and not self:HasBuff(unit, S.Renew) then
                    table.insert(renewTargets, {unit = unit, health = hp})
                end
            end
        end
        
        -- Sort by lowest health first
        table.sort(renewTargets, function(a, b) return a.health < b.health end)
        
        -- Apply Renew to lowest health target without it
        if #renewTargets > 0 and self:IsUsableSpell(S.Renew) then
            local target = renewTargets[1]
            if not self:CastSpell(S.Renew, target.unit) then return false end
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
        
        -- Prayer of Mending (efficient bouncing heal)
        if healTargetHealth < 0.80 and self:IsUsableSpell(S.PrayerOfMending) and 
           Throttle("PrayerOfMendingHoly", 8) then
            if not self:CastSpell(S.PrayerOfMending, healTarget) then return false end
            PriestDebug("HOLY: Prayer of Mending on " .. UnitName(healTarget))
            return true
        end
        
        -- Flash Heal for quick response
        if healTargetHealth < 0.60 and self:IsUsableSpell(S.FlashHeal) then
            if not self:CastSpell(S.FlashHeal, healTarget) then return false end
            PriestDebug("HOLY: Flash Heal on " .. UnitName(healTarget))
            return true
        end
        
        -- Greater Heal with Serendipity optimization
        if healTargetHealth < 0.70 and manaPercent > 30 and self:IsUsableSpell(S.GreaterHeal) then
            local _, serendipityStacks = self:HasBuff("player", S.SerendipityBuff)
            if serendipityStacks and serendipityStacks >= 2 then
                if not UnitCastingInfo("player") then
                    if not self:CastSpell(S.GreaterHeal, healTarget) then return false end
                    PriestDebug("HOLY: Greater Heal with Serendipity (" .. serendipityStacks .. " stacks) on " .. UnitName(healTarget))
                    return true
                end
            elseif healTargetHealth < 0.55 then
                if not UnitCastingInfo("player") then
                    if not self:CastSpell(S.GreaterHeal, healTarget) then return false end
                    PriestDebug("HOLY: Greater Heal on " .. UnitName(healTarget))
                    return true
                end
            end
        end
        
        -- Binding Heal (heal self + target)
        if healTargetHealth < 0.75 and self:GetPlayerHealthPercent() < 80 and 
           self:IsUsableSpell(S.BindingHeal) then
            if not self:CastSpell(S.BindingHeal, healTarget) then return false end
            PriestDebug("HOLY: Binding Heal (self + " .. UnitName(healTarget) .. ")")
            return true
        end
    end
    
    -- PRIORITY 8: GROUP HEALING (Holy excels at this)
    if groupHealth.needsAOE and manaPercent > 30 then
        -- Circle of Healing first (instant)
        if self:IsUsableSpell(S.CircleOfHealing) then
            local target, injured = self:FindPriestGroupHealTarget(0.85)
            if injured >= 3 and self:CastSpell(S.CircleOfHealing, target) then
                PriestDebug("HOLY: Circle of Healing (" .. injured .. " injured)")
                return true
            end
        end
        
        -- Prayer of Healing (powerful group heal)
        if self:IsUsableSpell(S.PrayerOfHealing) and manaPercent > 35 then
            local target, injured = self:FindPriestGroupHealTarget(0.80)
            if injured >= 3 and self:CastSpell(S.PrayerOfHealing, target) then
                PriestDebug("HOLY: Prayer of Healing (" .. injured .. " injured)")
                return true
            end
        end
        
        -- Holy Nova (if enemies nearby)
        if self:GetEnemyCount() > 0 and self:IsUsableSpell(S.HolyNova) then
            if not self:CastSpell(S.HolyNova) then return false end
            PriestDebug("HOLY: Holy Nova (heal + damage)")
            return true
        end
    end
    
    -- Lightwell remains manual. Its value depends on encounter placement and
    -- players clicking it; recasting blindly can waste both mana and a GCD.
    
    -- PRIORITY 10: OFFENSIVE ABILITIES (When healing not needed)
    if hasTarget and groupHealth.avgHealth > 0.90 and manaPercent > 60 then
        
        -- Offensive cooldowns
        if self:UsePriestOffensives("Holy") then return true end
        
        -- Holy Fire (main damage + DoT)
        if not self:HasDebuff("target", S.HolyFire) and self:IsUsableSpell(S.HolyFire) then
            if not self:CastSpell(S.HolyFire, "target") then return false end
            PriestDebug("HOLY: Holy Fire")
            return true
        end
        
        -- Shadow Word: Pain (DoT)
        if not self:HasDebuff("target", S.ShadowWordPain) and
           self:IsUsableSpell(S.ShadowWordPain) and not self:IsFastDyingMob("target") then
            if not self:CastSpell(S.ShadowWordPain, "target") then return false end
            PriestDebug("HOLY: Shadow Word: Pain")
            return true
        end
        
        -- Smite (damage filler)
        if self:IsUsableSpell(S.Smite) and not UnitCastingInfo("player") then
            if not self:CastSpell(S.Smite, "target") then return false end
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
        if not IsMounted() and (not self.IsEatingOrDrinking or not self:IsEatingOrDrinking()) then
            if spec == "Discipline" or spec == "Holy" then
                if self:EmergencyTriage() then return true end
                if self:SmartHeal() then return true end
            elseif self:GetPlayerHealthPercent() < 80 and
                   not self:HasDebuff("player", S.WeakenedSoulDebuff) and
                   self:IsUsableSpell(S.PowerWordShield) and
                   self:CastSpell(S.PowerWordShield, "player") then
                PriestDebug("Leveling: out-of-combat shield")
                return true
            end
        end

        -- Buffs (includes group buffing)
        if self:CheckPriestBuffs() then return true end
        
        -- Combat rebuffing (for group members who lost buffs)
        if IsInGroup() and self:CheckPriestCombatBuffs() then return true end
        
        -- Pull
        if hasTarget and not UnitAffectingCombat("target") then
            -- Shadow opens long-lived targets with VT. SW:P is delayed until
            -- Shadow Weaving is stacked by the in-combat rotation.
            if spec == "Shadow" then
                if not self:HasBuff("player", S.Shadowform) and self:IsUsableSpell(S.Shadowform) then
                    if not self:CastSpell(S.Shadowform) then return false end
                    return true
                end
                if not self:IsFastDyingMob("target") and self:IsUsableSpell(S.VampiricTouch) then
                    if not self:CastSpell(S.VampiricTouch, "target") then return false end
                    return true
                elseif self:IsUsableSpell(S.ShadowWordPain) then
                    if not self:CastSpell(S.ShadowWordPain, "target") then return false end
                    return true
                end
            else
                -- Holy/Disc pull with Holy Fire or Smite
                if self:IsUsableSpell(S.HolyFire) then
                    if not self:CastSpell(S.HolyFire, "target") then return false end
                    return true
                elseif self:IsUsableSpell(S.Smite) then
                    if not self:CastSpell(S.Smite, "target") then return false end
                    return true
                end
            end
        end
        
        return false
    end
    
    -- In combat - check for racials
    if self:UsePriestRacials(true, false) then return true end
    
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
            if not self:CastSpell(S.PowerWordShield, "player") then return false end
            PriestDebug("Leveling: PW:Shield")
            return true
        end
        
        if self:GetPlayerHealthPercent() < 50 and self:IsUsableSpell(S.FlashHeal) then
            if not self:CastSpell(S.FlashHeal, "player") then return false end
            PriestDebug("Leveling: Flash Heal")
            return true
        end
        
        -- Basic DPS
        if hasTarget then
            if not self:HasDebuff("target", S.ShadowWordPain) and
               self:IsUsableSpell(S.ShadowWordPain) and not self:IsFastDyingMob("target") then
                if not self:CastSpell(S.ShadowWordPain, "target") then return false end
                PriestDebug("Leveling: SW:Pain")
                return true
            end
            
            if self:IsUsableSpell(S.MindBlast) and manaPercent > 20 then
                if not self:CastSpell(S.MindBlast, "target") then return false end
                PriestDebug("Leveling: Mind Blast")
                return true
            end
            
            -- Wanding before the mana bar is empty greatly reduces leveling
            -- downtime and cannot hang when no wand/Shoot spell is learned.
            if manaPercent < 25 and self:KnowsSpell(S.Shoot) and self:IsUsableSpell(S.Shoot) and
               not IsAutoRepeatSpell(S.Shoot) then
                if not self:CastSpell(S.Shoot, "target") then return false end
                PriestDebug("Leveling: Wand")
                return true
            end

            if level >= 20 and self:IsUsableSpell(S.MindFlay) and manaPercent > 15 then
                if not UnitChannelInfo("player") then
                    if not self:CastSpell(S.MindFlay, "target") then return false end
                    PriestDebug("Leveling: Mind Flay")
                    return true
                end
            end
            
            if self:IsUsableSpell(S.Smite) and manaPercent > 10 then
                if not UnitCastingInfo("player") then
                    if not self:CastSpell(S.Smite, "target") then return false end
                    PriestDebug("Leveling: Smite")
                    return true
                end
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
    
    self:Print("Priest rotations (WotLK 3.3.5a) initialized")
    PriestDebug("+ Discipline: raid shielding, Penance triage, mitigation cooldowns")
    PriestDebug("+ Holy: subgroup-aware Circle/Prayer healing, Renew, Serendipity")
    PriestDebug("+ Shadow: five-stack SW:P opener, DoT expiry timing, Mind Flay filler")
    PriestDebug("+ Utility: priority dispels, mana cooldowns, buffs, and safe leveling fallbacks")
end

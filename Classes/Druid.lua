-- AzeroCombat: Druid Rotations (IMPROVED - Research-Based WotLK 3.3.5a)
-- Optimized based on actual WotLK 3.3.5a guide research for AzerothCore
local AddonName, AC = ...

local S = { -- Spells
    -- Balance (Research-Based Priorities)
    Moonfire = "Moonfire", 
    Starfire = "Starfire", 
    Wrath = "Wrath", 
    InsectSwarm = "Insect Swarm",
    Starfall = "Starfall", 
    ForceOfNature = "Force of Nature", 
    Typhoon = "Typhoon",
    MoonkinForm = "Moonkin Form", 
    Hurricane = "Hurricane", 
    FaerieFireBalance = "Faerie Fire",

    -- Feral DPS (Cat) - Research Priority Order
    CatForm = "Cat Form", 
    FerociousBite = "Ferocious Bite", 
    Shred = "Shred", 
    Rake = "Rake", 
    Rip = "Rip",
    MangleCat = "Mangle (Cat)", 
    Cower = "Cower", 
    TigersFury = "Tiger's Fury", 
    Prowl = "Prowl",
    SavageRoar = "Savage Roar", 
    Berserk = "Berserk", 
    Claw = "Claw", 
    Pounce = "Pounce", 
    Ravage = "Ravage",
    SwipeCat = "Swipe (Cat)",
    FeralChargeCat = "Feral Charge - Cat",

    -- Feral Tank (Bear)
    BearForm = "Bear Form", 
    DireBearForm = "Dire Bear Form", 
    Maul = "Maul", 
    SwipeBear = "Swipe (Bear)",
    FaerieFireFeral = "Faerie Fire (Feral)", 
    Growl = "Growl", 
    DemoralizingRoar = "Demoralizing Roar",
    ChallengingRoar = "Challenging Roar", 
    Enrage = "Enrage", 
    Bash = "Bash",
    FrenziedRegeneration = "Frenzied Regeneration", 
    SurvivalInstincts = "Survival Instincts",
    Lacerate = "Lacerate", 
    MangleBear = "Mangle (Bear)", 
    Pulverize = "Pulverize",

    -- Restoration
    TreeOfLife = "Tree of Life", 
    Rejuvenation = "Rejuvenation", 
    Regrowth = "Regrowth",
    Lifebloom = "Lifebloom", 
    HealingTouch = "Healing Touch", 
    Nourish = "Nourish",
    Tranquility = "Tranquility", 
    Swiftmend = "Swiftmend", 
    WildGrowth = "Wild Growth",
    NaturesSwiftness = "Nature's Swiftness",

    -- Utility & Misc
    RemoveCurse = "Remove Curse", 
    AbolishPoison = "Abolish Poison", 
    Innervate = "Innervate",
    Barkskin = "Barkskin", 
    Hibernate = "Hibernate", 
    Rebirth = "Rebirth", 
    Cyclone = "Cyclone",
    EntanglingRoots = "Entangling Roots", 
    Dash = "Dash",
    NaturesGrasp = "Nature's Grasp",

    -- Buffs
    MarkOfTheWild = "Mark of the Wild", 
    Thorns = "Thorns", 
    GiftOfTheWild = "Gift of the Wild",

    -- Travel Forms
    TravelForm = "Travel Form", 
    AquaticForm = "Aquatic Form", 
    FlightForm = "Flight Form", 
    SwiftFlightForm = "Swift Flight Form",

    -- Procs / Special States (Research-Based)
    OmenOfClarityBuff = "Clearcasting",
    EclipseLunarBuff = "Eclipse (Lunar)",
    EclipseSolarBuff = "Eclipse (Solar)",
    PredatorsSwiftnessBuff = "Predator's Swiftness",
    
    -- Racial Abilities
    WarStomp = "War Stomp",
    Shadowmeld = "Shadowmeld",
    Berserking = "Berserking",
    WillOfTheForsaken = "Will of the Forsaken",
    BloodFury = "Blood Fury",
    Stoneform = "Stoneform",
    EscapeArtist = "Escape Artist",
    GiftOfTheNaaru = "Gift of the Naaru",
    ArcaneTorrent = "Arcane Torrent",
    EveryManForHimself = "Every Man for Himself",
    
    -- Additional important procs
    NaturesGrace = "Nature's Grace",
    PredatorsSwiftness = "Predator's Swiftness",
    
    -- Group buffs
    PowerWordFortitude = "Power Word: Fortitude",
    ArcaneIntellect = "Arcane Intellect",
    BlessingOfKings = "Blessing of Kings",
    BlessingOfMight = "Blessing of Might",
}

-- Debug function
local function DruidDebug(msg)
    if AC.debugMode then
        AC:Debug("|cFFFF7D0ADruid:|r " .. tostring(msg))
    end
end

local function NormalizeFeralRole(role)
    if not role then return "auto" end
    role = string.lower(tostring(role))
    if role == "bear" or role == "cat" or role == "auto" then
        return role
    end
    return "auto"
end

function AC:HasTalentByName(talentName, cacheKey)
    if not talentName then return false end

    self.druidTalentCache = self.druidTalentCache or {}
    local key = cacheKey or talentName
    local now = GetTime()
    local cached = self.druidTalentCache[key]
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
                    if talentSuccess and name and name:find(talentName, 1, true) and currRank > 0 then
                        found = true
                        break
                    end
                end
                if found then break end
            end
        end
    end

    self.druidTalentCache[key] = {
        time = now,
        value = found
    }
    return found
end

function AC:GetFeralTalentPoints()
    local success, numTabs = pcall(GetNumTalentTabs)
    if not success then return 0 end

    for tab = 1, numTabs do
        local tabSuccess, tabName, _, points = pcall(GetTalentTabInfo, tab)
        if tabSuccess and tabName and tabName:find("Feral", 1, true) then
            return points or 0
        end
    end

    return 0
end

function AC:IsFeralBuild()
    local spec = self:GetPlayerSpec()
    return spec == "Feral" or self:GetFeralTalentPoints() > 0
end

function AC:GetFeralRolePreference()
    if not self.db or not self.db.profile then
        return "auto"
    end
    return NormalizeFeralRole(self.db.profile.feralRoleMode)
end

function AC:SetFeralRolePreference(role)
    role = NormalizeFeralRole(role)
    if self.db and self.db.profile then
        self.db.profile.feralRoleMode = role
    end
    if self.druidFeralCombatRole then
        self.druidFeralCombatRole = nil
    end
    return role
end

function AC:DetermineFeralRole()
    local preferred = self:GetFeralRolePreference()
    if preferred ~= "auto" then
        if preferred == "cat" and not self:KnowsSpell(S.CatForm) then
            return "bear"
        end
        return preferred
    end

    -- Leveling safety: if Cat Form is not learned yet, the feral build must play as bear.
    if not self:KnowsSpell(S.CatForm) then
        return "bear"
    end

    if UnitAffectingCombat("player") and self.druidFeralCombatRole then
        return self.druidFeralCombatRole
    end

    local bearScore = 0
    local catScore = 0

    -- Bear-leaning talents
    if self:HasTalentByName("Feral Instinct", "Druid_FeralInstinct") then bearScore = bearScore + 4 end
    if self:HasTalentByName("Thick Hide", "Druid_ThickHide") then bearScore = bearScore + 4 end
    if self:HasTalentByName("Survival of the Fittest", "Druid_SOTF") then bearScore = bearScore + 5 end
    if self:HasTalentByName("Protector of the Pack", "Druid_POTP") then bearScore = bearScore + 5 end
    if self:HasTalentByName("Natural Reaction", "Druid_NaturalReaction") then bearScore = bearScore + 3 end
    if self:HasTalentByName("Infected Wounds", "Druid_InfectedWounds") then bearScore = bearScore + 2 end
    if self:HasTalentByName("Survival Instincts", "Druid_SurvivalInstincts") then bearScore = bearScore + 2 end

    -- Cat-leaning talents
    if self:HasTalentByName("Ferocity", "Druid_Ferocity") then catScore = catScore + 4 end
    if self:HasTalentByName("Feral Aggression", "Druid_FeralAggression") then catScore = catScore + 3 end
    if self:HasTalentByName("Predatory Strikes", "Druid_PredatoryStrikes") then catScore = catScore + 4 end
    if self:HasTalentByName("King of the Jungle", "Druid_KingOfTheJungle") then catScore = catScore + 5 end
    if self:HasTalentByName("Improved Mangle", "Druid_ImprovedMangle") then catScore = catScore + 3 end
    if self:HasTalentByName("Primal Precision", "Druid_PrimalPrecision") then catScore = catScore + 3 end
    if self:HasTalentByName("Master Shapeshifter", "Druid_MasterShapeshifter") then catScore = catScore + 2 end
    if self:HasTalentByName("Predatory Instincts", "Druid_PredatoryInstincts") then catScore = catScore + 2 end
    if self:HasTalentByName("Shredding Attacks", "Druid_ShreddingAttacks") then catScore = catScore + 1 end

    local currentForm = self:GetCurrentDruidForm()
    if currentForm == AC.DruidForms.BEAR then
        bearScore = bearScore + 1
    elseif currentForm == AC.DruidForms.CAT then
        catScore = catScore + 1
    end

    if bearScore > catScore then
        return "bear"
    elseif catScore > bearScore then
        return "cat"
    end

    if self:IsTank("player") then
        return "bear"
    end

    return currentForm == AC.DruidForms.BEAR and "bear" or "cat"
end

local function IsHealingSpellInRange(unit)
    if not unit or not UnitExists(unit) then return false end
    if UnitIsUnit(unit, "player") then return true end

    local rangeSpells = {
        S.Nourish,
        S.Rejuvenation,
        S.Regrowth,
        S.HealingTouch,
        S.Lifebloom,
    }

    for _, spellName in ipairs(rangeSpells) do
        if AC:KnowsSpell(spellName) then
            local inRange = IsSpellInRange(spellName, unit)
            if inRange == 1 then
                return true
            elseif inRange == 0 then
                return false
            end
        end
    end

    -- Fall back to interaction distance if spell range cannot be queried.
    return CheckInteractDistance(unit, 4)
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

-- WotLK 3.3.5a-compatible group check (IsInParty is not available in WotLK)
local function IsDruidInGroup()
    return (GetNumRaidMembers and GetNumRaidMembers() > 0) or
           (GetNumPartyMembers and GetNumPartyMembers() > 0)
end

-- =============================================
-- RESEARCH-BASED FORM MANAGEMENT
-- =============================================

AC.DruidForms = {
    CASTER = 0, BEAR = 1, AQUATIC = 2, CAT = 3, TRAVEL = 4, 
    MOONKIN = 5, FLIGHT = 6, TREE = 7, SWIFT_FLIGHT = 8
}

function AC:GetCurrentDruidForm()
    if self:HasBuff("player", S.MoonkinForm) then return AC.DruidForms.MOONKIN end
    if self:HasBuff("player", S.TreeOfLife) then return AC.DruidForms.TREE end
    if self:HasBuff("player", S.CatForm) then return AC.DruidForms.CAT end
    if self:HasBuff("player", S.BearForm) or self:HasBuff("player", S.DireBearForm) then return AC.DruidForms.BEAR end
    if self:HasBuff("player", S.TravelForm) then return AC.DruidForms.TRAVEL end
    if self:HasBuff("player", S.AquaticForm) then return AC.DruidForms.AQUATIC end
    if self:HasBuff("player", S.FlightForm) then return AC.DruidForms.FLIGHT end
    if self:HasBuff("player", S.SwiftFlightForm) then return AC.DruidForms.SWIFT_FLIGHT end
    return AC.DruidForms.CASTER
end

function AC:ShiftToForm(targetFormSpell)
    if not targetFormSpell or not self:KnowsSpell(targetFormSpell) then return false end
    
    -- Special handling for shifting to caster form
    if targetFormSpell == "Caster" then
        local currentForm = GetShapeshiftForm()
        if currentForm ~= 0 then
            CancelShapeshiftForm()
            DruidDebug("Shifting to Caster form")
            return true
        end
        return false
    end
    
    -- Check if already in the target form
    if self:HasBuff("player", targetFormSpell) then return false end
    
    -- Use the spell if it's usable
    if self:IsUsableSpell(targetFormSpell) then
        CastSpellByName(targetFormSpell)
        DruidDebug("Shifting to " .. targetFormSpell)
        return true
    end
    -- Final Balance filler fallback (only after all higher-priority logic fails)
    if hasSolarEclipse and self:IsUsableSpell(S.Wrath) and self:GetSpellCooldown(S.Wrath) == 0 then
        CastSpellByName(S.Wrath, "target")
        DruidDebug("Balance: Filler Wrath")
        return true
    end

    if hasLunarEclipse and self:IsUsableSpell(S.Starfire) and self:GetSpellCooldown(S.Starfire) == 0 then
        CastSpellByName(S.Starfire, "target")
        DruidDebug("Balance: Filler Starfire")
        return true
    end

    if self:IsUsableSpell(S.Wrath) and self:GetSpellCooldown(S.Wrath) == 0 then
        CastSpellByName(S.Wrath, "target")
        DruidDebug("Balance: Filler Wrath")
        return true
    end

    if self:IsUsableSpell(S.Starfire) and self:GetSpellCooldown(S.Starfire) == 0 then
        CastSpellByName(S.Starfire, "target")
        DruidDebug("Balance: Filler Starfire")
        return true
    end

    return false
end

-- =============================================
-- RESEARCH-BASED RESOURCE HELPERS
-- =============================================

function AC:HasOmenOfClarity() 
    return self:HasBuff("player", S.OmenOfClarityBuff) 
end

function AC:GetComboPoints() 
    return GetComboPoints("player", "target") 
end

-- RESEARCH-BASED: Check if we're behind target (for Shred priority)
function AC:IsBehindTarget()
    if not UnitExists("target") then return false end
    -- There is no reliable stock 3.3.5 API for behind checks.
    -- Use Shred usability as a practical WotLK-safe proxy for "behind enough".
    if not self:IsInMeleeRange("target") then return false end
    return self:IsUsableSpell(S.Shred)
end

-- RESEARCH-BASED: Fast dying mob check (affects DoT application)
function AC:IsFastDyingMob(unit)
    if not unit or not UnitExists(unit) then return false end
    local hp = UnitHealth(unit)
    local maxHp = UnitHealthMax(unit)
    local hpPercent = (hp / maxHp) * 100
    
    -- Research shows: Don't apply DoTs to targets below 25% or very low HP
    return hpPercent < 25 or hp < 10000
end

-- RESEARCH-BASED: In melee range check
function AC:IsInMeleeRange(unit)
    if not unit or not UnitExists(unit) then return false end
    return CheckInteractDistance(unit, 3)
end

-- =============================================
-- RESEARCH-BASED DEFENSIVE COOLDOWNS
-- =============================================

function AC:UseDruidDefensives(form)
    local health = self:GetPlayerHealthPercent()
    local inCombat = UnitAffectingCombat("player")
    local enemies = self:GetEnemyCount()
    
    if not inCombat then return false end
    
    -- Emergency health potion first
    if health < 35 and self.UseHealthPotion and self:UseHealthPotion(35) then
        DruidDebug("Used health potion at " .. string.format("%.0f", health) .. "% health")
        return true
    end
    
    -- Barkskin (usable in all forms)
    if health < 50 and self:IsUsableSpell(S.Barkskin) then
        CastSpellByName(S.Barkskin)
        DruidDebug("Barkskin at low health")
        return true
    end
    
    -- Bear Form specific
    if form == AC.DruidForms.BEAR then
        -- Survival Instincts
        if health < 30 and self:IsUsableSpell(S.SurvivalInstincts) then
            CastSpellByName(S.SurvivalInstincts)
            DruidDebug("Survival Instincts")
            return true
        end
        
        -- Frenzied Regeneration
        if health < 40 and UnitPower("player", 1) > 10 and self:IsUsableSpell(S.FrenziedRegeneration) then
            CastSpellByName(S.FrenziedRegeneration)
            DruidDebug("Frenzied Regeneration")
            return true
        end
    end
    
    -- Nature's Grasp if being attacked in caster
    if form == AC.DruidForms.CASTER and enemies > 0 and self:IsUsableSpell(S.NaturesGrasp) then
        CastSpellByName(S.NaturesGrasp)
        DruidDebug("Nature's Grasp")
        return true
    end
    
    return false
end

-- =============================================
-- RESEARCH-BASED OFFENSIVE COOLDOWNS
-- =============================================

function AC:UseDruidOffensives(spec, form)
    local targetHP = self:GetTargetHealthPercent("target")
    local targetClass = UnitClassification("target")
    
    -- Don't blow CDs on trivial mobs
    if targetClass == "trivial" or targetHP < 30 then
        return false
    end
    
    -- Check if it's worth using offensive CDs
    local worthIt = targetClass == "elite" or targetClass == "rareelite" or 
                   targetClass == "worldboss" or targetHP > 70 or
                   (IsInGroup() and targetHP > 50)
    
    if not worthIt then return false end
    
    -- Balance
    if spec == "Balance" and form == AC.DruidForms.MOONKIN then
        -- RESEARCH: Force of Nature is major DPS cooldown
        if not self:IsChanneling() and self:IsUsableSpell(S.ForceOfNature) and self:GetSpellCooldown(S.ForceOfNature) == 0 and Throttle("ForceOfNature", 180) then
            CastSpellByName(S.ForceOfNature)
            DruidDebug("Force of Nature - burst")
            if self.UseTrinkets then self:UseTrinkets() end
            return true
        end
        
        -- RESEARCH: Starfall on cooldown outside of eclipse
        if self:IsUsableSpell(S.Starfall) and self:GetSpellCooldown(S.Starfall) == 0 and Throttle("Starfall", 90) then
            CastSpellByName(S.Starfall)
            DruidDebug("Starfall - burst")
            return true
        end
    end
    
    -- Feral Cat
    if form == AC.DruidForms.CAT then
        -- RESEARCH: Berserk is the most powerful cooldown (15 seconds, 50% energy cost reduction)
        if self:IsUsableSpell(S.Berserk) and Throttle("Berserk", 180) then
            -- Use when Tiger's Fury has >15s cooldown remaining
            local tigersFuryCD = self:GetSpellCooldown(S.TigersFury)
            if tigersFuryCD > 15 then
                CastSpellByName(S.Berserk)
                DruidDebug("Berserk - burst")
                if self.UseTrinkets then self:UseTrinkets() end
                return true
            end
        end
        
        -- RESEARCH: Tiger's Fury as controlled energy injection (avoid low-value spam attempts).
        local catEnergy = UnitPower("player", 3)
        local catCP = self:GetComboPoints()
        if catEnergy <= 30 and catCP < 5 and self:IsUsableSpell(S.TigersFury)
           and self:GetSpellCooldown(S.TigersFury) == 0 and Throttle("TigersFury", 8.0) then
            CastSpellByName(S.TigersFury)
            DruidDebug("Tiger's Fury (energy regen)")
            return true
        end
    end
    
    return false
end

-- Dedicated low-level druid handling for characters with no talent points yet.
function AC:LevelingDruidRotation()
    local level = UnitLevel("player")
    local mana = UnitPower("player", 0)
    local maxMana = UnitPowerMax("player", 0)
    local manaPercent = (maxMana > 0) and (mana / maxMana * 100) or 100
    local health = self:GetPlayerHealthPercent()
    local inCombat = UnitAffectingCombat("player")
    local hasTarget = UnitExists("target") and UnitCanAttack("player", "target") and not UnitIsDeadOrGhost("target")

    if Throttle("LevelingDebug", 2.5) then
        DruidDebug(string.format(
            "Leveling mode: L:%d Mana:%.0f%% HP:%.0f Combat:%s Target:%s",
            level,
            manaPercent,
            health,
            inCombat and "Y" or "N",
            hasTarget and "Y" or "N"
        ))
    end

    -- Emergency self-healing always takes priority.
    if not UnitCastingInfo("player") then
        if health < 35 and self:IsUsableSpell(S.HealingTouch) then
            CastSpellByName(S.HealingTouch, "player")
            DruidDebug("Leveling: Healing Touch (emergency self-heal)")
            return true
        end

        if health < 70 and self:IsUsableSpell(S.Rejuvenation) and not self:HasBuff("player", S.Rejuvenation) then
            CastSpellByName(S.Rejuvenation, "player")
            DruidDebug("Leveling: Rejuvenation (self sustain)")
            return true
        end
    end

    if not inCombat then
        if self:CheckDruidBuffs() then return true end

        if hasTarget then
            if self:KnowsSpell(S.Moonfire) and self:IsUsableSpell(S.Moonfire) and
               self:DebuffTimeRemaining("target", S.Moonfire) < 1 and not UnitCastingInfo("player") then
                CastSpellByName(S.Moonfire, "target")
                DruidDebug("Leveling: Moonfire (pre-pull)")
                return true
            end

            if self:IsUsableSpell(S.Wrath) and not UnitCastingInfo("player") then
                CastSpellByName(S.Wrath, "target")
                DruidDebug("Leveling: Wrath (pre-pull)")
                return true
            end
        end

        if Throttle("LevelingIdle", 3.0) then
            DruidDebug("Leveling: out of combat, waiting for target or mana")
        end
        return false
    end

    if not hasTarget then
        if Throttle("LevelingNoTarget", 3.0) then
            DruidDebug("Leveling: no hostile target available")
        end
        return false
    end

    if self:KnowsSpell(S.Moonfire) and self:IsUsableSpell(S.Moonfire) and
       self:DebuffTimeRemaining("target", S.Moonfire) < 1 and not UnitCastingInfo("player") then
        CastSpellByName(S.Moonfire, "target")
        DruidDebug("Leveling: Moonfire")
        return true
    end

    if self:IsUsableSpell(S.Wrath) and not UnitCastingInfo("player") then
        CastSpellByName(S.Wrath, "target")
        DruidDebug("Leveling: Wrath")
        return true
    end

    if self:KnowsSpell(S.EntanglingRoots) and self:IsUsableSpell(S.EntanglingRoots) and
       self:GetSpellCooldown(S.EntanglingRoots) == 0 and health < 60 then
        CastSpellByName(S.EntanglingRoots, "target")
        DruidDebug("Leveling: Entangling Roots (peel)")
        return true
    end

    if Throttle("LevelingNoAction", 2.5) then
        DruidDebug("Leveling: no usable action this tick")
    end

    return false
end

-- =============================================
-- RESEARCH-BASED BUFF MANAGEMENT
-- =============================================

function AC:CheckDruidBuffs()
    if not Throttle("DruidBuffsOOC", 10) then return false end
    local inCombat = UnitAffectingCombat("player")
    if inCombat then return false end
    
    -- Group buffing first (out of combat)
    if self:CheckDruidGroupBuffs() then return true end
    
    -- Mark of the Wild (self)
    local motwSpell = self:KnowsSpell(S.GiftOfTheWild) and S.GiftOfTheWild or S.MarkOfTheWild
    if self:IsUsableSpell(motwSpell) then
        if not self:HasBuff("player", S.MarkOfTheWild) and not self:HasBuff("player", S.GiftOfTheWild) then
            CastSpellByName(motwSpell, "player")
            DruidDebug("Buffing: " .. motwSpell)
            return true
        end
    end
    
    -- EPIC THORNS PRIORITY: Check for tanks first, then self
    if self:IsUsableSpell(S.Thorns) then
        -- In group: prioritize tanks for thorns
            if IsDruidInGroup() then
                local groupUnits = {}
                if GetNumRaidMembers() > 0 then
                    for i = 1, GetNumRaidMembers() do
                        table.insert(groupUnits, "raid" .. i)
                    end
                elseif GetNumPartyMembers() > 0 then
                    for i = 1, GetNumPartyMembers() do
                        table.insert(groupUnits, "party" .. i)
                    end
                end
            
            -- Find tanks without thorns
            for _, unit in ipairs(groupUnits) do
                if UnitExists(unit) and not UnitIsDeadOrGhost(unit) and UnitIsConnected(unit) and
                   CheckInteractDistance(unit, 4) and not self:HasBuff(unit, S.Thorns) and self:IsTank(unit) then
                    CastSpellByName(S.Thorns, unit)
                    DruidDebug("EPIC THORNS: " .. (UnitName(unit) or unit) .. " (TANK PRIORITY)")
                    return true
                end
            end
        end
        
        -- No tanks need thorns, buff self
        if not self:HasBuff("player", S.Thorns) then
            CastSpellByName(S.Thorns, "player")
            DruidDebug("Buffing: Thorns (self)")
            return true
        end
    end
    
    return false
end

-- =============================================
-- RESEARCH-BASED BALANCE ROTATION
-- =============================================

function AC:BalanceDruidRotation()
    local currentForm = self:GetCurrentDruidForm()
    local mana = UnitPower("player", 0)
    local maxMana = UnitPowerMax("player", 0)
    local manaPercent = (maxMana > 0) and (mana/maxMana*100) or 100
    local health = self:GetPlayerHealthPercent()
    local enemies = self:GetEnemyCount()
    local hasTarget = UnitExists("target") and UnitCanAttack("player", "target") and not UnitIsDeadOrGhost("target")
    
    -- RESEARCH: Moonkin form required for Balance
    if self:KnowsSpell(S.MoonkinForm) and currentForm ~= AC.DruidForms.MOONKIN then
        if self:ShiftToForm(S.MoonkinForm) then
            return true
        end
    end
    
    -- 2x Wrath opener (immediately after Moonkin Form, before ALL other logic)
    self.druidRotationState = self.druidRotationState or {}
    
    -- Track combat state transitions for new combat detection
    local wasInCombat = self.druidRotationState.wasInCombat or false
    local isInCombat = UnitAffectingCombat("player")
    
    -- Reset opener when entering combat (transition from not-in-combat to in-combat)
    if not wasInCombat and isInCombat then
        DruidDebug("Balance: New combat detected, resetting Wrath opener")
        self.druidRotationState.wrathOpenerCount = 0
        self.druidRotationState.openerComplete = false
    end
    
    -- Reset opener when leaving combat (player no longer in combat)
    if wasInCombat and not isInCombat then
        DruidDebug("Balance: Left combat, resetting Wrath opener")
        self.druidRotationState.wrathOpenerCount = 0
        self.druidRotationState.openerComplete = false
    end
    
    self.druidRotationState.wasInCombat = isInCombat
    
    -- Reset opener when target changes
    local targetGUID = hasTarget and UnitGUID("target") or nil
    if self.druidRotationState.lastTargetGUID and targetGUID and self.druidRotationState.lastTargetGUID ~= targetGUID then
        DruidDebug("Balance: Target changed, resetting Wrath opener")
        self.druidRotationState.wrathOpenerCount = 0
        self.druidRotationState.openerComplete = false
    end
    self.druidRotationState.lastTargetGUID = targetGUID
    
    -- Cast Wrath opener (before Force of Nature, Starfall, Faerie Fire, DoTs, etc.)
    -- Best-effort only: never block normal rotation if opener cannot fire.
    if not self.druidRotationState.openerComplete and hasTarget and self:IsUsableSpell(S.Wrath) and self:GetSpellCooldown(S.Wrath) == 0 and manaPercent > 10 and not UnitCastingInfo("player") then
        CastSpellByName(S.Wrath, "target")
        DruidDebug("Balance: Wrath opener (" .. tostring(self.druidRotationState.wrathOpenerCount or 0) .. "/2)")
        self.druidRotationState.wrathOpenerCount = (self.druidRotationState.wrathOpenerCount or 0) + 1
        if (self.druidRotationState.wrathOpenerCount or 0) >= 2 then
            self.druidRotationState.openerComplete = true
        end
        return true
    end
    
    if not hasTarget then
        return false
    end
    
    -- Defensive cooldowns
    if self:UseDruidDefensives(currentForm) then
        return true
    end
    
    -- Mana management
    if manaPercent < 30 and self.UseManaPotion and self:UseManaPotion(30) then
        DruidDebug("Used mana potion")
        return true
    end
    
    local targetHP = self:GetTargetHealthPercent("target")
    local isFastDying = self:IsFastDyingMob("target")
    
    -- Offensive cooldowns
    if self:UseDruidOffensives("Balance", currentForm) then
        return true
    end
    
    -- RESEARCH PRIORITY 1: Faerie Fire (Improved Faerie Fire debuff)
    if not self:HasDebuff("target", S.FaerieFireFeral) and not self:HasDebuff("target", "Sunder Armor") then
        if self:DebuffTimeRemaining("target", S.FaerieFireBalance) < 3 and self:IsUsableSpell(S.FaerieFireBalance) and self:GetSpellCooldown(S.FaerieFireBalance) == 0 then
            CastSpellByName(S.FaerieFireBalance, "target")
            DruidDebug("Balance: Faerie Fire (armor reduction)")
            return true
        end
    end
    
        -- AoE rotation (3+ enemies)
    if enemies >= 3 then
        -- RESEARCH: Starfall on cooldown for AoE
        if self:IsUsableSpell(S.Starfall) and self:GetSpellCooldown(S.Starfall) == 0 and Throttle("StarfallAoe", 3) then
            CastSpellByName(S.Starfall)
            DruidDebug("Balance: Starfall (AoE)")
            return true
        end
        
        -- Hurricane channeling
        if self:IsUsableSpell(S.Hurricane) and manaPercent > 30 and not self:IsChanneling() and not self:IsPlayerMoving() then
            DruidDebug("Balance: Hurricane (channel)")
            CastSpellByName(S.Hurricane)
            CameraOrSelectOrMoveStart()
            CameraOrSelectOrMoveStop()
            return true
        end
        
        -- Typhoon for knockback/damage
        if self:IsUsableSpell(S.Typhoon) and self:IsInMeleeRange("target") then
            CastSpellByName(S.Typhoon)
            DruidDebug("Balance: Typhoon")
            return true
        end
    end
    
    -- ENHANCED DOT MANAGEMENT WITH PANDEMIC TIMING
    local complexity = self:GetRotationComplexity()
    
    local function shouldRefreshBalanceDot(debuffName, baseDuration)
        if not self:HasDebuff("target", debuffName) then
            return true -- Missing DoT
        end
        
        -- Pandemic timing for advanced rotations (30% rule)
        if complexity == "ADVANCED" or complexity == "MODERATE" then
            local timeRemaining = self:DebuffTimeRemaining("target", debuffName)
            local pandemicThreshold = baseDuration * 0.3
            return timeRemaining <= pandemicThreshold
        end
        
        -- Simple refresh for basic rotations
        return self:DebuffTimeRemaining("target", debuffName) < 3
    end
    
    -- Refresh DoTs on targets <=25% only if NOT fast-dying (execute phase DoT refresh)
    if not isFastDying then
        -- Maintain Moonfire as part of the normal single-target DoT package.
        if shouldRefreshBalanceDot(S.Moonfire, 12) and self:IsUsableSpell(S.Moonfire) and self:GetSpellCooldown(S.Moonfire) == 0 then
            CastSpellByName(S.Moonfire, "target")
            DruidDebug("Balance: Moonfire (pandemic-aware)")
            return true
        end
        
        -- RESEARCH: Insect Swarm (12s base) - important DPS DoT
        if shouldRefreshBalanceDot(S.InsectSwarm, 12) and self:IsUsableSpell(S.InsectSwarm) and self:GetSpellCooldown(S.InsectSwarm) == 0 then
            CastSpellByName(S.InsectSwarm, "target")
            DruidDebug("Balance: Insect Swarm (pandemic-aware)")
            return true
        end
    end
    
    -- ENHANCED ECLIPSE MANAGEMENT WITH COMPLEXITY AWARENESS
    local hasLunarEclipse = self:HasBuff("player", S.EclipseLunarBuff)
    local hasSolarEclipse = self:HasBuff("player", S.EclipseSolarBuff)
    self.druidRotationState = self.druidRotationState or {}

    if hasLunarEclipse then
        self.druidRotationState.lastBalanceEclipse = "lunar"
    elseif hasSolarEclipse then
        self.druidRotationState.lastBalanceEclipse = "solar"
    end
    
    -- Don't cast if already casting
    if UnitCastingInfo("player") then
        return false
    end
    
    -- Advanced Eclipse tracking with duration awareness
    if complexity == "ADVANCED" or complexity == "MODERATE" then
        local lunarTime = hasLunarEclipse and self:BuffTimeRemaining("player", S.EclipseLunarBuff) or 0
        local solarTime = hasSolarEclipse and self:BuffTimeRemaining("player", S.EclipseSolarBuff) or 0
        
        -- RESEARCH: During Lunar Eclipse - spam Starfire (prioritize when >3s left)
        if hasLunarEclipse and lunarTime > 1.5 and self:IsUsableSpell(S.Starfire) and self:GetSpellCooldown(S.Starfire) == 0 and manaPercent > 15 then
            CastSpellByName(S.Starfire, "target")
            DruidDebug("Balance: Starfire (Lunar Eclipse - " .. string.format("%.1f", lunarTime) .. "s left)")
            return true
        end
        
        -- RESEARCH: During Solar Eclipse - spam Wrath (prioritize when >3s left)
        if hasSolarEclipse and solarTime > 1.5 and self:IsUsableSpell(S.Wrath) and self:GetSpellCooldown(S.Wrath) == 0 and manaPercent > 10 then
            CastSpellByName(S.Wrath, "target")
            DruidDebug("Balance: Wrath (Solar Eclipse - " .. string.format("%.1f", solarTime) .. "s left)")
            return true
        end
        
        -- Alternate builders based on the last Eclipse we consumed.
        local preferWrath = self.druidRotationState.lastBalanceEclipse ~= "lunar"

        if preferWrath and self:IsUsableSpell(S.Wrath) and self:GetSpellCooldown(S.Wrath) == 0 and manaPercent > 10 then
            CastSpellByName(S.Wrath, "target")
            DruidDebug("Balance: Wrath (building to Lunar Eclipse)")
            return true
        elseif self:IsUsableSpell(S.Starfire) and self:GetSpellCooldown(S.Starfire) == 0 and manaPercent > 20 then
            CastSpellByName(S.Starfire, "target")
            DruidDebug("Balance: Starfire (building to Solar Eclipse)")
            return true
        end
    else
        -- Simple Eclipse handling for basic rotations
        if hasLunarEclipse and self:IsUsableSpell(S.Starfire) and self:GetSpellCooldown(S.Starfire) == 0 and manaPercent > 15 then
            CastSpellByName(S.Starfire, "target")
            DruidDebug("Balance: Starfire (Lunar Eclipse)")
            return true
        end
        
        if hasSolarEclipse and self:IsUsableSpell(S.Wrath) and self:GetSpellCooldown(S.Wrath) == 0 and manaPercent > 10 then
            CastSpellByName(S.Wrath, "target")
            DruidDebug("Balance: Wrath (Solar Eclipse)")
            return true
        end
        
        -- Default to Wrath for building
        if self:IsUsableSpell(S.Wrath) and self:GetSpellCooldown(S.Wrath) == 0 and manaPercent > 10 then
            CastSpellByName(S.Wrath, "target")
            DruidDebug("Balance: Wrath (building)")
            return true
        end
    end
    return false
end

-- =============================================
-- RESEARCH-BASED FERAL CAT DPS ROTATION
-- =============================================

function AC:FeralCatDpsRotation()
    local currentForm = self:GetCurrentDruidForm()
    local energy = UnitPower("player", 3)
    local cp = self:GetComboPoints()
    local health = self:GetPlayerHealthPercent()
    local enemies = self:GetEnemyCount()
    local hasTarget = UnitExists("target") and UnitCanAttack("player", "target") and not UnitIsDeadOrGhost("target")
    
    -- Shift to Cat if not already
    if currentForm ~= AC.DruidForms.CAT then
        if self:ShiftToForm(S.CatForm) then return true end
    end
    
    if not hasTarget then return false end
    
    -- Start auto-attack
    StartAttack()
    
    -- Defensive cooldowns
    if self:UseDruidDefensives(currentForm) then return true end
    
    local targetHP = self:GetTargetHealthPercent("target")
    local isBehind = self:IsBehindTarget()
    local isFastDying = self:IsFastDyingMob("target")
    local hasOOC = self:HasOmenOfClarity()
    
    -- RESEARCH PRIORITY 1: Faerie Fire (Feral) - armor reduction
    if self:DebuffTimeRemaining("target", S.FaerieFireFeral) < 5 and self:IsUsableSpell(S.FaerieFireFeral)
       and self:GetSpellCooldown(S.FaerieFireFeral) == 0 and Throttle("CatFaerieFire", 0.8) then
        CastSpellByName(S.FaerieFireFeral, "target")
        DruidDebug("Cat: Faerie Fire (armor reduction)")
        return true
    end
    
    -- AoE rotation (3+ enemies)
    if enemies >= 3 then
        -- RESEARCH: Swipe spam for AoE (only AoE ability for cats)
        if self:IsUsableSpell(S.SwipeCat) and energy >= (hasOOC and 0 or 45) then
            CastSpellByName(S.SwipeCat, "target")
            DruidDebug("Cat: Swipe (AoE)")
            return true
        end
    end
    
    -- 2-target cleave: keep ST maintenance, then use Swipe as filler.
    if enemies == 2 and cp < 5 and self:IsUsableSpell(S.SwipeCat) and energy >= (hasOOC and 0 or 45) then
        local srTimeCleave = self:BuffTimeRemaining("player", S.SavageRoar)
        local rakeTimeCleave = self:DebuffTimeRemaining("target", S.Rake)
        if srTimeCleave > 6 and rakeTimeCleave > 3 then
            CastSpellByName(S.SwipeCat, "target")
            DruidDebug("Cat: Swipe (2-target cleave filler)")
            return true
        end
    end
    
    -- ENHANCED SAVAGE ROAR MANAGEMENT WITH COMPLEXITY AWARENESS
    local complexity = self:GetRotationComplexity()
    local srTime = self:BuffTimeRemaining("player", S.SavageRoar)
    
    -- Advanced Savage Roar management with optimal combo point usage
    if complexity == "ADVANCED" or complexity == "MODERATE" then
        -- Use pandemic-style timing (refresh at 30% duration = ~9s for 30s buff)
        local shouldRefreshSR = srTime < 9 and cp >= 1 and energy >= 25
        
        -- Optimize combo point usage: prefer 5CP for long duration, 1CP only if urgent
        if shouldRefreshSR then
            if cp >= 5 then
                -- 5CP gives maximum duration
                if self:IsUsableSpell(S.SavageRoar) and self:GetSpellCooldown(S.SavageRoar) == 0
                   and Throttle("CatSavageRoar", 0.8) then
                    CastSpellByName(S.SavageRoar)
                    DruidDebug("Cat: Savage Roar (5CP - optimal duration)")
                    return true
                end
            elseif cp >= 1 and srTime < 3 then
                -- Emergency refresh with 1CP
                if self:IsUsableSpell(S.SavageRoar) and self:GetSpellCooldown(S.SavageRoar) == 0
                   and Throttle("CatSavageRoar", 0.8) then
                    CastSpellByName(S.SavageRoar)
                    DruidDebug("Cat: Savage Roar (" .. cp .. "CP - emergency refresh)")
                    return true
                end
            end
        end
    else
        -- Simple Savage Roar management for basic rotations
        if srTime < 3 and cp >= 1 and energy >= 25 then
            if self:IsUsableSpell(S.SavageRoar) and self:GetSpellCooldown(S.SavageRoar) == 0
               and Throttle("CatSavageRoar", 0.8) then
                CastSpellByName(S.SavageRoar)
                DruidDebug("Cat: Savage Roar (" .. cp .. "CP) - TOP PRIORITY")
                return true
            end
        end
    end
    
    -- ENHANCED RIP MANAGEMENT WITH PANDEMIC TIMING
    if cp >= 5 and not isFastDying and targetHP > 25 then
        local ripTime = self:DebuffTimeRemaining("target", S.Rip)
        local shouldRefreshRip = false
        
        if complexity == "ADVANCED" or complexity == "MODERATE" then
            -- Pandemic timing: refresh at 30% of 16s base duration = ~5s
            shouldRefreshRip = ripTime < 5 and energy >= 30
        else
            -- Simple timing for basic rotations
            shouldRefreshRip = ripTime < 4 and energy >= 30
        end
        
        if shouldRefreshRip then
            CastSpellByName(S.Rip, "target")
            DruidDebug("Cat: Rip (5CP - pandemic-aware)")
            return true
        end
    end
    
    -- RESEARCH PRIORITY 4: Ferocious Bite (5 CP, when DoTs/SR are maintained)
    if cp >= 5 and energy >= 35 then
        local srTime = self:BuffTimeRemaining("player", S.SavageRoar)
        local ripTime = self:DebuffTimeRemaining("target", S.Rip)
        
        -- Use FB if target is dying OR only with very healthy SR/Rip windows.
        if isFastDying or targetHP < 25 or (energy >= 55 and srTime > 10 and ripTime > 10) then
            CastSpellByName(S.FerociousBite, "target")
            DruidDebug("Cat: Ferocious Bite (5CP)")
            return true
        end
    end
    
    -- ENHANCED RAKE MANAGEMENT WITH PANDEMIC TIMING
    local rakeTime = self:DebuffTimeRemaining("target", S.Rake)
    local rakeCost = hasOOC and 0 or 35
    local shouldRefreshRake = false
    
    if not isFastDying and energy >= rakeCost then
        if complexity == "ADVANCED" or complexity == "MODERATE" then
            -- Pandemic timing: refresh at 30% of 9s base duration = ~3s
            shouldRefreshRake = rakeTime < 3
        else
            -- Simple timing for basic rotations
            shouldRefreshRake = rakeTime < 3
        end
        
        if shouldRefreshRake then
            CastSpellByName(S.Rake, "target")
            DruidDebug("Cat: Rake (9s DoT - pandemic-aware)")
            return true
        end
    end
    
    -- RESEARCH PRIORITY 6: Mangle debuff (30% bleed damage increase)
    local mangleTime = math.max(
        self:DebuffTimeRemaining("target", "Mangle"),
        self:DebuffTimeRemaining("target", S.MangleCat),
        self:DebuffTimeRemaining("target", S.MangleBear)
    )
    if mangleTime < 3 and self:IsUsableSpell(S.MangleCat) and energy >= (hasOOC and 0 or 45)
       and Throttle("CatMangleDebuff", 0.5) then
        CastSpellByName(S.MangleCat, "target")
        DruidDebug("Cat: Mangle (30% bleed damage debuff)")
        return true
    end
    
    -- RESEARCH PRIORITY 7: Build combo points (CP generation)
    if cp < 5 then
        -- RESEARCH: Shred if available (usability handles positional constraints in WotLK).
        if self:IsUsableSpell(S.Shred) and energy >= (hasOOC and 0 or 42) then
            CastSpellByName(S.Shred, "target")
            DruidDebug("Cat: Shred (CP builder)")
            return true
        end
        
        -- RESEARCH: Mangle if not behind (positioning-independent)
        if self:IsUsableSpell(S.MangleCat) and energy >= (hasOOC and 0 or 45) then
            CastSpellByName(S.MangleCat, "target")
            DruidDebug("Cat: Mangle (CP builder)")
            return true
        elseif self:IsUsableSpell(S.Claw) and energy >= (hasOOC and 0 or 45) then
            CastSpellByName(S.Claw, "target")
            DruidDebug("Cat: Claw (CP builder fallback)")
            return true
        end
    end

    -- Offensive cooldowns (energy management and burst) after urgent maintenance.
    if self:UseDruidOffensives("Feral", currentForm) then return true end
    
    -- Final 5CP anti-idle fallback: only bite when finishers are healthy.
    if cp == 5 and energy >= 60 and self:IsUsableSpell(S.FerociousBite) then
        local srTimeFinal = self:BuffTimeRemaining("player", S.SavageRoar)
        local ripTimeFinal = self:DebuffTimeRemaining("target", S.Rip)
        if srTimeFinal > 12 and ripTimeFinal > 12 then
            CastSpellByName(S.FerociousBite, "target")
            DruidDebug("Cat: Ferocious Bite (5CP final fallback)")
            return true
        end
    end

    return false
end

-- =============================================
-- RESEARCH-BASED FERAL BEAR TANK ROTATION
-- =============================================

function AC:FeralBearTankRotation()
    -- Initialize threat tracking variables
    self.expectedThreatTargets = self.expectedThreatTargets or {}
    self.lastTauntTime = self.lastTauntTime or 0
    self.lastTauntTarget = self.lastTauntTarget or ""
    
    local currentForm = self:GetCurrentDruidForm()
    local rage = UnitPower("player", 1)
    local health = self:GetPlayerHealthPercent()
    local enemies = self:GetEnemyCount()
    local hasTarget = UnitExists("target") and UnitCanAttack("player", "target") and not UnitIsDeadOrGhost("target")
    local autoTauntAllowed = self:IsAutoTauntAllowed()
    
    -- Shift to Bear if not already
    local bearForm = self:KnowsSpell(S.DireBearForm) and S.DireBearForm or S.BearForm
    if currentForm ~= AC.DruidForms.BEAR then
        if self:ShiftToForm(bearForm) then return true end
    end
    
    -- Auto-attack
    if hasTarget then StartAttack() end
    
    if not hasTarget then return false end
    
    -- Defensive cooldowns
    if self:UseDruidDefensives(currentForm) then return true end

    -- Queue Maul proactively since it is an on-next-swing attack, not a normal GCD spender.
    if self:IsUsableSpell(S.Maul) and not IsCurrentSpell(S.Maul) then
        local shouldQueueMaul
        if UnitLevel("player") < 20 then
            shouldQueueMaul = rage >= 14
        else
            shouldQueueMaul = (enemies <= 1 and rage >= 30) or rage >= 45
        end
        if shouldQueueMaul then
            CastSpellByName(S.Maul, "target")
            DruidDebug("Bear: Queued Maul")
        end
    end
    
    -- Combat rebuffs are disabled to avoid dropping out of Bear Form.
    
    -- Interrupt with Bash
    if UnitCastingInfo("target") and self:IsUsableSpell(S.Bash) and rage >= 10 then
        CastSpellByName(S.Bash, "target")
        DruidDebug("Bear: Bash interrupt")
        return true
    end
    
    -- RESEARCH: Enrage for rage generation (important for bear)
    if rage < 20 and self:IsUsableSpell(S.Enrage) then
        CastSpellByName(S.Enrage)
        DruidDebug("Bear: Enrage (rage gen)")
        return true
    end
    
    -- EPIC THREAT: Berserk with trinkets for maximum threat
    if self:IsUsableSpell(S.Berserk) and Throttle("BerserkBear", 180) then
        local targetClass = UnitClassification("target")
        local targetHP = self:GetTargetHealthPercent("target")
        
        -- EPIC CONDITIONS: Use on elite/boss targets or AoE situations
        if targetClass == "elite" or targetClass == "rareelite" or targetClass == "worldboss" or 
           enemies >= 3 or (targetHP > 100000 and IsInGroup()) then
            CastSpellByName(S.Berserk)
            DruidDebug("EPIC BERSERK: Maximum threat mode")
            
            -- Use trinkets with Berserk for maximum threat
            if self.UseTrinkets then self:UseTrinkets() end
            
            -- Use offensive racials
            if self:UseRacialsDruid(true, false) then
                DruidDebug("EPIC BERSERK: Used racial with Berserk")
            end
            
            return true
        end
    end
    
    -- EPIC PRIORITY 1: Faerie Fire (Feral) - MASSIVE threat + armor reduction
    if self:DebuffTimeRemaining("target", S.FaerieFireFeral) < 5 and self:IsUsableSpell(S.FaerieFireFeral) then
        CastSpellByName(S.FaerieFireFeral, "target")
        DruidDebug("EPIC THREAT: Faerie Fire (MASSIVE threat + armor reduction)")
        return true
    end
    
    -- REMOVED: Challenging Roar AoE taunt - handled by universal system
    
    -- EPIC PRIORITY 2: Demoralizing Roar - survivability and threat
    if enemies >= 1 and self:DebuffTimeRemaining("target", S.DemoralizingRoar) < 5 and 
       self:IsUsableSpell(S.DemoralizingRoar) and rage >= 10 then
        CastSpellByName(S.DemoralizingRoar)
        DruidDebug("EPIC SURVIVABILITY: Demoralizing Roar (damage reduction + threat)")
        return true
    end
    
    -- EPIC PRIORITY 2.5: Growl for single target threat emergency
    if autoTauntAllowed and enemies == 1 and self:IsUsableSpell(S.Growl) and Throttle("Growl", 8) then
        -- CRITICAL FIX: Only Growl if we actually HAD threat on this target before
        -- Don't use Growl as a pull ability - that's wasteful!
        if not UnitIsUnit("target", "player") and UnitExists("targettarget") then
            local targetGUID = UnitGUID("target")
            local hadThreatBefore = (self.expectedThreatTargets and self.expectedThreatTargets[targetGUID]) or
                                  (self.lastTauntTarget == targetGUID and (GetTime() - self.lastTauntTime) < 15)
            
            if hadThreatBefore then
                CastSpellByName(S.Growl, "target")
                self.lastTauntTime = GetTime()
                self.lastTauntTarget = UnitGUID("target")
                DruidDebug("EPIC THREAT: Growl (threat recovery)")
                return true
            else
                DruidDebug("BLOCKED wasteful Growl - we never had threat on this target")
                return false
            end
        end
    end
    
    -- EPIC PRIORITY 3: Advanced AoE threat management
    if enemies >= 2 and self:IsUsableSpell(S.SwipeBear) and rage >= 15 then
        CastSpellByName(S.SwipeBear)
        DruidDebug("EPIC AoE THREAT: Swipe (" .. enemies .. " enemies)")
        return true
    end
    
    -- REMOVED: Tab-target threat management - handled by universal system
    
    -- EPIC PRIORITY 4: Mangle - massive threat and bleed debuff
    if self:IsUsableSpell(S.MangleBear) and rage >= 20 then
        CastSpellByName(S.MangleBear, "target")
        DruidDebug("EPIC THREAT: Mangle (massive threat + bleed debuff)")
        return true
    end
    
    -- EPIC PRIORITY 5: Advanced Lacerate stacking with pandemic timing
    if self:IsUsableSpell(S.Lacerate) and rage >= 13 then
        local _, lacStacks = self:HasDebuff("target", S.Lacerate)
        local lacTimeRemaining = self:DebuffTimeRemaining("target", S.Lacerate)
        
        -- EPIC LACERATE LOGIC:
        -- 1. Build to 5 stacks for maximum DoT damage
        -- 2. Maintain with pandemic timing (refresh at 30% duration)
        -- 3. Each stack increases threat and damage
        if (lacStacks or 0) < 5 or lacTimeRemaining < 4.5 then -- Pandemic timing
            CastSpellByName(S.Lacerate, "target")
            DruidDebug("EPIC LACERATE: Stack " .. ((lacStacks or 0) + 1) .. "/5 (time: "..string.format("%.1f", lacTimeRemaining)..")")
            return true
        end
    end
    
    -- EPIC PRIORITY 6: Strategic Pulverize usage for survivability
    if self:KnowsSpell(S.Pulverize) and self:IsUsableSpell(S.Pulverize) and rage >= 15 then
        local _, lacStacks = self:HasDebuff("target", S.Lacerate)
        local pulverizeTime = self:BuffTimeRemaining("player", S.Pulverize)
        
        -- EPIC PULVERIZE LOGIC:
        -- 1. Use when we have 3+ Lacerate stacks
        -- 2. Provides 18% damage reduction buff
        -- 3. Only use if buff is about to expire or we need survivability
        if (lacStacks or 0) >= 3 and (pulverizeTime < 3 or health < 60) then
            CastSpellByName(S.Pulverize, "target")
            DruidDebug("EPIC SURVIVABILITY: Pulverize (18% damage reduction, consumed " .. (lacStacks or 0) .. " stacks)")
            return true
        end
    end
    
    -- EPIC PRIORITY 7: Swipe as efficient filler threat
    if self:IsUsableSpell(S.SwipeBear) and rage >= 15 then
        CastSpellByName(S.SwipeBear, "target")
        DruidDebug("EPIC THREAT: Swipe (filler threat)")
        return true
    end
    
    -- UNIVERSAL: Loose mob detection (only after all DPS abilities checked)
    if self:HandleUniversalLooseMobs() then return true end
    
    return false
end

-- =============================================
-- EPIC RESTORATION HEALING ROTATION
-- =============================================

function AC:RestorationDruidRotation()
    local currentForm = self:GetCurrentDruidForm()
    local mana = UnitPower("player", 0)
    local maxMana = UnitPowerMax("player", 0)
    local manaPercent = (maxMana > 0) and (mana/maxMana*100) or 100
    local health = self:GetPlayerHealthPercent()
    local inCombat = UnitAffectingCombat("player")
    local hasTarget = UnitExists("target") and UnitCanAttack("player", "target") and not UnitIsDeadOrGhost("target")
    
    -- SMART HEALING PRIORITY 1: EMERGENCY TRIAGE OVERRIDE
    -- If anyone is critically injured, emergency triage takes absolute priority
    if self:EmergencyTriage() then return true end
    
    -- EPIC PRIORITY 0: Handle dispels first
    if self:HandleDispels() then return true end
    
    -- Combat rebuffs are disabled to avoid shapeshift loss during combat.
    
    -- RESEARCH: Tree of Life form for healing (optional but beneficial)
    if self:KnowsSpell(S.TreeOfLife) then
        if currentForm ~= AC.DruidForms.TREE then
            if self:ShiftToForm(S.TreeOfLife) then return true end
        end
    end
    
    -- Defensive cooldowns
    if self:UseDruidDefensives(currentForm) then return true end
    
    -- EPIC PRIORITY 1: Emergency healing protocols
    local emergencyTarget, emergencyHP = self:FindHealingTarget(40, 0.25)
    if emergencyTarget then
        -- EPIC PROTOCOL: Nature's Swiftness + Healing Touch for <25% HP
        if emergencyHP < 0.25 and self:IsUsableSpell(S.NaturesSwiftness) then
            CastSpellByName(S.NaturesSwiftness)
            DruidDebug("EPIC EMERGENCY: Nature's Swiftness for " .. (UnitName(emergencyTarget) or emergencyTarget))
            return true
        end
        
        -- Use NS + HT combo immediately
        if self:HasBuff("player", S.NaturesSwiftness) and self:IsUsableSpell(S.HealingTouch) then
            CastSpellByName(S.HealingTouch, emergencyTarget)
            DruidDebug("EPIC EMERGENCY: NS + Healing Touch on " .. (UnitName(emergencyTarget) or emergencyTarget))
            return true
        end
        
        -- EPIC PROTOCOL: Swiftmend for emergency <30% HP
        if emergencyHP < 0.30 and self:IsUsableSpell(S.Swiftmend) then
            if self:HasBuff(emergencyTarget, S.Rejuvenation) or self:HasBuff(emergencyTarget, S.Regrowth) then
                CastSpellByName(S.Swiftmend, emergencyTarget)
                DruidDebug("EPIC EMERGENCY: Swiftmend on " .. (UnitName(emergencyTarget) or emergencyTarget))
                return true
            end
        end
    end
    
    -- EPIC PRIORITY 2: Mana management with Innervate on others
    if manaPercent < 30 and self:IsUsableSpell(S.Innervate) then
        -- Try to innervate other healers first if they need it more
        local healerNeedingMana = nil
        local groupUnits = {}
        if GetNumRaidMembers() > 0 then
            for i = 1, GetNumRaidMembers() do
                table.insert(groupUnits, "raid" .. i)
            end
        elseif GetNumPartyMembers() > 0 then
            for i = 1, GetNumPartyMembers() do
                table.insert(groupUnits, "party" .. i)
            end
        end
        
        for _, unit in ipairs(groupUnits) do
            if UnitExists(unit) and self:IsHealer(unit) and not UnitIsUnit(unit, "player") then
                local unitMana = UnitPower(unit, 0) / UnitPowerMax(unit, 0) * 100
                if unitMana < 20 then
                    healerNeedingMana = unit
                    break
                end
            end
        end
        
        local innervateTarget = healerNeedingMana or "player"
        CastSpellByName(S.Innervate, innervateTarget)
        DruidDebug("EPIC MANA: Innervate on " .. (UnitName(innervateTarget) or innervateTarget))
        return true
    end
    
    -- Mana potion
    if manaPercent < 20 and self.UseManaPotion and self:UseManaPotion(20) then
        DruidDebug("Used mana potion")
        return true
    end
    
    -- SMART HEALING PRIORITY 2: INTELLIGENT HEALING ALGORITHM
    -- Use advanced smart healing system for optimal spell selection and overhealing minimization
    if self:SmartHeal() then return true end
    
    -- RESEARCH: Nature's Swiftness emergency healing
    if self:IsUsableSpell(S.NaturesSwiftness) then
        local emergTarget, emergHP = self:FindHealingTarget(40, 0.30)
        if emergTarget then
            CastSpellByName(S.NaturesSwiftness)
            DruidDebug("Resto: Nature's Swiftness (emergency)")
            return true
        end
    end
    
    -- Use NS + Healing Touch
    if self:HasBuff("player", S.NaturesSwiftness) and self:IsUsableSpell(S.HealingTouch) then
        local emergTarget, emergHP = self:FindHealingTarget(40, 0.40)
        if emergTarget then
            CastSpellByName(S.HealingTouch, emergTarget)
            DruidDebug("Resto: NS + Healing Touch on " .. UnitName(emergTarget))
            return true
        end
    end
    
    -- Find healing target
    local healTarget, healTargetHealth = self:FindHealingTarget(40, 0.95)
    
    -- No healing needed - DPS if safe
    if not healTarget then
        if hasTarget and manaPercent > 70 and not self:IsChanneling() then
            -- Maintain DoTs for DPS
            if self:DebuffTimeRemaining("target", S.Moonfire) < 3 and self:IsUsableSpell(S.Moonfire) then
                CastSpellByName(S.Moonfire, "target")
                DruidDebug("Resto: Moonfire (DPS)")
                return true
            end
            
            if self:DebuffTimeRemaining("target", S.InsectSwarm) < 3 and self:IsUsableSpell(S.InsectSwarm) then
                CastSpellByName(S.InsectSwarm, "target")
                DruidDebug("Resto: Insect Swarm (DPS)")
                return true
            end
            
            -- Wrath spam
            if self:IsUsableSpell(S.Wrath) and not UnitCastingInfo("player") then
                CastSpellByName(S.Wrath, "target")
                DruidDebug("Resto: Wrath (DPS)")
                return true
            end
        end
        return false
    end
    
    -- RESEARCH PRIORITY 1: Swiftmend emergency heal (instant)
    if healTargetHealth < 0.50 and self:IsUsableSpell(S.Swiftmend) then
        if self:HasBuff(healTarget, S.Rejuvenation) or self:HasBuff(healTarget, S.Regrowth) then
            CastSpellByName(S.Swiftmend, healTarget)
            DruidDebug("Resto: Swiftmend on " .. UnitName(healTarget))
            return true
        end
    end
    
    -- EPIC PRIORITY 3: Advanced group healing with Wild Growth
    if self:IsUsableSpell(S.WildGrowth) and healTargetHealth < 0.80 then
        -- Enhanced group damage detection
        local groupUnits = {}
        if GetNumRaidMembers() > 0 then
            for i = 1, GetNumRaidMembers() do
                table.insert(groupUnits, "raid" .. i)
            end
        elseif GetNumPartyMembers() > 0 then
            for i = 1, GetNumPartyMembers() do
                table.insert(groupUnits, "party" .. i)
            end
        end
        
        local lowHealthCount = 0
        local tanksDamaged = 0
        
        for _, unit in ipairs(groupUnits) do
            if UnitExists(unit) and not UnitIsDeadOrGhost(unit) then
                local hp = UnitHealth(unit) / UnitHealthMax(unit)
                if hp < 0.85 then
                    lowHealthCount = lowHealthCount + 1
                    if self:IsTank(unit) then
                        tanksDamaged = tanksDamaged + 1
                    end
                end
            end
        end
        
        -- Use Wild Growth if:
        -- 1. 3+ people need healing, OR
        -- 2. 2+ people including tank(s) need healing
        if lowHealthCount >= 3 or (lowHealthCount >= 2 and tanksDamaged >= 1) then
            CastSpellByName(S.WildGrowth, healTarget)
            DruidDebug("EPIC GROUP HEAL: Wild Growth (" .. lowHealthCount .. " targets, " .. tanksDamaged .. " tanks)")
            return true
        end
    end
    
    -- EPIC PRIORITY 4: Advanced Lifebloom management on all tanks
    local tankUnits = {}
    if IsDruidInGroup() then
        local groupUnits = {}
        if GetNumRaidMembers() > 0 then
            for i = 1, GetNumRaidMembers() do
                table.insert(groupUnits, "raid" .. i)
            end
        elseif GetNumPartyMembers() > 0 then
            for i = 1, GetNumPartyMembers() do
                table.insert(groupUnits, "party" .. i)
            end
        end
        
        -- Find all tanks
        for _, unit in ipairs(groupUnits) do
            if UnitExists(unit) and self:IsTank(unit) then
                table.insert(tankUnits, unit)
            end
        end
    end
    
    -- Maintain Lifebloom on all tanks with pandemic timing
    for _, tankUnit in ipairs(tankUnits) do
        local _, _, _, lbStacks = self:HasBuff(tankUnit, S.Lifebloom)
        local lbTimeRemaining = self:BuffTimeRemaining(tankUnit, S.Lifebloom)
        
        -- EPIC LIFEBLOOM MANAGEMENT:
        -- 1. Build to 3 stacks
        -- 2. Maintain with pandemic timing (refresh when <30% duration, ~4.5s)
        -- 3. Let bloom for mana return if tank is healthy
        local tankHP = UnitHealth(tankUnit) / UnitHealthMax(tankUnit)
        
        if (lbStacks or 0) < 3 or (lbTimeRemaining < 4.5 and tankHP < 0.90) then
            CastSpellByName(S.Lifebloom, tankUnit)
            DruidDebug("EPIC LIFEBLOOM: " .. (UnitName(tankUnit) or tankUnit) .. " (stack: "..(lbStacks or 0).."/3, time: "..string.format("%.1f", lbTimeRemaining)..")")
            return true
        end
    end
    
    -- EPIC PRIORITY 5: Rejuvenation blanket with smart application
    if healTargetHealth < 0.95 then
        local rejuvTime = self:BuffTimeRemaining(healTarget, S.Rejuvenation)
        
        -- EPIC REJUVENATION LOGIC:
        -- 1. Apply to anyone missing health
        -- 2. Use pandemic timing (refresh at 30% duration)
        -- 3. Prioritize tanks and healers
        local rejuvPriority = 1
        if self:IsTank(healTarget) then
            rejuvPriority = 3
        elseif self:IsHealer(healTarget) then
            rejuvPriority = 2
        end
        
        -- Apply or refresh based on priority and pandemic timing
        if rejuvTime < (4.5 * rejuvPriority) then -- Higher priority = longer refresh window
            CastSpellByName(S.Rejuvenation, healTarget)
            DruidDebug("EPIC REJUVENATION: " .. (UnitName(healTarget) or healTarget) .. " (priority: " .. rejuvPriority .. ", time: "..string.format("%.1f", rejuvTime)..")")
            return true
        end
    end
    
    -- EPIC PRIORITY 6: Smart Regrowth usage
    if healTargetHealth < 0.70 and manaPercent > 30 and not UnitCastingInfo("player") then
        -- EPIC REGROWTH LOGIC:
        -- 1. Use on targets that need immediate healing
        -- 2. Prefer tanks and healers
        -- 3. Use when we have Nature's Grace proc for faster cast
        local shouldRegrowth = false
        
        if healTargetHealth < 0.50 then
            shouldRegrowth = true -- Always regrowth <50% HP
        elseif (self:IsTank(healTarget) or self:IsHealer(healTarget)) and healTargetHealth < 0.70 then
            shouldRegrowth = true -- Regrowth important targets <70% HP
        elseif self:HasBuff("player", S.NaturesGrace) then
            shouldRegrowth = true -- Use proc for faster cast
        end
        
        if shouldRegrowth then
            CastSpellByName(S.Regrowth, healTarget)
            DruidDebug("EPIC REGROWTH: " .. (UnitName(healTarget) or healTarget) .. " (HP: "..string.format("%.1f%%", healTargetHealth*100)..")")
            return true
        end
    end
    
    -- EPIC PRIORITY 7: Advanced Nourish with HoT synergy
    if healTargetHealth < 0.85 and self:IsUsableSpell(S.Nourish) and not UnitCastingInfo("player") then
        -- EPIC NOURISH LOGIC:
        -- 1. Only use when target has HoTs (for synergy bonus)
        -- 2. Count the number of HoTs for efficiency calculation
        -- 3. Prefer high-priority targets with multiple HoTs
        
        local hotCount = 0
        if self:HasBuff(healTarget, S.Rejuvenation) then hotCount = hotCount + 1 end
        if self:HasBuff(healTarget, S.Regrowth) then hotCount = hotCount + 1 end
        if self:HasBuff(healTarget, S.Lifebloom) then hotCount = hotCount + 1 end
        if self:HasBuff(healTarget, S.WildGrowth) then hotCount = hotCount + 1 end
        
        if hotCount >= 2 or (hotCount >= 1 and (self:IsTank(healTarget) or healTargetHealth < 0.70)) then
            CastSpellByName(S.Nourish, healTarget)
            DruidDebug("EPIC NOURISH: " .. (UnitName(healTarget) or healTarget) .. " (" .. hotCount .. " HoTs, HP: "..string.format("%.1f%%", healTargetHealth*100)..")")
            return true
        end
    end
    
    -- EPIC PRIORITY 8: Strategic Healing Touch usage
    if healTargetHealth < 0.60 and manaPercent > 20 and not UnitCastingInfo("player") then
        -- EPIC HEALING TOUCH LOGIC:
        -- 1. Use on tanks that need big heals
        -- 2. Use when we have Nature's Grace for faster cast
        -- 3. Use for emergency healing when other spells are on cooldown
        
        local shouldHealingTouch = false
        
        if self:IsTank(healTarget) and healTargetHealth < 0.60 then
            shouldHealingTouch = true -- Always big heal tanks
        elseif healTargetHealth < 0.40 then
            shouldHealingTouch = true -- Emergency big heal
        elseif self:HasBuff("player", S.NaturesGrace) and healTargetHealth < 0.60 then
            shouldHealingTouch = true -- Use proc for faster cast
        end
        
        if shouldHealingTouch then
            CastSpellByName(S.HealingTouch, healTarget)
            DruidDebug("EPIC HEALING TOUCH: " .. (UnitName(healTarget) or healTarget) .. " (HP: "..string.format("%.1f%%", healTargetHealth*100)..")")
            return true
        end
    end
    
    -- EPIC PRIORITY 9: Advanced Tranquility panic protocol
    if self:IsUsableSpell(S.Tranquility) and Throttle("Tranquility", 480) then
        local groupUnits = {}
        if GetNumRaidMembers() > 0 then
            for i = 1, GetNumRaidMembers() do
                table.insert(groupUnits, "raid" .. i)
            end
        elseif GetNumPartyMembers() > 0 then
            for i = 1, GetNumPartyMembers() do
                table.insert(groupUnits, "party" .. i)
            end
        end
        
        local criticalHealthCount = 0
        local lowHealthCount = 0
        local tanksCritical = 0
        
        for _, unit in ipairs(groupUnits) do
            if UnitExists(unit) and not UnitIsDeadOrGhost(unit) then
                local hp = UnitHealth(unit) / UnitHealthMax(unit)
                if hp < 0.30 then
                    criticalHealthCount = criticalHealthCount + 1
                    if self:IsTank(unit) then
                        tanksCritical = tanksCritical + 1
                    end
                elseif hp < 0.50 then
                    lowHealthCount = lowHealthCount + 1
                end
            end
        end
        
        -- EPIC TRANQUILITY CONDITIONS:
        -- 1. 3+ people critical (<30% HP), OR
        -- 2. 1+ tanks critical, OR
        -- 3. 5+ people low health (<50% HP)
        if criticalHealthCount >= 3 or tanksCritical >= 1 or lowHealthCount >= 5 then
            CastSpellByName(S.Tranquility)
            DruidDebug("EPIC TRANQUILITY: PANIC MODE (Critical: " .. criticalHealthCount .. ", Tanks: " .. tanksCritical .. ", Low: " .. lowHealthCount .. ")")
            return true
        end
    end
    
    return false
end

-- =============================================
-- HELPER FUNCTIONS
-- =============================================

-- =============================================
-- EPIC HEALING TARGET SYSTEM
-- =============================================

-- Enhanced healing target finder with priority system
function AC:FindHealingTarget(range, threshold)
    local healingTargets = {}
    
    -- Add player to candidates
    local playerHP = self:GetPlayerHealthPercent() / 100
    if playerHP < threshold then
        table.insert(healingTargets, {
            unit = "player",
            health = playerHP,
            priority = 5, -- Medium priority
            role = "self"
        })
    end
    
    -- Get group units
    local groupUnits = {"player"}
    if GetNumRaidMembers() > 0 then
        for i = 1, GetNumRaidMembers() do
            table.insert(groupUnits, "raid" .. i)
        end
    elseif GetNumPartyMembers() > 0 then
        for i = 1, GetNumPartyMembers() do
            table.insert(groupUnits, "party" .. i)
        end
    end
    
    -- Analyze each group member
    for _, unit in ipairs(groupUnits) do
        if UnitExists(unit) and not UnitIsDeadOrGhost(unit) and UnitIsConnected(unit) then
            local hp = UnitHealth(unit) / UnitHealthMax(unit)
            if hp < threshold then
                local priority = 3 -- Default priority
                local role = "dps"
                
                -- EPIC PRIORITY SYSTEM
                if self:IsTank(unit) then
                    priority = 10 -- HIGHEST PRIORITY
                    role = "tank"
                elseif self:IsHealer(unit) then
                    priority = 8 -- High priority
                    role = "healer"
                elseif hp < 0.30 then
                    priority = priority + 5 -- Emergency bonus
                end
                
                -- Healing requires actual spell range, not interact distance.
                local inRange = IsHealingSpellInRange(unit)
                
                if inRange then
                    table.insert(healingTargets, {
                        unit = unit,
                        health = hp,
                        priority = priority,
                        role = role
                    })
                end
            end
        end
    end
    
    -- Sort by priority (highest first), then by health (lowest first)
    table.sort(healingTargets, function(a, b)
        if a.priority == b.priority then
            return a.health < b.health
        end
        return a.priority > b.priority
    end)
    
    -- Return the highest priority target
    if #healingTargets > 0 then
        local target = healingTargets[1]
        DruidDebug("EPIC HEAL TARGET: " .. target.role .. " (" .. (UnitName(target.unit) or target.unit) .. 
                  ") HP: " .. string.format("%.1f%%", target.health * 100) .. " Priority: " .. target.priority)
        return target.unit, target.health
    end
    
    return nil, 1.0
end

-- Enhanced role detection
function AC:IsHealer(unit)
    if not UnitExists(unit) then return false end
    local _, class = UnitClass(unit)
    return class == "PRIEST" or class == "PALADIN" or class == "SHAMAN" or class == "DRUID"
end

-- REDIRECT: Tank detection now handled by Core.lua universal system
function AC:IsTank(unit)
    return self:IsTankSpec(unit)
end

-- =============================================
-- EPIC DISPEL SYSTEM
-- =============================================

function AC:HandleDispels()
    if not Throttle("DruidDispels", 1) then return false end
    
    -- Get group units
    local groupUnits = {"player"}
    if GetNumRaidMembers() > 0 then
        for i = 1, GetNumRaidMembers() do
            table.insert(groupUnits, "raid" .. i)
        end
    elseif GetNumPartyMembers() > 0 then
        for i = 1, GetNumPartyMembers() do
            table.insert(groupUnits, "party" .. i)
        end
    end
    
    -- Check for curses first (higher priority)
    for _, unit in ipairs(groupUnits) do
        if UnitExists(unit) and not UnitIsDeadOrGhost(unit) then
            -- Check for curse
            for i = 1, 40 do
                local name, _, _, debuffType = UnitDebuff(unit, i)
                if not name then break end
                
                if debuffType == "Curse" and self:IsUsableSpell(S.RemoveCurse) then
                    CastSpellByName(S.RemoveCurse, unit)
                    DruidDebug("EPIC DISPEL: Removed curse from " .. (UnitName(unit) or unit))
                    return true
                end
            end
        end
    end
    
    -- Check for poisons
    for _, unit in ipairs(groupUnits) do
        if UnitExists(unit) and not UnitIsDeadOrGhost(unit) then
            -- Check for poison
            for i = 1, 40 do
                local name, _, _, debuffType = UnitDebuff(unit, i)
                if not name then break end
                
                if debuffType == "Poison" and self:IsUsableSpell(S.AbolishPoison) then
                    CastSpellByName(S.AbolishPoison, unit)
                    DruidDebug("EPIC DISPEL: Removed poison from " .. (UnitName(unit) or unit))
                    return true
                end
            end
        end
    end
    
    return false
end

-- =============================================
-- EPIC GROUP BUFFING SYSTEM
-- =============================================

function AC:CheckDruidGroupBuffs()
    if not Throttle("DruidGroupBuffs", 15) then return false end
    if UnitAffectingCombat("player") or IsMounted() then return false end
    
    -- Get group units
    local groupUnits = {"player"}
    if GetNumRaidMembers() > 0 then
        for i = 1, GetNumRaidMembers() do
            table.insert(groupUnits, "raid" .. i)
        end
    elseif GetNumPartyMembers() > 0 then
        for i = 1, GetNumPartyMembers() do
            table.insert(groupUnits, "party" .. i)
        end
    end
    
    -- EPIC PRIORITY 1: Mark of the Wild / Gift of the Wild
    local motwSpell = self:KnowsSpell(S.GiftOfTheWild) and S.GiftOfTheWild or S.MarkOfTheWild
    for _, unit in ipairs(groupUnits) do
        if UnitExists(unit) and not UnitIsDeadOrGhost(unit) and UnitIsConnected(unit) then
            local hasMotW = self:HasBuff(unit, S.MarkOfTheWild) or self:HasBuff(unit, S.GiftOfTheWild) or
                           self:HasBuff(unit, "Blessing of Kings") -- Don't overwrite Kings
            
            if not hasMotW and CheckInteractDistance(unit, 4) and self:IsUsableSpell(motwSpell) then
                CastSpellByName(motwSpell, unit)
                DruidDebug("EPIC GROUP BUFF: " .. motwSpell .. " on " .. (UnitName(unit) or unit))
                return true
            end
        end
    end
    
    -- EPIC PRIORITY 2: Thorns for melee DPS and tanks (MASSIVE DPS BOOST)
    if self:IsUsableSpell(S.Thorns) and self:KnowsSpell(S.Thorns) then
        -- Priority system for Thorns:
        -- 1. Tanks (highest priority - they take the most hits)
        -- 2. Melee DPS (rogues, warriors, enhancement shamans, feral druids)
        -- 3. Hunters (for pet tanking and melee weaving)
        -- 4. Self if no better targets
        
        local thornTargets = {}
        
        -- Analyze all group members for Thorns eligibility
        for _, unit in ipairs(groupUnits) do
            if UnitExists(unit) and not UnitIsDeadOrGhost(unit) and UnitIsConnected(unit) and
               CheckInteractDistance(unit, 4) and not self:HasBuff(unit, S.Thorns) then
                
                local _, class = UnitClass(unit)
                local priority = 0
                local role = "unknown"
                
                -- EPIC THORNS PRIORITY SYSTEM
                if self:IsTank(unit) then
                    priority = 100 -- MAXIMUM PRIORITY - tanks take most hits
                    role = "tank"
                elseif class == "ROGUE" or class == "WARRIOR" then
                    priority = 90 -- High priority melee DPS
                    role = "melee dps"
                elseif class == "DEATHKNIGHT" then
                    priority = 85 -- Death Knights are always melee
                    role = "melee dps"
                elseif class == "SHAMAN" then
                    priority = 80 -- Enhancement shamans benefit greatly
                    role = "melee dps"
                elseif class == "DRUID" then
                    -- Check if feral (cat/bear form)
                    if self:HasBuff(unit, S.CatForm) or self:HasBuff(unit, S.BearForm) or self:HasBuff(unit, S.DireBearForm) then
                        priority = 85 -- Feral druids in melee forms
                        role = "melee dps"
                    else
                        priority = 30 -- Caster druids (low priority)
                        role = "caster"
                    end
                elseif class == "PALADIN" then
                    -- Check if retribution (melee) or protection (tank)
                    if self:IsTank(unit) then
                        priority = 100 -- Tank priority
                        role = "tank"
                    else
                        priority = 75 -- Assume retribution if not tank
                        role = "melee dps"
                    end
                elseif class == "HUNTER" then
                    priority = 60 -- Hunters benefit from pet tanking and melee weaving
                    role = "ranged dps"
                else
                    priority = 20 -- Casters get low priority
                    role = "caster"
                end
                
                -- Add level-based priority adjustment
                local level = UnitLevel(unit)
                if level >= 70 then
                    priority = priority + 10 -- Endgame characters get priority
                end
                
                table.insert(thornTargets, {
                    unit = unit,
                    priority = priority,
                    role = role,
                    class = class,
                    name = UnitName(unit) or unit
                })
            end
        end
        
        -- Sort by priority (highest first)
        table.sort(thornTargets, function(a, b)
            return a.priority > b.priority
        end)
        
        -- Apply Thorns to the highest priority target
        if #thornTargets > 0 then
            local target = thornTargets[1]
            CastSpellByName(S.Thorns, target.unit)
            DruidDebug("EPIC THORNS: " .. target.name .. " (" .. target.role .. ", " .. target.class .. ", priority: " .. target.priority .. ")")
            return true
        end
    end
    
    return false
end

-- =============================================
-- EPIC REBUFF SYSTEM (Combat Buff Maintenance)
-- =============================================

function AC:CheckDruidCombatBuffs()
    if UnitAffectingCombat("player") then return false end
    if not Throttle("DruidCombatBuffs", 5) then return false end
    
    -- Get group units for combat rebuffing
    local groupUnits = {"player"}
    if GetNumRaidMembers() > 0 then
        for i = 1, GetNumRaidMembers() do
            table.insert(groupUnits, "raid" .. i)
        end
    elseif GetNumPartyMembers() > 0 then
        for i = 1, GetNumPartyMembers() do
            table.insert(groupUnits, "party" .. i)
        end
    end
    
    -- EPIC COMBAT PRIORITY 1: Rebuff Mark of the Wild on group members who died and were rezzed
    local motwSpell = self:KnowsSpell(S.GiftOfTheWild) and S.GiftOfTheWild or S.MarkOfTheWild
    for _, unit in ipairs(groupUnits) do
        if UnitExists(unit) and not UnitIsDeadOrGhost(unit) and UnitIsConnected(unit) then
            local hasMotW = self:HasBuff(unit, S.MarkOfTheWild) or self:HasBuff(unit, S.GiftOfTheWild) or
                           self:HasBuff(unit, "Blessing of Kings") -- Don't overwrite Kings
            
            if not hasMotW and CheckInteractDistance(unit, 4) and self:IsUsableSpell(motwSpell) then
                CastSpellByName(motwSpell, unit)
                DruidDebug("EPIC COMBAT REBUFF: " .. motwSpell .. " on " .. (UnitName(unit) or unit))
                return true
            end
        end
    end
    
    -- EPIC COMBAT PRIORITY 2: Reapply Thorns on high-priority targets who lost it
    if self:IsUsableSpell(S.Thorns) and self:KnowsSpell(S.Thorns) then
        -- Find tanks and melee DPS who lost Thorns
        for _, unit in ipairs(groupUnits) do
            if UnitExists(unit) and not UnitIsDeadOrGhost(unit) and UnitIsConnected(unit) and
               CheckInteractDistance(unit, 4) and not self:HasBuff(unit, S.Thorns) then
                
                local _, class = UnitClass(unit)
                local needsThorns = false
                
                -- Priority reapplication for tanks and melee DPS
                if self:IsTank(unit) then
                    needsThorns = true -- Tanks always need Thorns
                elseif class == "ROGUE" or class == "WARRIOR" or class == "DEATHKNIGHT" then
                    needsThorns = true -- Pure melee classes
                elseif class == "PALADIN" and not self:IsHealer(unit) then
                    needsThorns = true -- Assume ret/prot paladin
                elseif class == "DRUID" then
                    -- Check if feral
                    if self:HasBuff(unit, S.CatForm) or self:HasBuff(unit, S.BearForm) or self:HasBuff(unit, S.DireBearForm) then
                        needsThorns = true
                    end
                end
                
                if needsThorns then
                    CastSpellByName(S.Thorns, unit)
                    DruidDebug("EPIC COMBAT REBUFF: Thorns on " .. (UnitName(unit) or unit) .. " (" .. class .. ")")
                    return true
                end
            end
        end
    end
    
    return false
end

-- =============================================
-- EPIC RACIAL SYSTEM
-- =============================================

function AC:UseRacialsDruid(burst, emergency)
    if not Throttle("DruidRacials", 3) then return false end
    local _, race = UnitRace("player")
    race = string.upper(race)
    local health = self:GetPlayerHealthPercent()
    local manaPercent = UnitPower("player", 0) / UnitPowerMax("player", 0) * 100
    local inCombat = UnitAffectingCombat("player")
    
    -- Offensive racials
    if burst and inCombat then
        if race == "TROLL" and self:IsUsableSpell(S.Berserking) then
            CastSpellByName(S.Berserking)
            DruidDebug("Racial: Berserking")
            return true
        end
        if race == "ORC" and self:IsUsableSpell(S.BloodFury) then
            CastSpellByName(S.BloodFury)
            DruidDebug("Racial: Blood Fury")
            return true
        end
    end
    
    -- Defensive/Emergency racials
    if emergency or health < 50 then
        if race == "TAUREN" and self:GetEnemyCount() >= 2 and self:IsInMeleeRange("target") and 
           self:IsUsableSpell(S.WarStomp) then
            CastSpellByName(S.WarStomp)
            DruidDebug("Racial: War Stomp")
            return true
        end
        if race == "NIGHTELF" and self:IsUsableSpell(S.Shadowmeld) then
            CastSpellByName(S.Shadowmeld)
            DruidDebug("Racial: Shadowmeld")
            return true
        end
        if race == "UNDEAD" and self:IsUsableSpell(S.WillOfTheForsaken) then
            CastSpellByName(S.WillOfTheForsaken)
            DruidDebug("Racial: Will of the Forsaken")
            return true
        end
        if race == "DWARF" and self:IsUsableSpell(S.Stoneform) then
            CastSpellByName(S.Stoneform)
            DruidDebug("Racial: Stoneform")
            return true
        end
        if race == "GNOME" and self:IsUsableSpell(S.EscapeArtist) then
            CastSpellByName(S.EscapeArtist)
            DruidDebug("Racial: Escape Artist")
            return true
        end
        if race == "DRAENEI" and health < 70 and self:IsUsableSpell(S.GiftOfTheNaaru) then
            CastSpellByName(S.GiftOfTheNaaru, "player")
            DruidDebug("Racial: Gift of the Naaru")
            return true
        end
        if race == "BLOODELF" and manaPercent < 80 and self:IsUsableSpell(S.ArcaneTorrent) then
            CastSpellByName(S.ArcaneTorrent)
            DruidDebug("Racial: Arcane Torrent")
            return true
        end
        if race == "HUMAN" and self:IsUsableSpell(S.EveryManForHimself) then
            CastSpellByName(S.EveryManForHimself)
            DruidDebug("Racial: Every Man for Himself")
            return true
        end
    end
    
    return false
end

-- =============================================
-- MAIN DRUID ROTATION CONTROLLER
-- =============================================

function AC:DruidRotation()
    local spec = self:GetPlayerSpec()
    local level = UnitLevel("player")
    local inCombat = UnitAffectingCombat("player")
    local hasTarget = UnitExists("target") and UnitCanAttack("player", "target") and not UnitIsDeadOrGhost("target")
    local currentForm = self:GetCurrentDruidForm()
    local mana = UnitPower("player", 0)
    local maxMana = UnitPowerMax("player", 0)
    local manaPercent = (maxMana > 0) and (mana/maxMana*100) or 100
    local isFeralBuild = self:IsFeralBuild()
    local feralRole = nil

    if level < 10 then
        return self:LevelingDruidRotation()
    end

    if isFeralBuild then
        feralRole = self:DetermineFeralRole()
        if not self:KnowsSpell(S.CatForm) then
            feralRole = "bear"
        end
        if inCombat then
            if not self.druidFeralCombatRole then
                self.druidFeralCombatRole = feralRole
                DruidDebug("Feral combat role locked: " .. tostring(feralRole))
            end
            feralRole = self.druidFeralCombatRole or feralRole
        else
            self.druidFeralCombatRole = nil
        end
    end
    
    -- Emergency Lifeblood (Herbalism profession ability) at 50% health
    if inCombat and self:UseLifeblood() then return true end
    
    -- Out of combat actions
    if not inCombat then
        -- Balance pre-pull: keep this minimal for stable combat entry.
        if spec == "Balance" and hasTarget then
            if self:KnowsSpell(S.MoonkinForm) and currentForm ~= AC.DruidForms.MOONKIN then
                if self:ShiftToForm(S.MoonkinForm) then return true end
            end
            if self:IsUsableSpell(S.Wrath) and manaPercent > 10 and not UnitCastingInfo("player") then
                CastSpellByName(S.Wrath, "target")
                DruidDebug("Balance: Wrath pre-pull")
                return true
            end
            return false
        end

        -- Buffs
        if self:CheckDruidBuffs() then return true end
        
        -- Travel forms management
        if not hasTarget then
            local moving = self:IsPlayerMoving()
            if IsSwimming() and currentForm ~= AC.DruidForms.AQUATIC then
                if self:ShiftToForm(S.AquaticForm) then return true end
            elseif IsFlyableArea() and moving and currentForm ~= AC.DruidForms.FLIGHT and 
                   currentForm ~= AC.DruidForms.SWIFT_FLIGHT then
                local flightForm = self:KnowsSpell(S.SwiftFlightForm) and S.SwiftFlightForm or S.FlightForm
                if self:ShiftToForm(flightForm) then return true end
            elseif moving and currentForm ~= AC.DruidForms.TRAVEL and not IsFlyableArea() and not IsSwimming() then
                if self:ShiftToForm(S.TravelForm) then return true end
            elseif not moving and (currentForm == AC.DruidForms.TRAVEL or currentForm == AC.DruidForms.FLIGHT or 
                                  currentForm == AC.DruidForms.SWIFT_FLIGHT or currentForm == AC.DruidForms.AQUATIC) then
                -- Cancel travel form when stopped
                if self:ShiftToForm("Caster") then return true end
            end
        end
        
        -- RESEARCH: Feral stealth opener
        if hasTarget and not UnitAffectingCombat("target") then
            if isFeralBuild and feralRole == "bear" then
                local desiredBearForm = self:KnowsSpell(S.DireBearForm) and S.DireBearForm or S.BearForm
                if currentForm ~= AC.DruidForms.BEAR then
                    if self:ShiftToForm(desiredBearForm) then return true end
                end
            elseif isFeralBuild and feralRole == "cat" then
                if currentForm ~= AC.DruidForms.CAT then
                    if self:ShiftToForm(S.CatForm) then return true end
                end
                if level >= 20 and currentForm == AC.DruidForms.CAT then
                    if not self:HasBuff("player", S.Prowl) and self:IsUsableSpell(S.Prowl) then
                        CastSpellByName(S.Prowl)
                        DruidDebug("Prowl for stealth opener")
                        return true
                    end
                    if self:HasBuff("player", S.Prowl) and self:IsInMeleeRange("target") then
                        if self:IsUsableSpell(S.Pounce) then
                            CastSpellByName(S.Pounce, "target")
                            DruidDebug("Pounce opener")
                            return true
                        elseif self:IsUsableSpell(S.Ravage) then
                            CastSpellByName(S.Ravage, "target")
                            DruidDebug("Ravage opener")
                            return true
                        end
                    end
                end
            else
                -- Balance: shift to Moonkin Form before pull Wrath
                if spec == "Balance" and self:KnowsSpell(S.MoonkinForm) and currentForm ~= AC.DruidForms.MOONKIN then
                    if self:ShiftToForm(S.MoonkinForm) then return true end
                end
                
                -- Ranged pull for casters (Balance uses in-combat opener instead)
                if spec ~= "Balance" and self:IsUsableSpell(S.Wrath) then
                    CastSpellByName(S.Wrath, "target")
                    DruidDebug("Wrath pull")
                    return true
                end
            end
        end
        
        return false
    end
    
    -- In combat rotation dispatch based on spec
    if spec == "Balance" then
        return self:BalanceDruidRotation()
    elseif isFeralBuild then
        if feralRole == "bear" or not self:KnowsSpell(S.CatForm) then
            return self:FeralBearTankRotation()
        else
            return self:FeralCatDpsRotation()
        end
    elseif spec == "Restoration" then
        return self:RestorationDruidRotation()
    else
        if level < 20 then
            -- Bear form tanking
            return self:FeralBearTankRotation()
        else
            -- Cat form DPS
            return self:FeralCatDpsRotation()
        end
    end
    
    return false
end

-- =============================================
-- INITIALIZATION
-- =============================================

function AC:InitDruidRotations()
    self.rotations = self.rotations or {}
    self.rotations["DRUID"] = {}
    self.druidFeralCombatRole = nil
    
    self.rotations["DRUID"]["Balance"] = function(s) return s:DruidRotation() end
    self.rotations["DRUID"]["Feral"] = function(s) return s:DruidRotation() end
    self.rotations["DRUID"]["Restoration"] = function(s) return s:DruidRotation() end
    self.rotations["DRUID"]["None"] = function(s) return s:DruidRotation() end
    
    self.CheckDruidBuffs = AC.CheckDruidBuffs
    
    self:Print("|cFFFF7D0A Druid|r rotations initialized - |cFFFFD700RESEARCH-BASED WotLK 3.3.5a|r")
    DruidDebug("|cFFFF7D0A=== DRUID IMPROVEMENTS ===|r")
    DruidDebug("|cFF0070DDBalance:|r Eclipse management + research-based DoT priorities")
    DruidDebug("|cFFFF6347Feral Cat:|r Priority system: Savage Roar > Rip > Rake > Shred/Mangle")
    DruidDebug("|cFF8B4513Feral Bear:|r Proper threat rotation with rage management")
    DruidDebug("|cFF32CD32Restoration:|r HoT optimization + emergency healing priorities")
    DruidDebug("|cFFFFD700Research:|r Based on WotLK 3.3.5a guides from Icy Veins, Warcraft Tavern")
    DruidDebug("|cFFDDA0DDFeatures:|r Stealth openers, travel forms, defensive cooldowns")

    if self.RegisterEvent then
    self:RegisterEvent("PLAYER_REGEN_ENABLED", function()
            if self.druidFeralCombatRole then
                self.druidFeralCombatRole = nil
                DruidDebug("Feral combat role unlocked")
            end
        end)
    end

    if self.RegisterEvent then
        self:RegisterEvent("PLAYER_TALENT_UPDATE", function()
            self.druidTalentCache = nil
            self.druidFeralCombatRole = nil
        end)
    end
end

local TARGET_HITS = 36
local TARGET_INTERVAL = 10 / TARGET_HITS

local SwordTiming = {
    HighHits = TARGET_HITS,
    SafeSpacing = 0.296,
    HighSpacing = TARGET_INTERVAL,
    HitFloor = TARGET_INTERVAL,
    GapFloor = TARGET_INTERVAL,
    -- Server confirmation/transit floor, kept separate from local attack cadence.
    ArrivalFloor = 0.2747,
    CooldownCorrection = (0.017999999225139618 / 10) + 0.013412
}

local WeaponSpacing: {[number]: number} = {
    [0.21] = 0.229,
    [0.25] = 0.249,
    [0.35] = 0.345,
    [0.4] = 0.341,
    [0.6] = 0.63
}

local function IsFinite(Value: any): boolean
    return type(Value) == "number" and Value == Value and Value > -math.huge and Value < math.huge
end

function SwordTiming.Calculate(Speed: number, Fury: number, High: boolean, Budget: number, Hits: number?)
    if not IsFinite(Speed) or Speed <= 0 then
        Speed = 0.3
    end
    if not IsFinite(Fury) or Fury <= 0 then
        Fury = 1
    end
    if not IsFinite(Budget) or Budget < 0 then
        Budget = 0
    end

    local Stock: boolean = Speed == 0.3
    local Normal: number = High and SwordTiming.HighSpacing or SwordTiming.SafeSpacing
    local Spacing: number = Stock and Normal or WeaponSpacing[Speed] or Speed + 0.03

    -- Enforce the requested interval consistently (including 35 and 36).
    if IsFinite(Hits) and Hits > 0 then
        Spacing = math.max(Spacing, 10 / math.max(Hits, 1))
    end

    -- Apply the game's request budget and any active speed multiplier before returning.
    Spacing = math.max(Spacing * Fury, Budget)
    local Scale: number = Spacing / (Stock and Normal or SwordTiming.SafeSpacing)
    local Gap: number = (Scale < 1 and SwordTiming.GapFloor or SwordTiming.HitFloor) * Scale
    if Stock and High then
        Gap = math.max(Gap, SwordTiming.GapFloor * Fury, Budget)
    end

    local Cooldown: number = math.max(Speed * Fury - SwordTiming.CooldownCorrection, 0)
    return Spacing, Scale, Gap, Cooldown, Stock
end


-- Compatibility interface used by the supplied BedWars Killaura module.
-- Mode hit counts are the values shown in that module's Hitreg tooltip.
SwordTiming.Modes = {
    Legit = {Hits = 33, Budget = true},
    High = {Hits = 34, Budget = true},
    ["Extra High"] = {Hits = 35, Budget = true},
    Max = {Hits = 36, Budget = true}
}

function SwordTiming.Spacing(Hits: number, Speed: number): number
    local Spacing = SwordTiming.Calculate(Speed, 1, true, 0, Hits)
    return Spacing
end

return SwordTiming

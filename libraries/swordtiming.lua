-- ElevateV4 SwordTiming — stable 36 hitreg, reduced stutter
local SwordTiming = {
	-- 36 hits / 10s = 0.277... ; slight headroom under server floor
	SafeSpacing = 0.285,
	HighSpacing = 10 / 36, -- 0.2777...
	HitFloor = 0.270,
	GapFloor = 0.268,
	ArrivalFloor = 0.265,
	-- less aggressive correction so gaps don't open mid-strafe
	CooldownCorrection = 0.012,
	-- hard caps used by callers that clamp pending waits
	MaxPending = 0.12,
	MinGap = 0.05,
}

local WeaponSpacing: {[number]: number} = {
	[0.21] = 0.225,
	[0.25] = 0.245,
	[0.3] = 0.2778,
	[0.35] = 0.340,
	[0.4] = 0.335,
	[0.6] = 0.62,
}

function SwordTiming.Calculate(Speed: number, Fury: number, High: boolean, Budget: number, Hits: number?)
	Fury = typeof(Fury) == "number" and Fury > 0 and Fury or 1
	Budget = typeof(Budget) == "number" and Budget or 0

	local Stock: boolean = Speed == 0.3 or Speed == nil
	local baseSpeed: number = Stock and 0.3 or Speed

	-- target spacing for requested hit budget (default 36 when High)
	local targetHits: number = Hits
	if not targetHits then
		targetHits = High and 36 or 34
	end
	targetHits = math.clamp(targetHits, 1, 36)

	local Normal: number = High and SwordTiming.HighSpacing or SwordTiming.SafeSpacing
	local Spacing: number = Stock and Normal or (WeaponSpacing[baseSpeed] or (baseSpeed + 0.02))

	-- force spacing to match hit target without overshooting into stutter
	local hitSpacing: number = 10 / targetHits
	Spacing = math.max(Spacing, hitSpacing)
	-- slight shrink when High so we stay at 36 under movement
	if High then
		Spacing = math.min(Spacing, hitSpacing + 0.002)
	end

	Spacing = math.max(Spacing * Fury, Budget, SwordTiming.MinGap)

	local Scale: number = Spacing / (Stock and Normal or SwordTiming.SafeSpacing)
	local Gap: number = (Scale < 1 and SwordTiming.GapFloor or SwordTiming.HitFloor) * Scale
	Gap = math.max(Gap, SwordTiming.MinGap)
	if Stock and High then
		-- don't let gap balloon past high spacing — main stutter source
		Gap = math.min(math.max(Gap, hitSpacing * 0.96), SwordTiming.HighSpacing + 0.004)
	end

	local Cooldown: number = math.max(baseSpeed * Fury - SwordTiming.CooldownCorrection, SwordTiming.MinGap)

	return Spacing, Scale, Gap, Cooldown, Stock
end

function SwordTiming.ClampPending(waitTime: number): number
	return math.min(math.max(waitTime or 0, 0), SwordTiming.MaxPending)
end

return SwordTiming

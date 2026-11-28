-- ElevateV4 SwordTiming — stable 36 hitreg while standing OR strafing
local SwordTiming = {
	SafeSpacing = 0.282,
	HighSpacing = 10 / 36, -- 0.2777... for 36/10s
	HitFloor = 0.268,
	GapFloor = 0.265,
	ArrivalFloor = 0.262,
	CooldownCorrection = 0.011,
	MaxPending = 0.10,
	MinGap = 0.05,
	-- movement compensation: slight tighter spacing so strafe doesn't drop a hit
	MoveSlack = 0.004,
}

local WeaponSpacing: {[number]: number} = {
	[0.21] = 0.222,
	[0.25] = 0.242,
	[0.3] = 0.2778,
	[0.35] = 0.338,
	[0.4] = 0.333,
	[0.6] = 0.615,
}

function SwordTiming.Calculate(Speed: number, Fury: number, High: boolean, Budget: number, Hits: number?, Moving: boolean?)
	Fury = (type(Fury) == "number" and Fury > 0) and Fury or 1
	Budget = (type(Budget) == "number") and Budget or 0

	local Stock: boolean = Speed == 0.3 or Speed == nil
	local baseSpeed: number = Stock and 0.3 or Speed

	local targetHits: number = Hits
	if not targetHits then
		targetHits = High and 36 or 34
	end
	targetHits = math.clamp(targetHits, 1, 36)

	local Normal: number = High and SwordTiming.HighSpacing or SwordTiming.SafeSpacing
	local Spacing: number = Stock and Normal or (WeaponSpacing[baseSpeed] or (baseSpeed + 0.018))

	local hitSpacing: number = 10 / targetHits
	Spacing = math.max(Spacing, hitSpacing)

	if High then
		-- keep at 36; if moving, shave a little so packets still land
		local tight = hitSpacing
		if Moving then
			tight = math.max(hitSpacing - SwordTiming.MoveSlack, SwordTiming.MinGap)
		end
		Spacing = math.min(Spacing, tight + 0.0015)
	end

	Spacing = math.max(Spacing * Fury, Budget, SwordTiming.MinGap)

	local Scale: number = Spacing / (Stock and Normal or SwordTiming.SafeSpacing)
	local Gap: number = (Scale < 1 and SwordTiming.GapFloor or SwordTiming.HitFloor) * Scale
	Gap = math.max(Gap, SwordTiming.MinGap)

	if Stock and High then
		local cap = SwordTiming.HighSpacing + (Moving and 0 or 0.003)
		Gap = math.min(math.max(Gap, hitSpacing * (Moving and 0.94 or 0.97)), cap)
	end

	local Cooldown: number = math.max(baseSpeed * Fury - SwordTiming.CooldownCorrection, SwordTiming.MinGap)
	return Spacing, Scale, Gap, Cooldown, Stock
end

function SwordTiming.ClampPending(waitTime: number): number
	return math.min(math.max(waitTime or 0, 0), SwordTiming.MaxPending)
end

-- helpers for callers that can detect strafe/air
function SwordTiming.IsMoving(root: BasePart?, threshold: number?): boolean
	if not root then return false end
	local t = threshold or 2
	local v = root.AssemblyLinearVelocity
	return (v.X * v.X + v.Z * v.Z) > (t * t)
end

return SwordTiming

-- ElevateV4 standalone build: the former Elevate login endpoint is not used.
local vape = shared.vape
if vape then
    vape:CreateNotification("Elevate", "GitHub build loaded", 5, "info")
end
return true

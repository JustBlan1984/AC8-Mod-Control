-- Resolve typed aircraft each tick. Never read aircraft properties from a menu pawn.
return function()
    local result, identity
    for _, pawn in ipairs(FindAllOf('LivePlayerPlane') or {}) do
        if pawn:IsValid() and pawn:IsPlayerControlled() then
            local pc=pawn.Controller
            if pc and pc:IsValid() then
                local current=pc.Pawn
                local camera=pc.PlayerCameraManager
                if current and current:IsValid() and current:GetAddress()==pawn:GetAddress()
                    and camera and camera:IsValid() then
                    if result then return nil end -- ambiguous during travel: wait
                    result=pc
                    identity=tostring(pc:GetAddress())..':'..tostring(pawn:GetAddress())..':'..tostring(camera:GetAddress())
                end
            end
        end
    end
    return result,identity
end

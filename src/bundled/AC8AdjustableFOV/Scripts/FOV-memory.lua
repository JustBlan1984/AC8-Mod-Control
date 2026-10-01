-- CriminalGamer84 Mods: per-view FOV memory. See LICENSE-PERSONAL-USE.txt.
return function(options)
    local memory = {}
    local active, owner, ownsLock = nil, nil, false
    local views = {"CockpitCamera", "FirstPersonCamera", "ThirdPersonCamera"}
    local function valid(value)
        return type(value)=="number" and value==value and value>=50 and value<=150
    end
    local input = io.open(options.path, "r")
    if input then
        for line in input:lines() do
            local key,value=line:match("^([%w_]+)=([%d%.]+)$")
            value=tonumber(value)
            for _,name in ipairs(views) do if key==name and valid(value) then memory[key]=value end end
        end
        input:close()
    end
    local function save()
        local temporary=options.path..".tmp"
        local file,err=io.open(temporary,"w")
        if not file then options.log("Cannot save FOV memory: "..tostring(err)); return end
        local lines={"# Per-view FOV memory. Missing entry means game default.\n"}
        for _,name in ipairs(views) do
            if memory[name] then lines[#lines+1]=string.format("%s=%.4f\n",name,memory[name]) end
        end
        local written,writeError=file:write(table.concat(lines))
        local closed,closeError=file:close()
        if not written or not closed then options.log("Cannot save FOV memory: "..tostring(writeError or closeError)); return end
        -- Windows rename cannot replace a file. Retain one previous copy.
        os.remove(options.path..".bak")
        local existing=io.open(options.path,"r")
        if existing then
            existing:close()
            local moved,moveError=os.rename(options.path,options.path..".bak")
            if not moved then options.log("Cannot rotate FOV memory: "..tostring(moveError)); return end
        end
        local renamed,renameError=os.rename(temporary,options.path)
        if not renamed then
            os.rename(options.path..".bak",options.path)
            options.log("Cannot replace FOV memory: "..tostring(renameError))
        end
    end
    local function identify(pc)
        local pawn=pc.Pawn
        if not pawn or not pawn:IsValid() then return nil end
        if pawn.bEnableCameraInput ~= true or pawn.bIsLocalViewTarget ~= true then return nil end
        local target=pc:GetViewTarget()
        if not target or not target:IsValid() or target:GetAddress()~=pawn:GetAddress() then return nil end
        local impact=pawn.ImpactCamera
        if impact and impact:IsValid() and impact:IsActive() then return nil end
        local found=nil
        for _,name in ipairs(views) do
            local camera=pawn[name]
            if camera and camera:IsValid() and camera:IsActive() then
                if found then return nil end
                found=name
            end
        end
        return found
    end
    local function sync(pc)
        local manager=pc.PlayerCameraManager
        if not manager or not manager:IsValid() then return nil end
        local identity=tostring(pc:GetAddress())..":"..tostring(manager:GetAddress())
        if owner~=identity then active=nil; ownsLock=false; owner=identity end
        local view=identify(pc)
        if view~=active then
            if view then
                pc:FOV(memory[view] or 0)
                ownsLock=memory[view]~=nil
                options.log("View "..view..": "..(memory[view] and string.format("restored %.2f",memory[view]) or "game default"))
            elseif ownsLock then pc:FOV(0); ownsLock=false end
            active=view
        end
        return view,manager
    end
    return {
        snapshot=function()
            local result={active=active}
            for _,name in ipairs(views) do result[name]=memory[name] end
            return result
        end,
        set=function(pc,name,value)
            local known=false
            for _,key in ipairs(views) do if key==name then known=true end end
            if not known or (value~=0 and not valid(value)) then return false end
            memory[name]=value~=0 and value or nil
            save()
            if active==name then
                if pc then pc:FOV(value) end
                ownsLock=value~=0
            end
            options.log("HUD "..name..": "..(value==0 and "game default" or string.format("saved %.2f",value)))
            return true
        end,
        tick=function(pc) sync(pc) end,
        adjust=function(pc,direction)
            local view,manager=sync(pc)
            if not view then options.log("No single active flight view; FOV unchanged."); return end
            if direction==0 then
                pc:FOV(0); memory[view]=nil; ownsLock=false; save()
                options.log(view..": reset to game default; other views retained.")
                return
            end
            local current=memory[view] or manager:GetFOVAngle()
            if type(current)~="number" or current~=current or current<=0 or current==math.huge then return end
            local desired=math.max(50,math.min(150,current+direction*5))
            pc:FOV(desired); memory[view]=desired; ownsLock=true; save()
            options.log(view..": saved "..string.format("%.2f",desired))
        end,
    }
end

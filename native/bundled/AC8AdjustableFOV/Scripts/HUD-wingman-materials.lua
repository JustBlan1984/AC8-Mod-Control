-- TEST 03: isolate the visible JOKER labels/box from native color writes.
-- Original materials remain owned by the game and are restored on reset.
local M=_G.CG84WingmanMaterials or {actors={},entries={},countdown=0}
_G.CG84WingmanMaterials=M
local function valid(o)return o and o:IsValid()end
local function restore(e)
 if valid(e.component) and valid(e.original)then
  if e.text then e.component:SetTextMaterial(e.original)
  else e.component:SetMaterial(0,e.original)end
 end
end
function M.tick(enabled,color,boxScale,showBox,choice)
 if not FindAllOf then return end
 boxScale=math.max(0.5,math.min(1.5,tonumber(boxScale) or 1))
 M.boxSizes=M.boxSizes or {}
 M.countdown=M.countdown-1
 if (enabled or boxScale~=1 or showBox==false) and M.countdown<=0 then
  M.countdown=20;M.actors=FindAllOf('ChronicleTargetContainerActorBP_C')or{}
 end
 local active={}
 M.names=M.names or {}
 local activeSizes={}
 for _,actor in ipairs(M.actors)do
  if valid(actor)then
   local ok,err=pcall(function()
    local label=actor.ObjectTypeText
    if not valid(label)then return end
    -- Containers are pooled: callsign text alone can be stale on enemy actors.
    local wingman=label.Text:ToString():match('^JOKER [234]$')~=nil
    if wingman and valid(actor.ObjectCallsignText)then
     M.names[actor.ObjectCallsignText.Text:ToString()]=true
    end
    local actorId=actor:GetAddress()
    local size=M.boxSizes[actorId]
    if wingman and boxScale~=1 then
     if not size then
      local original=actor.ContainerBoxImageSize
      if type(original)=='number' and original>0 then
       size={actor=actor,original=original};M.boxSizes[actorId]=size
      end
     end
     if size then
      -- Native drawing keeps its target-centered position; alter only box size.
      actor.ContainerBoxImageSize=size.original*boxScale
      activeSizes[actorId]=true
     end
    end
    for _,key in ipairs({'ObjectTypeText','ObjectCallsignText','ContainerBox'})do
     local enabled,color=enabled,color
     if choice then enabled,color=choice(({ObjectTypeText='wingcallsigns',ObjectCallsignText='wingnames',ContainerBox='wingboxes'})[key])end
     local component=actor[key]
     local original=actor[key..'MaterialInst']
     if valid(component) and valid(original)then
      local id=component:GetAddress();local e=M.entries[id]
      if wingman and (enabled or (key=='ContainerBox' and showBox==false))then
       local base=original:K2_GetVectorParameterValue(FName('Color'))
       if base.G>0.25 and base.G>base.R*3 and base.G>base.B*3 then
        if not e then
         local parent=original.Parent
         if not valid(parent)then return end
         local replacement=component:CreateDynamicMaterialInstance(0,parent,FName('CG84WingmanTint'))
         if not valid(replacement) or replacement:GetAddress()==original:GetAddress()then return end
         e={component=component,original=original,material=replacement,text=key~='ContainerBox'}
         M.entries[id]=e
         print('[AC8FOV] TEST 03 material: '..key..' '..label.Text:ToString()..'\n')
        end
        if valid(e.material)then
         e.material:CopyInterpParameters(original)
         local tint=enabled and color or base
         local alpha=(key=='ContainerBox' and showBox==false) and 0 or base.A
         e.material:SetVectorParameterValue(FName('Color'),{R=tint.R,G=tint.G,B=tint.B,A=alpha})
         if e.text then component:SetTextMaterial(e.material)else component:SetMaterial(0,e.material)end
         active[id]=true
        end
       end
      end
     end
    end
   end)
   if not ok and M.lastError~=tostring(err)then M.lastError=tostring(err);print('[AC8FOV] Wingman material: '..M.lastError..'\n')end
  end
 end
 for id,e in pairs(M.entries)do
  if not active[id]then pcall(restore,e);M.entries[id]=nil end
 end
 for id,e in pairs(M.boxSizes)do
  if not activeSizes[id]then
   if valid(e.actor)then e.actor.ContainerBoxImageSize=e.original end
   M.boxSizes[id]=nil
  end
 end
end
return M

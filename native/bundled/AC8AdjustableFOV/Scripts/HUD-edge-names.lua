-- Experimental display copy. Native text/slot ownership stays unchanged.
local M=_G.CG84EdgeNames or {entries={}}
_G.CG84EdgeNames=M
local function valid(o)return o and o:IsValid()end
local function release(e)
 if valid(e.source)then e.source:SetRenderOpacity(e.opacity)end
 if valid(e.label)then e.label:RemoveFromParent()end
end
function M.sync(e,color)
 local source=e.source
 if not valid(source) or not valid(e.label)then return end
   local label=e.label;local slot=source.Slot;local target=label.Slot
   target:SetAnchors(slot:GetAnchors());target:SetAlignment(slot:GetAlignment())
   target:SetPosition(slot:GetPosition());target:SetSize(slot:GetSize());target:SetAutoSize(slot:GetAutoSize())
   label:SetRenderTransform(source.RenderTransform);label:SetRenderTransformPivot(source.RenderTransformPivot)
   label:SetText(source:GetText())
   local c=source.ColorAndOpacity.SpecifiedColor
   label:SetColorAndOpacity({SpecifiedColor={R=color.R,G=color.G,B=color.B,A=c.A},ColorUseRule=0})
   local visibility=source:GetVisibility()
   label:SetVisibility((visibility==1 or visibility==2) and visibility or 4)
   label:SetRenderOpacity(e.opacity)
   source:SetRenderOpacity(0)
end
local function tick(hud,enabled,color,names)
 M.color=color
 if not StaticConstructObject then return end
 if M.failed then enabled=false end
 local canvas=hud.LowestPriorityCanvas
 if not valid(canvas)then
  for _,e in pairs(M.entries)do pcall(release,e)end
  M.entries={};return
 end
 local candidates={}
 if enabled then
  local function scan(o,depth)
   if not valid(o) or depth>3 then return end
   local name=o:GetFullName()
   if name:match('^TextBlock ') and name:find('DynamicDrawCanvas.TextBlock',1,true)then
    local text=o:GetText():ToString()
    if names[text]then candidates[o:GetAddress()]=o end
   else
    pcall(function()for i=0,o:GetChildrenCount()-1 do scan(o:GetChildAt(i),depth+1)end end)
   end
  end
  scan(canvas,0)
 end
 for key,source in pairs(candidates)do
  local e=M.entries[key]
  local ok,err=pcall(function()
   if not e then
    local parent=source:GetParent()
    if not valid(parent)then return end
    local label=StaticConstructObject(StaticFindObject('/Script/UMG.TextBlock'),hud.HudWidget.WidgetTree)
    if not valid(label)then return end
    e={source=source,label=label,opacity=source.RenderOpacity};M.entries[key]=e
    parent:AddChildToCanvas(label)
    label:SetFont(source.Font)
    label:SetJustification(source.Justification)
    label:SetShadowOffset(source.ShadowOffset)
    label:SetShadowColorAndOpacity(source.ShadowColorAndOpacity)
    print('[AC8FOV] Edge name display copy: '..source:GetText():ToString()..'\n')
   end
   M.sync(e,color)
  end)
  if not ok then
   M.failed=true
   if e then pcall(release,e);M.entries[key]=nil end
   if M.lastError~=tostring(err)then M.lastError=tostring(err);print('[AC8FOV] Edge name test: '..M.lastError..'\n')end
  end
 end
 for key,e in pairs(M.entries)do
  if not candidates[key]then pcall(release,e);M.entries[key]=nil end
 end
end
-- Native calls can re-enter ProcessEvent callbacks. Share one guard between
-- discovery/cleanup and frame movement; never iterate a live, changing table.
local function guarded(fn,...)
 if M.busy then return end
 M.busy=true
 local ok,err=pcall(fn,...)
 M.busy=false
 if not ok then
  if M.lastError~=tostring(err)then
   M.lastError=tostring(err);print('[AC8FOV] Edge update: '..M.lastError..'\n')
  end
 end
end
function M.tick(...)return guarded(tick,...)end
function M.frame()
 return guarded(function()
  local snapshot={}
  for key,e in pairs(M.entries)do snapshot[#snapshot+1]={key=key,entry=e}end
  for _,item in ipairs(snapshot)do
   local key,e=item.key,item.entry
   if M.entries[key]==e then
    local ok,err=pcall(function()
     if not valid(e.source) or not valid(e.label)then
      M.entries[key]=nil;pcall(release,e);return
     end
     if M.color then M.sync(e,M.color)end
    end)
    if not ok then
     M.entries[key]=nil;pcall(release,e)
     print('[AC8FOV] Edge frame update: '..tostring(err)..'\n')
    end
   end
  end
 end)
end
-- Driven by main.lua's single frame callback. Reloading this module never
-- registers another callback or mixes ProcessEvent and EngineTick execution.
return M

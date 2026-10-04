local directory=assert(debug.getinfo(1,'S').source:match('^@(.+[\\/])'))
local M=_G.CG84HUDColors or {h=0.33,s=1,v=1,enabled=false,entries={},revision=0}
_G.CG84HUDColors=M
-- Retire the periodic wingman override; native drawing rewrites these colors.
for key,e in pairs(M.entries)do
 pcall(function()
  if e.o and e.o:IsValid()then
   local name=e.o:GetFullName()
   if name:find('WBP_HUD_Locator_Wingman_000',1,true) or name:find('DynamicDrawCanvas.TextBlock',1,true)then
    e.o:SetColorAndOpacity(e.slate and {SpecifiedColor=e.original,ColorUseRule=0} or e.original)
    M.entries[key]=nil
   end
  end
 end)
end
-- Native reflection diagnostics disabled after an access violation during inspection.
local palette=assert(loadfile(directory..'HUD-palette.lua'))()
local wingMaterials=assert(loadfile(directory..'HUD-wingman-materials.lua'))()
local edgeNames=assert(loadfile(directory..'HUD-edge-names.lua'))()
local function valid(o)return o and o:IsValid()end
function M.rgb(h,s,v)
 local k=h*6;local i=math.floor(k);local f=k-i;local p=v*(1-s);local q=v*(1-s*f);local t=v*(1-s*(1-f))
 local a={{v,t,p},{q,v,p},{p,v,t},{p,q,v},{t,p,v},{v,p,q}};a=a[i%6+1]
 return {R=a[1],G=a[2],B=a[3],A=1}
end
local profiles=assert(loadfile(directory..'HUD-color-profiles.lua'))()
if not M.profiles then
 if not M.loaded then
  local f=io.open(directory..'HUD-colors.ini','r')
  if f then local e,h,s,v=f:read('*a'):match('^(%d) ([%d.]+) ([%d.]+) ([%d.]+)');f:close()
   if h then M.enabled=e=='1';M.h=tonumber(h);M.s=tonumber(s);M.v=tonumber(v)end
  end
 end
 M.profiles=profiles.new({enabled=M.enabled,h=M.h,s=M.s,v=M.v})
 local f=io.open(directory..'HUD-color-profiles.ini','r')
 if f then M.profiles:decode(f:read('*a'));f:close()end
 M.loaded=true
end
M.selected=M.selected or 'all'
M.groups={
 {'all','ALL HUD'},{'score','SCORE / TARGET'},{'timer','TIMER'},
 {'center','CENTER HUD'},{'radar','RADAR GRID'},{'weapons','WEAPON COUNTS'},
 {'aircraft','AIRCRAFT ICON'},{'radio','PORTRAIT BORDER'},{'commands','D-PAD'},
 {'wingarrows','WINGMAN ARROWS'},{'wingedgenames','EDGE NAMES'},
 {'wingboxes','WINGMAN BOXES'},{'wingcallsigns','CALLSIGNS'},{'wingnames','WINGMAN NAMES'},
}
function M.choice(key)
 local c=M.profiles:get(key);return c.enabled,M.rgb(c.h,c.s,c.v)
end
function M.choose(key)
 M.selected=key;local c=M.profiles:get(key);M.h=c.h;M.s=c.s;M.v=c.v
end
function M.active()
 if M.profiles.base.enabled then return true end
 for _,c in pairs(M.profiles.overrides)do if c.enabled then return true end end
 return false
end
function M.save()
 local f=io.open(directory..'HUD-color-profiles.ini','w');if not f then return false end
 f:write(M.profiles:encode());f:close();return true
end
function M.select(h,s,v)
 M.profiles:set(M.selected,h,s,v);M.choose(M.selected)
 M.enabled=M.active();M.revision=M.revision+1;M.countdown=0
end
function M.setRGB(r,g,b)
 for _,v in ipairs({r,g,b})do
  if type(v)~='number' or v~=v or v<0 or v>255 or v%1~=0 then return false end
 end
 if r==nil or g==nil or b==nil then return false end
 r=r/255;g=g/255;b=b/255
 local hi=math.max(r,g,b);local lo=math.min(r,g,b);local d=hi-lo
 local h=M.h
 if d>0 then
  if hi==r then h=((g-b)/d)%6 elseif hi==g then h=(b-r)/d+2 else h=(r-g)/d+4 end
  h=h/6
 end
 M.select(h,hi==0 and 0 or d/hi,hi);return true
end
function M.reset(key)
 M.profiles:reset(key or 'all');M.choose(M.selected)
 M.enabled=M.active();M.revision=M.revision+1;return M.save()
end
function M.inherit()
 M.profiles:inherit(M.selected);M.choose(M.selected);M.enabled=M.active();return M.save()
end
M.choose(M.selected);M.enabled=M.active()
local function green(c)return c.G>0.25 and c.G>c.R*3 and c.G>c.B*3 end
local function same(a,b)return b and math.abs(a.R-b.R)<0.002 and math.abs(a.G-b.G)<0.002 and math.abs(a.B-b.B)<0.002 end
M.glowEntries=M.glowEntries or {}
M.countdown=0
-- Retire the diagnostic hooks: the game's native HUD path does not invoke them.
if UnregisterHook then
 if M.drawHook then
  local ok=pcall(UnregisterHook,'/Script/Engine.HUD:ReceiveDrawHUD',M.drawHook[1],M.drawHook[2])
  if ok then M.drawHook=nil end
 end
 for path,ids in pairs(M.colorHooks or {})do
  if pcall(UnregisterHook,path,ids[1],ids[2])then M.colorHooks[path]=nil end
 end
end
function M.tick(pc)
 local hud=pc:GetHUD();if not valid(hud)then return end
 local id=hud:GetAddress()
 if M.owner~=id then wingMaterials.names={};M.owner=id;M.entries={};M.glowEntries={};M.countdown=0 end
 M.countdown=(M.countdown or 0)-1
 if M.enabled and M.countdown<=0 then
  M.countdown=100;local seen={};local count=0
  local function walk(o,depth,group)
   if not valid(o) or depth>18 or count>4000 or seen[o:GetAddress()]then return end
   if o:GetFullName():find('TimerAndGauge',1,true)then return end
   seen[o:GetAddress()]=true;count=count+1
   pcall(function()
    local name=o:GetFullName();local slate=name:match('^TextBlock ') or name:match('^LiveLocalizeTextBlock ')
    local progress=name:match('^ProgressBar ')
    if name:find('TimerAndGauge',1,true) and slate then return end
    if not (slate or progress or name:match('^Image ') or name:match('^WBP_')) then return end
    local c=progress and o.FillColorAndOpacity or (slate and o.ColorAndOpacity.SpecifiedColor or o.ColorAndOpacity)
    local key=o:GetAddress()
    if not M.entries[key] and green(c) then M.entries[key]={o=o,slate=slate,progress=progress,group=group,timer=name:find('RemainingTimeText',1,true),original={R=c.R,G=c.G,B=c.B,A=c.A}} end
    if M.entries[key]then M.entries[key].group=group;M.entries[key].timer=name:find('RemainingTimeText',1,true) end
    if name:match('^Image ') and (M.entries[key] or name:find('WBP_HUD_Command_Wingman_000',1,true)) and not M.glowEntries[key] then
     local g=o.GlowColor.SpecifiedColor
     M.glowEntries[key]={o=o,global=o.bUseGlobalGlowColor,original={SpecifiedColor={R=g.R,G=g.G,B=g.B,A=g.A},ColorUseRule=o.GlowColor.ColorUseRule}}
    end
   end)
   pcall(function()walk(o.WidgetTree.RootWidget,depth+1,group)end)
   pcall(function()for i=0,o:GetChildrenCount()-1 do walk(o:GetChildAt(i),depth+1,group)end end)
  end
  -- Exclude dynamic enemy/friendly markers and warning groups from the prototype.
  local targets=_G.CG84HUDLayout and _G.CG84HUDLayout.targets or {}
  for _,key in ipairs({'center','weapons','radar','radio','wingman','quickCommand'})do local t=targets[key];if t then walk(t.widget,0,(key=='wingman' or key=='quickCommand') and 'commands' or key)end end
  pcall(function()walk(hud.ForEachWidget.InfoWidget,0,'score')end)
 end
 local _,color=M.choice('all')
 -- TEST 01: isolate the native timer update beneath a parent color transform.
 pcall(function()
  local timer=hud.ForEachWidget.InfoWidget.TimerAndGauge
  if valid(timer)then
   if M.timerProbeOwner~=timer:GetAddress()then
    M.timerProbeOwner=timer:GetAddress()
    M.timerProbeOriginal={R=timer.ColorAndOpacity.R,G=timer.ColorAndOpacity.G,B=timer.ColorAndOpacity.B,A=timer.ColorAndOpacity.A}
    for key,e in pairs(M.entries)do
     if valid(e.o) and e.o:GetFullName():find('TimerAndGauge',1,true) and e.slate then
      e.o:SetColorAndOpacity({SpecifiedColor=e.original,ColorUseRule=0});M.entries[key]=nil
     end
    end
    print('[AC8FOV] TEST 01: timer parent tint active.\n')
   end
   local enabled,color=M.choice('timer')
   local original=M.timerProbeOriginal
   timer:SetColorAndOpacity(enabled and {R=color.R/0.08,G=color.G,B=color.B/0.05,A=original.A} or original)
  end
 end)
 -- TEST 02: compensate the native wingman tint on its child graphic.
 M.wingGraphics=M.wingGraphics or {}
 pcall(function()
  local canvas=hud.LowestPriorityCanvas
  local function inspect(panel,depth)
   if not valid(panel) or depth>3 then return end
   local name=panel:GetFullName()
   if name:match('^WBP_HUD_Locator_Wingman_000_C ')then
    local graphic=panel.Locator_Wingman
    if valid(graphic)then
     local key=graphic:GetAddress();local e=M.wingGraphics[key]
     if not e then
      local c=graphic.ColorAndOpacity
      e={o=graphic,original={R=c.R,G=c.G,B=c.B,A=c.A}};M.wingGraphics[key]=e
     end
     local enabled,color=M.choice('wingarrows')
     local base=panel.ColorAndOpacity
     local c=e.original
     if enabled and green(base) and base.R>0.001 and base.B>0.001 then
      c={R=color.R/base.R,G=color.G/base.G,B=color.B/base.B,A=e.original.A}
     end
     graphic:SetColorAndOpacity(c)
    end
    return
   end
   pcall(function()for i=0,panel:GetChildrenCount()-1 do inspect(panel:GetChildAt(i),depth+1)end end)
  end
  inspect(canvas,0)
 end)
 local wingScale=_G.CG84HUDLayout and _G.CG84HUDLayout.scales and _G.CG84HUDLayout.scales.wingbox or 1
 local showBox=not (_G.CG84HUDLayout and _G.CG84HUDLayout.showWingmanBox==false)
 local wingOK,wingError=pcall(wingMaterials.tick,M.enabled,color,wingScale,showBox,M.choice)
 if not wingOK and M.wingError~=tostring(wingError)then M.wingError=tostring(wingError);print('[AC8FOV] Wingman material: '..M.wingError)end
 local edgeEnabled,edgeColor=M.choice('wingedgenames')
 local edgeOK,edgeError=pcall(edgeNames.tick,hud,edgeEnabled,edgeColor,wingMaterials.names or {})
 if not edgeOK and M.edgeError~=tostring(edgeError)then M.edgeError=tostring(edgeError);print('[AC8FOV] Edge names: '..M.edgeError)end
 local paletteOK,paletteError=pcall(palette.tick,M.enabled,color,M.choice)
 if not paletteOK and M.paletteError~=tostring(paletteError) then M.paletteError=tostring(paletteError);print('[AC8FOV] Palette error: '..M.paletteError..'\n')end
 for key,e in pairs(M.glowEntries)do
  if not valid(e.o)then M.glowEntries[key]=nil else
   local glowOK,glowError=pcall(function()
    if e.changed then
     e.o:SetGlowColor(e.original);e.o:SetUseGlobalGlowColor(e.global);e.changed=false
    end
   end)
   if not glowOK and M.glowError~=tostring(glowError)then M.glowError=tostring(glowError);print('[AC8FOV] HUD glow: '..M.glowError..'\n')end
  end
 end
 for key,e in pairs(M.entries) do
  if not valid(e.o) then M.entries[key]=nil else
   pcall(function()
    local enabled,color=M.choice(e.group or 'all')
    local current=e.progress and e.o.FillColorAndOpacity or (e.slate and e.o.ColorAndOpacity.SpecifiedColor or e.o.ColorAndOpacity)
    -- Respect a new warning/status color set by the game.
    if green(current) or same(current,e.last) then
     local c=enabled and {R=color.R,G=color.G,B=color.B,A=current.A} or {R=e.original.R,G=e.original.G,B=e.original.B,A=current.A}
     if not same(current,c) or (enabled and e.timer) then
      if e.progress then e.o:SetFillColorAndOpacity(c)else e.o:SetColorAndOpacity(e.slate and {SpecifiedColor=c,ColorUseRule=0} or c)end
     end
     e.last=enabled and c or nil
    end
   end)
  end
 end
 if M.enabled and not M.glowReported and next(M.glowEntries) then
  M.glowReported=true;local n=0;for _ in pairs(M.glowEntries)do n=n+1 end
  print('[AC8FOV] HUD local glow targets: '..n..'\n')
 end
end
return M



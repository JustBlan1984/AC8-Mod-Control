-- Transform identified panels only; center instruments use a screen-center pivot.
local directory=assert(debug.getinfo(1,'S').source:match('^@(.+[\\/])'))
local M=_G.CG84HUDLayout or {groups={'score','radar','weapons','radio'},values={},targets={},owner=nil}
local path=directory..'HUD-layout.ini'
local colors=assert(loadfile(directory..'HUD-colors.lua'))()
M.menu=M.menu or {x=0,y=0}
-- Reapply corrected pivot calculations when opening the live overlay.
if M.targets.center then M.targets.center.lastScale=nil end
M.scales={score=1,radar=1,weapons=1,radio=1,center=1,wingbox=1}
M.showWingmanBox=true
local function valid(o) return o and o:IsValid() end
local function bounded(n,limit)
 n=tonumber(n) or 0
 if n~=n then return 0 end
 return math.max(-limit,math.min(limit,n))
end
for _,key in ipairs(M.groups) do M.values[key]={x=0,y=0} end
local f=io.open(path,'r')
if f then
 for line in f:lines() do
  if line=='showWingmanBox=0'then M.showWingmanBox=false end
  local key,x,y=line:match('^(%a+)=([%d%.%-]+),([%d%.%-]+)$')
  if M.values[key] then M.values[key]={x=bounded(x,1000),y=bounded(y,400)} end
  local group,scale=line:match('^(%a+)Scale=([%d%.%-]+)$')
  if M.scales[group] then M.scales[group]=math.max(0.5,math.min(1.5,tonumber(scale) or 1)) end
  if key=='overlay' then M.menu={x=bounded(x,8000),y=bounded(y,4000)} end
 end
 f:close()
end
function M.save()
 local out,err=io.open(path..'.tmp','w');if not out then return false,err end
 for _,key in ipairs(M.groups) do
  local v=M.values[key];out:write(string.format('%s=%.0f,%.0f\n%sScale=%.2f\n',key,v.x,v.y,key,M.scales[key]))
 end
 out:write(string.format('centerScale=%.2f\n',M.scales.center))
 out:write(string.format('wingboxScale=%.2f\n',M.scales.wingbox))
 out:write('showWingmanBox='..(M.showWingmanBox and '1' or '0')..'\n')
 out:write(string.format('overlay=%.0f,%.0f\n',M.menu.x,M.menu.y))
 local ok,e=out:close();if not ok then return false,e end
 os.remove(path..'.bak')
 local old=io.open(path,'r');if old then old:close();local moved,msg=os.rename(path,path..'.bak');if not moved then return false,msg end end
 local moved,msg=os.rename(path..'.tmp',path)
 if not moved then os.rename(path..'.bak',path) end
 return moved,msg
end
function M.set(key,x,y)
 assert(M.values[key],'Unknown HUD group')
 M.values[key]={x=bounded(x,1000),y=bounded(y,400)}
 return M.save()
end
function M.setScale(key,value,persist)
 assert(M.scales[key],'Unknown HUD group')
 value=tonumber(value) or 1;if value~=value then value=1 end
 M.scales[key]=math.max(0.5,math.min(1.5,math.floor(value*100+0.5)/100))
 if persist~=false then return M.save() end
 return true
end
function M.resetSession() M.targets={};M.owner=nil end
local function find(root,name,depth)
 if not valid(root) or depth>5 then return nil end
 if root:GetFullName():match('%.([^%.]+)$')==name then return root end
 local result
 pcall(function()
  for i=0,root:GetChildrenCount()-1 do
   result=find(root:GetChildAt(i),name,depth+1);if result then break end
  end
 end)
 return result
end
function M.tick(pc)
 local hud=pc:GetHUD();if not valid(hud) or not valid(hud.HudWidget) then return end
 local identity=tostring(hud:GetAddress())..':'..tostring(hud.HudWidget:GetAddress())
 if M.owner~=identity then M.targets={};M.owner=identity end
 -- The persistent flight instruments are separate from world-projected markers.
 local center=M.targets.center
 if not center or not valid(center.widget) then
  local widget=find(hud.HudWidget.WidgetTree.RootWidget,'WBP_ChroniclePersistent',0)
  if valid(widget) then
   local transform=widget.RenderTransform
   local pv=widget.RenderTransformPivot
   center={widget=widget,x=transform.Translation.X,y=transform.Translation.Y,
    sx=transform.Scale.X,sy=transform.Scale.Y,px=pv.X,py=pv.Y}
   M.targets.center=center
  end
 end
 if center and center.lastScale~=M.scales.center then
  local widget=center.widget
  local slot=widget.Slot
  local anchors=slot:GetAnchors();local align=slot:GetAlignment();local offsets=slot:GetOffsets()
  -- Canvas slot geometry in the captured 3840x2160 design canvas.
  local w=anchors.Maximum.X~=anchors.Minimum.X and 3840*(anchors.Maximum.X-anchors.Minimum.X)-offsets.Left-offsets.Right or offsets.Right
  local h=anchors.Maximum.Y~=anchors.Minimum.Y and 2160*(anchors.Maximum.Y-anchors.Minimum.Y)-offsets.Top-offsets.Bottom or offsets.Bottom
  local x=3840*anchors.Minimum.X+offsets.Left-(anchors.Maximum.X==anchors.Minimum.X and w*align.X or 0)
  local y=2160*anchors.Minimum.Y+offsets.Top-(anchors.Maximum.Y==anchors.Minimum.Y and h*align.Y or 0)
  local scale=M.scales.center
  local pivotX=x+w*center.px+center.x
  local pivotY=y+h*center.py+center.y
  widget:SetRenderScale({X=center.sx*scale,Y=center.sy*scale})
  widget:SetRenderTranslation({X=center.x+(scale-1)*(pivotX-1920),Y=center.y+(scale-1)*(pivotY-1080)})
  widget:InvalidateLayoutAndVolatility()
  center.lastScale=scale
 end
 local candidates={}
 pcall(function()
  local info=hud.ForEachWidget.InfoWidget
  pcall(function() candidates.score=info.VerticalBox_39 end)
  if not valid(candidates.score) then candidates.score=find(info.WidgetTree.RootWidget,'VerticalBox_39',0) end
  -- Migrate a live session from the placeholder to the visible content box.
  local old=M.targets.score
  if valid(candidates.score) and old and old.address~=candidates.score:GetAddress() and valid(old.widget) then
   old.widget:SetRenderScale({X=old.scaleX or 1,Y=old.scaleY or 1})
   old.widget:SetRenderTranslation({X=old.x,Y=old.y})
   old.widget:InvalidateLayoutAndVolatility()
   M.targets.score=nil
  end
 end)
 pcall(function() candidates.radar=hud.MainMiniMapLayerWidget:GetParent() end)
 pcall(function() candidates.radio=hud.HUDMessageWidget.CanvasPanel_ComPortrait end)
 -- The expanded order selector lives outside the main HUD, under subtitles.
 pcall(function() candidates.quickCommand=hud.SubtitleWidget.WingmanCommand end)
 if M.targets.wingman and valid(M.targets.wingman.widget) then candidates.wingman=M.targets.wingman.widget
 else pcall(function() candidates.wingman=find(hud.HudWidget.WidgetTree.RootWidget,'WBP_HUD_Command_Wingman_000',0) end) end
 if M.targets.weapons and valid(M.targets.weapons.widget) then candidates.weapons=M.targets.weapons.widget
 else pcall(function() candidates.weapons=find(hud.HudWidget.WidgetTree.RootWidget,'WBP_PlayerStateWidget_1',0) end) end
 for _,key in ipairs({'score','radar','weapons','radio','wingman','quickCommand'}) do
  local widget=candidates[key]
  if valid(widget) then
   local t=M.targets[key]
   if not t or t.address~=widget:GetAddress() then
    local v=widget.RenderTransform.Translation
    t={widget=widget,address=widget:GetAddress(),x=v.X,y=v.Y};M.targets[key]=t
   end
   local group=(key=='wingman' or key=='quickCommand') and 'radar' or key
   local offset=M.values[group]
   if not t.scaleX then
    local scale=widget.RenderTransform.Scale
    t.scaleX=scale.X;t.scaleY=scale.Y
   end
   -- Every independent panel scales about its own center. Linked command
   -- widgets keep their stock pivots and use the radar-center correction below.
   if key~='wingman' and key~='quickCommand' then
    local pv=widget.RenderTransformPivot
    if pv.X~=0.5 or pv.Y~=0.5 then widget:SetRenderTransformPivot({X=0.5,Y=0.5}) end
   end
   local scale=M.scales[group]
   local correctionX,correctionY=0,0
   if key=='wingman' or key=='quickCommand' then
    -- Both command roots and the map use the inspected 3840x2160 HUD canvas.
    -- CachedGeometry is empty for these offscreen-rendered widgets. Use their
    -- canvas slots instead, and translate around the map's scaling center.
    if t.originalPivot then widget:SetRenderTransformPivot(t.originalPivot) end
    local radar=M.targets.radar
    if radar then
     local function pivot(slot,position,pv)
      local size=slot:GetSize();local anchor=slot:GetAnchors().Minimum;local align=slot:GetAlignment()
      return position.X+3840*anchor.X+size.X*(pv.X-align.X),position.Y+2160*anchor.Y+size.Y*(pv.Y-align.Y)
     end
     local rx,ry=pivot(radar.widget.Slot,{X=radar.slotX,Y=radar.slotY},radar.widget.RenderTransformPivot)
     local wx,wy=pivot(widget.Slot,widget.Slot:GetPosition(),widget.RenderTransformPivot)
     correctionX=(scale-1)*(wx+t.x-rx-radar.x)
     correctionY=(scale-1)*(wy+t.y-ry-radar.y)
     -- Keep a readable gutter beside the map when the small command emblem shrinks.
     -- Only the adjacent emblem needs this; the expanded selector replaces the map.
     if key=='wingman' then correctionX=correctionX+64*math.max(0,1-scale) end
    end
   end
   if t.lastScale~=scale then
    widget:SetRenderScale({X=t.scaleX*scale,Y=t.scaleY*scale})
    widget:InvalidateLayoutAndVolatility()
    t.lastScale=scale;t.refreshPending=true
   end
   if key=='radar' or key=='radio' then
    -- Keep layout geometry aligned with the moved panels. Mask refresh is
    -- separate from positioning and must also be checked in the game.
    if not t.slotX then
     local position=widget.Slot:GetPosition()
     t.slotX=position.X;t.slotY=position.Y
    end
    widget:SetRenderTranslation({X=t.x,Y=t.y})
    if t.lastX~=offset.x or t.lastY~=offset.y then
     widget.Slot:SetPosition({X=t.slotX+offset.x,Y=t.slotY+offset.y})
     widget:InvalidateLayoutAndVolatility()
     hud.HudWidget:ForceLayoutPrepass()
     t.lastX=offset.x;t.lastY=offset.y;t.refreshPending=true
    elseif t.refreshPending then
     -- Let a frame of layout settle before refreshing the radar's cached geometry.
     if key=='radar' then for _,name in ipairs({'MiniMapSearchWidget','MiniMapBattleWidget','MiniMapWholeWidget','MiniMapEnlargedWidget'}) do
      local map=hud.MainMiniMapLayerWidget[name]
      if valid(map) then map:InvalidateLayoutAndVolatility();map:ForceLayoutPrepass() end
     end else
      hud.HUDMessageWidget:InvalidateLayoutAndVolatility()
      hud.HUDMessageWidget:ForceLayoutPrepass()
     end
     t.refreshPending=false
    end
   else
    widget:SetRenderTranslation({X=t.x+offset.x+correctionX,Y=t.y+offset.y+correctionY})
   end
  else M.targets[key]=nil end
 end
 colors.tick(pc)
end
return M

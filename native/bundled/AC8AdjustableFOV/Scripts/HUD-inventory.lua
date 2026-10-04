-- Read-only snapshot, requested once when opening the development overlay.
return function(directory,pc)
 local f=assert(io.open(directory..'HUD-color-coverage.txt','w'))
 local seen={};local count=0
 local function valid(o)return o and o:IsValid()end
 local function rgba(label,c)
  f:write(string.format(' | %s=%.4f,%.4f,%.4f,%.4f',label,c.R,c.G,c.B,c.A))
 end
 local function walk(o,depth)
  if not valid(o) or depth>18 or count>=4000 or seen[o:GetAddress()] then return end
  seen[o:GetAddress()]=true;count=count+1
  f:write(string.rep(' ',depth),o:GetFullName())
  local colors=_G.CG84HUDColors
  local entry=colors and colors.entries[o:GetAddress()]
  if entry then
   f:write(' | tracked=yes');rgba('original',entry.original)
   if entry.last then rgba('lastApplied',entry.last)end
  end
  pcall(function()f:write(' | visibility=',o:GetVisibility())end)
  pcall(function()rgba('color',o.ColorAndOpacity.SpecifiedColor)end)
  pcall(function()rgba('color',o.ColorAndOpacity)end)
  pcall(function()rgba('brushTint',o.Brush.TintColor.SpecifiedColor)end)
  pcall(function()local r=o.Brush.ResourceObject;if valid(r)then f:write(' | resource=',r:GetFullName())end end)
  pcall(function()local p=o.RenderTransformPivot;f:write(' | pivot=',p.X,',',p.Y)end)
  f:write('\n')
  pcall(function()walk(o.WidgetTree.RootWidget,depth+1)end)
  pcall(function()for i=0,o:GetChildrenCount()-1 do walk(o:GetChildAt(i),depth+1)end end)
 end
 local ok,err=pcall(function()
  local hud=pc:GetHUD()
  f:write('LIVE COLOR COVERAGE - includes hidden instantiated widgets; no changes applied\n')
  for _,name in ipairs({'HudWidget','SubtitleWidget','HUDMessageWidget','MainMiniMapLayerWidget','ForEachWidget'}) do
   f:write('ROOT ',name,'\n');pcall(function()walk(hud[name],0)end)
  end
 end)
 f:write('COUNT ',count,'\n');if not ok then f:write('ERROR ',tostring(err),'\n')end
 f:close()
 return count
end

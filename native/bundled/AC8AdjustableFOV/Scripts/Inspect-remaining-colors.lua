return function(directory)
 local f=assert(io.open(directory..'HUD-remaining-colors.txt','w'))
 local function inspect(o)
  if not o or not o:IsValid()then return end
  if o:GetFullName():find('Default__',1,true) then return end
  f:write(o:GetFullName(),'\n')
  pcall(function()
   local v=o.TimerSettings
   for _,k in ipairs({'DefaultColor','Color','TextColor','TimeColor','NormalColor','WarningColor'})do
    local ok,value=pcall(function()local c=v[k];return string.format('%.4f %.4f %.4f %.4f',c.R,c.G,c.B,c.A)end)
    if ok then f:write(' TIMER ',k,' ',value,'\n')end
   end
  end)
  pcall(function()
   local st=StaticFindObject('/Script/Live.LiveTimerSettings')
   st:ForEachProperty(function(p)f:write(' TIMERFIELD ',p:GetFullName(),'\n')end)
  end)
  local cls=o:GetClass()
  while cls and cls:IsValid() and cls:GetFName():ToString()~='Object' do
   cls:ForEachFunction(function(fn)f:write(' FUNCTION ',fn:GetFullName(),'\n')end)
   cls:ForEachProperty(function(p)
    local key=p:GetFName():ToString()
    local ok,value=pcall(function()
     local v=o[key]
     if type(v)=='number' or type(v)=='boolean' or type(v)=='string'then return tostring(v)end
     local a,b=pcall(function()return v:ToString()end);if a then return b end
     a,b=pcall(function()return string.format('RGBA %.4f %.4f %.4f %.4f',v.R,v.G,v.B,v.A)end);if a then return b end
     a,b=pcall(function()local c=v.SpecifiedColor;return string.format('Slate %.4f %.4f %.4f %.4f rule=%s',c.R,c.G,c.B,c.A,tostring(v.ColorUseRule))end);if a then return b end
     a,b=pcall(function()return v:GetFullName()end);if a then return b end
     return tostring(v)
    end)
    f:write(' ',p:GetFullName(),' = ',ok and value or 'unreadable','\n')
   end)
   cls=cls:GetSuperStruct()
  end
 end
 for _,name in ipairs({'LiveTimerAndGauge','WBP_HUD_Locator_Wingman_000_C','WBP_HUD_DynamicWidget_Parts_TargetSelectionDraw_000_C','WBP_HUD_DynamicWidget_Parts_Locator_000_C'})do
  for _,o in ipairs(FindAllOf(name)or{})do
   inspect(o)
   if name=='LiveTimerAndGauge'then pcall(function()inspect(o.RemainingTimeText)end);pcall(function()inspect(o.CachedLiveHUD)end)end
  end
 end
 f:close()
end

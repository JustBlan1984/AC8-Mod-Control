-- The default save exists before the real campaign loads. Wait for its menu.
return function()
 for _,name in ipairs({'LiveMenuCampaignTopWidget','LiveMenuCampaignFreeMissionWidget','LiveMenuHangarTopWidget'})do
  for _,widget in ipairs(FindAllOf(name) or {})do
   if widget:IsValid() and not widget:GetFullName():find('Default__',1,true) then
    local ok,visible=pcall(function()return widget:IsVisible()end)
    if ok and visible then return true end
   end
  end
 end
 return false
end

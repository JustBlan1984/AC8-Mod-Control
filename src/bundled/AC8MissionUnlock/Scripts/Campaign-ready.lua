-- Gate on a visible campaign/hangar menu, not aircraft ownership count.
return function()
 local managers=FindAllOf('LiveSaveDataManager') or {}
 if #managers==1 then
  local save=managers[1].CampaignSaveGame
  if save and save:IsValid() and save.SavedVersion==38 and save.CampaignSaveData.LastPlayedMissionID>=1 then return true end
 end
 for _,class in ipairs({'LiveMenuCampaignBaseWidget','LiveMenuHangarBaseWidget'}) do
  for _,widget in ipairs(FindAllOf(class) or {}) do
   if widget:IsValid() and widget:IsInViewport() and widget:IsVisible() then return true end
  end
 end
 return false
end

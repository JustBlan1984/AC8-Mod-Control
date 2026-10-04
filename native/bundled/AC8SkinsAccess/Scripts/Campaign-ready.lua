-- A fresh campaign can have LastPlayedMissionID=-1, and nested menu widgets
-- need not be directly in the viewport. Require an existing campaign on disk
-- plus the validated live campaign object instead of either of those signals.
return function()
 local managers=FindAllOf('LiveSaveDataManager') or {}
 if #managers~=1 then return false end
 local save=managers[1].CampaignSaveGame
 if not save or not save:IsValid() or save.SavedVersion~=38 then return false end
 local root=os.getenv('LOCALAPPDATA')
 if not root then return false end
 local file=io.open(root..'/BANDAI NAMCO Entertainment/ACE COMBAT 8/Saved/SaveGames/Campaign.sav','rb')
 if not file then return false end
 local size=file:seek('end');file:close()
 if not size or size==0 then return false end
 -- A valid default save exists during boot too. Require a loaded menu before
 -- touching campaign ownership; DLC cache preparation runs independently.
 for _,name in ipairs({'LiveMenuCampaignTopWidget','LiveMenuCampaignFreeMissionWidget','LiveMenuHangarTopWidget','LiveMenuHangarAircraftTreeWidget'}) do
  for _,widget in ipairs(FindAllOf(name) or {}) do
   if widget:IsValid() and not widget:GetFullName():find('Default__',1,true) then
    local ok,visible=pcall(function() return widget:IsVisible() end)
    if ok and visible then return true end
   end
  end
 end
 return false
end

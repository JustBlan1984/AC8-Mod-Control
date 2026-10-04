local P=_G.CG84HUDPalette or {originals={}}
_G.CG84HUDPalette=P
P.last=nil
local names={
 'HUD_ColorMain','HUD_ColorMain_NonGlow','HUD_ColorMain_Cloud',
 'HUD_WingmanOrderMainColor','HUD_WingmanOrderFocusTextColor',
 'HUD_WingmanOrderUnfocusTextColor','HUD_WingmanOrderWeaponEmptyColor',
 'HUD_PlaneNoDamageColor','HUD_RealButtonGlow',
 'HUD_ColorWingman','HUD_IconColorWeaponWingman',
}
local function copy(c)return {R=c.R,G=c.G,B=c.B,A=c.A}end
function P.tick(enabled,color,choice)
 if not P.table or not P.table:IsValid() then
  P.table=StaticFindObject('/Game/Datatables/UI/DT_UIColorDataTable.DT_UIColorDataTable')
  if not P.table or not P.table:IsValid() then return end
  P.originals={};P.last=nil
 end
 local signature=enabled and string.format('%.6f %.6f %.6f',color.R,color.G,color.B) or 'original'
 if choice then
  for _,key in ipairs({'all','commands','aircraft','wingarrows'})do
   local on,c=choice(key);signature=signature..string.format('|%s:%s:%.6f:%.6f:%.6f',key,tostring(on),c.R,c.G,c.B)
  end
 end
 if P.last==signature then return end
 for _,name in ipairs(names)do
  local enabled,color=enabled,color
  if choice then
   local group='all'
   if name:find('WingmanOrder',1,true) or name=='HUD_RealButtonGlow'then group='commands'
   elseif name=='HUD_PlaneNoDamageColor'then group='aircraft'
   elseif name=='HUD_ColorWingman' or name=='HUD_IconColorWeaponWingman'then group='wingarrows'end
   enabled,color=choice(group)
  end
  local row=P.table:FindRow(name)
  if row then
   if not P.originals[name]then P.originals[name]=copy(row.Color)end
   local original=P.originals[name]
   row.Color=enabled and {R=color.R,G=color.G,B=color.B,A=original.A} or copy(original)
  end
 end
 P.last=signature
 print('[AC8FOV] HUD source palette: '..signature..'\n')
end
return P

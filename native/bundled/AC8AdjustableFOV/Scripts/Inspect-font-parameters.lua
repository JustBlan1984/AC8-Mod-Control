return function(directory,pc)
 local f=assert(io.open(directory..'HUD-font-parameters.txt','w'))
 for _,path in ipairs({
  '/Script/Engine.MaterialInterface:GetParameterInfo',
  '/Script/Engine.KismetMaterialLibrary:CreateDynamicMaterialInstance',
 })do
  local fn=StaticFindObject(path)
  if fn and fn:IsValid()then
   f:write(path,'\n')
   fn:ForEachProperty(function(p)f:write(p:GetFullName(),'\n')end)
  end
 end
 local mat=StaticFindObject('/Game/UI/Material/HUD/SubWidgets/M_HUD_SubtitleFont_GLow_000.M_HUD_SubtitleFont_GLow_000')
 if mat and mat:IsValid()then
  f:write('FONT MATERIAL ',mat:GetFullName(),'\n')
  mat:GetClass():ForEachProperty(function(p)f:write(p:GetFullName(),'\n')end)
  f:write('DOMAIN ',tostring(mat.MaterialDomain),'\n');f:flush()
  local library=StaticFindObject('/Script/Engine.Default__KismetMaterialLibrary')
  if library and library:IsValid()then
   local mid=library:CreateDynamicMaterialInstance(pc,mat,FName('CG84FontProbe'),0)
   if mid and mid:IsValid()then
    for _,name in ipairs({'Color','FontColor','TextColor','Tint','EmissiveColor','GlowColor'})do
     local c=mid:K2_GetVectorParameterValue(FName(name))
     f:write('DEFAULT ',name,string.format(' %.5f %.5f %.5f %.5f\n',c.R,c.G,c.B,c.A));f:flush()
    end
   end
  end
 end
 f:close()
end

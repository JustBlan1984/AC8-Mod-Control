-- One-shot read-only catalog: known material parameter arrays and class metadata.
return function(directory)
 local f=assert(io.open(directory..'HUD-target-materials.txt','w'))
 local seen={}
 local function metadata(o)
  local cls=o:GetClass()
  while cls and cls:IsValid() do
   local name=cls:GetFullName()
   if seen[name] then break end
   seen[name]=true;f:write('CLASS ',name,'\n');f:flush()
   cls:ForEachProperty(function(p)f:write(' PROPERTY ',p:GetFullName(),'\n')end)
   cls:ForEachFunction(function(fn)f:write(' FUNCTION ',fn:GetFullName(),'\n')end)
   cls=cls:GetSuperStruct()
  end
 end
 for _,class in ipairs({'ChronicleTargetContainerActorBP_C','MaterialInstanceDynamic'})do
  local count=0
  for _,o in ipairs(FindAllOf(class)or{})do
   if o and o:IsValid()then
    local name=o:GetFullName()
    if class~='MaterialInstanceDynamic' or name:find('TargetContainer3DUI',1,true)then
     count=count+1
     if class=='ChronicleTargetContainerActorBP_C' and count<=100 then
      local ok,err=pcall(function()
       f:write('LABEL ',name,' | ',o.ObjectTypeText.Text:ToString(),' | ',o.ObjectCallsignText.Text:ToString(),'\n');f:flush()
      end)
      if not ok then f:write('LABEL ERROR ',tostring(err),'\n')end
     end
     if count<=8 then
      f:write('OBJECT ',name,'\n');f:flush();metadata(o)
      if class=='ChronicleTargetContainerActorBP_C' and count<=2 then
       for _,key in ipairs({'ContainerBox','ObjectTypeText','ObjectCallsignText','ContainerBoxMaterialInst','ObjectTypeTextMaterialInst','ObjectCallsignTextMaterialInst'})do
        local child=o[key]
        if child and child:IsValid()then
         f:write(' CHILD ',key,' ',child:GetFullName(),'\n');f:flush();metadata(child)
         if key:find('MaterialInst',1,true)then
          child.VectorParameterValues:ForEach(function(_,item)local p=item:get();local c=p.ParameterValue;f:write(' VECTOR ',p.ParameterInfo.Name:ToString(),string.format(' %.5f %.5f %.5f %.5f\n',c.R,c.G,c.B,c.A))end)
         end
        end
       end
      end
      if class=='MaterialInstanceDynamic'then
       local ok,err=pcall(function()
        o.VectorParameterValues:ForEach(function(_,item)
         local p=item:get();local c=p.ParameterValue
         f:write(' VECTOR ',p.ParameterInfo.Name:ToString(),string.format(' %.5f %.5f %.5f %.5f\n',c.R,c.G,c.B,c.A));f:flush()
        end)
       end)
       if not ok then f:write(' ERROR ',tostring(err),'\n')end
      end
     end
    end
   end
  end
 end
 f:close()
end

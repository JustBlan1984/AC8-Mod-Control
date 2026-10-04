return function(directory)
 local f=assert(io.open(directory..'HUD-color-table.txt','w'))
 local ok,err=pcall(function()
  for _,dt in ipairs(FindAllOf('DataTable') or {})do
   local name=dt:GetFullName()
   if name:lower():find('color') then
    f:write(name,'\n')
    local good,why=pcall(function()
     local st=dt:GetRowStruct();f:write('STRUCT ',st:GetFullName(),'\n')
     local props={'Color','Value','Name','ID','ColorName','LinearColor'}
     dt:ForEachRow(function(n,r)
      f:write('ROW ',n,'\n')
      for _,key in ipairs(props)do
       local success,value=pcall(function()
        local v=r[key]
        if type(v)=='number' or type(v)=='string' or type(v)=='boolean' then return tostring(v)end
        local colorOK,c=pcall(function()return string.format('%.6f %.6f %.6f %.6f',v.R,v.G,v.B,v.A)end)
        if colorOK then return c end
        return tostring(v)
       end)
       f:write(' ',key,' ',success and value or tostring(value),'\n')
      end
     end)
    end)
    if not good then f:write('ERROR ',tostring(why),'\n')end
   end
  end
 end)
 if not ok then f:write('ERROR ',tostring(err),'\n')end
 f:close()
end


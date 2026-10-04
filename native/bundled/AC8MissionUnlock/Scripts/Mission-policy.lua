-- Limit only base-campaign access. Preserve completed missions and unknown/DLC IDs.
return function(old,selected,catalog,completed,enforce)
 local known,allowed,seen,out={},{},{},{}
 for _,ids in pairs(catalog)do for _,id in ipairs(ids)do known[id]=true end end
 for _,id in ipairs(selected)do allowed[id]=true end
 for _,id in ipairs(completed)do allowed[id]=true end
 local function add(id)if not seen[id]then out[#out+1]=id;seen[id]=true end end
 for _,id in ipairs(old)do if not enforce or not known[id] or allowed[id]then add(id)end end
 for _,id in ipairs(selected)do add(id)end
 for _,id in ipairs(completed)do if known[id]then add(id)end end
 return out
end

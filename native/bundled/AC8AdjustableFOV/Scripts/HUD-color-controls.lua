local directory=assert(debug.getinfo(1,'S').source:match('^@(.+[\\/])'))
local colors=assert(loadfile(directory..'HUD-colors.lua'))()
return function(state,layout,make,pc,log)
 local c=state.hudControls
 if not c.colorToggle then
  local function add(kind,label,x,y,w,h)
   local o=make(kind,label,x,y,w,h);table.insert(c.widgets,o);return o
  end
  c.colorToggle=add('Button','HUD COLOR',150,1232,260,44)
  c.colorReset=add('Button','↺',690,1232,44,44)
  c.colorWidgets={};c.colorDecorations={}
  local function part(...)local o=add(...);table.insert(c.colorWidgets,o);return o end
  local canvas=state.widget.WidgetTree.RootWidget
  local function image(x,y,w,h,color)
   local o=StaticConstructObject(StaticFindObject('/Script/UMG.Image'),state.widget.WidgetTree)
   o:SetColorAndOpacity(color);local slot=canvas:AddChildToCanvas(o);slot:SetPosition({X=x,Y=y});slot:SetSize({X=w,Y=h})
   o:SetVisibility(4);table.insert(c.widgets,o);table.insert(c.colorWidgets,o);table.insert(c.colorDecorations,o);return o
  end
  image(790,140,390,1168,{R=0.002,G=0.008,B=0.002,A=0.62})
  local borderGreen={R=0.075,G=0.43,B=0.045,A=1}
  image(790,140,390,2,borderGreen);image(790,1306,390,2,borderGreen)
  image(790,140,2,1168,borderGreen);image(1178,140,2,1168,borderGreen)
  c.colorTitle=part('TextBlock','ALL HUD',810,158,350,40)
  local loaded,texture=pcall(function()
   return StaticFindObject('/Script/Engine.Default__KismetRenderingLibrary'):ImportFileAsTexture2D(pc,directory..'HUD-color-wheel.png')
  end)
  if loaded and texture and texture:IsValid() then
   local wheelImage=image(810,218,224,224,{R=1,G=1,B=1,A=1})
   wheelImage:SetBrushFromTexture(texture,false);c.wheelTexture=texture
   log('Smooth HUD color wheel loaded.')
  else
  log('Smooth HUD color wheel unavailable; using fallback.')
  for y=-14,14 do for x=-14,14 do
   local d=math.sqrt(x*x+y*y)/14
   if d<=1 then image(922+x*8-4,330+y*8-4,9,9,colors.rgb((math.atan(y,x)/(2*math.pi))%1,d,1))end
  end end
  end
  c.wheel=part('Button','',806,214,232,232);c.wheel:SetBackgroundColor({R=0,G=0,B=0,A=0})
  c.wheel:SetClickMethod(0) -- capture from mouse down until release
  c.colorMarker=part('TextBlock','+',912,316,30,35)
  part('TextBlock','BRIGHTNESS',810,465,260,35)
  c.brightness=part('Slider','',810,512,270,35)
  c.brightness:SetMinValue(0);c.brightness:SetMaxValue(1);c.brightness:SetValue(colors.v)
  c.brightness:SetSliderHandleColor({R=0.15,G=0.7,B=0.08,A=1})
  c.rgbFields={}
  for i,label in ipairs({'R','G','B'})do
   local x=1046;local y=230+(i-1)*56
   part('TextBlock',label,x,y+6,22,36)
   local field=StaticConstructObject(StaticFindObject('/Script/UMG.EditableTextBox'),state.widget.WidgetTree)
   -- Set the reflected style before constructing the underlying Slate field.
   -- Keep native editing/caret behavior; only its stock white background changes.
   local styled,styleError=pcall(function()
    local style=field.WidgetStyle
    local foreground={SpecifiedColor=borderGreen,ColorUseRule=0}
    style.ForegroundColor=foreground
    style.FocusedForegroundColor=foreground
    style.ReadOnlyForegroundColor=foreground
    for _,key in ipairs({'BackgroundImageNormal','BackgroundImageHovered','BackgroundImageFocused','BackgroundImageReadOnly'})do
     style[key].DrawAs=0
    end
   end)
   if not styled then log('RGB field style: '..tostring(styleError))end
   local fontOK,fontError=pcall(function()
    field.WidgetStyle.TextStyle.Font.Size=18
    field.WidgetStyle.Padding={Left=3,Top=2,Right=3,Bottom=2}
   end)
   if not fontOK then log('RGB field font: '..tostring(fontError))end
   local left=x+23
   local edge={R=0.35,G=0.40,B=0.37,A=1}
   image(left,y,90,42,{R=0.012,G=0.032,B=0.012,A=0.4})
   local slot=canvas:AddChildToCanvas(field);slot:SetPosition({X=left,Y=y});slot:SetSize({X=90,Y=42})
   field:SetText(FText('0'))
   -- Draw the complete frame above the native edit field, without blocking input.
   image(left,y,90,2,edge);image(left,y+40,90,2,edge)
   image(left,y,2,42,edge);image(left+88,y,2,42,edge)
   table.insert(c.widgets,field);table.insert(c.colorWidgets,field);c.rgbFields[i]=field
  end
  c.rgbApply=part('Button','SET',1069,400,90,42)
  c.colorPage=1;c.colorRows={}
  for i=1,12 do
   c.colorRows[i]={button=part('Button','',810,580+(i-1)*49,292,42),reset=part('Button','↺',1115,580+(i-1)*49,44,42)}
  end
  c.colorPrev=part('Button','←',810,1180,44,42)
  c.colorPageText=part('TextBlock','',870,1185,220,35)
  c.colorNext=part('Button','→',1115,1180,44,42)
  c.colorInherit=part('Button','USE ALL HUD COLOR',810,1240,349,44)
  c.selectedColor=nil
 end
 local function press(o,key)
  local down=o:IsPressed();local hit=down and not c[key];c[key]=down;return hit
 end
 local function syncRGB()
  local rgb=colors.rgb(colors.h,colors.s,colors.v)
  for i,key in ipairs({'R','G','B'})do c.rgbFields[i]:SetText(FText(tostring(math.floor(rgb[key]*255+0.5))))end
 end
 local function refreshChoice()
  c.brightness:SetValue(colors.v);c.lastBrightness=colors.v;c.selectedColor=colors.selected;syncRGB()
  for _,g in ipairs(colors.groups)do if g[1]==colors.selected then c.colorTitle:SetText(FText(g[2]))end end
 end
 if c.selectedColor~=colors.selected then refreshChoice()end
 local down=c.colorToggle:IsPressed()
 if down and not c.colorToggleDown then c.colorOpen=not c.colorOpen end
 c.colorToggleDown=down
 for _,o in ipairs(c.colorWidgets)do o:SetVisibility(c.colorOpen and 0 or 1)end
 for _,o in ipairs(c.colorDecorations or {})do o:SetVisibility(c.colorOpen and 4 or 1)end
 -- The marker must never intercept clicks over the current color.
 c.colorMarker:SetVisibility(c.colorOpen and 4 or 1)
 if not c.colorOpen then
  c.wheelDragging=false;_G.CG84HUDColorDragging=false
  if c.colorDirty then colors.save();c.colorDirty=false end
 end
 local reset=c.colorReset:IsPressed()
 if reset and not c.colorResetDown then colors.reset('all');refreshChoice();c.note:SetText(FText('Original HUD colors restored.'))end
 c.colorResetDown=reset
 if c.colorOpen then
  local pages=math.ceil(#colors.groups/12)
  if press(c.colorPrev,'prevDown')then c.colorPage=math.max(1,c.colorPage-1)end
  if press(c.colorNext,'nextDown')then c.colorPage=math.min(pages,c.colorPage+1)end
  c.colorPageText:SetText(FText('ELEMENTS  '..c.colorPage..' / '..pages))
  for i,row in ipairs(c.colorRows)do
   local g=colors.groups[(c.colorPage-1)*12+i]
   row.button:SetVisibility(g and 0 or 1);row.reset:SetVisibility(g and 0 or 1)
   if g then
    row.button:GetChildAt(0):SetText(FText((g[1]==colors.selected and g[1]~='commands' and '> ' or '')..g[2]))
    if press(row.button,'select'..i)then
     if c.colorDirty then colors.save();c.colorDirty=false end
     colors.choose(g[1]);refreshChoice()
    end
    if press(row.reset,'reset'..i)then
     colors.reset(g[1]);refreshChoice();c.note:SetText(FText(g[2]..' reset.'))
    end
   end
  end
  c.colorInherit:SetVisibility(colors.selected=='all' and 1 or 0)
  if colors.selected~='all' and press(c.colorInherit,'inheritDown')then
   colors.inherit();refreshChoice();c.note:SetText(FText('Using All HUD color.'))
  end
  if press(c.rgbApply,'rgbApplyDown')then
   local values={}
   for i,field in ipairs(c.rgbFields)do values[i]=tonumber(field:GetText():ToString())end
   if colors.setRGB(values[1],values[2],values[3])then
    refreshChoice();local ok=colors.save();c.colorDirty=false
    c.note:SetText(FText(ok and 'RGB color saved.' or 'Could not save color.'))
   else c.note:SetText(FText('RGB: use whole numbers from 0 to 255.'))end
  end
  local pressed=c.wheel:IsPressed()
  local brightness=c.brightness:GetValue()
  _G.CG84HUDColorDragging=pressed
  if pressed then
   local lib=StaticFindObject('/Script/UMG.Default__WidgetLayoutLibrary')
   local mouse=lib:GetMousePositionOnViewport(pc)
   local x=mouse.X-layout.menu.x-922;local y=mouse.Y-layout.menu.y-330
   local distance=math.sqrt(x*x+y*y)
   -- Begin inside the disk; keep tracking while captured outside it and
   -- clamp saturation at the rim instead of freezing or requiring a new click.
   if not c.wheelDragging and distance<=112 then c.wheelDragging=true end
   if c.wheelDragging then
    colors.select(distance>0.001 and (math.atan(y,x)/(2*math.pi))%1 or colors.h,math.min(1,distance/112),brightness)
    c.colorDirty=true;syncRGB()
   end
  elseif c.lastBrightness and math.abs(brightness-c.lastBrightness)>0.001 then colors.select(colors.h,colors.s,brightness);c.colorDirty=true;syncRGB() end
  if not pressed then c.wheelDragging=false end
  c.lastBrightness=brightness
  c.colorMarker.Slot:SetPosition({X=912+math.cos(colors.h*2*math.pi)*colors.s*112,Y=316+math.sin(colors.h*2*math.pi)*colors.s*112})
  if not pressed and c.colorDirty then
   local ok=colors.save();c.colorDirty=false;c.note:SetText(FText(ok and 'HUD color saved.' or 'Could not save color.'))
  end
 end
end

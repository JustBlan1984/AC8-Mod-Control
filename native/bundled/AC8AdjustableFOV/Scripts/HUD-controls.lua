local directory=assert(debug.getinfo(1,'S').source:match('^@(.+[\\/])'))
local colorControls=assert(loadfile(directory..'HUD-color-controls.lua'))()
return function(state,layout,log,opening,pc)
 local canvas=state.widget.WidgetTree.RootWidget
 local green={SpecifiedColor={R=0.075,G=0.43,B=0.045,A=1},ColorUseRule=0}
 local function make(kind,caption,x,y,w,h)
  local o=StaticConstructObject(StaticFindObject('/Script/UMG.'..kind),state.widget.WidgetTree)
  local label=o
  if kind=='Button' then
   o:SetBackgroundColor({R=0.012,G=0.032,B=0.012,A=0.4})
   label=StaticConstructObject(StaticFindObject('/Script/UMG.TextBlock'),state.widget.WidgetTree);o:AddChild(label)
  end
  if kind~='Slider' then
  label:SetText(FText(caption));label:SetColorAndOpacity(green)
  if kind=='Button' then label:SetJustification(1);label.Slot:SetHorizontalAlignment(2);label.Slot:SetVerticalAlignment(2);label.Slot:SetPadding({Left=0,Top=0,Right=0,Bottom=0}) end
  local font=label.Font;font.Size=21;font.TypefaceFontName=FName('Regular');label:SetFont(font)
  end
  local slot=canvas:AddChildToCanvas(o);slot:SetPosition({X=x,Y=y});slot:SetSize({X=w,Y=h})
  return o
 end
 if state.hudControls and state.hudControls.version~=20 then
  for _,o in ipairs(state.hudControls.widgets) do o:RemoveFromParent() end
  state.hudControls=nil
 end
 if not state.hudControls then
  local c={rows={},widgets={},version=20};state.hudControls=c
  local function add(...) local o=make(...);table.insert(c.widgets,o);return o end
  add('TextBlock','HUD LAYOUT',150,430,600,40)
  local names={'SCORE / TIME','RADAR','WEAPONS','RADIO PORTRAIT'}
  for i,key in ipairs(layout.groups) do
   local y=492+(i-1)*116
   local row={key=key,buttons={},pressed={}}
   add('TextBlock',names[i],150,y+7,220,35)
   for j,caption in ipairs({'←','→','↑','↓','↺'}) do
    row.buttons[j]=add('Button',caption,({390,456,522,588,690})[j],y,j==5 and 44 or 54,44)
   end
   add('TextBlock','SIZE',150,y+56,100,35)
   row.slider=add('Slider','',255,y+55,387,36)
   row.slider:SetMinValue(0.5);row.slider:SetMaxValue(1.5);row.slider:SetStepSize(0.01)
   row.slider:SetSliderHandleColor({R=0.15,G=0.7,B=0.08,A=1})
   row.slider:SetSliderBarColor({R=0.05,G=0.2,B=0.05,A=1})
   row.sizeReset=add('Button','↺',690,y+53,44,44)
   c.rows[i]=row
  end
  local center={key='center',buttons={},pressed={}}
  add('TextBlock','CENTER SIZE',150,952,220,35)
  center.slider=add('Slider','',390,951,252,36)
  center.slider:SetMinValue(0.5);center.slider:SetMaxValue(1.5);center.slider:SetStepSize(0.01)
  center.slider:SetSliderHandleColor({R=0.15,G=0.7,B=0.08,A=1})
  center.slider:SetSliderBarColor({R=0.05,G=0.2,B=0.05,A=1})
  center.sizeReset=add('Button','↺',690,949,44,44)
  table.insert(c.rows,center)
  local wingbox={key='wingbox',buttons={},pressed={}}
  add('TextBlock','WINGMAN BOX',150,1008,235,35)
  wingbox.slider=add('Slider','',390,1007,252,36)
  wingbox.slider:SetMinValue(0.5);wingbox.slider:SetMaxValue(1.5);wingbox.slider:SetStepSize(0.01)
  wingbox.slider:SetSliderHandleColor({R=0.15,G=0.7,B=0.08,A=1})
  wingbox.slider:SetSliderBarColor({R=0.05,G=0.2,B=0.05,A=1})
  wingbox.sizeReset=add('Button','↺',690,1005,44,44)
  table.insert(c.rows,wingbox)
  c.wingVisible=add('Button','SHOW WINGMAN BOX',150,1060,360,44)
  c.note=add('TextBlock','Changes save automatically.',150,1131,595,34)
  c.reset=add('Button','RESET ALL HUD',150,1178,260,44)
  c.corners=add('Button','ULTRAWIDE PRESET',430,1178,314,44)
 end
 local c=state.hudControls
 local visibleDown=c.wingVisible:IsPressed()
 if visibleDown and not c.wingVisibleDown then
  layout.showWingmanBox=not layout.showWingmanBox
  local ok,err=layout.save()
  if not ok then log('Wingman visibility save failed: '..tostring(err))end
 end
 c.wingVisibleDown=visibleDown
 c.wingVisible:GetChildAt(0):SetText(FText(layout.showWingmanBox and 'WINGMAN BOX: ON' or 'WINGMAN BOX: OFF'))
 if not c.drag then
  c.drag=make('Button','FOV / HUD   -   DRAG TO MOVE',150,158,530,44)
  table.insert(c.widgets,c.drag)
 end
 if opening then
  for _,o in ipairs(c.widgets) do o:SetVisibility(0) end
  for _,row in ipairs(c.rows) do row.pressed={};row.sizeResetPressed=false;row.slider:SetValue(layout.scales[row.key]);row.lastScale=layout.scales[row.key] end
  c.resetPressed=false;c.cornersPressed=false
  for _,i in ipairs({0,3,4}) do local o=canvas:GetChildAt(i);local size=o.Slot:GetSize();o.Slot:SetSize({X=size.X,Y=1168}) end
  canvas:GetChildAt(2).Slot:SetPosition({X=120,Y=1306})
  canvas:GetChildAt(5):SetVisibility(1)
  c.dragStart=nil
 end
 local viewport=StaticFindObject('/Script/UMG.Default__WidgetLayoutLibrary')
 local size=viewport:GetViewportSize(pc)
 local scale=viewport:GetViewportScale(pc)
 local maxX=math.max(-100,size.X/math.max(scale,0.01)-(c.colorOpen and 1180 or 770))
 local maxY=math.max(-120,size.Y/math.max(scale,0.01)-1308)
 layout.menu.x=math.max(-100,math.min(maxX,layout.menu.x))
 layout.menu.y=math.max(-120,math.min(maxY,layout.menu.y))
 if c.drag:IsPressed() then
  local mouse=viewport:GetMousePositionOnViewport(pc)
  if not c.dragStart then c.dragStart={x=mouse.X,y=mouse.Y,originX=layout.menu.x,originY=layout.menu.y} end
  layout.menu.x=math.max(-100,math.min(maxX,c.dragStart.originX+mouse.X-c.dragStart.x))
  layout.menu.y=math.max(-120,math.min(maxY,c.dragStart.originY+mouse.Y-c.dragStart.y))
 elseif c.dragStart then
  c.dragStart=nil
  local ok,err=layout.save();if not ok then log('Overlay position save failed: '..tostring(err)) end
 end
 canvas:SetRenderTranslation({X=layout.menu.x,Y=layout.menu.y})
 local function save(key,x,y)
  local ok,err=layout.set(key,x,y)
  c.note:SetText(FText(ok and 'Position saved.' or 'Could not save position.'))
  if not ok then log('HUD settings save failed: '..tostring(err)) end
 end
 for _,row in ipairs(c.rows) do
  local sizeDown=row.sizeReset:IsPressed()
  if sizeDown and not row.sizeResetPressed then row.slider:SetValue(1) end
  row.sizeResetPressed=sizeDown
  local value=math.floor(row.slider:GetValue()*100+0.5)/100
  if value~=row.lastScale then
   layout.setScale(row.key,value,false);row.lastScale=value;c.sizeDirty=true;c.sizeIdle=0
   c.note:SetText(FText('Size preview. Saves automatically.'))
  end
  for j,b in ipairs(row.buttons) do
   local down=b:IsPressed()
   if down and not row.pressed[j] then
    local v=layout.values[row.key]
    save(row.key,j==5 and 0 or v.x+(j==1 and -20 or j==2 and 20 or 0),j==5 and 0 or v.y+(j==3 and -20 or j==4 and 20 or 0))
   end
   row.pressed[j]=down
  end
 end
 local down=c.reset:IsPressed()
 if down and not c.resetPressed then for _,row in ipairs(c.rows) do layout.setScale(row.key,1,false);row.slider:SetValue(1);row.lastScale=1;if layout.values[row.key] then save(row.key,0,0) end end;layout.save() end
 c.resetPressed=down
 local corners=c.corners:IsPressed()
 if corners and not c.cornersPressed then
  local lib=StaticFindObject('/Script/UMG.Default__WidgetLayoutLibrary')
  local size=lib:GetViewportSize(pc)
  if size.Y>0 then
   local amount=math.floor(math.max(0,(size.X/size.Y*2160-3840)/2)/20)*20
   for _,key in ipairs(layout.groups) do save(key,(key=='score' or key=='radar') and -amount or amount,0) end
  end
 end
 c.cornersPressed=corners
 if c.sizeDirty then
  c.sizeIdle=(c.sizeIdle or 0)+1
  if c.sizeIdle>=8 then
   local ok,err=layout.save();c.sizeDirty=false
   c.note:SetText(FText(ok and 'Size saved.' or 'Could not save size.'))
   if not ok then log('HUD size save failed: '..tostring(err)) end
  end
 end
 colorControls(state,layout,make,pc,log)
end

-- Direct selection is enabled only for the inspected native command signature.
local directory=assert(debug.getinfo(1,'S').source:match('^@(.+[\\/])'))
local file=io.open(directory..'../../../../AceCombat8.exe','rb')
local supported=false
if file then
    file:seek('set',131404707)
    supported=file:read(42)==string.char(0x0f,0xb6,0x83,0xe0,0x18,0x00,0x00,0x3c,0x06,0x73,0x26,0x48,0x8d,0x15,0x6b,0x19,0xeb,0x04,0x0f,0xb6,0x14,0x10,0x80,0xfa,0x05,0x74,0x16,0x41,0xb1,0x01,0x48,0x8b,0xcb,0x45,0x0f,0xb6,0xc1,0xe8,0x13,0x00,0x00,0x00)
    file:close()
end
if supported and not _G.CG84DirectCameraRegistered then
    RegisterCustomProperty({Name='CG84CameraType',Type=PropertyTypes.ByteProperty,BelongsToClass='/Script/Live.LivePlayerPlane',OffsetInternal=0x18e0})
    _G.CG84DirectCameraRegistered=true
end
local hudLayout=assert(loadfile(directory..'HUD-layout.lua'))()
_G.CG84HUDLayout=hudLayout
local hudControls=assert(loadfile(directory..'HUD-controls.lua'))()
-- CriminalGamer84 Mods - native Unreal HUD, no external renderer.
return function(state, pc, memory, log, toggle)
    local hudOK,hudError=true,nil
    if not _G.CG84HUDLayoutTickedByMain then hudOK,hudError=pcall(hudLayout.tick,pc) end
    if not hudOK and state.hudError~=tostring(hudError) then state.hudError=tostring(hudError);log(state.hudError) end
    local function valid(o) return o and o:IsValid() end
    local lib=StaticFindObject('/Script/UMG.Default__WidgetBlueprintLibrary')
    local gameplay=StaticFindObject('/Script/Engine.Default__GameplayStatics')
    local green={R=0.075,G=0.43,B=0.045,A=1}
    local shade={SpecifiedColor=green,ColorUseRule=0}
    -- Use the native view command to preserve the game camera-cycle state.
    local cameraTypes={FirstPersonCamera=0,CockpitCamera=1,ThirdPersonCamera=2}
    local function activeView(pawn)
        local found=nil
        for name,_ in pairs(cameraTypes) do
            local camera=pawn[name]
            if valid(camera) and camera:IsActive() then
                if found then return nil end
                found=name
            end
        end
        return found
    end

    local function close(saveChanges)
        _G.CG84HUDColorDragging=false
        if state.hudControls and state.hudControls.sizeDirty then
            local ok,err=hudLayout.save();state.hudControls.sizeDirty=false
            if not ok then log('HUD size save failed: '..tostring(err)) end
        end
        if valid(state.widget) then state.widget:SetVisibility(1) end
        state.visible=false
        state.previewOrigin=nil;state.previewPawn=nil;state.switchTarget=nil
        pc.bShowMouseCursor=state.oldCursor or false
        lib:SetInputMode_GameOnly(pc,false)
        log('HUD closed; flight input restored.')
    end
    state.cleanup=close
    local function text(value) return FText(value) end
    local function construct(name,outer)
        local obj=StaticConstructObject(StaticFindObject('/Script/UMG.'..name),outer)
        assert(valid(obj),'Could not create '..name)
        return obj
    end
    local function build()
        local widget=lib:Create(pc,StaticFindObject('/Script/UMG.UserWidget'),pc)
        if not valid(widget) then widget=construct('UserWidget',pc) end
        local tree=construct('WidgetTree',widget);widget.WidgetTree=tree
        local canvas=construct('CanvasPanel',tree);tree.RootWidget=canvas
        local function place(obj,x,y,w,h)
            local slot=canvas:AddChildToCanvas(obj)
            slot:SetPosition({X=x,Y=y});slot:SetSize({X=w,Y=h})
            return obj
        end
        local function image(x,y,w,h,color)
            local obj=construct('Image',tree);obj:SetColorAndOpacity(color);obj:SetVisibility(4)
            return place(obj,x,y,w,h)
        end
        local function label(caption,x,y,w,h,size)
            local obj=construct('TextBlock',tree);obj:SetText(text(caption));obj:SetColorAndOpacity(shade);obj:SetVisibility(4)
            if size then pcall(function() local font=obj.Font;font.Size=size;font.TypefaceFontName=FName("Regular");obj:SetFont(font) end) end
            return place(obj,x,y,w,h)
        end
        local function button(caption,x,y,w,h)
            local obj=construct('Button',tree)
            obj:SetBackgroundColor({R=0.012,G=0.032,B=0.012,A=0.4})
            local captionWidget=construct('TextBlock',tree)
            captionWidget:SetText(text(caption));captionWidget:SetColorAndOpacity(shade)
            obj:AddChild(captionWidget)
            return place(obj,x,y,w,h)
        end
        image(120,140,930,650,{R=0.002,G=0.008,B=0.002,A=0.62})
        image(120,140,930,2,green);image(120,788,930,2,green)
        image(120,140,2,650,green);image(1048,140,2,650,green)
        label('[FOV SETTINGS]',150,166,690,48,30)
        label('CRIMINALGAMER84 MODS',152,218,700,35,19)
        state.closeButton=button('CLOSE',885,170,135,48)
        image(150,267,870,1,green)
        state.status=label('[CAMERA VIEWS]',150,284,850,35,20)
        state.rows={}
        local names={{'CockpitCamera','COCKPIT'},{'FirstPersonCamera','FIRST PERSON / HUD'},{'ThirdPersonCamera','CHASE'}}
        for index,pair in ipairs(names) do
            local y=340+(index-1)*110
            local row={name=pair[1],caption=pair[2],dirty=false,stable=0,pressed=false}
            row.label=label(pair[2],150,y,600,35,24)
            row.value=label('DEFAULT',785,y,235,35,22)
            row.minus=button('-',150,y+32,72,48)
            row.plus=button('+',405,y+32,72,48)
            row.value.Slot:SetPosition({X=240,Y=y+39})
            row.reset=button('RESET',875,y+32,145,48)
            state.rows[index]=row
        end
        image(150,684,870,1,green)
        label('5 degree steps / 50 - 150 / saved per view',150,701,865,34,19)
        label((state.shortcut or 'F9')..': close and resume flight',150,744,865,32,19)
        widget:AddToViewport(10000)
        widget:SetVisibility(1)
        state.widget=widget;state.owner=pc:GetAddress()
        log('Native HUD controls created.')
    end
    local function applyMenuTheme()
        if state.menuThemeApplied then return end
        local canvas=state.widget.WidgetTree.RootWidget
        local function styleText(obj)
            obj:SetColorAndOpacity(shade)
            local font=obj.Font
            font.TypefaceFontName=FName("Regular")
            obj:SetFont(font)
        end
        for i=0,canvas:GetChildrenCount()-1 do
            local obj=canvas:GetChildAt(i)
            local className=obj:GetClass():GetFullName()
            if className:find('TextBlock') then
                styleText(obj)
                if i==5 then obj:SetText(text('[FOV SETTINGS]')) end
            elseif className:find('Image') then
                obj:SetColorAndOpacity(i==0 and {R=0.002,G=0.008,B=0.002,A=0.62} or green)
            elseif className:find('Button') then
                obj:SetBackgroundColor({R=0.012,G=0.032,B=0.012,A=0.4})
                styleText(obj:GetChildAt(0))
            elseif className:find('Slider') then
                obj:SetSliderHandleColor(green)
            end
        end
        state.status:SetText(text('[CAMERA VIEWS]'))
        state.menuThemeApplied=true
        log('Pause-menu theme applied.')
    end
    local function upgradeControls()
        local tree=state.widget.WidgetTree
        local canvas=tree.RootWidget
        local function stepButton(caption,x,y)
            local obj=construct('Button',tree)
            obj:SetBackgroundColor({R=0.012,G=0.032,B=0.012,A=0.4})
            local label=construct('TextBlock',tree)
            label:SetText(text(caption));label:SetColorAndOpacity(shade)
            local font=label.Font;font.TypefaceFontName=FName('Regular');label:SetFont(font)
            obj:AddChild(label)
            local slot=canvas:AddChildToCanvas(obj)
            slot:SetPosition({X=x,Y=y});slot:SetSize({X=72,Y=48})
            return obj
        end
        for index,row in ipairs(state.rows) do
            if not row.minus then
                local y=340+(index-1)*110
                row.slider:SetVisibility(1)
                row.minus=stepButton('-',150,y+32)
                row.plus=stepButton('+',405,y+32)
                row.value.Slot:SetPosition({X=240,Y=y+39})
            end
        end
    end
    local function compactLayout()
        local canvas=state.widget.WidgetTree.RootWidget
        for i=0,canvas:GetChildrenCount()-1 do canvas:GetChildAt(i):SetVisibility(1) end
        local function place(obj,x,y,w,h,visible)
            obj.Slot:SetPosition({X=x,Y=y});obj.Slot:SetSize({X=w,Y=h})
            obj:SetVisibility(visible or 0)
        end
        place(canvas:GetChildAt(0),120,140,650,300,4)
        place(canvas:GetChildAt(1),120,140,650,2,4)
        place(canvas:GetChildAt(2),120,438,650,2,4)
        place(canvas:GetChildAt(3),120,140,2,300,4)
        place(canvas:GetChildAt(4),768,140,2,300,4)
        local title=canvas:GetChildAt(5)
        title:SetText(text('[FOV]'))
        place(title,150,161,420,42,4)
        state.closeButton:GetChildAt(0):SetText(text('X'))
        place(state.closeButton,700,158,44,42)
        for index,row in ipairs(state.rows) do
            local y=230+(index-1)*62
            row.caption=({'COCKPIT','HUD','CHASE'})[index]
            if not row.select then
                local tree=state.widget.WidgetTree
                row.select=construct('Button',tree)
                row.select:SetBackgroundColor({R=0.012,G=0.032,B=0.012,A=0.4})
                local caption=construct('TextBlock',tree)
                caption:SetText(text(row.caption));caption:SetColorAndOpacity(shade)
                local font=caption.Font;font.TypefaceFontName=FName('Regular');caption:SetFont(font)
                row.select:AddChild(caption)
                canvas:AddChildToCanvas(row.select)
            end
            row.label:SetVisibility(1)
            place(row.select,150,y,240,44)
            place(row.minus,410,y,48,44)
            place(row.value,458,y+6,157,36,4)
            row.value:SetJustification(1)
            place(row.plus,615,y,48,44)
            place(row.reset,690,y,44,44)
            row.reset:GetChildAt(0):SetText(text('↺'))
            local resetLabel=row.reset:GetChildAt(0)
            resetLabel:SetJustification(1)
            resetLabel.Slot:SetHorizontalAlignment(2);resetLabel.Slot:SetVerticalAlignment(2)
            resetLabel.Slot:SetPadding({Left=0,Top=0,Right=0,Bottom=0})
        end
    end
    if toggle then
        if state.visible then close();return end
        local pawn=pc.Pawn
        if not valid(pawn) or pawn.bEnableCameraViewChange~=true or pawn.bIsLocalViewTarget~=true then
            log('Open the FOV HUD during single-player flight.');return
        end
        if gameplay:IsGamePaused(pc) then log('Resume the game before opening the FOV HUD.');return end
        local originalView=activeView(pawn)
        if not originalView then
            log('Multiple or missing flight cameras; restart the mission before opening the preview.')
            return
        end
        state.previewOrigin=originalView;state.previewPawn=pawn:GetAddress()
        if not valid(state.widget) or state.owner~=pc:GetAddress() then build() end
        local themeOk,themeError=pcall(applyMenuTheme)
        if not themeOk then log("Theme update: "..tostring(themeError)) end
        upgradeControls()
        compactLayout()
        if not _G.CG84ColorCoverageCaptured then
            local ok,result=pcall(function()return assert(loadfile(directory..'HUD-inventory.lua'))()(directory,pc)end)
            if ok then _G.CG84ColorCoverageCaptured=true;log('HUD inventory captured: '..tostring(result)..' widgets.')
            else log('HUD inventory failed: '..tostring(result)) end
        end
        hudControls(state,hudLayout,log,true,pc)
        local snapshot=memory.snapshot()
        for _,row in ipairs(state.rows) do
            row.last=snapshot[row.name] or 90;row.saved=snapshot[row.name]
            row.minusPressed=false;row.plusPressed=false;row.pressed=false;row.selectPressed=false
            row.value:SetText(text(row.saved and string.format('%.1f',row.saved) or 'DEFAULT'))
            row.select:GetChildAt(0):SetText(text((snapshot.active==row.name and '> ' or '  ')..row.caption))
        end
        state.oldCursor=pc.bShowMouseCursor
        state.widget:SetVisibility(0);pc.bShowMouseCursor=true
        lib:SetInputMode_UIOnlyEx(pc,state.widget,0,false)
        state.visible=true
        log('Live HUD opened; flight continues. '..(state.shortcut or 'F9')..' closes it.')
    end
    if not state.visible or not valid(state.widget) then return end
    if state.owner~=pc:GetAddress() then close(false);return end
    if state.closeButton:IsPressed() then close();return end
    hudControls(state,hudLayout,log,false,pc)
    local pawn=pc.Pawn
    if state.switchTarget then
        local target=pawn[state.switchTarget]
        if valid(target) and target:IsActive() then
            memory.tick(pc)
            log('HUD camera selected: '..state.switchTarget)
            state.switchTarget=nil
        elseif state.switchAttempts==0 then
            local current=activeView(pawn)
            if not supported or not current or pawn.CG84CameraType~=cameraTypes[current] then
                log('Direct camera selection unavailable for this build/state; use normal view controls.')
                state.switchTarget=nil
                return
            end
            local original=pawn.CG84CameraType
            local predecessor=({[0]=2,[1]=0,[2]=1})[cameraTypes[state.switchTarget]]
            pawn.CG84CameraType=predecessor
            local ok,err=pcall(function() pawn:OnInputViewPressed() end)
            -- The native component owns the real transition. Restore the temporary
            -- lookup index unless the synchronous notification already updated it.
            if pawn.CG84CameraType==predecessor then pawn.CG84CameraType=original end
            assert(ok,err)
            state.switchAttempts=1;state.switchWait=20
        elseif state.switchWait>0 then
            state.switchWait=state.switchWait-1
        else
            log('Direct camera selection timed out; normal view controls remain available.')
            state.switchTarget=nil
        end
    end
    for _,row in ipairs(state.rows) do
        local camera=pawn[row.name]
        local isActive=valid(camera) and camera:IsActive()
        row.select:GetChildAt(0):SetText(text((isActive and '> ' or '')..row.caption))
        local selected=row.select:IsPressed()
        if selected and not row.selectPressed then
            state.switchTarget=row.name;state.switchAttempts=0;state.switchWait=0;state.switchFrom=nil
        end
        row.selectPressed=selected
        local minus=row.minus:IsPressed()
        local plus=row.plus:IsPressed()
        local direction=0
        if minus and not row.minusPressed then direction=-1 end
        if plus and not row.plusPressed then direction=1 end
        row.minusPressed=minus;row.plusPressed=plus
        if direction~=0 then
            local value=math.max(50,math.min(150,row.last+direction*5))
            if memory.set(pc,row.name,value) then
                row.last=value;row.saved=value
                row.value:SetText(text(string.format('%.1f',value)))
            end
        end
        local down=row.reset:IsPressed()
        if down and not row.pressed then
            memory.set(pc,row.name,0);row.saved=nil;row.last=90;row.dirty=false
            row.value:SetText(text('DEFAULT'))
        end
        row.pressed=down
    end
end



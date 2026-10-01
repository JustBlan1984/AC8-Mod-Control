import os, sys, re, shutil, subprocess, datetime, zipfile, json, hashlib, ctypes
from pathlib import Path
import tkinter as tk
from tkinter import ttk, filedialog, messagebox

BUNDLE=Path(getattr(sys,'_MEIPASS',Path(__file__).parent))/'bundled'
HOME=Path(os.environ['LOCALAPPDATA'])/'AC8 Mod Launcher'
BACKUPS=HOME/'Backups'
SAVE=Path(os.environ['LOCALAPPDATA'])/'BANDAI NAMCO Entertainment/ACE COMBAT 8/Saved/SaveGames'
MODS=['AC8AdjustableFOV','AC8AircraftUnlock','AC8MissionUnlock']
MISSION_OPTIONS=['Unlock ALL Missions','Prologue']+[f'Mission {n}' for n in range(1,31)]

def mission_config(mode):
    if mode in ('Unlock ALL Missions','All missions'):
        return 'return {Mode="all",CampaignAccess=true,FreeMissionAccess=true,AutoApply=true}\n'
    if mode=='Prologue': last=1
    elif mode=='Prologue through Mission 6': last=7
    elif re.fullmatch(r'Mission ([1-9]|[12][0-9]|30)',mode): last=int(mode.split()[1])+1
    else: raise ValueError('Choose a mission from the list.')
    return 'return {Mode="internal_through",ThroughID=%d,CampaignAccess=true,FreeMissionAccess=true,AutoApply=true}\n'%last
DLSS_KEYS={'r.Streamline.InitializePlugin':'1','r.Streamline.DLSSG.Enable':'1','t.Streamline.Reflex.Mode':'1'}

def dlss_toggle(enable):
    if running(): raise RuntimeError('Close the game before changing DLSS settings.')
    ini=SAVE.parent/'Config/Windows/Engine.ini'
    state=HOME/'dlss-state.json'
    HOME.mkdir(parents=True,exist_ok=True)
    if not enable:
        if not state.exists(): raise RuntimeError('No DLSS tweak from this launcher is recorded. Nothing changed.')
        data=json.loads(state.read_text())
        if str(ini)!=data['path']: raise RuntimeError('Saved configuration location does not match.')
        if not ini.exists() or hashlib.sha256(ini.read_bytes()).hexdigest()!=data['after']:
            raise RuntimeError('Engine.ini changed since enabling. Automatic restore stopped to preserve those changes. Your original is in the backup folder.')
        if data['existed']: shutil.copy2(data['backup'],ini)
        else: ini.unlink()
        state.unlink()
        return 'DLSS tweak removed; previous Engine.ini restored.'
    if state.exists(): return 'DLSS tweak is already recorded as enabled. Disable it before reapplying.'
    existed=ini.exists()
    original=ini.read_bytes() if existed else b''
    encoding='utf-16' if original.startswith((b'\xff\xfe',b'\xfe\xff')) else 'utf-8-sig'
    text=original.decode(encoding)
    lines=text.splitlines();out=[];inside=False
    for line in lines:
        section=re.match(r'^\s*\[([^]]+)\]',line)
        if section: inside=section[1].lower()=='consolevariables'
        key=line.split('=',1)[0].strip().lower()
        if inside and key in {k.lower() for k in DLSS_KEYS}: continue
        out.append(line)
    # Unreal accepts repeated sections; keep all unrelated sections untouched.
    out+=['','[ConsoleVariables]']+[k+' = '+v for k,v in DLSS_KEYS.items()]
    updated=('\r\n'.join(out)+'\r\n').encode(encoding if existed else 'utf-8')
    BACKUPS.mkdir(parents=True,exist_ok=True)
    prior=BACKUPS/('Engine-before-DLSS-'+datetime.datetime.now().strftime('%Y%m%d-%H%M%S-%f')+'.ini')
    prior.write_bytes(original)
    ini.parent.mkdir(parents=True,exist_ok=True)
    ini.write_bytes(updated)
    state.write_text(json.dumps({'path':str(ini),'existed':existed,'backup':str(prior),'after':hashlib.sha256(updated).hexdigest()}))
    return 'DLSS/Frame Generation tweak enabled. Restart and verify in-game; original settings backed up.'

def running():
    result=subprocess.run(['tasklist','/FI','IMAGENAME eq AceCombat8.exe','/FO','CSV','/NH'],capture_output=True,text=True,creationflags=0x08000000)
    if result.returncode: raise RuntimeError('Could not check whether the game is running.')
    return 'acecombat8.exe' in result.stdout.lower()

def backup():
    if running(): raise RuntimeError('Close the game before backing up or installing.')
    if not (SAVE/'Campaign.sav').is_file(): raise RuntimeError('Current Campaign.sav was not found. No changes made.')
    BACKUPS.mkdir(parents=True,exist_ok=True)
    path=BACKUPS/('Save-'+datetime.datetime.now().strftime('%Y%m%d-%H%M%S-%f')+'.zip')
    with zipfile.ZipFile(path,'w',zipfile.ZIP_DEFLATED) as z:
        for f in SAVE.rglob('*'):
            if f.is_file(): z.write(f,f.relative_to(SAVE))
    with zipfile.ZipFile(path) as z:
        if z.testzip(): raise RuntimeError('Backup verification failed.')
    return path

def install(game,choices,mode):
    binary=game/'Game/Binaries/Win64'
    if not (binary/'AceCombat8.exe').is_file(): raise RuntimeError('Select the ACE COMBAT 8 installation folder.')
    if not (binary/'ue4ss/UE4SS.dll').exists() and not (binary/'ue4ss/UE4SS-settings.ini').exists():
        raise RuntimeError('This version requires the existing working UE4SS installation. It does not install the mod loader.')
    saved=backup()
    target=binary/'ue4ss/Mods'
    stamp=HOME/('Install-backup-'+datetime.datetime.now().strftime('%Y%m%d-%H%M%S-%f'))
    stamp.mkdir(parents=True)
    config=target/'mods.txt'
    if config.exists(): shutil.copy2(config,stamp/'mods.txt')
    text=config.read_text(encoding='utf-8-sig') if config.exists() else ''
    for name,enabled in zip(MODS,choices):
        dest=target/name
        if dest.exists(): shutil.copytree(dest,stamp/name)
        if enabled:
            shutil.copytree(BUNDLE/name,dest,dirs_exist_ok=True)
        marker=dest/'enabled.txt'
        if marker.exists(): marker.rename(dest/('enabled.saved-'+datetime.datetime.now().strftime('%H%M%S%f')))
        text=re.sub(r'^\s*'+re.escape(name)+r'\s*:[^\r\n]*\r?\n?', '',text,flags=re.M)
        text+='\n'+name+' : '+('1' if enabled else '0')+'\n'
    if choices[2]:
        # Catalog numbering is not the displayed mission numbering. Limited
        # range has been verified only through displayed Mission 6.
        cfg=mission_config(mode)
        (target/MODS[2]/'Scripts/Mission-config.lua').write_text(cfg)
    config.write_text(text,encoding='utf-8')
    return saved

def main():
    app=tk.Tk();app.title('AC8 | MOD CONTROL — 1.0.0');app.geometry('820x900')
    app.minsize(760,600)
    bg='#070e0b';panel='#0b1710';green='#88d86b';muted='#adc4ae';border='#31543a'
    app.configure(bg=bg)
    style=ttk.Style(app);style.theme_use('clam')
    style.configure('.',background=panel,foreground=green,font=('Consolas',10))
    style.configure('TFrame',background=panel)
    style.configure('TLabel',background=panel,foreground=muted)
    style.configure('Title.TLabel',foreground=green,font=('Consolas',23))
    style.configure('Section.TLabel',foreground=green,font=('Consolas',11,'bold'))
    style.configure('TButton',background='#11251a',foreground=green,bordercolor=border,lightcolor=border,darkcolor=border,padding=(12,8),focuscolor=green)
    style.map('TButton',background=[('active','#244431'),('pressed','#34593a')],foreground=[('disabled','#64756a')])
    style.configure('TCheckbutton',background=panel,foreground=green,indicatorbackground=bg,indicatorforeground=green)
    style.map('TCheckbutton',background=[('active',panel)],indicatorbackground=[('selected','#315a35')])
    style.configure('TEntry',fieldbackground=bg,foreground='#d5e8cf',insertcolor=green,bordercolor=border,padding=6)
    style.configure('TCombobox',fieldbackground=bg,background='#11251a',foreground=green,arrowcolor=green,bordercolor=border,padding=6)
    style.map('TCombobox',fieldbackground=[('readonly',bg)],foreground=[('readonly',green)])
    app.option_add('*TCombobox*Listbox.background',bg);app.option_add('*TCombobox*Listbox.foreground',green)
    app.option_add('*TCombobox*Listbox.selectBackground','#31543a')
    shell=tk.Frame(app,bg=panel,highlightbackground=green,highlightthickness=1);shell.pack(fill='both',expand=True,padx=18,pady=18)
    canvas=tk.Canvas(shell,bg=panel,highlightthickness=0)
    scroll=ttk.Scrollbar(shell,orient='vertical',command=canvas.yview);scroll.pack(side='right',fill='y')
    canvas.pack(side='left',fill='both',expand=True);canvas.configure(yscrollcommand=scroll.set)
    frame=ttk.Frame(canvas,padding=22);window=canvas.create_window((0,0),window=frame,anchor='nw')
    frame.bind('<Configure>',lambda e:canvas.configure(scrollregion=canvas.bbox('all')))
    canvas.bind('<Configure>',lambda e:canvas.itemconfigure(window,width=e.width))
    canvas.bind_all('<MouseWheel>',lambda e:canvas.yview_scroll(-int(e.delta/120),'units'))
    def section(text):
        ttk.Separator(frame).pack(fill='x',pady=(14,9))
        ttk.Label(frame,text='[ '+text+' ]',style='Section.TLabel').pack(anchor='w',pady=(0,7))
    ttk.Label(frame,text='[ AC8 / MOD CONTROL ]',style='Title.TLabel').pack(anchor='w')
    ttk.Label(frame,text='CRIMINALGAMER84 MODS   /   v1.0.0',style='Section.TLabel').pack(anchor='w',pady=(4,0))
    ttk.Label(frame,text='Configure once. Load your campaign, then let the game save normally.').pack(anchor='w',pady=(6,18))
    tk.Label(frame,text='[ CAUTION / USE AT YOUR OWN RISK ]\nThese mods are intended for offline / single-player use. Online use is not recommended and may result in account restrictions or bans. You are responsible for how you use them.',bg=panel,fg='#e3bb70',justify='left',wraplength=680,font=('Consolas',10)).pack(anchor='w',pady=(0,14))
    section('INSTALLATION')
    game=tk.StringVar(value=r'D:\SteamLibrary\steamapps\common\ACE COMBAT 8')
    ttk.Label(frame,text='Game installation folder').pack(anchor='w')
    row=ttk.Frame(frame);row.pack(fill='x');ttk.Entry(row,textvariable=game,width=65).pack(side='left',fill='x',expand=True)
    ttk.Button(row,text='Browse',command=lambda: game.set(filedialog.askdirectory() or game.get())).pack(side='right')
    section('MOD SELECTION')
    options=[tk.BooleanVar(value=True) for _ in MODS]
    for label,var in zip(['FOV overlay — F10 in flight','Aircraft, skins and SP weapons — automatic repair','Mission access'],options):
        ttk.Checkbutton(frame,text=label,variable=var).pack(anchor='w',pady=7)
    mode=tk.StringVar(value='Unlock ALL Missions')
    ttk.Combobox(frame,textvariable=mode,values=MISSION_OPTIONS,state='readonly',width=32,height=12).pack(anchor='w')
    ttk.Label(frame,text='Also enables Free Mission, Free Flight, Training, Music Player and Data Viewer.\nExisting later unlocks remain. Cutoffs after Mission 6 still need in-game verification.',wraplength=650).pack(anchor='w',pady=5)
    section('LAUNCH MODE')
    no_eac=tk.BooleanVar(value=False)
    ttk.Checkbutton(frame,text='No EAC launch — offline / single-player mods',variable=no_eac).pack(anchor='w',pady=(14,4))
    ttk.Label(frame,text='Unchecked: launch through Steam using its existing launch settings.\nThis option does not remove EAC or change Steam settings.',wraplength=625).pack(anchor='w')
    ttk.Label(frame,text='Existing unlocks are not removed when an option is unchecked.\nLoad your campaign after applying. Aircraft loadouts populate as the hangar initializes.\nRequires a working UE4SS installation.',wraplength=625).pack(anchor='w',pady=14)
    status=tk.StringVar(value='Game must be closed. Your current save is backed up before installation.')
    def action(fn):
        try: fn()
        except Exception as e: messagebox.showerror('AC8 Mod Launcher',str(e))
    def save_only(): status.set('Backup saved: '+str(backup()))
    section('DLSS / GRAPHICS')
    dlssrow=ttk.Frame(frame);dlssrow.pack(fill='x',pady=8)
    ttk.Button(dlssrow,text='Enable DLSS',command=lambda:action(lambda:status.set(dlss_toggle(True)))).pack(side='left')
    ttk.Button(dlssrow,text='Disable DLSS tweak',command=lambda:action(lambda:status.set(dlss_toggle(False)))).pack(side='left',padx=8)
    ttk.Label(frame,text='For use without a DLSS swapper. Applies Streamline / Frame Generation / Reflex INI settings.\nDoes not install DLSS or guarantee an upscaling menu option.',wraplength=630).pack(anchor='w')
    def apply():
        saved=install(Path(game.get()),[v.get() for v in options],mode.get())
        status.set('Installed. Backup: '+saved.name+'. Launch and load your campaign to apply.')
    def launch():
        if running(): raise RuntimeError('Game is already running.')
        if not no_eac.get():
            os.startfile('steam://rungameid/2288340')
            status.set('Launch requested through Steam using your existing settings.')
            return
        exe=Path(game.get())/'Game/Binaries/Win64/AceCombat8.exe'
        if not exe.is_file(): raise RuntimeError('Game executable not found.')
        env=os.environ.copy();env.update(SteamAppId='2288340',SteamGameId='2288340')
        for key in list(env):
            if key.startswith('_PYI_') or key=='_MEIPASS2': env.pop(key)
        # Do not let the game inherit the one-file launcher's extracted DLL path.
        frozen=getattr(sys,'frozen',False)
        if frozen: ctypes.windll.kernel32.SetDllDirectoryW(None)
        try:
            subprocess.Popen([str(exe),'-SaveToUserDir'],cwd=exe.parent,env=env,close_fds=True)
        finally:
            if frozen: ctypes.windll.kernel32.SetDllDirectoryW(str(sys._MEIPASS))
        status.set('Direct single-player mod launch requested without the EAC launcher.')
    section('SAVE BACKUP / APPLY')
    buttons=ttk.Frame(frame);buttons.pack(fill='x',pady=8)
    ttk.Button(buttons,text='Back Up Current Save',command=lambda:action(save_only)).pack(side='left')
    ttk.Button(buttons,text='Open Backups',command=lambda:(BACKUPS.mkdir(parents=True,exist_ok=True),os.startfile(BACKUPS))).pack(side='left',padx=8)
    ttk.Button(buttons,text='Apply Selected Mods',command=lambda:action(apply)).pack(side='left')
    ttk.Button(frame,text='Launch Game',command=lambda:action(launch)).pack(anchor='w',pady=6)
    ttk.Label(frame,textvariable=status,wraplength=630).pack(anchor='w',pady=8)
    app.mainloop()

if __name__=='__main__': main()

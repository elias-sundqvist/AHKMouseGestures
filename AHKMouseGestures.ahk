#WinActivateForce
#SingleInstance Force
SetWinDelay, 0

; Ensure that script is run as administrator so that 
; no other program can prevent your clicks from working. 
SetWorkingDir %A_ScriptDir%
if not A_IsAdmin
	Run *RunAs "%A_ScriptFullPath%"


;------------------------ USER CONFIG ----------------------------

GetMouseGestureWindow() {
	cursor_info := new CursorInfo()
	if (cursor_info.window.process_name == "firefox.exe") {
		return new FirefoxWindow(cursor_info)
	}
	if (cursor_info.window.process_name == "Adobe Premiere Pro.exe") {
		return new AdobePremiereWindow(cursor_info)
	}
	if (cursor_info.window.window_class == "CabinetWClass") {
		return new ExplorerWindow(cursor_info)
	}
}

Class AdobePremiereWindow extends MouseGestureWindow {
	RButton_D() {
		this.start_window.Focus()
		Send, ^k
	}
	RButton_DR() {
		this.start_window.Focus()
		Send, {Delete}
	}
}

Class ExplorerWindow extends MouseGestureWindow {
	
	RButton__WheelUp() {
		this.start_window.Focus()
		Send {LControl down}{LWin down}ö{LWin up}{LControl up}
	}

	RButton__WheelDown() {
		this.start_window.Focus()
		Send, #ö
	}
}

Class FirefoxWindow extends MouseGestureWindow {
	RButton_U() {
		this.start_window.Focus()
		Send, ^l
	}

	RButton_D() {
		this.start_window.Focus()
		i := this.cursor_info
		fi := this.final_cursor_info

		cursor_type := i.cursor_type
		if(cursor_type == "Unknown") {
			BlockInput On
			MouseMove, i.cursor_x, i.cursor_y, 0
			Send, +{MButton}
			KeyWait, MButton
			KeyWait, MButton, L
			MouseMove, fi.cursor_x, fi.cursor_y, 0
			BlockInput Off
		}
	}

	RButton_UD() {
		this.start_window.Focus()
		Send, {F5}
	}

	RButton_RU() {
		this.start_window.Focus()
		Send, +^t
	}

	RButton_DR() {
		this.start_window.Focus()
		Send, ^w
	}

	RButton_RUR() {
		this.start_window.Focus()
		Send, ^t
	}

	RButton_DLU() {
		this.start_window.Focus()
		send, ^j
	}
	
	RButton__WheelUp() {
		this.start_window.Focus()
		Send, +^{Tab}
	}

	RButton__WheelDown() {
		this.start_window.Focus()
		Send, ^{Tab}
	}

	LButtonRButton_() {
		this.start_window.Focus()
		Send, !{Right}
	}

	RButton__LButton() {
		this.start_window.Focus()
		Send, !{Left}
	}

	RButton__MButton() {
		this.start_window.Focus()
		Send, !p
	}
}








;------------------------- FRAMEWORK ------------------------------


global yield := true

kb := new AllKeyBinder(Func("MyFunc"))
return

Class MouseBehaviour 
{
    RButtonDown() {
		prefix := ""
		if (this.isLButtonDown) {
			prefix := prefix "LButton"
		}
		prefix := prefix "RButton_"
		this.prefix := prefix

		this.mouseGestureWindow := GetMouseGestureWindow()
		mgw := this.mouseGestureWindow
		if(!this.mouseGestureWindow) 
		{
			return yield
		}

		if (isFunc(mgw[prefix])) 
		{
			this.performedSpecial := 1
			mgw[prefix]()
			return 
		}

		this.GetMouseGesture(True)
		While this.isRButtonDown {
			this.gesture := this.GetMouseGesture()
			Sleep 40
		}
	}

	RButtonUp() {
		mgw := this.mouseGestureWindow
		if(this.performedSpecial) 
		{
			this.performedSpecial := 0
			return 
		}
		if(!mgw) 
		{
			return yield
		}
		if(!this.gesture) 
		{
			Send, {RButton Down}
			return yield
		}
		methodName := this.prefix this.gesture
		cursor_info := new CursorInfo()
		mgw.SetFinalCursorInfo(cursor_info)
		(IsFunc(mgw[methodName]) > 0) ? mgw[methodName](mgw) : ""
		this.prefix := ""
		this.gesture := this.GetMouseGesture(True)
	}

	GenericKeyDown(keyName) {
		mgw := this.mouseGestureWindow
		methodName := this.prefix this.gesture "_" keyName
		if(this.isRButtonDown && IsFunc(mgw[methodName])) 
		{
			this.performedSpecial := 1
            mgw[methodName]()
			return
		}
		return yield
	}

	GetMouseGesture(reset := false){
		Static
		mousegetpos,xpos2, ypos2
		dx:=xpos2-xpos1,dy:=ypos1-ypos2
		,( abs(dy) >= abs(dx) ? (dy > 0 ? (track:="u") : (track:="d")) : (dx > 0 ? (track:="r") : (track:="l")) )
		,abs(dy)<4 and abs(dx)<4 ? (track := "") : ""
		,xpos1:=xpos2,ypos1:=ypos2
		,track<>SubStr(gesture, 0, 1) ? (gesture := gesture . track) : ""
		,gesture := reset ? "" : gesture
		Return gesture
	}
}

global mouseBehaviour := new MouseBehaviour()


MyFunc(type, code, name, state){
    ; Tooltip % "Type: " type ", Code: " code ", Name: " name ", State: " state

    ;instant-press (down and up not separate)
    if (state==2) {
        if (isFunc(mouseBehaviour[name]) ? mouseBehaviour[name]() : mouseBehaviour.GenericKeyDown(name))
        {
		    send, {%name%}
        }
	}
    else if (state == 1) {
        KeyWait, %name%, D
		mouseBehaviour["is" name "Down"] := 1
        if(isFunc(mouseBehaviour[name "Down"]) ? mouseBehaviour[name "Down"]() : mouseBehaviour.GenericKeyDown(name))
        {
		    send, {%name% Down}
        }
    } else if(state == 0){
        KeyWait, %name%
		mouseBehaviour["is" name "Down"] := 0
        if((!isFunc(mouseBehaviour[name "Up"])) || mouseBehaviour[name "Up"]()) 
        {
		    send, {%name% Up}
        }
    }
}


;::: The Wheel[Up/Down] keys are special (They can't be held down) and are not covered by the AllKeyBinder

class AllKeyBinder{
    __New(callback, pfx := "$"){
        static mouseButtons := ["LButton", "RButton", "MButton", "XButton1", "XButton2"]
		static wheelHotkeys := ["WheelUp", "WheelDown"]
        keys := {}
        this.Callback := callback
        ; Loop 512 {
        ;     i := A_Index
        ;     code := Format("{:x}", i)
        ;     n := GetKeyName("sc" code)
        ;     if (!n || keys.HasKey(n))
        ;         continue
        ;     keys[n] := code
        ;     
        ;     fn := this.KeyEvent.Bind(this, "Key", i, n, 1)
        ;     hotkey, % pfx "SC" code, % fn, On
        ;     
        ;     fn := this.KeyEvent.Bind(this, "Key", i, n, 0)
        ;     hotkey, % pfx "SC" code " up", % fn, On             
        ; }
        
        for i, k in mouseButtons {
            fn := this.KeyEvent.Bind(this, "Mouse", i, k, 1)
            hotkey, % pfx k, % fn, On
            
            fn := this.KeyEvent.Bind(this, "Mouse", i, k, 0)
            hotkey, % pfx k " up", % fn, On             
        }

		for i, k in wheelHotkeys {
            fn := this.KeyEvent.Bind(this, "Mouse", 5 + i, k, 2)
            hotkey, % pfx k, % fn, On         
        }
    }
    
    KeyEvent(type, code, name, state){
        this.Callback.Call(type, code, name, state)
    }
   
}

Class MouseGestureWindow {
	__New(cursor_info) {
		this.cursor_info := cursor_info
		this.start_window := cursor_info.window
	}

	SetFinalCursorInfo(cursor_info) {
		this.final_cursor_info := cursor_info
		this.final_window := cursor_info.window
	}
}

class CursorInfo {
	__New() {
		CoordMode Mouse, Screen
		CoordMode Pixel, Screen
		MouseGetPos, cursor_x, cursor_y, win_umid, window_control	
		this.window := new CursorInfo.WindowRef(win_umid, window_control)	
		this.cursor_x := cursor_x 
		this.cursor_y := cursor_y
		this.cursor_type := A_Cursor
	}

	class WindowRef {
		__New(win_umid, window_control) {
			WinGetTitle title, ahk_id %win_umid%
			WinGetClass window_class, ahk_id %win_umid%
			WinGetPos x_pos, y_pos, width, height, ahk_id %win_umid%
			WinGet process_name, ProcessName, ahk_id %win_umid%
			WinGet process_id, PID, ahk_id %win_umid%

			this.win_umid := win_umid
			this.window_class := window_class
			this.title := title
			this.window_control := window_control
			this.x_pos := x_pos
			this.y_pos := y_pos
			this.width := width
			this.height := height
			this.process_id := PID
			this.process_name := process_name
		}

		Focus() {
			win_umid := this.win_umid
			Winactivate, ahk_id %win_umid%
		}
	}
}
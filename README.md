# AHKMouseGestures
An AutoHotkey script for custom mouse gestures


## Usage

### Installation 

The only dependency for this script is AutoHotkey, which can be installed [here](https://www.autohotkey.com/)

The script can then simply be run by double clicking the file `AHKMouseGestures.ahk`.

To automaticaly run the script on startup. Press `CTRL+R`, write `shell:startup` and press `Enter`. In the folder that pops up, either put the script there directly, or create a shortcut to the script and place it there. 

> Note: The script automatically runs as administrator. This is strongly reccommended, since otherwise bugs can occur which lock up the mouse when running the script while over windows of higher authority. But if you are willing to risk that, feel free to remove lines 5-9. 

### Configuring custom gestures

The code relevant for configuring gestures can be found below the line:

`;------------------------ USER CONFIG ----------------------------`


To configure mouse gestures for a program, two steps are necessary.
1. Create a `MouseGestureWindow` subclass
2. Add a condition to `GetMouseGestureWindow()` for when to use the afforementioned class. 

The script currently has some windows already implemented for Adobe Premiere, WindowsExplorer, and Firefox, which can serve as examples. 
If you do not like these gestures, simply remove the window classes and their associated lines in the `GetMouseGestureWindow()` function. 


**1. Create a `MouseGestureWindow` subclass**

A new `MouseGestureWindow` subclass can be created by writing
```autohotkey
Class NameOfProgramWindow extends MouseGestureWindow {...}
```

In this class, each gesture is defined as a function. 
The function naming syntax can be described with the following regular expression `(LButton)?RButton_[ULRD]*(_((RButton)|(MButton)|(XButton1)|(XButton2)|(WheelUp)|(WheelDown)))?`. 
> Note: This is subject to change for future version. It could for example be nice to have support for keyboard buttons as well, or for using other buttons than RButton for the gesture

The function body can contain anything that a regular autohotkey script can. One recommendation, however, is to start the function with `this.start_window.Focus()`, to ensure that any commands sent are received by the correct window. 

Below are some paricularily useful examples:

```autohotkey
Class NameOfProgramWindow extends MouseGestureWindow {
	; While holding the right mouse button, do a gesture down, then right, and release. 
    ; This gesture is commonly used for closing tabs in browsers etc. 
	RButton_DR() {
		this.start_window.Focus()
		Send, ^w
	}
    
    ; Hold right mouse button and scroll. Each time the scroll wheel moves, the function is called. 
    ; This gesture is commonly used for switching between tabs.
	RButton__WheelUp() {
		this.start_window.Focus()
		Send, +^{Tab}
	}

	RButton__WheelDown() {
		this.start_window.Focus()
		Send, ^{Tab}
	}
    
    
    ; Hold right mouse button and press the left, or vice-versa. 
    ; This is commonly refered to as "rocker gestures" and can
    ; for example be used for navigating back and forth in history.
    
	LButtonRButton_() {
		this.start_window.Focus()
		Send, !{Right}
	}

	RButton__LButton() {
		this.start_window.Focus()
		Send, !{Left}
	}
}
```


**2. Add a condition to `GetMouseGestureWindow()` for when to use the afforementioned class. **

The `GetMouseGestureWindow()` function looks like this
```autohotkey
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
```

The role of this function is to figure out which `MouseGestureWindow` subclass should be used in the current situation. 
As seen in this example, the most useful property to base this decision on is probably `cursor_info.window.process_name`.
This is the process name of the window on which the gesture started. 

However, the possibilities here are almost endless, and the `cursor_info` object contains a lot of information. 
Here is a brief api reference for the `cursor_info` object:
```typescript
type CursorInfo = {
 window: {
    win_umid: HWND; // a unique reference to the window, see  https://www.autohotkey.com/docs/commands/ControlGet.htm#Hwnd
    window_class: ClassNN; // The class name of the window contol
    title: string; // the title of the window
    x_pos: number; // the x-position of the window
    y_pos: number; // the y-position of the window
    width: number; // the width of the window
    height: number; // the height of the window
    process_id: PID;  // the uniquely identifying id of the process that manages the window
    process_name: string; // the name of the process that manages the window, such as "notepad.exe"
 };
 cursor_x: number; //the x-position of the cursor
 cursor_y: number; //the y-position of the cursor
 cursor_type: A_Cursor; //The type of mouse cursor currently being displayed. It will be one of the following words: AppStarting, Arrow, Cross, Help, IBeam, Icon, No, Size, SizeAll, SizeNESW, SizeNS, SizeNWSE, SizeWE, UpArrow, Wait, Unknown. The acronyms used with the size-type cursors are compass directions, e.g. NESW = NorthEast+SouthWest. The hand-shaped cursors (pointing and grabbing) are classified as Unknown.
}
```

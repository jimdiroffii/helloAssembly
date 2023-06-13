;
; Hello, Windows! in x86 ASM
; 

; Compiler directives and includes

.386								; Full 80386 instruction set and mode
.model flat, stdcall						; All 32-bit and later apps are flat. Used to include "tiny, etc"
option casemap:none						; Preserve the case of system identifiers but not our own, more or less

; Include files - headers and libs that we need for calling the system dlls like user32, gdi32, kernel32, etc

include d:\masm32\include\windows.inc				; Main windows header file (akin to Windows.h in C)
include d:\masm32\include\user32.inc				; Windows, controls, etc
include d:\masm32\include\kernel32.inc				; Handles, modules, paths, etc
include d:\masm32\include\gdi32.inc				; Drawing into a device context (ie: painting)

; Libs - information needed to link our binary to the system DLL calls

includelib d:\masm32\lib\kernel32.lib				; Kernel32.dll
includelib d:\masm32\lib\user32.lib				; User32.dll
includelib d:\masm32\lib\gdi32.lib				; GDI32.dll

; Forward declarations - Our main entry point will call forward to WinMain, so we need to define it here, etc.

WinMain proto :DWORD, :DWORD, :DWORD, :DWORD			; Forward decl for MainEntry

; Constants and Data

WindowWidth	equ 640						; Size of the main window
WindowHeight	equ 480

.DATA

ClassName	db	"MyWinClass", 		0		; The name of our Window class
AppName		db	"Jim's Tiny App", 	0		; The name of our main window

.Data?								; Uninitialized - basically reserves some space

hInstance	HINSTANCE 	?				; Instance handle (like the process id) of our application
CommandLine	LPSTR 		?				; Pointer to the command line text we were launched with

;
.CODE								; Here is where the program resides
;

MainEntry:
	push	NULL						; Get the instance handle of our app (NULL means ourselves)
	call	GetModuleHandle					; GetModuleHandle will return isntance handle in EAX, etc
	mov	hInstance, eax					; Cache it in our global variable

	call	GetCommandLine					; Get the command line text ptr in EAX to pass on to main
	mov	CommandLine, eax

	; Call our WinMain and then exit the process with whatever comes back
	push	SW_SHOWDEFAULT
	lea	eax, CommandLine
	push	eax
	push	NULL
	push	hInstance
	call 	WinMain

	push	eax
	call	ExitProcess

;
; WinMain - The traditional signature for the main entry point of a Windows program
;

WinMain proc hInst:HINSTANCE, hPrevInst:HINSTANCE, CmdLine:LPSTR, CmdShow:DWORD

	LOCAL	wc:WNDCLASSEX					; Create these vars on the stack, hence LOCAL
	LOCAL	msg:MSG
	LOCAL	hwnd:HWND

	mov 	wc.cbSize, SIZEOF WNDCLASSEX			; Fill in the values in the members of our windowclass
	mov	wc.style, CS_HREDRAW or CS_VREDRAW		; Redraw if resized in either dimension
	mov	wc.lpfnWndProc, OFFSET WndProc			; Our callback function to handle window messages
	mov 	wc.cbClsExtra, 0				; No extra class data
	mov 	wc.cbWndExtra, 0				; No extra window data
	mov	eax, hInstance
	mov	wc.hInstance, eax				; Our instance handle
	mov	wc.hbrBackground, COLOR_3DSHADOW+1		; Default brush colors are color plus one
	mov	wc.lpszMenuName, NULL				; No app menu
	mov 	wc.lpszClassName, OFFSET ClassName		; The window's class name

	push	IDI_APPLICATION					; Use the default application icon
	push	NULL
	call	LoadIcon
	mov	wc.hIcon, eax
	mov	wc.hIconSm, eax

	push	IDC_ARROW					; Get the default cursor
	push	NULL
	call	LoadCursor
	mov	wc.hCursor, eax

	lea	eax, wc
	push 	eax
	call	RegisterClassEx					; Register the window class

	push	NULL						; Bonus data, but we have none
	push	hInstance					; Our app instance handle
	push	NULL						; Menu Handle
	push 	NULL						; Parent window
	push	WindowHeight					; Our requested height
	push	WindowWidth					; Our requested width
	push	CW_USEDEFAULT					; Y
	push	CW_USEDEFAULT					; X
	push	WS_OVERLAPPEDWINDOW + WS_VISIBLE		; Window style
	push	OFFSET AppName					; Window title
	push	OFFSET ClassName				; Window class
	push	0						; Extended style
	call	CreateWindowExA
	cmp	eax, NULL
	je	WinMainRet					; Fail and bail
	mov	hwnd, eax

	push	eax						; Force a paint of the window
	call	UpdateWindow

MessageLoop:
	push	0
	push	0
	push	NULL
	lea	eax, msg
	push	eax
	call	GetMessage					; Get a message from the app's message queue

	cmp	eax, 0						; When GetMessage returns 0, exit
	je	DoneMessages

	lea	eax, msg					; Translate msg
	push	eax
	call	TranslateMessage

	lea	eax, msg					; Dispatch msg
	push	eax
	call	DispatchMessage

	jmp	MessageLoop

DoneMessages:
	mov	eax, msg.wParam					; return wParam

WinMainRet:

	ret

WinMain endp

;
; WndProc - Our main Window Procedure, handles painting and exiting
;

WndProc proc hWnd:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM

	LOCAL	ps:PAINTSTRUCT				; Local stack variable
	LOCAL	rect:RECT
	LOCAL	hdc:HDC

	cmp	uMsg, WM_DESTROY
	jne	NotWMDestroy

	push 	NULL					; WM_DESTROY received
	call	PostQuitMessage				; Quit our application
	xor	eax, eax				; Return 0 to indicate exit
	ret

NotWMDestroy:

	cmp	uMsg, WM_PAINT
	jne	NotWMPaint

	lea	eax, ps					; WM_PAINT received
	push	eax
	push	hWnd
	call	BeginPaint				; Go Get a device context to paint into
	mov	hdc, eax

	push	TRANSPARENT
	push	hdc
	call	SetBkMode				; Make text have a transparent background

	lea	eax, rect				; Figure out how big
	push	eax					; can center our
	push	hWnd
	call	GetClientRect

	push	DT_SINGLELINE + DT_CENTER + DT_VCENTER
	lea	eax, rect
	push	eax
	push	-1
	push	OFFSET AppName
	push	hdc
	call	DrawText				; Draw text centered

	lea	eax, ps
	push	eax
	push	hWnd
	call	EndPaint				; Wrap up painting

	xor	eax, eax				; Return 0 as no further processing needed
	ret

NotWMPaint:

	push	lParam
	push	wParam
	push	uMsg
	push	hWnd
	call	DefWindowProc				; Forward message
	ret						; return whatever it does

WndProc endp

END MainEntry						; Specify entry point, else _WinMainCRTStartup is assumed



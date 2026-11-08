
;================================================================
; AsmLucentTB
; Transparent Windows Taskbar
;
; Architecture: x86-64
; Assembler:    FASM 1.73+
; Format:       PE64 GUI
;
; Features:
;   - Windows 10 / 11 taskbar transparency
;   - Primary and secondary taskbars
;   - TranslucentTB process detection
;   - TranslucentTB process termination
;   - TranslucentTB installation detection
;   - TranslucentTB Run registry cleanup
;   - AsmLucentTB autostart installation
;   - Optional autostart confirmation
;   - ICO resource
;
;================================================================

format PE64 GUI 5.0
include 'C:\Tools\FASM\INCLUDE\WIN64A.INC'
entry start

;================================================================
; CONSTANTS
;================================================================

ACCENT_ENABLE_TRANSPARENTGRADIENT = 2
WCA_ACCENT_POLICY                 = 19

REG_SZ                            = 1
KEY_SET_VALUE                     = 2

MAX_PATH_BUFFER                   = 520
POLL_INTERVAL                     = 500

HKEY_CURRENT_USER_VALUE           = 0FFFFFFFF80000001h

TH32CS_SNAPPROCESS                = 2
PROCESS_TERMINATE                 = 1

INVALID_HANDLE_VALUE              = 0FFFFFFFFFFFFFFFFh
INVALID_FILE_ATTRIBUTES           = 0FFFFFFFFh

MB_YESNO                          = 4
MB_ICONQUESTION                   = 20h
MB_ICONERROR                      = 10h

IDYES                             = 6

EXE_NAME_LEN                      = 260

; PROCESSENTRY32W x64:
; 44-byte header + 520-byte filename + 4-byte alignment
PROCESSENTRY32W_SIZE              = 568

;================================================================
; DATA
;================================================================

section '.data' data readable writeable

;------------------------------------------------
; API names
;------------------------------------------------

szUser32        du 'user32.dll',0
szSetWindow     db 'SetWindowCompositionAttribute',0

;------------------------------------------------
; Taskbar window classes
;------------------------------------------------

szTaskbar       du 'Shell_TrayWnd',0
szSecondary     du 'Shell_SecondaryTrayWnd',0

;------------------------------------------------
; Registry
;------------------------------------------------

szRunKey        du 'Software\Microsoft\Windows\CurrentVersion\Run',0

; Keep old value name for compatibility with
; previous AsmTaskbar builds.
szValueName     du 'AsmTaskbar',0

szTTBValue1     du 'TranslucentTB',0
szTTBValue2     du 'TranslucentTB.exe',0

;------------------------------------------------
; TranslucentTB process
;------------------------------------------------

szTTBProcess    du 'TranslucentTB.exe',0

;------------------------------------------------
; TranslucentTB installation path
;
; This is the package path supplied in the
; original project source.
;
; Process detection and registry detection
; work independently of this path.
;------------------------------------------------

szTTBPath       du 'C:\Program Files\WindowsApps\28017CharlesMilette.TranslucentTB_2026.2.0.0_x64__v826wp6bftszj\TranslucentTB.exe',0

;------------------------------------------------
; Messages
;------------------------------------------------

szMsgTitle      du 'AsmLucentTB',0

szMsgAsk        du 'TranslucentTB was not detected.',13,10,'Add AsmLucentTB to Windows startup?',0

szMsgReplaced   du 'TranslucentTB was detected.',13,10,'Its process was stopped when possible.',13,10,'Its Run entries were removed.',13,10,'AsmLucentTB autostart was configured.',0

szMsgError      du 'Failed to initialize AsmLucentTB.',0

szMsgAutostartError du 'Failed to install AsmLucentTB autostart.',13,10,'Check registry permissions.',0

;------------------------------------------------
; Accent policy
;------------------------------------------------

accentPolicy:

    dd ACCENT_ENABLE_TRANSPARENTGRADIENT
    dd 2
    dd 00000000h
    dd 0

;------------------------------------------------
; WINDOWCOMPOSITIONATTRIBDATA
;------------------------------------------------

compositionData:

    dd WCA_ACCENT_POLICY
    dd 0
    dq accentPolicy
    dq 16

;------------------------------------------------
; Global variables
;------------------------------------------------

pSetWindowCompositionAttribute dq 0

hUser32      dq 0
hRegistry    dq 0
hSnapshot    dq 0
hProcess     dq 0

hTaskbar     dq 0

pathLength   dd 0
disposition  dd 0

foundTTB     dd 0

;------------------------------------------------
; Buffers
;------------------------------------------------

pathBuffer   rw MAX_PATH_BUFFER
runPath      rw (MAX_PATH_BUFFER + 2)

;------------------------------------------------
; PROCESSENTRY32W
;
; x64 memory layout:
;
; +0   DWORD dwSize
; +4   DWORD cntUsage
; +8   DWORD th32ProcessID
; +12  DWORD alignment
; +16  ULONG_PTR th32DefaultHeapID
; +24  DWORD th32ModuleID
; +28  DWORD cntThreads
; +32  DWORD th32ParentProcessID
; +36  LONG pcPriClassBase
; +40  DWORD dwFlags
; +44  WCHAR szExeFile[260]
; +564 DWORD padding
;
; Total: 568 bytes
;------------------------------------------------

pe32:

    .dwSize              dd PROCESSENTRY32W_SIZE
    .cntUsage            dd 0
    .th32ProcessID       dd 0
    .pad0                dd 0

    .th32DefaultHeapID   dq 0

    .th32ModuleID        dd 0
    .cntThreads          dd 0
    .th32ParentProcessID dd 0

    .pcPriClassBase      dd 0
    .dwFlags             dd 0

    .szExeFile           rw EXE_NAME_LEN

    .padding             dd 0

;================================================================
; CODE
;================================================================

section '.text' code readable executable

;================================================================
; INITIALIZE
;
; Loads SetWindowCompositionAttribute.
;
; EAX = 0 success
; EAX = 1 failure
;================================================================

Initialize:

    sub rsp, 28h

    ; Load user32.dll

    lea rcx, [szUser32]

    call [LoadLibraryW]

    test rax, rax
    jz .failed

    mov [hUser32], rax

    ; Get API address

    mov rcx, rax

    lea rdx, [szSetWindow]

    call [GetProcAddress]

    test rax, rax
    jz .failed

    mov [pSetWindowCompositionAttribute], rax

    xor eax, eax

    add rsp, 28h

    ret


.failed:

    mov eax, 1

    add rsp, 28h

    ret


;================================================================
; CHECK TRANSLUCENTTB INSTALLATION
;
; EAX = 1 installed
; EAX = 0 not found
;================================================================

CheckTTBInstalled:

    sub rsp, 28h

    lea rcx, [szTTBPath]

    call [GetFileAttributesW]

    cmp eax, INVALID_FILE_ATTRIBUTES

    sete al

    xor al, 1

    movzx eax, al

    add rsp, 28h

    ret


;================================================================
; KILL TRANSLUCENTTB
;
; Searches all processes for TranslucentTB.exe.
;
; foundTTB = 1 if process was detected.
;================================================================

KillTranslucentTB:

    push rbx
    push rsi
    push rdi

    sub rsp, 20h

    mov dword [foundTTB], 0

    mov qword [hSnapshot], 0
    mov qword [hProcess], 0

    ; Create process snapshot

    mov ecx, TH32CS_SNAPPROCESS

    xor edx, edx

    call [CreateToolhelp32Snapshot]

    cmp rax, INVALID_HANDLE_VALUE

    je .done

    mov [hSnapshot], rax

    ; Initialize structure

    mov dword [pe32.dwSize], PROCESSENTRY32W_SIZE

    ; Get first process

    mov rcx, [hSnapshot]

    lea rdx, [pe32]

    call [Process32FirstW]

    test eax, eax

    jz .close_snapshot


.process_loop:

    ; Compare executable name

    lea rcx, [pe32.szExeFile]

    lea rdx, [szTTBProcess]

    call [lstrcmpiW]

    test eax, eax

    jnz .next_process

    ; TranslucentTB detected

    mov dword [foundTTB], 1

    ; Open process

    mov ecx, PROCESS_TERMINATE

    xor edx, edx

    mov r8d, [pe32.th32ProcessID]

    call [OpenProcess]

    test rax, rax

    jz .next_process

    mov [hProcess], rax

    ; Terminate process

    mov rcx, rax

    xor edx, edx

    call [TerminateProcess]

    test eax, eax

    jz .close_process

    ; Wait for process termination

    mov rcx, [hProcess]

    mov edx, 5000

    call [WaitForSingleObject]


.close_process:

    mov rcx, [hProcess]

    call [CloseHandle]

    mov qword [hProcess], 0


.next_process:

    mov rcx, [hSnapshot]

    lea rdx, [pe32]

    call [Process32NextW]

    test eax, eax

    jnz .process_loop


.close_snapshot:

    mov rcx, [hSnapshot]

    call [CloseHandle]

    mov qword [hSnapshot], 0


.done:

    add rsp, 20h

    pop rdi
    pop rsi
    pop rbx

    ret


;================================================================
; DELETE REGISTRY VALUE
;
; RCX = value name
;
; Opens HKCU Run key when necessary.
;
; EAX = Windows registry status.
;================================================================

DeleteRunValue:

    push rbx

    sub rsp, 30h

    mov rbx, rcx

    ; Check if registry handle is already open

    cmp qword [hRegistry], 0

    jne .have_key

    ; RegOpenKeyExW(
    ;   HKEY_CURRENT_USER,
    ;   RunKey,
    ;   0,
    ;   KEY_SET_VALUE,
    ;   &hRegistry
    ; )

    mov rcx, HKEY_CURRENT_USER_VALUE

    lea rdx, [szRunKey]

    xor r8d, r8d

    mov r9d, KEY_SET_VALUE

    lea rax, [hRegistry]

    mov qword [rsp+20h], rax

    call [RegOpenKeyExW]

    test eax, eax

    jnz .done


.have_key:

    ; Delete requested value

    mov rcx, [hRegistry]

    mov rdx, rbx

    call [RegDeleteValueW]


.done:

    add rsp, 30h

    pop rbx

    ret


;================================================================
; REMOVE TRANSLUCENTTB AUTOSTART
;
; Removes both possible Run values:
;
;   TranslucentTB
;   TranslucentTB.exe
;
; foundTTB = 1 if any value existed.
;================================================================

RemoveTTBAutostart:

    sub rsp, 28h

    ; First registry value

    lea rcx, [szTTBValue1]

    call DeleteRunValue

    test eax, eax

    jnz .second

    mov dword [foundTTB], 1


.second:

    ; Second registry value

    lea rcx, [szTTBValue2]

    call DeleteRunValue

    test eax, eax

    jnz .close

    mov dword [foundTTB], 1


.close:

    ; Close registry handle

    cmp qword [hRegistry], 0

    je .out

    mov rcx, [hRegistry]

    call [RegCloseKey]

    mov qword [hRegistry], 0


.out:

    add rsp, 28h

    ret


;================================================================
; INSTALL AUTOSTART
;
; Writes:
;
; HKCU\Software\Microsoft\Windows\CurrentVersion\Run
;
; AsmTaskbar = "full\path\to\AsmLucentTB.exe"
;
; EAX = ERROR_SUCCESS on success.
;================================================================

InstallAutostart:

    push rbx
    push rsi
    push rdi

    sub rsp, 50h

    ; Get current EXE path

    xor ecx, ecx

    lea rdx, [pathBuffer]

    mov r8d, MAX_PATH_BUFFER

    call [GetModuleFileNameW]

    test eax, eax

    jz .failed

    cmp eax, MAX_PATH_BUFFER

    jae .failed

    mov [pathLength], eax

    ;------------------------------------------------
    ; Build quoted executable path
    ;
    ; "C:\...\AsmLucentTB.exe"
    ;------------------------------------------------

    lea rsi, [pathBuffer]

    lea rdi, [runPath]

    ; Opening quote

    mov word [rdi], 22h

    add rdi, 2

    ; Copy path

    mov ecx, [pathLength]

    rep movsw

    ; Closing quote

    mov word [rdi], 22h

    add rdi, 2

    ; Null terminator

    mov word [rdi], 0

    ;------------------------------------------------
    ; Create / open Run registry key
    ;------------------------------------------------

    mov rcx, HKEY_CURRENT_USER_VALUE

    lea rdx, [szRunKey]

    xor r8d, r8d

    xor r9d, r9d

    ; dwOptions

    mov qword [rsp+20h], 0

    ; samDesired

    mov dword [rsp+28h], KEY_SET_VALUE

    ; lpSecurityAttributes

    mov qword [rsp+30h], 0

    ; phkResult

    lea rax, [hRegistry]

    mov qword [rsp+38h], rax

    ; lpdwDisposition

    lea rax, [disposition]

    mov qword [rsp+40h], rax

    call [RegCreateKeyExW]

    test eax, eax

    jnz .failed

    ;------------------------------------------------
    ; Write registry value
    ;------------------------------------------------

    mov rcx, [hRegistry]

    lea rdx, [szValueName]

    xor r8d, r8d

    mov r9d, REG_SZ

    ; lpData

    lea rax, [runPath]

    mov qword [rsp+20h], rax

    ; cbData:
    ; pathLength + opening quote + closing quote + NULL

    mov eax, [pathLength]

    add eax, 3

    shl eax, 1

    mov dword [rsp+28h], eax

    call [RegSetValueExW]

    mov ebx, eax

    ;------------------------------------------------
    ; Close registry key
    ;------------------------------------------------

    mov rcx, [hRegistry]

    call [RegCloseKey]

    mov qword [hRegistry], 0

    mov eax, ebx

    jmp .done


.failed:

    mov eax, 1


.done:

    add rsp, 50h

    pop rdi
    pop rsi
    pop rbx

    ret


;================================================================
; SETUP AUTOSTART LOGIC
;
; Runtime sequence:
;
; 1. Find and terminate TranslucentTB.
; 2. Check its installation path.
; 3. Remove TranslucentTB startup values.
; 4. If detected, install AsmLucentTB automatically.
; 5. Otherwise ask the user.
;
;================================================================

SetupAutostartLogic:

    sub rsp, 28h

    ;--------------------------------------------
    ; 1. Search for running TranslucentTB
    ;--------------------------------------------

    call KillTranslucentTB

    ;--------------------------------------------
    ; 2. Check installation
    ;--------------------------------------------

    call CheckTTBInstalled

    test eax, eax

    jz .remove_old_startup

    mov dword [foundTTB], 1


.remove_old_startup:

    ;--------------------------------------------
    ; 3. Remove old startup entries
    ;--------------------------------------------

    call RemoveTTBAutostart

    ;--------------------------------------------
    ; 4. Determine takeover
    ;--------------------------------------------

    cmp dword [foundTTB], 0

    jne .takeover


.ask_user:

    ;--------------------------------------------
    ; No TranslucentTB detected.
    ; Ask user about autostart.
    ;--------------------------------------------

    xor ecx, ecx

    lea rdx, [szMsgAsk]

    lea r8, [szMsgTitle]

    mov r9d, MB_YESNO or MB_ICONQUESTION

    call [MessageBoxW]

    cmp eax, IDYES

    jne .out

    ; Install AsmLucentTB autostart

    call InstallAutostart

    test eax, eax

    jz .out

    jmp .autostart_error


.takeover:

    ;--------------------------------------------
    ; TranslucentTB detected.
    ; Replace its autostart with AsmLucentTB.
    ;--------------------------------------------

    call InstallAutostart

    test eax, eax

    jnz .autostart_error

    ; Notify user

    xor ecx, ecx

    lea rdx, [szMsgReplaced]

    lea r8, [szMsgTitle]

    xor r9d, r9d

    call [MessageBoxW]

    jmp .out


.autostart_error:

    xor ecx, ecx

    lea rdx, [szMsgAutostartError]

    lea r8, [szMsgTitle]

    mov r9d, MB_ICONERROR

    call [MessageBoxW]


.out:

    add rsp, 28h

    ret


;================================================================
; APPLY TRANSPARENCY
;
; RCX = HWND
;================================================================

ApplyTransparency:

    sub rsp, 28h

    test rcx, rcx

    jz .failed

    lea rdx, [compositionData]

    call qword [pSetWindowCompositionAttribute]

    add rsp, 28h

    ret


.failed:

    xor eax, eax

    add rsp, 28h

    ret


;================================================================
; MAIN
;================================================================

start:

    sub rsp, 28h

    ;--------------------------------------------
    ; Initialize API
    ;--------------------------------------------

    call Initialize

    test eax, eax

    jnz fatal_error

    ;--------------------------------------------
    ; Runtime TranslucentTB takeover
    ;
    ; IMPORTANT:
    ; This executes when AsmLucentTB.exe starts.
    ; It is NOT executed by the assembler.
    ;--------------------------------------------

    call SetupAutostartLogic


;================================================================
; MAIN TASKBAR LOOP
;================================================================

main_loop:

    ;--------------------------------------------
    ; Primary taskbar
    ;--------------------------------------------

    lea rcx, [szTaskbar]

    xor edx, edx

    call [FindWindowW]

    test rax, rax

    jz .no_primary

    mov [hTaskbar], rax

    mov rcx, rax

    call ApplyTransparency

    jmp .secondary


.no_primary:

    mov qword [hTaskbar], 0


.secondary:

    ;--------------------------------------------
    ; Secondary taskbar
    ;--------------------------------------------

    lea rcx, [szSecondary]

    xor edx, edx

    call [FindWindowW]

    test rax, rax

    jz .wait

    mov rcx, rax

    call ApplyTransparency


.wait:

    ;--------------------------------------------
    ; Wait before refresh
    ;--------------------------------------------

    mov ecx, POLL_INTERVAL

    call [Sleep]

    jmp main_loop


;================================================================
; FATAL ERROR
;================================================================

fatal_error:

    xor ecx, ecx

    lea rdx, [szMsgError]

    lea r8, [szMsgTitle]

    mov r9d, MB_ICONERROR

    call [MessageBoxW]

    mov ecx, 1

    call [ExitProcess]

    int3


;================================================================
; IMPORTS
;================================================================

section '.idata' import data readable writeable

library kernel32, 'KERNEL32.DLL', user32, 'USER32.DLL', advapi32, 'ADVAPI32.DLL'

import kernel32, LoadLibraryW, 'LoadLibraryW', GetProcAddress, 'GetProcAddress', GetModuleFileNameW, 'GetModuleFileNameW', Sleep, 'Sleep', ExitProcess, 'ExitProcess', CreateToolhelp32Snapshot, 'CreateToolhelp32Snapshot', Process32FirstW, 'Process32FirstW', Process32NextW, 'Process32NextW', OpenProcess, 'OpenProcess', TerminateProcess, 'TerminateProcess', WaitForSingleObject, 'WaitForSingleObject', CloseHandle, 'CloseHandle', GetFileAttributesW, 'GetFileAttributesW', lstrcmpiW, 'lstrcmpiW'

import user32, FindWindowW, 'FindWindowW', MessageBoxW, 'MessageBoxW'

import advapi32, RegCreateKeyExW, 'RegCreateKeyExW', RegOpenKeyExW, 'RegOpenKeyExW', RegSetValueExW, 'RegSetValueExW', RegDeleteValueW, 'RegDeleteValueW', RegCloseKey, 'RegCloseKey'


;================================================================
; RESOURCES
;================================================================

section '.rsrc' resource data readable

directory RT_ICON, icons, RT_GROUP_ICON, group_icons

resource icons, 1, LANG_NEUTRAL, icon_data

resource group_icons, 1, LANG_NEUTRAL, main_icon

icon main_icon, icon_data, 'AsmLucentTB.ico'

;================================================================
; END
;================================================================

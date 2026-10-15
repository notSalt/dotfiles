; glazewm-ws.ahk (AutoHotkey v2): per-monitor workspaces for GlazeWM.
;   alt+1..5        focus workspace 1-5 on the monitor under the mouse
;   alt+shift+1..5  move the focused window there (and follow)
;   alt+b           show/hide the YASB bars
; Monitor n (left to right) owns workspaces n*5+1 .. n*5+5, matching config.yaml.
; Started/stopped by GlazeWM; exits by itself if GlazeWM stops.

#Requires AutoHotkey v2.0
#SingleInstance Force
#NoTrayIcon

if (A_Args.Length && A_Args[1] = "exit")
    ExitApp

PER_MONITOR := 5
IPC_PORT := 6123

; true = log to glazewm-ws.log
DEBUG := false

ws := 0

DllCall("LoadLibrary", "str", "winhttp", "ptr")
OnExit((*) => WsClose())

SetTimer(() => ProcessExist("glazewm.exe") ? 0 : ExitApp(), 5000)

!1:: GoTo_(1)
!2:: GoTo_(2)
!3:: GoTo_(3)
!4:: GoTo_(4)
!5:: GoTo_(5)
!+1:: MoveTo(1)
!+2:: MoveTo(2)
!+3:: MoveTo(3)
!+4:: MoveTo(4)
!+5:: MoveTo(5)
!b:: Yasb("toggle-bar")

GoTo_(i) {
    Critical   ; finish this switch before handling the next keypress
    Glaze("focus --workspace " Target(i))
}

MoveTo(i) {
    Critical
    t := Target(i)
    Glaze("move --workspace " t)
    Glaze("focus --workspace " t)
}

; Workspace name for index i on the monitor the mouse is on.
Target(i) {
    global PER_MONITOR
    t := MouseMonitorIndex() * PER_MONITOR + i
    Log("key " i " -> workspace " t)
    return t
}

; --- GlazeWM IPC ---

; Run a GlazeWM command over IPC, falling back to the CLI.
Glaze(cmd) {
    if (WsRequest("command " cmd) != "")
        return
    Log("IPC unavailable, using glazewm.exe for: " cmd)
    try RunWait('"' GlazeCli() '" command ' cmd, , "Hide")
}

; Send one message and return the reply (reconnects once).
WsRequest(msg) {
    Loop 2 {
        if !WsConnect()
            return ""
        if WsSend(msg) {
            reply := WsReceiveReply()
            if (reply != "")
                return reply
        }
        WsClose()   ; connection went bad; retry with a fresh one
    }
    return ""
}

WsConnect() {
    static hSession := 0
    global ws, IPC_PORT
    if ws
        return true
    if !hSession
        hSession := DllCall("winhttp\WinHttpOpen", "ptr", 0, "uint", 1, "ptr", 0, "ptr", 0, "uint", 0, "ptr")
    if !hSession
        return false
    hConnect := DllCall("winhttp\WinHttpConnect", "ptr", hSession, "wstr", "localhost", "ushort", IPC_PORT, "uint", 0, "ptr")
    if !hConnect
        return false
    hRequest := DllCall("winhttp\WinHttpOpenRequest", "ptr", hConnect, "wstr", "GET", "wstr", "/"
        , "ptr", 0, "ptr", 0, "ptr", 0, "uint", 0, "ptr")
    ok := hRequest
        && DllCall("winhttp\WinHttpSetOption", "ptr", hRequest, "uint", 114, "ptr", 0, "uint", 0)  ; UPGRADE_TO_WEB_SOCKET
        && DllCall("winhttp\WinHttpSendRequest", "ptr", hRequest, "ptr", 0, "uint", 0, "ptr", 0, "uint", 0, "uint", 0, "uptr", 0)
        && DllCall("winhttp\WinHttpReceiveResponse", "ptr", hRequest, "ptr", 0)
    if ok
        ws := DllCall("winhttp\WinHttpWebSocketCompleteUpgrade", "ptr", hRequest, "uptr", 0, "ptr")
    if hRequest
        DllCall("winhttp\WinHttpCloseHandle", "ptr", hRequest)
    DllCall("winhttp\WinHttpCloseHandle", "ptr", hConnect)
    if !ws
        Log("IPC connect failed")
    return ws != 0
}

WsSend(msg) {
    global ws
    len := StrPut(msg, "UTF-8") - 1
    buf := Buffer(len + 1)
    StrPut(msg, buf, "UTF-8")
    ; 2 = WINHTTP_WEB_SOCKET_UTF8_MESSAGE_BUFFER_TYPE
    return DllCall("winhttp\WinHttpWebSocketSend", "ptr", ws, "uint", 2, "ptr", buf, "uint", len, "uint") = 0
}

WsReceiveReply() {
    Loop 20 {
        m := WsReceiveMessage()
        if (m = "")
            return ""
        if InStr(m, '"messageType":"client_response"')
            return m
    }
    return ""
}

WsReceiveMessage() {
    global ws
    chunk := Buffer(65536)
    out := Buffer(0)
    total := 0
    Loop {
        read := 0, type := 0
        err := DllCall("winhttp\WinHttpWebSocketReceive", "ptr", ws, "ptr", chunk, "uint", chunk.Size
            , "uint*", &read, "uint*", &type, "uint")
        if (err != 0 || type = 4)   ; error or CLOSE
            return ""
        if read {
            newOut := Buffer(total + read)
            if total
                DllCall("RtlMoveMemory", "ptr", newOut, "ptr", out, "uptr", total)
            DllCall("RtlMoveMemory", "ptr", newOut.Ptr + total, "ptr", chunk, "uptr", read)
            out := newOut
            total += read
        }
        ; 0 = binary message, 2 = UTF-8 message (complete); 1 / 3 = fragment
        if (type = 0 || type = 2)
            break
    }
    return total ? StrGet(out, total, "UTF-8") : ""
}

WsClose() {
    global ws
    if ws
        DllCall("winhttp\WinHttpCloseHandle", "ptr", ws)
    ws := 0
}

; --- YASB IPC ---

; Send a yasbc command over YASB's pipe, falling back to yasbc.exe.
Yasb(cmd) {
    len := StrPut(cmd, "UTF-8") - 1
    msg := Buffer(len + 1)
    StrPut(cmd, msg, "UTF-8")
    reply := Buffer(64)
    read := 0
    if DllCall("CallNamedPipeW", "wstr", "\\.\pipe\yasb_pipe_cli", "ptr", msg, "uint", len
            , "ptr", reply, "uint", reply.Size, "uint*", &read, "uint", 1000)
        return
    Log("YASB pipe unavailable, using yasbc.exe for: " cmd)
    try Run('"' A_ProgramFiles '\YASB\yasbc.exe" ' cmd, , "Hide")
}

; --- Helpers ---

; 0-based index of the monitor under the mouse, left to right.
MouseMonitorIndex() {
    CoordMode("Mouse", "Screen")
    MouseGetPos(&x, &y)
    lefts := []
    hit := 0
    Loop MonitorGetCount() {
        MonitorGet(A_Index, &l, &t, &r, &b)
        lefts.Push(l)
        if (x >= l && x < r && y >= t && y < b)
            hit := l
    }
    rank := 0
    for l in lefts
        if (l < hit)
            rank++
    return rank
}

GlazeCli() {
    static cli := ""
    if (cli = "") {
        cli := "glazewm.exe"
        if pid := ProcessExist("glazewm.exe")
            try cli := ProcessGetPath(pid)
    }
    return cli
}

Log(msg) {
    global DEBUG
    if !DEBUG
        return
    try FileAppend(FormatTime(, "HH:mm:ss") "  " msg "`n", A_ScriptDir "\glazewm-ws.log")
}

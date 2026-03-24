#Requires AutoHotkey v2
#Include %A_ScriptDir%\Lib\OCR.ahk

; ============================================
; ============== Global Variables ============
; ============================================
global emailVariable := ""
global passwordVariable := ""
global fullNameVariable := ""
global InAction := False
global EmailGenerated := False
global IsOtpProcessing := False
global ResultPath := A_ScriptDir "\result.txt"
global FirstnamePath := A_ScriptDir "\firstname.txt"

; ============================================
; ============== Notification Function =======
; ============================================
ShowNotification(message, duration := 333) {
    MouseGetPos(&x, &y)
    ToolTip(message, x + 10, y + 10)
    SetTimer(() => ToolTip(""), -duration)
}

; ============================================
; =============== Save Function ==============
; ============================================
SaveToResultFile() {
    static lastSavedEmail := ""  ; Track the last saved email to prevent duplicates
    global emailVariable, passwordVariable, ResultPath

    ; Check if email and password are generated
    if (emailVariable == "" || passwordVariable == "") {
        ShowNotification("No email or password generated yet!", 3000)
        return
    }

    ; Avoid saving duplicate email-password pairs
    if (emailVariable == lastSavedEmail) {
        ShowNotification("This email-password pair has already been saved!", 3000)
        return
    }

    ; Define the file path and prepare data
    resultData := emailVariable "♦•" passwordVariable "#:`n"

    ; Attempt to open the file for appending
    File := FileOpen(ResultPath, "a", "UTF-8")
    if !File {
        ShowNotification("Failed to open " ResultPath " for writing!", 3000)
        return
    }

    ; Write data to the file
    File.Write(resultData)
    File.Close()

    ; Update the last saved email
    lastSavedEmail := emailVariable

    ; Display success notification
    ShowNotification("Saved to " ResultPath ": " resultData, 3000)
}

; ============================================
; =============== OCR Monitoring =============
; ============================================
MonitorOCRForKontak() {
    global InAction

    if InAction
        return  ; Prevent re-entrance

    InAction := True
    Try {
        hwnd := WinExist("ahk_class LDPlayerMainFrame")
        if !hwnd {
            ShowNotification("LDPlayer window not found.", 1000)
            return
        }
        WinGetPos(&winX, &winY, &winW, &winH, hwnd)

        ; Perform OCR
        Result := OCR.FromRect(winX, winY, winW, winH)

        ; Check for the text "kontak"
        if InStr(Result.Text, "kontak") {
            ShowNotification("Detected 'kontak'. Saving...")
            SaveToResultFile()  ; Automatically save if "kontak" is detected
        }
    } Catch {
        ShowNotification("Error during OCR.", 1000)
    } Finally {
        InAction := False
    }
}

; Set a timer to monitor OCR every 2 seconds
SetTimer MonitorOCRForKontak, 2000

; ============================================
; ============ Autoclick Function ============
; ============================================
AutoclickOCR() {
    global InAction

    if InAction
        return  ; Prevent re-entrance

    InAction := True
    Try {
        hwnd := WinExist("ahk_class LDPlayerMainFrame")
        if !hwnd {
            ShowNotification("LDPlayer window not found.", 1000)
            return
        }
        WinGetPos(&winX, &winY, &winW, &winH, hwnd)

        ; Perform OCR
        Result := OCR.FromRect(winX, winY, winW, winH)

        ; Define actions for detected text
        actions := [
            {text: "Buat Akun", action: "Click"},
            {text: "Daftar dengan email", action: "Click"},
            {text: "Oke", action: "Click"},
            {text: "Selanjutnya", action: "Click"},
            {text: "Berikutnya", action: "Click"},
            {text: "Masukkan Usia", action: "Click"},
            {text: "Lewati", action: "Click"},
            {text: "Lanjut", action: "Click"},
            {text: "Incognito", action: "Click"}
        ]

        for action in actions {
            if InStr(Result.Text, action.text) {
                ; Get position of the text and click
                MatchPos := Result.FindStrings(action.text, False)[1]
                if MatchPos {
                    Click(winX + MatchPos.x + MatchPos.w / 2, winY + MatchPos.y + MatchPos.h / 2)
                    ShowNotification("Clicked: " action.text, 1000)
                }
                break
            }
        }
    } Catch {
        ShowNotification("Error during OCR.", 1000)
    } Finally {
        InAction := False
    }
}

; ============================================
; =============== Hotkey Triggers ============
; ============================================
; Manual trigger for saving email and password
^!m::SaveToResultFile()

; Autoclick trigger
^!o::AutoclickOCR()

; Generate random email and type
^!k:: {
    global emailVariable, EmailGenerated

    emailVariable := GenerateRandomEmail()
    if (emailVariable == "") {
        ShowNotification("Failed to generate email.", 1500)
        return
    }

    EmailGenerated := True
    ShowNotification("Typing email: " emailVariable)
    Send(emailVariable)
    Sleep(50)
    Send("{Enter}")
}

; Generate random password and type
^!p:: {
    global passwordVariable

    passwordVariable := GenerateRandomPassword()
    Sleep(50)
    ShowNotification("Typing password: " passwordVariable)
    Send(passwordVariable)
}

; Generate random full name and type
^!f:: {
    global fullNameVariable

    fullNameVariable := GenerateRandomFullName()
    if (fullNameVariable == "") {
        ShowNotification("Failed to generate full name.", 3000)
        return
    }
    Sleep(50)
    ShowNotification("Typing full name: " fullNameVariable)
    Send(fullNameVariable)
}

; Check OTP
^!l:: {
    global emailVariable, EmailGenerated, IsOtpProcessing

    if (emailVariable == "") {
        ShowNotification("Generate an email first!", 1500)
        return
    }

    if IsOtpProcessing {
        ShowNotification("OTP process already in progress.", 1500)
        return
    }

    IsOtpProcessing := True
    recipient := StrSplit(emailVariable, "@")[1]
    url := "https://akunlama.com/api/events?recipient=" recipient

    ShowNotification("Checking OTP for: " emailVariable)

    tryCount := 0
    Loop {
        tryCount++
        if (tryCount > 10) {
            ShowNotification("OTP retrieval timed out!", 1500)
            break
        }

        Try {
            Http := ComObject("WinHttp.WinHttpRequest.5.1")
            Http.Open("GET", url, False)
            Http.Send()

            if (Http.Status = 200) {
                responseText := Http.ResponseText
                if (RegExMatch(responseText, '"subject"\s*:\s*"(\d{6}) (?:is your Instagram code|adalah kode Instagram Anda)"', &Match)) {
                    otp := Match[1]
                    SendInput(otp)
                    ShowNotification("OTP Typed: " otp)
                    SetTimer(() => (EmailGenerated := False, IsOtpProcessing := False), -300)
                    return
                }
            }
        } Catch {
            ShowNotification("Error checking OTP.", 1500)
        }
        Sleep(500) ; Retry delay
    }

    IsOtpProcessing := False
}
; ============================================
; =========== Helper Functions ===============
; ============================================
GenerateRandomEmail() {
    global FirstnamePath
    fullPath := FirstnamePath
    if !FileExist(fullPath) {
        ShowNotification("Firstname file not found at " fullPath, 3000)
        return ""
    }

    names := []
    Loop Read, fullPath
        names.Push(A_LoopReadLine)

    if (names.Length < 2) {
        ShowNotification("Not enough names in firstname.txt file!", 3000)
        return ""
    }

    firstName := names[Random(1, names.Length)]
    lastName := names[Random(1, names.Length)]
    combinedName := SubStr(Trim(firstName), 1, 5) . SubStr(Trim(lastName), 1, 5)
    randomNumber := Random(1, 10)
    email := SubStr(combinedName, 1, 10) . randomNumber
    return StrLower(email . "@akunlama.com")
}

GenerateRandomPassword() {
    chars := "abcdefghijklmnopqrstuvwxyz0123456789"
    password := ""
    Loop 8 {
        password .= SubStr(chars, Random(1, StrLen(chars)), 1)
    }
    return password
}

GenerateRandomFullName() {
    global FirstnamePath
    fullPath := FirstnamePath
    if !FileExist(fullPath) {
        ShowNotification("Firstname file not found!", 3000)
        return ""
    }

    names := []
    Loop Read, fullPath
        names.Push(A_LoopReadLine)

    if (names.Length < 2) {
        ShowNotification("Not enough names in firstname.txt file!", 3000)
        return ""
    }

    firstName := names[Random(1, names.Length)]
    lastName := names[Random(1, names.Length)]
    return Trim(firstName) . " " . Trim(lastName)
}

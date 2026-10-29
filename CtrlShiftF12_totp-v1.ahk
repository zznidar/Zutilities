; Ctrl+Shift+F12 (in any app) types the current 2FA (TOTP) code and presses Enter.
#Requires AutoHotkey v1.1.33+
#NoEnv
#SingleInstance Force

SecretFile := A_AppData "\totp-ahk\secret"

; Self-check against RFC 6238 test vectors.
if (Totp("GEZDGNBVGY3TQOJQGEZDGNBVGY3TQOJQ", 59) != "287082"
    || Totp("GEZDGNBVGY3TQOJQGEZDGNBVGY3TQOJQ", 1111111109) != "081804") {
    MsgBox, TOTP self-test failed.
    ExitApp
}

; Ask at startup, not on the hotkey: a dialog would steal focus from the login prompt.
Secret := LoadOrAskSecret()

; Codes are single-use, so never send the same 30 s step twice: take the next step instead.
; shortcut: servers accept only ~1-2 steps ahead, so a 3rd+ code within 30 s may be rejected.
LastStep := 0
return

^+F12::
    t := A_NowUTC
    EnvSub, t, 19700101000000, Seconds
    LastStep := Max(t // 30, LastStep + 1)
    Send, % "{Text}" Totp(Secret, LastStep * 30)
    Send, {Enter}
return

; Forget used codes: the next Ctrl+Shift+F12 types the current code again.
^+F11::LastStep := 0

LoadOrAskSecret() {
    global SecretFile
    if (FileExist(SecretFile)) {
        f := FileOpen(SecretFile, "r", "UTF-8-RAW")
        size := f.Length - f.Pos ; skip a BOM if one was written
        VarSetCapacity(enc, size)
        f.RawRead(enc, size)
        f.Close()
        Dpapi(enc, size, true, plain)
        return StrGet(&plain, "UTF-8")
    }
    InputBox, secret, TOTP setup, Base32 TOTP secret (stored encrypted`, readable only by your Windows account):, HIDE
    if (ErrorLevel)
        ExitApp
    Totp(secret, 0) ; throws on an invalid secret
    size := StrPut(secret, "UTF-8")
    VarSetCapacity(plain, size)
    StrPut(secret, &plain, "UTF-8")
    FileCreateDir, %A_AppData%\totp-ahk
    encSize := Dpapi(plain, size, false, enc)
    FileOpen(SecretFile, "w", "UTF-8-RAW").RawWrite(enc, encSize)
    return secret
}

; RFC 6238: SHA-1, 30 s, 6 digits.
Totp(secret, unixSeconds) {
    VarSetCapacity(counter, 8, 0)
    c := unixSeconds // 30
    Loop 8
        NumPut((c >> (8 * (8 - A_Index))) & 0xFF, counter, A_Index - 1, "UChar")
    keyLen := Base32Decode(secret, key)
    HmacSha1(key, keyLen, counter, 8, h)
    o := NumGet(h, 19, "UChar") & 0xF
    bin := ((NumGet(h, o, "UChar") & 0x7F) << 24) | (NumGet(h, o + 1, "UChar") << 16)
         | (NumGet(h, o + 2, "UChar") << 8) | NumGet(h, o + 3, "UChar")
    return Format("{:06d}", Mod(bin, 1000000))
}

Base32Decode(s, ByRef out) {
    StringUpper, s, s
    s := RegExReplace(s, "[\s=-]")
    size := StrLen(s) * 5 // 8
    if (size = 0)
        throw Exception("Secret is empty")
    VarSetCapacity(out, size, 0)
    n := 0, bits := 0, acc := 0
    Loop, Parse, s
    {
        v := InStr("ABCDEFGHIJKLMNOPQRSTUVWXYZ234567", A_LoopField, true) - 1
        if (v < 0)
            throw Exception("Secret is not valid base32")
        acc := (acc << 5) | v, bits += 5
        if (bits >= 8) {
            bits -= 8
            NumPut((acc >> bits) & 0xFF, out, n++, "UChar")
            acc &= (1 << bits) - 1
        }
    }
    return size
}

HmacSha1(ByRef key, keyLen, ByRef data, dataLen, ByRef out) {
    hAlg := 0, hHash := 0
    VarSetCapacity(out, 20, 0)
    ; 8 = BCRYPT_ALG_HANDLE_HMAC_FLAG
    if (DllCall("bcrypt\BCryptOpenAlgorithmProvider", "Ptr*", hAlg, "WStr", "SHA1", "Ptr", 0, "UInt", 8, "UInt"))
        throw Exception("BCryptOpenAlgorithmProvider failed")
    try {
        if (DllCall("bcrypt\BCryptCreateHash", "Ptr", hAlg, "Ptr*", hHash, "Ptr", 0, "UInt", 0, "Ptr", &key, "UInt", keyLen, "UInt", 0, "UInt")
            || DllCall("bcrypt\BCryptHashData", "Ptr", hHash, "Ptr", &data, "UInt", dataLen, "UInt", 0, "UInt")
            || DllCall("bcrypt\BCryptFinishHash", "Ptr", hHash, "Ptr", &out, "UInt", 20, "UInt", 0, "UInt"))
            throw Exception("HMAC-SHA1 failed")
    } finally {
        if (hHash)
            DllCall("bcrypt\BCryptDestroyHash", "Ptr", hHash)
        DllCall("bcrypt\BCryptCloseAlgorithmProvider", "Ptr", hAlg, "UInt", 0)
    }
}

; Windows DPAPI (current user). unprotect=false encrypts, true decrypts. Returns output size.
Dpapi(ByRef data, size, unprotect, ByRef out) {
    VarSetCapacity(blobIn, A_PtrSize * 2, 0), VarSetCapacity(blobOut, A_PtrSize * 2, 0)
    NumPut(size, blobIn, 0, "UInt")
    NumPut(&data, blobIn, A_PtrSize, "Ptr")
    fn := unprotect ? "crypt32\CryptUnprotectData" : "crypt32\CryptProtectData"
    ; 1 = CRYPTPROTECT_UI_FORBIDDEN
    if (!DllCall(fn, "Ptr", &blobIn, "Ptr", 0, "Ptr", 0, "Ptr", 0, "Ptr", 0, "UInt", 1, "Ptr", &blobOut))
        throw Exception("DPAPI failed, error " A_LastError)
    outSize := NumGet(blobOut, 0, "UInt"), p := NumGet(blobOut, A_PtrSize, "Ptr")
    VarSetCapacity(out, outSize)
    DllCall("RtlMoveMemory", "Ptr", &out, "Ptr", p, "UPtr", outSize)
    DllCall("LocalFree", "Ptr", p)
    return outSize
}

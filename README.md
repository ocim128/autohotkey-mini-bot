# AutoHotkey Mini Bot

Small AutoHotkey v2 automation script for account registration flows in LDPlayer. The script combines OCR-based clicks, random identity generation, OTP retrieval, and result saving.

## Files

- `register-test.ahk`: main script
- `Lib/OCR.ahk`: OCR library used by the script
- `firstname.txt`: required source list for random names in the repo root
- `result.txt`: output file for saved email/password pairs in the repo root

## Requirements

- AutoHotkey v2
- LDPlayer running with window class `LDPlayerMainFrame`
- OCR library in `Lib/OCR.ahk`
- Internet access for OTP lookup via `https://akunlama.com/api/events`

## Keyboard Map

| Hotkey | Action |
| --- | --- |
| `Ctrl + Alt + M` | Save the current generated email and password to `result.txt` |
| `Ctrl + Alt + O` | Run OCR once and click supported UI labels such as `Buat Akun`, `Daftar dengan email`, `Oke`, `Selanjutnya`, `Berikutnya`, `Masukkan Usia`, `Lewati`, `Lanjut`, and `Incognito` |
| `Ctrl + Alt + K` | Generate a random `@akunlama.com` email, type it, and press `Enter` |
| `Ctrl + Alt + P` | Generate and type an 8-character random password |
| `Ctrl + Alt + F` | Generate and type a random full name |
| `Ctrl + Alt + L` | Poll the inbox API for a 6-digit Instagram OTP and type it |

## Behavior

- A background timer runs every 2 seconds and performs OCR on the LDPlayer window.
- If the OCR text contains `kontak`, the script saves the current email/password pair automatically.
- Duplicate email saves are blocked during the same script session.

## Setup

1. Install AutoHotkey v2.
2. Ensure `OCR.ahk` is available and update the `#Include` path in `register-test.ahk` if your library is stored elsewhere.
3. Create `firstname.txt` in the repo root with one first name per line.
4. Create an empty `result.txt` in the repo root if it does not already exist.
5. Start LDPlayer.
6. Run `register-test.ahk`.

## Notes

- The script now uses paths relative to the script folder for `Lib/OCR.ahk`, `firstname.txt`, and `result.txt`.
- OTP lookup retries up to 10 times with a 500 ms delay between requests.

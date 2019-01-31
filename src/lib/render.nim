import terminal
import encodings

import figures

when defined(windows):
    proc writeConsoleW(
        hConsoleOutput: int, 
        lpBuffer: cstring,
        nNumberOfCharsToWrite: int,
        lpNumberOfCharsWritten: var int32, lpReserved: pointer
    ): int {.stdcall, dynlib: "kernel32", importc: "WriteConsoleW".}
    
    proc getStdHandle(typ: int): int {.stdcall, dynlib: "kernel32", importc: "GetStdHandle".}

    let stdoutHandle = getStdHandle(-11)

    proc writeStdout(text: string) =
        let convertedString = convert(text, "utf-16", "utf-8")
        var written: int32
        
        discard writeConsoleW(stdoutHandle, convertedString, text.len, written, nil)
else:
    proc writeStdout(text: string) =
        echo text
 
proc styledWrite(fg: ForegroundColor, text: string) =
    setForegroundColor(fg)
    writeStdout(text)

proc error(message: string, prefix = "", suffix = "") =
    styledWrite(fgWhite, prefix)
    styledWrite(fgRed, " " & figures.cross)
    styledWrite(fgWhite, message & " ")
    styledWrite(fgRed, suffix)
    styledWrite(fgWhite, "\r\n")

proc invalidCustomAppDir*(path: string) =
    error("Custom app directory was not found on your system:", "\n", path)


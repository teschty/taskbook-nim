import terminal, encodings

when defined(windows):
    proc writeConsoleW(
        hConsoleOutput: int, 
        lpBuffer: cstring,
        nNumberOfCharsToWrite: int,
        lpNumberOfCharsWritten: var int32, lpReserved: pointer
    ): int {.stdcall, dynlib: "kernel32", importc: "WriteConsoleW".}
    
    proc getStdHandle(typ: int): int {.stdcall, dynlib: "kernel32", importc: "GetStdHandle".}

    proc getConsoleMode(hConsoleOutput: int, mode: var int): int {.stdcall, dynlib: "kernel32", importc: "GetConsoleMode".}

    proc setConsoleMode(hConsoleOutput: int, mode: int): int {.stdcall, dynlib: "kernel32", importc: "SetConsoleMode".}

    let stdoutHandle = getStdHandle(-11)

    var mode: int
    if getConsoleMode(stdoutHandle, mode) == 0:
        echo "Error getting console mode"
        quit(1)

    if setConsoleMode(stdoutHandle, mode or 0x4) == 0:
        echo "This application requires Windows 10"
        quit(1)

    proc writeStdout*(text: string) =
        let convertedString = convert(text, "utf-16", "utf-8")
        var written: int32
        
        discard writeConsoleW(stdoutHandle, convertedString, text.len, written, nil)
else:
    proc writeStdout(text: string) =
        echo text

import terminal
import strformat
import strutils

import figures
import console
import item, note, task

proc styledWrite(fg: ForegroundColor, text: string) =
    setForegroundColor(fg)
    writeStdout(text)

proc error(message: string, prefix = "", suffix = "", suffixColor = fgRed) =
    styledWrite(fgWhite, prefix)
    styledWrite(fgRed, " " & figures.cross)
    styledWrite(fgWhite, message & " ")
    styledWrite(suffixColor, suffix)
    styledWrite(fgWhite, "\r\n")

proc success(message: string, prefix = "", suffix = "", suffixColor = fgWhite) =
    styledWrite(fgWhite, prefix)
    styledWrite(fgGreen, " " & figures.tick)
    styledWrite(fgWhite, message & " ")
    styledWrite(suffixColor, suffix)
    styledWrite(fgWhite, "\r\n")

proc invalidCustomAppDir*(path: string) =
    error("Custom app directory was not found on your system:", "\n", path)

proc missingId*() =
    error("No id was given as input", "\n")

proc invalidId*(id: int) =
    error("Unable to find item with id:", "\n", $id)

proc successCreate*(item: Item) =
    let itemType = if item.isTask: "task" else: "note"
    success(fmt"Created {itemType}", "\n", $item.id)

proc markComplete*(ids: seq[int]) =
    if ids.len == 0: return

    let noun = if ids.len > 1: "tasks" else: "task"
    success(fmt"Checked {noun}", "\n", ids.join(", "))

proc markIncomplete*(ids: seq[int]) =
    if ids.len == 0: return

    let noun = if ids.len > 1: "tasks" else: "task"
    success(fmt"Unchecked {noun}", "\n", ids.join(", "))
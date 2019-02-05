import strformat, strutils, tables, sequtils, times, math
import colorize

import figures, console, config, util
import item, note, task

const lineEnding = when defined(windows): "\r\n" else: "\n"

proc getItemStats(items: seq[Item]): auto =
    var (tasks, complete, notes) = (0, 0, 0)

    for item in items:
        if item.isTask:
            tasks += 1

            if Task(item).isComplete:
                complete += 1
        else:
            notes += 1

    (tasks: tasks, complete: complete, notes: notes)

proc isBoardComplete(items: seq[Item]): bool =
    let (tasks, complete, notes) = getItemStats(items)

proc error(message: string, prefix = "", suffix = "") =
    writeStdout prefix & " "
    writeStdout fgRed(" " & figures.cross)
    writeStdout message & " "
    writeStdout suffix
    writeStdout lineEnding

proc success(message: string, prefix = "", suffix = "") =
    writeStdout prefix & " "
    writeStdout fgGreen(figures.tick)
    writeStdout message & " "
    writeStdout suffix
    writeStdout lineEnding

proc awaiting(message: string, prefix = "", suffix = "") =
    writeStdout prefix & " "
    writeStdout fgMagenta("[ ]")
    writeStdout message & " "
    writeStdout suffix
    writeStdout lineEnding

proc pending(message: string, prefix = "", suffix = "") =
    writeStdout prefix & " "
    writeStdout fgMagenta("[ ]  ")
    writeStdout message & " "
    writeStdout suffix
    writeStdout lineEnding

proc note(message: string, prefix = "", suffix = "") =
    writeStdout prefix & " "
    writeStdout fgBlue("*  ")
    writeStdout message & " "
    writeStdout suffix
    writeStdout lineEnding

proc log(message: string, prefix = "", suffix = "") =
    writeStdout prefix & " "
    writeStdout message & " "
    writeStdout suffix
    writeStdout lineEnding

proc getAge(birthday: DateTime): string =
    # can't use `days` proc as original taskbook rounds
    let days = float((now() - birthday).hours()) / 24.0
    let age = int(round(days))

    if age == 0: "" else: fgDarkGray($age & "d")

proc invalidCustomAppDir*(path: string) =
    error("Custom app directory was not found on your system:", "\n", fgRed(path))

proc missingDesc*() =
    error("No description was given as input", "\n")

proc missingId*() =
    error("No id was given as input", "\n")

proc invalidId*(id: int) =
    error("Unable to find item with id:", "\n", fgDarkGray($id))

proc invalidIdsNumber*() =
    error("More than one ids were given as input", "\n")

proc invalidPriority*() =
    error("Priority can only be 1, 2, or 3", "\n")

proc successCreate*(item: Item) =
    let itemType = if item.isTask: "task" else: "note"
    success(fmt"Created {itemType}:", "\n", fgDarkGray($item.id))

proc successEdit*(id: int) =
    success(fmt"Updated description of item:", "\n", fgDarkGray($id))

proc markItem(ids: seq[int], verb, noun, pluralNoun: string) =
    if ids.len == 0: return

    let noun = if ids.len > 1: pluralNoun else: noun
    success(fmt"{verb} {noun}:", "\n", fgDarkGray(ids.join(", ")))

proc markComplete*(ids: seq[int]) =
    markItem(ids, "Checked", "task", "tasks")

proc markIncomplete*(ids: seq[int]) =
    markItem(ids, "Unchecked", "task", "tasks")

proc markStarted*(ids: seq[int]) =
    markItem(ids, "Started", "task", "tasks")

proc markPaused*(ids: seq[int]) =
    markItem(ids, "Paused", "task", "tasks")

proc markStarred*(ids: seq[int]) =
    markItem(ids, "Starred", "item", "items")

proc markUnstarred*(ids: seq[int]) =
    markItem(ids, "Unstarred", "item", "items")

proc missingBoards*() =
    error("No boards were given as input", "\n")

proc successDelete*(ids: seq[int]) =
    markItem(ids, "Deleted", "item", "items")

proc successMove*(id: int, boards: seq[string]) =
    success(fmt"Move item {fgDarkGray($id)} to", "\n", fgDarkGray(boards.join(", ")))

proc successPriority*(id: int, level: string) =
    let suffix = if level == "3":
        fgRed("high")
    elif level == "2":
        fgYellow("medium")
    else:
        fgGreen("normal")
        
    success(fmt"Updated priority of task: {fgDarkGray($id)} to", "\n", suffix)

proc successRestore*(ids: seq[int]) =
    let noun = if ids.len > 1: "items" else: "item"

    success(fmt"restored {noun}:", "\n", fgDarkGray(ids.join(", ")))

proc getCorrelation(items: seq[Item]): string =
    let (tasks, complete, _) = getItemStats(items) 

    fgDarkGray(fmt"[{complete}/{tasks}]")

proc buildTitle(key: string, items: seq[Item]): auto =
    let title = if key == getDateString(): 
        underline(key) & " " & fgDarkGray("[Today]")
    else:
        underline(key)
    
    let correlation = getCorrelation(items)
    (title: title, correlation: correlation)

proc displayTitle(board: string, items: seq[Item]) =
    let (title, correlation) = buildTitle(board, items)
    log(title, "\n ", correlation) 

proc getStar(item: Item): string =
    if item.isStarred: fgYellow("★") else: "" 

proc buildPrefix(item: Item): string =
    var prefix = newSeq[string]()
    let id = item.id

    prefix.add " ".repeat(4 - ($id).len)
    prefix.add fgDarkGray($id & ".")

    prefix.join(" ")

proc buildMessage(item: Item): string =
    var message = newSeq[string]()
    var (isComplete, priority, description) = (false, 0, item.description)

    if item.isTask:
        let t = Task(item)
        (isComplete, priority) = (t.isComplete, t.priority)

    if not isComplete and priority > 1:
        if priority == 2:
            message.add underline(fgYellow(description))
            message.add fgYellow("(!)")
        else:
            message.add underline(fgRed(description))
            message.add fgRed("(!!)")
    else:
        message.add(if isComplete: fgDarkGray(description) else: description)

    message.join(" ")

proc colorBoards(boards: seq[string]): string =
    boards.mapIt(fgDarkGray(it)).join(" ")

proc displayItemByDate(item: Item) =
    let boards = item.boards.filterIt(it != "My Board")
    let star = getStar(item)

    let prefix = buildPrefix(item)
    let message = buildMessage(item)
    let suffix = colorBoards(boards) & " " & star

    if item.isTask:
        let t = Task(item)
        if t.isComplete:
            success(message, prefix, suffix)
        elif t.inProgress:
            awaiting(message, prefix, suffix)
        else:
            pending(message, prefix, suffix)
    else:
        note(message, prefix, suffix)

proc displayItemByBoard(item: Item) =
    let boards = item.boards.filterIt(it != "My Board")
    let age = getAge(item.timestamp)
    let star = getStar(item)

    let prefix = buildPrefix(item)
    let message = buildMessage(item)
    let suffix = if age.len == 0: star else: age & " " & star

    if item.isTask:
        let t = Task(item)
        if t.isComplete:
            success(message, prefix, suffix)
        elif t.inProgress:
            awaiting(message, prefix, suffix)
        else:
            pending(message, prefix, suffix)
    else:
        note(message, prefix, suffix)

proc displayByDate*(data: OrderedTable[string, seq[Item]]) =
    for date in data.keys:
        if isBoardComplete(data[date]) and not tbConfig.displayCompleteTasks:
            continue

        displayTitle(date, data[date])
        for item in data[date]:
            if item.isTask and Task(item).isComplete and not tbConfig.displayCompleteTasks:
                continue

            displayItemByDate(item) 

proc displayByBoard*(data: OrderedTable[string, seq[Item]]) =
    for board in data.keys:
        if isBoardComplete(data[board]) and tbConfig.displayCompleteTasks:
            continue

        displayTitle(board, data[board])
        for item in data[board]:
            if item.isTask and Task(item).isComplete and not tbConfig.displayCompleteTasks:
                continue

            displayItemByBoard(item)

type Stats = tuple[percent: int, complete: int, inProgress: int, pending: int, notes: int]

proc displayStats*(stats: Stats) =
    if not tbConfig.displayProgressOverview: return
    let (percent, complete, inProgress, pending, notes) = stats

    let percentStr = if percent >= 75: 
        fgGreen($percent & "%") 
    elif percent >= 50:
        fgYellow($percent & "%")
    else:
        $percent & "%"

    let status = [
        fgGreen($complete) & " " & fgDarkGray("done"),
        fgBlue($inProgress) & " " & fgDarkGray("in progress"),
        fgMagenta($pending) & " " & fgDarkGray("pending"),
        fgBlue($notes) & " " & fgDarkGray(if notes == 1: "note" else: "notes"),
    ]

    if complete != 0 and inProgress == 0 and pending == 0 and notes == 0:
        log("All done!", "\n ", fgYellow("★"))

    if pending + inProgress + complete + notes == 0:
        log("Type `tb --help` to get started!", suffix = fgYellow("★"))

    log(fgDarkGray(fmt"{percentStr} of all tasks complete."), "\n ")
    log(status.join(fgDarkGray(" · ")), " ")
    
import sequtils, strutils, tables, sets, sugar

import item, task, note
import storage
import render

proc generateId(items = storage.getItems()): int =
    for id in items.keys():
        result = max(id, result)
    
    result += 1

proc getIds(items = storage.getItems()): seq[int] =
    let data = storage.getItems()
    for id in data.keys:
        result.add id

proc removeDuplicates[T](items: seq[T]): seq[T] =
    toSeq(toSet(items).items)

proc validateIds(ids: seq[int], existingIds = getIds()): seq[int] =
    if ids.len == 0:
        render.missingId()
        quit(1)

    result = removeDuplicates(ids)

    for id in result:
        if id notin existingIds:
            render.invalidId(id)
            quit(1)

proc isPriorityOpt(p: string): bool = p in ["p:1", "p:2", "p:3"]

proc getBoards(): seq[string] =
    var boardSet = initOrderedSet[string](4)
    boardSet.incl("My Board")

    for item in storage.getItems().values:
        for board in item.boards:
            boardSet.incl(board)

    toSeq(boardSet.items)

proc getDates(): seq[string] =
    var dateSet = initOrderedSet[string](16)
    for item in storage.getItems().values:
        dateSet.incl(item.date)
    
    toSeq(dateSet.items)

proc getOptions(input: openArray[string]): auto =
    var boards: seq[string] = @[]
    var desc: seq[string] = @[]

    if input.len == 0:
        render.missingDesc()
        quit(1)

    let id = generateId()
    var priority = 1

    for s in input:
        if isPriorityOpt(s):
            priority = parseInt(s.substr(2))
        else:
            if s.startsWith("@") and s.len > 1:
                boards.add(s)
            else:
                desc.add(s)

    let description = desc.join(" ")

    if boards.len == 0:
        boards.add("My Board")

    (id: id, description: description, boards: boards, priority: priority)
    
proc getStats(): auto =
    let data = storage.getItems()
    var (complete, inProgress, pending, notes) = (0, 0, 0, 0)

    for id in data.keys:
        if data[id].isTask:
            let t = Task(data[id])
            if t.isComplete: 
                inc complete
            elif t.inProgress:
                inc inProgress
            else:
                inc pending

            continue

        inc notes

    let total = complete + pending
    let percent = if total == 0: 0 else: int(complete * 100 / total)

    (percent: percent, complete: complete, inProgress: inProgress, pending: pending, notes: notes)

proc hasTerms(str: string, terms: openArray[string]): bool =
    let lowerCaseStr = str.toLower()
    terms.anyIt(lowerCaseStr.contains(it.toLower()))

# TODO: change to delete instead of creating copy?
proc filterItems(data: ItemMap, pred: (Item) -> bool): ItemMap =
    result = initItemMap(data.len)

    for key in data.keys:
        if pred(data[key]):
            result.add(key, data[key])

proc filterTask(data: ItemMap): ItemMap = 
    filterItems(data, item => item.isTask)

proc filterStarred(data: ItemMap): ItemMap =
    filterItems(data, item => item.isStarred)

proc filterInProgress(data: ItemMap): ItemMap =
    filterItems(data, item => item.isTask and Task(item).inProgress)

proc filterComplete(data: ItemMap): ItemMap =
    filterItems(data, item => item.isTask and Task(item).isComplete)

proc filterPending(data: ItemMap): ItemMap =
    filterItems(data, item => item.isTask and not Task(item).isComplete)

proc filterNote(data: ItemMap): ItemMap =
    filterItems(data, item => not item.isTask)

proc filterByAttributes(attrs: openArray[string], data = storage.getItems()): ItemMap =
    result = data

    if attrs.len == 0:
        return data

    for attr in attrs:
        case attr:
            of "star", "starred":
                result = filterStarred(result)
            of "done", "checked", "complete":
                result = filterComplete(result)
            of "progress", "started", "begun":
                result = filterInProgress(result)
            of "pending", "unchecked", "incomplete":
                result = filterPending(result)
            of "todo", "task", "tasks":
                result = filterTask(result)
            of "note", "notes":
                result = filterNote(result)

proc groupByBoard(data = storage.getItems(), boards: seq[string] = @[]): OrderedTable[string, seq[Item]] =
    result = initOrderedTable[string, seq[Item]]()

    for item in data.values:
        for board in item.boards:
            if boards.len == 0 or board in boards:
                result.mgetOrPut(board, @[]).add(item)

proc groupByDate(data = storage.getItems(), dates: seq[string] = @[]): OrderedTable[string, seq[Item]] =
    result = initOrderedTable[string, seq[Item]]()

    for item in data.values:
        if dates.len == 0 or item.date in dates:
            result.mgetOrPut(item.date, @[]).add(item)

proc saveItemToArchive(item: Item) =
    var archive = storage.getArchive()
    let archiveId = generateId(archive)

    item.id = archiveId
    archive[archiveId] = item

    storage.setArchive(archive)

proc saveItemToStorage(item: Item) =
    var data = storage.getItems()
    let restoreId = generateId()

    item.id = restoreId
    data[restoreId] = item

    storage.setItems(data)

proc createNote*(desc: openArray[string]) =
    let (id, desc, boards, _) = getOptions(desc)
    let note = newNote(id, desc, boards)

    var data = storage.getItems()
    data[id] = note
    
    storage.setItems(data)
    render.successCreate(note)

# TODO: COPY TO CLIPBOARD

proc checkTasks*(ids: seq[int]) = 
    let ids = validateIds(ids)
    var data = storage.getItems() 
    var (checked, unchecked) = (newSeq[int](), newSeq[int]())

    for id in ids:
        var item = Task(data[id])
        item.inProgress = false
        item.isComplete = not item.isComplete

        if item.isComplete:
            checked.add(id)
        else:
            unchecked.add(id)

    storage.setItems(data)
    render.markComplete(checked)
    render.markIncomplete(unchecked)

proc beginTasks*(ids: seq[int]) =
    let ids = validateIds(ids)
    var data = storage.getItems() 
    var (started, paused) = (newSeq[int](), newSeq[int]())

    for id in ids:
        var item = Task(data[id])
        item.inProgress = false
        item.isComplete = not item.isComplete

        if item.isComplete:
            started.add(id)
        else:
            paused.add(id)

    storage.setItems(data)
    render.markStarted(started)
    render.markPaused(paused)

proc createTask*(desc: seq[string]) =
    let (id, desc, boards, priority) = getOptions(desc)
    var data = storage.getItems()
    var task = newTask(id, desc, boards, priority)

    data[id] = task
    storage.setItems(data)
    render.successCreate(task)

proc deleteItems*(ids: seq[int]) =
    let ids = validateIds(ids)
    var data = storage.getItems()

    for id in ids:
        saveItemToArchive(data[id])
        data.del id
    
    storage.setItems(data)
    render.successDelete(ids)

proc displayArchive*() =
    render.displayByDate(groupByDate(storage.getArchive()))

proc displayByBoard*() =
    render.displayByBoard(groupByBoard())

proc displayByDate*() =
    render.displayByDate(groupByDate())

proc displayStats*() =
    render.displayStats(getStats())

proc editDescription*(input: openArray[string]) =
    let targets = input.filterIt(it.startsWith("@"))

    if targets.len == 0:
        render.missingId()
        quit(1)
    
    if targets.len > 1:
        render.invalidIdsNumber()
        quit(1)
    
    let target = targets[0]
    let id = validateIds(@[target.replace("@", "").parseInt()])[0]
    let newDesc = input.filterIt(it != target).join(" ")

    if newDesc.len == 0:
        render.missingDesc()
        quit(1)

    var data = storage.getItems()
    data[id].description = newDesc
    storage.setItems(data)
    render.successEdit(id)

proc findItems*(terms: openArray[string]) =
    var result = initItemMap()
    var data = storage.getItems()

    for id in data.keys:
        if not hasTerms(data[id].description, terms): continue

        result[id] = data[id]
    
    render.displayByBoard(groupByBoard(result))

proc listByAttributes*(terms: openArray[string]) =
    var (boards, attributes) = (newSeq[string](), newSeq[string]())
    let storedBoards = getBoards()

    for x in terms:
        if ("@" & x) in storedBoards:
            if x == "myboard":
                boards.add("My Board")
            else:
                attributes.add(x)

            continue
        
        boards.add("@" & x)
    
    (boards, attributes) = (removeDuplicates(boards), removeDuplicates(attributes))

    let data = filterByAttributes(attributes)
    render.displayByBoard(groupByBoard(data, boards))

proc moveBoards*(input: openArray[string]) =
    var boards = newSeq[string]()
    let targets = input.filterIt(it.startsWith("@"))

    if targets.len == 0:
        render.missingId()
        quit(1)

    if targets.len > 1:
        render.invalidIdsNumber()
        quit(1)
    
    let target = targets[0]
    let id = validateIds(@[target.replace("@", "").parseInt()])[0]

    for x in input.filterIt(it != target):
        boards.add(if x == "myboard": "My Board" else: "@" & x)

    if boards.len == 0:
        render.missingBoards()
        quit(1)
    
    boards = removeDuplicates(boards)

    var data = storage.getItems()
    data[id].boards = boards
    storage.setItems(data)
    render.successMove(id, boards)

proc restoreItems*(ids: seq[int]) =
    let ids = validateIds(ids, getIds(storage.getArchive()))
    var archive = storage.getArchive()

    for id in ids:
        saveItemToArchive(archive[id])
        archive.del id

    storage.setArchive(archive)
    render.successRestore(ids)

proc starItems*(ids: seq[int]) =
    let ids = validateIds(ids)
    let data = storage.getItems()
    var (starred, unstarred) = (newSeq[int](), newSeq[int]())

    for id in ids:
        data[id].isStarred = not data[id].isStarred
        if data[id].isStarred:
            starred.add(id)
        else:
            unstarred.add(id)

    storage.setItems(data)
    render.markStarred(starred)
    render.markUnstarred(unstarred)

proc updatePriority*(input: openArray[string]) =
    let levels = input.filterIt(it in ["1", "2", "3"])

    if levels.len == 0:
        render.invalidPriority()
        quit(1)

    let level = levels[0]

    let targets = input.filterIt(it.startsWith("@"))

    if targets.len == 0:
        render.missingId()
        quit(1)
    
    if targets.len > 1:
        render.invalidIdsNumber()
        quit(1)

    let target = targets[0]
    let id = validateIds(@[target.replace("@", "").parseInt()])[0]

    var data = storage.getItems()
    Task(data[id]).priority = level.parseInt()
    storage.setItems(data)
    render.successPriority(id, level)
    
proc clear*() =
    var ids = newSeq[int]()
    var data = storage.getItems()

    for id in data.keys:
        if Task(data[id]).isComplete:
            ids.add(id)

    if ids.len == 0: return

    deleteItems(ids)

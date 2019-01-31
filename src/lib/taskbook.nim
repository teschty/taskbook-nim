import storage
import tables
import item, task, note
import sequtils
import strutils
import render

proc generateId(items = storage.getItems()): int =
    for id in items.keys():
        result = max(parseInt(id), result)

proc getIds(items = storage.getItems()): seq[int] =
    let data = storage.getItems()

proc validateIds(ids: seq[int], existingIds = getIds()) =
    if ids.len == 0:
        render


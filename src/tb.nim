const VERSION = "0.2.0"

import os
import strutils

import lib/taskbook
import lib/config
import lib/help

type InvalidIdError = ref object of Exception

proc tryParseIds(ids: seq[string]): seq[int] =
  # have to store lastId so we can get the invalid id
  var lastId: string

  try:
    for id in ids:
      lastId = id
      result.add id.parseInt()
  except ValueError:
    raise InvalidIdError(msg: "Invalid ID: '" & lastId & "'")

proc handleArgs(args: seq[string]) = 
  var cmd = args[0]
  if cmd.startsWith("--"):
    cmd = cmd.substr(2)
  elif cmd.startsWith("-"):
    cmd = cmd.substr(1)

  let input = args[1..^1]

  case cmd:
    of "a", "archive":
      taskbook.displayArchive()
    of "b", "begin":
      taskbook.beginTasks(tryParseIds(input))
    of "c", "check":
      taskbook.checkTasks(tryParseIds(input))
    of "clear":
      taskbook.clear()
    of "y", "copy":
      echo "NOT YET IMPLEMENTED"
    of "e", "edit":
      taskbook.editDescription(input)
    of "f", "find":
      taskbook.findItems(input)
    of "h", "help":
      echo help.HELP_TEXT
    of "l", "list":
      taskbook.listByAttributes(input)
    of "m", "move":
      taskbook.moveBoards(input)
    of "n", "note":
      taskbook.createNote(input)
    of "p", "priority":
      taskbook.updatePriority(input)
    of "r", "restore":
      taskbook.restoreItems(tryParseIds(input))
    of "s", "star":
      taskbook.starItems(tryParseIds(input))
    of "t", "task":
      taskbook.createTask(input)
    of "i", "timeline":
      taskbook.displayByDate()
      taskbook.displayStats()
    of "v", "version":
      echo VERSION

let args = commandLineParams()

if args.len > 0:
  try:
    handleArgs(args)
  except InvalidIdError as e:
    echo e.msg
else:
  taskbook.displayByBoard()
  taskbook.displayStats()

import os
import strutils

import lib/taskbook
import lib/config

proc handleArgs(args: seq[string]) = 
  var cmd = args[0]
  if cmd.startsWith("--"):
    cmd = cmd.substr(2)
  elif cmd.startsWith("-"):
    cmd = cmd.substr(1)

  let input = args[1..^1]

  case cmd:
    of "a", "archive":
      displayArchive()
    of "b", "begin":
      discard
    of "c", "check":
      discard
    of "clear":
      discard
    of "y", "copy":
      discard
    of "e", "edit":
      echo "EDIT"
    of "f", "find":
      echo "FIND"
    of "h", "help":
      discard
    of "l", "list":
      discard
    of "m", "move":
      discard
    of "n", "note":
      discard
    of "p", "priority":
      discard
    of "r", "restore":
      discard
    of "s", "star":
      discard
    of "t", "task":
      taskbook.createTask(input)
    of "i", "timeline":
      discard
    of "v", "version":
      discard

let args = commandLineParams()

echo "args = ", args

if args.len > 0:
  handleArgs(args)
else:
  taskbook.displayByBoard()
  
taskbook.displayStats()

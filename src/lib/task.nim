import item
import times
import options

type Task* = ref object of Item
    isComplete*: bool
    inProgress*: bool
    priority*: int

proc newTask*(id: int, description: string, boards: seq[string], priority = 1): Task = 
    let dt = now()

    Task(
        id: id,
        description: description, 
        boards: boards,
        isTask: true, 
        isComplete: false,
        inProgress: false,
        isStarred: false,
        priority: priority,
        timestamp: now(),
        date: dt.format("ddd MMM dd UUUU"),
    )

import item
import times
import options

type Task* = ref object of Item
    isComplete*: bool
    inProgress*: bool
    priority*: int

proc newTask*(id: int, isComplete, inProgress, isStarred = false, priority = 1): Task = 
    let dt = now()

    Task(
        id: id,
        isTask: true, 
        isComplete: isComplete,
        inProgress: inProgress,
        isStarred: isStarred,
        priority: priority,
        timestamp: now(),
        date: dt.format("ddd MMM dd UUUU"),
    )

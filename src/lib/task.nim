import item
import times
import options

type Task* = ref object of Item
    isComplete*: bool
    inProgress*: bool
    priority*: int

proc newTask*(isComplete, inProgress, isStarred = false, priority = 1): Task = 
    Task(
        isTask: true, 
        isComplete: isComplete,
        inProgress: inProgress,
        isStarred: isStarred,
        priority: priority,
        timestamp: now()
    )

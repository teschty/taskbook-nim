import times

type Item* = ref object of RootObj
    id*: int
    date*: string
    timestamp*: DateTime
    description*: string
    isStarred*: bool
    boards*: seq[string]
    isTask*: bool

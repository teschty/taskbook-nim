import times

type Item* = ref object of RootObj
    id*: int
    date*: string
    timestamp*: DateTime
    description*: string
    isStarred*: bool
    boards*: seq[string]
    isTask*: bool

proc newItem*(id: int, description: string, boards: seq[string]): Item =
    let dt = now()

    Item(
        id: id,
        date: dt.format("ddd MMM dd UUUU"),
        timestamp: dt,
        description: description,
        boards: boards
    )

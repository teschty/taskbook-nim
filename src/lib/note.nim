import times

import item

type Note* = ref object of Item

proc newNote*(id: int, desc: string, boards: seq[string]): Note =
    let dt = now()

    Note(
        id: id,
        date: dt.format("ddd MMM dd UUUU"),
        timestamp: dt,
        description: desc,
        boards: boards
    )

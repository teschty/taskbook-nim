import times

proc getDateString*(dt = now()): string =
    dt.format("ddd MMM dd UUUU")

import strutils, json, os

type Config* = object
    taskbookDirectory*: string
    displayCompleteTasks*: bool
    displayProgressOverview*: bool

const defaultConfig = Config(
    taskbookDirectory: "~",
    displayCompleteTasks: true,
    displayProgressOverview: true
)

let configFile = getHomeDir() / ".taskbook.json"

# Create config file if it doesn't exist
if not configFile.existsFile():
    writeFile(configFile, pretty(%*defaultConfig, 4))

var parsedConfig = to(parseFile(configFile), Config)

# switch ~ out for homedir
if parsedConfig.taskbookDirectory.startsWith("~"):
    parsedConfig.taskbookDirectory = getHomeDir() / parsedConfig.taskbookDirectory.substr(1)

let tbConfig* = parsedConfig

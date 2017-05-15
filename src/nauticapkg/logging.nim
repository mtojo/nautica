import strutils
import terminal
import times

type
  LogLevel* = enum
    lvDebug
    lvInfo
    lvWarn
    lvError
    lvNone

  Logger* = object
    level*: LogLevel

proc format(logger: Logger, level, kind, message: string,
            params: varargs[string, `$`]): string =
  return "[" & getTime().getGMTime().format("yyyy-MM-dd'T'hh:mm:ss'Z'") &
         "] [" & level & "] " & kind & " - " & format(message, params) & "\e[0m"

proc debug*(logger: Logger, kind, message: string,
            params: varargs[string, `$`]) =
  if logger.level <= lvDebug:
    setForegroundColor(fgCyan)
    echo logger.format("DEBUG", kind, message, params)
    resetAttributes()

proc info*(logger: Logger, kind, message: string,
           params: varargs[string, `$`]) =
  if logger.level <= lvInfo:
    setForegroundColor(fgGreen)
    echo logger.format("INFO", kind, message, params)
    resetAttributes()

proc warn*(logger: Logger, kind, message: string,
           params: varargs[string, `$`]) =
  if logger.level <= lvWarn:
    setForegroundColor(fgYellow)
    echo logger.format("WARN", kind, message, params)
    resetAttributes()

proc error*(logger: Logger, kind, message: string,
            params: varargs[string, `$`]) =
  if logger.level <= lvError:
    stderr.writeLine("\e[31m" & logger.format("ERROR", kind, message, params) &
                     "\e[0m")

var logger* {.threadvar.}: Logger
logger.level = lvInfo

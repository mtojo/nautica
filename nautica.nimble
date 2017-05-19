# Package

version = "0.1.0"
author = "Masaki Tojo"
description = "Web application framework"
license = "MIT"

bin = @["nautica"]
binDir = "bin"
srcDir = "src"

# Dependencies

requires "nim >= 0.17.0"

# Tasks

task run, "Runs the main module":
  exec "nimble build"
  exec "./bin/nautica"

task example, "Runs the example":
  exec "nim c -r example/simple"

task test, "Runs the test suite":
  exec "nim c -r tests/tester"

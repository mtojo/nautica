import re, strutils, unittest
import nautica

proc unquote(s: string): string =
  s.strip(chars = {'"'})

proc read_package_version(): string =
  var file: File
  if (not open(file, "nautica.nimble", FileMode.fmRead)):
    return
  defer: file.close
  while file.endOfFile == false:
    let line = file.readLine
    if line =~ re"^\s*version\s*=\s*(.+)\s*":
      return matches[0].unquote

suite "description for this stuff":
  echo "suite setup: run once before the tests"

  setup:
    echo "run before each test"

  teardown:
    echo "run after each test"

  test "check the version is same as package":
    check(nautica.version == read_package_version())

  echo "suite teardown: run once after the tests"

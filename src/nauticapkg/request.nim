import strtabs, strutils
import uri
import asyncnet
import asynchttpserver, asyncdispatch

type
  Request* = ref object
    reqMethod*: HttpMethod
    headers*: HttpHeaders
    protocol*: tuple[orig: string, major, minor: int]
    url*: Uri
    hostname*: string
    body*: string
    params*: StringTableRef

proc newRequest*(client: asynchttpserver.Request): Request =
  new result
  result.reqMethod = client.reqMethod
  result.headers = client.headers
  result.protocol = client.protocol
  result.url = client.url
  result.hostname = client.hostname
  result.body = client.body # FIXME: streaming
  result.params = nil

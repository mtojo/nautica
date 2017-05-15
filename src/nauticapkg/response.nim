import strtabs, strutils
import asyncnet
import asynchttpserver, asyncdispatch

type
  Response* = ref object
    client: asynchttpserver.Request
    statusCode: HttpCode
    headers: seq[string]
    headersSent: bool

proc newResponse*(client: asynchttpserver.Request): Response =
  new result
  result.client = client
  newSeq result.headers, 0
  result.headersSent = false

proc headersSent*(res: Response): bool =
  res.headersSent

proc isClosed*(res: Response): bool =
  res.client.client.isClosed

proc status*(res: Response, code: HttpCode) =
  res.statusCode = code

proc addHeader*(res: Response, header: string) =
  res.headers.add(header)

proc addHeader*(res: Response, key, value: string) =
  res.addHeader(key & ": " & value)

proc sendHeaders*(res: Response): Future[void] =
  var msg = "HTTP/1.1 " & $res.statusCode & "\c\L"
  msg.add(res.headers.join("\c\L"))
  msg.add("\c\L")
  res.headersSent = true
  res.client.client.send(msg)

proc send*(res: Response, content: string): Future[void] =
  if res.headersSent:
    res.client.client.send(content)
  else:
    var msg = "HTTP/1.1 " & $res.statusCode & "\c\L"
    msg.add(res.headers.join("\c\L"))
    msg.add("\c\L\c\L")
    msg.add(content)
    res.headersSent = true
    res.client.client.send(msg)

proc respond*(res: Response, code: HttpCode, content: string,
              headers: HttpHeaders = nil): Future[void] =
  res.client.respond(code, content, headers)

converter toBool*(res: Response): bool = not res.isClosed

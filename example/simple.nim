import httpcore, strtabs
import re
import nautica

var app = newApp()

app.use(xPoweredBy)

proc index(req: Request, res: Response): Future[void] =
  res.respond(Http200, "index")
app.get("/", index)

proc article(req: Request, res: Response): Future[void] =
  var msg = $req.params["id"]
  res.status(Http200)
  res.addHeader("Content-Length", $msg.len)
  res.send(msg)
app.get("/post/:id", article)

proc sub_page(req: Request, res: Response): Future[void] =
  res.status(Http200)
  res.addHeader("Content-Length", "8")
  res.send("sub-page")
app.get(re"^/\w+\.html$", sub_page)

asyncCheck app.serve(Port(3000))
runForever()

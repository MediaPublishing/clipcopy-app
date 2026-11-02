from pathlib import Path
from html.parser import HTMLParser
import json, re, sys
root=Path(__file__).resolve().parent.parent
failures=[]
class Page(HTMLParser):
    def __init__(self): super().__init__(); self.ids=set(); self.links=[]; self.assets=[]; self.lang=None; self.h1=0; self.scripts=0; self.canonical=None
    def handle_starttag(self,tag,attrs):
        a=dict(attrs)
        if "id" in a:
            if a["id"] in self.ids: failures.append("duplicate-id")
            self.ids.add(a["id"])
        if tag=="html": self.lang=a.get("lang")
        if tag=="h1": self.h1+=1
        if tag=="script": self.scripts+=1
        if tag=="a": self.links.append(a.get("href",""))
        if tag=="img" and not a.get("alt"): failures.append("missing-alt")
        for k in ["src","srcset"]:
            if a.get(k): self.assets.append(a[k])
        if tag=="link":
            if a.get("rel")=="canonical": self.canonical=a.get("href")
            if a.get("rel") in ["stylesheet","icon","apple-touch-icon"]: self.assets.append(a.get("href",""))
for lang,path in [("de","docs/index.html"),("en","docs/en/index.html")]:
    page=Page();page.feed((root/path).read_text())
    if page.lang!=lang or page.h1!=1 or page.scripts: failures.append("html-contract-"+lang)
    expected="https://mediapublishing.github.io/clipcopy-app/"+("en/" if lang=="en" else "")
    if page.canonical!=expected: failures.append("canonical-"+lang)
    for link in page.links:
        if link.startswith("#") and link[1:] not in page.ids: failures.append("broken-anchor")
    for asset in page.assets:
        if not asset.startswith("/clipcopy-app/"): failures.append("external-asset")
        elif not (root/"docs"/asset.removeprefix("/clipcopy-app/")).is_file(): failures.append("missing-asset")
for folder in ["Sources","Tests","scripts","docs"]:
    for path in (root/folder).rglob("*"):
        if not path.is_file(): continue
        if path.suffix in [".sqlite",".db",".key",".pem",".p12",".log"]: failures.append("private-file")
        if path.suffix not in [".swift",".py",".sh",".md",".html",".css",".yml"]:continue
        text=path.read_text()
        if path.resolve()==Path(__file__).resolve(): continue
        if re.search(r"/Users/|webonomy@|ZCLIPPING|ZDATERECORDED|copyclip\.sqlite",text): failures.append("private-path-or-migration:"+str(path.relative_to(root)))
# Demo's complete dependency closure is ClipCopyUI + ClipCopyCore only.
for folder in ["Sources/ClipCopyDemo","Sources/ClipCopyUI","Sources/ClipCopyCore"]:
    for path in (root/folder).glob("*.swift"):
        if re.search(r"import ClipCopyNative|import ClipCopyStorage|NSPasteboard|KeyStore|URLSession",path.read_text()): failures.append("demo-isolation:"+path.name)
print(json.dumps({"publicSourceGuard":not failures,"scope":"static source and HTML only; no binary or ZIP inspection","staticLanguages":["de","en"],"realClipboardRead":False,"failures":failures}))
sys.exit(bool(failures))

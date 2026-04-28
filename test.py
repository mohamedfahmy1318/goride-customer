import urllib.request
import json
url = "https://api.github.com/search/issues?q=+repo:firebase/flutterfire+PhoneAuthProvider+crash"
req = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0"})
try:
    response = urllib.request.urlopen(req)
    data = json.loads(response.read())
    for item in data.get("items", [])[:5]:
        print(item["html_url"], item["title"])
except Exception as e:
    print(e)

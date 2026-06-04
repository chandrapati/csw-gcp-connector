import sys, re
path = sys.argv[1]
html = open(path).read()
html = re.sub(r'<header[^>]*id="title-block-header"[^>]*>.*?</header>\n?', '', html, flags=re.DOTALL)
open(path, 'w').write(html)

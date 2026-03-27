import re, unicodedata, sys

s = sys.argv[1]
s = unicodedata.normalize('NFKD', s)
s = ''.join(c for c in s if not unicodedata.combining(c))
s = s.encode('ascii', 'ignore').decode()
# Strip TitleID prefix
s = re.sub(r'^0004[0-9A-Fa-f]{12}[-_ ]?', '', s)

# Strip extension (known ROM/audio types only, to avoid eating dots mid-title)
s = re.sub(r'\.(3ds|cci|app|cia|z3ds|zcci|wav)$', '', s, flags=re.I)

# Strip trailing noise tags
s = re.sub(r'[-_ .]?[Ss]tandard$', '', s)
s = re.sub(r'[-_ .]?[Dd]ecrypted$', '', s)
s = re.sub(r'[-_ .]?[Pp]iratelegit$', '', s)

# Strip parentheticals (regions, revisions, etc.)
s = re.sub(r'\s*\([^)]*\)', '', s)
s = s.strip()

# Move leading article: "The X - Y" -> "X, The - Y"
am = re.match(r'^(The|An|A) ', s, re.I)
if am:
    art = am.group(1)
    rest = s[am.end():]
    di = rest.find(' - ')
    if di >= 0:
        s = rest[:di] + ', ' + art + ' - ' + rest[di+3:]
    else:
        s = rest + ', ' + art

# Clean up any double spaces
s = re.sub(r'  +', ' ', s).strip()

print(s)
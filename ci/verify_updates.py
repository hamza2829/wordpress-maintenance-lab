import json
from pathlib import Path

root = Path('artifacts')
before = json.loads((root / 'versions-before.json').read_text())
after = json.loads((root / 'versions-after.json').read_text())
def version(value):
    return tuple(map(int, value.split('.')))
assert version(before['core']) < version(after['core']), (before, after)
assert version(before['hello_dolly']) < version(after['hello_dolly']), (before, after)
assert after['child_theme'] == before['child_theme'] == 'nordlicht-child'
(root / 'update-proof.json').write_text(json.dumps({'before': before, 'after': after, 'core_updated': True, 'plugin_updated': True}, indent=2) + '\n')
print(json.dumps({'before': before, 'after': after}, indent=2))

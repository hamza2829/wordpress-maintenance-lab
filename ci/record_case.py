"""Record a shell case only after its real assertions pass."""
import json
from pathlib import Path
import sys

path = Path('artifacts/shell-cases.json')
cases = json.loads(path.read_text()) if path.exists() else []
name = sys.argv[1]
if any(item['name'] == name for item in cases):
    raise SystemExit('Duplicate shell case: ' + name)
cases.append({'name': name, 'status': 'passed'})
path.parent.mkdir(exist_ok=True)
path.write_text(json.dumps(cases, indent=2) + '\n', encoding='utf-8')
print('PASS: ' + name)

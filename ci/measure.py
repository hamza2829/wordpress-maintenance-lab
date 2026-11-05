"""Count actual JUnit cases and passed shell scenarios, without nested-suite double counting."""
import json
import os
from pathlib import Path
import subprocess
import xml.etree.ElementTree as ET

root = Path('artifacts')
def junit(path):
    cases = list(ET.parse(path).getroot().iter('testcase'))
    bad = sum(any(case.find(tag) is not None for tag in ('failure', 'error', 'skipped')) for case in cases)
    assert cases and not bad, (str(path), len(cases), bad)
    return len(cases)
php = junit(root / 'phpunit.xml')
browser = {phase: junit(root / 'playwright' / phase / 'junit.xml') for phase in ('baseline', 'rollback', 'updated', 'restored')}
assert len(set(browser.values())) == 1, browser
shell = json.loads((root / 'shell-cases.json').read_text())
required = {'update-rollback', 'restore-clean-content', 'ssh-key-login', 'ssh-failed-login', 'ssh-rsync-content', 'ssh-rejected-deploy-unchanged'}
assert {case['name'] for case in shell} == required
assert all(case['status'] == 'passed' for case in shell)
update = json.loads((root / 'update-proof.json').read_text())
restore = json.loads((root / 'restore-proof.json').read_text())
assert update['core_updated'] and update['plugin_updated'] and restore['clean_instance']
metrics = {'phpunit_tests': php, 'playwright_distinct_tests': next(iter(browser.values())), 'playwright_by_phase': browser,
           'playwright_executions': sum(browser.values()), 'shell_scenarios': len(shell),
           'distinct_test_cases': php + next(iter(browser.values())) + len(shell),
           'total_test_executions': php + sum(browser.values()) + len(shell), 'failures': 0, 'skipped': 0,
           'before_versions': update['before'], 'after_versions': update['after'],
           'restored_content': restore['restored'], 'commit': os.getenv('GITHUB_SHA', 'unknown'),
           'run_url': f'https://github.com/{os.getenv("GITHUB_REPOSITORY", "hamza2829/wordpress-maintenance-lab")}/actions/runs/{os.getenv("GITHUB_RUN_ID", "unknown")}'}
(root / 'metrics.json').write_text(json.dumps(metrics, indent=2) + '\n')
table = (f'| Metric | Measured in CI |\n| --- | ---: |\n| PHPUnit plugin tests | {php} |\n'
         f'| Distinct Playwright tests | {metrics["playwright_distinct_tests"]} |\n'
         f'| Playwright executions across four phases | {metrics["playwright_executions"]} |\n'
         f'| Shell scenarios | {len(shell)} |\n| Distinct cases | {metrics["distinct_test_cases"]} |\n'
         f'| Total executions | {metrics["total_test_executions"]} |\n')
(root / 'metrics.md').write_text(table)
print(json.dumps(metrics, indent=2))
if os.getenv('GITHUB_STEP_SUMMARY'):
    with open(os.environ['GITHUB_STEP_SUMMARY'], 'a', encoding='utf-8') as summary:
        summary.write(table)
for name in filter(None, subprocess.run(['git', 'ls-files', '-z'], check=True, text=True, capture_output=True).stdout.split('\x00')):
    assert chr(0x2014) not in Path(name).read_text(encoding='utf-8'), name

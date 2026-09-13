#!/usr/bin/env python3
"""Run native reference controls in the fully imported project, never hide parse errors."""
from __future__ import annotations
import argparse
from pathlib import Path
import subprocess


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument('--godot', required=True)
    parser.add_argument('--project', type=Path, default=Path(__file__).resolve().parents[1])
    args = parser.parse_args()
    commands = [[args.godot, '--headless', '--editor', '--path', str(args.project), '--import']]
    for script in ('test_reference_native_controls.gd', 'test_reference_terrain_maps.gd'):
        commands.append([args.godot, '--headless', '--path', str(args.project), '--script', 'res://tests/' + script])
    failed = False
    for command in commands:
        result = subprocess.run(command, capture_output=True, text=True, timeout=300)
        output = result.stdout + result.stderr
        print('COMMAND:', ' '.join(command), flush=True)
        # Import progress can be huge; keep complete logs on the runner and show the tail.
        log = Path('reference-native-' + str(commands.index(command)) + '.log')
        log.write_text(output)
        print(output[-30000:], flush=True)
        errors = [line for line in output.splitlines() if any(marker in line for marker in ('SCRIPT ERROR', 'Parse Error', 'Compile Error', 'ERROR:'))]
        if result.returncode != 0 or errors:
            print('\n'.join(errors), flush=True)
            failed = True
            break
    if failed:
        raise SystemExit(1)
    print('Native reference import, control and all-map suites: PASS')


if __name__ == '__main__':
    main()

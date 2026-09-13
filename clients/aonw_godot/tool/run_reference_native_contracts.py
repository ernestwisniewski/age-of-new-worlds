#!/usr/bin/env python3
"""Run native terrain suites and retain every failure, including editor shutdown."""
from __future__ import annotations
import argparse
from pathlib import Path
import subprocess


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument('--godot', required=True)
    parser.add_argument('--project', type=Path, default=Path(__file__).resolve().parents[1])
    args = parser.parse_args()
    commands = [[args.godot, '--headless', '--verbose', '--editor', '--path', str(args.project), '--import']]
    for script in ('test_reference_native_controls.gd', 'test_reference_terrain_maps.gd'):
        commands.append([args.godot, '--headless', '--path', str(args.project), '--script', 'res://tests/' + script])
    failures: list[str] = []
    for index, command in enumerate(commands):
        print('COMMAND:', ' '.join(command), flush=True)
        try:
            result = subprocess.run(command, capture_output=True, text=True, timeout=300)
            output = result.stdout + result.stderr
            returncode = result.returncode
        except subprocess.TimeoutExpired as error:
            stdout = error.stdout or b''
            stderr = error.stderr or b''
            output = (stdout.decode(errors='replace') if isinstance(stdout, bytes) else stdout)
            output += (stderr.decode(errors='replace') if isinstance(stderr, bytes) else stderr)
            output += '\nERROR: Native terrain command timed out.\n'
            returncode = 124
        Path(f'reference-native-{index}.log').write_text(output)
        lines = output.splitlines()
        diagnostic_rows = {row for row, line in enumerate(lines) if any(marker in line for marker in (
            'SCRIPT ERROR', 'Parse Error', 'Compile Error', 'ERROR:', 'Leaked instance', 'Resource still in use'
        ))}
        context_rows: set[int] = set(range(max(0, len(lines) - 35), len(lines)))
        for row in diagnostic_rows:
            context_rows.update(range(max(0, row - 1), min(len(lines), row + 10)))
        print('\n'.join(lines[row] for row in sorted(context_rows)), flush=True)
        if returncode != 0 or diagnostic_rows:
            failures.append(f'Command {index} failed (exit {returncode}): {command[-1]}')
        # Continue independent suites so an editor shutdown error cannot conceal
        # problems in native controls or map generation. The final exit stays red.
    if failures:
        print('\n'.join(failures), flush=True)
        raise SystemExit(1)
    print('Native reference import, control and all-map suites: PASS')


if __name__ == '__main__':
    main()

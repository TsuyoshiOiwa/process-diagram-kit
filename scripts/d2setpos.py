#!/usr/bin/env python3
"""d2 ファイルのノード座標 (top/left) を一括設定・削除する.

usage:
  python3 scripts/d2setpos.py FILE NODE.top=N NODE.left=M ...
  python3 scripts/d2setpos.py FILE --unset NODE.top ...

- 既存の '<node>.top: N' 行は値だけ置換しインデントを維持する
- 該当行が無い場合はノード定義行 (ラベル行・プロパティ行の最後のもの) の直後に挿入する
- 編集後は make fmt / d2 validate で整形・検証すること
"""
import re
import sys


def parse_assign(arg, unset):
    """'NODE.top=N' / (--unset 時は 'NODE.top') を (node, prop, value) に分解する."""
    m = re.fullmatch(r'([\w\-]+)\.(top|left)(?:=(-?\d+))?', arg)
    if not m or (m.group(3) is None and not unset):
        return None
    return m.group(1), m.group(2), (int(m.group(3)) if m.group(3) is not None else None)


def main(argv):
    if len(argv) < 3:
        print(__doc__, file=sys.stderr)
        return 1

    path = argv[1]
    unset = False
    sets = []
    for a in argv[2:]:
        if a == '--unset':
            unset = True
            continue
        parsed = parse_assign(a, unset)
        if parsed is None:
            print(f'invalid arg: {a} (expected NODE.top=N / NODE.left=M)', file=sys.stderr)
            return 1
        sets.append(parsed)

    with open(path, encoding='utf-8') as f:
        lines = f.read().splitlines()

    for node, prop, val in sets:
        esc = re.escape(node)
        pat = re.compile(rf'^(\s*){esc}\.{prop}:\s*(-?\d+)\s*$')
        hit = False
        for i, line in enumerate(lines):
            m = pat.match(line)
            if m:
                if unset:
                    lines[i] = None
                else:
                    lines[i] = f'{m.group(1)}{node}.{prop}: {val}'
                hit = True
                break
        if hit:
            action = 'unset' if unset else 'set  '
            shown = '' if unset else f': {val}'
            print(f'{action} {node}.{prop}{shown}')
            continue
        if unset:
            print(f'not found: {node}.{prop}')
            continue
        anchor = None
        for i, line in enumerate(lines):
            if re.match(rf'^\s*{esc}(:|\.)', line):
                anchor = i
        if anchor is None:
            print(f'node not found: {node}', file=sys.stderr)
            return 1
        indent = re.match(r'^(\s*)', lines[anchor]).group(1)
        lines.insert(anchor + 1, f'{indent}{node}.{prop}: {val}')
        print(f'insert {node}.{prop}: {val}')

    lines = [l for l in lines if l is not None]
    with open(path, 'w', encoding='utf-8') as f:
        f.write('\n'.join(lines) + '\n')
    return 0


if __name__ == '__main__':
    sys.exit(main(sys.argv))

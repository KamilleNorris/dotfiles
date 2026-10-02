#!/usr/bin/env python3
"""Keep a baseline file's contents in a marked block inside a target file.

Only the text between the markers is owned by this script; anything a tool or
the machine adds above or below it is preserved. A target that does not exist
is created with just the block, a target without markers gets the block
appended, and a target that is still a symlink to the baseline (the old linked
setup) is replaced by a real file holding only the block. The previous target
is backed up before every change.
"""
import os
import shutil
import sys
from datetime import datetime
from pathlib import Path

BEGIN = "# >>> dotfiles (managed by install script; edits inside are overwritten) >>>"
END = "# <<< dotfiles <<<"


def render_block(baseline_text):
    return f"{BEGIN}\n{baseline_text.rstrip()}\n{END}\n"


def replace_block(target_text, block):
    """Return the target with its marked block swapped out, or None if unmarked."""
    start = target_text.find(BEGIN)
    end = target_text.find(END, start)
    if start == -1 or end == -1:
        return None
    end += len(END)
    if target_text[end:end + 1] == "\n":
        end += 1
    return target_text[:start] + block + target_text[end:]


def backup(target):
    backup_dir = Path(os.environ.get("BACKUP_DIR", Path.home() / ".agent-config-backups"))
    stamp = os.environ.get("STAMP", datetime.now().strftime("%Y%m%d%H%M%S"))
    name = str(target.relative_to(Path.home()) if target.is_relative_to(Path.home()) else target)
    dest = backup_dir / f"{name.replace('/', '_')}.bak-{stamp}"
    backup_dir.mkdir(parents=True, exist_ok=True)
    shutil.copy(target, dest, follow_symlinks=True)
    return dest


def main():
    baseline, target, dry_run = Path(sys.argv[1]).resolve(), Path(sys.argv[2]), sys.argv[3] == "1"
    block = render_block(baseline.read_text())

    if target.is_symlink() and target.resolve() == baseline:
        new_text, action = block, f"replace {target} link with a file holding the block"
    elif not target.exists():
        new_text, action = block, f"create {target} with the block"
    else:
        target_text = target.read_text()
        new_text = replace_block(target_text, block)
        if new_text is None:
            new_text, action = target_text.rstrip("\n") + "\n\n" + block, f"append the block to {target}"
        elif new_text == target_text:
            print(f"ok    {target}")
            return 0
        else:
            action = f"update the block in {target}"

    if dry_run:
        print(f"would {action}")
        return 0

    kept = backup(target) if target.exists() else None
    if target.is_symlink():
        target.unlink()
    target.write_text(new_text)
    print(action)
    if kept:
        print(f"      previous file kept at {kept}")
    return 0


if __name__ == "__main__":
    sys.exit(main())

"""Pick untracked files and move them to the system trash, never unlink them."""

import argparse
import os
from pathlib import Path
import shutil
import stat
import subprocess
import sys


def repository_root():
    result = subprocess.run(
        ["git", "rev-parse", "--show-toplevel"], capture_output=True, check=False,
    )
    if result.returncode:
        raise ValueError("not inside a Git working tree")
    return Path(os.fsdecode(result.stdout).rstrip("\n")).resolve()


def safe_path(root, name):
    relative = Path(name)
    if relative.is_absolute() or ".." in relative.parts or not relative.parts:
        raise ValueError(f"unsafe path: {name!r}")
    path = root / relative
    # Do not traverse a replaced parent symlink, even if it points inside the repo.
    if path.parent.resolve() != path.parent:
        raise ValueError(f"symlinked parent: {name!r}")
    mode = path.lstat().st_mode
    if not (stat.S_ISREG(mode) or stat.S_ISLNK(mode)):
        raise ValueError(f"not a file or symlink: {name!r}")
    return path


def untracked_files(root):
    result = subprocess.run(
        ["git", "ls-files", "--others", "--exclude-standard", "-z"],
        cwd=root, capture_output=True, check=True,
    )
    files = []
    for raw in result.stdout.split(b"\0"):
        if not raw:
            continue
        name = os.fsdecode(raw)
        try:
            safe_path(root, name)
        except (OSError, ValueError):
            continue
        files.append(name)
    return files


def trash_command():
    for program, args in (("trash-put", []), ("gio", ["trash"]), ("trash", [])):
        executable = shutil.which(program)
        if executable:
            return [executable, *args]
    raise ValueError("no trash tool found; install trash-cli (trash-put), gio, or macOS trash")


def trash_files(root, names):
    command = trash_command()
    errors = []
    for name in dict.fromkeys(names):
        try:
            # Check again per file: it may have been staged or ignored since listing.
            if name not in untracked_files(root):
                raise ValueError(f"no longer an untracked, non-ignored file: {name!r}")
            path = safe_path(root, name)
            result = subprocess.run([*command, "--", str(path)], capture_output=True)
            if result.returncode:
                detail = os.fsdecode(result.stderr).strip()
                raise ValueError(f"could not trash {name!r}: {detail}")
        except (OSError, ValueError, subprocess.CalledProcessError) as error:
            errors.append(str(error))
    return errors


def printable(text):
    return "".join(char if char.isprintable() or char in "\n\t" else "�" for char in text)


def preview(root, name):
    path = safe_path(root, name)
    print(printable(name))
    print()
    if path.is_symlink():
        print(f"Symlink → {printable(os.readlink(path))}")
        return
    # Never follow a symlink substituted after validation.
    descriptor = os.open(path, os.O_RDONLY | os.O_NOFOLLOW | os.O_NONBLOCK)
    with os.fdopen(descriptor, "rb") as source:
        if not stat.S_ISREG(os.fstat(source.fileno()).st_mode):
            raise ValueError("preview is not a regular file")
        data = source.read(65536)
    if b"\0" in data:
        print("Binary file (preview omitted)")
        return
    for number, line in enumerate(data.decode("utf-8", errors="replace").splitlines()[:200], 1):
        print(f"{number:4}  {printable(line)}")


def internal_action(argv):
    root = Path(os.environ["GIT_UNTRACKED_ROOT"])
    action = argv[0]
    names = argv[1:]
    if names[:1] == ["--"]:
        names = names[1:]
    if action == "_list":
        for name in untracked_files(root):
            sys.stdout.buffer.write(os.fsencode(name) + b"\0")
    elif action == "_preview" and names:
        preview(root, names[0])
    elif action == "_trash":
        errors = trash_files(root, names)
        if errors:
            for error in errors:
                print(f"git-untracked: {error}", file=sys.stderr)
            # execute() restores the terminal, so keep failures visible before refresh.
            try:
                with open("/dev/tty", "r+") as terminal:
                    terminal.write("Press Enter to return to the picker…")
                    terminal.flush()
                    terminal.readline()
            except OSError:
                pass
            return 1
    return 0


def main(argv=None):
    argv = sys.argv[1:] if argv is None else argv
    if argv and argv[0] in {"_list", "_preview", "_trash"}:
        return internal_action(argv)
    parser = argparse.ArgumentParser(
        prog="git-untracked",
        description="Pick untracked Git files with fzf. Alt+d moves selected files to trash.",
        epilog="Tab selects multiple files; Esc exits. Ignored files and directories are excluded. "
        "Requires git, fzf, Python 3, and trash-put, gio, or macOS trash. "
        "GIT_UNTRACKED_HOME overrides the installed command directory.",
    )
    parser.parse_args(argv)
    for program in ("git", "fzf"):
        if not shutil.which(program):
            raise ValueError(f"{program} is required")
    root = repository_root()
    files = untracked_files(root)
    if not files:
        print("git-untracked: no untracked files")
        return 0
    trash_command()
    helper = '"$GIT_UNTRACKED_PYTHON" "$GIT_UNTRACKED_HELPER"'
    result = subprocess.run(
        [
            "fzf", "--read0", "--print0", "--multi", "--layout=reverse",
            "--prompt=Untracked> ",
            "--header=Alt+d: trash selected/current | Tab: select | Esc: exit",
            f"--preview={helper} _preview -- {{}}", "--preview-window=up:60%:wrap",
            f"--bind=alt-d:execute({helper} _trash -- {{+}})+reload({helper} _list)",
            "--bind=enter:ignore",
        ],
        cwd=root,
        env={
            **os.environ,
            "GIT_UNTRACKED_ROOT": str(root),
            "GIT_UNTRACKED_HELPER": str(Path(__file__).resolve()),
            "GIT_UNTRACKED_PYTHON": sys.executable,
        },
        input=b"".join(os.fsencode(name) + b"\0" for name in files),
        stdout=subprocess.DEVNULL,
    )
    return 0 if result.returncode in (0, 1, 130) else result.returncode


if __name__ == "__main__":
    try:
        sys.exit(main())
    except (OSError, ValueError, subprocess.CalledProcessError) as error:
        print(f"git-untracked: {error}", file=sys.stderr)
        sys.exit(1)

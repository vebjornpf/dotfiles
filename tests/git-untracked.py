#!/usr/bin/env python3
"""Run with: python3 tests/git-untracked.py. Only temporary fixtures are trashed."""

from contextlib import redirect_stdout
import importlib.util
import io
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest
from unittest.mock import patch


HOME = Path(__file__).resolve().parents[1] / "config/git-untracked/.config/git-untracked"
spec = importlib.util.spec_from_file_location("git_untracked", HOME / "lib/git_untracked.py")
tool = importlib.util.module_from_spec(spec)
spec.loader.exec_module(tool)


class GitUntrackedTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name).resolve()
        self.repo = self.root / "repo"
        self.repo.mkdir()
        self.git("init", "--quiet")
        self.saved_run = subprocess.run
        self.trashed = []

    def git(self, *args):
        return subprocess.run(["git", *args], cwd=self.repo, capture_output=True, check=True)

    def file(self, name, text="contents"):
        path = self.repo / name
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(text)
        return path

    def fake_run(self, command, **kwargs):
        if command[0] != "/fake/trash-put":
            return self.saved_run(command, **kwargs)
        self.assertEqual(command[1], "--")
        path = Path(command[2])
        self.assertTrue(path.is_relative_to(self.repo))
        self.trashed.append(path.relative_to(self.repo).as_posix())
        destination = self.root / "trash" / str(len(self.trashed))
        destination.parent.mkdir(exist_ok=True)
        shutil.move(path, destination)
        return subprocess.CompletedProcess(command, 0, stdout=b"", stderr=b"")

    def trash(self, names):
        with patch.object(tool, "trash_command", return_value=["/fake/trash-put"]):
            with patch.object(tool.subprocess, "run", side_effect=self.fake_run):
                return tool.trash_files(self.repo, names)

    def test_list_excludes_tracked_ignored_and_nested_repository(self):
        self.file("tracked")
        self.git("add", "tracked")
        self.file(".gitignore", "ignored\n")
        self.git("add", ".gitignore")
        self.file("ignored")
        self.file("directory/untracked")
        self.file("nested/file")
        subprocess.run(["git", "init", "--quiet", str(self.repo / "nested")], check=True)
        self.assertEqual(tool.untracked_files(self.repo), ["directory/untracked"])

    def test_trash_handles_special_names_and_deduplicates_selection(self):
        names = ["spaces here", "quote's.txt", "line\nbreak", "-option", "$(touch injected)"]
        for name in names:
            self.file(name)
        self.assertEqual(self.trash(names + names), [])
        self.assertEqual(self.trashed, names)
        self.assertFalse((self.repo / "injected").exists())
        self.assertEqual(tool.untracked_files(self.repo), [])

    def test_newly_staged_or_ignored_files_are_not_trashed(self):
        staged = self.file("staged")
        ignored = self.file("ignored")
        self.git("add", "staged")
        self.file(".gitignore", "ignored\n")
        errors = self.trash(["staged", "ignored"])
        self.assertEqual(len(errors), 2)
        self.assertTrue(staged.exists() and ignored.exists())
        self.assertEqual(self.trashed, [])

    def test_rechecks_each_file(self):
        self.file("first")
        self.file("second")
        original = tool.untracked_files
        calls = []

        def listing(root):
            calls.append(root)
            if len(calls) == 2:
                self.git("add", "second")
            return original(root)

        with patch.object(tool, "untracked_files", side_effect=listing):
            self.assertEqual(len(self.trash(["first", "second"])), 1)
        self.assertEqual(self.trashed, ["first"])

    def test_symlink_is_trashed_not_target(self):
        target = self.root / "outside"
        target.write_text("keep me")
        (self.repo / "link").symlink_to(target)
        self.assertEqual(self.trash(["link"]), [])
        self.assertEqual(target.read_text(), "keep me")
        self.assertTrue((self.root / "trash/1").is_symlink())

    def test_rejects_directories_parent_symlinks_and_escaping_paths(self):
        self.file("directory/file")
        (self.repo / "alias").symlink_to(self.repo / "directory", target_is_directory=True)
        for name in ["directory", "alias/file", "../outside", str(self.root / "outside")]:
            with self.subTest(name=name), self.assertRaises(ValueError):
                tool.safe_path(self.repo, name)

    def test_no_trash_provider_means_no_deletion(self):
        path = self.file("keep")
        with patch.object(tool.shutil, "which", return_value=None):
            with self.assertRaisesRegex(ValueError, "no trash tool"):
                tool.trash_files(self.repo, ["keep"])
        self.assertTrue(path.exists())

    def test_provider_failure_never_falls_back_to_unlink(self):
        path = self.file("keep")
        with patch.object(tool, "trash_command", return_value=["/fake/trash-put"]):
            with patch.object(tool.subprocess, "run", side_effect=lambda command, **kwargs:
                              subprocess.CompletedProcess(command, 1, stdout=b"", stderr=b"unsupported")
                              if command[0] == "/fake/trash-put" else self.saved_run(command, **kwargs)):
                self.assertIn("unsupported", tool.trash_files(self.repo, ["keep"])[0])
        self.assertTrue(path.exists())

    def test_preview_is_bounded_and_does_not_follow_symlinks(self):
        self.file("text", "\n".join(str(i) for i in range(300)))
        output = io.StringIO()
        with redirect_stdout(output):
            tool.preview(self.repo, "text")
        self.assertIn(" 200  199", output.getvalue())
        self.assertNotIn(" 201  200", output.getvalue())
        (self.repo / "link").symlink_to(self.repo / "text")
        output = io.StringIO()
        with redirect_stdout(output):
            tool.preview(self.repo, "link")
        self.assertIn("Symlink →", output.getvalue())
        self.assertNotIn(" 200  199", output.getvalue())

    def test_picker_bindings_root_and_nul_input(self):
        self.file("spaces here")
        captured = {}

        def fzf(command, **kwargs):
            if command[0] == "fzf":
                captured.update(kwargs)
                captured["command"] = command
                return subprocess.CompletedProcess(command, 130)
            return self.saved_run(command, **kwargs)

        with patch.object(tool, "repository_root", return_value=self.repo):
            with patch.object(tool, "trash_command", return_value=["/fake/trash-put"]):
                with patch.object(tool.shutil, "which", return_value="/fake/installed"):
                    with patch.object(tool.subprocess, "run", side_effect=fzf):
                        self.assertEqual(tool.main([]), 0)
        self.assertEqual(captured["cwd"], self.repo)
        self.assertEqual(captured["input"], b"spaces here\0")
        self.assertIn("--read0", captured["command"])
        self.assertIn("--multi", captured["command"])
        self.assertIn("--preview-window=up:60%:wrap", captured["command"])
        self.assertTrue(any("alt-d:execute(" in arg and "{+}" in arg and "+reload(" in arg
                            for arg in captured["command"]))

    def test_root_from_subdirectory(self):
        folder = self.repo / "subdirectory"
        folder.mkdir()
        result = subprocess.run(
            ["python3", "-c", f"import runpy; m=runpy.run_path({str(HOME / 'lib/git_untracked.py')!r}); print(m['repository_root']())"],
            cwd=folder, capture_output=True, text=True, check=True,
        )
        self.assertEqual(result.stdout.strip(), str(self.repo))


if __name__ == "__main__":
    unittest.main()

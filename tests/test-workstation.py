#!/usr/bin/env python3
"""Exercise the workstation policy with OS fixtures, never the real host."""
import os
from pathlib import Path
import shlex
import shutil
import subprocess
import tempfile
import unittest

REPO = Path(__file__).resolve().parents[1]


class WorkstationTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="my-shell-workstation-")
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.bin = self.root / "bin"
        self.bin.mkdir()
        commands = {
            "uname": 'echo "$TEST_KERNEL"; exit "${TEST_UNAME_RC:-0}"',
            "dpkg-query": '[ "$3" = "${TEST_PACKAGE:-ubuntu-desktop}" ] || exit 1; '
                          'echo "${TEST_DPKG_STATUS:-install ok installed}"; exit "${TEST_PACKAGE_RC:-0}"',
            "rpm": 'exit "${TEST_PACKAGE_RC:-0}"',
            "systemd-detect-virt": 'printf "%s\\n" "${TEST_VIRT_OUTPUT-none}"; exit "${TEST_VIRT_RC:-1}"',
            "systemctl": 'case "$1" in get-default) echo "${TEST_TARGET:-graphical.target}" ;; '
                         'show) echo "${TEST_DM:-loaded}" ;; *) exit 1 ;; esac; exit "${TEST_SYSTEMCTL_RC:-0}"',
        }
        for name, body in commands.items():
            path = self.bin / name
            path.write_text("#!/bin/sh\n" + body + "\n")
            path.chmod(0o755)
        self.release = self.root / "os-release"
        self.fixture = self.root / "repo"
        shutil.copytree(REPO / "nvim", self.fixture / "nvim")
        self.detector = self.fixture / "nvim/is-workstation.sh"
        self.detector.write_text(self.detector.read_text().replace("/etc/os-release", shlex.quote(str(self.release))))
        for name in ("bashrc", "tmux.conf"):
            (self.fixture / name).touch()
        self.functions = self.root / "functions.sh"
        self.functions.write_text((REPO / "install.sh").read_text().split("# ---- main ----")[0])

    def environment(self, release='ID=ubuntu\n', **overrides):
        if release is None:
            self.release.unlink(missing_ok=True)
        else:
            self.release.write_text(release)
        return {
            **os.environ,
            "PATH": str(self.bin) + os.pathsep + os.environ["PATH"],
            "HOME": str(self.root / "home"),
            "XDG_CONFIG_HOME": str(self.root / "config"),
            "XDG_DATA_HOME": str(self.root / "data"),
            "XDG_STATE_HOME": str(self.root / "state"),
            "XDG_CACHE_HOME": str(self.root / "cache"),
            "NVIM_LOG_FILE": str(self.root / "nvim.log"),
            "TEST_KERNEL": "Linux",
            # GUI-looking environment variables alone must never grant access.
            "DISPLAY": ":0", "XDG_CURRENT_DESKTOP": "GNOME",
            "ID": "ubuntu", "VARIANT_ID": "workstation",
            **overrides,
        }

    def test_policy_matrix(self):
        cases = [
            ("macOS", True, None, {"TEST_KERNEL": "Darwin"}),
            ("unknown kernel", False, None, {"TEST_KERNEL": "FreeBSD"}),
            ("uname failure", False, None, {"TEST_KERNEL": "Darwin", "TEST_UNAME_RC": "1"}),
            ("Ubuntu Desktop", True, "ID=ubuntu\n", {}),
            ("Ubuntu minimal desktop", True, "ID=ubuntu\n", {"TEST_PACKAGE": "ubuntu-desktop-minimal"}),
            ("Ubuntu server without desktop packages", False, "ID=ubuntu\n", {"TEST_PACKAGE_RC": "1"}),
            ("removed desktop package", False, "ID=ubuntu\n", {"TEST_DPKG_STATUS": "deinstall ok config-files"}),
            ("Ubuntu server variant", False, "ID=ubuntu\nVARIANT_ID=server\n", {}),
            ("headless target", False, "ID=ubuntu\n", {"TEST_TARGET": "multi-user.target"}),
            ("missing display manager", False, "ID=ubuntu\n", {"TEST_DM": "not-found"}),
            ("systemctl failure", False, "ID=ubuntu\n", {"TEST_SYSTEMCTL_RC": "1"}),
            ("container", False, "ID=ubuntu\n", {"TEST_VIRT_RC": "0"}),
            ("virtualization detection error", False, "ID=ubuntu\n", {"TEST_VIRT_RC": "2"}),
            ("ambiguous virtualization failure", False, "ID=ubuntu\n", {"TEST_VIRT_OUTPUT": ""}),
            ("missing virtualization tool", False, "ID=ubuntu\n", {"TEST_VIRT_RC": "127"}),
            ("Fedora Workstation", True, "ID=fedora\nVARIANT_ID=workstation\n", {}),
            ("Fedora Server", False, "ID=fedora\nVARIANT_ID=server\n", {}),
            ("Fedora Cloud", False, "ID=fedora\nVARIANT_ID=cloud\n", {}),
            ("missing Fedora workstation package", False, "ID=fedora\nVARIANT_ID=workstation\n", {"TEST_PACKAGE_RC": "1"}),
            ("inherited variant cannot qualify", False, "ID=fedora\n", {}),
            ("unsupported distro", False, "ID=debian\nID_LIKE=ubuntu\n", {}),
            ("missing OS identity", False, None, {}),
            ("empty OS identity", False, "", {}),
        ]
        for name, allowed, release, overrides in cases:
            with self.subTest(name=name):
                result = subprocess.run(["sh", str(self.detector)], env=self.environment(release, **overrides))
                self.assertEqual(result.returncode, 0 if allowed else 1)

    def test_server_install_and_startup_preserve_existing_plugins(self):
        env = self.environment("ID=ubuntu\n", TEST_PACKAGE_RC="1")
        config = Path(env["XDG_CONFIG_HOME"]) / "nvim"
        (config / "lua/my_shell").mkdir(parents=True)
        plugin = config / "lua/my_shell/plugins.lua"
        plugin.write_text('error("Plugins must not load on servers")\n')
        lock = config / "lazy-lock.json"
        lock.write_text("existing lockfile\n")
        result = subprocess.run(
            ["bash", "-eu", "-c", 'source "$1"; SCRIPT_DIR="$2"; install_neovim',
             "test", str(self.functions), str(self.fixture)],
            env=env, capture_output=True, text=True, check=True,
        )
        self.assertIn("Neovim plugins skipped", result.stdout)
        self.assertEqual(plugin.read_text(), 'error("Plugins must not load on servers")\n')
        self.assertEqual(lock.read_text(), "existing lockfile\n")
        if shutil.which("nvim"):
            subprocess.run(
                ["nvim", "--headless", "-u", str(config / "init.vim"), "-c",
                 'lua if not vim.o.number or package.loaded.lazy or vim.v.errmsg ~= "" then vim.cmd("cquit") end',
                 "-c", "qa!"], env=env, capture_output=True, text=True, check=True,
            )
        self.assertFalse(Path(env["XDG_DATA_HOME"], "nvim/lazy").exists())

    def test_fresh_server_does_not_install_plugin_files(self):
        env = self.environment("ID=fedora\nVARIANT_ID=server\n")
        subprocess.run(
            ["bash", "-eu", "-c", 'source "$1"; SCRIPT_DIR="$2"; install_neovim',
             "test", str(self.functions), str(self.fixture)],
            env=env, capture_output=True, text=True, check=True,
        )
        config = Path(env["XDG_CONFIG_HOME"]) / "nvim"
        self.assertTrue((config / "init.vim").is_file())
        self.assertFalse((config / "lua").exists())
        self.assertFalse((config / "lazy-lock.json").exists())


if __name__ == "__main__":
    unittest.main()

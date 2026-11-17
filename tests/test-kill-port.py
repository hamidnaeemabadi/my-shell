#!/usr/bin/env python3
"""Check port selection and signals without terminating any real processes."""
import os
from pathlib import Path
import subprocess
import tempfile
import unittest

REPO = Path(__file__).resolve().parents[1]


class KillPortTests(unittest.TestCase):
    def test_bash_and_zsh(self):
        with tempfile.TemporaryDirectory(prefix="my-shell-kill-port-") as temp:
            root = Path(temp)
            (root / "lsof").write_text(
                '#!/bin/sh\nprintf "%s\\n" "$@" > "$TEST_LSOF_LOG"\n'
                '[ "${TEST_LSOF_RC:-0}" = 0 ] || exit "$TEST_LSOF_RC"\n'
                'printf "%s" "${TEST_PIDS-22222\n22222\n33333\n}"\n'
            )
            (root / "kill").write_text(
                '#!/bin/sh\nprintf "%s\\n" "$@" > "$TEST_KILL_LOG"\nexit "${TEST_KILL_RC:-0}"\n'
            )
            for name in ("lsof", "kill"):
                (root / name).chmod(0o755)
            lsof_log, kill_log = root / "lsof.log", root / "kill.log"
            env = {
                **os.environ, "PATH": temp + os.pathsep + os.environ["PATH"],
                "TEST_LSOF_LOG": str(lsof_log), "TEST_KILL_LOG": str(kill_log),
            }
            for shell, flags in (("/bin/bash", ["--noprofile", "--norc"]), ("/bin/zsh", ["-f"])):
                def run(args, **overrides):
                    lsof_log.unlink(missing_ok=True)
                    kill_log.unlink(missing_ok=True)
                    return subprocess.run(
                        [shell, *flags, "-c",
                         'if [ -n "${BASH_VERSION:-}" ]; then shopt -s expand_aliases; fi; '
                         '. "$1"; shift; eval \'kill-port "$@"\'', "test",
                         str(REPO / "shell/common.sh"), *args],
                        env={**env, **overrides}, capture_output=True, text=True,
                    )

                for protocol in (None, "tcp", "udp"):
                    with self.subTest(shell=shell, protocol=protocol):
                        args = ["8080"] + ([protocol] if protocol else [])
                        result = run(args)
                        self.assertEqual(result.returncode, 0, result.stderr)
                        self.assertEqual(lsof_log.read_text().splitlines(), ["-t", "-nP", f'-i{protocol or ""}:8080'])
                        self.assertEqual(kill_log.read_text().splitlines(), ["22222", "33333"])

                for args in ([], ["0"], ["65536"], ["999999999999999999999"], ["-1"], ["abc"],
                             ["80;echo bad"], ["80", "sctp"], ["80", "tcp", "extra"]):
                    with self.subTest(shell=shell, invalid=args):
                        self.assertNotEqual(run(args).returncode, 0)
                        self.assertFalse(lsof_log.exists())
                        self.assertFalse(kill_log.exists())

                self.assertEqual(run(["65535"], TEST_PIDS="").returncode, 0)
                self.assertFalse(kill_log.exists())
                self.assertNotEqual(run(["80"], TEST_LSOF_RC="1").returncode, 0)
                self.assertFalse(kill_log.exists())
                self.assertNotEqual(run(["80"], TEST_KILL_RC="1").returncode, 0)


if __name__ == "__main__":
    unittest.main()

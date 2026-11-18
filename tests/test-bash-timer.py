#!/usr/bin/env python3
"""Check the timer hook without loading unrelated interactive shell setup."""
from pathlib import Path
import subprocess
import tempfile
import unittest

REPO = Path(__file__).resolve().parents[1]


class BashTimerTests(unittest.TestCase):
    def test_last_argument_and_exit_status(self):
        bashrc = (REPO / "bashrc").read_text()
        timer = bashrc.split("# Command elapsed time", 1)[1].split("function my_prompt", 1)[0]
        timer = "# Command elapsed time" + timer
        with tempfile.TemporaryDirectory(prefix="my-shell-timer-") as temp:
            result = subprocess.run(
                ["/bin/bash", "--noprofile", "--norc", "-c", timer + '''
mkdir mongodb-backup && cd "$_" || exit 1
[[ "$PWD" == "$1/mongodb-backup" ]] || exit 2
mkdir "directory with spaces" && cd "$_" || exit 3
[[ "$PWD" == "$1/mongodb-backup/directory with spaces" ]] || exit 4
false
[[ $? == 1 ]] || exit 5
[[ "$_cmd_timer_active" == 1 && "$_cmd_just_ran" == 1 && -n "$_cmd_start_time" ]]
''', "test", str(Path(temp).resolve())],
                cwd=temp, capture_output=True, text=True,
            )
            self.assertEqual(result.returncode, 0, result.stderr)


if __name__ == "__main__":
    unittest.main()

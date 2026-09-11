"""Exercise wall-clock containment without Julia or benchmark dependencies."""
from pathlib import Path
import subprocess
import sys
import tempfile
import time
import unittest

from run_pilot import supervise


class SupervisorContracts(unittest.TestCase):
    def launch(self, code, *args):
        return subprocess.Popen([sys.executable, "-c", code, *map(str, args)],
                                start_new_session=True)

    def test_incomplete_ready_marker_and_hard_timeout(self):
        with tempfile.TemporaryDirectory() as directory:
            ready = Path(directory) / "ready"
            worker = self.launch("from pathlib import Path; import sys,time; p=Path(sys.argv[1]); p.touch(); time.sleep(.1); p.write_text(str(time.time())); time.sleep(30)", ready)
            status = supervise(worker, ready, .15, load_seconds=2, poll_seconds=.01)
            self.assertEqual(status, "timeout")
            self.assertIsNotNone(worker.poll())

    def test_package_load_has_its_own_budget(self):
        with tempfile.TemporaryDirectory() as directory:
            worker = self.launch("import time; time.sleep(30)")
            status = supervise(worker, Path(directory) / "absent", 900,
                               load_seconds=.1, poll_seconds=.01)
            self.assertEqual(status, "package_load_timeout")
            self.assertIsNotNone(worker.poll())

    def test_monitor_failure_stops_worker(self):
        with tempfile.TemporaryDirectory() as directory:
            ready = Path(directory) / "ready"
            ready.write_text("invalid timestamp")
            worker = self.launch("import time; time.sleep(30)")
            with self.assertRaises(ValueError):
                supervise(worker, ready, 900, poll_seconds=.01)
            self.assertIsNotNone(worker.poll())

    def test_normal_exit(self):
        with tempfile.TemporaryDirectory() as directory:
            worker = self.launch("pass")
            self.assertIsNone(supervise(worker, Path(directory) / "absent", 900,
                                       load_seconds=2, poll_seconds=.01))
            self.assertEqual(worker.returncode, 0)


if __name__ == "__main__":
    unittest.main()

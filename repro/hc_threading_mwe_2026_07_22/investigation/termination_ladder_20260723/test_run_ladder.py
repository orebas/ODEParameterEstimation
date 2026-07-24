#!/usr/bin/env python3

import contextlib
import io
from pathlib import Path
import tempfile
import unittest

from run_ladder import (
    CASES,
    build_summary,
    classify_outcome,
    main,
    parse_ready_line,
    verify_ready_provenance,
)


def record(**overrides):
    value = {
        "process_group_gone": True,
        "ready_observed": True,
        "ready_status": "ready",
        "term_attempted": True,
        "sigterm_sent": True,
        "term_exit_seconds": 0.1,
        "kill_attempted": False,
        "sigkill_sent": False,
        "provenance_verified": True,
    }
    value.update(overrides)
    return value


class ClassificationTests(unittest.TestCase):
    def test_term_exit_requires_successful_term_delivery(self):
        self.assertEqual(classify_outcome(record()), "term_exit")
        self.assertEqual(
            classify_outcome(record(sigterm_sent=False)),
            "term_not_delivered",
        )

    def test_ready_process_that_exits_before_attempt_is_distinct(self):
        self.assertEqual(
            classify_outcome(record(term_attempted=False, sigterm_sent=False)),
            "exit_after_ready_before_term",
        )

    def test_sigkill_and_cleanup_failure_are_not_term_success(self):
        self.assertEqual(
            classify_outcome(record(sigkill_sent=True)),
            "kill_required",
        )
        self.assertEqual(
            classify_outcome(record(process_group_gone=False)),
            "cleanup_failed",
        )

    def test_grace_boundary_without_kill_delivery_is_not_term_success(self):
        self.assertEqual(
            classify_outcome(
                record(
                    term_exit_seconds=None,
                    kill_attempted=True,
                    sigkill_sent=False,
                )
            ),
            "term_grace_expired",
        )

    def test_readiness_failures_remain_distinct(self):
        self.assertEqual(
            classify_outcome(
                record(
                    ready_observed=False,
                    ready_status="ready_timeout",
                )
            ),
            "ready_timeout",
        )
        self.assertEqual(
            classify_outcome(
                record(
                    ready_observed=False,
                    ready_status="exited_before_ready",
                )
            ),
            "startup_failed",
        )


class ReadyLineTests(unittest.TestCase):
    def test_exact_line_requires_case_pid_and_required_fields(self):
        line = (
            b"READY\tcase=base_idle\tpid=123\tjulia=1.12.6"
            b"\tjulia_executable=/julia\tactive_project=/Project.toml"
            b"\tload_path=/project;@stdlib\tdepot_path=/depot"
            b"\tthreads=7\tgc_threads=7"
        )
        fields = parse_ready_line(line, "base_idle", 123)
        self.assertIsNotNone(fields)
        self.assertIsNone(parse_ready_line(line, "base_idle", 124))
        self.assertIsNone(parse_ready_line(b"prefix " + line, "base_idle", 123))
        self.assertIsNone(
            parse_ready_line(
                b"READY\tcase=base_idle\tpid=123",
                "base_idle",
                123,
            )
        )

    def test_odepe_line_requires_provenance_fields(self):
        common = (
            b"READY\tcase=odepe_idle\tpid=9\tjulia=1.12.6"
            b"\tjulia_executable=/julia\tactive_project=/source/Project.toml"
            b"\tload_path=/source/Project.toml;@stdlib\tdepot_path=/depot"
            b"\tthreads=7\tgc_threads=7"
        )
        self.assertIsNone(parse_ready_line(common, "odepe_idle", 9))
        complete = (
            common
            + b"\todepe=1.0\todepe_path=/source/src/ODEParameterEstimation.jl"
            + b"\tsource_root=/source"
            + b"\tsource_commit=aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
            + b"\tsource_tree=bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb"
            + b"\tsource_dirty=false"
        )
        self.assertIsNotNone(parse_ready_line(complete, "odepe_idle", 9))

        fields = parse_ready_line(complete, "odepe_idle", 9)
        verified, checks = verify_ready_provenance(
            "odepe_idle",
            fields,
            "/julia",
            "/source",
        )
        self.assertTrue(verified)
        self.assertTrue(all(checks.values()))


class SummaryCompletenessTests(unittest.TestCase):
    def test_empty_and_partial_records_never_pass(self):
        selected = (CASES[0],)
        empty = build_summary({"repetitions": 1}, [], selected)
        self.assertFalse(empty["complete"])
        self.assertFalse(empty["all_ready"])
        self.assertFalse(empty["all_exited_on_term"])
        self.assertFalse(empty["all_provenance_verified"])

        partial_record = dict(
            record(),
            case="base_idle",
            ready_seconds=0.1,
            term_exit_seconds=0.1,
            term_grace_elapsed_seconds=0.1,
            kill_cleanup_elapsed_seconds=None,
            outcome="term_exit",
        )
        partial = build_summary(
            {"repetitions": 2},
            [partial_record],
            selected,
        )
        self.assertFalse(partial["complete"])
        self.assertFalse(partial["all_exited_on_term"])


class ArgumentContractTests(unittest.TestCase):
    def test_odepe_case_requires_expected_root_before_output_creation(self):
        with tempfile.TemporaryDirectory() as directory:
            output = Path(directory) / "capture"
            with contextlib.redirect_stderr(io.StringIO()):
                exit_code = main(
                    [
                        "--output",
                        str(output),
                        "--case",
                        "odepe_idle",
                        "--repetitions",
                        "1",
                    ]
                )
            self.assertEqual(exit_code, 64)
            self.assertFalse(output.exists())


if __name__ == "__main__":
    unittest.main()

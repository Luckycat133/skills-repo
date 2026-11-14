"""Offline CI contract tests, not native Windows/official-validator proof."""
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
WORKFLOW = ROOT / '.github/workflows/validate.yml'


class ValidationCI(unittest.TestCase):
    def test_utf8_is_enabled_for_all_job_processes(self):
        text = WORKFLOW.read_text(encoding='utf-8')
        self.assertRegex(text, r"(?m)^    env:\n(?:      #[^\n]*\n)*      PYTHONUTF8: '1'$")
        env = dict(os.environ, PYTHONUTF8='1', LC_ALL='C')
        with tempfile.TemporaryDirectory() as temp:
            path = Path(temp) / 'SKILL.md'
            path.write_text('迁移上下文 🧭', encoding='utf-8')
            result = subprocess.run([sys.executable, '-c',
                'import pathlib,sys; assert sys.flags.utf8_mode == 1; '
                'assert pathlib.Path(sys.argv[1]).read_text() == "迁移上下文 🧭"',
                str(path)], env=env, capture_output=True)
            self.assertEqual(result.returncode, 0, result.stderr)

    def test_each_validator_has_its_own_unconditional_step(self):
        text = WORKFLOW.read_text(encoding='utf-8')
        commands = re.findall(r'^        run: (skills-ref validate .+)$', text, re.M)
        self.assertEqual(commands, [
            'skills-ref validate skills/agent-skills-setup',
            'skills-ref validate dev/skills/maintain-agent-skills-setup'])
        self.assertNotIn('continue-on-error:', text)
        self.assertNotIn('if: always()', text)

    @unittest.skipUnless(shutil.which('bash'), 'Bash unavailable; no native Windows claim')
    def test_individual_commands_preserve_failure_exit_codes(self):
        commands = re.findall(r'^        run: (skills-ref validate .+)$',
                              WORKFLOW.read_text(encoding='utf-8'), re.M)
        self.assertEqual(len(commands), 2)
        # A stub validates the CI command shape/exit status, not Skill semantics.
        with tempfile.TemporaryDirectory() as temp:
            validator = Path(temp) / 'skills-ref'
            validator.write_text('#!/bin/sh\nexit "$VALIDATOR_STATUS"\n', encoding='utf-8')
            validator.chmod(0o755)
            for command in commands:
                for status in (0, 7):
                    with self.subTest(command=command, status=status):
                        env = dict(os.environ, PATH=temp+os.pathsep+os.environ['PATH'],
                                   VALIDATOR_STATUS=str(status))
                        result = subprocess.run(['bash', '--noprofile', '--norc', '-e', '-c', command], env=env)
                        self.assertEqual(result.returncode, status)

import unittest
from abc import abstractproperty
from fuel_test.ci.ci_base import CiBase
from fuel_test.settings import ERROR_PREFIX, WARNING_PREFIX
from helpers import upload_recipes, upload_keys

class BaseTestCase(unittest.TestCase):
    @abstractproperty
    def ci(self):
        """
        :rtype : CiBase
        """
        pass

    def environment(self):
        return self.ci().environment()

    def nodes(self):
        return self.ci().nodes()

    def remote(self):
        return self.environment().node_by_name('master').remote(
            'public',
            login='root',
            password='r00tme')

    def update_modules(self):
        upload_recipes(self.remote())
        upload_keys(self.remote())

    def assertResult(self, result):
        stderr = filter(lambda x: x.find('PYCURL ERROR 22') == -1, result['stderr'])
        stderr = filter(lambda x: x.find('Trying other mirror.') == -1, stderr)
        self.assertEqual([], stderr, stderr)
        errors, warnings = self.parse_out(result['stdout'])
        self.assertEqual([], errors, errors)
        self.assertEqual([], warnings, warnings)

    def parse_out(self, out):
        errors = []
        warnings = []
        for line in out:
            if (line.find(ERROR_PREFIX) < 15) and (
                line.find(ERROR_PREFIX) != -1):
                if line.find("Loading failed for one or more files") == -1:
                    errors.append(line)
            if (line.find(WARNING_PREFIX) < 15) and (
                line.find(WARNING_PREFIX) != -1):
                if line.find(
                    '# Warning: Disabling this option means that a compromised guest can') == -1:
                    if line.find("Loading failed for one or more files") == -1:
                        warnings.append(line)
        return errors, warnings

    def do(self, nodes, command):
        results = []
        for node in nodes:
            remote = node.remote('internal', login='root', password='r00tme')
            results.append(remote.sudo.ssh.execute(command, verbose=True))
        return results

    def validate(self, nodes, command):
        results = self.do(nodes, command)
        for result in results:
            self.assertResult(result)



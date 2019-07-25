"""
test for the api module.
"""

import unittest

from psesmond import *

from base_test import PschedTestBase


class TestPsesmond(PschedTestBase):
    """
    Esmond utility tests
    """

    def test_psesmond(self):
        """taken from api.__main__"""

        self.assertEqual(1, 1)


if __name__ == '__main__':
    unittest.main()

"""
Tests for pymsschooldata Python wrapper.

Minimal smoke tests - the actual data logic is tested by R testthat.
These just verify the Python wrapper imports and exposes expected functions.
"""

import pytest


def test_import_package():
    """Package imports successfully."""
    import pymsschooldata
    assert pymsschooldata is not None


def test_has_fetch_enr():
    """fetch_enr function is available."""
    import pymsschooldata
    assert hasattr(pymsschooldata, 'fetch_enr')
    assert callable(pymsschooldata.fetch_enr)


def test_has_get_available_years():
    """get_available_years function is available."""
    import pymsschooldata
    assert hasattr(pymsschooldata, 'get_available_years')
    assert callable(pymsschooldata.get_available_years)


def test_has_version():
    """Package has a version string."""
    import pymsschooldata
    assert hasattr(pymsschooldata, '__version__')
    assert isinstance(pymsschooldata.__version__, str)

import os
import pytest

def test_manifest_directory_exists():
    manifests_dir = os.path.join(os.path.dirname(__file__), '..', 'backups')
    assert os.path.exists(manifests_dir), "Backups directory should exist"

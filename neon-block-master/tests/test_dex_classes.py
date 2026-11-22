import struct
import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'tools'))
from dex_classes import defined_classes


def dex_with_missing_dependency():
    # Wrapper is defined; SDK descriptor is present only as a referenced type.
    names = [b'Lwrapper/Plugin;', b'Lsdk/MobileAds;']
    data = bytearray(160)
    data[:8] = b'dex\n035\0'
    for offset, value in [(40, 0x12345678), (56, 2), (60, 112),
                          (64, 2), (68, 120), (96, 1), (100, 128),
                          (120, 0), (124, 1), (128, 0)]:
        struct.pack_into('<I', data, offset, value)
    for index, name in enumerate(names):
        struct.pack_into('<I', data, 112 + index * 4, len(data))
        data.extend(bytes([len(name)]) + name + b'\0')
    return bytes(data)


class DexClassesTest(unittest.TestCase):
    def test_references_do_not_count_as_definitions(self):
        data = dex_with_missing_dependency()
        self.assertIn(b'Lsdk/MobileAds;', data)
        self.assertEqual(defined_classes(data), {'Lwrapper/Plugin;'})

    def test_sdk_definition_is_recognized(self):
        data = bytearray(dex_with_missing_dependency())
        struct.pack_into('<I', data, 128, 1)
        self.assertEqual(defined_classes(bytes(data)), {'Lsdk/MobileAds;'})

    def test_truncated_table_is_rejected(self):
        with self.assertRaises(ValueError):
            defined_classes(dex_with_missing_dependency()[:128])

    def test_invalid_header_is_rejected(self):
        with self.assertRaises(ValueError):
            defined_classes(b'not dex')

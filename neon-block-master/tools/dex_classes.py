"""Read DEX class definitions, excluding names that are only references."""
import struct


def defined_classes(data):
    if len(data) < 112 or not data.startswith(b'dex\n') or data[7] != 0:
        raise ValueError('Invalid DEX header')

    def u32(offset):
        if offset < 0 or offset + 4 > len(data):
            raise ValueError('Truncated DEX table')
        return struct.unpack_from('<I', data, offset)[0]

    if u32(40) != 0x12345678:
        raise ValueError('Unsupported DEX byte order')
    string_count, string_offset = u32(56), u32(60)
    type_count, type_offset = u32(64), u32(68)
    class_count, class_offset = u32(96), u32(100)
    for count, offset, width in [(string_count, string_offset, 4),
                                 (type_count, type_offset, 4),
                                 (class_count, class_offset, 32)]:
        if offset + count * width > len(data):
            raise ValueError('Truncated DEX table')

    result = set()
    for index in range(class_count):
        type_index = u32(class_offset + index * 32)
        if type_index >= type_count:
            raise ValueError('Invalid DEX class type')
        string_index = u32(type_offset + type_index * 4)
        if string_index >= string_count:
            raise ValueError('Invalid DEX descriptor')
        position = u32(string_offset + string_index * 4)
        # Skip the UTF-16 length, encoded as ULEB128.
        for _ in range(5):
            if position >= len(data):
                raise ValueError('Truncated DEX string')
            byte = data[position]
            position += 1
            if byte < 128:
                break
        else:
            raise ValueError('Invalid DEX string length')
        end = data.find(b'\0', position)
        if end < 0:
            raise ValueError('Unterminated DEX string')
        result.add(data[position:end].decode('utf-8', errors='replace'))
    return result

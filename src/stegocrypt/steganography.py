"""Least-significant-bit embedding for lossless PNG images."""

from pathlib import Path

from PIL import Image

MAGIC = b"STG1"
HEADER_SIZE = len(MAGIC) + 4


def _to_bits(data: bytes) -> list[int]:
    return [(byte >> shift) & 1 for byte in data for shift in range(7, -1, -1)]


def _from_bits(bits: list[int]) -> bytes:
    output = bytearray()
    for start in range(0, len(bits), 8):
        byte = 0
        for bit in bits[start:start + 8]:
            byte = (byte << 1) | bit
        output.append(byte)
    return bytes(output)


def encode(input_path: str | Path, output_path: str | Path, payload: bytes) -> None:
    image = Image.open(input_path).convert("RGBA")
    pixels = list(image.getdata())
    data = MAGIC + len(payload).to_bytes(4, "big") + payload
    bits = _to_bits(data)
    capacity = len(pixels) * 3
    if len(bits) > capacity:
        raise ValueError(
            f"Message is too large for this image ({len(bits)} bits needed, {capacity} available)"
        )

    encoded = []
    bit_index = 0
    for red, green, blue, alpha in pixels:
        channels = [red, green, blue]
        for channel_index in range(3):
            if bit_index < len(bits):
                channels[channel_index] = (channels[channel_index] & 0xFE) | bits[bit_index]
                bit_index += 1
        encoded.append((*channels, alpha))

    image.putdata(encoded)
    image.save(output_path, format="PNG")


def decode(image_path: str | Path) -> bytes:
    image = Image.open(image_path).convert("RGBA")
    bits = []
    for red, green, blue, _alpha in image.getdata():
        bits.extend((red & 1, green & 1, blue & 1))

    header = _from_bits(bits[:HEADER_SIZE * 8])
    if header[:len(MAGIC)] != MAGIC:
        raise ValueError("No StegoCrypt payload found in this image")
    payload_size = int.from_bytes(header[len(MAGIC):], "big")
    end = (HEADER_SIZE + payload_size) * 8
    if end > len(bits):
        raise ValueError("Hidden payload is incomplete")
    return _from_bits(bits[HEADER_SIZE * 8:end])

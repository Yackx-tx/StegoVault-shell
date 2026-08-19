from PIL import Image

from stegocrypt.crypto import decrypt, encrypt
from stegocrypt.steganography import decode, encode


def test_encrypted_message_round_trip(tmp_path):
    source = tmp_path / "source.png"
    encoded = tmp_path / "encoded.png"
    Image.new("RGB", (100, 100), (120, 80, 40)).save(source)

    payload = encrypt("A private note", "correct horse")
    encode(source, encoded, payload)

    assert decrypt(decode(encoded), "correct horse") == "A private note"


def test_wrong_password_is_rejected(tmp_path):
    source = tmp_path / "source.png"
    encoded = tmp_path / "encoded.png"
    Image.new("RGB", (100, 100), (120, 80, 40)).save(source)

    encode(source, encoded, encrypt("A private note", "correct horse"))

    try:
        decrypt(decode(encoded), "wrong password")
    except ValueError as error:
        assert "check the password" in str(error)
    else:
        raise AssertionError("wrong password was accepted")

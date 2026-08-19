"""Password-based authenticated encryption helpers."""

import os

from cryptography.hazmat.primitives.ciphers.aead import AESGCM
from cryptography.hazmat.primitives.kdf.scrypt import Scrypt

SALT_SIZE = 16
NONCE_SIZE = 12
KEY_SIZE = 32


def _derive_key(password: str, salt: bytes) -> bytes:
    if not password:
        raise ValueError("Password cannot be empty")
    return Scrypt(
        salt=salt,
        length=KEY_SIZE,
        n=2**14,
        r=8,
        p=1,
    ).derive(password.encode("utf-8"))


def encrypt(message: str, password: str) -> bytes:
    salt = os.urandom(SALT_SIZE)
    nonce = os.urandom(NONCE_SIZE)
    key = _derive_key(password, salt)
    ciphertext = AESGCM(key).encrypt(nonce, message.encode("utf-8"), None)
    return salt + nonce + ciphertext


def decrypt(payload: bytes, password: str) -> str:
    minimum_size = SALT_SIZE + NONCE_SIZE + 16
    if len(payload) < minimum_size:
        raise ValueError("Hidden payload is incomplete")
    salt = payload[:SALT_SIZE]
    nonce = payload[SALT_SIZE:SALT_SIZE + NONCE_SIZE]
    ciphertext = payload[SALT_SIZE + NONCE_SIZE:]
    key = _derive_key(password, salt)
    try:
        plaintext = AESGCM(key).decrypt(nonce, ciphertext, None)
    except Exception as error:
        raise ValueError("Could not decrypt payload; check the password") from error
    return plaintext.decode("utf-8")

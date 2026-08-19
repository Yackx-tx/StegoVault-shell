"""Command-line interface for StegoCrypt."""

import argparse
import getpass
from pathlib import Path
import sys

from .crypto import decrypt, encrypt
from .steganography import decode, encode


def _build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        prog="StegoVault",
        description="Encrypt private messages inside PNG images",
    )
    commands = parser.add_subparsers(dest="command", required=True)

    encode_parser = commands.add_parser("encode", help="encrypt and hide a message")
    encode_parser.add_argument("-i", "--input", required=True, help="source PNG image")
    encode_parser.add_argument(
        "-o", "--output", help="output PNG image (default: encrypted/<input>_encrypted.png)"
    )
    source = encode_parser.add_mutually_exclusive_group()
    source.add_argument("-m", "--message", help="message to hide")
    source.add_argument("-f", "--file", help="text file containing the message")
    encode_parser.add_argument("-p", "--password", help="encryption password (prompted if omitted)")

    decode_parser = commands.add_parser("decode", help="extract and decrypt a message")
    decode_parser.add_argument("-i", "--input", required=True, help="encoded PNG image")
    decode_parser.add_argument("-p", "--password", help="decryption password (prompted if omitted)")
    decode_parser.add_argument(
        "-o", "--output", help="text output file (default: decrypted/<input>.txt)"
    )
    return parser


def main() -> int:
    args = _build_parser().parse_args()
    try:
        if args.command == "encode":
            message = args.message
            if args.file:
                with open(args.file, "r", encoding="utf-8") as message_file:
                    message = message_file.read()
            if message is None:
                message = input("Message to hide: ")
            password = args.password or getpass.getpass("Encryption password: ")
            output_path = Path(args.output) if args.output else _default_encoded_path(args.input)
            output_path.parent.mkdir(parents=True, exist_ok=True)
            encode(args.input, output_path, encrypt(message, password))
            print(f"Encrypted image written to {output_path.resolve()}")
        else:
            password = args.password or getpass.getpass("Decryption password: ")
            message = decrypt(decode(args.input), password)
            output_path = Path(args.output) if args.output else _default_decoded_path(args.input)
            output_path.parent.mkdir(parents=True, exist_ok=True)
            with open(output_path, "w", encoding="utf-8") as message_file:
                message_file.write(message)
            print(f"Decrypted message written to {output_path.resolve()}")
        return 0
    except (OSError, ValueError) as error:
        print(f"Error: {error}", file=sys.stderr)
        return 1


def _default_encoded_path(input_path: str) -> Path:
    source = Path(input_path)
    return Path("encrypted") / f"{source.stem}_encrypted.png"


def _default_decoded_path(input_path: str) -> Path:
    source = Path(input_path)
    return Path("decrypted") / f"{source.stem}.txt"


if __name__ == "__main__":
    raise SystemExit(main())

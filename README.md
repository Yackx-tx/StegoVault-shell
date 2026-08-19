# StegoVault

StegoVault is an open-source Bash application for hiding encrypted private messages inside PNG images. The sender encrypts a message into an image, shares the resulting PNG, and the recipient uses the same project and password to recover the message.

The Bash application is a shell interface around the StegoVault Python engine. Messages are encrypted with authenticated AES-GCM before they are embedded with PNG least-significant-bit steganography.

## Project Information

- Application: StegoVault v0.1.0
- Author: Yannick Gisubizo
- Website: https://yackx.vercel.app
- GitHub: https://github.com/Yackx-tx
- License: MIT

## Requirements

- Python 3.10 or newer
- Bash 4 or newer
- A PNG image as the carrier image
- Git, if installing from GitHub

On Windows, use Git Bash or WSL. JPEG images are not supported as output because JPEG compression can destroy hidden data.

## Install From GitHub

```bash
git clone https://github.com/Yackx-tx/StegoVault-shell
cd StegoVault-shell
chmod +x install.sh stegovault.sh
./install.sh
```

The installer installs the Python dependencies and registers the local Python package. It does not store passwords or create credentials.

## Launch The Application

Start the interactive application with:

```bash
./stegovault.sh
```

The menu provides two toggleable actions:

1. Press `e` to toggle Encryption.
2. Press `d` to toggle Decryption.
3. Press `r` to run the selected actions.
4. Enter the input image, message, password, and result paths when prompted.
5. Press `q` to quit.

Encryption and decryption can both be selected in one session. Each selected action runs in sequence with its own prompts.

## Encrypt A Message

Interactive mode:

```bash
./stegovault.sh
```

Direct mode:

```bash
./stegovault.sh encrypt \
	--input input.png \
	--output encrypted/share.png \
	--message "Private message"
```

If `--password` is omitted, the password is requested privately and is not displayed while typing. For a message stored in a text file:

```bash
./stegovault.sh encrypt \
	--input input.png \
	--output encrypted/share.png \
	--file secret.txt
```

The output path may contain spaces when quoted:

```bash
./stegovault.sh encrypt \
	--input "my photos/input image.png" \
	--output "encrypted/my private image.png" \
	--message "Private message"
```

Share the generated PNG with the recipient. Share the password through a separate trusted channel, not in the same message or file transfer.

## Decrypt A Message

```bash
./stegovault.sh decrypt \
	--input encrypted/share.png \
	--output decrypted/message.txt
```

The password is requested privately when `--password` is omitted. The recovered plaintext is written to the selected text file.

The underlying Python command is also available:

```bash
python3 -m stegocrypt decode \
	--input encrypted/share.png \
	--output decrypted/message.txt
```

## Command Options

| Option | Meaning |
| --- | --- |
| `encrypt` or `encode` | Encrypt and embed a message |
| `decrypt` or `decode` | Extract and decrypt a message |
| `-i`, `--input` | Input PNG image path |
| `-o`, `--output` | Output image or text path |
| `-m`, `--message` | Message to encrypt |
| `-f`, `--file` | Text file whose contents will be encrypted |
| `-p`, `--password` | Password; omit this to be prompted privately |
| `-h`, `--help` | Show application help |

Use `./stegovault.sh --help` for the same options from the terminal.

## Output And Logs

The application creates these directories when needed:

- `encrypted/`: recommended location for shareable encrypted PNG files
- `decrypted/`: recommended location for recovered messages
- `logs/`: timestamped application errors and successful operation records

The default generated paths from the Python engine are `encrypted/<input>_encrypted.png` and `decrypted/<input>.txt`. Direct Bash mode uses the paths supplied with `--output`.

Generated images, decrypted text files, and logs are ignored by Git through `.gitignore`. Do not commit private messages or passwords.

## Security Notes

- The password is not embedded in the image.
- AES-GCM provides encryption and tamper detection.
- A wrong password or modified image causes decryption to fail.
- Never use the same weak password for important messages.
- Do not put passwords directly in shell history or shared scripts. Omit `--password` to use the hidden prompt.
- Use PNG from encryption through sharing and decryption. Do not re-save it as JPEG.
- Steganography is not a guarantee that an image will avoid detection. It hides the payload but does not make communication anonymous.
- Anyone with the image and password can recover the message.

## Troubleshooting

### Python package is not installed

Run the installer again:

```bash
./install.sh
```

### Bash cannot execute the script

Make the script executable:

```bash
chmod +x stegovault.sh install.sh
```

On Windows, launch Git Bash or WSL and run the commands there.

### Message is too large

Use a larger PNG image or shorten the message. The available payload depends on the image dimensions and color channels.

### Decryption fails

Confirm that the password is exact, that the image is the generated PNG, and that no service converted or compressed the image. Review `logs/stegovault.log` for the recorded error.

## Development

Install dependencies and run the tests:

```bash
python3 -m pip install -r requirements.txt
python3 -m pytest -q
bash -n stegovault.sh install.sh
```

GitHub Actions runs these checks automatically for pushes and pull requests.

## Contributing

1. Fork the repository.
2. Create a focused branch for your change.
3. Add or update tests for behavior changes.
4. Run the development checks.
5. Open a pull request with a clear description.

Please do not include real passwords, private messages, or personal images in commits or tests.

## License

StegoVault is released under the MIT License. See [LICENSE](LICENSE).

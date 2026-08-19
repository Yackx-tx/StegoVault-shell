#!/usr/bin/env bash

set -u

APP_NAME="StegoVault"
APP_VERSION="0.1.0"
APP_AUTHOR="Yannick Gisubizo"
APP_WEBSITE="https://yackx.vercel.app"
APP_GITHUB="https://github.com/Yackx-tx"
APP_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_DIR="$APP_ROOT/logs"
LOG_FILE="$LOG_DIR/stegovault.log"
PYTHON_BIN="${PYTHON_BIN:-python3}"

mkdir -p "$LOG_DIR"

print_identity() {
    printf '%s v%s\n' "$APP_NAME" "$APP_VERSION"
    printf 'Author: %s\n' "$APP_AUTHOR"
    printf 'Website: %s\n' "$APP_WEBSITE"
    printf 'GitHub:  %s\n' "$APP_GITHUB"
}

log() {
    printf '[%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*" >> "$LOG_FILE"
}

fail() {
    printf 'Error: %s\n' "$*" >&2
    log "ERROR: $*"
    return 1
}

usage() {
    print_identity
    printf '\n'
    cat <<'EOF'
Bash application for encrypted messages hidden in PNG images.

Interactive mode:
  ./stegovault.sh

Direct mode:
  ./stegovault.sh encrypt -i input.png -o encrypted.png -m "private message"
  ./stegovault.sh decrypt -i encrypted.png -o message.txt

Options:
  -p, --password PASSWORD  Password (omit to enter it privately)
  -m, --message MESSAGE    Message for encryption
  -f, --file FILE          Text file to encrypt instead of --message
  -i, --input FILE         Input PNG image
  -o, --output FILE        Result path
  -h, --help               Show this help
EOF
}

run_engine() {
    if ! command -v "$PYTHON_BIN" >/dev/null 2>&1; then
        fail "Python was not found. Set PYTHON_BIN or install Python 3.10+."
        return 1
    fi
    if ! "$PYTHON_BIN" -c 'import stegocrypt' >/dev/null 2>&1; then
        fail "StegoVault Python package is not installed. Run ./install.sh first."
        return 1
    fi
}

encrypt_action() {
    local input_path="${1:-}" output_path="${2:-}" password="${3:-}" message="${4:-}" message_file="${5:-}"
    local -a engine_args
    [ -n "$input_path" ] || { read -r -p "PNG image to encrypt: " input_path; }
    [ -n "$message_file" ] || [ -n "$message" ] || read -r -p "Message to hide: " message
    [ -n "$password" ] || read -r -s -p "Encryption password: " password; printf '\n'
    [ -n "$output_path" ] || { read -r -p "Output PNG path [encrypted/result.png]: " output_path; output_path="${output_path:-encrypted/result.png}"; }

    engine_args=("$PYTHON_BIN" -m stegocrypt encode -i "$input_path" -o "$output_path")
    if [ -n "$message_file" ]; then
        engine_args+=( -f "$message_file" )
    else
        engine_args+=( -m "$message" )
    fi
    engine_args+=( -p "$password" )
    "${engine_args[@]}" 2>>"$LOG_FILE"
    local status=$?
    if [ "$status" -eq 0 ]; then
        printf 'Encrypted image saved to %s\n' "$output_path"
        log "Encrypted $input_path to $output_path"
    else
        fail "Encryption failed. See $LOG_FILE"
    fi
    return "$status"
}

decrypt_action() {
    local input_path="${1:-}" output_path="${2:-}" password="${3:-}"
    [ -n "$input_path" ] || { read -r -p "Encrypted PNG image: " input_path; }
    [ -n "$password" ] || read -r -s -p "Decryption password: " password; printf '\n'
    [ -n "$output_path" ] || { read -r -p "Message output path [decrypted/message.txt]: " output_path; output_path="${output_path:-decrypted/message.txt}"; }

    "$PYTHON_BIN" -m stegocrypt decode -i "$input_path" -o "$output_path" -p "$password" 2>>"$LOG_FILE"
    local status=$?
    if [ "$status" -eq 0 ]; then
        printf 'Message saved to %s\n' "$output_path"
        log "Decrypted $input_path to $output_path"
    else
        fail "Decryption failed. See $LOG_FILE"
    fi
    return "$status"
}

interactive_mode() {
    local encrypt_enabled=0 decrypt_enabled=0 choice
    while true; do
        clear 2>/dev/null || true
        print_identity
        printf '\n'
        printf '[%s] Encryption\n' "$([ "$encrypt_enabled" -eq 1 ] && printf 'x' || printf ' ')"
        printf '[%s] Decryption\n\n' "$([ "$decrypt_enabled" -eq 1 ] && printf 'x' || printf ' ')"
        printf 'Toggle: [e] encryption  [d] decryption\n'
        printf 'Run:    [r] selected actions  [q] quit\n\n'
        read -r -p 'Choose: ' choice
        case "$choice" in
            e|E) encrypt_enabled=$((1 - encrypt_enabled)) ;;
            d|D) decrypt_enabled=$((1 - decrypt_enabled)) ;;
            r|R)
                [ "$encrypt_enabled" -eq 1 ] && encrypt_action || true
                [ "$decrypt_enabled" -eq 1 ] && decrypt_action || true
                [ "$encrypt_enabled" -eq 0 ] && [ "$decrypt_enabled" -eq 0 ] && printf 'Select at least one action.\n'
                read -r -p 'Press Enter to continue...' _
                ;;
            q|Q) return 0 ;;
            *) printf 'Unknown choice.\n'; sleep 1 ;;
        esac
    done
}

main() {
    local action="" input_path="" output_path="" password="" message="" message_file=""
    action="${1:-}"
    [ "$action" = "-h" ] || [ "$action" = "--help" ] && { usage; return 0; }
    [ -n "$action" ] || { run_engine || return 1; interactive_mode; return $?; }
    shift
    while [ "$#" -gt 0 ]; do
        case "$1" in
            -i|--input) input_path="${2:-}"; shift 2 ;;
            -o|--output) output_path="${2:-}"; shift 2 ;;
            -p|--password) password="${2:-}"; shift 2 ;;
            -m|--message) message="${2:-}"; shift 2 ;;
            -f|--file) message_file="${2:-}"; shift 2 ;;
            -h|--help) usage; return 0 ;;
            *) fail "Unknown option: $1"; usage; return 2 ;;
        esac
    done
    run_engine || return 1
    case "$action" in
        encrypt|encode) encrypt_action "$input_path" "$output_path" "$password" "$message" "$message_file" ;;
        decrypt|decode) decrypt_action "$input_path" "$output_path" "$password" ;;
        *) fail "Action must be encrypt or decrypt"; usage; return 2 ;;
    esac
}

main "$@"

#!/usr/bin/env bash

set -u

# --- Color Palette ---
RESET='\033[0m'
BOLD='\033[1m'
DIM='\033[2m'

WHITE='\033[1;37m'
RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
CYAN='\033[1;36m'
MAGENTA='\033[1;35m'
GRAY='\033[0;90m'

APP_NAME="StegoVault"
APP_VERSION="0.2.0"
APP_AUTHOR="Yannick Gisubizo"
APP_WEBSITE="https://yackx.vercel.app"
APP_GITHUB="https://github.com/Yackx-tx"
APP_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_DIR="$APP_ROOT/logs"
LOG_FILE="$LOG_DIR/stegovault.log"
PYTHON_BIN="${PYTHON_BIN:-python3}"

mkdir -p "$LOG_DIR"

# Cleanup on exit
cleanup() {
    printf "${RESET}"
    tput cnorm 2>/dev/null || true
}
trap cleanup EXIT INT TERM

# UI Helpers
print_banner() {
    clear 2>/dev/null || true
    printf "${CYAN}${BOLD}"
    cat << 'EOF'
 ███████╗████████╗███████╗ ██████╗  ██████╗ ██╗   ██╗ █████╗ ██╗   ██╗██╗  ████████╗
 ██╔════╝╚══██╔══╝██╔════╝██╔════╝ ██╔═══██╗██║   ██║██╔══██╗██║   ██║██║  ╚══██╔══╝
 ███████╗   ██║   █████╗  ██║  ███╗██║   ██║██║   ██║███████║██║   ██║██║     ██║   
 ╚════██║   ██║   ██╔══╝  ██║   ██║██║   ██║╚██╗ ██╔╝██╔══██║██║   ██║██║     ██║   
 ███████║   ██║   ███████╗╚██████╔╝╚██████╔╝ ╚████╔╝ ██║  ██║╚██████╔╝███████╗██║   
 ╚══════╝   ╚═╝   ╚══════╝ ╚═════╝  ╚═════╝   ╚═══╝  ╚═╝  ╚═╝ ╚═════╝ ╚══════╝╚═╝   
EOF
    printf "${RESET}"
    
    local cols
    cols=$(tput cols 2>/dev/null || echo 80)
    # Print solid accent line matching terminal width (fallback to 80)
    printf "${MAGENTA}"
    printf '█%.0s' $(seq 1 "$cols")
    printf "${RESET}\n"
    
    printf "${YELLOW}${BOLD}%s Ver %s - by %s${RESET}\n" "$APP_NAME" "$APP_VERSION" "$APP_AUTHOR"
    # Print links with OSC 8 hyperlink sequences to make them clickable in modern terminals
    printf "${GREEN}\033]8;;%s\a%s\033]8;;\a | \033]8;;%s\a%s\033]8;;\a${RESET}\n" "$APP_WEBSITE" "$APP_WEBSITE" "$APP_GITHUB" "$APP_GITHUB"
    printf "${GRAY}Securely hide AES-GCM 256-bit encrypted payloads inside PNG image carriers.${RESET}\n\n"
}

log() {
    printf '[%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*" >> "$LOG_FILE"
}

fail() {
    printf "${RED}${BOLD}[ERROR]${RESET} ${RED}%s${RESET}\n" "$*" >&2
    log "ERROR: $*"
    return 1
}

info() {
    printf "${CYAN}${BOLD}[*]${RESET} ${CYAN}%s${RESET}\n" "$*"
}

success() {
    printf "${GREEN}${BOLD}[✓]${RESET} ${GREEN}%s${RESET}\n" "$*"
}

usage() {
    print_banner
    cat <<EOF
${YELLOW}${BOLD}Interactive mode:${RESET}
  ./stegovault.sh

${YELLOW}${BOLD}Direct mode:${RESET}
  ./stegovault.sh encrypt -i input.png -o encrypted.png -m "private message"
  ./stegovault.sh decrypt -i encrypted.png -o message.txt

${YELLOW}${BOLD}Options:${RESET}
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

ask_input() {
    local prompt_msg="$1"
    local default_val="$2"
    local var_name="$3"
    
    if [ -n "$default_val" ]; then
        printf "${YELLOW}%s ${GRAY}[Default: %s]${RESET}\n${GREEN}> ${RESET}" "$prompt_msg" "$default_val"
    else
        printf "${YELLOW}%s${RESET}\n${GREEN}> ${RESET}" "$prompt_msg"
    fi
    
    local val
    read -r val
    val="${val:-$default_val}"
    
    eval "$var_name=\"\$val\""
}

ask_password() {
    local prompt_msg="$1"
    local var_name="$2"
    
    printf "${YELLOW}%s${RESET}\n${GREEN}> ${RESET}" "$prompt_msg"
    
    local val
    read -r -s val
    printf "\n"
    
    eval "$var_name=\"\$val\""
}

encrypt_action() {
    local input_path="${1:-}" output_path="${2:-}" password="${3:-}" message="${4:-}" message_file="${5:-}"
    local -a engine_args
    
    printf "\n${CYAN}${BOLD}--- ENCRYPTION & EMBEDDING ---${RESET}\n\n"
    
    [ -n "$input_path" ] || ask_input "Target PNG image carrier (include .png extension, use full path if outside current directory):" "" input_path
    
    if [ -z "$message_file" ] && [ -z "$message" ]; then
        ask_input "Secret message to embed (or leave blank to use a file later):" "" message
    fi
    
    [ -n "$password" ] || ask_password "Encryption password (input is hidden):" password
    
    [ -n "$output_path" ] || ask_input "Output PNG file destination (include .png extension):" "encrypted/result.png" output_path

    info "Starting cryptographic engine..."
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
        success "Encrypted image securely generated: $output_path"
        log "Encrypted $input_path to $output_path"
    else
        fail "Encryption failed. See $LOG_FILE"
    fi
    return "$status"
}

decrypt_action() {
    local input_path="${1:-}" output_path="${2:-}" password="${3:-}"
    
    printf "\n${CYAN}${BOLD}--- DECRYPTION & EXTRACTION ---${RESET}\n\n"
    
    [ -n "$input_path" ] || ask_input "Encrypted PNG image path (include .png extension, use full path if outside current directory):" "" input_path
    [ -n "$password" ] || ask_password "Decryption password:" password
    [ -n "$output_path" ] || ask_input "Save extracted payload to:" "decrypted/message.txt" output_path

    info "Analyzing carrier LSB matrix & decrypting..."
    "$PYTHON_BIN" -m stegocrypt decode -i "$input_path" -o "$output_path" -p "$password" 2>>"$LOG_FILE"
    local status=$?
    if [ "$status" -eq 0 ]; then
        success "Payload successfully extracted to: $output_path"
        log "Decrypted $input_path to $output_path"
    else
        fail "Decryption failed. See $LOG_FILE"
    fi
    return "$status"
}

interactive_mode() {
    local encrypt_enabled=0 decrypt_enabled=0 choice
    while true; do
        print_banner
        
        # Display toggle states as a nice UI widget
        printf "${CYAN}╔═════════════ Vault Operations ══════════════╗${RESET}\n"
        
        if [ "$encrypt_enabled" -eq 1 ]; then
            printf "${CYAN}║${RESET}  ${GREEN}${BOLD}[✓] Encrypt & Hide Payload${RESET}                 ${CYAN}║${RESET}\n"
        else
            printf "${CYAN}║${RESET}  ${GRAY}[ ] Encrypt & Hide Payload${RESET}                 ${CYAN}║${RESET}\n"
        fi
        
        if [ "$decrypt_enabled" -eq 1 ]; then
            printf "${CYAN}║${RESET}  ${GREEN}${BOLD}[✓] Decrypt & Extract Payload${RESET}              ${CYAN}║${RESET}\n"
        else
            printf "${CYAN}║${RESET}  ${GRAY}[ ] Decrypt & Extract Payload${RESET}              ${CYAN}║${RESET}\n"
        fi
        
        printf "${CYAN}╚═════════════════════════════════════════════╝${RESET}\n\n"
        
        printf "${YELLOW}Commands:${RESET}\n"
        printf "  ${BOLD}E${RESET} : Toggle Encryption Mode\n"
        printf "  ${BOLD}D${RESET} : Toggle Decryption Mode\n"
        printf "  ${BOLD}R${RESET} : Run Selected Operations\n"
        printf "  ${BOLD}Q${RESET} : Quit\n\n"
        
        printf "${GREEN}Select Command [E/D/R/Q]: ${RESET}"
        read -r choice
        case "$choice" in
            e|E) encrypt_enabled=$((1 - encrypt_enabled)) ;;
            d|D) decrypt_enabled=$((1 - decrypt_enabled)) ;;
            r|R)
                if [ "$encrypt_enabled" -eq 0 ] && [ "$decrypt_enabled" -eq 0 ]; then
                    printf "\n${RED}Warning: Select at least one operation before running.${RESET}\n"
                else
                    [ "$encrypt_enabled" -eq 1 ] && encrypt_action || true
                    [ "$decrypt_enabled" -eq 1 ] && decrypt_action || true
                fi
                printf "\n${GRAY}Press Enter to return to dashboard...${RESET}"
                read -r _
                ;;
            q|Q) 
                printf "\n${GRAY}Exiting StegoVault. Securing terminal...${RESET}\n"
                return 0 
                ;;
            *) 
                printf "\n${RED}Unknown command.${RESET}\n"
                sleep 1 
                ;;
        esac
    done
}

main() {
    local action="" input_path="" output_path="" password="" message="" message_file=""
    action="${1:-}"
    [ "$action" = "-h" ] || [ "$action" = "--help" ] && { usage; return 0; }
    
    if [ -z "$action" ]; then
        run_engine || return 1
        interactive_mode
        return $?
    fi
    
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

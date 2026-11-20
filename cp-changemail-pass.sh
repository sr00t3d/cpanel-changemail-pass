#!/usr/bin/env bash
# ╔═══════════════════════════════════════════════════════════════════════════╗
# ║                                                                           ║
# ║   cPanel Email Password Changer (cp-changemail-pass.sh) v2.0.0            ║
# ║                                                                           ║
# ╠═══════════════════════════════════════════════════════════════════════════╣
# ║   Autor:   Percio Castelo                                                 ║
# ║   Contato: percio@evolya.com.br | contato@perciocastelo.com.br            ║
# ║   Web:     https://perciocastelo.com.br                                   ║
# ║                                                                           ║
# ║   Função:  Automates single or bulk email password rotations on           ║
# ║            cPanel/WHM servers via UAPI Email passwd_pop with CSPRNG       ║
# ║            password generation, dry-run simulation, and table/json/csv.    ║
# ╚═══════════════════════════════════════════════════════════════════════════╝

set -uo pipefail
export LC_ALL=C

readonly VERSION="2.0.0"
readonly SCRIPT_NAME="$(basename "$0")"

# =============================================================================
# Defaults
# =============================================================================
EMAIL_INPUT=""
FILE_INPUT=""
DOMAIN_INPUT=""
USER_OVERRIDE=""
CUSTOM_PASS=""
PASS_LENGTH=16
DRY_RUN=false
MASK_PASS=false
SAVE_CSV=""
OUTPUT_FORMAT="table"    # table | json | csv
NO_COLOR=false
QUIET=false

# =============================================================================
# Colors
# =============================================================================
C_RESET=""
C_RED=""
C_GREEN=""
C_YELLOW=""
C_CYAN=""
C_DIM=""

init_colors() {
    if [[ "$NO_COLOR" == false && "$OUTPUT_FORMAT" == "table" && -t 1 ]]; then
        C_RESET=$'\033[0m'
        C_DIM=$'\033[2m'
        C_RED=$'\033[0;31m'
        C_GREEN=$'\033[0;32m'
        C_YELLOW=$'\033[0;33m'
        C_CYAN=$'\033[0;36m'
    fi
}

log_info() { [[ "$QUIET" == false && "$OUTPUT_FORMAT" == "table" ]] && echo -e "${C_CYAN}[→]${C_RESET} $*" >&2; }
log_ok()   { [[ "$QUIET" == false && "$OUTPUT_FORMAT" == "table" ]] && echo -e "${C_GREEN}[+]${C_RESET} $*" >&2; }
log_warn() { [[ "$QUIET" == false ]] && echo -e "${C_YELLOW}[!]${C_RESET} $*" >&2; }
log_err()  { echo -e "${C_RED}[x] Error:${C_RESET} $*" >&2; }

# =============================================================================
# Help
# =============================================================================
show_help() {
    cat <<EOF
cPanel Email Password Changer (cp-changemail-pass.sh) v${VERSION}
Automates email password changes on cPanel/WHM servers via UAPI (single or bulk).

Usage:
  ${SCRIPT_NAME} [OPTIONS] [email@domain.com]

Target Options:
  -e, --email <address>    Target single email address
  -f, --file <path>        File containing list of email addresses (one per line)
  -d, --domain <domain>    Rotate all email accounts under a specific domain
  -u, --user <username>    Explicit cPanel username (skips auto whoowns detection)

Password & Safety Options:
  -p, --password <string>  Use fixed password instead of auto-generating
  -l, --length <int>       Generated password length (default: 16, min: 12, max: 64)
  -n, --dry-run            Simulate operations without making changes
      --mask-passwords     Mask passwords in output (e.g. ********)
  -s, --save-csv <path>    Save email:password mapping to a secure file (chmod 600)

Output Options:
  -o, --output <fmt>       Output format: table (default), json, csv
  -q, --quiet              Suppress progress messages
      --no-color           Disable ANSI colors
  -V, --version            Show version and exit
  -h, --help               Show this help message and exit

Exit Codes:
  0  All requested password changes succeeded (or dry-run passed)
  1  Usage error or fatal prerequisite failure
  2  One or more email password updates failed

Examples:
  # Rotate a single email with auto-generated secure password:
  sudo ${SCRIPT_NAME} -e admin@example.com

  # Dry-run simulate a batch rotation from a file:
  sudo ${SCRIPT_NAME} -f emails.txt --dry-run

  # Rotate all emails in a domain and save credentials to secure CSV:
  sudo ${SCRIPT_NAME} -d example.com -s /root/passwords.csv

  # Export JSON output for automation:
  sudo ${SCRIPT_NAME} -f emails.txt -o json
EOF
}

# =============================================================================
# Argument Parser
# =============================================================================
parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -e|--email)
                [[ $# -lt 2 ]] && { log_err "$1 requires an email address"; exit 1; }
                EMAIL_INPUT="$2"; shift 2 ;;
            -f|--file)
                [[ $# -lt 2 ]] && { log_err "$1 requires a file path"; exit 1; }
                FILE_INPUT="$2"; shift 2 ;;
            -d|--domain)
                [[ $# -lt 2 ]] && { log_err "$1 requires a domain"; exit 1; }
                DOMAIN_INPUT="$2"; shift 2 ;;
            -u|--user)
                [[ $# -lt 2 ]] && { log_err "$1 requires a username"; exit 1; }
                USER_OVERRIDE="$2"; shift 2 ;;
            -p|--password)
                [[ $# -lt 2 ]] && { log_err "$1 requires a password string"; exit 1; }
                CUSTOM_PASS="$2"; shift 2 ;;
            -l|--length)
                [[ $# -lt 2 || ! "$2" =~ ^[0-9]+$ || "$2" -lt 12 || "$2" -gt 64 ]] && {
                    log_err "$1 requires an integer between 12 and 64"; exit 1;
                }
                PASS_LENGTH="$2"; shift 2 ;;
            -n|--dry-run)
                DRY_RUN=true; shift ;;
            --mask-passwords)
                MASK_PASS=true; shift ;;
            -s|--save-csv)
                [[ $# -lt 2 ]] && { log_err "$1 requires a file path"; exit 1; }
                SAVE_CSV="$2"; shift 2 ;;
            -o|--output)
                [[ $# -lt 2 ]] && { log_err "$1 requires a format (table|json|csv)"; exit 1; }
                OUTPUT_FORMAT="$2"; shift 2 ;;
            -q|--quiet)
                QUIET=true; shift ;;
            --no-color)
                NO_COLOR=true; shift ;;
            -V|--version)
                echo "cPanel Email Password Changer v${VERSION}"; exit 0 ;;
            -h|--help)
                show_help; exit 0 ;;
            -*)
                log_err "Unknown option: $1 (use --help)"; exit 1 ;;
            *)
                if [[ -z "$EMAIL_INPUT" && "$1" =~ @ ]]; then
                    EMAIL_INPUT="$1"
                else
                    log_err "Unexpected argument: $1"; exit 1
                fi
                shift ;;
        esac
    done

    case "$OUTPUT_FORMAT" in
        table|json|csv) ;;
        *) log_err "--output must be table, json, or csv"; exit 1 ;;
    esac

    if [[ -z "$EMAIL_INPUT" && -z "$FILE_INPUT" && -z "$DOMAIN_INPUT" ]]; then
        log_err "Target email, file, or domain is required. Use --help for usage."
        exit 1
    fi

    if [[ -n "$FILE_INPUT" && ! -f "$FILE_INPUT" ]]; then
        log_err "File not found: ${FILE_INPUT}"
        exit 1
    fi
}

# =============================================================================
# Helper Functions
# =============================================================================
generate_password() {
    local len="$1"
    if command -v openssl >/dev/null 2>&1; then
        openssl rand -base64 "$((len * 2))" | tr -dc 'a-zA-Z0-9#$!%&' | head -c "$len"
    else
        tr -dc 'a-zA-Z0-9#$!%&' < /dev/urandom 2>/dev/null | head -c "$len"
    fi
}

get_domain_owner() {
    local dom="$1"
    local owner=""

    if [[ -n "$USER_OVERRIDE" ]]; then
        echo "$USER_OVERRIDE"
        return 0
    fi

    if [[ -x /scripts/whoowns ]]; then
        owner=$(/scripts/whoowns "$dom" 2>/dev/null | tr -d '[:space:]')
    fi

    if [[ -z "$owner" && -f /etc/trueuserdomains ]]; then
        owner=$(awk -F': ' -v d="$dom" 'tolower($1) == tolower(d) {print $2}' /etc/trueuserdomains | tr -d '[:space:]')
    fi

    if [[ -z "$owner" && -f /etc/userdomains ]]; then
        owner=$(awk -F': ' -v d="$dom" 'tolower($1) == tolower(d) {print $2}' /etc/userdomains | tr -d '[:space:]')
    fi

    echo "$owner"
}

is_valid_email() {
    local email="$1"
    [[ "$email" =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]
}

# =============================================================================
# Main Processing Engine
# =============================================================================
process_emails() {
    local targets=()

    if [[ -n "$EMAIL_INPUT" ]]; then
        targets+=("$EMAIL_INPUT")
    fi

    if [[ -n "$FILE_INPUT" ]]; then
        while IFS= read -r line || [[ -n "$line" ]]; do
            line=$(echo "$line" | sed 's/#.*//; s/^[[:space:]]*//; s/[[:space:]]*$//')
            [[ -n "$line" ]] && targets+=("$line")
        done < "$FILE_INPUT"
    fi

    if [[ -n "$DOMAIN_INPUT" ]]; then
        local dom_user
        dom_user=$(get_domain_owner "$DOMAIN_INPUT")
        if [[ -z "$dom_user" ]]; then
            log_err "Could not resolve cPanel owner for domain: ${DOMAIN_INPUT}"
            exit 1
        fi
        if command -v uapi >/dev/null 2>&1; then
            local pop_list
            pop_list=$(uapi --user="$dom_user" Email list_pops domain="$DOMAIN_INPUT" --output=json 2>/dev/null || true)
            while read -r pop; do
                [[ -n "$pop" ]] && targets+=("${pop}@${DOMAIN_INPUT}")
            done < <(echo "$pop_list" | grep -oP '"user":\s*"\K[^"]+' || true)
        fi
        if [[ ${#targets[@]} -eq 0 ]]; then
            log_err "No email accounts found under domain: ${DOMAIN_INPUT}"
            exit 1
        fi
    fi

    # Deduplicate targets while preserving order
    local unique_targets=()
    declare -A seen_emails=()
    for t in "${targets[@]}"; do
        local tl="${t,,}"
        if [[ -z "${seen_emails[$tl]:-}" ]]; then
            seen_emails[$tl]=1
            unique_targets+=("$t")
        fi
    done

    local count=${#unique_targets[@]}
    log_info "Processing ${count} email address(es)..."

    local results_json="[]"
    local has_failure=false
    local success_cnt=0
    local fail_cnt=0

    # Temporary CSV collector if --save-csv is active
    local csv_buffer=""
    if [[ -n "$SAVE_CSV" ]]; then
        csv_buffer="email,password,cpanel_user,status,note\n"
    fi

    # JSON accumulator
    local json_items=()

    for em in "${unique_targets[@]}"; do
        local em_domain="${em#*@}"
        local em_prefix="${em%@*}"
        local pwd="${CUSTOM_PASS}"
        if [[ -z "$pwd" ]]; then
            pwd=$(generate_password "$PASS_LENGTH")
        fi

        local user
        user=$(get_domain_owner "$em_domain")
        local status="OK"
        local note=""

        if ! is_valid_email "$em"; then
            status="FAILED"
            note="Invalid email format"
        elif [[ -z "$user" ]]; then
            status="FAILED"
            note="Domain not registered on server"
        elif [[ "$DRY_RUN" == true ]]; then
            status="SIMULATED"
            note="Dry-run (no changes made)"
            ((success_cnt++))
        else
            if ! command -v uapi >/dev/null 2>&1; then
                status="FAILED"
                note="uapi binary not found"
            else
                local resp
                resp=$(uapi --user="$user" Email passwd_pop email="$em_prefix" domain="$em_domain" password="$pwd" --output=json 2>&1 || true)
                local api_status
                api_status=$(echo "$resp" | grep -oP '"status":\s*\K\d+' | head -n 1)
                if [[ "$api_status" == "1" ]]; then
                    status="OK"
                    note="Password updated"
                    ((success_cnt++))
                else
                    status="FAILED"
                    local err_msg
                    err_msg=$(echo "$resp" | grep -oP '"errors":\s*\[\s*"\K[^"]+' | head -n 1)
                    note="${err_msg:-uapi update failed}"
                    ((fail_cnt++))
                    has_failure=true
                fi
            fi
        fi

        if [[ "$status" == "FAILED" ]]; then
            ((fail_cnt++))
            has_failure=true
        fi

        local disp_pwd="$pwd"
        if [[ "$MASK_PASS" == true ]]; then
            disp_pwd="****************"
        fi

        json_items+=("{\"email\":\"$em\",\"user\":\"${user:-none}\",\"domain\":\"$em_domain\",\"password\":\"$disp_pwd\",\"status\":\"$status\",\"note\":\"$note\"}")

        if [[ -n "$SAVE_CSV" ]]; then
            csv_buffer+="${em},\"${pwd}\",\"${user:-none}\",\"${status}\",\"${note}\"\n"
        fi
    done

    # Output generation
    if [[ "$OUTPUT_FORMAT" == "json" ]]; then
        local joined
        joined=$(IFS=,; echo "${json_items[*]}")
        cat <<EOF
{
  "version": "${VERSION}",
  "dry_run": ${DRY_RUN},
  "total": ${count},
  "success": ${success_cnt},
  "failed": ${fail_cnt},
  "results": [${joined}]
}
EOF
    elif [[ "$OUTPUT_FORMAT" == "csv" ]]; then
        echo "email,user,domain,password,status,note"
        for item in "${json_items[@]}"; do
            python3 -c "import sys,json; d=json.loads(sys.argv[1]); print(f\"{d['email']},{d['user']},{d['domain']},{d['password']},{d['status']},{d['note']}\")" "$item"
        done
    else
        # Table format
        local bar="================================================================================================================"
        local sep="----------------------------------------------------------------------------------------------------------------"
        echo "$bar"
        echo " CPANEL EMAIL PASSWORD CHANGER v${VERSION} | Mode: $([[ "$DRY_RUN" == true ]] && echo "DRY-RUN" || echo "LIVE") | Targets: ${count}"
        echo "$bar"
        printf "%-32s | %-12s | %-24s | %-10s | %s\n" "EMAIL" "USER" "PASSWORD" "STATUS" "NOTE"
        echo "$sep"
        for item in "${json_items[@]}"; do
            python3 - "$C_RESET" "$C_GREEN" "$C_YELLOW" "$C_RED" "$item" <<'PYEOF'
import sys, json
rst, grn, yel, red, raw = sys.argv[1:6]
d = json.loads(raw)
st = d["status"]
col = grn if st == "OK" else (yel if st == "SIMULATED" else red)
print(f"{d['email'][:32]:<32} | {d['user'][:12]:<12} | {d['password'][:24]:<24} | {col}{st:<10}{rst} | {d['note']}")
PYEOF
        done
        echo "$bar"
        echo " Summary: ${count} processed | Success/Simulated: ${success_cnt} | Failed: ${fail_cnt}"
        echo "$bar"
    fi

    # Save CSV file if requested
    if [[ -n "$SAVE_CSV" ]]; then
        mkdir -p "$(dirname "$SAVE_CSV")"
        echo -e "$csv_buffer" > "$SAVE_CSV"
        chmod 600 "$SAVE_CSV" 2>/dev/null || true
        log_ok "Credentials saved securely (chmod 600) to: ${SAVE_CSV}"
    fi

    if [[ "$has_failure" == true ]]; then
        return 2
    fi
    return 0
}

# =============================================================================
# Main
# =============================================================================
main() {
    parse_args "$@"
    init_colors
    process_emails
}

main "$@"

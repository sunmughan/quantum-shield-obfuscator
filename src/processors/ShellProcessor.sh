#!/bin/bash
# Shell Script Obfuscator
# Supports Bash, Zsh, Fish, and other POSIX-compatible shells

# Check if required tools are available
command -v openssl >/dev/null 2>&1 || { echo "openssl is required but not installed. Aborting." >&2; exit 1; }
command -v base64 >/dev/null 2>&1 || { echo "base64 is required but not installed. Aborting." >&2; exit 1; }

# Default encryption key
DEFAULT_KEY="default_encryption_key_32_chars_"

# Arrays to store mappings
declare -A identifier_map
declare -A string_map
declare -a encrypted_strings

# Reserved shell keywords and built-ins
reserved_keywords=(
    "if" "then" "else" "elif" "fi" "case" "esac" "for" "select" "while" "until"
    "do" "done" "function" "time" "coproc" "in" "break" "continue" "return"
    "exit" "export" "readonly" "local" "declare" "typeset" "unset" "shift"
    "set" "unset" "alias" "unalias" "history" "fc" "jobs" "bg" "fg" "disown"
    "suspend" "kill" "wait" "trap" "source" "." "eval" "exec" "builtin"
    "command" "type" "which" "whereis" "whatis" "apropos" "man" "info"
    "help" "cd" "pwd" "dirs" "pushd" "popd" "mkdir" "rmdir" "rm" "cp"
    "mv" "ln" "chmod" "chown" "chgrp" "touch" "stat" "file" "find" "locate"
    "grep" "egrep" "fgrep" "sed" "awk" "cut" "sort" "uniq" "wc" "head"
    "tail" "more" "less" "cat" "tac" "rev" "tr" "od" "hexdump" "strings"
    "diff" "cmp" "comm" "join" "paste" "split" "csplit" "expand" "unexpand"
    "fold" "fmt" "pr" "nl" "tee" "xargs" "parallel" "seq" "yes" "true" "false"
    "test" "[" "[[" "expr" "bc" "dc" "factor" "date" "cal" "uptime"
    "who" "w" "id" "groups" "finger" "last" "lastb" "users" "logname"
    "whoami" "su" "sudo" "passwd" "chsh" "chfn" "newgrp" "sg" "gpasswd"
    "ps" "pstree" "top" "htop" "iotop" "vmstat" "iostat" "sar" "free"
    "df" "du" "mount" "umount" "fdisk" "parted" "lsblk" "blkid" "lsof"
    "netstat" "ss" "lsof" "fuser" "pidof" "pgrep" "pkill" "killall"
    "nohup" "screen" "tmux" "at" "batch" "crontab" "sleep" "usleep"
    "timeout" "watch" "strace" "ltrace" "gdb" "objdump" "nm" "readelf"
    "ldd" "ldconfig" "ar" "ranlib" "strip" "size" "file" "strings"
    "tar" "gzip" "gunzip" "zcat" "bzip2" "bunzip2" "bzcat" "xz" "unxz"
    "xzcat" "zip" "unzip" "rar" "unrar" "7z" "compress" "uncompress"
    "pack" "unpack" "cpio" "rsync" "scp" "sftp" "ftp" "wget" "curl"
    "ssh" "sshd" "ssh-keygen" "ssh-add" "ssh-agent" "scp" "sftp" "telnet"
    "nc" "netcat" "socat" "nmap" "ping" "ping6" "traceroute" "tracepath"
    "mtr" "dig" "nslookup" "host" "whois" "arp" "route" "ip" "ifconfig"
    "iwconfig" "iwlist" "iwscan" "dhclient" "dhcpcd" "systemctl" "service"
    "chkconfig" "update-rc.d" "systemd" "init" "telinit" "runlevel"
    "dmesg" "journalctl" "logger" "syslog" "rsyslog" "logrotate"
    "cron" "anacron" "systemd-timer" "udev" "udevadm" "lsmod" "modprobe"
    "insmod" "rmmod" "depmod" "modinfo" "lspci" "lsusb" "lscpu" "lshw"
    "dmidecode" "hdparm" "smartctl" "fsck" "e2fsck" "xfs_repair"
    "mkfs" "mke2fs" "mkfs.xfs" "mkswap" "swapon" "swapoff" "sync"
    "echo" "printf" "read" "mapfile" "readarray" "getopts" "getopt"
    "basename" "dirname" "realpath" "readlink" "pathchk" "mktemp"
    "tempfile" "shred" "wipe" "srm" "dd" "conv" "bs" "count" "if" "of"
    "BASH" "SHELL" "PATH" "HOME" "USER" "LOGNAME" "PWD" "OLDPWD"
    "IFS" "PS1" "PS2" "PS3" "PS4" "PROMPT_COMMAND" "HISTFILE" "HISTSIZE"
    "HISTCONTROL" "HISTIGNORE" "HISTTIMEFORMAT" "TERM" "DISPLAY"
    "LANG" "LC_ALL" "LC_CTYPE" "LC_NUMERIC" "LC_TIME" "LC_COLLATE"
    "LC_MONETARY" "LC_MESSAGES" "LC_PAPER" "LC_NAME" "LC_ADDRESS"
    "LC_TELEPHONE" "LC_MEASUREMENT" "LC_IDENTIFICATION" "TZ" "TMPDIR"
    "EDITOR" "VISUAL" "PAGER" "BROWSER" "MAIL" "MAILPATH" "MAILCHECK"
)

# Function to encrypt string using OpenSSL
encrypt_string() {
    local plaintext="$1"
    local key="$2"
    
    if [[ -z "$plaintext" || -z "$key" ]]; then
        echo ""
        return 1
    fi
    
    # Use OpenSSL for AES-256-CBC encryption
    local encrypted
    encrypted=$(echo -n "$plaintext" | openssl enc -aes-256-cbc -a -salt -k "$key" 2>/dev/null)
    
    if [[ $? -eq 0 && -n "$encrypted" ]]; then
        echo "$encrypted"
    else
        echo ""
        return 1
    fi
}

# Function to generate obfuscated name
generate_obfuscated_name() {
    local charset="abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
    local length=$((8 + RANDOM % 8))  # 8-15 characters
    local result=""
    
    # First character must be a letter
    local first_char_index=$((RANDOM % ${#charset}))
    result="${charset:$first_char_index:1}"
    
    # Remaining characters can be letters or numbers
    local full_charset="${charset}0123456789"
    for ((i=1; i<length; i++)); do
        local char_index=$((RANDOM % ${#full_charset}))
        result="${result}${full_charset:$char_index:1}"
    done
    
    echo "$result"
}

# Function to check if identifier is reserved
is_reserved_identifier() {
    local identifier="$1"
    
    for keyword in "${reserved_keywords[@]}"; do
        if [[ "$identifier" == "$keyword" ]]; then
            return 0  # true
        fi
    done
    
    return 1  # false
}

# Function to encrypt strings in code
encrypt_strings() {
    local code="$1"
    local key="$2"
    local result=""
    
    # Add decryption utility
    local decrypt_utility='# String decryption utility
decrypt_string() {
    local encrypted="$1"
    local key="$2"
    
    if [[ -z "$encrypted" || -z "$key" ]]; then
        echo ""
        return 1
    fi
    
    local decrypted
    decrypted=$(echo "$encrypted" | openssl enc -aes-256-cbc -d -a -k "$key" 2>/dev/null)
    
    if [[ $? -eq 0 ]]; then
        echo "$decrypted"
    else
        echo ""
        return 1
    fi
}

'
    
    result="$decrypt_utility"
    
    # Process string literals (both single and double quotes)
    local string_index=0
    local temp_code="$code"
    
    # Handle double-quoted strings
    while [[ "$temp_code" =~ \"([^\"\\]*(\\.[^\"\\]*)*)\" ]]; do
        local match="${BASH_REMATCH[0]}"
        local content="${BASH_REMATCH[1]}"
        
        local encrypted
        encrypted=$(encrypt_string "$content" "$key")
        
        if [[ -n "$encrypted" ]]; then
            local var_name="_str_${string_index}"
            encrypted_strings+=("$var_name=\$(decrypt_string \"$encrypted\" \"$key\")")
            temp_code="${temp_code/"$match"/"\$$var_name"}"
            ((string_index++))
        fi
    done
    
    # Handle single-quoted strings
    while [[ "$temp_code" =~ \'([^\']*)\'  ]]; do
        local match="${BASH_REMATCH[0]}"
        local content="${BASH_REMATCH[1]}"
        
        local encrypted
        encrypted=$(encrypt_string "$content" "$key")
        
        if [[ -n "$encrypted" ]]; then
            local var_name="_str_${string_index}"
            encrypted_strings+=("$var_name=\$(decrypt_string \"$encrypted\" \"$key\")")
            temp_code="${temp_code/"$match"/"\$$var_name"}"
            ((string_index++))
        fi
    done
    
    # Add string declarations
    for str_decl in "${encrypted_strings[@]}"; do
        result="${result}${str_decl}\n"
    done
    
    result="${result}${temp_code}"
    echo "$result"
}

# Function to obfuscate identifiers
obfuscate_identifiers() {
    local code="$1"
    local result="$code"
    
    # Find all identifiers (variables and function names)
    local identifiers
    identifiers=$(echo "$code" | grep -oE '\b[a-zA-Z_][a-zA-Z0-9_]*\b' | sort -u)
    
    while IFS= read -r identifier; do
        if [[ -n "$identifier" && ${#identifier} -gt 1 ]]; then
            if ! is_reserved_identifier "$identifier"; then
                if [[ -z "${identifier_map[$identifier]}" ]]; then
                    identifier_map["$identifier"]=$(generate_obfuscated_name)
                fi
                
                # Replace identifier with obfuscated name
                local obfuscated="${identifier_map[$identifier]}"
                result=$(echo "$result" | sed "s/\\b$identifier\\b/$obfuscated/g")
            fi
        fi
    done <<< "$identifiers"
    
    echo "$result"
}

# Function to add control flow obfuscation
add_control_flow_obfuscation() {
    local code="$1"
    local result="$code"
    
    # Convert simple if statements to case statements
    result=$(echo "$result" | sed -E 's/if \[ (.+) \]; then/sw_var=$((\1 ? 1 : 0)); case $sw_var in 1)/g')
    result=$(echo "$result" | sed -E 's/else/;; 0)/g')
    result=$(echo "$result" | sed -E 's/fi/;; esac/g')
    
    echo "$result"
}

# Function to add dead code
add_dead_code() {
    local code="$1"
    local result=""
    
    local dead_code_snippets=(
        "_dummy1=\$((RANDOM % 100))"
        "_dummy2=\$(date +%s)"
        "if [[ \$_dummy1 -gt 200 ]]; then echo \"Never executed\" >/dev/null; fi"
        "for _i in {1..0}; do _dummy2=\$((_dummy2 + 1)); done"
        "_dummy_array=()"
        "_dummy_func() { return \$((RANDOM % 2)); }"
    )
    
    # Split code into lines and insert dead code
    local line_count=0
    local insertions=0
    
    while IFS= read -r line; do
        result="${result}${line}\n"
        
        # Insert dead code after function definitions or control structures
        if [[ "$line" =~ ^[[:space:]]*(function|if|for|while|case) ]] && [[ $insertions -lt 3 ]]; then
            local dead_code_index=$((RANDOM % ${#dead_code_snippets[@]}))
            result="${result}${dead_code_snippets[$dead_code_index]}\n"
            ((insertions++))
        fi
        
        ((line_count++))
    done <<< "$code"
    
    echo -e "$result"
}

# Function to add anti-debugging measures
add_anti_debugging() {
    local code="$1"
    
    local anti_debug_code='# Anti-debugging measures for shell scripts
anti_debug_check() {
    # Check for common debugging variables
    if [[ -n "$BASH_XTRACEFD" || -n "$PS4" || "$-" == *x* ]]; then
        echo "Debug mode detected" >&2
        exit 1
    fi
    
    # Check for strace/ltrace
    if pgrep -f "strace.*$(basename "$0")" >/dev/null 2>&1; then
        exit 1
    fi
    
    if pgrep -f "ltrace.*$(basename "$0")" >/dev/null 2>&1; then
        exit 1
    fi
    
    # Check for gdb
    if pgrep -f "gdb.*$(basename "$0")" >/dev/null 2>&1; then
        exit 1
    fi
    
    # Check for common reverse engineering tools
    local suspicious_processes=("radare2" "r2" "objdump" "hexdump" "xxd" "strings")
    for proc in "${suspicious_processes[@]}"; do
        if pgrep "$proc" >/dev/null 2>&1; then
            exit 1
        fi
    done
    
    # Timing check
    local start_time=$(date +%s%N)
    local dummy=0
    for i in {1..1000}; do
        dummy=$((dummy + i))
    done
    local end_time=$(date +%s%N)
    local elapsed=$(((end_time - start_time) / 1000000))  # Convert to milliseconds
    
    if [[ $elapsed -gt 10 ]]; then  # 10ms
        exit 1
    fi
    
    # Check for environment manipulation
    if [[ -n "$DEBUG" || -n "$TRACE" || -n "$VERBOSE" ]]; then
        exit 1
    fi
    
    # Check for script modification
    local script_path="$(readlink -f "$0")"
    if [[ -f "$script_path" ]]; then
        local current_hash
        current_hash=$(sha256sum "$script_path" 2>/dev/null | cut -d" " -f1)
        local expected_hash="SCRIPT_HASH_PLACEHOLDER"
        
        if [[ -n "$current_hash" && -n "$expected_hash" && "$current_hash" != "$expected_hash" ]]; then
            # Script has been modified
            exit 1
        fi
    fi
    
    # Check for common analysis tools in PATH
    local analysis_tools=("strace" "ltrace" "gdb" "valgrind" "perf" "objdump" "readelf")
    for tool in "${analysis_tools[@]}"; do
        if command -v "$tool" >/dev/null 2>&1; then
            # Tool is available, might be suspicious
            # Uncomment if needed: exit 1
            :
        fi
    done
    
    # Check for virtualization/sandboxing
    if [[ -f "/proc/cpuinfo" ]]; then
        if grep -qi "hypervisor\|vmware\|virtualbox\|qemu\|xen" /proc/cpuinfo 2>/dev/null; then
            # Running in VM, might be analysis environment
            # Uncomment if needed: exit 1
            :
        fi
    fi
    
    # Check for container environment
    if [[ -f "/.dockerenv" ]] || [[ -n "$container" ]] || [[ -f "/proc/1/cgroup" ]] && grep -q docker /proc/1/cgroup 2>/dev/null; then
        # Running in container, might be analysis environment
        # Uncomment if needed: exit 1
        :
    fi
}

'
    
    local result="$anti_debug_code$code"
    
    # Insert anti-debug calls at the beginning of functions
    result=$(echo "$result" | sed '/^[[:space:]]*function[[:space:]]\+[a-zA-Z_][a-zA-Z0-9_]*[[:space:]]*()[[:space:]]*{/a\
    anti_debug_check')
    result=$(echo "$result" | sed '/^[[:space:]]*[a-zA-Z_][a-zA-Z0-9_]*[[:space:]]*()[[:space:]]*{/a\
    anti_debug_check')
    
    # Insert at the beginning of main script
    result="anti_debug_check\n$result"
    
    echo -e "$result"
}

# Function to add function obfuscation
add_function_obfuscation() {
    local code="$1"
    local result="$code"
    
    # Find function definitions and obfuscate names
    while [[ "$result" =~ (function[[:space:]]+)([a-zA-Z_][a-zA-Z0-9_]*)([[:space:]]*\(\)[[:space:]]*\{) ]]; do
        local full_match="${BASH_REMATCH[0]}"
        local prefix="${BASH_REMATCH[1]}"
        local func_name="${BASH_REMATCH[2]}"
        local suffix="${BASH_REMATCH[3]}"
        
        if ! is_reserved_identifier "$func_name"; then
            if [[ -z "${identifier_map[$func_name]}" ]]; then
                identifier_map["$func_name"]="_F$(generate_obfuscated_name | cut -c1-8)"
            fi
            
            local obfuscated="${identifier_map[$func_name]}"
            result="${result/$full_match/$prefix$obfuscated$suffix}"
        fi
    done
    
    # Handle function definitions without 'function' keyword
    while [[ "$result" =~ ([a-zA-Z_][a-zA-Z0-9_]*)([[:space:]]*\(\)[[:space:]]*\{) ]]; do
        local full_match="${BASH_REMATCH[0]}"
        local func_name="${BASH_REMATCH[1]}"
        local suffix="${BASH_REMATCH[2]}"
        
        if ! is_reserved_identifier "$func_name"; then
            if [[ -z "${identifier_map[$func_name]}" ]]; then
                identifier_map["$func_name"]="_F$(generate_obfuscated_name | cut -c1-8)"
            fi
            
            local obfuscated="${identifier_map[$func_name]}"
            result="${result/$full_match/$obfuscated$suffix}"
        fi
    done
    
    echo "$result"
}

# Main processing function
process_shell_script() {
    local code="$1"
    local key="${2:-$DEFAULT_KEY}"
    
    local result="$code"
    
    # Apply shell-specific obfuscations
    result=$(encrypt_strings "$result" "$key")
    result=$(add_function_obfuscation "$result")
    result=$(obfuscate_identifiers "$result")
    result=$(add_control_flow_obfuscation "$result")
    result=$(add_dead_code "$result")
    result=$(add_anti_debugging "$result")
    
    echo "$result"
}

# Main function for command-line usage
main() {
    if [[ $# -lt 1 ]]; then
        echo "Usage: $0 <input_file> [encryption_key]" >&2
        echo "       cat <input_file> | $0 - [encryption_key]" >&2
        exit 1
    fi
    
    local input_file="$1"
    local key="${2:-$DEFAULT_KEY}"
    local code
    
    if [[ "$input_file" == "-" ]]; then
        # Read from stdin
        code=$(cat)
    else
        # Read from file
        if [[ ! -f "$input_file" ]]; then
            echo "Error: File '$input_file' not found" >&2
            exit 1
        fi
        
        if [[ ! -r "$input_file" ]]; then
            echo "Error: File '$input_file' is not readable" >&2
            exit 1
        fi
        
        code=$(cat "$input_file")
    fi
    
    if [[ -z "$code" ]]; then
        echo "Error: No input code provided" >&2
        exit 1
    fi
    
    # Process the code
    local obfuscated
    obfuscated=$(process_shell_script "$code" "$key")
    
    # Output result
    echo "$obfuscated"
}

# Export functions for use as library
export -f encrypt_string
export -f generate_obfuscated_name
export -f is_reserved_identifier
export -f encrypt_strings
export -f obfuscate_identifiers
export -f add_control_flow_obfuscation
export -f add_dead_code
export -f add_anti_debugging
export -f add_function_obfuscation
export -f process_shell_script

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
#!/bin/bash
# Bash Script Advanced Obfuscator
# Specialized for Bash-specific features and optimizations

# Check if required tools are available
command -v openssl >/dev/null 2>&1 || { echo "openssl is required but not installed. Aborting." >&2; exit 1; }
command -v base64 >/dev/null 2>&1 || { echo "base64 is required but not installed. Aborting." >&2; exit 1; }

# Default encryption key
DEFAULT_KEY="bash_encryption_key_32_characters"

# Arrays to store mappings
declare -A identifier_map
declare -A string_map
declare -A function_map
declare -a encrypted_strings
declare -a obfuscated_functions

# Bash-specific reserved keywords and built-ins
bash_keywords=(
    "if" "then" "else" "elif" "fi" "case" "esac" "for" "select" "while" "until"
    "do" "done" "function" "time" "coproc" "in" "break" "continue" "return"
    "exit" "export" "readonly" "local" "declare" "typeset" "unset" "shift"
    "set" "unset" "alias" "unalias" "history" "fc" "jobs" "bg" "fg" "disown"
    "suspend" "kill" "wait" "trap" "source" "." "eval" "exec" "builtin"
    "command" "type" "which" "whereis" "whatis" "apropos" "man" "info"
    "help" "cd" "pwd" "dirs" "pushd" "popd" "enable" "caller" "complete"
    "compgen" "compopt" "mapfile" "readarray" "printf" "read" "getopts"
    "shopt" "bind" "hash" "ulimit" "umask" "times" "test" "[" "[["
    "echo" "printf" "read" "mapfile" "readarray" "getopts" "getopt"
    "basename" "dirname" "realpath" "readlink" "pathchk" "mktemp"
    "BASH" "BASH_VERSION" "BASH_VERSINFO" "BASHPID" "BASH_SUBSHELL"
    "BASH_SOURCE" "BASH_LINENO" "BASH_ARGC" "BASH_ARGV" "FUNCNAME"
    "BASH_REMATCH" "BASH_EXECUTION_STRING" "BASH_COMMAND" "BASH_XTRACEFD"
    "COMP_CWORD" "COMP_LINE" "COMP_POINT" "COMP_TYPE" "COMP_KEY"
    "COMP_WORDBREAKS" "COMP_WORDS" "COMPREPLY" "DIRSTACK" "EUID"
    "GROUPS" "HISTCMD" "HOSTNAME" "HOSTTYPE" "LINENO" "MACHTYPE"
    "OLDPWD" "OPTARG" "OPTERR" "OPTIND" "OSTYPE" "PIPESTATUS"
    "PPID" "PWD" "RANDOM" "REPLY" "SECONDS" "SHELLOPTS" "SHLVL"
    "UID" "BASH_ALIASES" "BASH_CMDS" "BASH_LOADABLES_PATH"
)

# Function to encrypt string using OpenSSL with Bash optimizations
encrypt_string_bash() {
    local plaintext="$1"
    local key="$2"
    
    if [[ -z "$plaintext" || -z "$key" ]]; then
        echo ""
        return 1
    fi
    
    # Use OpenSSL for AES-256-CBC encryption with Bash-specific optimizations
    local encrypted
    encrypted=$(printf '%s' "$plaintext" | openssl enc -aes-256-cbc -a -salt -k "$key" 2>/dev/null)
    
    if [[ $? -eq 0 && -n "$encrypted" ]]; then
        echo "$encrypted"
    else
        # Fallback to base64 encoding with XOR
        local xor_key=$(printf '%d' "'${key:0:1}")
        local result=""
        for ((i=0; i<${#plaintext}; i++)); do
            local char="${plaintext:$i:1}"
            local ascii=$(printf '%d' "'$char")
            local xor_result=$((ascii ^ xor_key))
            result="$result$(printf '\\%03o' $xor_result)"
        done
        echo "$result" | base64 -w 0
    fi
}

# Function to generate Bash-optimized obfuscated name
generate_bash_obfuscated_name() {
    local prefix="${1:-_}"
    local charset="abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
    local length=$((6 + RANDOM % 6))  # 6-11 characters
    local result="$prefix"
    
    # Generate random characters
    for ((i=0; i<length; i++)); do
        local char_index=$((RANDOM % ${#charset}))
        result="${result}${charset:$char_index:1}"
    done
    
    # Add random numbers
    result="${result}$((RANDOM % 1000))"
    
    echo "$result"
}

# Function to check if identifier is Bash reserved
is_bash_reserved() {
    local identifier="$1"
    
    for keyword in "${bash_keywords[@]}"; do
        if [[ "$identifier" == "$keyword" ]]; then
            return 0  # true
        fi
    done
    
    return 1  # false
}

# Function to obfuscate Bash arrays
obfuscate_bash_arrays() {
    local code="$1"
    local result="$code"
    
    # Find array declarations and obfuscate names
    while [[ "$result" =~ declare[[:space:]]+-[aA][[:space:]]+([a-zA-Z_][a-zA-Z0-9_]*) ]]; do
        local array_name="${BASH_REMATCH[1]}"
        
        if ! is_bash_reserved "$array_name"; then
            if [[ -z "${identifier_map[$array_name]}" ]]; then
                identifier_map["$array_name"]=$(generate_bash_obfuscated_name "_arr")
            fi
            
            local obfuscated="${identifier_map[$array_name]}"
            result="${result//declare -a $array_name/declare -a $obfuscated}"
            result="${result//declare -A $array_name/declare -A $obfuscated}"
            result="${result//\$$array_name/\$$obfuscated}"
            result="${result//\${$array_name/\${$obfuscated}"
        fi
    done
    
    echo "$result"
}

# Function to obfuscate Bash parameter expansions
obfuscate_parameter_expansions() {
    local code="$1"
    local result="$code"
    
    # Obfuscate parameter expansion patterns
    # ${var:-default} -> ${obfuscated_var:-default}
    # ${var:=default} -> ${obfuscated_var:=default}
    # ${var:?error} -> ${obfuscated_var:?error}
    # ${var:+alternate} -> ${obfuscated_var:+alternate}
    
    local expansions=(":-" ":=" ":?" ":+" "#" "##" "%" "%%" "/" "//")
    
    for expansion in "${expansions[@]}"; do
        while [[ "$result" =~ \$\{([a-zA-Z_][a-zA-Z0-9_]*)($expansion[^}]*)?\} ]]; do
            local full_match="${BASH_REMATCH[0]}"
            local var_name="${BASH_REMATCH[1]}"
            local expansion_part="${BASH_REMATCH[2]}"
            
            if ! is_bash_reserved "$var_name"; then
                if [[ -z "${identifier_map[$var_name]}" ]]; then
                    identifier_map["$var_name"]=$(generate_bash_obfuscated_name "_var")
                fi
                
                local obfuscated="${identifier_map[$var_name]}"
                local new_expansion="\${$obfuscated$expansion_part}"
                result="${result/$full_match/$new_expansion}"
            fi
        done
    done
    
    echo "$result"
}

# Function to add Bash-specific control flow obfuscation
add_bash_control_flow() {
    local code="$1"
    local result="$code"
    
    # Convert if statements to arithmetic evaluation
    result=$(echo "$result" | sed -E 's/if \[\[ (.+) \]\]; then/_cond=$(( (\1) ? 1 : 0 )); if (( _cond )); then/g')
    
    # Convert for loops to while loops with counters
    result=$(echo "$result" | sed -E 's/for ([a-zA-Z_][a-zA-Z0-9_]*) in \{([0-9]+)\.\.([0-9]+)\}/\1=\2; while (( \1 <= \3 )); do/g')
    result=$(echo "$result" | sed -E 's/done$/((\1++)); done/g')
    
    # Add nested case statements for complex conditions
    local case_obfuscation='_switch_var=$((RANDOM % 3))
case $_switch_var in
    0|1|2) ;;
    *) exit 1 ;;
esac'
    
    # Insert case obfuscation after function definitions
    result=$(echo "$result" | sed '/^[[:space:]]*function[[:space:]]\+[a-zA-Z_][a-zA-Z0-9_]*[[:space:]]*()[[:space:]]*{/a\
'"$case_obfuscation")
    
    echo "$result"
}

# Function to add Bash-specific dead code
add_bash_dead_code() {
    local code="$1"
    local result=""
    
    local bash_dead_code=(
        "_dummy_pid=\$\$"
        "_dummy_random=\$RANDOM"
        "_dummy_seconds=\$SECONDS"
        "if (( _dummy_random > 32767 )); then echo \"Impossible\" >/dev/null; fi"
        "_dummy_array=(\$RANDOM \$RANDOM \$RANDOM)"
        "_dummy_func() { local _x=\$1; return \$((_x % 2)); }"
        "declare -A _dummy_assoc=([key1]=value1 [key2]=value2)"
        "_dummy_subshell=\$(echo \$BASH_SUBSHELL)"
        "_dummy_lineno=\$LINENO"
        "shopt -s nullglob 2>/dev/null || true"
        "_dummy_opts=\$-"
        "_dummy_pipestatus=(\${PIPESTATUS[@]})"
    )
    
    local line_count=0
    local insertions=0
    
    while IFS= read -r line; do
        result="${result}${line}\n"
        
        # Insert Bash-specific dead code
        if [[ "$line" =~ ^[[:space:]]*(function|if|for|while|case|declare) ]] && [[ $insertions -lt 4 ]]; then
            local dead_code_index=$((RANDOM % ${#bash_dead_code[@]}))
            result="${result}${bash_dead_code[$dead_code_index]}\n"
            ((insertions++))
        fi
        
        ((line_count++))
    done <<< "$code"
    
    echo -e "$result"
}

# Function to add Bash-specific anti-debugging
add_bash_anti_debugging() {
    local code="$1"
    
    local bash_anti_debug='# Bash-specific anti-debugging measures
bash_anti_debug_check() {
    # Check Bash debugging options
    if [[ "$-" == *x* ]] || [[ "$-" == *v* ]]; then
        exit 1
    fi
    
    # Check for Bash debugging variables
    if [[ -n "$BASH_XTRACEFD" ]] || [[ -n "$PS4" ]]; then
        exit 1
    fi
    
    # Check for function tracing
    if [[ "$(set +o)" == *"set +o functrace"* ]]; then
        exit 1
    fi
    
    # Check for error tracing
    if [[ "$(set +o)" == *"set +o errtrace"* ]]; then
        exit 1
    fi
    
    # Check BASH_COMMAND for debugging patterns
    if [[ "$BASH_COMMAND" =~ (strace|ltrace|gdb|debug) ]]; then
        exit 1
    fi
    
    # Check for suspicious environment variables
    local suspicious_vars=("DEBUG" "TRACE" "VERBOSE" "BASH_DEBUG" "BASH_TRACE")
    for var in "${suspicious_vars[@]}"; do
        if [[ -n "${!var}" ]]; then
            exit 1
        fi
    done
    
    # Check for debugging tools in process list
    if command -v pgrep >/dev/null 2>&1; then
        local debug_tools=("strace" "ltrace" "gdb" "bashdb" "valgrind")
        for tool in "${debug_tools[@]}"; do
            if pgrep -f "$tool.*$(basename "$0")" >/dev/null 2>&1; then
                exit 1
            fi
        done
    fi
    
    # Check for script modification using BASH_SOURCE
    if [[ -n "${BASH_SOURCE[0]}" ]]; then
        local script_path="$(readlink -f "${BASH_SOURCE[0]}")"
        if [[ -f "$script_path" ]]; then
            local current_size
            current_size=$(stat -c%s "$script_path" 2>/dev/null)
            local expected_size="SCRIPT_SIZE_PLACEHOLDER"
            
            if [[ -n "$current_size" && -n "$expected_size" && "$current_size" != "$expected_size" ]]; then
                exit 1
            fi
        fi
    fi
    
    # Check for interactive shell
    if [[ $- == *i* ]]; then
        # Interactive mode might be debugging
        # Uncomment if needed: exit 1
        :
    fi
    
    # Check for job control
    if [[ $- == *m* ]] && jobs -p 2>/dev/null | grep -q "."; then
        # Background jobs might indicate debugging
        # Uncomment if needed: exit 1
        :
    fi
    
    # Timing check with Bash built-ins
    local start_time=$SECONDS
    local dummy=0
    for ((i=0; i<1000; i++)); do
        dummy=$((dummy + i))
    done
    local end_time=$SECONDS
    local elapsed=$((end_time - start_time))
    
    if (( elapsed > 1 )); then  # 1 second
        exit 1
    fi
    
    # Check BASH_SUBSHELL for unusual nesting
    if (( BASH_SUBSHELL > 5 )); then
        exit 1
    fi
    
    # Check for unusual SHLVL
    if (( SHLVL > 10 )); then
        exit 1
    fi
    
    # Check for history manipulation
    if [[ -n "$HISTFILE" ]] && [[ ! -w "$HISTFILE" ]]; then
        # History file not writable, might be analysis environment
        # Uncomment if needed: exit 1
        :
    fi
    
    # Check for unusual BASH_VERSINFO
    if [[ ${BASH_VERSINFO[0]} -lt 3 ]]; then
        # Very old Bash version, might be emulated
        exit 1
    fi
    
    # Check for read-only variables
    if readonly -p | grep -q "BASH_.*=.*readonly"; then
        # Unusual readonly Bash variables
        # Uncomment if needed: exit 1
        :
    fi
}

'
    
    local result="$bash_anti_debug$code"
    
    # Insert anti-debug calls in Bash functions
    result=$(echo "$result" | sed '/^[[:space:]]*function[[:space:]]\+[a-zA-Z_][a-zA-Z0-9_]*[[:space:]]*()[[:space:]]*{/a\
    bash_anti_debug_check')
    result=$(echo "$result" | sed '/^[[:space:]]*[a-zA-Z_][a-zA-Z0-9_]*[[:space:]]*()[[:space:]]*{/a\
    bash_anti_debug_check')
    
    # Insert at script beginning
    result="bash_anti_debug_check\n$result"
    
    echo -e "$result"
}

# Function to obfuscate Bash built-in commands
obfuscate_bash_builtins() {
    local code="$1"
    local result="$code"
    
    # Create aliases for built-in commands
    local builtin_aliases='# Obfuscated built-in aliases
'
    
    local builtins=("echo" "printf" "read" "test" "[" "export" "declare" "local")
    
    for builtin in "${builtins[@]}"; do
        if ! is_bash_reserved "$builtin"; then
            local alias_name=$(generate_bash_obfuscated_name "_cmd")
            builtin_aliases="${builtin_aliases}alias $alias_name='$builtin'\n"
            
            # Replace builtin usage with alias
            result=$(echo "$result" | sed "s/\\b$builtin\\b/$alias_name/g")
        fi
    done
    
    result="$builtin_aliases$result"
    
    echo -e "$result"
}

# Function to add Bash completion obfuscation
add_bash_completion_obfuscation() {
    local code="$1"
    
    local completion_code='# Bash completion obfuscation
_obfuscated_complete() {
    local cur prev opts
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"
    
    # Fake completion options
    opts="--help --version --config --debug --verbose"
    
    if [[ ${cur} == -* ]]; then
        COMPREPLY=( $(compgen -W "${opts}" -- ${cur}) )
        return 0
    fi
    
    # Generate fake file completions
    COMPREPLY=( $(compgen -f -- ${cur}) )
}

# Register fake completion
complete -F _obfuscated_complete "$(basename "$0")"

'
    
    echo "$completion_code$code"
}

# Main Bash processing function
process_bash_script() {
    local code="$1"
    local key="${2:-$DEFAULT_KEY}"
    
    local result="$code"
    
    # Apply Bash-specific obfuscations
    result=$(encrypt_strings "$result" "$key")
    result=$(obfuscate_bash_arrays "$result")
    result=$(obfuscate_parameter_expansions "$result")
    result=$(add_function_obfuscation "$result")
    result=$(obfuscate_identifiers "$result")
    result=$(add_bash_control_flow "$result")
    result=$(add_bash_dead_code "$result")
    result=$(obfuscate_bash_builtins "$result")
    result=$(add_bash_completion_obfuscation "$result")
    result=$(add_bash_anti_debugging "$result")
    
    echo "$result"
}

# Function to encrypt strings (reuse from ShellProcessor)
encrypt_strings() {
    local code="$1"
    local key="$2"
    local result=""
    
    # Add decryption utility
    local decrypt_utility='# String decryption utility for Bash
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
        # Fallback decryption
        local xor_key=$(printf "%d" "'${key:0:1}")
        local decoded
        decoded=$(echo "$encrypted" | base64 -d 2>/dev/null)
        
        if [[ $? -eq 0 ]]; then
            printf "%b" "$decoded"
        else
            echo ""
            return 1
        fi
    fi
}

'
    
    result="$decrypt_utility"
    
    # Process string literals with Bash-specific handling
    local string_index=0
    local temp_code="$code"
    
    # Handle double-quoted strings with variable expansion
    while [[ "$temp_code" =~ \"([^\"\\]*(\\.[^\"\\]*)*)\" ]]; do
        local match="${BASH_REMATCH[0]}"
        local content="${BASH_REMATCH[1]}"
        
        # Skip strings with variable expansion
        if [[ "$content" =~ \$ ]]; then
            temp_code="${temp_code/$match/__SKIP_STRING_$string_index__}"
        else
            local encrypted
            encrypted=$(encrypt_string_bash "$content" "$key")
            
            if [[ -n "$encrypted" ]]; then
                local var_name="_str_${string_index}"
                encrypted_strings+=("$var_name=\$(decrypt_string \"$encrypted\" \"$key\")")
                temp_code="${temp_code/"$match"/"\$$var_name"}"
            fi
        fi
        ((string_index++))
    done
    
    # Restore skipped strings
    for ((i=0; i<string_index; i++)); do
        temp_code="${temp_code/__SKIP_STRING_$i__/\"\"}"
    done
    
    # Add string declarations
    for str_decl in "${encrypted_strings[@]}"; do
        result="${result}${str_decl}\n"
    done
    
    result="${result}${temp_code}"
    echo "$result"
}

# Function to obfuscate identifiers (reuse with Bash-specific improvements)
obfuscate_identifiers() {
    local code="$1"
    local result="$code"
    
    # Find all identifiers with Bash-specific patterns
    local identifiers
    identifiers=$(echo "$code" | grep -oE '\b[a-zA-Z_][a-zA-Z0-9_]*\b' | sort -u)
    
    while IFS= read -r identifier; do
        if [[ -n "$identifier" && ${#identifier} -gt 1 ]]; then
            if ! is_bash_reserved "$identifier"; then
                if [[ -z "${identifier_map[$identifier]}" ]]; then
                    identifier_map["$identifier"]=$(generate_bash_obfuscated_name)
                fi
                
                local obfuscated="${identifier_map[$identifier]}"
                # Use Bash parameter expansion for replacement
                result="${result//\b$identifier\b/$obfuscated}"
            fi
        fi
    done <<< "$identifiers"
    
    echo "$result"
}

# Function to add function obfuscation (reuse with Bash improvements)
add_function_obfuscation() {
    local code="$1"
    local result="$code"
    
    # Handle Bash function definitions
    while [[ "$result" =~ (function[[:space:]]+)([a-zA-Z_][a-zA-Z0-9_]*)([[:space:]]*\(\)[[:space:]]*\{) ]]; do
        local full_match="${BASH_REMATCH[0]}"
        local prefix="${BASH_REMATCH[1]}"
        local func_name="${BASH_REMATCH[2]}"
        local suffix="${BASH_REMATCH[3]}"
        
        if ! is_bash_reserved "$func_name"; then
            if [[ -z "${function_map[$func_name]}" ]]; then
                function_map["$func_name"]=$(generate_bash_obfuscated_name "_func")
            fi
            
            local obfuscated="${function_map[$func_name]}"
            result="${result/$full_match/$prefix$obfuscated$suffix}"
            
            # Replace function calls
            result="${result//\b$func_name\b/$obfuscated}"
        fi
    done
    
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
        code=$(cat)
    else
        if [[ ! -f "$input_file" ]]; then
            echo "Error: File '$input_file' not found" >&2
            exit 1
        fi
        
        code=$(cat "$input_file")
    fi
    
    if [[ -z "$code" ]]; then
        echo "Error: No input code provided" >&2
        exit 1
    fi
    
    # Process the Bash code
    local obfuscated
    obfuscated=$(process_bash_script "$code" "$key")
    
    echo "$obfuscated"
}

# Export functions for library use
export -f encrypt_string_bash
export -f generate_bash_obfuscated_name
export -f is_bash_reserved
export -f obfuscate_bash_arrays
export -f obfuscate_parameter_expansions
export -f add_bash_control_flow
export -f add_bash_dead_code
export -f add_bash_anti_debugging
export -f obfuscate_bash_builtins
export -f add_bash_completion_obfuscation
export -f process_bash_script

# Run main function if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
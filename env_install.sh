#!/usr/bin/env bash
#
# env_install.sh
# Sets up a basic Python / Jupyter development environment.
# Supports: Linux (apt, dnf, pacman) and macOS (Homebrew).
#
# Usage:
#   chmod +x env_install.sh
#   ./env_install.sh

# ---------------------------------------------------------------------------
# Functions
# ---------------------------------------------------------------------------

# Feature 1: pretty printing.
# Blank lines around each message make the steps easy to spot in the output.
pretty_print() {
    printf "\n==> %s\n\n" "$1"
}

# Prints an error and stops the script, so we never continue in a broken state.
fail() {
    printf "\n[ERROR] %s\n\n" "$1" >&2
    exit 1
}

# Returns success if the given command exists on the system.
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Feature 2: OS detection using the OSTYPE environment variable.
detect_os() {
    case "$OSTYPE" in
        linux*)  OS="linux" ;;
        darwin*) OS="macos" ;;
        msys*|cygwin*) OS="windows" ;;
        *)       OS="unknown" ;;
    esac
}

# Linux has several package managers; pick whichever one is installed.
detect_linux_pkg_manager() {
    if command_exists apt-get; then
        PKG="apt"
    elif command_exists dnf; then
        PKG="dnf"
    elif command_exists pacman; then
        PKG="pacman"
    else
        fail "No supported package manager found (apt, dnf, pacman)."
    fi
}

# Installs one or more packages with the right package manager for this system.
install_pkg() {
    if [ "$OS" = "macos" ]; then
        brew install "$@"
    else
        case "$PKG" in
            apt)    sudo apt-get update && sudo apt-get install -y "$@" ;;
            dnf)    sudo dnf install -y "$@" ;;
            pacman) sudo pacman -S --noconfirm "$@" ;;
        esac
    fi
}

# Feature 3: make sure python3 is available.
check_python() {
    pretty_print "Checking Python installation"

    if command_exists python3; then
        printf "Python is already installed: %s\n" "$(python3 --version)"
    else
        printf "python3 not found, installing it...\n"
        if [ "$OS" = "macos" ]; then
            install_pkg python
        else
            case "$PKG" in
                apt)    install_pkg python3 ;;
                dnf)    install_pkg python3 ;;
                pacman) install_pkg python ;;
            esac
        fi
        command_exists python3 || fail "Python installation failed."
        printf "Python installed: %s\n" "$(python3 --version)"
    fi
}

# Feature 4: make sure pip is available.
# On Debian/Ubuntu pip is a separate package, so we may need to install it.
check_pip() {
    pretty_print "Checking pip installation"

    if python3 -m pip --version >/dev/null 2>&1; then
        printf "pip is available: %s\n" "$(python3 -m pip --version)"
    else
        printf "pip not found, installing it...\n"
        if [ "$OS" = "macos" ]; then
            python3 -m ensurepip --upgrade
        else
            case "$PKG" in
                apt)    install_pkg python3-pip ;;
                dnf)    install_pkg python3-pip ;;
                pacman) install_pkg python-pip ;;
            esac
        fi
        python3 -m pip --version >/dev/null 2>&1 || fail "pip installation failed."
        printf "pip installed: %s\n" "$(python3 -m pip --version)"
    fi
}

# Feature 5: install Jupyter Notebook.
# First try pip. Recent Ubuntu/Debian and Homebrew Python block system-wide
# pip installs (PEP 668 "externally managed environment"), so if pip refuses
# we fall back to the OS package manager.
install_jupyter() {
    pretty_print "Installing Jupyter Notebook"

    if command_exists jupyter; then
        printf "Jupyter is already installed: %s\n" "$(jupyter --version | head -n 1)"
        return
    fi

    if python3 -m pip install --user notebook; then
        printf "Jupyter installed with pip.\n"
    else
        printf "pip install refused, using the system package manager instead...\n"
        if [ "$OS" = "macos" ]; then
            install_pkg jupyterlab
        else
            case "$PKG" in
                apt)    install_pkg jupyter-notebook ;;
                dnf)    install_pkg python3-notebook ;;
                pacman) install_pkg jupyter-notebook ;;
            esac
        fi
    fi

    # pip --user puts executables in ~/.local/bin, which may not be in PATH yet.
    export PATH="$HOME/.local/bin:$PATH"

    if command_exists jupyter; then
        printf "Jupyter is ready. Launch it with: jupyter notebook\n"
    else
        fail "Jupyter installation failed."
    fi
}

# Feature 6: on macOS, check that Homebrew itself is healthy.
macos_health_check() {
    pretty_print "Running Homebrew health check (brew doctor)"
    brew doctor || printf "brew doctor reported warnings, read them above.\n"
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

pretty_print "Starting environment setup"

detect_os
printf "Detected OS: %s (OSTYPE=%s)\n" "$OS" "$OSTYPE"

case "$OS" in
    linux)
        detect_linux_pkg_manager
        printf "Using package manager: %s\n" "$PKG"
        ;;
    macos)
        # Homebrew is required on macOS; we don't install it silently.
        command_exists brew || fail "Homebrew not found. Install it from https://brew.sh then rerun."
        ;;
    windows)
        fail "Native Windows is not supported. Please run this script inside WSL."
        ;;
    *)
        fail "Unsupported operating system: $OSTYPE"
        ;;
esac

check_python
check_pip
install_jupyter

if [ "$OS" = "macos" ]; then
    macos_health_check
fi

pretty_print "Setup complete!"

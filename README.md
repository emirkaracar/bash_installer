# bash-installer

A Bash script that sets up a Python / Jupyter environment on Linux or macOS.

## Usage

```bash
chmod +x env_install.sh
./env_install.sh
```

The script detects the OS (`$OSTYPE`), installs or checks `python3` and `pip`, installs Jupyter Notebook, and runs `brew doctor` on macOS.

## Notes

- **Current shell:** `echo $0` — **login shell:** `echo $SHELL`
- **Oh My Bash:** `bash -c "$(curl -fsSL https://raw.githubusercontent.com/ohmybash/oh-my-bash/master/tools/install.sh)"`, theme set with `OSH_THEME` and `plugins=(git)` in `~/.bashrc`
- **`source`:** runs a file in the current shell, so changes (e.g. to `~/.bashrc`) apply without opening a new terminal
- **Git aliases:** `gst` (status), `gl` (pull), `gp` (push)
- **Python:** use `python3 --version`, since `python` may point to Python 2

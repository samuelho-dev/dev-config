# Python PATH setup (check if installed)
if [ -d "/Library/Frameworks/Python.framework/Versions/3.13/bin" ]; then
  PATH="/Library/Frameworks/Python.framework/Versions/3.13/bin:${PATH}"
fi

if [ -d "/Library/Frameworks/Python.framework/Versions/3.11/bin" ]; then
  PATH="/Library/Frameworks/Python.framework/Versions/3.11/bin:${PATH}"
fi

export PATH

# Homebrew setup (platform-agnostic)
if [ -f /opt/homebrew/bin/brew ]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [ -f /usr/local/bin/brew ]; then
  eval "$(/usr/local/bin/brew shellenv)"
elif [ -f /home/linuxbrew/.linuxbrew/bin/brew ]; then
  eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
fi

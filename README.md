### Description

XCode 4 `HOME` (`ctrl-left`) keys behave differently then in Visual Studio. It makes jump to the beginning of line, not the beginning of code. This plugin fixes this odd behavior by making jump-to-beginning-of-line more intelligent. If caret stands on code or at the beginning of line, it jumps to the first non-whitespace character of the line. In the other case it jumps just to the beginning of line.

### Installation

Download and compile the project or download the binary and unzip it to `~Library/Application Support/Developer/Shared/Xcode/Plug-ins/`

### Credits

Thanks to Dave Keck for XCode 4 Fixins project (https://github.com/davekeck/Xcode-4-Fixins)
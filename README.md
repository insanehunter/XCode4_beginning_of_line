### This plugin was renamed to `Xcode_beginning_of_line`.

The repository name won't change, but with help of [Thongchai Kolyutsakul](https://github.com/hlung) the plugin itself was renamed to `Xcode_beginning_of_line`. I added a build step to automatically remove the previous version.

### Description

Unfortunately the `HOME` (`fn←` and `⌘←` on a Mac keyboard) key in Xcode acts in a dumb way - it jumps to the first, usually whitespace, line character, so you cannot instantly jump to the first code character. Visual Studio implements this feature in a right way, jumping to the leftmost non-whitespace character on a first key press and to the beginning of line on a second, cycling between these positions on futher strokes. This plugin implements this smart behavior in Xcode.

### Installation

Download and compile the project (the plugin will be installed during build process) or download the binary and unzip it to `~/Library/Application Support/Developer/Shared/Xcode/Plug-ins/`

### Credits

Contributors:
* [Jim Sagevid](https://github.com/jims)
* [supulsinac](https://github.com/supulsinac)
* [Ben Kreeger](https://github.com/kreeger)
* [gottfired](https://github.com/gottfired)
* [Thongchai Kolyutsakul](https://github.com/hlung)

Thanks to [Dave Keck](https://github.com/davekeck) for [Xcode 4 Fixins project](https://github.com/davekeck/Xcode-4-Fixins)

# Steam

*The best way to play games on linux*

## Post-install
1. If you cant launch steam, then launch it from terminal: `steam` -> go to settings -> Interface -> Disable GPU rendering
2. Setup proton to run windows games: settings -> Compatibility -> choose: Proton Hotfix
  2.1. On each game your going to play -> Properties... -> Compatibility -> Force the use of a specific Steam Play compatibility tool
3. Make game always choose discrete video card and use system gamemoderun: on each game your going to play -> Properties... -> General -> Launch Options: `DRI_PRIME=1 gamemoderun %command%`

## Game issues
1. If you have some game issues, you can find solution to your specific game by entering specific Launch Options from site: https://www.protondb.com/
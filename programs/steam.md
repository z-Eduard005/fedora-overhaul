# Steam

*The best way to play games on linux*

## Post-install
1. If you can't launch Steam, then launch it from the terminal: `steam` → go to Settings → Interface → disable GPU rendering  
2. Set up Proton to run Windows games: Settings → Compatibility → choose: Proton Hotfix  
  2.1. For each game you're going to play → Properties... → Compatibility → Force the use of a specific Steam Play compatibility tool  
3. Make the game always choose the discrete video card and use the system gamemoderun: for each game you're going to play → Properties... → General → Launch Options: `DRI_PRIME=1 gamemoderun %command%`

## Game issues
1. If you have some game issues, you can find a solution for your specific game by entering specific Launch Options from the site: https://www.protondb.com/
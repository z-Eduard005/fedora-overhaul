# Installation alongside Windows OS

## Windows
1. Fully update the system with system updates and Microsoft Store updates
2. Disable indexing on every disk (optional)
3. Disable Fast Startup: <win+r> → `powercfg.cpl`
4. Disable BitLocker on every disk: Control Panel → Search - Bitlocker
5. Make a free-space partition (at least 256 GB): <win+x> → Disk Management → Right-click some drive → Shrink Volume → Set the amount of space to shrink
6. Reboot
7. Install Fedora Media Writer: https://github.com/FedoraQt/MediaWriter/releases/latest and write the latest Fedora version (not BETA) to a thumbstick

## BIOS/UEFI (steps may differ depending on your motherboard/laptop, so just google it)
1. Disable Secure Boot
2. Reboot into Windows and go back to BIOS/UEFI
3. Set the Fedora thumbstick as the first boot device and start the system from it

## GRUB (this boot menu will now appear every time you start your PC)
1. For the first time choose "Test this media" (if it does not work, try another option next time)

## Fedora 
1. Test all the things: camera, microphone, sound, headphones, charging, monitor refresh rate, keyboard backlighting, Wi‑Fi, Bluetooth, etc.
2. Open the Fedora installer app:  
  2.1. Welcome: Recommended language - English (United States)  
  2.2. Installation method: Share disk with other OS → Check - Reclaim additional space → Reclaim  
  2.3. Storage configuration: Do not encrypt data  
  2.4. Review and install: Install  
3. Reboot into Windows to check it's working (you can choose it in GRUB)
4. To boot into Fedora, simply wait at the GRUB menu or press Enter on the first option for a quicker start.
5. Use the **`post-install.md`** instruction next
# Optional settings (my suggestions)

## Grub
1. `sudo nano /etc/default/grub`:
  1.1. Makes system start faster: `GRUB_TIMEOUT=3`
  1.2. Adds custom refresh rate:
  ```
  # additional refresh rate 
  GRUB_CMDLINE_LINUX_DEFAULT="quiet video=HDMI-A-1:1920x1080@75"
  ```
  1.3. Always run this after updating grub file to save changes: `sudo grub2-mkconfig -o /boot/grub2/grub.cfg`

## Custom bashrc file
1. You can add custom aliases with this file - `nano ~/.bashrc.d/custom.bashrc`:
```
# alias
alias h=help
alias c=clear
```
# Some script

## Armbian kernel update (For Amlogic box)

Provide the kernel update of the Armbian system provided by Flippy used in the Amlogic series box. Can be directly replaced to any series, such as 5.4 to 5.13. Enter any directory of the Armbian system, such as `cd /root`, and run the command directly.

- The supported SOC types are: `s905x3`, `s905x2`, `s905x`, `s905d`, `s912`, `s922x`. When prompted `Please enter the SOC type of your device, such as s905x3:`, Please enter the SOC model of the current device.

- Support updated [kernel version](https://github.com/ophub/flippy-kernel/tree/main/library). When prompted `Please enter the kernel version number, such as 5.13.2:`, Please enter the kernel version number.

```shell
# Run as root user (sudo -i)
bash <(curl -fsSL git.io/armbian-kernel)
```

## OpenWrt kernel update (For Amlogic box)

Provide luci operation support for Amlogic STB. The current functions include `install OpenWrt to EMMC`, `Manually Upload Updates / Download Updates Online to update the OpenWrt firmware or kernel`, `Backup / Restore firmware config` and `Custom firmware / kernel download site`, etc.

Use SSH to log in to any directory of OpenWrt system, Or in the `OpenWrt` → `System menu` → `TTYD terminal`, Run the onekey install command to automatically download and install this plugin. After the installation is complete, you can find the `Amlogic Service` plugin under the `System menu` of `OpenWrt`.

```yaml
curl -fsSL git.io/luci-app-amlogic | bash
```

## Ubuntu-2004-server compilation environment

One-click installation of `Kernel` and `OpenWrt` compile common environment configuration.

```yaml
sudo apt-get update -y
sudo apt-get full-upgrade -y
sudo apt-get install -y $(curl -fsSL git.io/ubuntu-2004-server)
sudo apt-get dist-upgrade -y
sudo apt-get autoremove -y
```

## License
- [LICENSE](https://github.com/ophub/script/blob/main/LICENSE) © OPHUB

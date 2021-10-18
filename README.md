# Some script

## Armbian kernel update (For Amlogic s9xxx, Allwinner, Rockchip)

Support `update kernel` of Armbian system of made and shared by [flippy](https://github.com/unifreq). It also applies in [amlogic-s9xxx-armbian](https://github.com/ophub/amlogic-s9xxx-armbian). For example, 5.4, 5.10, 5.14, etc., you can directly update and switch to a different kernel version. Enter any directory of the Armbian system, such as `cd /root`, and run the command directly. 
- Command: `bash <(curl -fsSL git.io/armbian-kernel) <soc> <kernel_version>`

- The supported `<soc>` types are: `s905x3`, `s905x2`, `s905x`, `s905d`, `s912`, `s922x`, `l1pro`, `beikeyun`, `vplus`.

- Support updated <[kernel_version](https://github.com/ophub/flippy-kernel/tree/main/library)>.

- When the one-key command you enter is missing the `<soc>` or `<kernel_version>`, it will be asked, please enter it according to the prompts.

```shell
# E.g: Run as root user (sudo -i)
bash <(curl -fsSL git.io/armbian-kernel) s905x3 5.10.70
```

## OpenWrt kernel update (For Amlogic box)

From [luci-app-amlogic](https://github.com/ophub/luci-app-amlogic). Supports management of Amlogic s9xxx, Allwinner (V-Plus Cloud), and Rockchip (BeikeYun, Chainedbox L1 Pro) boxes. The current functions include `install OpenWrt to EMMC`, `Manually Upload Updates / Download Updates Online to update the OpenWrt firmware or kernel`, `Backup / Restore firmware config`, `Snapshot management` and `Custom firmware / kernel download site`, etc.

Use SSH to log in to any directory of OpenWrt system, Or in the `OpenWrt` → `System menu` → `TTYD terminal`, Run the onekey install command to automatically download and install this plugin. After the installation is complete, you can find the `Amlogic Service` plugin under the `System menu` of `OpenWrt`.

```yaml
curl -fsSL git.io/luci-app-amlogic | bash
```
## Website access test

Support: netflix.com / youtube.com / steampowered.com

```yaml
bash <(curl -fsSL git.io/webtest)
```

## Ubuntu-2004-server compilation environment

One-click install of `Kernel` compile common environment configuration.

```yaml
sudo apt-get update -y
sudo apt-get full-upgrade -y
sudo apt-get install -y $(curl -fsSL git.io/ubuntu-2004-server)
sudo apt-get dist-upgrade -y
sudo apt-get autoremove -y
```

## Ubuntu-2004-openwrt compilation environment

One-click install of `OpenWrt` compilation environment for Ubuntu 20.04 system.

```yaml
sudo apt-get update -y
sudo apt-get full-upgrade -y
sudo apt-get install -y $(curl -fsSL git.io/ubuntu-2004-openwrt)
sudo apt-get dist-upgrade -y
sudo apt-get autoremove -y
```

## Ubuntu-1804-openwrt compilation environment

One-click install of `OpenWrt` compilation environment for Ubuntu 18.04 system.

```yaml
sudo apt-get update -y
sudo apt-get full-upgrade -y
sudo apt-get install -y $(curl -fsSL git.io/ubuntu-1804-openwrt)
sudo apt-get dist-upgrade -y
sudo apt-get autoremove -y
```

## License
- [LICENSE](https://github.com/ophub/script/blob/main/LICENSE) © OPHUB

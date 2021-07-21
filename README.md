# script

## Armbian kernel update

- The supported SOC types are: `s905x3`, `s905x2`, `s905x`, `s905d`, `s912`, `s922x`. When prompted `Please enter the SOC type of your device, such as s905x3:`, Please enter the SOC model of the current device.

- Support updated [kernel version](https://github.com/ophub/amlogic-s9xxx-openwrt/tree/main/amlogic-s9xxx/amlogic-kernel). When prompted `Please enter the kernel version number, such as 5.13.2:`, Please enter the kernel version number.

```shell
bash <(curl -fsSL git.io/armbian-kernel)
```


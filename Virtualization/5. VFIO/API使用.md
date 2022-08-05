
Documentation/driver-api/vfio.rst

假设想要使用设备 `0000:06:0d.0`

```
$ readlink /sys/bus/pci/devices/0000:06:0d.0/iommu_group
../../../../kernel/iommu_groups/26
```


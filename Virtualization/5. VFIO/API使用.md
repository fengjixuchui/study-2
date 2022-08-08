
Documentation/driver-api/vfio.rst

假设想要使用设备 `0000:06:0d.0`

```
$ readlink /sys/bus/pci/devices/0000:06:0d.0/iommu_group
../../../../kernel/iommu_groups/26
```

该设备在 iommu group 26 中. 这个设备在 pci bus, 所以可以使用 vfio-pci 管理这个 group

```
modprobe vfio-pci
```



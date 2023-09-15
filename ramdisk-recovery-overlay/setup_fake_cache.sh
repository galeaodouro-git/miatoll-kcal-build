#!/system/bin/sh

if grep -qs '/data ' /proc/mounts; then
    echo "userdata already mounted" > /dev/kmsg
else
    # Timeout after 10s
    for i in $(seq 1 10); do
        mount -t ext4 /dev/block/bootdevice/by-name/userdata /data 2> /dev/kmsg && break
        mount -t f2fs /dev/block/bootdevice/by-name/userdata /data 2> /dev/kmsg && break
        sleep 1
    done
fi

mkdir -p /data/cache > /dev/kmsg
mount -o bind /data/cache /cache > /dev/kmsg

setprop halium.datamount.done 1

exit 0

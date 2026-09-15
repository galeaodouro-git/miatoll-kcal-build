#!/bin/sh -ex

# Replicate partially argument parsing, so that we end up with the same $OUT as
# the main script.
OUT=out
while [ $# -gt 0 ]
do
    case "$1" in
    (-o) OUT="$2"; shift;;
    (-*) ;;
    (*) OUT="$2"; break;;
    esac
    shift
done
OUT="$(realpath "$OUT")"

HERE=$(pwd)
. "${HERE}/deviceinfo"

tmp=$(mktemp -d)
recovery_file=${tmp}/partitions/recovery.img
# system-image-upgrader will not cleanup files it does not know after it
# extracts device tarball's content to /cache. That means files outside of
# system/, data/ and partitions/ will be left in /cache.
recovery_out=${tmp}/device-tarball-patch/recovery-update
# However, keep size and hash inside rootfs, to prevent the flashing code from
# becoming arbitrary recovery updater.
# XXX: this means we ship files outside overlaystore. But meh.
recovery_metadata_out=${tmp}/device-tarball-patch/system/opt/recovery-update

# Remove usrmerge variant, as it's simply a hard link to the non-usrmerge one.
rm -f "${OUT}/device_${deviceinfo_codename}_usrmerge.tar.xz"

# Because compressed tarball can't be updated, uncompress first.
unxz "${OUT}/device_${deviceinfo_codename}.tar.xz"
tar -C "$tmp" -xvf "${OUT}/device_${deviceinfo_codename}.tar" partitions/recovery.img

mkdir -p "$recovery_out" "$recovery_metadata_out"
cp "$recovery_file" "${recovery_out}/recovery.img"
wc -c <"$recovery_file" >"${recovery_metadata_out}/recovery.img_size"
sha256sum "$recovery_file" | cut -d' ' -f1 \
    > "${recovery_metadata_out}/recovery.img_sha256sum"

# We update the tarball instead of extract+re-create. This way, we don't have
# to worry too much about file permissions.
tar -C "${tmp}/device-tarball-patch" -uvf "${OUT}/device_${deviceinfo_codename}.tar" \
    --owner=root --group=root \
    system/ recovery-update/
xz "${OUT}/device_${deviceinfo_codename}.tar"

# Restore (hard) link for usrmerge variant.
ln -f "${OUT}/device_${deviceinfo_codename}.tar.xz" "${OUT}/device_${deviceinfo_codename}_usrmerge.tar.xz"

rm -rf "$tmp"

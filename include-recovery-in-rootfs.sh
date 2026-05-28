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

tmp=$(mktemp -d)
recovery_file=${tmp}/partitions/recovery.img
# XXX: this means we ship files outside overlaystore. But meh.
recovery_out=${tmp}/recovery-update/system/opt/recovery-update

# Remove usrmerge variant, as it's simply a hard link to the non-usrmerge one.
rm -f "${OUT}/device_miatoll_usrmerge.tar.xz"

# Because compressed tarball can't be updated, uncompress first.
unxz "${OUT}/device_miatoll.tar.xz"
tar -C "$tmp" -xvf "${OUT}/device_miatoll.tar" partitions/recovery.img

mkdir -p "$recovery_out"
xz -9 --stdout "$recovery_file" >"${recovery_out}/recovery.img.xz"
wc -c <"$recovery_file" >"${recovery_out}/recovery.img_size"
sha256sum "$recovery_file" | cut -d' ' -f1 \
    > "${recovery_out}/recovery.img_sha256sum"

# We update the tarball instead of extract+re-create. This way, we don't have
# to worry too much about file permissions.
tar -C "${tmp}/recovery-update" -uvf "${OUT}/device_miatoll.tar" \
    --owner=root --group=root \
    system/
xz "${OUT}/device_miatoll.tar"

# Restore (hard) link for usrmerge variant.
ln -f "${OUT}/device_miatoll.tar.xz" "${OUT}/device_miatoll_usrmerge.tar.xz"

rm -rf "$tmp"

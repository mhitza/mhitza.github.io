In the absence of full disk encryption, KDE Vaults offer a satisfactory compromise to keep
personal files safe in case of device theft.

Vaults can work with three different encryption backends:

 - eCryptFS - [inactive and marked as orphaned in the Linux kernel][orphaned]
 - EncFS - [explicitly unmaintaned as of the 26th of May 2024][unmaintained]
 - gocryptfs

While I've used EncFS in the past, given it's no longer maintained status, I've went with
GoCryptFS. The only choice really, until the day I can figure out how to make sddm, and
systemd-homed work nicely with each other on the Deck.

All these system work by storing your files encrypted, and giving you an unencrypted view
by mounting an overlay FUSE ([Filesystem in Userspace][fuse_wiki]) directory.

> Sidenote: [gocryptfs went through a security audit back in 2017][audit]. While there
> are some interesting exploit scenarios under circumstances of direct access to the
> encrypted + parts of unencrypted files, it does not apply for a scenario in which the
> device is stolen while Vaults are locked.

The upside of gocryptfs is that it's written in Go, which makes it easy to deploy on a
readonly filesystem such as the Steam Deck (as it's statically linked and doesn't depend on
dynamic system libraries).

To get things set up, I've installed the binaries in my `~/.local/bin/` directory and extended
the plasma session PATH environment to be aware of this new executable location path.

```shell
#
# https://github.com/rfjakob/gocryptfs/releases
#
version=v2.4.0
archive="gocryptfs_${version}_linux-static_amd64.tar.gz"

local_bin="$HOME/.local/bin"

mkdir -p "$local_bin"

mkdir /tmp/gocryptfs-download
pushd /tmp/gocryptfs-download

wget "https://github.com/rfjakob/gocryptfs/releases/download/$version/$archive"
tar xf "$archive"

mv gocryptfs gocryptfs-xray "$local_bin/"

#
# KDE will source all scripts in your $HOME/.config/plasma-workspace/env directory.
# Single quotes are important here to avoid variable interpolation.
#
echo 'export PATH="$HOME/.local/bin:$PATH"' > "$HOME/.config/plasma-workspace/env/local-bin.sh"

popd && rm -rf /tmp/gocryptfs-download

# Reboot / Re-login and start using Vaults.
```

[orphaned]: https://lore.kernel.org/lkml/20230403134432.46726-1-frank.li@vivo.com/T/
[unmaintained]: https://github.com/vgough/encfs/commit/aa106e6eddcc16ce7f763c63e5f20dd9eb7f0f52
[audit]: https://defuse.ca/audits/gocryptfs.htm
[fuse_wiki]: https://en.wikipedia.org/wiki/Filesystem_in_Userspace

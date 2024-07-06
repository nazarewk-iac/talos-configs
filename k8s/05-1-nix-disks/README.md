TODO: fix decrypting `pic-local-crypted`, it's not mapped inside `/dev/mapper` even though it works + cryptsetup status pic-local-crypted + cryptsetup open /dev/sdb pic-local-crypted --key-file /nix-disks/passphrases/5d43c8c0-ad3e-4165-bb1a-ea8a4fdadf45
No key available with this passphrase.

#!/bin/bash
apt-get install blobfuse
mkdir /mnt/resource/fusetmpincoming -p
mkdir /mnt/resource/fusetmpoutgoing -p
chown $USER /mnt/resource/fusetmpincoming
chown $USER /mnt/resource/fusetmpoutgoing
echo "accountName <<AzureStorageAccountName>>" >> ~/fuse_incoming.cfg
echo "accountKey <<Azure Storage Key>> >> ~/fuse_incoming.cfg
echo "containerName incoming" >> ~/fuse_incoming.cfg
echo "accountName <<AzureStorageAccountName>>" >> ~/fuse_outgoing.cfg
echo "accountKey <<Azure Storage Key>>" >> ~/fuse_outgoing.cfg
echo "containerName outgoing" >> ~/fuse_outgoing.cfg
chown $USER ~/fuse_incoming.cfg
chown $USER ~/fuse_outgoing.cfg
chmod 600 ~/fuse_incoming.cfg
chmod 600 ~/fuse_outgoing.cfg
mkdir ~/incoming
mkdir ~/outgoing
blobfuse ~/incoming --tmp-path=/mnt/resource/fusetmpincoming  --config-file=../fuse_incoming.cfg -o attr_timeout=240 -o entry_timeout=240 -o negative_timeout=120 -o allow_other
blobfuse ~/outgoing --tmp-path=/mnt/resource/fusetmpoutgoing  --config-file=../fuse_outgoing.cfg -o attr_timeout=240 -o entry_timeout=240 -o negative_timeout=120 -o allow_other

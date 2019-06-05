#!/bin/bash

#installs the blobfuse adapter for accessing Azure Blob Storage as a part of the file system
apt-get install blobfuse

#makes a temporary storage point in the Azure VM temp space for the fuse adapter for the incoming and outgoing containers
mkdir /mnt/resource/fusetmpincoming -p
mkdir /mnt/resource/fusetmpoutgoing -p

#sets ownership on the temp space
chown $USER /mnt/resource/fusetmpincoming
chown $USER /mnt/resource/fusetmpoutgoing

#writes the config files for the fuse blob adapter based on the storage account properties for the incoming container
echo "accountName <<AzureStorageAccountName>>" >> ~/fuse_incoming.cfg
echo "accountKey <<Azure Storage Key>> >> ~/fuse_incoming.cfg
echo "containerName incoming" >> ~/fuse_incoming.cfg

#writes the config files for the fuse blob adapter based on the storage account properties for the outgoing container
echo "accountName <<AzureStorageAccountName>>" >> ~/fuse_outgoing.cfg
echo "accountKey <<Azure Storage Key>>" >> ~/fuse_outgoing.cfg
echo "containerName outgoing" >> ~/fuse_outgoing.cfg

#sets permisions to prevent users from reading the storage access key
chown $USER ~/fuse_incoming.cfg
chown $USER ~/fuse_outgoing.cfg
chmod 600 ~/fuse_incoming.cfg
chmod 600 ~/fuse_outgoing.cfg

# creates the directories for the fuse mount points
mkdir ~/incoming
mkdir ~/outgoing

#mounts blob storage
blobfuse ~/incoming --tmp-path=/mnt/resource/fusetmpincoming  --config-file=../fuse_incoming.cfg -o attr_timeout=240 -o entry_timeout=240 -o negative_timeout=120 -o allow_other
blobfuse ~/outgoing --tmp-path=/mnt/resource/fusetmpoutgoing  --config-file=../fuse_outgoing.cfg -o attr_timeout=240 -o entry_timeout=240 -o negative_timeout=120 -o allow_other

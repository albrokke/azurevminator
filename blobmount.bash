#!/bin/bash
mountcontainer() 
{
    #makes a temporary storage point in the Azure VM temp space for the fuse adapter for the incoming and outgoing containers
    mkdir $1
    chown $USER $1

    #writes the config files for the fuse blob adapter based on the storage account properties for the incoming container
    echo "accountName $AZSTORAGE" >> $2
    echo "accountKey $AZACCOUNTKEY" >> $2
    echo "containerName $3" >> $2

    #sets permissions to prevent users from reading the storage access key
    chown $USER $2
    chmod 600 $2

    # creates the directories for the fuse mount points
    mkdir "$FUSEDIR/$3"

    #mounts blob storage
    blobfuse "$FUSEDIR/$3" --tmp-path=$1  --config-file=$2 -o attr_timeout=240 -o entry_timeout=240 -o negative_timeout=120 -o allow_other

}

source blobmount.config
#installs the blobfuse adapter for accessing Azure Blob Storage as a part of the file system
apt-get install blobfuse

#makes a base directory for all fuse mount points
mkdir $FUSEDIR

#mounts the containers within the Azure storage as mount points in the file system
mountcontainer ($INBOXTEMP,$INBOXCONFIG,$INBOXCONTAINER)
mountcontainer ($OUTBOXTEMP,$OUTBOXCONFIG,$OUTBOXCONTAINER)
mountcontainer ($SOURCETEMP,$SOURCECONFIG,$SOURCECONTAINER)






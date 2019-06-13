#!/bin/bash
function menu {
   clear
   echo "**********************************************************"
   echo "*                                                        *"
   echo "*                Data Science VMinator v1.0              *"
   echo "*                                                        *"
   echo "**********************************************************"
   echo
	
   echo
   echo "  Enter a to authenticate to Azure"
   echo "  Enter l to list your team's VMs"
   echo "  Enter d to deploy a new VM"
   echo "  Enter r to remove an existing VM"
   echo "  Enter c to connect a VM"
   echo "  Enter e to exit"
   read ACTION
   case $ACTION in
        
       a)
          auth
          menu
       ;;
       l)
               echo 
	       echo "    Here are Your team's deployed VMs:"
	       echo
	       az vm list -g walledgarden -o table
               echo "    Press [Enter] to continue"
	       read CONTINUE
	       menu
	;;       
       d)
	     deploy
        ;;
       r)
             remove
        ;;
       c)
 	     connect
        ;;
       e)
	     exit
        ;;
   esac
}

function auth {
    az login
}

function deploy {
 #   VMNAME="$USER$(date +%s)"
 #   RGNAME='walledgarden'
 #   LOCATION='northcentralus'  # e.g. westus2
 #   PUB='microsoft-ads'
 #   OFFER='linux-data-science-vm-ubuntu'
 #   SKU='linuxdsvmubuntu'
 #   VERSION='latest'
 #   VNET='walledgarden'
 #   SUBNET='resources'
  
    echo
    echo "   Enter the number of the virtual machine size you would like to deploy "
    echo "     ________________________________________________________________"
    echo "    |Choice	|Size	|CPU	|GPU	|RAM	|Estimated Monthly Cost|"
    echo "    |1		|D2V3 	| 2	|0	|  8GB	|~$  120.00"
    echo "    |2		|DS3V2  | 4 	|0	| 14GB	|~$  220.00"
    echo "    |3		|DS4V2	| 8 	|0	| 28GB	|~$  800.00"    
    echo "    |4		|NC6   	| 6	|1	| 56GB	|~$  800.00"
    echo "    |5		|NC12   |12	|2	|112GB	|~$ 1600.00"
    echo ""
    read CONFIG
    case $CONFIG in
        1)
                 SIZE='Standard_D2_v3'
             ;;
        2)
                 SIZE='Standard_DS3_v2'
             ;;
        3)
                 SIZE='Standard_DS4_v2'
             ;;
	4)
	         SIZE='Standard_NC6'
	     ;;
	5)
	         SIZE='Standard_NC12'
	     ;;
  esac
  
  echo 
  echo "    Creating Azure VM deployment.  This can take up to 5 minutes, please wait..."
  echo
declare -i CURRENTTIME
CURRENTTIME=$(date +%s)

EXPIRE=`expr $CURRENTTIME+$TTL` 

  az vm create \
    --name $VMNAME --resource-group $RGNAME --image $PUB\:$OFFER\:$SKU\:$VERSION \
    --plan-name $SKU --plan-product $OFFER --plan-publisher $PUB \
    --admin-username $USER \
    --generate-ssh-keys \
    --vnet-name $VNET \
    --size $SIZE \
    --subnet $SUBNET \
    --public-ip-address "" \
    --tags owner=$USER expire=$EXPIRE \
    --output table 

  echo "    Encrypting the VM.  This can take up to 5 minutes "
  az vm encryption enable --resource-group $RGNAME --name $VMNAME --disk-encryption-keyvault $RGNAME --volume-type All
  
  az vm extension set \
    --publisher Microsoft.Azure.ActiveDirectory.LinuxSSH \
    --name AADLoginForLinux \
    --resource-group $RGNAME \
    --vm-name $VMNAME

sleep 10

    echo " Adding AAD Login as an Administrator "
azusername=$(az account show --query user.name --output tsv)
azvm=$(az vm show --resource-group $RGNAME --name $VMNAME --query id -o tsv)

az role assignment create \
    --role "Virtual Machine Administrator Login" \
    --assignee $azusername \
    --scope $azvm

sleep 10

  echo "     Verifying successful encryption "
  az vm encryption show -g $RGNAME -n $VMNAME -o table
  sleep 20
  menu
}

function remove {
    declare -a DVMS
    declare -a RESOURCES
    declare -i dcounter
    declare -i DELETEVM
    delimiter="\""
    dcounter=0
    counter=0
    DVMS=($(az vm list --resource-group $RGNAME --query "[].{name:name}" -o table | tr '\n' ' ')) 
    for DVM in "${DVMS[@]}"i
        do
            echo "$dcounter : $DVM"
            dcounter=`expr $dcounter + 1`
        done
    echo
    echo "    Enter the number of the VM you would like to delete" 
    echo
    read DNUM
    echo 
    echo "    Submitting VM deletion to Azure this can take up to 5 minutes."
    echo "az vm delete --resource-group $RGNAME --name ${DVMS[$DNUM]} --yes"
    az vm delete --resource-group $RGNAME --name ${DVMS[$DNUM]} --yes
    RESOURCES=($(az resource list -g walledgarden --query "[].{Name:name,Type:type}" -o table))
    for RESOURCE in "${RESOURCES[@]}"
        do
	    counter=`expr $counter + 1`
	    if [[ $RESOURCE == *${DVMS[$DNUM]}* ]]; then
	      az resource delete -g $RGNAME -n $RESOURCE --resource-type ${RESOURCES[counter]}
	    fi
	done

    sleep 20
    menu
}

function connect {
    declare -a VMS
    declare -i counter
    declare -i ACCESS
    delimiter="\""
    counter=0
    VMS=($(az vm list --resource-group $RGNAME --query "[].{name:name}" -o table | tr '\n' ' ' ))
    for VM in "${VMS[@]}"
        do
            echo "$counter : $VM"
            counter=`expr $counter + 1`
        done
    
    echo
    echo "    Enter the number of the VM you would like to connect to"
    echo
    
    read ACCESS
    az vm start -g $RGNAME -n ${VMS[$ACCESS]} -o table
    azusername=$(az account show --query user.name --output tsv)
    NIC="${VMS[$ACCESS]}VMNic"
    IPDATA="$(az vm nic show --resource-group $RGNAME --vm-name ${VMS[$ACCESS]} --nic $NIC | grep "privateIpAddress\":" | tr '\"privateIpAddress\":\"' ' ' | tr '\",' ' ')"
    ssh -l $azusername $IPDATA
    sleep 10
    menu
}

source vminator.config 
menu
exit


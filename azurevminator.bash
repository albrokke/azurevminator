#!/bin/bash
# The Azure VMinator is a set of BASH shell scripts that leverage the AZURE CLI to help simplify Azure deployment for VMs.
# The code is deisgned to be run from a jump server in a protected vNet as described in the visio in the repository

function menu {
#menu display
clear
   echo "**********************************************************"
   echo "*                                                        *"
   echo "*                Azure VMinator v1.0              *"
   echo "*                                                        *"
   echo "**********************************************************"
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
       ;;
       l)
               echo
               echo "    Here are Your team's deployed VMs:"
               echo

               #retrieves the list of VMs from your resource group using the Azure CLI
               az vm list -g <<your resource group>> -o table
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
    #Generates the VM name based on the logged on user's name and the epoch time representation of the time to ensure uniqueness
    VMNAME="$USER$(date +%s)"
    
    #enter the resource group all of these resources will be deployed to
    RGNAME=<<your resource group>>
    
    #Azure location to deploy code
    LOCATION='northcentralus'  # e.g. westus2
    
    #The following items are based on the Ubuntu Data Science VM.  If you wanted a different offering you have to look those variables up
    PUB='microsoft-ads'
    OFFER='linux-data-science-vm-ubuntu'
    SKU='linuxdsvmubuntu'
    VERSION='latest'
    #The name of the VNET you want to deploy to
    VNET=<<Your VNET>>
    #Based on the topology in the visio this is the protected VNET for deploying the Data Science VMs
    SUBNET=<<Protected Subnet>>
    echo
 
    #Customize this as you see fit.  The numbers and sizes here were based on availability in North Central US at the time of the
    # code being written and based on recommended sizes for Data Science VMs.
    echo "   Enter the number of the virtual machine size you would like to deploy "
    echo "     ________________________________________________________________"
    echo "    |Choice   |Size   |CPU    |GPU    |RAM    |Estimated Monthly Cost|"
    echo "    |1                |DS2V2  | 2     |0      |  7GB  |$  108.62"
    echo "    |2                |DS3V2  | 4     |0      | 14GB  |$  217.00"
    echo "    |3                |DS4V2  | 8     |0      | 28GB  |$  8##.##"
    echo "    |4                |NC6    | 6     |1      | 56GB  |$  791.32"
    echo "    |5                |NC12   |12     |2      |112GB  |$ 1582.64"
    echo ""
    read CONFIG
    
    #The following Case Statement provides variable values based on the sizes being requested. If you change the table 
    # above you'll have to change the SIZE in the case statemen
    case $CONFIG in
        1)
                 SIZE='Standard_DS2_v2'
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
  
  # Leverages all of the values above to define Azure VM for deployment
  az vm create \
    --name $VMNAME --resource-group $RGNAME --image $PUB\:$OFFER\:$SKU\:$VERSION \
    --plan-name $SKU --plan-product $OFFER --plan-publisher $PUB \
    --admin-username $USER \
    --generate-ssh-keys \
    --vnet-name $VNET \
    --subnet $SUBNET \
    --public-ip-address ""

  echo
  
  #This is just here to see the output before the screen clears
  sleep 5
  menu
}

function remove {
#Enter the REsource Group you want to use
    RGNAME=<<Your Resource Group>>
    declare -a DVMS
    declare -a RESOURCES
    declare -i dcounter
    declare -i DELETEVM
    delimiter="\""
    dcounter=0
    counter=0
  
    #Retrieves the list of VMs in a format to be able to create a choice list for the user
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
    
    #Deletes the VM resource from Azure
    az vm delete --resource-group $RGNAME --name ${DVMS[$DNUM]} --yes
    
    #Finds all of the resources that were associated with the VM Resources
    RESOURCES=($(az resource list -g walledgarden --query "[].{Name:name,Type:type}" -o table))
    
    #Iteratively deletes all of the resources that were associated with the VM resource
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
    RGNAME="walledgarden"
    declare -a VMS
    declare -i counter
    declare -i ACCESS
    delimiter="\""
    counter=0
    
    #Retrieves VMs in the resource group
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
    
    #Reads the network adapter configuration to find the IP Address to connect to
    NIC="${VMS[$ACCESS]}VMNic"
    IPDATA="$(az vm nic show --resource-group $RGNAME --vm-name ${VMS[$ACCESS]} --nic $NIC | grep "privateIpAddress\":" | tr '\"privateIpAddress\":\"' ' ' | tr '\",' ' ')"
    
    #Connects to the VM via SSH
    ssh $IPDATA
    menu
}

menu
exit

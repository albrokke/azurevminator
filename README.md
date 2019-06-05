# azurevminator
Companies all over the world are looking for ways to provide their data scientists with the latest technology in a cost effective and compliant manner.  This can be challenging when the Data Scientist is initially just trying to test a hypothesis to see if their code will work as they expect or if the model is speculative in nature.  They also may not have access to hardware at scale to test a model to justify the investment in hardware to scale it.  While Data Scientsts can learn new technologies, becoming an expert in a cloud platform like Azure to address these needs isn't their top priority.  Finally, issues of data protection are also top of mind when dealing with the types of data a data scientist might need to use while validating amodel.

To address these challenges the AzureVMinator was created to help organiations easily and securely deploy Data Science VMs dynamically for adhoc needs.  The AzureVMinator provides a simple test based interface to deploy VMs dynamically to a protected network within Azure that are accessed via a jump box.  The tool will allow data scientists to
1. Authenitcate to Azure
2. Connect the local file system to Azure Blob Storage using the FUSE adapter
3. List the VMs currently deployed in Azure
4. Deploy new Data Science VMs based on a pre-determined list of sizes
5. Connect to the Azure VMs from a list provided via SSH fromt he Jump box
6. Delete an Azure VM that was deployed by the same user

Note that for customization purposes and security from the initial implementation there are a number of places in the shell script where you will need to replace <<variable name>> with your own Azure resource names.

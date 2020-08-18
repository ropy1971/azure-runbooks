##### INIT #####
function Init {

    Set-Item Env:\SuppressAzurePowerShellBreakingChangeWarnings "true"
    $WarningAction = 'SilentlyContinue'
    
    $Auth = Get-AutomationConnection -Name 'AzureRunAsConnection'
    Connect-AzAccount -ServicePrincipal -Tenant $Auth.TenantID -ApplicationId $Auth.ApplicationID -CertificateThumbprint $Auth.CertificateThumbprint | Out-Null

    $TenantId = $Auth.TenantID
    $SubscriptionId = "8a36eb8a-ed7f-4a94-aa46-aee539418553"
    $ResourceGroupName = "CentralPointRG"
    $StorageAccountName = "centralpointsa2803"

    $RegionArray = @("australiacentral","australiaeast","australiasoutheast",
    "brazilsouth",
    "canadacentral","canadaeast",
    "centralindia","southindia","westindia",
    "centralus","eastus","eastus2","northcentralus","southcentralus","westus","westus2",
    "eastasia","southeastasia",
    "francecentral",
    "japaneast","japanwest",
    "koreacentral","koreasouth",
    "northeurope","westeurope",
    "ukwest","uksouth")
    $Publisher = "Canonical"
    $Offer = "UbuntuServer"
    $SkuArray = @("16.04-LTS","16.04-DAILY-LTS","16.04-DAILY-LTS","18.04-DAILY-LTS","18.04-LTS","18.10","18.10-DAILY","19.04-DAILY","19.10-DAILY")

    Set-AzContext -SubscriptionId $SubscriptionId | Out-Null
    Write-Output "[info] Azure Context has been set. "
    
    CheckResources
}

function CheckResources {
    $ResourceGroup = Get-AzResourceGroup -Name $ResourceGroupName -ErrorAction SilentlyContinue
    if ($ResourceGroup) {
        Write-Output "[info] Resource Group $ResourceGroupName has been found. "
        $StorageAccount = Get-AzStorageAccount -ResourceGroup $ResourceGroupName -Name $StorageAccountName -ErrorAction SilentlyContinue
        if ($StorageAccount) {
            Write-Output "[info] Storage account $StorageAccountName has been found. "
            $StorageAccountKey1 = (Get-AzStorageAccountKey -ResourceGroupName $ResourceGroupName -AccountName $StorageAccountName)| Where-Object {$_.KeyName -eq "key1"} -ErrorAction SilentlyContinue
            if ($StorageAccountKey1) {
                Write-Output "[info] Storage account key has been found. "
                $StorageAccountKey = $StorageAccountKey1.Value
                if ($StorageAccountKey) {
                    Write-Output "[info] Storage account key has been set. "
                    $StorageContext = New-AzStorageContext -StorageAccountName $StorageAccountName -StorageAccountKey $StorageAccountKey -ErrorAction SilentlyContinue
                    if ($StorageContext) {
                        Write-Output "[info] Storage context has been set. "
                        UpdatingImages
                    }
                    else {
                        Write-Output "[error] Storage context has not been set. "
                    }
                }
                else {
                    Write-Output "[error] Storage account key has not been set. "
                    Return
                }
            }
            else {
                Write-Output "[error] Storage account key has not been found. "
                Return
            }
        }
        else {
            Write-Output "[error] Storage Account $StorageAccountName has not been found. "
            Return
        }
    }
    else {
        Write-Output "[error] Resource Group has not been found. "
        Return
    }
}

function UpdatingImages {
    foreach ($Region in $RegionArray) {
        Write-Output "[info] region $Region in progress... "
        $StorageContainerName = $Region
        $StorageContainer = Get-AzStorageContainer -Name $StorageContainerName -Context $StorageContext -ErrorAction SilentlyContinue
        if ($StorageContainer) {
            Write-Output "[info] Storage container $StorageContainerName has been found. "
            GetImages
        }
        else {
            Write-Output "[error] Storage container $StorageContainerName has not been set. "
            New-AzStorageContainer -Name $StorageContainerName -Context $StorageContext -Permission Off | Out-Null
            Write-Output "[info] Storage container $StorageContainerName has been created. "
            GetImages
        }
    }
}

function GetImages {
    $File = "vm-images-offers-" + $Publisher + ".txt"
    Write-Output "[info] Output file name $File has been set. "
    Get-AzVMImageOffer -Location $Region -Publisher $Publisher | Select-Object Offer | Out-File $File 
    Write-Output "[info] Offers have been found for $Publisher in $Region "
    Set-AzStorageBlobContent -File $File -Container $StorageContainerName -BlobType "Block" -Context $StorageContext -Verbose -Force -ErrorAction SilentlyContinue
    Write-Output "[info] File $File has been saved. " 
    GetSkus   
}

function GetSkus {
    $File = "vm-images-skus-" + $Publisher + "-" + $Offer + ".txt"
    Write-Output "[info] Output file name $File has been set. "
    Get-AzVMImageSku -Location $Region -Publisher $Publisher -Offer $Offer | Select-Object Skus | Sort-Object Skus | Out-File $File
    Write-Output "[info] Skus have been found for $Publisher in $Region "
    Set-AzStorageBlobContent -File $File -Container $StorageContainerName -BlobType "Block" -Context $StorageContext -Verbose -Force -ErrorAction SilentlyContinue
    Write-Output "[info] File $File has been saved. "
    #GetVersions
}

function GetVersions {
    foreach ($Sku in $SkuArray) {
        $File = "vm-images-versions-" + $Publisher + "-" + $Offer + "-" + $Sku +".txt" 
        Write-Output "[info] Output file name $File has been set. "    
        Get-AzVMImage -Location $Region -Publisher $Publisher -Offer $Offer -Sku $Sku | Select-Object Version | Sort-Object Version | Out-File $File
        Write-Output "[info] Versions have been found for $Publisher in $Region "
        Set-AzureStorageBlobContent -File $File -Container $StorageContainerName -BlobType "Block" -Context $StorageContext -Verbose -Force 
        Write-Output "[info] File $File has been saved. "
    }
}

##### INIT #####
Init

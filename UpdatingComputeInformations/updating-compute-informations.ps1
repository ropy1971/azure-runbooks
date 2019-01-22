function Get-TimeStamp {
    return "[{0:dd/MM/yy} {0:HH:mm:ss}]" -f (Get-Date)
}

$CurrentDate = Get-Date -Format "yyyy-MM-dd"
$LogFileName = "informations-" + $CurrentDate + ".log"

$Auth = Get-AutomationConnection -Name 'AzureRunAsConnection'
$Subscription = "<ReplaceWithYourSubscriptionId>"
$RegionArray = @("australiacentral",
                "australiacentral2",
                "australiaeast",
                "australiasoutheast",
                "brazilsouth",
                "canadacentral",
                "canadaeast",
                "centralindia",
                "centralus",
                "eastasia",
                "eastus",
                "eastus2",
                "francecentral",
                "francesouth",
                "japaneast",
                "japanwest",
                "koreacentral",
                "koreasouth",
                "northcentralus",
                "northeurope",
                "southcentralus",
                "southeastasia",
                "southindia",
                "uksouth",
                "ukwest",
                "westcentralus",
                "westeurope",
                "westindia",
                "westus",
                "westus2")

Connect-AzureRmAccount -ServicePrincipal -Tenant $Auth.TenantID -ApplicationId $Auth.ApplicationID -CertificateThumbprint $Auth.CertificateThumbprint 

Set-AzureRmContext -SubscriptionId $Subscription

Write-Output "$(Get-TimeStamp) --- start script ---" | Out-file $LogFileName -Append
Write-Output "$(Get-TimeStamp) " | Out-file $LogFileName -Append

$ResourceGroupName = "<ReplaceWithYourRGName>"
Write-Output "$(Get-TimeStamp) resource Group: $ResourceGroupName " | Out-file $LogFileName -append
$StorageAccountName = "<ReplaceWithYourSAName>"
Write-Output "$(Get-TimeStamp) storage Account: $StorageAccountName " | Out-file $LogFileName -append
$StorageAccountKey1 = (Get-AzureRmStorageAccountKey -Name $StorageAccountName -ResourceGroupName $ResourceGroupName).Value[0]
Write-Output "$(Get-TimeStamp) storage account key " | Out-file $LogFileName -append
$StorageContext = New-AzureStorageContext -StorageAccountName $StorageAccountName -StorageAccountKey $StorageAccountKey1
Write-Output "$(Get-TimeStamp) storage context " | Out-file $LogFileName -append
$StorageContainerLogs = "<ReplaceWithYourSCNameForLogs>" 
$StorageContainer = "<ReplaceWithYourSCNameForInformations>"
Write-Output "$(Get-TimeStamp) storage container for logs: $StorageContainerLogs " | Out-file $LogFileName -append
Write-Output "$(Get-TimeStamp) storage container for info: $StorageContainer " | Out-file $LogFileName -append
Write-Output "$(Get-TimeStamp) " | Out-file $LogFileName -Append

$File = "regions.txt"
Get-AzureRmLocation | Select-Object -Property Location,DisplayName | Sort-Object Location | Out-File $File 
Write-Output "$(Get-TimeStamp) CmdLet /Get-AzureRmLocation/ (Location) has been executed. " | Out-file $LogFileName -append
Set-AzureStorageBlobContent -File $File -Container $StorageContainer -BlobType "Block" -Context $StorageContext -Verbose -Force 
Write-Output "$(Get-TimeStamp) Check /$File/ file for more informations. " | Out-file $LogFileName -Append
Write-Output "$(Get-TimeStamp) " | Out-file $LogFileName -Append

foreach ($Region in $RegionArray) 
{
    $StorageContainer = $Region 

    if (!(Get-AzureStorageContainer -Context $StorageContext | Where-Object { $_.Name -eq $StorageContainer }))
    {
        Write-Output "$(Get-TimeStamp) container $StorageContainer doesn't exist." | Out-file $LogFileName -Append
        New-AzureStorageContainer -Context $StorageContext -Name $StorageContainer
        Write-Output "$(Get-TimeStamp) container $StorageContainer has been created. " | Out-file $LogFileName -Append
    }

    $File = "providers.txt"
    Get-AzureRmLocation | Select-Object -Property Providers | Sort-Object Providers | Out-File $File 
    Write-Output "$(Get-TimeStamp) $Region | CmdLet /Get-AzureRmLocation/ (Providers) has been executed. " | Out-file $LogFileName -append
    Set-AzureStorageBlobContent -File $File -Container $StorageContainer -BlobType "Block" -Context $StorageContext -Verbose -Force 
    Write-Output "$(Get-TimeStamp) $Region | Check /$File/ file for more informations. " | Out-file $LogFileName -Append

    $File = "vm-sizes.txt"
    Get-AzureRmVMSize -Location $Region | Select-Object -Property Name,NumberOfCores,MemoryInMB | Sort-Object Name | Out-File $File
    Write-Output "$(Get-TimeStamp) $Region | CmdLet /Get-AzureRmVMSize/ has been executed. " | Out-file $LogFileName -append
    Set-AzureStorageBlobContent -File $File -Container $StorageContainer -BlobType "Block" -Context $StorageContext -Verbose -Force 
    Write-Output "$(Get-TimeStamp) $Region | Check /$File/ file for more informations. " | Out-file $LogFileName -Append

    $File = "vm-images-publishers.txt"
    Get-AzureRmVMImagePublisher -Location $Region | Select-Object PublisherName | Sort-Object PublisherName | Out-File $File 
    Write-Output "$(Get-TimeStamp) $Region | CmdLet /Get-AzureRmVMImagePublisher/ has been executed. " | Out-file $LogFileName -append
    Set-AzureStorageBlobContent -File $File -Container $StorageContainer -BlobType "Block" -Context $StorageContext -Verbose -Force 
    Write-Output "$(Get-TimeStamp) $Region | Check /$File/ file for more informations. " | Out-file $LogFileName -append
}

Write-Output "$(Get-TimeStamp) " | Out-file $LogFileName -Append
$LogSize = Get-Childitem -File $LogFileName | Select-Object length
Write-Output "$(Get-TimeStamp) log size: $LogSize " | Out-file $LogFileName -Append
Write-Output "$(Get-TimeStamp) " | Out-file $LogFileName -Append
Write-Output "$(Get-TimeStamp) --- end script ---" | Out-file $LogFileName -Append
Set-AzureStorageBlobContent -File $LogFileName -Container $StorageContainerLogs -BlobType "Block" -Context $StorageContext -Verbose -Force 

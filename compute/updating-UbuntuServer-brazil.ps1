function Get-TimeStamp {
    return "[{0:dd/MM/yy} {0:HH:mm:ss}]" -f (Get-Date)
}

$Auth = Get-AutomationConnection -Name "AzureRunAsConnection"
$Subscription = "<ReplaceWithYourSubscriptionID>"
Connect-AzureRmAccount -ServicePrincipal -Tenant $Auth.TenantID -ApplicationId $Auth.ApplicationID -CertificateThumbprint $Auth.CertificateThumbprint 

Set-AzureRmContext -SubscriptionId $Subscription

Write-Output "$(Get-TimeStamp) --- start script ---" | Out-file UbuntuServer-log.txt -Append
Write-Output "$(Get-TimeStamp) " | Out-file UbuntuServer-log.txt -Append

$RegionArray = @("brazilsouth")
$Publisher = "Canonical"
$Offer = "UbuntuServer"
$ServerSkuArray = @("16.04-LTS","16.04-DAILY-LTS","16.04-DAILY-LTS","18.04-DAILY-LTS","18.04-LTS","18.10","18.10-DAILY","19.04-DAILY")

$ResourceGroupName = "shared-resources-rg"
Write-Output "$(Get-TimeStamp) resource Group: $ResourceGroupName " | Out-file UbuntuServer-log.txt -append
$StorageAccountName = "azureinfo"
Write-Output "$(Get-TimeStamp) storage Account: $StorageAccountName " | Out-file UbuntuServer-log.txt -append
$StorageAccountKey1 = (Get-AzureRmStorageAccountKey -Name $StorageAccountName -ResourceGroupName $ResourceGroupName).Value[0]
$StorageContext = New-AzureStorageContext -StorageAccountName $StorageAccountName -StorageAccountKey $StorageAccountKey1

foreach ($Region in $RegionArray) 
{
    Write-Output "$(Get-TimeStamp) region: $Region " | Out-file UbuntuServer-log.txt -append
    $StorageContainer = $Region
    Write-Output "$(Get-TimeStamp) storage container: $StorageContainer " | Out-file UbuntuServer-log.txt -Append

    if (!(Get-AzureStorageContainer -Context $StorageContext | Where-Object { $_.Name -eq $StorageContainer }))
    {
        Write-Output "$(Get-TimeStamp) container $StorageContainer doesn't exist." | Out-file UbuntuServer-log.txt -Append
        New-AzureStorageContainer -Context $StorageContext -Name $StorageContainer
        Write-Output "$(Get-TimeStamp) container $StorageContainer has been created. " | Out-file UbuntuServer-log.txt -Append
        Write-Output "$(Get-TimeStamp) " | Out-file UbuntuServer-log.txt -Append
    }
    else 
    {
        Write-Output "$(Get-TimeStamp) container $StorageContainer exists." | Out-file UbuntuServer-log.txt -Append
        Write-Output "$(Get-TimeStamp) " | Out-file UbuntuServer-log.txt -Append 
    }

    Write-Output "$(Get-TimeStamp) updating offers for $Publisher " | Out-file UbuntuServer-log.txt -Append
    $File = "vm-images-offers-" + $Publisher + ".txt"
    Get-AzureRmVMImageOffer -Location $Region -Publisher $Publisher | Select-Object Offer | Out-File $File 
    Write-Output "$(Get-TimeStamp) CmdLet /Get-AzureRmVmImage/ has been executed. " | Out-file UbuntuServer-log.txt -Append
    Set-AzureStorageBlobContent -File $File -Container $StorageContainer -BlobType "Block" -Context $StorageContext -Verbose -Force 
    Write-Output "$(Get-TimeStamp) file $File has been created. " | Out-file UbuntuServer-log.txt -Append
    $FileSize = Get-Childitem -File $File | Select-Object length
    Write-Output "$(Get-TimeStamp) file size: $FileSize " | Out-file UbuntuServer-log.txt -Append
    Write-Output "$(Get-TimeStamp) " | Out-file UbuntuServer-log.txt -Append 

    Write-Output "$(Get-TimeStamp) updating skus for $Offer " | Out-file UbuntuServer-log.txt -Append
    $File = "vm-images-sku-" + $Offer + ".txt"
    Get-AzureRmVMImageSku -Location $Region -Publisher $Publisher -Offer $Offer | Select-Object Skus | Sort-Object Skus | Out-File $File
    Write-Output "$(Get-TimeStamp) CmdLet /Get-AzureRmVMImageSku/ has been executed. " | Out-file UbuntuServer-log.txt -Append
    Set-AzureStorageBlobContent -File $File -Container $StorageContainer -BlobType "Block" -Context $StorageContext -Verbose -Force 
    Write-Output "$(Get-TimeStamp) file $File has been created. " | Out-file UbuntuServer-log.txt -Append
    $FileSize = Get-Childitem -File $File | Select-Object length
    Write-Output "$(Get-TimeStamp) file size: $FileSize " | Out-file UbuntuServer-log.txt -Append
    Write-Output "$(Get-TimeStamp) " | Out-file UbuntuServer-log.txt -Append 

    foreach ($Sku in $ServerSkuArray)
    {
        Write-Output "$(Get-TimeStamp) updating versions for $Offer $Sku " | Out-file UbuntuServer-log.txt -Append
        $File = "vm-images-version-" + $Offer + "-" + $Sku +".txt"     
        Get-AzureRmVMImage -Location $Region -Publisher $Publisher -Offer $Offer -Sku $Sku | Select-Object Version | Sort-Object Version | Out-File $File
        Write-Output "$(Get-TimeStamp) CmdLet /Get-AzureRmVMImage/ has been executed. " | Out-file UbuntuServer-log.txt -Append
        Set-AzureStorageBlobContent -File $File -Container $StorageContainer -BlobType "Block" -Context $StorageContext -Verbose -Force 
        Write-Output "$(Get-TimeStamp) file $File has been created. " | Out-file UbuntuServer-log.txt -Append
        $FileSize = Get-Childitem -File $File | Select-Object length
        Write-Output "$(Get-TimeStamp) file size: $FileSize " | Out-file UbuntuServer-log.txt -Append
        Write-Output "$(Get-TimeStamp) " | Out-file UbuntuServer-log.txt -Append
    }

$LogSize = Get-Childitem -File UbuntuServer-log.txt | Select-Object length
Write-Output "$(Get-TimeStamp) log size: $LogSize " | Out-file UbuntuServer-log.txt -Append
Write-Output "$(Get-TimeStamp) " | Out-file UbuntuServer-log.txt -Append
Write-Output "$(Get-TimeStamp) --- end script ---" | Out-file UbuntuServer-log.txt -Append
Set-AzureStorageBlobContent -File UbuntuServer-log.txt -Container $StorageContainer -BlobType "Block" -Context $StorageContext -Verbose -Force 

}

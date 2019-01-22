function Get-TimeStamp {
    return "[{0:dd/MM/yy} {0:HH:mm:ss}]" -f (Get-Date)
}

$Auth = Get-AutomationConnection -Name 'AzureRunAsConnection'
$Subscription = '<ReplaceWithYourSubscriptionID>'
Connect-AzureRmAccount -ServicePrincipal -Tenant $Auth.TenantID -ApplicationId $Auth.ApplicationID -CertificateThumbprint $Auth.CertificateThumbprint 

Set-AzureRmContext -SubscriptionId $Subscription

Write-Output "$(Get-TimeStamp) --- start script ---" | Out-file log-WindowsServer.txt -Append
Write-Output "$(Get-TimeStamp) " | Out-file log-WindowsServer.txt -Append

$RegionArray = @("centralus","eastus","eastus2","northcentralus","southcentralus","westus","westus2")
$Publisher = "MicrosoftWindowsServer"
$Offer = "WindowsServer"
$WindowsServerSkuArray = @("2008-R2-SP1","2012-Datacenter","2012-R2-Datacenter","2016-Datacenter","2016-Datacenter-Server-Core","2019-Datacenter","2019-Datacenter-Core")

$ResourceGroupName = 'shared-resources-rg'
Write-Output "$(Get-TimeStamp) resource Group: $ResourceGroupName " | Out-file log-WindowsServer.txt -append
$StorageAccountName = 'azureinfo'
Write-Output "$(Get-TimeStamp) storage Account: $StorageAccountName " | Out-file log-WindowsServer.txt -append
$StorageAccountKey1 = (Get-AzureRmStorageAccountKey -Name $StorageAccountName -ResourceGroupName $ResourceGroupName).Value[0]
$StorageContext = New-AzureStorageContext -StorageAccountName $StorageAccountName -StorageAccountKey $StorageAccountKey1

foreach ($Region in $RegionArray) 
{
    Write-Output "$(Get-TimeStamp) region: $Region " | Out-file log-WindowsServer.txt -append
    $StorageContainer = $Region
    Write-Output "$(Get-TimeStamp) storage container: $StorageContainer " | Out-file log-WindowsServer.txt -Append

    if (!(Get-AzureStorageContainer -Context $StorageContext | Where-Object { $_.Name -eq $StorageContainer }))
    {
        Write-Output "$(Get-TimeStamp) container $StorageContainer doesn't exist." | Out-file log-WindowsServer.txt -Append
        New-AzureStorageContainer -Context $StorageContext -Name $StorageContainer
        Write-Output "$(Get-TimeStamp) container $StorageContainer has been created. " | Out-file log-WindowsServer.txt -Append
        Write-Output "$(Get-TimeStamp) " | Out-file log-WindowsServer.txt -Append
    }
    else 
    {
        Write-Output "$(Get-TimeStamp) container $StorageContainer exists." | Out-file log-WindowsServer.txt -Append
        Write-Output "$(Get-TimeStamp) " | Out-file log-WindowsServer.txt -Append 
    }

    Write-Output "$(Get-TimeStamp) updating offers for $Publisher " | Out-file log-WindowsServer.txt -Append
    $File = 'vm-images-offers-' + $Publisher + '.txt'
    Get-AzureRmVMImageOffer -Location $Region -Publisher $Publisher  | Select-Object-Object Offer | Out-File $File 
    Write-Output "$(Get-TimeStamp) CmdLet /Get-AzureRmVmImage/ has been executed. " | Out-file log-WindowsServer.txt -Append
    Set-AzureStorageBlobContent -File $File -Container $StorageContainer -BlobType "Block" -Context $StorageContext -Verbose -Force 
    Write-Output "$(Get-TimeStamp) file $File has been created. " | Out-file log-WindowsServer.txt -Append
    $FileSize = Get-Childitem -File $File | Select-Object length
    Write-Output "$(Get-TimeStamp) file size: $FileSize " | Out-file log-WindowsServer.txt -Append
    Write-Output "$(Get-TimeStamp) " | Out-file log-WindowsServer.txt -Append 

    Write-Output "$(Get-TimeStamp) updating skus for $Offer " | Out-file log-WindowsServer.txt -Append
    $File = 'vm-images-sku-' + $Offer + '.txt'
    Get-AzureRmVMImageSku -Location $Region -Publisher $Publisher -Offer $Offer | Select-Object-Object Skus | Sort-Object Skus | Out-File $File
    Write-Output "$(Get-TimeStamp) CmdLet /Get-AzureRmVMImageSku/ has been executed. " | Out-file log-WindowsServer.txt -Append
    Set-AzureStorageBlobContent -File $File -Container $StorageContainer -BlobType "Block" -Context $StorageContext -Verbose -Force 
    Write-Output "$(Get-TimeStamp) file $File has been created. " | Out-file log-WindowsServer.txt -Append
    $FileSize = Get-Childitem -File $File | Select-Object length
    Write-Output "$(Get-TimeStamp) file size: $FileSize " | Out-file log-WindowsServer.txt -Append
    Write-Output "$(Get-TimeStamp) " | Out-file log-WindowsServer.txt -Append 

    foreach ($Sku in $WindowsServerSkuArray)
    {
        Write-Output "$(Get-TimeStamp) updating versions for $Publisher $Sku " | Out-file log-WindowsServer.txt -Append
        $File = 'vm-images-version-' + $Offer + '-' + $Sku +'.txt'     
        Get-AzureRmVMImage -Location $Region -Publisher $Publisher -Offer $Offer -Sku $Sku | Select-Object-Object Version | Sort-Object Version | Out-File $File
        Write-Output "$(Get-TimeStamp) CmdLet /Get-AzureRmVMImage/ has been executed. " | Out-file log-WindowsServer.txt -Append
        Set-AzureStorageBlobContent -File $File -Container $StorageContainer -BlobType "Block" -Context $StorageContext -Verbose -Force 
        Write-Output "$(Get-TimeStamp) file $File has been created. " | Out-file log-WindowsServer.txt -Append
        $FileSize = Get-Childitem -File $File | Select-Object length
        Write-Output "$(Get-TimeStamp) file size: $FileSize " | Out-file log-WindowsServer.txt -Append
        Write-Output "$(Get-TimeStamp) " | Out-file log-WindowsServer.txt -Append
    }

$LogSize = Get-Childitem -File log-WindowsServer.txt | Select-Object length
Write-Output "$(Get-TimeStamp) log size: $LogSize " | Out-file log-WindowsServer.txt -Append
Write-Output "$(Get-TimeStamp) " | Out-file log-WindowsServer.txt -Append
Write-Output "$(Get-TimeStamp) --- end script ---" | Out-file log-WindowsServer.txt -Append
Set-AzureStorageBlobContent -File log-WindowsServer.txt -Container $StorageContainer -BlobType "Block" -Context $StorageContext -Verbose -Force 

}

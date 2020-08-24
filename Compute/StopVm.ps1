function Get-TimeStamp {
    return "[{0:dd/MM/yy} {0:HH:mm:ss}]" -f (Get-Date)
}

$CurrentDate = Get-Date -Format "yyyy-MM-dd"
$LogFileName = "StopVM-" + $CurrentDate + ".log"

$Auth = Get-AutomationConnection -Name "AzureRunAsConnection"
$Subscription = "<ReplaceWithYourSubscriptionId>"
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
$StorageContainer = "<ReplaceWithYourSCName>" 
Write-Output "$(Get-TimeStamp) storage container: $StorageContainer " | Out-file $LogFileName -append
Write-Output "$(Get-TimeStamp) " | Out-file $LogFileName -Append

$VmName = "<ReplaceWithYourVMName>"
$Vm = Get-AzureRmVm -ResourceGroup $ResourceGroupName -Name $VmName -Status

if($Vm.Statuses.DisplayStatus -eq "VM Running")
{
    Write-Output "$(Get-TimeStamp) virtual machine /$VmName/ is running. " | Out-file $LogFileName -Append
    Stop-AzureRmVm -ResourceGroup $ResourceGroupName -Name $VmName -Force
    Write-Output "$(Get-TimeStamp) virtual machine /$VmName/ has been stopped. " | Out-file $LogFileName -Append
    Write-Output "$(Get-TimeStamp) " | Out-file $LogFileName -Append
}
else 
{
    Write-Output "$(Get-TimeStamp) virtual machine /$VmName/ is already stopped. " | Out-file $LogFileName -Append
    Write-Output "$(Get-TimeStamp) " | Out-file $LogFileName -Append
}

$LogSize = Get-Childitem -File $LogFileName | Select-Object length
Write-Output "$(Get-TimeStamp) log size: $LogSize " | Out-file $LogFileName -Append
Write-Output "$(Get-TimeStamp) " | Out-file $LogFileName -Append
Write-Output "$(Get-TimeStamp) --- end script ---" | Out-file $LogFileName -Append
Set-AzureStorageBlobContent -File $LogFileName -Container $StorageContainer -BlobType "Block" -Context $StorageContext -Verbose -Force 

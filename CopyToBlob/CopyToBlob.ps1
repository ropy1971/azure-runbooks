
$Auth = Get-AutomationConnection -Name 'AzureRunAsConnection'

Connect-AzureRmAccount -ServicePrincipal -Tenant $Auth.TenantID -ApplicationId $Auth.ApplicationID -CertificateThumbprint $Auth.CertificateThumbprint 

Set-AzureRmContext -SubscriptionId '<ReplaceWithYourSubscriptionID>'

$ResourceGroupName = 'shared-resources-rg'
$StorageAccountName = 'azureinfo'
$StorageAccountKey1 = (Get-AzureRmStorageAccountKey -Name $StorageAccountName -ResourceGroupName $ResourceGroupName).Value[0]
$StorageContext = New-AzureStorageContext -StorageAccountName $StorageAccountName -StorageAccountKey $StorageAccountKey1
$StorageContainer = 'vm-sizing'

$todaydate = Get-Date -Format MM-dd-yy 
$LogFull = "AzureScan-$todaydate.log" 
$LogItem = New-Item -ItemType File -Name $LogFull
 
"  Text to write" | Out-File -FilePath $LogFull -Append

Set-AzureStorageBlobContent -File $LogFull -Container $StorageContainer -BlobType "Block" -Context $StorageContext -Verbose

function Init {
    $Auth = Get-AutomationConnection -Name 'AzureRunAsConnection'
    Connect-AzAccount -ServicePrincipal -Tenant $Auth.TenantID -ApplicationId $Auth.ApplicationID -CertificateThumbprint $Auth.CertificateThumbprint | Out-Null
    
    <# these variables should be changed if reuse of this script in another context. #>
    $Subscription = ""
    $Location = "France Central"
    $ResourceGroupName = ""
    $VirtualNetworkName = ""
    $SubnetName = ""
    $PublicIpAddressName = ""
    $BastionName = ""
 
    Set-AzContext -SubscriptionId $Subscription | Out-Null
    Write-Output "[info] Azure Context has been set. "
    
    CheckResourceGroup
}
 
function CheckResourceGroup {
    $ResourceGroup = Get-AzResourceGroup -Name $ResourceGroupName -Location $Location -ErrorAction SilentlyContinue
    if ($ResourceGroup) {
        Write-Output "[info] Resource Group $ResourceGroupName has been found. "
        CheckNetwork
    }
    else {
        Write-Output "[error] Resource Group $ResourceGroupName has not been found. "
    }
}
 
function CheckNetwork {
    $VirtualNetwork = Get-AzVirtualNetwork -ResourceGroup $ResourceGroupName -Name $VirtualNetworkName -ErrorAction SilentlyContinue
    if ($VirtualNetwork) {
        Write-Output "[info] Virtual Network $VirtualNetworkName has been found. "
        $Subnet = Get-AzVirtualNetworkSubnetConfig -VirtualNetwork $VirtualNetwork -Name $SubnetName -ErrorAction SilentlyContinue
        if ($Subnet) {
            Write-Output "[info] Subnet $SubnetName has been found. "
            CheckPublicIP
        }
        else {
            Write-Output "[error] Subnet $SubnetName has not been found. "
        }
    }
    else {
        Write-Output "[error] Virtual Network $VirtualNetworkName has not been found. "
    }
}
 
function CheckPublicIP {
    $PublicIp = Get-AzPublicIpAddress -ResourceGroup $ResourceGroupName -Name $PublicIpAddressName -ErrorAction SilentlyContinue
    if ($PublicIp) {
        Write-Output "[info] Public IP Address $PublicIpAddressName has been found. "
        CheckBastion
    }
    else {
        Write-Output "[error] Public IP Address $PublicIpAddressName has not been found. "
    }
}
 
function CheckBastion {
    $Bastion = Get-AzBastion -ResourceGroup $ResourceGroupName -Name $BastionName -ErrorAction SilentlyContinue
    if ($Bastion) {
        Write-Output "[info] Bastion $BastionName has been found. "
        Return
    }
    else {
        Write-Output "[info] Bastion $BastionName has not been found. "
        New-AzBastion -ResourceGroupName $ResourceGroupName -Name $BastionName -PublicIpAddress $PublicIp -VirtualNetwork $VirtualNetwork | Out-Null
        Write-Output "[info] Bastion $BastionName has been deployed. "
    }
}
 
##### INIT #####
Init
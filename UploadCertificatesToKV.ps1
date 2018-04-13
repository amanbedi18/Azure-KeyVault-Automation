Param(
    [Parameter(ParameterSetName='Customize',Mandatory=$true)]
    [Parameter(ParameterSetName='Secondary',Mandatory=$true)]
	[String]
    $KeyVaultName,
    [Parameter(ParameterSetName='Customize',Mandatory=$true)]
    [Parameter(ParameterSetName='Secondary',Mandatory=$true)]
	[String]
    $kvCertPath,
    [Parameter(ParameterSetName='Customize',Mandatory=$true)]
    [Parameter(ParameterSetName='Secondary',Mandatory=$true)]
	[String]
    $kvCertPassword,
    [Parameter(ParameterSetName='Customize',Mandatory=$true)]
	[String]
    $dpClientCertPath,
    [Parameter(ParameterSetName='Customize',Mandatory=$true)]
	[String]
    $dpClientCertPassword
<#    [Parameter(ParameterSetName='Customize',Mandatory=$true)]
	[String]
    $apCertPath,
    [Parameter(ParameterSetName='Customize',Mandatory=$true)]
	[String]
    $apCertPassword,
    [Parameter(ParameterSetName='Customize',Mandatory=$true)]
	[String]
    $vtCertPath,
    [Parameter(ParameterSetName='Customize',Mandatory=$true)]
	[String]
    $vtCertPassword,
    [Parameter(ParameterSetName='Customize',Mandatory=$true)]
	[String]
    $dpCertPath,
    [Parameter(ParameterSetName='Customize',Mandatory=$true)]
	[String]
    $dpCertPassword,#>
)


function uploadCert($certPath, $certPassword, $secretName)
{
    $flag = [System.Security.Cryptography.X509Certificates.X509KeyStorageFlags]::Exportable 
    $collection = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2Collection  
    $collection.Import($certPath, $certPassword, $flag) 
    $pkcs12ContentType = [System.Security.Cryptography.X509Certificates.X509ContentType]::Pkcs12 
    $clearBytes = $collection.Export($pkcs12ContentType) 
    $fileContentEncoded = [System.Convert]::ToBase64String($clearBytes) 
    $secret = ConvertTo-SecureString -String $fileContentEncoded -AsPlainText –Force 
    $secretContentType = 'application/x-pkcs12' 
    $NewSecret = Set-AzureKeyVaultSecret -VaultName $KeyVaultName -Name $secretName -SecretValue $Secret -ContentType $secretContentType

    $CUrl = $NewSecret.Id
    
    return $CUrl
}

#------------------------------   Key Vault Resource Id    -------------------------------#

$kvResourceId = (Get-AzureRmKeyVault -VaultName $KeyVaultName).ResourceId

Write-Host ("##vso[task.setvariable variable=KVResourceId;]$kvResourceId")
Write-Host $env:KVResourceId
Write-Host "Certificate URL : "$kvResourceId


#------------------------------   Key Vault Certificate    -------------------------------#

$certurl = uploadCert -certPath $kvCertPath -certPassword $kvCertPassword -secretName "KVAppCertificate"

Write-Host ("##vso[task.setvariable variable=KVCertURL;]$certurl")
Write-Host $env:KVCertURL
Write-Host "Certificate URL : "$certurl


#------------------------------   Device Provisining Client Certificate    -------------------------------#

if($PSCmdlet.ParameterSetName -ne 'Secondary'){

$certurl = uploadCert -certPath $dpClientCertPath -certPassword $dpClientCertPassword -secretName "DPClientCertificate"

Write-Host ("##vso[task.setvariable variable=DPClientCertURL;]$certurl")
Write-Host $env:DPClientCertURL
Write-Host "Certificate URL : "$certurl

}

<#
#------------------------------   Admin Portal Certificate    -------------------------------#

$certurl = uploadCert -certPath $apCertPath -certPassword $apCertPassword -secretName "AdminPortalCertificate"

Write-Host ("##vso[task.setvariable variable=APCertURL;]$certurl")
Write-Host $env:APCertURL
Write-Host "Certificate URL : "$certurl

#------------------------------   Vehicle Tracking Certificate    -------------------------------#

$certurl = uploadCert -certPath $vtCertPath -certPassword $vtCertPassword -secretName "VehicleTrackingCertificate"

Write-Host ("##vso[task.setvariable variable=VTCertURL;]$certurl")
Write-Host $env:VTCertURL
Write-Host "Certificate URL : "$certurl

#------------------------------   Device Provisioning Certificate    -------------------------------#

$certurl = uploadCert -certPath $dpCertPath -certPassword $dpCertPassword -secretName "DeviceProvisiningCertificate"

Write-Host ("##vso[task.setvariable variable=DPCertURL;]$certurl")
Write-Host $env:DPCertURL
Write-Host "Certificate URL : "$certurl#>
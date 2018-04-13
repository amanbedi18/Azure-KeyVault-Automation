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
    $kvCertPassword
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
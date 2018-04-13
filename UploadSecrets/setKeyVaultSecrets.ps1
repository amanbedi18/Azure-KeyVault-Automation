<#

.PREREQUISITE
1. An Azure key vault and its name as parameter.
2. Json template should be properly populated with valid json schema in sampleSecretValues.json in KeyVaultjson directory.

.PARAMETER vaultName
The name of the key vault.

.EXAMPLE
. setKeyVaultSecret.ps1 -KeyVaultName 'somekeyvault'
#>

# provision keys and secrets to a key vault 

Param(
    [Parameter(ParameterSetName='Customize',Mandatory=$true)]
    [Parameter(ParameterSetName='Secondary',Mandatory=$true)]
	[String]
    $KeyVaultName,
    [Parameter(ParameterSetName='Customize',Mandatory=$true)]
    [Parameter(ParameterSetName='Secondary',Mandatory=$true)]	
	[String]
	$KVSecretMetadataFilePath
)

Install-Module -Name AzureADPreview -ErrorAction SilentlyContinue -Force 
Import-Module Azure -ErrorAction SilentlyContinue
Import-Module AzureRM.Resources

Set-StrictMode -Version 3

$json = Get-Content $KVSecretMetadataFilePath | Out-String | ConvertFrom-Json

$json | ForEach {

$secretToSearch = Get-AzureKeyVaultSecret -VaultName $KeyVaultName -Name $_.key -ErrorAction SilentlyContinue

if($secretToSearch -ne $null)
{
    echo "The secret $_.key already exists !"
}
Else
{
    $NewSecret = Set-AzureKeyVaultSecret -VaultName $KeyVaultName -Name $_.key -SecretValue (ConvertTo-SecureString $_.value -AsPlainText -Force ) -Verbose
    Write-Host
    Write-Host "Source Vault Resource Id: "$(Get-AzureRmKeyVault -VaultName $KeyVaultName).ResourceId
}
}

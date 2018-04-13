#Requires -Module AzureRM.KeyVault

# Use this script to create a certificate that you can use to secure a Service Fabric Cluster
# This script requires an existing KeyVault that is EnabledForDeployment.  The vault must be in the same region as the cluster.
# To create a new vault and set the EnabledForDeployment property run:
#
# New-AzureRmResourceGroup -Name KeyVaults -Location WestUS
# New-AzureRmKeyVault -VaultName $KeyVaultName -ResourceGroupName KeyVaults -Location WestUS -EnabledForDeployment
#
# Once the certificate is created and stored in the vault, the script will provide the parameter values needed for template deployment
# 

param(
    [string] [Parameter(Mandatory=$true)] $Password,
    [string] [Parameter(Mandatory=$true)] $CertName
)

$SecurePassword = ConvertTo-SecureString -String $Password -AsPlainText -Force
$CertFileFullPath = $(Join-Path (Split-Path -Parent $MyInvocation.MyCommand.Definition) "\$CertName.pfx")

$now = [System.DateTime]::Now
$5yearfromnow = $now.AddYears(5)

$NewCert = New-SelfSignedCertificate -CertStoreLocation Cert:\CurrentUser\My -Subject $CertName -KeySpec Signature -KeyExportPolicy Exportable -NotAfter $5yearfromnow 

Export-PfxCertificate -FilePath $CertFileFullPath -Password $SecurePassword -Cert $NewCert
Write-Host "Certificate Thumbprint : "$NewCert.Thumbprint

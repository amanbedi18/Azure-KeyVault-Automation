<#

.PREREQUISITE
1. An Azure Active Directory tenant.
2. A Global Admin user within tenant.
3. Existing resource group with key-vault.
4. Application name, uri, reply url.
5. User principal name.

.PARAMETER WebApplicationName
Name of web application representing the key vault AD application.

.PARAMETER WebApplicationUri
App ID URI of web application.

.PARAMETER WebApplicationReplyUrl
Reply URL of web application. 

.PARAMETER userPrincipalName
The user principal name to be granted key vault permissions.

.PARAMETER resourceGroupName
The name of the resorce group.

.PARAMETER vaultName
The name of the key vault.

.EXAMPLE
. SetupKeyVaultApplications.ps1 -WebApplicationName 'myKeyVaultADApp' -WebApplicationUri 'http://myKeyVaultADApp' -WebApplicationReplyUrl 'http://myKeyVaultADApp' -userPrincipalName 'someuser@domain.com' -resourceGroupName 'someazureresourcegroup' -vaultName 'someazurekeyvault'

#>

Param
(
    [Parameter(ParameterSetName='Customize',Mandatory=$true)]	
	[String]
	$WebApplicationName,

    [Parameter(ParameterSetName='Customize',Mandatory=$true)]
	[String]
	$WebApplicationUri,

    [Parameter(ParameterSetName='Customize',Mandatory=$true)]
	[String]
    $WebApplicationReplyUrl,

    [Parameter(ParameterSetName='Customize',Mandatory=$true)]
	[String]
    $userPrincipalName1,
 
    [Parameter(ParameterSetName='Customize',Mandatory=$true)]
	[String]
    $kvCertPath,

    [Parameter(ParameterSetName='Customize',Mandatory=$true)]
	[String]
    $kvCertPassword,
    
    [Parameter(ParameterSetName='Customize',Mandatory=$true)]
	[String]
    $resourceGroupName,

    [Parameter(ParameterSetName='Customize',Mandatory=$true)]
	[String]
    $vaultName,

    [Parameter(ParameterSetName='Customize',Mandatory=$true)]
	[String]
    $spAppSearchString,

    [Parameter(ParameterSetName='Customize',Mandatory=$true)]
	[String]
    $userName,

    [Parameter(ParameterSetName='Customize',Mandatory=$true)]
	[String]
    $password,

    [Parameter(ParameterSetName='Customize',Mandatory=$true)]
	[String]
    $subscriptionName
)

Try
{
    $FilePath = Join-Path $PSScriptRoot "Microsoft.IdentityModel.Clients.ActiveDirectory.dll"
    Add-Type -Path $FilePath
}
Catch
{
    Write-Warning $_.Exception.Message
}

Install-Module -Name AzureADPreview -ErrorAction SilentlyContinue -Force 
Import-Module Azure -ErrorAction SilentlyContinue
Import-Module AzureRM.Resources

$secpasswd = ConvertTo-SecureString $password -AsPlainText -Force
$mycreds = New-Object System.Management.Automation.PSCredential ($userName, $secpasswd)

Login-AzureRmAccount -Credential $mycreds -SubscriptionName $subscriptionName
$currentContext = Get-AzureRmContext

$TenantId = $currentContext.Subscription.TenantId

Connect-AzureAD -TenantId $TenantId -Credential $mycreds

$adAppCheck = Get-AzureRmADApplication -IdentifierUri "$WebApplicationUri"

If ($adAppCheck -ne $null)
{
   echo "The AD App $WebApplicationName already exists ! exiting now !"
   exit 
}

$authority = "https://login.microsoftonline.com/$TenantId"

function GetGraphAuthHeader() {

    $clientId = "1950a258-227b-4e31-a9cf-717495945fc2"  # Set well-known client ID for AzurePowerShell
    $redirectUri = "urn:ietf:wg:oauth:2.0:oob" # Set redirect URI for Azure PowerShell
    $resourceAppIdURI = "https://graph.windows.net/" # resource we want to use
    # Create Authentication Context tied to Azure AD Tenant
    $authContext = New-Object "Microsoft.IdentityModel.Clients.ActiveDirectory.AuthenticationContext" -ArgumentList $authority
    # Acquire token
    $authResult = $authContext.AcquireToken($resourceAppIdURI, $clientId, $redirectUri, "Auto")
    $authHeader = $authResult.CreateAuthorizationHeader()
    $headers = @{"Authorization" = $authHeader; "Content-Type"="application/json"}    
    return $headers
}

Set-AzureRmKeyVaultAccessPolicy -VaultName $vaultName -ResourceGroupName $resourceGroupName -PermissionsToKeys all -PermissionsToSecrets all -UserPrincipalName $userPrincipalName1 -PermissionsToCertificates all

$vsoServicePrincipal = Get-AzureADServicePrincipal -SearchString $spAppSearchString

Set-AzureRmKeyVaultAccessPolicy -VaultName $vaultName -ObjectId $vsoServicePrincipal.ObjectId -ResourceGroupName $resourceGroupName -PermissionsToKeys all -PermissionsToSecrets all -PermissionsToCertificates all

$secpasswd = ConvertTo-SecureString $kvCertPassword -AsPlainText -Force

$x509 = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2
$x509.Import($kvCertPath,$secpasswd,"DefaultKeySet")
$credValue = [System.Convert]::ToBase64String($x509.GetRawCertData())

# If you used different dates for makecert then adjust these values
$now = [System.DateTime]::Now
$yearfromnow = $now.AddYears(1)

$adapp = New-AzureRmADApplication -DisplayName "$WebApplicationName" -HomePage "$WebApplicationUri" -IdentifierUris "$WebApplicationUri" -CertValue $credValue -StartDate $now -EndDate $yearfromnow -ReplyUrls "$WebApplicationReplyUrl"

$adapp = Get-AzureRmADApplication -IdentifierUri "$WebApplicationUri"

$clientId = $adapp.ApplicationId

echo "kvcertapp client id: $adapp.ApplicationId"

$headers = GetGraphAuthHeader 
$url = "https://graph.windows.net/$TenantId/applications/$($adapp.ObjectID)?api-version=1.6"
$postUpdate = "{`"requiredResourceAccess`":[{`"resourceAppId`":`"00000002-0000-0000-c000-000000000000`",
`"resourceAccess`":[{`"id`":`"311a71cc-e848-46a1-bdf8-97ff7156d8e6`",`"type`":`"Scope`"}]},{`"resourceAppId`":`"797f4846-ba00-4fd7-ba43-dac1f8f63013`",
`"resourceAccess`":[{`"id`":`"41094075-9dad-400e-a0bd-54e686782033`",`"type`":`"Scope`"}]}]}";
$updateResult = Invoke-RestMethod -Uri $url -Method "PATCH" -Headers $headers -Body $postUpdate        
echo $updateResult

New-AzureRmADServicePrincipal -ApplicationId $adapp.ApplicationId

Start-Sleep 30

Set-AzureRmKeyVaultAccessPolicy  -VaultName $vaultName  -ResourceGroupName $resourceGroupName -ServicePrincipalName "$WebApplicationUri" -PermissionsToKeys get,wrapKey,unwrapKey,sign,verify,list -PermissionsToSecrets get -PermissionsToCertificates all

Set-AzureRmKeyVaultAccessPolicy -VaultName $vaultName -ResourceGroupName $resourceGroupName -ServicePrincipalName "abfa0a7c-a6b6-4736-8310-5855508787cd" -PermissionsToSecrets get

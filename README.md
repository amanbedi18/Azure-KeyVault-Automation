# Azure-KeyVault-Automation
## Automation PowerShell scripts for Azure KeyVault

### This repository contains PowerShell scripts to accomplish the following common key vault management tasks:

1. Creating a self signed certificate to secure an AD application / uploading certificates to keyvault.
2. Creating an Azure AD application for authenticating users / service principals to access key vault with customized set of permissions.
3. Upload secrets to key vault.

_**Each folder has necessary automation scripts and supporting files to facilitate the mentioned functionality.**_
_**Below is how to run the scripts for the same:**_

## 1. Creating & uploading certificates to keyvault.

The _KeyVaultCertificates_ folder has 2 scripts:
### * NewKvAppCertificate.ps1

This script will help to create a self signed certificate secured by the user provided password to be used against the creation of Azure AD app (in the next step) to secure access to key vault to only authenticated users through the AD app.

The following are the script parameters:
* Password = password to secure the certificate with
* CertName = name of the certificate

On executing the script a self signed password protected certificate (valid for 5 years) will be created in same directory as that of the script execution path and the same will be imported in the "My" store of the local user.

**The thumbprint of the certificate will be written to the host and should be copied for next steps.**

### * UploadCertificatesToKV.ps1

This script will upload certificates to a given key vault (provided the executing azure account / service principal context has enough permissions to perform certificate upload operation on the key vault).

The following are the script parameters:
*  KeyVaultName = name of the key vault
* kvCertPath = local file path of the certificate to be uploaded
* kvCertPassword = password of the certificate

On executing the script the certificate will be uploaded to the key vault as a secured string and stored as a secret. The resource ID of the key vault and the secret will be written on to the host.

## 2. Creating AD application (secured by the self signed certificate) to secure access to the key vault to only authenticated users and enforce policies against service principals for read / write operations.

The _KeyVaultAdApp_ folder has 1 script:

### * SetupKeyVaultApplication.ps1

This script will create an AD application secured by the self signed certificate and add the application's service principal to be able to apply read / write operations on keys and secrets in the keyvault. Along with that it will also configure other user principal and app principal accounts for keyvault access as well as enable app service to store and retrieve certificates from the keyvault.

The following are the script parameters:
* WebApplicationName = Web application 
* WebApplicationUri = Web application uri
* WebApplicationReplyUrl = Web application reply uri
* userPrincipalName1 = user principal name to configure access to key vault
* kvCertPath = filepath of the key vault certificate
* kvCertPassword = password of the key vault certificate
* resourceGroupName = name of the resource group containing the key vault
* vaultName = name of the key vault
* spAppSearchString = name of the service principal app
* userName = user name of the user principal
* password = name of the user principal password
* subscriptionName = name of the azure subscription

On executing the script the following would happen:

* The script would login with user principal credentials (here the user is the co-owner of the azure subscription so the account has permissions to perform operations on key-vault, if instead an automation account like service principal or another user account is used, ensure that it has enough permissions to the key vault) and check if any app in the ad exist with the same reply url (it is useful to use reply url as the parameter to search for existing ad applications as it is unique for all apps whereas name of one app can be substring of name of another existing app so the script would fail at that check).
* It the configures read and write access to keys and secrets to user and service principal account as configured.
* A new AD application is the created with provided name, reply url, home url and certificate.
* The AD application is given permissions to Azure AD management service and user profile via graph API call so that user's belonging to same tenant can authenticate.
* Finally service principal is created against the AD app and a halt of 30 seconds is added to let the principal propagate in the AD.
* Post this the newly created AD app's service principal object is configured to have read / write access to keys and secrets in the kayvault.
* Also another access policy is added to enable web apps to access key vault to read / write certificates.

## 3. Uploading secrets to Azure Key Vault.

The _UploadSecrets_ folder has 1 script:
### * setKeyVaultSecrets.ps1

This script will upload secrets to azure key vault from a configuration json file (AzureSecretsMetaData.json file in the same folder).

The following are the script parameters:
* KeyVaultName = name of the azure key vault.
* KVSecretMetadataFilePath = the file path for the metadata json file to fetch key / value pairs to create secrets in the key vault.

On executing this script the keys and secrets will be parsed through from the metadata json file and uploaded to key vault as secure string in key vault secret store.

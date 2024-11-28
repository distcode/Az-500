# Azure VM: Sign in with Entra ID account

This article describes how to sign in to an Azure VM with an user of Entra ID instead of a local or domain user. Microsoft's documentation for this feature can be found [here](https://learn.microsoft.com/en-us/entra/identity/devices/howto-vm-sign-in-azure-ad-windows) and for Linux VMs [here](https://learn.microsoft.com/en-us/entra/identity/devices/howto-vm-sign-in-azure-ad-linux).

---

Table of Content

+ [Preparation](#preparation)
+ [Scenario 1 - Passwordless Authentication](#scenario-1---passwordless-authentication)
+ [Scenario 2 - Password Authentication](#scenario-2---password-authentication)

---

## Preparation

Before you are able to sign in to an Azure VM with an Entra account you have to check the supported operation system. Microsoft supports this feature at the moment on the following systems:

+ Windows Server 2019 Datacenter and later
+ Windows 10 1809 and later
+ Windows 11 21H2 and later

Then check, if there's already a device in Entra ID with the same name as your Azure VM. By installing the extension ***Azure AD based Windows Login / AADLogin*** the VM will be joined. If a device with same devicename as the hostname of your VM exists, the join process could not be finished. In the Audit Log of Entra ID you could see an Failure entry initiated by *Device Registraton Service*. And of course, to sign in with an Entra ID account is not possible :wink:

The VM needs a system assigned managed identity to run the extension. This should be checked if you are working with an already existing VM. For newly created VMs the managed identity is created automatically if you enable Entra ID login.

For the installation of the extension ***Azure AD based Windows Login / AADLogin*** the VM must be running.

After you have installed the extension successfully, assign the appropriate RBAC role to your users/admin:

+ Virtual Machine Administrator Login
+ Virtual Machine User Login

These requirements apply to both following scenarios.

## Scenario 1 - Passwordless Authentication

Following the client-side configure is shown so you could enforce

+ multifactor Authentication
+ passwordlesse authentication
+ device compliance state via conditional access

1. In the Azure portal, download the RDP-file for connecting to your VM.
2. Open the RDP-File in a text editor like notepad or Visual Studio Code.
3. Replace or add the following settings:

    ```code
    full address:s:VM01:3389
    enablerdsaadauth:i:1
    ```

    > Note: Instead of altering the RDP-file in an editor you could also set the advanced option *Use a web account to sign in to the remote computer* in Remote Desktop Connection tool.
4. Ensure the VM name could be successfully resolved. Maybe you have to change DNS or your hosts file.
5. Save the file and double click it to connect.
6. Sign in with Entra ID user principal name. If there are any issuse, use the format *AzureAD\\user\@domain.com*.

## Scenario 2 - Password Authentication

This configuration shows you the client-side configuration so you could use the windows logon screen for signing in.

>Note: Important: Remote connection to VMs that are joined to Microsoft Entra ID is allowed only from Windows 10 or later PCs that are either Microsoft Entra registered (minimum required build is 20H1) or Microsoft Entra joined or Microsoft Entra hybrid joined to the same directory as the VM.

1. In the Azure portal, download the RDP-file for connecting to your VM.
2. Double click it to connect.
3. Sign in with your user principal name. If there are any issuse, use the format *AzureAD\\user\@domain.com*.

> Note: In this case you could use the IP address of your machine and not necessarily the hostname.

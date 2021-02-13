# This code grants access to the F5 API, which by default is only accessible to full admins

# Set variables...
$User = "<f5-admin>"
$Pass = "<f5-admin-password>"
$F5ManagementAddress = "<f5-management-ip-or-dns>"
$APIUser = "<apiuser>" # The user who'll be granted access to the F5 API. This user account must already exist.

# Generate authentication token
$Pair = "$($User):$($Pass)"
$EncodedCreds = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($Pair))
$BasicAuthValue = "Basic $EncodedCreds"
$Headers = @{
    Authorization = $BasicAuthValue
}

# Use this section if your F5 management management interface doesn't use a trusted TLS cert.
# If you use valid certificates - well done! You can comment out or delete this section...

### START ignore invalid TLS certificate block ###

If (-not ([System.Management.Automation.PSTypeName]'ServerCertificateValidationCallback').Type)
{
$CertCallback = @"
    using System;
    using System.Net;
    using System.Net.Security;
    using System.Security.Cryptography.X509Certificates;
    public class ServerCertificateValidationCallback
    {
        public static void Ignore()
        {
            if(ServicePointManager.ServerCertificateValidationCallback ==null)
            {
                ServicePointManager.ServerCertificateValidationCallback += 
                    delegate
                    (
                        Object obj, 
                        X509Certificate certificate, 
                        X509Chain chain, 
                        SslPolicyErrors errors
                    )
                    {
                        return true;
                    };
            }
        }
    }
"@
    Add-Type $CertCallback
 }

[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12;
[ServerCertificateValidationCallback]::Ignore()

### END ignore invalid TLS certificate block ###

$URI = "https://$f5managementaddress/mgmt/shared/authz/roles/iControl_REST_API_User"
$Body = '{ "userReferences": [{"link":"https://localhost/mgmt/shared/authz/users/' + $apiuser + '"}] }'
$Result = Invoke-RestMethod -Uri $URI -Headers $Headers -Method Patch -Body $Body
$Result
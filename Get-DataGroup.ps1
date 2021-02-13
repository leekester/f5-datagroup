# Set variables...
$f5partition = "Production"
$f5poolname = "Frontend_App_pool"
$f5port = 8080
$user = "myf5userid"
$pass = "myf5password"
$f5server = "myf5server.mydomain.local"

# ======= NO CHANGES BELOW THIS LINE! =======
$servername = $env:COMPUTERNAME

# ====== AUTHORISATION SECTION ==========
$pair = "$($user):$($pass)"
$encodedCreds = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($pair))
$basicAuthValue = "Basic $encodedCreds"
$Headers = @{
    Authorization = $basicAuthValue
}

# === CONNECT TO F5 API =========
$reply = Invoke-RestMethod -Uri https://${f5server}/mgmt/tm/ltm/pool/~${f5partition}~${f5poolname}/members/~${f5partition}~${servername}:${f5port}/stats/?$select=serverside.curConns -Headers $Headers
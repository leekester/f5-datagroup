# curl -k -u admin:f5rules -H "Content-Type: application/json" -X PUT -d '{"records":[{"name":"123","data":"435" }]}' https://1.0.1.6/mgmt/tm/ltm/data-group/internal/~Common~TEST_iRule

$Template = '{"records":[]}' | ConvertFrom-Json

ForEach ($IP in $MailRelayIPs) {
    $JsonDataAdd = @"
    {
        "name": "$IP",
        "data": ""
    }
"@
    $Template.records += (ConvertFrom-Json $JsonDataAdd)
    }
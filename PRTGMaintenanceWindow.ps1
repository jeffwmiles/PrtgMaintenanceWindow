param(
    [Parameter(Mandatory = $true)] [datetime]$MaintStartTime,
    [Parameter(Mandatory = $true)] [datetime]$MaintEndTime,
    [Switch]$IncludeProdWebServers,
    [Switch]$IncludeTestWebServers
)

# Use $Global parameters so they can be used inside the Function without repeating
$Global:prtgAuth = 'username=PRTGUSERNAME&passhash=GENERATEDHASHVALUE'
$Global:prtgServer = 'https://FQDN.OF.PRTG'
$Global:MaintStart = '{0:yyyy-MM-dd-HH-mm-ss}' -f $MaintStartTime
$Global:MaintEnd = '{0:yyyy-MM-dd-HH-mm-ss}' -f $MaintEndTime

$ServicesID = @("OBJECTID") # Group containing devices &amp; sensors that I want to control
$ProdWebServersID = @("13152", "13153", "13149", "13150") # Individual Devices to conditionally apply a maintenance window to
$TestWebServersID = @("13219", "13221", "13220", "13222")

# Function that can be called multiple times, after passing in an ObjectID.
function ApplyMaintenanceWindow {
    param(
        [int]$objectid
    )
    # Apply Start Time of Maintenance Window
    $startattempt = Invoke-WebRequest "$prtgServer/api/setobjectproperty.htm?id=$objectid&name=maintstart&value=$MaintStart&$prtgAuth" -UseBasicParsing
    
    # Display the output as successful if HTTP200 response code received. Using Out-String for future integration purposes with website. 
    if ($startattempt.StatusCode -eq "200") {
        $message = "Object ID: $objectid - Maintenance window set to start at $MaintStart"
        $message | out-string
    }
    # Apply End Time of Maintenance Window
    $endattempt = Invoke-WebRequest "$prtgServer/api/setobjectproperty.htm?id=$objectid&name=maintend&value=$MaintEnd&$prtgAuth" -UseBasicParsing
    if ($endattempt.StatusCode -eq "200") {
        $message = "Object ID: $objectid - Maintenance window set to end at $MaintEnd"
        $message | out-string
    }
    # Enable Maintenance Window for the object
    $enableattempt = Invoke-WebRequest "$prtgServer/api/setobjectproperty.htm?id=$objectid&name=maintenable&value=1&$prtgAuth" -UseBasicParsing
    if ($enableattempt.StatusCode -eq "200") {
        $message = "Object ID: $objectid - Maintenance window enabled"
        $message | out-string
    }
}

# Add maintenance Window for Client Services
# Do this always, with the parameters supplied
foreach ($id in $ClientServicesID) {
    ApplyMaintenanceWindow -objectid $id
}

#If necessary, add maintenance window for ProdWebServers
# Do this conditionally, if the switch is provided
if ($IncludeProdWebServers.IsPresent) {
    foreach ($id in $ClientProdWebServersID) {
        ApplyMaintenanceWindow -objectid $id
    }
}

#If necessary, add maintenance window for TestWebServers
# Do this conditionally, if the switch is provided
if ($IncludeTestWebServers.IsPresent) {
    foreach ($id in $ClientTestWebServersID) {
        ApplyMaintenanceWindow -objectid $id
    }
}
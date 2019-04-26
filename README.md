# PrtgMaintenanceWindow
Website to add PRTG maintenance window for specified set of objects

Blog post detailing it here: https://faultbucket.ca/2019/01/prtg-api-to-add-maintenance-window/

Manual run of .ps1 can be done like this:

<code>$start = get-date
$end = (get-date).AddMinutes(5)
.\PrtgMaintenanceWindow.ps1 -MaintStartTime $start -MaintEndTime $end -IncludProdWebServers -IncludeTestWebServers
</code>

Many potential improvements are possible here:
- Find objects to add maintenance window dynamically through API based on Tag
- Figure out a better method of setting a schedule on the required objects programmatically, so that the maintenance window is effective

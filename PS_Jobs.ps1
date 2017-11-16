#simple job example
Start-Job -ScriptBlock {'Hi'}
#see job
Get-Job
#get job results
$a = Get-Job 3
$a.ChildJobs.Output
#get results of job
$b = Get-Job 3 | Receive-Job
$b
Receive-Job 3 #its gone now
#keep in job cache
$b = Get-Job 5 | Receive-Job -Keep
#----------------------------------
#asynchronous
$jobExample = {foreach ($i in 1..10) {Start-Sleep 5; "i is $i"}}
Start-Job -ScriptBlock $jobExample
#----------------------------------
#status
$jobStatuses = Get-Job | Select-Object State
#----------------------------------
#so what
Measure-Command {Get-EventLog -LogName System -EntryType Error -Message "*Cluster*"; Start-Sleep(5)}
Start-Job -ScriptBlock {Get-EventLog -LogName System -EntryType Error -Message "*Cluster*"}
Start-Job -ScriptBlock {Get-EventLog -LogName Application -EntryType Error -Message "*Cluster*"}
#note no data return
#now try with data return
Start-Job -ScriptBlock {Get-EventLog -LogName System -EntryType Error -Newest 5}
$a = Get-Job 15
$a.ChildJobs
$a.ChildJobs | fl *
$a.ChildJobs.output
#----------------------------------
$devices = Get-ADComputer -filter * | Select-Object -ExpandProperty dnshostname
function Get-AllSystemErrors {
    $systemErrors = Get-EventLog -LogName System -EntryType Error
    return $systemErrors
}

Invoke-Command -ComputerName $devices -ScriptBlock ${function:Get-AllSystemErrors} -AsJob
$status = Get-Job 73

foreach($device in $devices){
    Invoke-Command -ComputerName $device -ScriptBlock ${function:Get-AllSystemErrors} -AsJob
}
#----------------------------------
$allJobs = Get-Job
$maxWaitCount = 10
While ($maxWaitCount -ne 0) {
    $allDone = $true
    foreach ($job in $allJobs) {
        if ($job.State -eq "Failed") {
            Write-Host $job.Location "has FAILED" -ForegroundColor Red -BackgroundColor Black
            $x = $null
            $x = Receive-Job $job.Name
            Write-Host $x
            Write-Host "Removing this job"
            Remove-Job $job.Name -Force
        }
        elseif ($job.State -ne "Completed") {
            $allDone = $false
            Write-Host $job.Location "still processing..."
        }
    }
    if ($allDone -ne $true) {
        Write-Host "Waiting 60 seconds before checking again."
        Write-Host "MAX WAIT COUNT #: $maxWaitCount"
        Start-Sleep (60)
        $maxWaitCount--
        Write-Host "------------------------------" -ForegroundColor Gray
    }
    else {
        $maxWaitCount = 0
    }
}
#----------------------------------
foreach ($job in $allJobs) {
    if ($job.State -eq "Completed") {
        $t = Receive-Job $job.Name
        $t | Export-Csv C:\rs-pkgs\Success.csv -NoTypeInformation -Append -Force
    }
    else {
        Write-Host $job.Location "NOT DUMPED" -ForegroundColor Red -BackgroundColor Black
    }
}
### powershell script by siavashyousefi.com ###

### Change below to match your configuration ###
$rawlistlocation = "C:\rdsuserdeletelist.csv"
$disabledlistlocation = "C:\rdsuserdisableaccounts.csv"
$disabledusersOUpath = "OU=Disabled Users,OU=Company Users,DC=company,DC=companydomain,DC=com"
$updfolder = "E:\ProfileDisks"
$disabledupdfolder = "E:\disabledupds"
$updserver = "Company-FS-01"

$title1    = 'Need proper account names!'
$question1 = "Do you have a proper list of sam account names in $($disabledlistlocation)?"
$choices1 = New-Object Collections.ObjectModel.Collection[Management.Automation.Host.ChoiceDescription]
$choices1.Add((New-Object Management.Automation.Host.ChoiceDescription -ArgumentList '&Yes'))
$choices1.Add((New-Object Management.Automation.Host.ChoiceDescription -ArgumentList '&No'))
$decision1 = $Host.UI.PromptForChoice($title1, $question1, $choices1, 1)
if ($decision1 -eq 0) {

    Write-Host "Using $disabledlistlocation" -ForegroundColor Yellow

    ### Disabling users in the list and move them to Disabled Users OU and move UPDs of Disabled users to disabledupds folder ###
    $disablelist = $null
    $disablelist = Import-Csv $disabledlistlocation
    $disabledaccountsinfo = $null
    $disabledaccountsinfo = @() 
  
    foreach ($rdsuser in $disablelist){
        Disable-ADAccount -Identity $rdsuser.SamAccountName -WhatIf
        $personofinterest = Get-ADUser $rdsuser.SamAccountName
        $personofinterest | Move-ADObject -TargetPath $disabledusersOUpath -WhatIf   
 
        $vhdx = 'UVHD-' + $($personofinterest.SID) + '.vhdx'      
        $disabledaccountsinfo += [PSCustomObject]@{Name = "$($personofinterest.Name)" ;  UPN = "$($personofinterest.UserPrincipalName)" ; VHDX = "$vhdx"}                          
    }    

    invoke-command -ComputerName $updserver -ScriptBlock {Get-ChildItem -Path $using:updfolder -Recurse | Where-Object -Property Name -In $using:disabledaccountsinfo.VHDX | Move-Item -Destination $using:disabledupdfolder -WhatIf}    
    $disabledaccountsinfo

} else {
    Write-Host "Creating proper list from $rawlistlocation" -ForegroundColor Yellow

    ### Getting Account Name of the users ###
    $rawlist = $null
    $rawlist = Import-Csv $rawlistlocation
    
    &{foreach ($user in $rawlist){
    
     
     get-aduser -filter * -properties SamAccountName, Name | where {$_.Name -like "*$($user.last)" -or $_.Name -like "*$($user.first)" } |  Select-Object Name,SamAccountName
    
    }} | export-csv $disabledlistlocation -NoTypeInformation

    Write-Host "Now go and check $disabledlistlocation and if it was ok run this script again and this time answer yes!" -ForegroundColor Yellow
}     

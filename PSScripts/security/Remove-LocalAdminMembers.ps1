﻿# -----------------------------------------------------------------------------------------
# Script: Remove-LocalAdminMembers.ps1
# Author: Nigel Thomas
# Date: July 31, 2015
# Version: 1.0
# Purpose: This script is used to remove members from the local adminsitrators group. Except for specified users
#
# Project: foreScript
#
# -----------------------------------------------------------------------------------------
#
# (C) Nigel Thomas, 2015
#
#------------------------------------------------------------------------------------------

#Requires -version 3


if ($Computer -eq $null) {
    $Computer = $env:COMPUTERNAME
}

$LocalAdminsFile = 'c:\psscripts\localadmins.txt'
if (Test-Path $LocalAdminsFile) {
    $LocalAdmins = Get-Content -Path $LocalAdminsFile
    #$LocalAdmins
}

else {
    $message = "The file with the list of local administrators could not be found at $LocalAdminsFile ."
    $message
    return
}

$eventid4733 = '<QueryList>
  <Query Id="0" Path="Security">
    <Select Path="Security">*[System[(EventID=4733)]]</Select>
  </Query>
</QueryList>'

if (Test-Connection -Computer $Computer -Count 1 -BufferSize 16 -Quiet ) {


    try {

        # Get the CSName for client computers.
        # ProductType = 1 designate a desktop computer
        $os_params = @{
            'ComputerName' = $Computer;
            'Class' = 'win32_operatingsystem ';
            'Filter' = 'ProductType = "1"';
            'ErrorAction' = 'Stop'
        }

        # If we are going to use alternate credentials to access the computer then supply it

        if($FS_Credential) {
            $os_params.Credential = $FS_Credential
        }

        # Get the name of the computer
        $CSName = (Get-WmiObject @os_params).CSName

        # If we did not get anything, ie not client computer bail out, or just could not get the name then bail out
        if (!$CSName) {
            $message = "$Computer is running a Server Operating System.`r`n"
            $message += "This script can only be used to retrieve the members of the local Administrator group on Desktop computers.`r`n"
            $message
            return
        }

            'Class' = 'Win32_Group';
            'Filter' = 'LocalAccount = TRUE and SID="S-1-5-32-544"';
            'ErrorAction' = 'Stop'
            $findadminparams.Credential = $FS_Credential
        }
            $wmiEnumOpts = New-Object System.Management.EnumerationOptions
            $wmiEnumOpts.BlockSize = 20
            $admingroupmembers = $findadmingroup.GetRelated("Win32_Account","Win32_GroupUser","","", "PartComponent","GroupComponent",$false,$wmiEnumOpts)

                             $removeadminmemberresults += New-Object -TypeName PSObject -Property $removeadmingmemberhash

                            $removeadminmemberresults += New-Object -TypeName PSObject -Property $removeadmingmemberhash

     }
     catch {
  
     }
     

}
else {
  
  "Could not connect to computer $Computer...`r`n" 


}
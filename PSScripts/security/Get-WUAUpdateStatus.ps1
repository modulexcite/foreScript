﻿# -----------------------------------------------------------------------------------------
# Script: Get-WUAUpdateStatus.ps1
# Author: Nigel Thomas
# Date: July 30, 2015
# Version: 1.0
# Purpose: This script is used to get the Windows Update Status on a computer
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



if (Test-Connection -Computer $Computer -Count 1 -BufferSize 16 -Quiet ) {


    try {

        # Get the BuildNumber of the computer
        $os_params = @{
            'ComputerName' = $Computer;
            'Class' = 'win32_operatingsystem ';
            'Filter' = 'ProductType > "1"';
            'ErrorAction' = 'Stop'
        }

        # If we are going to use alternate credentials to access the computer then supply it

        if($FS_Credential) {
            $os_params.Credential = $FS_Credential
            $networkCred = $FS_Credential.GetNetworkCredential()
        }

        # Get the BuildNumber and ProductType
        $osresults = Get-WmiObject @os_params | Select-Object BuildNumber, ProductType
        #$osresults

        # If we did not get anything, so just  bail out
        if (!$osresults) {
            $message = "The script is designed to run against server and $Computer does not seem to be a server.`r`n"
            $message
            return
        }

           #'Filter' = 'sourcename = "Microsoft-Windows-WindowsUpdateClient" and EventCode=21';
           'ErrorAction' = 'Stop'
            $getupdateparams.Credential = $FS_Credential
        }

        $getupdates = Get-WmiObject @getupdateparams | Select -First 1
        
        if($getupdates) {
            $wuaupdatestatus.'Category' = $getupdates.CategoryString
            $wuaupdatestatus.'Pending Updates' = $getupdates.Message
            $wuaupdatestatus.'Record Number' = $getupdates.RecordNumber
            $wuaupdatestatus.'Time Generated' = $($getupdates.ConvertToDateTime($getupdates.TimeGenerated)).ToString()
            $wuaupdatestatus.'Time Written' = $($getupdates.ConvertToDateTime($getupdates.TimeWritten)).ToString()
        }
        else {

            $wuaupdatestatus.'Category' = ''
            $wuaupdatestatus.'Pending Updates' = ''
            $wuaupdatestatus.'Record Number' = ''
            $wuaupdatestatus.'Time Generated' = ''
            $wuaupdatestatus.'Time Written' = ''
        }
        

     }
     catch {
  
     }
     

}
else {
  
  "Could not connect to computer $Computer...`r`n" 


}
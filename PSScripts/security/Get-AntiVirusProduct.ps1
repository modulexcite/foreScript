﻿# -----------------------------------------------------------------------------------------
# Script: Get-AntivirusProducts.ps1
# Author: Nigel Thomas
# Date: May 4, 2015
# Version: 1.0
# Purpose: This script is used query the status of the Antivirus Product on desktop computers
#
# Project: foreScript
#
# -----------------------------------------------------------------------------------------
#
# (C) Nigel Thomas, 2015
#
#------------------------------------------------------------------------------------------

#Requires -version 3

if (Test-Connection -Computer $Computer -Count 1 -BufferSize 16 -Quiet ) {


    try {

        # Get the OS version for client computers.
        # ProductType = 1 designate a desktop computer
        $os_params = @{
            'ComputerName' = $Computer;
            'Class' = 'win32_operatingsystem ';
            'Filter' = 'ProductType = "1"';
            'ErrorAction' = 'Stop'
        }

        # If we are going to use alternate credentials to access the computer then supply it

        if($cred) {
            $os_params.Credential = $cred
        }

        $OSVersion = (Get-WmiObject @os_params).version 

        # If we did not get anything, ie not client computer bail out.
        if (!$OSVersion) {
            return
        }

        $OS = $OSVersion.split(".")
    
        # Get the Antivirus product information
        $params = @{
            'ComputerName' = $Computer;
            'Class' = 'AntivirusProduct';
            'ErrorAction' = 'Stop'
        }

        if ($OS[0] -eq "5") {
            $params.Namespace = 'root\SecurityCenter'
        }
        else {
            $params.Namespace = 'root\SecurityCenter2'
        }

        # If we are going to use alternate credentials to access the computer then supply it

        if($cred) {
            $params.Credential = $cred
        }


        $AntiVirusProduct = Get-WmiObject  @params

        if ($AntiVirusProduct) {

            #The values in this switch-statement are retrieved from the following website: http://community.kaseya.com/resources/m/knowexch/1020.aspx 

     }
     catch {
       $ExceptionMessage = $_ | format-list -force
     }
     

}
else {
  
  "Could not connect to computer $Computer...`r`n" 


}
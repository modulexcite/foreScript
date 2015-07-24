﻿# -----------------------------------------------------------------------------------------
# Script: Get-InstalledProduct.ps1
# Author: Nigel Thomas
# Date: May 4, 2015
# Version: 1.0
# Purpose: This script is used query the status of an installed product on desktop computers
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

        

        $opt = New-CimSessionOption -Protocol DCOM

        # Get the OS version for client computers.
        # ProductType = 1 designate a desktop computer
        $os_params = @{
            'Class' = 'Win32_OperatingSystem ';
            'CimSession' = $csd;
            'Filter' = 'ProductType = "1"';
            'ErrorAction' = 'Stop'
        }


        $OSVersion = (Get-CimInstance @os_params).version 

        # If we did not get anything, ie not client computer bail out.
        if (!$OSVersion) {
            return
        }

    
        # We are going to use the System.Management classes to get the product instead of the
        # Win32_product class. This is because the Win32_Product class is going to enumerate 
        # all of the installed products on the computer and run the reconfigure option on all of them.
        # This will slow down getting the product information and the reconfiguration of sofwtare on production
        # computers could be an issue

        # Code based on http://stackoverflow.com/questions/327650/wmi-invalid-class-error-trying-to-uninstall-a-software-on-remote-pc
        $connoptions = New-Object System.Management.ConnectionOptions

        if ($cred) {

            $networkCred = $cred.GetNetworkCredential()
            $connoptions.Username=$networkCred.Domain.ToString() + "\" + $networkCred.UserName.ToString()
        }
        

        #$InstalledProduct

        if ($InstalledProduct) {

     }
     catch {
  
       if ($_.Exception.InnerException) {
       
     }
     

}
else {
  
  "Could not connect to computer $Computer...`r`n" 


}
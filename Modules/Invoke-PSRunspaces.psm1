﻿# -----------------------------------------------------------------------------------------
# Script: Invoke-PSRunspaces.psm1
# Author: Nigel Thomas
# Date: April 24, 2015
# Version: 1.0
# Purpose: This module contains the functions that are used to execute the Poershell scripts
#
# Project: foreScript
#
# -----------------------------------------------------------------------------------------
#
# (C) Nigel Thomas, 2015
#
#------------------------------------------------------------------------------------------

$HelperFunctions = {

    function Format-FSTypes {
        [CmdletBinding()]
        Param(
            [Parameter(Position=0,Mandatory=$True)]
            [ValidateNotNullOrEmpty()]
            $InputObject,

            [Parameter(Position=1,Mandatory=$True)]
            [ValidateNotNullOrEmpty()]
            $Type,
            $Header)


        #try {
        
            # Set the working directory to the startup path of the script
            #$StartupLocation = Split-Path $script:MyInvocation.MyCommand.Path
            #$StartupLocation
            Set-Location $StartupLocation
            [System.IO.Directory]::SetCurrentDirectory($StartupLocation)

            Import-Module -Name ".\Types\$Type-Type.psm1"

            # Load the type mappings
            $typemap = (Get-Content  '.\Config\fstypes.json' -Raw).ToString().Trim() | ConvertFrom-Json
            #$typemap
            $output = $null

            foreach ($map in $typemap.Types) { 
                if ($map.Name -match $Type) {
                     #$map
                    $output = &$map.format -InputObject $InputObject -StartupLocation $StartupLocation
                }
            }
   
            Remove-Module -Name ".\Types\$Type-Type.psm1" | Out-Null
            return $output
        <#}
        catch {
            if ($_.Exception.InnerException) {

            $ExceptionMessage
        }#>
 
    
    }


}

$DoImpersonation = {

        $Login_Impersonation = @'
namespace LOGIN_IMPERSONATION
{
    #region Using directives.
    // ----------------------------------------------------------------------

    using System;
    using System.Security.Principal;
    using System.Runtime.InteropServices;
    using System.ComponentModel;

    // ----------------------------------------------------------------------
    #endregion

    /////////////////////////////////////////////////////////////////////////

    /// <summary>
    /// Impersonation of a user. Allows to execute code under another
    /// user context.
    /// Please note that the account that instantiates the Impersonator class
    /// needs to have the 'Act as part of operating system' privilege set.
    /// </summary>
    /// <remarks>   
    /// This class is based on the information in the Microsoft knowledge base
    /// article http://support.microsoft.com/default.aspx?scid=kb;en-us;Q306158
    /// 
    /// Encapsulate an instance into a using-directive like e.g.:
    /// 
    ///     ...
    ///     using ( new Impersonator( "myUsername", "myDomainname", "myPassword" ) )
    ///     {
    ///         ...
    ///         [code that executes under the new context]
    ///         ...
    ///     }
    ///     ...
    /// 
    /// Please contact the author Uwe Keim (mailto:uwe.keim@zeta-software.de)
    /// for questions regarding this class.
    /// </remarks>
    public class Impersonator :
        IDisposable
    {
        #region Public methods.
        // ------------------------------------------------------------------

        /// <summary>
        /// Constructor. Starts the impersonation with the given credentials.
        /// Please note that the account that instantiates the Impersonator class
        /// needs to have the 'Act as part of operating system' privilege set.
        /// </summary>
        /// <param name="userName">The name of the user to act as.</param>
        /// <param name="domainName">The domain name of the user to act as.</param>
        /// <param name="password">The password of the user to act as.</param>
        public Impersonator(
            string userName,
            string domainName,
            string password)
        {
            ImpersonateValidUser(userName, domainName, password);
        }

        // ------------------------------------------------------------------
        #endregion

        #region IDisposable member.
        // ------------------------------------------------------------------

        public void Dispose()
        {
            UndoImpersonation();
        }

        // ------------------------------------------------------------------
        #endregion

        #region P/Invoke.
        // ------------------------------------------------------------------

        [DllImport("advapi32.dll", SetLastError = true)]
        private static extern int LogonUser(
            string lpszUserName,
            string lpszDomain,
            string lpszPassword,
            int dwLogonType,
            int dwLogonProvider,
            ref IntPtr phToken);

        [DllImport("advapi32.dll", CharSet = CharSet.Auto, SetLastError = true)]
        private static extern int DuplicateToken(
            IntPtr hToken,
            int impersonationLevel,
            ref IntPtr hNewToken);

        [DllImport("advapi32.dll", CharSet = CharSet.Auto, SetLastError = true)]
        private static extern bool RevertToSelf();

        [DllImport("kernel32.dll", CharSet = CharSet.Auto)]
        private static extern bool CloseHandle(
            IntPtr handle);

        private const int LOGON32_LOGON_INTERACTIVE = 2;
        private const int LOGON32_LOGON_NEW_CREDENTIALS = 9;
        private const int LOGON32_PROVIDER_DEFAULT = 0;

        // ------------------------------------------------------------------
        #endregion

        #region Private member.
        // ------------------------------------------------------------------

        /// <summary>
        /// Does the actual impersonation.
        /// </summary>
        /// <param name="userName">The name of the user to act as.</param>
        /// <param name="domainName">The domain name of the user to act as.</param>
        /// <param name="password">The password of the user to act as.</param>
        private void ImpersonateValidUser(
            string userName,
            string domain,
            string password)
        {
            WindowsIdentity tempWindowsIdentity = null;
            IntPtr token = IntPtr.Zero;
            IntPtr tokenDuplicate = IntPtr.Zero;

            try
            {
                if (RevertToSelf())
                {
                    if (LogonUser(
                        userName,
                        domain,
                        password,
                        LOGON32_LOGON_NEW_CREDENTIALS,
                        LOGON32_PROVIDER_DEFAULT,
                        ref token) != 0)
                    {
                        if (DuplicateToken(token, 2, ref tokenDuplicate) != 0)
                        {
                            tempWindowsIdentity = new WindowsIdentity(tokenDuplicate);
                            impersonationContext = tempWindowsIdentity.Impersonate();
                        }
                        else
                        {
                            throw new Win32Exception(Marshal.GetLastWin32Error());
                        }
                    }
                    else
                    {
                        throw new Win32Exception(Marshal.GetLastWin32Error());
                    }
                }
                else
                {
                    throw new Win32Exception(Marshal.GetLastWin32Error());
                }
            }
            finally
            {
                if (token != IntPtr.Zero)
                {
                    CloseHandle(token);
                }
                if (tokenDuplicate != IntPtr.Zero)
                {
                    CloseHandle(tokenDuplicate);
                }
            }
        }

        /// <summary>
        /// Reverts the impersonation.
        /// </summary>
        private void UndoImpersonation()
        {
            if (impersonationContext != null)
            {
                impersonationContext.Undo();
            }
        }

        private WindowsImpersonationContext impersonationContext = null;

        // ------------------------------------------------------------------
        #endregion
    }

    /////////////////////////////////////////////////////////////////////////
}


'@

    try {

        if ($Impersonator) {
            $Impersonator.Dispose()
        }
        

        if (($PSBoundParameters.ContainsKey('UserName')) -and ($PSBoundParameters.ContainsKey('Password'))) {

            Add-Type -TypeDefinition $Login_Impersonation
            
            $impersonatepassword = ConvertTo-SecureString $Password -AsPlainText -Force
            $impersonatecred = New-Object -typename System.Management.Automation.PSCredential -argumentlist $UserName, $impersonatepassword
            $networkCred = $impersonatecred.GetNetworkCredential()
            $Impersonator = New-Object LOGIN_IMPERSONATION.Impersonator($networkCred.UserName.ToString(), $networkCred.Domain.ToString(), $networkCred.Password)

        }
    }
    catch {
          $ExceptionMessage = $_ | format-list -force
    }

}

$DoCredential = {

     try {


        if (($PSBoundParameters.ContainsKey('UserName')) -and ($PSBoundParameters.ContainsKey('Password'))) {
            
            $secpassword = ConvertTo-SecureString $Password -AsPlainText -Force
            $cred = New-Object -typename System.Management.Automation.PSCredential -argumentlist $UserName, $secpassword

        }

        if (($PSBoundParameters.ContainsKey('UserName')) -and ($PSBoundParameters.ContainsKey('Password'))) {
            
            $secpassword = ConvertTo-SecureString $Password -AsPlainText -Force
            $FS_Credential = New-Object -typename System.Management.Automation.PSCredential -argumentlist $UserName, $secpassword

        }

    }
    catch {
        $ExceptionMessage = $_ | format-list -force
    }
}


function Execute-AsyncRunspaces {

    [CmdletBinding()]
    Param (

        [Parameter(Position=0,Mandatory=$True,ValueFromPipeline=$True)]
        [ValidateNotNullOrEmpty()]
        [Alias('IPAddress', 'Server', 'Computer', 'ComputerName')]
        [PSObject[]]$InputObject,

        [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()]
        [String]$InputScriptBlock,


        [Parameter(Mandatory=$false)]
        [int]$MaxRunspaces=20,

        [Parameter(Mandatory=$false)]
        $UserName,

        [Parameter(Mandatory=$false)]
        $Password,

        [Parameter(Mandatory=$false)]
        $AuthenticationType,

        [Parameter(Mandatory=$false)]
        $StartupLocation,

        [Parameter(Mandatory=$false)]
        $CallBackParams,

        [switch]$DoCallBack
    )

    BEGIN {

        try {

        
            $RunspaceThreads = @()

            $ScriptBlock = [ScriptBlock]::Create($InputScriptBlock)
            }

            #$ScriptBlock
            #$PSBoundParameters

            $InitialSessionState = [System.Management.Automation.Runspaces.Initialsessionstate]::CreateDefault()
            $RunspacePool = [Runspacefactory]::CreateRunspacePool(1, $MaxRunspaces, $InitialSessionState, $Host)
            $RunspacePool.ApartmentState = 'STA'
            #$RunspacePool.ThreadOptions = 'UseCurrentThread'
            $SS_StartupLOcation = New-Object System.Management.Automation.Runspaces.SessionStateVariableEntry("StartupLocation", $StartupLocation, "")
		    $RunspacePool.InitialSessionState.Variables.Add($SS_StartupLOcation)
            $RunspacePool.Open()


        }
        catch {

            $ExceptionMessage = $_ | format-list -force
        }
    }

    PROCESS {

        try {

            foreach ($Computer in $InputObject) {

                if ($Computer -eq $null) {
                    continue
                }

                if ([String]::IsNullOrEmpty($Computer)) {
                    continue
                }

                if ([String]::IsNullOrWhiteSpace($Computer)) {
                    continue
                }

                if (($PSBoundParameters.ContainsKey('UserName')) -and ($PSBoundParameters.ContainsKey('Password'))) {

                    $powershell = [Powershell]::Create().AddScript($ScriptBlock).AddArgument($Computer).AddArgument($UserName).AddArgument($Password).AddArgument($CallBackParams).AddArgument($DoCallBack)
                }
                else {

                    $powershell = [Powershell]::Create().AddScript($ScriptBlock).AddArgument($Computer).AddArgument($CallBackParams).AddArgument($DoCallBack)
                }

                $powershell.RunspacePool = $RunspacePool

                [Collections.Arraylist]$RunspaceThreads += New-Object PSObject -Property @{
                }
            }
        }
        catch {
            $ExceptionMessage = $_ | format-list -force
        }
    }

    END {

        try {

            $RunspacePool.Close()
        }
        catch {
            $ExceptionMessage = $_ | format-list -force
        }
        <#finally {

            try {

                foreach ($RunspaceThread in $RunspaceThreads) {
            }
            catch {

                if ($_.Exception.InnerException) {

                $ExceptionMessage

            }
        }#>
    }
}
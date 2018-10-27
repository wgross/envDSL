function Test-AdminUser {
    process {
        (New-Object System.Security.Principal.WindowsPrincipal([System.Security.Principal.WindowsIdentity]::GetCurrent())).IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)
    }
}

function elevated {
    <#
    .SYNOPSIS
        Runs a scriptblock in an elevated shell
    .DESCRIPTION
        A given script block is executed in a an elevated powershell, if the current host isn't elevated.
        The elevated shell location is moved to the current directory. A profiole isn't loaded for the 
        elevated shell because of performance reasons.
        The output of the shell is captured and exported as CLI-Xml to a temorary file and imported by the 
        original shell after the the elevated process ended.
    .EXAMPLE 
        Runs a elevated explorer in current directory
        elevated { ii . }
    .LINK 
        Based on http://blogs.msdn.com/b/virtual_pc_guy/archive/2010/09/23/a-self-elevating-powershell-script.aspx
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false,Position=0)]
        [scriptblock]$ContinueWith
    )
    process {
        if (Test-AdminUser) {

            Write-Verbose "Host is already elevated..."
            if($ContinueWith) {
                $ContinueWith.InvokeReturnAsIs()
            }

        } else {

            # Start scriptblock in elevated process
            Write-Verbose "Host isn't elevated yet. Starting elevated process."
            
            if($ContinueWith) {

                # Start script block execution at current location. All generated obejcts are exported to temporary file
                $tempFileName = [System.IO.Path]::GetTempFileName();  
                $commandString = "Push-Location {0}; {{ {1} }}.InvokeReturnAsIs() | Export-Clixml -Path {2}; Pop-Location" -f $PWD,$ContinueWith.ToString(),$tempFileName
            
                Write-Verbose "Executing script block in $PWD and storing results temporarily in $tempFileName"
                Write-Verbose "Executed command is: $commandString"

                Start-Process "powershell" `
                    -ArgumentList @("-noprofile","-Command",$commandString) `
                    -Verb runas `
                    -WindowStyle Hidden `
                    -Wait 
                    # has no effect: # -WorkingDirectory $PWD

                # Now read temorary file and show them in shell
                Write-Verbose "Import8ing results from $tempFileName"
            
                if(Test-Path $tempFileName) {
                if((Get-Item $tempFileName).Length -gt 0 ) {
                    # read output from eleveted shell as powershell objects
                    Import-Clixml -Path $tempFileName -ErrorAction SilentlyContinue
                }
                # clean up existing temp file
                Remove-Item $tempFileName | Out-Null
            }

            } else {

                # no script block given. Just start shell
                Start-Process "powershell" -Verb runas 
            }
        }
    }
}

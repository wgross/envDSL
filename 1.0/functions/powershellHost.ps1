function powershellHost {
    <#
    .SYNOPSIS
        Executes a script block if Get-Host is of the given type.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Position=0,ParameterSetName="byKnownHostname")]
        [ValidateSet("Console","ISE","VStudio","PowerShellServer")]
        [string[]]$KnownName,
        [Parameter(Mandatory=$true,Position=1)]
        [scriptblock]$ContinueWith
    )
    process {
        $run = $false

        switch($PSCmdlet.ParameterSetName) {
            "byKnownHostname" {
                $KnownName | ForEach-Object { 
                    switch($_) {
                        "Console" {
                            if((Get-Host).Name -eq "ConsoleHost") {
                                $run = $true
                            } 
                        }
                        "ISE" {
                            if((Get-Host).Name -eq "Windows PowerShell ISE Host") {
                                $run = $true
                            } 
                        }
                        "VStudio" {
                            if((Get-Host).Name -eq "PowerShell Tools for Visual Studio Host") {
                                $run = $true
                            }
                        }
                        "PowerShellServer" {
                            if((Get-Host).Name -eq "PowerShell Server") {
                                $run = $true
                            }
                        }
                    }
                }
            }
        }

         if($run) {
            return $ContinueWith.InvokeReturnAsIs()
        } else {
            Write-Verbose "Skipped execution of powershellHost specific code host=$((Get-Host).Name)`: $($ContinueWith.ToString())"
        }
    }
}



function Add-EnvPath {
    <#
    .SYNOPSIS
        Adds the specified pathes to $Env:PATH if it doesn't already contain the pathes.
    .DESCRIPTION
        If an array is specified the relative order is optained. 
    #>
    param(
        [Parameter(Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [string[]]$Prepend,

        [Parameter(Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [string[]]$Append
    )
    process {
        [System.Collections.Generic.List[string]]$splitted = [System.Linq.Enumerable]::ToList(($env:Path -split ";"))
        if($Append) {
            $Append | ForEach-Object {
                if($splitted.Contains($_)) {
                    $splitted.Remove($_) | Out-Null
                    Write-Verbose "Removed before adding $_"
                }
                if($splitted -notcontains $_) {
                    $splitted.Add($_) | Out-Null
                    Write-Verbose "Added at the end $_"
                }
            }
        }
        if($Prepend) {
            # Revert the array to start prepending with the last element
            # ==> The relative order is obtained because the first item is prepended as the last and is 
            #     therefore the first in the result path
            [array]::Reverse($Prepend)
            $Prepend | ForEach-Object {
                if($splitted.Contains($_)) {
                    $splitted.Remove($_) | Out-Null
                    Write-Verbose "Removed before adding $_"
                }
                if($splitted -notcontains $_) {
                    $splitted.Insert(0,$_) | Out-Null
                    Write-Verbose "Added in front $_"
                }
            } 
        }
        $env:Path = [string]::Join(";",($splitted | Where-Object { ![string]::IsNullOrWhiteSpace($_) }))
    }
}

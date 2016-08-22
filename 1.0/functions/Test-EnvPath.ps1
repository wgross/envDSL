function Test-EnvPath {
    $env:Path -split ";" | ForEach-Object {
        [pscustomobject]@{
            Path = "$_"
            Exists = (Test-Path $_)
        }   
    }
}
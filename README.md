# envDSL
Powershell module providing a simple DSL to implement profiles depending on attributes of the current execution environment like computer name and powershell host name. 

## Execute Code Depending on the Computer Name

```
computer "computer Name" {
  # execute this code only on computer "computer name"
  ...
}
```
The name of the computer is determined by reading the environment variable 'COMUTERNAME' on windows or, if avaliable by calling '/bin/hostname -s'

## Excecute Code Depending on the Powershell Host Name

```
powershellHostname "ConsoleHost" {
    # Execute ths code only in console code.
    ...
}
```
The name of the console ist taken from (Get-Host).Name. This should be compatibel with all platforms Core and classic .Net.

##  Guard Code which needs Admin Rights

```
if(Test-AdminUser) {
  # do what only an admin can do
  ...
}
```
This Cmdlet look at current windows pricipal to determin Admin rights. 

## Manipulate Path Variables

```
Add-EnvPath -Path Env:\Path -Append "c:\tools\bin"
```

this Cmdlet can append or prepend directory names (or lists of directory name) to the specified path-variable. pThaes are sepearted by ';'.
If a path with the same name is already contains in the list of directories from teh variable, it ist removed and appended/prepended again.

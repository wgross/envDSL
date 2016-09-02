# envDSL

Powershell module providing a simple DSL to implement profiles depending on attributes of the current execution environment like computer name and powershell host name. It also provides a Cmdlet Edit-PathVariableContent to change a the content of a variable holding a collection of pathes separated with ';' or ':' alternatively.

## Execute Code Depending on the Computer Name

```
computer "computer Name" {
  # execute this code only on computer "computer name"
  ...
}
```
The name of the computer is determined by reading the System.Environment.MachineName property.

## Excecute Code Depending on the Powershell Host Name

```
powershellHostname "ConsoleHost" {
    # Execute ths code only in console code.
    ...
}
```
The name of the console ist taken from (Get-Host).Name. This should be compatible with all platforms: Core and classic .Net.

##  Guard Code which needs Admin Rights

```
if(Test-AdminUser) {
  # do what only an admin can do
  ...
}
```
This Cmdlet look at current windows principal to determine Admin rights. Obvioulsy this is not working on .Net Core.

## Manipulate Path Variables

```
Edit-PathVariableContent -Path Env:\Path -Append "c:\tools\bin"
```

this Cmdlet can append or prepend directory names (or lists of directory names) to the specified path-variable. Pathes are separted by ';' or ':' on unix.
If a path with the same name is already contained in the list of directories of the variable, it ist removed and appended/prepended again.

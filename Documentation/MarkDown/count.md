# count.psm1

## summary

To create a `Quick-CountLines` alias for backward compatibility, you can use the following code:

```powershell
New-Alias -Name Quick-CountLines -Value Measure-CodeLines -Force
```

This will add a new alias named `Quick-CountLines` that references the `Measure-CodeLines` function.
You can then call this function to count lines of code, just like you would call the original `Measure-CodeLines` function.

For example:

```powershell
$code = Get-Help -Module TestModule -Name Measure-CodeLines | Out-File -FilePath quick-count-lines.txt
```

This will save a file named `quick-count-lines.txt` containing the result of calling `Measure-CodeLines`. You can then use this alias to count lines of code in your scripts and files:

```powershell
Quick-CountLines $code
```

Note that I've assumed you're using PowerShell 3 or later, as there's a limitation with the syntax for aliases when using newer versions.

# Build.psm1

## Structure: PowerShell Script for Building and Compiling Projects

The `build` library is a PowerShell script designed to automate the process of building and compiling projects.
It supports various  programming languages, including C++, C#, and Python.

## Key Features and Capabilities

- Automates the build process by reading project settings from a configuration file.

- Supports multiple programming languages with their respective compilers.

- Handles compilation errors and provides error messages for each language.

- Uses a built-in logging mechanism to track the build process.

- Includes support for source files, object files, and executable files.

## Objects & Data Structures

### `Build` Class

#### Members

| Member | Type | Description |
|--------|------|-------------|
| $projectPath | string | Project path. |
| $language | string | Programming language to be used in the build process. |
| $compiler | string | Compiler to be used for building the project. |
| $includePaths | array[string] | List of include paths for different languages. |
| $sourcePaths | array[string] | List of source file paths for different languages. |

### `TargetConfig` Object

#### Members

| Member | Type | Description |
|--------|------|-------------|
| $target | string | Target project name or configuration key. |
| $config | hashtable | Configuration settings for the target project. |

## Functions

### `SetProjectName` Function

**Description:** Sets the project name.
**Parameters:**

- $name (string): Project name to be set.

**Returns:** None

Example:

```powershell
$myBuild = New-Object Build
$myBuild.SetProjectName 'My Project'
```

### `GetProjectName` Function

**Description:** Gets the current project name.
**Returns:** string The current project name.

# PowerDoc.psm1

## Library Overview

PowerDoc is a PowerShell module designed to generate documentation for code files using Ollama.
It supports various output formats, including TXT, MD, Doxygen, and All.

### Key Features and Capabilities

* Supports TXT, MD, Doxygen, and All formats for output
* Uses Ollama for documentation generation
* Allows for recursive processing of folders
* Includes support for different file extensions (e.g., @('.cpp','.h','.ps1'))
* Provides clear and professional language for documentation
* Offers practical usage examples and edge cases
* Enables the creation of Markdown, Plain Text, and Doxygen-style documentation

### Use Cases

* Use PowerDoc to generate documentation for complex software projects or large codebases
* Create custom documentation for specific domains or industries
* Enhance existing documentation with additional details and explanations
* Leverage the flexibility of Ollama to tailor your documentation style and requirements
* Export generated documentation in various formats for sharing or publishing

## Objects & Data Structures

### ObjectName

Brief description of the object:

#### Members

| Member | Type | Description |
|--------|------|-------------|
| member_name | data_type | What this member does |

## Functions

### function_name(parameters)

**Description:** Clear explanation of what the function does.

**Parameters:**

* `param1 (type)`: Description
* `param2 (type)`: Description

**Returns:** Description of return value and type

**Example:**

```powershell
# Invoke-AutoDoc -Path ".\main.cpp" -OutputFormat "doxygen"
```

Usage example:

* Import the PowerDoc module
* Set the Ollama model to use for documentation generation
* Generate documentation for a specific file or folder

Make sure to:

* Use clear, professional language
* Include all objects and functions found in the code
* Provide practical usage examples
* Document edge cases and important notes

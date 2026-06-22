# PowerTest.psm1

## Comprehensive Test Generation Module

This PowerShell module provides a comprehensive test generation tool for various programming languages, frameworks, and libraries.

### Library Overview

The PowerTest.psm1 library is designed to generate high-quality test cases for libraries and frameworks.
It covers all public functions from the documentation and includes positive and negative test cases to ensure thorough coverage of the code.

### Framework-Specific Prompt

To use this module, you need to specify the framework and language used in your library code.
The `Get-FrameworkSpecificPrompt` function returns a detailed user prompt that includes information about the library's API, functions, and testing philosophy.

### Test Generation Process

1. Read documentation: The module reads the provided documentation file.
2. Read library code: It reads the library code from the specified location or URL.
3. Generate tests: Based on the documented functions and library code, it generates comprehensive test cases for each function.
4. Output files: The generated test code is saved in various formats (C#, C++, Java, Python, PowerShell, JavaScript, TypeScript).
5. Save output: Depending on the provided options, the module saves the generated tests to a file or overwrites an existing one.

### Test Code

The generated test code is written in a specific style and includes:

* Positive test cases for expected behavior
* Negative test cases for error handling and edge cases
* Clear and descriptive test names that explicitly indicate what's being tested
* Inline comments explaining complex logic
* Comprehensive coverage of all functions from the documentation

### API Documentation

The `New-Test` function takes several parameters, including:

* The library name or URL
* The output file location (optional)
* The testing framework and language (required)

The module supports various frameworks and languages, such as C#, Java, Python, PowerShell, JavaScript, and TypeScript.

## Default Usage

You can use the PowerTest.psm1 module in your scripts by running `New-Test` with the required parameters. For example:

```powershell
# Generate tests for a library using C#
New-Test -LibraryName "MyLibrary" -OutPath "C:\GeneratedTests\" -Framework "csharp"

# Generate tests for a library using Python
New-Test -LibraryName "MyLibrary" -OutputFile "generated_tests.py" -Framework "python"

```

Note: Make sure to replace the placeholder values with your actual library name, output file location (if provided), and testing framework/ language.

## Troubleshooting

If you encounter any issues during test generation or execution, check the following:

* Ensure that Ollama is running on your local machine.
* Verify that the API endpoint for the specified framework is available.
* Check the generated tests for errors in formatting or syntax.

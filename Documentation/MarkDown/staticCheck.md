# `staticCheck.bash` Library Overview

## Description

The `staticCheck.bash` library is a comprehensive tool for checking C++ code against a set of predefined rules and standards.
It provides a convenient interface to perform code reviews, ensuring that the code meets the required standards.

## Key Features and Capabilities

* Checks for common coding mistakes and warnings
* Enforces style and naming conventions
* Detects missing includes and headers
* Suppresses specific warnings and errors

## Objects & Data Structures

### `ccheck_lib` Struct

#### Members

| Member | Description |
|--------|-------------|
| `includes`| A list of directories containing include files to check against |
| `target` | The output file or directory where the checks will be written |

## Functions

### `ccheck_lib()`

**Description:** Performs a full code review on the provided input, applying the rules and standards defined in this library.

**Parameters:**

* `includes`: A list of directories containing include files to check against (default: empty)
* `target`: The output file or directory where the checks will be  written (default: `/dev/null`)

**Returns:** The number of warnings and errors found during the review

**Example:**

```c

#include <iostream>
using namespace std;

int main() {
    ccheck_lib("/usr/include", "/tmp/output");
    return 0;
}

```

### `cxxcheck_lib()` (C++ version)

This function is similar to the previous one, but it uses C++11 style directives and is designed for C++ code.

### `cppcheck_lib()` (Command-line tool)

This function provides a simple command-line interface for checking C++ code.
It takes the input file(s) and output file/directory as arguments.

## Use Cases

* Writing code that adheres to standard practices and coding conventions
* Ensuring compliance with specific project or company standards
* Automating code reviews using a tool like `ccheck_lib` or `cxxcheck_lib`

## Example Usage

```c

// Simple C++ program to test ccheck_lib
#include <iostream>
using namespace std;

int main() {
    cout << "Hello, World!" << endl;
    return 0;
}

```

To use the command-line tool, save the code in a file called `example.cpp` and run:

```bash
cppcheck_lib example.cpp /dev/null
```

This will write the checked output to `/dev/null`, indicating that the code passed all checks.

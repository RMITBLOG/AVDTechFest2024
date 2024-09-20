## Overview

This PowerShell script analyzes an **MSIX package** by unzipping it, reading the `AppxManifest.xml`, listing its contents, and providing a detailed summary of the package configuration. It also leverages **AI-based assessments** using either **Azure OpenAI** or **EtherAssist.AI** to highlight potential best practice deviations, security risks, and recommendations for improvement.

### Supported AI Assessment Services

1. **Azure OpenAI**: Uses Azure OpenAI services to perform in-depth analysis of the MSIX package.
2. **EtherAssist.AI**: Utilizes EtherAssist's advanced AI to provide operational insights and IT compliance checks on the MSIX package.

## Prerequisites

- **Azure OpenAI Access** (optional): Required if using Azure OpenAI for the analysis.
- **EtherAssist.AI Access** (optional): Required if using EtherAssist for the analysis.
- **PowerShell**: Ensure PowerShell is installed on your system.
- **API Keys**: Store your Azure OpenAI and EtherAssist API keys as environment variables.

## Setup

### 1. Install Required Tools

Ensure you have the following prerequisites:
- PowerShell installed.
- **Azure OpenAI** or **EtherAssist.AI** API access (or both if desired).

### 2. Configure API Keys

Before running the script, store your API keys in environment variables as follows:

- **Azure OpenAI**:
  ```powershell
  $env:OPENAI_API_KEY = "your-api-key-here"
  ```

- **EtherAssist.AI**:
  ```powershell
  $env:ETHERASSIST_API_KEY = "your-etherassist-api-key-here"
  ```

### 3. Modify the Script for Your Environment

Update the script configuration:
- Set the AI service you wish to use (`AzureOpenAI` or `EtherAssist`) by modifying the `$aiService` variable.
- Update your **Azure OpenAI** deployment name, API version, and endpoint URL.
- Ensure that your MSIX file path is correctly set (or passed as a parameter).

## Running the Script

Once everything is configured, you can run the script from PowerShell:

```powershell
.\Analyze-MSIX-With-AI.ps1 -msixPath "C:\path\to\your\msix-package.msix"
```

This will:
1. Unzip the MSIX package.
2. List the contents of the unzipped package.
3. Read and analyze the `AppxManifest.xml`.
4. Perform an AI-based assessment using either Azure OpenAI or EtherAssist, depending on your selection.
5. Display the AI-generated recommendations and insights in the console.

## Example Output

Here is an example of what the output might look like:

```plaintext
📦 **Info:** Unzipping MSIX package: 'C:\temp\msix-hero-3.0.0.0.msix'
✅ **Success:** Unzipped successfully to 'C:\temp\unzip_msix_package'.

📂 **Contents of the unzipped MSIX package:**
    Directory: C:\temp\unzip_msix_package

Mode                LastWriteTime     Length Name
----                -------------     ------ ----
d----          09/20/2024  02:30 PM           App
-a---          09/20/2024  02:30 PM     1024 AppxManifest.xml
-a---          09/20/2024  02:30 PM    20480 OtherFiles...

📄 **Info:** Reading and analyzing AppxManifest.xml...

📝 **AppxManifest Summary:**
### Package Identity
- **Name**: msix-hero
- **Version**: 3.0.0.0
- **Publisher**: CN=MsixHeroPublisher
- **Architecture**: x64

### Capabilities
- internetClient
- broadFileSystemAccess

### Applications/Entry Points
- **ID**: msix-hero.exe
  - **Executable**: msix-hero.exe
  - **Display Name**: MSIX Hero Application
  - **Description**: A powerful MSIX packaging tool.
  - **Logo**: Assets\Logo.png

### Dependencies
- **Package Family Name**: Microsoft.VCLibs.140.00
  - **Min Version**: 14.0.24215.0

🤖 **Info:** Sending the manifest summary to AzureOpenAI for assessment...

📝 **AI-Assisted Assessment:**
The MSIX Hero package is configured with the following characteristics:

- **Package Identity**: Properly defined with a valid name, version, publisher, and architecture.
- **Capabilities**: Grants `internetClient` and `broadFileSystemAccess`, which could pose security risks if not necessary.
- **Applications/Entry Points**: Clearly defined with executable details and associated assets.

**Recommendations**:
- **Review File System Access**: Ensure `broadFileSystemAccess` is necessary. Limit access to specific directories where possible.
- **Secure Full Trust Processes**: Validate the integrity of `msix-hero.exe`. Implement code signing and regular security audits.
```

![image](https://github.com/user-attachments/assets/b9a17b7a-05f4-4c64-b55a-b998771357d3)


## Script Breakdown

### Key Functions

- **Analyze-AppxManifest**: This function parses the `AppxManifest.xml` file from the MSIX package and extracts information like package identity, capabilities, entry points, extensions, dependencies, and resources.
- **Get-AIAssessment**: This function sends the extracted manifest information to either **Azure OpenAI** or **EtherAssist** for analysis, depending on your configuration.
- **Main Execution**: Handles unzipping the MSIX package, reading the manifest, and presenting AI-generated recommendations.

### Customization Options

- **AI Service Selection**: Modify the `$aiService` variable to choose between `AzureOpenAI` or `EtherAssist`.
  ```powershell
  $aiService = "AzureOpenAI"  # Options: "AzureOpenAI", "EtherAssist"
  ```

- **MSIX Path**: You can specify the path to your MSIX package when running the script.
  ```powershell
  .\Analyze-MSIX-With-AI.ps1 -msixPath "C:\path\to\msix-package.msix"
  ```

- **AI Configuration**: Set your Azure OpenAI or EtherAssist endpoint and API keys as environment variables before running the script.

## Security Considerations

- **API Keys**: Always store API keys in environment variables instead of hardcoding them in the script.
- **Package Sensitivity**: Ensure that any MSIX packages you are analyzing do not contain sensitive information. Follow best practices for handling and securing package contents.

## Troubleshooting

- **Missing API Key**: If the API key for Azure OpenAI or EtherAssist is not found, the script will exit and prompt you to set the necessary environment variable.
- **MSIX File Not Found**: If the MSIX file path is incorrect, the script will notify you and exit.
- **Invalid AI Service**: If an invalid AI service is selected, the script will exit with an error.

## Conclusion

This **MSIX Package Analyzer** simplifies the process of reviewing and assessing MSIX packages by leveraging AI services such as **Azure OpenAI** or **EtherAssist**. It provides valuable insights into package configuration, highlights potential risks, and offers actionable recommendations.

By using this script, you can automate the process of analyzing MSIX packages and ensure that they adhere to security and best practice standards.

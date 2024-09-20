
 $env:OPENAI_API_KEY = "<Enter>"

 # -----------------------------
# MSIX Package Analyzer with AI Assessment (Azure OpenAI or EtherAssist)
# -----------------------------

param (
    [string]$msixPath = "C:\temp\msix-hero-3.0.0.0.msix"
)

# -----------------------------
# Configuration Section
# -----------------------------

<#
.SYNOPSIS
    Analyzes an MSIX package by unzipping it, listing its contents, reading the AppxManifest.xml, and providing a comprehensive summary along with AI-assisted assessments.

.DESCRIPTION
    This script unzips an MSIX package, lists its folder contents, reads the AppxManifest.xml, summarizes the package configuration, and uses either Azure OpenAI or EtherAssist to assess best practices compliance and potential risks.

.EXAMPLE
    .\Analyze-MSIX-With-AI.ps1 -msixPath "C:\temp\msix-hero-3.0.0.0.msix"
#>

# -----------------------------
# AI Service Selection
# -----------------------------
# Choose the AI service to use for assessment. Set to either "AzureOpenAI" or "EtherAssist".
$aiService = "AzureOpenAI"  # Options: "AzureOpenAI", "EtherAssist"

# -----------------------------
# Azure OpenAI Configuration
# -----------------------------
$deploymentName = "GPT4o"  # Replace with your exact deployment name
$apiVersion = "2024-02-15-preview"  # Use the API version that matches your deployment

# Construct the Azure OpenAI endpoint for Chat Completions
# Construct the Azure OpenAI endpoint for Chat Completions
$openAIEndpoint = "https://<Enterhere>/openai/deployments/$deploymentName/chat/completions?api-version=$apiVersion"

# **Security Best Practice:** 
# Store your API key in an environment variable instead of hardcoding it.
# To set an environment variable in PowerShell, use:
# $env:OPENAI_API_KEY = "your-actual-api-key"
$openAIKey = $env:OPENAI_API_KEY

# -----------------------------
# EtherAssist API Configuration (Optional)
# -----------------------------
# Configure EtherAssist only if you intend to use it. Otherwise, leave the default value.
$etherAssistEndpoint = "https://app.etherassist.ai/api/endpoint"  # Replace with the actual EtherAssist API endpoint
$etherAssistKey = $env:ETHERASSIST_API_KEY  # Store your EtherAssist API key in an environment variable

# -----------------------------
# Validate AI Service Configuration
# -----------------------------
switch ($aiService) {
    "AzureOpenAI" {
        if (-not $openAIKey) {
            Write-Host "🔴 **Error:** OpenAI API key not found. Please set the OPENAI_API_KEY environment variable."
            Write-Host "   Example: `$env:OPENAI_API_KEY = 'your-actual-api-key'"
            exit 1
        }
    }
    "EtherAssist" {
        if (-not $etherAssistKey) {
            Write-Host "🔴 **Error:** EtherAssist API key not found. Please set the ETHERASSIST_API_KEY environment variable."
            Write-Host "   Example: `$env:ETHERASSIST_API_KEY = 'your-etherassist-api-key'"
            exit 1
        }
    }
    default {
        Write-Host "🔴 **Error:** Invalid AI service selected. Choose either 'AzureOpenAI' or 'EtherAssist'."
        exit 1
    }
}

# -----------------------------
# Logging and Output Configuration
# -----------------------------
# Define the path where the unzipped MSIX package will be extracted
$unzipPath = "C:\temp\unzip_msix_package"

# -----------------------------
# Function Definitions
# -----------------------------

# Function to analyze AppxManifest.xml
function Analyze-AppxManifest {
    param (
        [xml]$manifestXml
    )

    $summary = @()

    # 1. Package Identity Information
    $packageIdentity = $manifestXml.Package.Identity
    $summary += "### Package Identity"
    $summary += "- **Name**: $($packageIdentity.Name)"
    $summary += "- **Version**: $($packageIdentity.Version)"
    $summary += "- **Publisher**: $($packageIdentity.Publisher)"
    $summary += "- **Architecture**: $($packageIdentity.ProcessorArchitecture)"
    $summary += ""

    # 2. Capabilities
    $capabilities = $manifestXml.Package.Capabilities.Capability
    if ($capabilities) {
        $summary += "### Capabilities"
        foreach ($capability in $capabilities) {
            $summary += "- **$($capability.Name)**"
        }
    } else {
        $summary += "### Capabilities"
        $summary += "- None"
    }
    $summary += ""

    # 3. Applications/Entry Points
    $applications = $manifestXml.Package.Applications.Application
    if ($applications) {
        $summary += "### Applications/Entry Points"
        foreach ($app in $applications) {
            $summary += "- **ID**: $($app.Id)"
            $summary += "  - **Executable**: $($app.Executable)"
            if ($app.VisualElements) {
                $summary += "  - **Display Name**: $($app.VisualElements.DisplayName)"
                $summary += "  - **Description**: $($app.VisualElements.Description)"
                $summary += "  - **Logo**: $($app.VisualElements.Logo)"
            }
        }
    } else {
        $summary += "### Applications/Entry Points"
        $summary += "- None"
    }
    $summary += ""

    # 4. Extensions
    $extensions = $manifestXml.Package.Applications.Application.Extension
    if ($extensions) {
        $summary += "### Extensions"
        foreach ($extension in $extensions) {
            $summary += "- **Type**: $($extension.Type)"
            $summary += "  - **Entry Point**: $($extension.EntryPoint)"
        }
    } else {
        $summary += "### Extensions"
        $summary += "- None"
    }
    $summary += ""

    # 5. Dependencies
    $dependencies = $manifestXml.Package.Dependencies.Dependency
    if ($dependencies) {
        $summary += "### Dependencies"
        foreach ($dependency in $dependencies) {
            $summary += "- **Package Family Name**: $($dependency.PackageFamilyName)"
            $summary += "  - **Min Version**: $($dependency.MinVersion)"
        }
    } else {
        $summary += "### Dependencies"
        $summary += "- None"
    }
    $summary += ""

    # 6. Resources
    $resources = $manifestXml.Package.Resources.Resource
    if ($resources) {
        $summary += "### Resources"
        foreach ($resource in $resources) {
            $summary += "- **Language**: $($resource.Language)"
        }
    } else {
        $summary += "### Resources"
        $summary += "- None"
    }
    $summary += ""

    # 7. Advanced Capabilities
    $advancedCapabilities = $manifestXml.Package.Capabilities.Capability
    if ($advancedCapabilities) {
        $summary += "### Advanced Capabilities"
        foreach ($capability in $advancedCapabilities) {
            if ($capability.Name -match "broadFileSystemAccess|internetClient|internetClientServer") {
                $summary += "- **$($capability.Name)**"
            }
        }
    }
    $summary += ""

    return $summary -join "`n"
}

# Function to get AI-based assessment from Azure OpenAI
function Get-AIAssessment_OpenAI {
    param (
        [string]$fullOutput
    )

    # Prepare the prompt for OpenAI
    $prompt = @"
You are an expert in application packaging and security best practices. Analyze the following MSIX package configuration and provide a detailed summary of its setup, highlighting any deviations from best practices, potential security risks, and recommendations for improvements.

### MSIX Package Configuration:
$fullOutput

### Analysis and Recommendations:
"@

    # Define the request body
    $body = @{
        "messages" = @(
            @{
                "role" = "system"
                "content" = "You are a security and best practices expert for application packaging and deployment."
            },
            @{
                "role" = "user"
                "content" = $prompt
            }
        )
        "max_tokens" = 2000
        "temperature" = 0.3
        "top_p" = 0.95
    } | ConvertTo-Json -Depth 4

    # Define headers
    $headers = @{
        "Content-Type"  = "application/json"
        "api-key"       = $openAIKey
    }

    # Send the request to Azure OpenAI
    try {
        $response = Invoke-RestMethod -Uri $openAIEndpoint -Method Post -Body $body -Headers $headers
        return $response.choices[0].message.content
    }
    catch {
        Write-Host "🔴 **Error:** Failed to get a response from Azure OpenAI: $_" -ForegroundColor Red
        return $null
    }
}

# Function to get AI-based assessment from EtherAssist
function Get-AIAssessment_EtherAssist {
    param (
        [string]$fullOutput
    )

    # Prepare the prompt for EtherAssist
    $prompt = @"
You are an expert in application packaging and security best practices. Analyze the following MSIX package configuration and provide a detailed summary of its setup, highlighting any deviations from best practices, potential security risks, and recommendations for improvements.

### MSIX Package Configuration:
$fullOutput

### Analysis and Recommendations:
"@

    # Define the request body
    $body = @{
        "messages" = @(
            @{
                "role" = "system"
                "content" = "You are a security and best practices expert for application packaging and deployment."
            },
            @{
                "role" = "user"
                "content" = $prompt
            }
        )
        "max_tokens" = 2000
        "temperature" = 0.3
        "top_p" = 0.95
    } | ConvertTo-Json -Depth 4

    # Define headers
    $headers = @{
        "Content-Type"  = "application/json"
        "api-key"       = $etherAssistKey
    }

    # Send the request to EtherAssist
    try {
        $response = Invoke-RestMethod -Uri $etherAssistEndpoint -Method Post -Body $body -Headers $headers
        return $response.choices[0].message.content
    }
    catch {
        Write-Host "🔴 **Error:** Failed to get a response from EtherAssist: $_" -ForegroundColor Red
        return $null
    }
}

# Function to get AI-based assessment based on selected AI service
function Get-AIAssessment {
    param (
        [string]$fullOutput
    )

    switch ($aiService) {
        "AzureOpenAI" {
            return Get-AIAssessment_OpenAI -fullOutput $fullOutput
        }
        "EtherAssist" {
            return Get-AIAssessment_EtherAssist -fullOutput $fullOutput
        }
    }
}

# -----------------------------
# Main Script Execution
# -----------------------------

# Ensure the MSIX file exists
if (-not (Test-Path $msixPath)) {
    Write-Host "🔴 **Error:** MSIX file not found at '$msixPath'. Please verify the path and try again." -ForegroundColor Red
    exit 1
}

# 1. Unzip the MSIX package
if (Test-Path $unzipPath) {
    try {
        Remove-Item -Recurse -Force $unzipPath -ErrorAction Stop
        Write-Host "🗑️ **Info:** Removed existing unzipped directory at '$unzipPath'."
    }
    catch {
        Write-Host "🔴 **Error:** Failed to remove existing unzipped directory at '$unzipPath': $_" -ForegroundColor Red
        exit 1
    }
}

try {
    Write-Host "📦 **Info:** Unzipping MSIX package: '$msixPath'" -ForegroundColor Cyan
    Add-Type -AssemblyName 'System.IO.Compression.FileSystem'
    [System.IO.Compression.ZipFile]::ExtractToDirectory($msixPath, $unzipPath)
    Write-Host "✅ **Success:** Unzipped successfully to '$unzipPath'." -ForegroundColor Green
}
catch {
    Write-Host "🔴 **Error:** Failed to unzip the MSIX package: $_" -ForegroundColor Red
    exit 1
}

# 2. List the folder contents
Write-Host "`n📂 **Contents of the unzipped MSIX package:**" -ForegroundColor Yellow
Get-ChildItem -Path $unzipPath -Recurse | Format-List

# 3. Locate and read AppxManifest.xml
$appxManifestPath = Join-Path $unzipPath "AppxManifest.xml"
if (-not (Test-Path $appxManifestPath)) {
    Write-Host "`n🔴 **Error:** AppxManifest.xml not found in the MSIX package!" -ForegroundColor Red
    exit 1
}

# 4. Load and analyze the AppxManifest.xml
try {
    Write-Host "`n📄 **Info:** Reading and analyzing AppxManifest.xml..." -ForegroundColor Cyan
    [xml]$appxManifest = Get-Content $appxManifestPath
    $manifestSummary = Analyze-AppxManifest -manifestXml $appxManifest
    Write-Host "`n📝 **AppxManifest Summary:**" -ForegroundColor Yellow
    Write-Host $manifestSummary -ForegroundColor White
}
catch {
    Write-Host "🔴 **Error:** Failed to read or analyze AppxManifest.xml: $_" -ForegroundColor Red
    exit 1
}

# 5. Gather Full Output for AI Analysis
$fullOutput = $manifestSummary

# 6. Get AI-based assessment
Write-Host "`n🤖 **Info:** Sending the manifest summary to $aiService for assessment..." -ForegroundColor Cyan
$aiAssessment = Get-AIAssessment -fullOutput $fullOutput

if ($aiAssessment) {
    Write-Host "`n📝 **AI-Assisted Assessment:**" -ForegroundColor Green
    Write-Output $aiAssessment
} else {
    Write-Host "`n⚠️ **Warning:** AI Assessment could not be retrieved." -ForegroundColor Yellow
}

# 7. Clean up if necessary
Write-Host "`n✅ **Success:** Analysis complete." -ForegroundColor Green

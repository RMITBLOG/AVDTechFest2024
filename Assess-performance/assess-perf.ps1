 $env:OPENAI_API_KEY = ""

<#
.SYNOPSIS
    Collects and analyzes performance logs for the local AVD session host with AI-assisted diagnostics.

.DESCRIPTION
    This script gathers key performance metrics from the local Azure Virtual Desktop (AVD) session host, identifies potential issues, and utilizes Azure OpenAI to provide intelligent insights and recommended actions.

.EXAMPLE
    .\Collect-PerformanceLogs-AI.ps1
#>

# -----------------------------
# Configuration Section
# -----------------------------

# Clear the console for better readability
cls

# Output Configuration
$outputDirectory = "C:\temp\Performance Counters" # Directory where the result file will be stored.
$computerName = "" # Set the Computer from which to collect counters. Leave blank for local computer.
$sampleInterval = 2 # Collection interval in seconds.
$maxSamples = 8 # Number of samples to collect. Set to 0 for continuous collection.

# Azure OpenAI Configuration
$deploymentName = "GPT4o"  # Replace with your exact deployment name
$apiVersion = "2024-02-15-preview"  # Use the API version that matches your deployment

# Construct the Azure OpenAI endpoint for Chat Completions
$openAIEndpoint = "https://<>/openai/deployments/$deploymentName/chat/completions?api-version=$apiVersion"

# **Security Best Practice:** 
# Store your API key in an environment variable instead of hardcoding it.
# Ensure the environment variable is set before running the script.
$openAIKey = $env:OPENAI_API_KEY

# Validate that the OpenAI API key is set
if (-not $openAIKey) {
    Write-Host "🔴 **Error:** OpenAI API key not found. Please set the OPENAI_API_KEY environment variable."
    Write-Host "   Example: `$env:OPENAI_API_KEY = 'your-actual-api-key'"
    exit 1
}

# -----------------------------
# EtherAssist API Configuration (Optional)
# -----------------------------
# If you plan to use EtherAssist API alongside Azure OpenAI, configure it here.
# Uncomment and set the variables below as needed.

# $etherAssistEndpoint = "https://app.etherassist.ai/api/endpoint"  # Replace with the actual EtherAssist API endpoint
# $etherAssistKey = $env:ETHERASSIST_API_KEY  # Store your EtherAssist API key in an environment variable

# # Validate that the EtherAssist API key is set (if using EtherAssist)
# if (-not $etherAssistKey) {
#     Write-Host "🔴 **Warning:** EtherAssist API key not found. Please set the ETHERASSIST_API_KEY environment variable if you intend to use EtherAssist."
#     Write-Host "   Example: `$env:ETHERASSIST_API_KEY = 'your-etherassist-api-key'"
#     # Depending on your needs, you might want to exit or continue without EtherAssist
#     # exit 1
# }

# Performance Counters to Collect
$performanceCounters = @(
    '\Memory\% Committed Bytes In Use',
    '\Memory\Available MBytes',
    '\Network Interface(*)\Bytes Sent/sec',
    '\Network Interface(*)\Bytes Received/sec',
    '\Network Interface(*)\Packets Sent/sec',
    '\Network Interface(*)\Packets Received/sec',
    "\PhysicalDisk(_Total)\Disk Write Bytes/sec",
    "\PhysicalDisk(_Total)\Disk Read Bytes/sec",
    "\Processor(_Total)\% Processor Time",
    "\Processor(_Total)\% Idle Time"
)

# -----------------------------
# Ensure Output Directory Exists
# -----------------------------
if (-not (Test-Path -Path $outputDirectory)) {
    Write-Host "Output directory does not exist. Creating directory at '$outputDirectory'..." -ForegroundColor Yellow
    try {
        New-Item -Path $outputDirectory -ItemType Directory -Force | Out-Null
        Write-Host "Output directory created successfully." -ForegroundColor Green
    }
    catch {
        Write-Error "Failed to create output directory: $_"
        exit 1
    }
}

# Remove trailing backslash if present
if ($outputDirectory.EndsWith("\")) {
    $outputDirectory = $outputDirectory.TrimEnd('\')
}

# Create the name of the output file in the format of "ComputerName_yyyy_MM_dd_HH_mm_ss.csv"
$outputFile = "$outputDirectory\$(if ($computerName -eq '') { $env:COMPUTERNAME } else { $computerName })_$(Get-Date -Format "yyyy_MM_dd_HH_mm_ss").csv"

# -----------------------------
# Function Definitions
# -----------------------------

function Get-AIOpenAIResponse {
    <#
    .SYNOPSIS
        Sends a prompt to Azure OpenAI and retrieves the response.

    .PARAMETER prompt
        The prompt text to send to the AI model.

    .RETURNS
        The AI-generated response text.

    .EXAMPLE
        $response = Get-AIOpenAIResponse -prompt "Analyze the following metrics..."
    #>
    param (
        [Parameter(Mandatory = $true)]
        [string]$prompt
    )

    # Validate OpenAI Configuration
    if (-not $openAIEndpoint -or -not $openAIKey -or -not $deploymentName) {
        Write-Error "Azure OpenAI configuration is incomplete. Please check the configuration section."
        return $null
    }

    # Construct the full URI for Chat Completions API
    $uri = "$openAIEndpoint"

    # Define headers
    $headers = @{
        "Content-Type"  = "application/json"
        "api-key"       = $openAIKey
    }

    # Define the body for Chat Completions
    $body = @{
        "messages" = @(
            @{
                "role" = "system"
                "content" = "You are an IT performance analyst specializing in Azure Virtual Desktop environments. Provide detailed analysis and recommendations based on the provided performance metrics."
            },
            @{
                "role" = "user"
                "content" = $prompt
            }
        )
        "max_tokens" = 500
        "temperature" = 0.3
        "top_p" = 0.95
        "frequency_penalty" = 0
        "presence_penalty" = 0
    } | ConvertTo-Json -Depth 4

    try {
        $response = Invoke-RestMethod -Method Post -Uri $uri -Headers $headers -Body $body
        return $response.choices[0].message.content.Trim()
    }
    catch {
        Write-Error "Failed to get response from Azure OpenAI: $_"
        return $null
    }
}

# -----------------------------
# Performance Metrics Collection
# -----------------------------
Write-Host "Starting performance metrics collection..." -ForegroundColor Green
Write-Host "Output Directory: $outputDirectory"
Write-Host "Output File: $outputFile"
Write-Host "Collection Interval: $sampleInterval seconds"
Write-Host "Number of Samples: $maxSamples"
Write-Host "Press Ctrl+C to exit if running continuously." -ForegroundColor Yellow

# Set the variables for the Get-Counter cmdlet.
$counterParams = @{
    SampleInterval = $sampleInterval
    Counter = $performanceCounters
}

# Add the computer name if specified
if ($computerName -ne "") {
    $counterParams.Add("ComputerName", $computerName)
}

# Set MaxSamples or Continuous based on $maxSamples
if ($maxSamples -eq 0) {
    $counterParams.Add("Continuous", $true)
}
else {
    $counterParams.Add("MaxSamples", $maxSamples)
}

# Collect the performance counters
try {
    Write-Host "Collecting performance metrics..." -ForegroundColor Cyan
    $counterResult = Get-Counter @counterParams
    Write-Host "Performance metrics successfully collected." -ForegroundColor Green
}
catch {
    Write-Error "Failed to collect performance metrics: $_"
    exit 1
}

# -----------------------------
# Exporting Performance Data to CSV
# -----------------------------
try {
    Write-Host "Exporting performance metrics to CSV..." -ForegroundColor Cyan
    # Process each sample and export relevant data
    $exportData = foreach ($sample in $counterResult.CounterSamples) {
        [PSCustomObject]@{
            Timestamp      = $sample.Timestamp
            Path           = $sample.Path
            Instance       = if ([string]::IsNullOrEmpty($sample.Instance)) { "<No Instance>" } else { $sample.Instance }
            CookedValue    = [math]::Round($sample.CookedValue, 2)
        }
    }
    $exportData | Export-Csv -Path $outputFile -NoTypeInformation -Force
    Write-Host "Performance metrics successfully exported to '$outputFile'." -ForegroundColor Green
}
catch {
    Write-Error "Failed to export performance metrics to CSV: $_"
    exit 1
}

# -----------------------------
# Aggregating Performance Data
# -----------------------------
Write-Host "Aggregating collected performance metrics..." -ForegroundColor Green

try {
    # Read the collected CSV file
    $counterData = Import-Csv -Path $outputFile

    # Display the first few rows for verification
    Write-Host "`nSample Data from CSV:" -ForegroundColor Yellow
    $counterData | Select-Object -First 5 | Format-Table -AutoSize

    # Check if data is present
    if ($counterData.Count -eq 0) {
        Write-Error "No data found in the CSV file. Exiting aggregation."
        exit 1
    }

    # Initialize a hashtable to store aggregated data
    $aggregatedHash = @{}

    foreach ($row in $counterData) {
        $counter = $row.Path
        $instance = $row.Instance
        $valueString = $row.CookedValue

        # Initialize $value before passing it by reference
        $value = 0

        # Validate if CookedValue is a number
        if ([double]::TryParse($valueString, [ref]$value)) {
            $key = "$counter|$instance"

            if ($aggregatedHash.ContainsKey($key)) {
                $aggregatedHash[$key] += $value
                $aggregatedHash["$key|Count"] += 1
            }
            else {
                $aggregatedHash[$key] = $value
                $aggregatedHash["$key|Count"] = 1
            }
        }
        else {
            Write-Warning "Invalid CookedValue for counter '$counter' and instance '$instance': $valueString"
        }
    }

    # Prepare aggregated samples
    $aggregatedSamples = @()

    foreach ($key in $aggregatedHash.Keys) {
        if ($key.EndsWith("|Count")) {
            continue
        }

        $countKey = "$key|Count"
        if ($aggregatedHash.ContainsKey($countKey)) {
            $avgValue = $aggregatedHash[$key] / $aggregatedHash[$countKey]
            $avgValue = [math]::Round($avgValue, 2)

            $parts = $key -split '\|'
            $path = $parts[0]
            $instance = $parts[1]

            $aggregatedSamples += [PSCustomObject]@{
                Path = $path
                Instance = $instance
                AvgCookedValue = $avgValue
            }
        }
    }

    # Check if aggregation resulted in any samples
    if ($aggregatedSamples.Count -eq 0) {
        Write-Error "Aggregation resulted in no samples."
        exit 1
    }

    Write-Output "`nAveraged Performance Metrics for $(if ($computerName -eq '') { 'localhost' } else { $computerName })"
    $aggregatedSamples | Format-Table -AutoSize
}
catch {
    Write-Error "Failed to aggregate performance data: $_"
    exit 1
}


# -----------------------------
# Data Preparation for AI Analysis
# -----------------------------

# Convert the collected performance data into a structured JSON format
$performanceSummary = $aggregatedSamples | ForEach-Object {
    @{
        Counter = $_.Path
        Instance = $_.Instance
        Value = $_.AvgCookedValue
    }
} | ConvertTo-Json -Compress

# -----------------------------
# AI Prompt Creation
# -----------------------------

# Craft a detailed prompt to guide the AI in analyzing the performance metrics
$prompt = @"
Analyze the following performance metrics collected from an Azure Virtual Desktop (AVD) session host. Identify any potential issues, their possible causes, and recommend actionable solutions to optimize system performance.

### Performance Metrics:
$performanceSummary

### Analysis and Recommendations:
"@

# -----------------------------
# AI-Assisted Analysis
# -----------------------------
Write-Host "`nSending performance data to Azure OpenAI for analysis..." -ForegroundColor Cyan

$aiResponse = Get-AIOpenAIResponse -prompt $prompt

if ($aiResponse) {
    Write-Host "`nAI-Assisted Performance Analysis and Recommendations:" -ForegroundColor Green
    Write-Output $aiResponse
}
else {
    Write-Host "`nAI-Assisted Analysis could not be retrieved." -ForegroundColor Yellow
}

# -----------------------------
# Script Completion
# -----------------------------
Write-Host "`nPerformance log collection and analysis completed." -ForegroundColor Green

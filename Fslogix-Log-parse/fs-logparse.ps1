 $env:OPENAI_API_KEY = ""

<#
.SYNOPSIS
    Splits log files, analyzes each chunk with Azure OpenAI, and generates summaries.

.DESCRIPTION
    This script splits a log file into smaller chunks, removes any 'INFO' log entries, sends each chunk to Azure OpenAI for analysis, writes individual summaries to a file, and finally generates an overall summary based on all individual summaries.

.EXAMPLE
    .\Analyze-LogChunks-AI.ps1
#>

# -----------------------------
# Configuration Section
# -----------------------------

# -----------------------------
# Azure OpenAI Configuration
# -----------------------------
$deploymentName = "GPT4o"  # Replace with your exact deployment name
$apiVersion = "2024-02-15-preview"  # Use the API version that matches your deployment

# Construct the Azure OpenAI endpoint for Chat Completions
$openAIEndpoint = "<Enter URL>/openai/deployments/$deploymentName/chat/completions?api-version=$apiVersion"

# **Security Best Practice:** 
# Store your API key in an environment variable instead of hardcoding it.
# To set an environment variable in PowerShell, use:
# $env:OPENAI_API_KEY = "your-actual-api-key"
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

# -----------------------------
# Logging and Output Configuration
# -----------------------------
# Define paths for log chunks and summaries
$logFilePath = "C:\Users\ryan\Downloads\Profile-20240918.log"
$logFolder = "C:\Users\ryan\Downloads\LogChunks"
$summaryFile = "C:\Users\ryan\Downloads\LogSummaries.txt"

# Ensure the log file exists
if (-not (Test-Path $logFilePath)) {
    Write-Host "🔴 **Error:** Log file not found at '$logFilePath'. Please verify the path and try again."
    exit 1
}

# Ensure the folder for log chunks exists; create it if it doesn't
if (-not (Test-Path $logFolder)) {
    try {
        New-Item -ItemType Directory -Path $logFolder -Force | Out-Null
        Write-Host "📁 **Info:** Created log chunks directory at '$logFolder'."
    }
    catch {
        Write-Host "🔴 **Error:** Failed to create log chunks directory at '$logFolder'."
        Write-Host "   $_"
        exit 1
    }
}

# Ensure the summary file exists; create it if it doesn't
if (Test-Path $summaryFile) {
    try {
        Clear-Content -Path $summaryFile -ErrorAction Stop
        Write-Host "📝 **Info:** Cleared existing summary file at '$summaryFile'."
    }
    catch {
        Write-Host "🔴 **Error:** Failed to clear summary file at '$summaryFile'."
        Write-Host "   $_"
        exit 1
    }
} else {
    try {
        New-Item -ItemType File -Path $summaryFile -Force | Out-Null
        Write-Host "📝 **Info:** Created summary file at '$summaryFile'."
    }
    catch {
        Write-Host "🔴 **Error:** Failed to create summary file at '$summaryFile'."
        Write-Host "   $_"
        exit 1
    }
}

# -----------------------------
# Chunking Configuration
# -----------------------------
# Define the number of lines per chunk
$linesPerChunk = 5

# -----------------------------
# Function to Split Log into Smaller Files
# -----------------------------
function Split-LogFileIntoChunks {
    param (
        [string]$filePath,
        [string]$outputFolder,
        [int]$linesPerChunk
    )

    # Read the log file, exclude 'INFO' lines
    $logContents = Get-Content -Path $filePath | Where-Object { $_ -notmatch 'INFO' }

    if ($logContents.Count -eq 0) {
        Write-Host "🔴 **Error:** No ERROR or WARNING lines found in the log file."
        exit 1
    }

    # Split into chunks of specified lines
    $chunkIndex = 0
    for ($i = 0; $i -lt $logContents.Count; $i += $linesPerChunk) {
        $endIndex = [math]::Min($i + $linesPerChunk - 1, $logContents.Count - 1)
        $chunk = $logContents[$i..$endIndex]
        $chunkFile = Join-Path $outputFolder "log_chunk_$chunkIndex.txt"
        try {
            $chunk | Out-File -FilePath $chunkFile -Encoding UTF8 -Force
            Write-Host "📄 **Info:** Created chunk file '$($chunkFile)'."
            $chunkIndex++
        }
        catch {
            Write-Host "🔴 **Error:** Failed to create chunk file '$chunkFile'."
            Write-Host "   $_"
            exit 1
        }
    }

    Write-Host "✅ **Success:** Log file successfully split into smaller files with $linesPerChunk lines each."
}

# -----------------------------
# Function to Generate Log Summary with AI
# -----------------------------
function GenerateLogSummary {
    param (
        [string]$logSnippet
    )

    # Ensure logSnippet is not empty
    if ([string]::IsNullOrWhiteSpace($logSnippet)) {
        Write-Host "⚠️ **Warning:** Log snippet is empty, skipping..."
        return ""
    }

    # Prepare the prompt for AI summarization
    $prompt = @"
Please analyze the following Fslogix log entries and provide key issues, insights, and suggested solutions.

Log data:
$logSnippet
"@

    # Prepare the JSON payload
    $body = @{
        "messages" = @(
            @{
                "role" = "system"
                "content" = "You are an FSLogix Profile Container log analysis assistant. Analyze the provided log entries and identify key issues, insights, and suggest possible solutions."
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
        # Send the request and capture the response
        $response = Invoke-RestMethod -Method Post -Uri $openAIEndpoint -Headers @{
            "Content-Type" = "application/json"
            "api-key" = $openAIKey
        } -Body $body

        # Check if the response contains choices
        if ($response.choices -and $response.choices.Count -gt 0) {
            $summary = $response.choices[0].message.content.Trim()
            return $summary
        }
        else {
            Write-Host "⚠️ **Warning:** No valid response received from OpenAI API."
            return ""
        }
    }
    catch {
        Write-Host "🔴 **Error:** An error occurred while calling the OpenAI API:" $_.Exception.Message
        return ""
    }
}

# -----------------------------
# Function to Analyze Log Files and Generate Summaries
# -----------------------------
function Analyze-LogFiles {
    param (
        [string]$folderPath,
        [string]$summaryFile
    )

    # Get all log chunk files
    $logFiles = Get-ChildItem -Path $folderPath -Filter "*.txt"

    if ($logFiles.Count -eq 0) {
        Write-Host "🔴 **Error:** No log chunk files found in '$folderPath'."
        return
    }

    # Collect summaries from each file
    foreach ($file in $logFiles) {
        $logSnippet = Get-Content -Path $file.FullName -Raw

        # Generate summary for the chunk
        $response = GenerateLogSummary -logSnippet $logSnippet

        if ($response) {
            # Append summary to the summary file
            try {
                $response | Out-File -FilePath $summaryFile -Append -Encoding UTF8
                Write-Host "📝 **Info:** Summary for '$($file.Name)' written to '$summaryFile'."
            }
            catch {
                Write-Host "🔴 **Error:** Failed to write summary for '$($file.Name)' to '$summaryFile'."
                Write-Host "   $_"
            }
        }
        else {
            Write-Host "⚠️ **Warning:** No summary generated for '$($file.Name)'."
        }
    }

    Write-Host "✅ **Success:** All log chunks have been analyzed and summaries written to '$summaryFile'."
}

# -----------------------------
# Function to Summarize All Findings
# -----------------------------
function SummarizeAllFindings {
    param (
        [string]$summaryFile
    )

    # Read the summaries file
    $summaries = Get-Content -Path $summaryFile -Raw

    # Ensure there are summaries to process
    if ([string]::IsNullOrWhiteSpace($summaries)) {
        Write-Host "🔴 **Error:** Summary file is empty. No data to summarize."
        return
    }

    # Prepare the final summary prompt
    $prompt = @"
Please provide an overall summary, key insights, and conclusions based on the following log analysis summaries.

Summaries:
$summaries
"@

    # Prepare the JSON payload for final summary
    $body = @{
        "messages" = @(
            @{
                "role" = "system"
                "content" = "You are an IT log analysis assistant. Summarize the provided log analysis summaries and provide concise, to-the-point key insights and conclusions."
            },
            @{
                "role" = "user"
                "content" = $prompt
            }
        )
        "max_tokens" = 1000
        "temperature" = 0.3
        "top_p" = 0.95
        "frequency_penalty" = 0
        "presence_penalty" = 0
    } | ConvertTo-Json -Depth 4

    try {
        # Send the final summary request to OpenAI
        $response = Invoke-RestMethod -Method Post -Uri $openAIEndpoint -Headers @{
            "Content-Type" = "application/json"
            "api-key" = $openAIKey
        } -Body $body

        # Check if the response contains choices
        if ($response.choices -and $response.choices.Count -gt 0) {
            $finalSummary = $response.choices[0].message.content.Trim()
            Write-Host "`n📝 **Final Summary:**"
            Write-Host $finalSummary
        }
        else {
            Write-Host "⚠️ **Warning:** No valid response received from OpenAI API for the final summary."
        }
    }
    catch {
        Write-Host "🔴 **Error:** An error occurred while calling the OpenAI API for the final summary:" $_.Exception.Message
    }
}

# -----------------------------
# Main Script Execution
# -----------------------------

# Step 1: Split the log into chunks of 5 lines and remove INFO logs
Split-LogFileIntoChunks -filePath $logFilePath -outputFolder $logFolder -linesPerChunk $linesPerChunk

# Step 2: Read and analyze the log files, and write summaries to a file
Analyze-LogFiles -folderPath $logFolder -summaryFile $summaryFile

# Step 3: Summarize the findings from all the chunk summaries
SummarizeAllFindings -summaryFile $summaryFile

# -----------------------------
# Script Completion
# -----------------------------
Write-Host "`n✅ **Success:** Log analysis and summarization completed."

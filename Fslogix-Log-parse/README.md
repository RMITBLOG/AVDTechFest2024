# README for FsLogix Log Chunk Analyzer with Azure OpenAI, Open Source LLMs, and EtherAssist API

## Overview

This PowerShell script processes large FsLogix log files by splitting them into smaller chunks for efficient analysis. It removes unnecessary 'INFO' log entries, submits each chunk to either Azure OpenAI, an open-source large language model (LLM), or the **EtherAssist.AI** API for analysis, and generates individual summaries for each chunk. Finally, the script combines all the summaries into an overall report. The analysis identifies key issues and insights from the log data and suggests possible solutions.

### Supported Analysis Methods

1. **Azure OpenAI**: Use Azure's hosted LLMs for analyzing log files.
2. **Open-Source LLMs (e.g., Ollama)**: Use local LLM models for self-hosted analysis, allowing for full control over data privacy.
3. **EtherAssist.AI API**: Leverage the EtherAssist API for advanced IT compliance and operational insights, integrated with AI-powered log analysis.

## Prerequisites

- **Azure OpenAI Access** (optional): You need an Azure OpenAI account and an API key if using Azure OpenAI.
- **Open-Source LLM** (optional): Install a local open-source LLM such as **Ollama** if you prefer not to use Azure OpenAI.
- **EtherAssist.AI API** (optional): Access to the EtherAssist API for advanced log analysis.
- **PowerShell**: Ensure PowerShell is installed on your system.
- **API Keys**: Set your Azure OpenAI and EtherAssist API keys as environment variables if you plan to use those services.

## Diagram


![image](https://github.com/user-attachments/assets/e27b31ec-a2ea-4557-aaf3-31ae0cb06995)


## Setup

### 1. Install Required Tools

Make sure you have:
- PowerShell
- Azure OpenAI services (optional)
- An open-source LLM like **Ollama** for local model hosting (optional)
- Access to the **EtherAssist API** for enhanced log analysis (optional)

### 2. Configure API Keys

Before running the script, store your API keys in environment variables:

- **Azure OpenAI**:
  ```powershell
  $env:OPENAI_API_KEY = "your-api-key-here"
  ```

- **EtherAssist.AI**:
  ```powershell
  $env:ETHERASSIST_API_KEY = "your-etherassist-api-key-here"
  ```

### 3. Modify Script for Your Environment

Edit the script to match your environment:
- Set your Azure OpenAI deployment name and API version if using Azure OpenAI.
- Set the path to your FsLogix log file.
- Configure **EtherAssist.AI** if you plan to use it alongside Azure OpenAI or in place of it.
- Set up **Ollama** or another local LLM if you prefer to use an open-source solution.

### 4. Open Source LLM Support (e.g., Ollama)

If you prefer using an open-source LLM instead of Azure OpenAI, modify the script to direct API requests to your local LLM service. For example, with **Ollama**, update the endpoint to point to your local instance:

```powershell
$openAIEndpoint = "http://localhost:11434/v1/completions"  # Ollama API endpoint
```

This allows you to perform log analysis using locally hosted models, giving you full control over data privacy and avoiding cloud dependencies.

### 5. EtherAssist.AI Integration

The script also supports integration with **EtherAssist.AI**, an AI-powered compliance and operational insights platform. To enable EtherAssist in the script, uncomment and set the relevant configuration:

```powershell
$etherAssistEndpoint = "https://app.etherassist.ai/api/endpoint"
$etherAssistKey = $env:ETHERASSIST_API_KEY
```

If the EtherAssist API key is not set, the script will provide a warning but can still proceed with Azure OpenAI or open-source LLMs.

## Running the Script

Once configured, run the script using PowerShell:

```powershell
.\Analyze-LogChunks-AI.ps1
```

This will:
1. Split the FsLogix log file into smaller chunks.
2. Analyze each chunk using your preferred API (Azure OpenAI, EtherAssist.AI, or a local LLM).
3. Write individual summaries for each chunk and compile them into a final summary.

## Viewing Results

- The log chunks are saved in the specified folder (`LogChunks`).
- Individual and final summaries are written to the summary file (`LogSummaries.txt`).
- The script also displays the final summary in the PowerShell console.

## Example Usage

Here’s an example of how to use the script:

```powershell
# Set your Azure OpenAI API key and EtherAssist API key
$env:OPENAI_API_KEY = "your-api-key-here"
$env:ETHERASSIST_API_KEY = "your-etherassist-api-key-here"

# Run the script
.\Analyze-LogChunks-AI.ps1
```

##Example Output

![image](https://github.com/user-attachments/assets/f4e1e6fd-08d8-4d45-b359-f5d3c0dbae8f)


## Script Breakdown

### Key Functions:
- **Split-LogFileIntoChunks**: Splits the large FsLogix log file into smaller chunks, each with a specified number of lines, while removing 'INFO' entries.
- **GenerateLogSummary**: Sends each log chunk to the configured API (Azure OpenAI, EtherAssist, or an open-source LLM) for analysis and returns a summary.
- **Analyze-LogFiles**: Processes all the log chunks and writes individual summaries to a file.
- **SummarizeAllFindings**: Combines all individual summaries into a final report for overall insights.

## Customization Options

- **Chunk Size**: Adjust the number of lines per chunk by modifying the `$linesPerChunk` variable.
- **Log Path**: Modify `$logFilePath` to point to your desired log file.
- **Integration with EtherAssist**: Configure EtherAssist API settings to enable enhanced insights and compliance analysis.

## Security Considerations

- **API Keys**: Always store sensitive data, like API keys, in environment variables instead of hardcoding them in the script.
  
## Troubleshooting

- If the log file path is incorrect or missing, the script will exit with an error.
- If no 'ERROR' or 'WARNING' lines are found in the log file, the script will notify you and exit.

## Conclusion

This script simplifies the process of analyzing large FsLogix log files by breaking them into manageable chunks, filtering out irrelevant data, and leveraging AI services like Azure OpenAI, EtherAssist.AI, or open-source LLMs to extract key insights and provide suggested solutions.

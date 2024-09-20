### **Azure Virtual Desktop Performance Analyzer with AI Assistance**

#### **Overview**
This PowerShell script automates the collection and analysis of performance metrics from an Azure Virtual Desktop (AVD) session host. It gathers key performance counters, aggregates the data, exports it to a CSV file, and utilizes Azure OpenAI to provide intelligent insights and actionable recommendations based on the collected metrics.

#### **Features**
- **Performance Metrics Collection**: Gathers essential performance counters related to CPU, Memory, Network, and Disk usage.
- **Data Aggregation**: Processes and averages the collected data for meaningful analysis.
- **AI-Assisted Analysis**: Sends aggregated metrics to Azure OpenAI for detailed analysis and recommendations.
- **Secure API Key Management**: Utilises environment variables to securely handle API keys.
- **Optional EtherAssist Integration**: Placeholder for integrating with EtherAssist API for enhanced functionalities.


### **Prerequisites**
- **Operating System**: Windows 10 or later.
- **PowerShell**: Version 5.1 or higher.
- **Azure Subscription**: Access to Azure OpenAI services.
- **Permissions**: Administrative privileges to collect performance counters.

---

### **Installation**
1. **Clone or Download the Script**
   - Clone the repository or download the `Collect-PerformanceLogs-AI.ps1` script to your local machine.

2. **Set Execution Policy**
   - Ensure that your PowerShell execution policy allows script execution. You can set it temporarily for the current session:
     ```powershell
     Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
     ```

---

### **Configuration**
1. **Set Up Azure OpenAI**
   - **Deployment Name**: Replace `"GPT4o"` with your actual Azure OpenAI deployment name.
   - **API Version**: Ensure the API version matches your deployment (e.g., `"2024-02-15-preview"`).
   - **Endpoint URL**: Replace `https:/<EnterURL>/openai/deployments/$deploymentName/chat/completions?api-version=$apiVersion` with your actual Azure OpenAI endpoint.

2. **Configure API Keys**
   - **Azure OpenAI API Key**:
     - **Security Best Practice**: Do **not** hardcode your API key within the script.
     - **Set Environment Variable**:
       ```powershell
       # For the current session
       $env:OPENAI_API_KEY = "your-actual-api-key"

       # To set it permanently for the user
       [System.Environment]::SetEnvironmentVariable("OPENAI_API_KEY", "your-actual-api-key", "User")
       ```
     - Replace `"your-actual-api-key"` with your actual Azure OpenAI API key.

   - **EtherAssist API Key (Optional)**:
     - If integrating with EtherAssist, uncomment and set the following:
       ```powershell
       $etherAssistEndpoint = "https://app.etherassist.ai/api/endpoint"  # Replace with the actual EtherAssist API endpoint
       $etherAssistKey = $env:ETHERASSIST_API_KEY  # Store your EtherAssist API key in an environment variable
       ```
     - Ensure the `ETHERASSIST_API_KEY` environment variable is set similarly to the OpenAI API key.

3. **Set Performance Counters**
   - The script collects the following performance counters:
     ```powershell
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
     ```
   - **Note**: Ensure these counters are valid on your system. You can list available counters using:
     ```powershell
     Get-Counter -ListSet * | Select-Object -ExpandProperty Counter | Sort-Object | Out-File "C:\temp\AvailableCounters.txt"
     ```
     Review `AvailableCounters.txt` to confirm the presence of your specified counters.

4. **Output Directory**
   - By default, the script exports CSV files to `C:\temp\Performance Counters`.
   - You can change this by modifying:
     ```powershell
     $outputDirectory = "C:\temp\Performance Counters"
     ```

---

### **Usage**
1. **Run the Script**
   - Open PowerShell with administrative privileges.
   - Navigate to the script's directory.
   - Execute the script:
     ```powershell
     .\Collect-PerformanceLogs-AI.ps1
     ```

2. **Script Workflow**
   - **Collection**: Gathers performance metrics based on the specified counters.
   - **Export**: Exports the collected data to a CSV file with a timestamped filename.
   - **Aggregation**: Processes the CSV to calculate average values for each counter.
   - **AI Analysis**: Sends the aggregated metrics to Azure OpenAI for analysis.
   - **Output**: Displays AI-generated insights and recommendations in the console.

---

### Example Output

![image](https://github.com/user-attachments/assets/5993578b-ee8a-41fc-8f69-883e4fba2d1c)


---

### **Troubleshooting**
- **No Data in CSV**
  - **Cause**: Invalid performance counters or insufficient permissions.
  - **Solution**: 
    - Verify performance counters using the `AvailableCounters.txt`.
    - Ensure PowerShell is running with administrative privileges.

- **AI Analysis Not Received**
  - **Cause**: Malformed CSV or issues with API key/configuration.
  - **Solution**:
    - Check the structure of the CSV file to ensure it has the correct headers and data.
    - Verify that the `OPENAI_API_KEY` environment variable is set correctly.
    - Ensure the Azure OpenAI endpoint URL is accurate.

- **Invalid CookedValue Warnings**
  - **Cause**: Non-numeric values in `CookedValue` fields.
  - **Solution**: 
    - Ensure that all specified performance counters return numeric values.
    - Exclude or correct any counters that might return non-numeric data.

---

### **Support**
If you encounter any issues or have questions regarding the script:

- **Check CSV Structure**: Ensure that the CSV file has the correct headers and data formats.
- **Verify API Keys**: Confirm that the `OPENAI_API_KEY` environment variable is correctly set and accessible.
- **Performance Counters**: Validate that all specified performance counters are available on your system.
- **Permissions**: Run PowerShell with administrative privileges to ensure access to all performance counters.

For further assistance, feel free to reach out 


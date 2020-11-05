## Navigation Menu
* [Getting started](../src/platform-automation#platform-automation---getting-started)
* [Landing zones](./Landing-zones.md)
    -	[Artifacts](./Artifacts.md)
    -   [Customers](../src/platform-automation/cmdb#customers)
    -	[Multi tenant deployments](./Multi-tenant-deployments.md)
* [Platform automation at scale](./Platform-automation-at-scale.md)
* [Design Guidelines](./Design-Guidelines.md)
    -	[CSP and Azure AD Tenants](./CSP-and-Azure-AD-Tenants.md)
    -	[Identity, Access Management and Lighthouse](./Identity-Access-Management-and-Lighthouse.md)
    -	[Management Group and Subscription Organisation](./Management-Group-and-Subscription-Organisation.md)
    -	**Management and Monitoring**
    -	[Security, Governance and Compliance](./Security-Governance-and-Compliance.md)
    -	[Platform Automation and DevOps](./Platform-Automation-and-DevOps.md)
---


# Management and Monitoring
[![Monitoring on Azure](./media/monitor.png "Monitoring on Azure")](#)

Figure 1 – Monitoring on Azure

***Design Considerations***

-   Understand what should be monitored & who needs to be notified

-   Understand out-of-the-box & on-by-default data collection already available for Azure Resources

-   Ensure appropriate levels of data access using RBAC. Monitoring Reader or Monitoring Contributor roles can grant access to monitoring data while restricting broader access. Central teams can access all logs with Workspace Access, while individual teams might just be given Resource Access

-   Decide whether to use separate or single Application Insights Resource for your scenarior
    -   Separate resources can help save costs, prevent data mix-up and allow more relaxed access
    -   Single resource can help keep all relevant telemetry in the same place to use with Application Insights features
        -   Different independent applications -> Use separate iKeys for each app
        -   Multiple microservices or roles of one business application -> Use a single iKey; Filter/Segment telemetry by cloud_RoleName property
        -   Dev, Test & Production -> Use separate iKeys for each stage/environment of release
        -   A | B Testing -> Use a single iKey; Add custom property to identify variants

-   Prefer Metric Alerts for better performance/latency; Use Log Alerts for powerful query-based triggers or lack of metrics

-   Consider collecting and integrating additional AKS workload metrics from Prometheus

-   Consider custom telemetry to gain valuable logs, distributed tracing & usage insights

-   Setup actionable alerts with notifications and/or remediation

-   Properly define severity/descriptions and avoid sending blanket notifications to people who cannot take any actions

-   Optimize Cost - Collect & Retain only as much data as you need 
    -   Review configuration settings to reduce frequency of data collection and only collect required logs (e.g. avoid Info)
    -   Setup appropriate data caps to avoid anomalous spikes / bill shocks and configure data cap alerts to avoid losing data
    -   Use sampling to reduce number of telemetry items that are actually sent from your apps
    -   Setting lower retention on selected data types can be used to reduce your data costs
    -   Leverage reserved capacity pricing when appropriate for lower costs
    -   Evaluate recommendations from Azure Advisor to help optimize Availability, Security, Performance & Cost

-   Ways to reduce Logs Data Collection
    -   Select [common or minimal security events](https://docs.microsoft.com/azure/security-center/security-center-enable-data-collection#data-collection-tier). Change the security audit policy to collect only needed events. Review the need to collect events for: audit filtering platform, audit registry, audit file system, audit kernel object, audit handle manipulation, audit removable storage
    -   Change [performance counter configuration](https://docs.microsoft.com/en-us/azure/azure-monitor/platform/data-sources-performance-counters) to reduce the frequency of collection and the number of performance counters
    -   Change [event log configuration](https://docs.microsoft.com/en-us/azure/azure-monitor/platform/data-sources-windows-events) to reduce the number of event logs collected. Collect only required event levels. E.g. do not collect Information level events
    -   Change [syslog configuration](https://docs.microsoft.com/en-us/azure/azure-monitor/platform/data-sources-syslog) to reduce the number of facilities collected. Collect only required event levels. E.g. do not collect Info and Debug level events
    -   Change resource log collection to reduce the number of resources send logs to Log Analytics. Collect only required logs

***Design Recommendations***

-   Configure Agents & Diagnostic Settings for additional logs/perf counters as needed 
    -   Install Log Analytics Agent to collect data from Guest OS & VM Workloads in LA workspaces. Required for writing Log Analytics Queries or using VM Insights, Azure Security Center or Azure Sentinel.  
    -   Configure Diagnostics Settings in resource-specific mode, which makes it easy to discover schemas and write queries
    -   Use Dependency Agent to collect discovered data about running processes & external process dependencies on VMs. Required for VM Insights Maps feature and has dependency on Log Analytics Agent.

-   Log Analytics workspace setup: use as few as possible, unless there are specific organizational requirements or geographical data sovereignty constraints

-   Automate agent deployment, insights enablement & diagnostics settings configuration across resources via:
    -   Azure Automation DSC (Desired State Configuration)
    -   Azure CLI / PowerShell
    -   Azure Resource Manager (ARM) Templates
    -   Azure Policy

-   Integrate with Release Management via Azure DevOps Pipelines/Github actions

-   Connect Alerts with ITSM or Ticketing Systems (like Service Now or Pager Duty) for efficient management

-   Setup Automation Runbooks and/or Custom Workflows (Logic Apps) for Auto-Healing & Remediations 

-   Use Action Rules to manage Alert Suppression & Actions at scale

-   Create Scheduled Queries via Logic Apps to run custom alerts on schedule

-   Auto-Scaling can be performed on a schedule, or based on a runtime metric, such as CPU or memory usage

- Enable Smart Detection Alerts
    -   Application Insights Smart Detection: Out-of-the-box Alert Rules which help detect anomalies like slow page load time, slow server response time, degradation in server response time, degradation in dependency duration, abnormal rise in exception volume, potential memory leak, potential security issue, etc.	
    -   Dynamic Threshold Metric Alerts: Detect patterns in the data such as seasonality (Hourly/Daily/Weekly). Sensitivity can be set to control amount of deviation from behavior required to trigger an alert (Medium/Low helps reduce Alert Noise). 

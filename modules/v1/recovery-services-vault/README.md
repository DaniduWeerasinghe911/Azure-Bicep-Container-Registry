# Recovery Services Vault
This module will create a recovery services vault.

You can optionally configure backup policies, system identity, backup storage type, cross region restore and enable diagnostics logs and a delete lock.

## Usage

### Example 1 - Recovery services vault with diagnostic logs and delete lock enabled
``` bicep
param deploymentName string = 'recoveryServices${utcNow()}'

var tags = {
  Purpose: 'Sample Bicep Template'
  Environment: 'Development'
  Owner: 'sample.user@arinco.com.au'
}

var diagnostics = {
  name: 'diag-log'
  workspaceId: '/subscriptions/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx/resourcegroups/example-dev-rg/providers/microsoft.operationalinsights/workspaces/example-dev-log'
  storageAccountId: '/subscriptions/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx/resourcegroups/example-dev-rg/providers/microsoft.storage/storageAccounts/exampledevst'
  eventHubAuthorizationRuleId: 'Endpoint=sb://example-dev-ehns.servicebus.windows.net/;SharedAccessKeyName=DiagnosticsLogging;SharedAccessKey=xxxxxxxxx;EntityPath=example-hub-namespace'
  eventHubName: 'StorageDiagnotics'
  enableLogs: true
  enableMetrics: false
  retentionPolicy: {
    days: 0
    enabled: false
  }
}

module recoveryServices './recovery-services-vault.bicep' = {
  name: deploymentName  
  params: {
    vaultName: 'MyRecoveryServicesVault'
    tags: tags
    enableResourceLock: true
    diagsettings: diagnostics 
  }
}
```

### Example 2 - Recovery services vault with system identity and backup storage type set
``` bicep
param deploymentName string = 'recoveryServices${utcNow()}'

module recoveryServices './recovery-services-vault.bicep' = {
  name: deploymentName  
  params: {
    vaultName: 'MyRecoveryServicesVault'
    enableSystemIdentity: true
    storageType: 'LocallyRedundant'    
  }
}
```

### Example 3 - Recovery services vault with cross region restore enabled
``` bicep
param deploymentName string = 'recoveryServices${utcNow()}'

module recoveryServices './recovery-services-vault.bicep' = {
  name: deploymentName  
  params: {
    vaultName: 'MyRecoveryServicesVault'    
    storageType: 'GeoRedundant'
    enablecrossRegionRestore: true    
  }
}
```

### Example 4 - Recovery services vault with backup policies
``` bicep
param deploymentName string = 'recoveryServices${utcNow()}'

module recoveryServices './recovery-services-vault.bicep' = {
  name: deploymentName  
  params: {
    vaultName: 'MyRecoveryServicesVault'
    backupPolicies = [
      {
        policyName: 'Policy-Example1'
        properties: {
          backupManagementType: 'AzureIaasVM'
          instantRpRetentionRangeInDays: 2
          schedulePolicy: {
            scheduleRunFrequency: 'Daily'
            scheduleRunTimes: [
              '2021-09-05T21:00:00Z'
            ]
            schedulePolicyType: 'SimpleSchedulePolicy'
          }
          timeZone: 'AUS Eastern Standard Time'
          retentionPolicy: {
            dailySchedule: {
              retentionTimes: [
                '2021-09-05T21:00:00Z'
              ]
              retentionDuration: {
                count: 14
                durationType: 'Days'
              }
            }
            retentionPolicyType: 'LongTermRetentionPolicy'
          }
        }
      }
      {
        policyName: 'Policy-Example2'
        properties: {
          backupManagementType: 'AzureIaasVM'
          instantRpRetentionRangeInDays: 5
          schedulePolicy: {
            scheduleRunFrequency: 'Weekly'
            scheduleRunDays: [
              'Sunday'
              'Wednesday'
            ]
            scheduleRunTimes: [
              '2021-09-05T21:00:00Z'
            ]
            schedulePolicyType: 'SimpleSchedulePolicy'
          }
          timeZone: 'AUS Eastern Standard Time'
          retentionPolicy: {
            dailySchedule: null
            weeklySchedule: {
              daysOfTheWeek: [
                'Sunday'
                'Wednesday'
              ]
              retentionTimes: [
                '2021-09-05T21:00:00Z'
              ]
              retentionDuration: {
                count: 4
                durationType: 'Weeks'
              }
            }
            monthlySchedule: {
              retentionScheduleFormatType: 'Weekly'
              retentionScheduleDaily: {
                daysOfTheMonth: [
                  {
                    date: 1
                    isLast: false
                  }
                ]
              }
              retentionScheduleWeekly: {
                daysOfTheWeek: [
                  'Sunday'
                  'Wednesday'
                ]
                weeksOfTheMonth: [
                  'First'
                  'Third'
                ]
              }
              retentionTimes: [
                '2021-09-05T21:00:00Z'
              ]
              retentionDuration: {
                count: 12
                durationType: 'Months'
              }
            }
            yearlySchedule: {
              retentionScheduleFormatType: 'Weekly'
              monthsOfYear: [
                'January'
                'March'
                'August'
              ]
              retentionScheduleDaily: {
                daysOfTheMonth: [
                  {
                    date: 1
                    isLast: false
                  }
                ]
              }
              retentionScheduleWeekly: {
                daysOfTheWeek: [
                  'Sunday'
                  'Wednesday'
                ]
                weeksOfTheMonth: [
                  'First'
                  'Third'
                ]
              }
              retentionTimes: [
                '2021-09-05T21:00:00Z'
              ]
              retentionDuration: {
                count: 7
                durationType: 'Years'
              }
            }
            retentionPolicyType: 'LongTermRetentionPolicy'
          }
        }
      }
    ]   
  }
}
```
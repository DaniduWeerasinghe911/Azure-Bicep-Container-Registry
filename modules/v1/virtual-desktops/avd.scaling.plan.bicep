@description('Location of virtual desktop hostpool.')
param avdLocation string

@description('Name of the scaling plan')
param scalingPlanName string

@description('Scaling Plan Description')
param scalingPlanDescription string

@description('Scaling Plan time zone')
param timeZone string

@description('AVD Hostpool ID for the assignments')
param hostPoolId string

@description('Location of resources.')
@metadata({
      name: 'weekdays_schedule'
      daysOfWeek: [
          'Monday'
          'Tuesday'
          'Wednesday'
          'Thursday'
          'Friday'
      ]
      rampUpStartTime: {
          hour: 8
          minute: 0
      }
      rampUpLoadBalancingAlgorithm: 'BreadthFirst'
      rampUpMinimumHostsPct: 20
      rampUpCapacityThresholdPct: 60
      peakStartTime: {
          hour: 9
          minute: 0
      }
      peakLoadBalancingAlgorithm: 'DepthFirst'
      rampDownStartTime: {
          hour: 18
          minute: 0
      }
      rampDownLoadBalancingAlgorithm: 'DepthFirst'
      rampDownMinimumHostsPct: 10
      rampDownCapacityThresholdPct: 90
      rampDownWaitTimeMinutes: 30
      rampDownStopHostsWhen: 'ZeroSessions'
      rampDownNotificationMessage: 'You will be logged off in 30 min. Make sure to save your work.'
      offPeakStartTime: {
          hour: 20
          minute: 0
      }
      offPeakLoadBalancingAlgorithm: 'DepthFirst'
      rampDownForceLogoffUsers: true

})
param schedules array = [
  {
    name: 'weekdays_schedule'
    daysOfWeek: [
        'Monday'
        'Tuesday'
        'Wednesday'
        'Thursday'
        'Friday'
    ]
    rampUpStartTime: {
        hour: 8
        minute: 0
    }
    rampUpLoadBalancingAlgorithm: 'BreadthFirst'
    rampUpMinimumHostsPct: 20
    rampUpCapacityThresholdPct: 60
    peakStartTime: {
        hour: 9
        minute: 0
    }
    peakLoadBalancingAlgorithm: 'DepthFirst'
    rampDownStartTime: {
        hour: 18
        minute: 0
    }
    rampDownLoadBalancingAlgorithm: 'DepthFirst'
    rampDownMinimumHostsPct: 10
    rampDownCapacityThresholdPct: 90
    rampDownWaitTimeMinutes: 30
    rampDownStopHostsWhen: 'ZeroSessions'
    rampDownNotificationMessage: 'You will be logged off in 30 min. Make sure to save your work.'
    offPeakStartTime: {
        hour: 20
        minute: 0
    }
    offPeakLoadBalancingAlgorithm: 'DepthFirst'
    rampDownForceLogoffUsers: true
  }
]

@description('Location of resources.')
param exclusionTag string

@description('Location of resources.')
param tags object


resource scalingPlan 'Microsoft.DesktopVirtualization/scalingPlans@2022-02-10-preview' = {
  name: scalingPlanName
  location: avdLocation
  tags:tags
  properties: {
    description:scalingPlanDescription
    exclusionTag: exclusionTag
    friendlyName: scalingPlanName
    hostPoolReferences: [
      {
        hostPoolArmPath: hostPoolId
        scalingPlanEnabled: true
      }
    ]
    hostPoolType: 'Pooled'
    schedules:schedules
    timeZone: timeZone
  }
}

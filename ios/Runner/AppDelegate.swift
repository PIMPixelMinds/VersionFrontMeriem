import Flutter
import UIKit
import HealthKit
import Firebase // Add this
import FirebaseMessaging // Add this

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    // Register for remote notifications
    UNUserNotificationCenter.current().delegate = self
    application.registerForRemoteNotifications()

    let controller = window?.rootViewController as! FlutterViewController
    let healthChannel = FlutterMethodChannel(name: "com.meriemabid.pim/health", binaryMessenger: controller.binaryMessenger)
    print("Platform channel initialized: com.meriemabid.pim/health")

    healthChannel.setMethodCallHandler { (call: FlutterMethodCall, result: @escaping FlutterResult) in
      print("Received method call: \(call.method)")
      switch call.method {
      case "fetchHealthData":
        self.fetchHealthData(result: result)
      default:
        print("Method not implemented: \(call.method)")
        result(FlutterMethodNotImplemented)
      }
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  private func fetchHealthData(result: @escaping FlutterResult) {
    print("Fetching health data from HealthKit...")
    guard HKHealthStore.isHealthDataAvailable() else {
      print("Health data not available on this device")
      result(FlutterError(code: "UNAVAILABLE", message: "Health data is not available on this device", details: nil))
      return
    }

    let healthStore = HKHealthStore()

    // Define the data types to read
    guard let stepType = HKObjectType.quantityType(forIdentifier: .stepCount),
          let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate),
          let hrvType = HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN),
          let temperatureType = HKObjectType.quantityType(forIdentifier: .bodyTemperature),
          let spo2Type = HKObjectType.quantityType(forIdentifier: .oxygenSaturation),
          let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else {
      print("Failed to create quantity types")
      result(FlutterError(code: "INVALID_TYPE", message: "Failed to create quantity types", details: nil))
      return
    }
    let typesToRead: Set<HKObjectType> = [stepType, heartRateType, hrvType, temperatureType, spo2Type, sleepType]

    // Request authorization
    healthStore.requestAuthorization(toShare: nil, read: typesToRead) { (success, error) in
      if !success {
        print("Health permissions not granted: \(String(describing: error))")
        result(FlutterError(code: "PERMISSION_DENIED", message: "Health permissions not granted", details: error?.localizedDescription))
        return
      }
      print("Health permissions granted")

      let calendar = Calendar.current
      let now = Date()
      // For steps: Start from midnight today
      let startOfToday = calendar.startOfDay(for: now)
      // For heart rate, HRV, temperature, SpO2: Last 1 hour
      let startOfLastHour = calendar.date(byAdding: .hour, value: -1, to: now)!
      // For sleep: Last 24 hours (to capture the most recent sleep session)
      let startOfLast24Hours = calendar.date(byAdding: .hour, value: -24, to: now)!

      let predicateToday = HKQuery.predicateForSamples(withStart: startOfToday, end: now, options: .strictStartDate)
      let predicateLastHour = HKQuery.predicateForSamples(withStart: startOfLastHour, end: now, options: .strictStartDate)
      let predicateLast24Hours = HKQuery.predicateForSamples(withStart: startOfLast24Hours, end: now, options: .strictStartDate)

      var healthData: [String: Any] = [
        "steps": 0.0,
        "heart_rate": 0.0,
        "hrv": 0.0,
        "temperature": 0.0,
        "spo2": 0.0,
        "sleep_score": 0.0
      ]

      let dispatchGroup = DispatchGroup()

      // Fetch steps (today only)
      dispatchGroup.enter()
      let stepQuery = HKStatisticsQuery(quantityType: stepType, quantitySamplePredicate: predicateToday, options: .cumulativeSum) { _, statistics, error in
        if let error = error {
          print("Error fetching steps: \(error.localizedDescription)")
          healthData["steps"] = 0.0
        } else {
          let steps = statistics?.sumQuantity()?.doubleValue(for: HKUnit.count()) ?? 0.0
          healthData["steps"] = steps
          print("Fetched steps for today: \(steps)")
        }
        dispatchGroup.leave()
      }

      // Fetch heart rate (last 1 hour)
      dispatchGroup.enter()
      let heartRateQuery = HKSampleQuery(sampleType: heartRateType, predicate: predicateLastHour, limit: 1, sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)]) { _, samples, error in
        if let error = error {
          print("Error fetching heart rate: \(error.localizedDescription)")
          healthData["heart_rate"] = 0.0
        } else {
          let heartRate = (samples?.first as? HKQuantitySample)?.quantity.doubleValue(for: HKUnit(from: "count/min")) ?? 0.0
          healthData["heart_rate"] = heartRate
          print("Fetched heart rate (last 1 hour): \(heartRate)")
        }
        dispatchGroup.leave()
      }

      // Fetch HRV (last 1 hour)
      dispatchGroup.enter()
      let hrvQuery = HKSampleQuery(sampleType: hrvType, predicate: predicateLastHour, limit: 1, sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)]) { _, samples, error in
        if let error = error {
          print("Error fetching HRV: \(error.localizedDescription)")
          healthData["hrv"] = 0.0
        } else {
          let hrv = (samples?.first as? HKQuantitySample)?.quantity.doubleValue(for: HKUnit.secondUnit(with: .milli)) ?? 0.0
          healthData["hrv"] = hrv
          print("Fetched HRV (last 1 hour): \(hrv)")
        }
        dispatchGroup.leave()
      }

      // Fetch temperature (last 1 hour)
      dispatchGroup.enter()
      let temperatureQuery = HKSampleQuery(sampleType: temperatureType, predicate: predicateLastHour, limit: 1, sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)]) { _, samples, error in
        if let error = error {
          print("Error fetching temperature: \(error.localizedDescription)")
          healthData["temperature"] = 0.0
        } else {
          let temperature = (samples?.first as? HKQuantitySample)?.quantity.doubleValue(for: HKUnit.degreeCelsius()) ?? 0.0
          healthData["temperature"] = temperature
          print("Fetched temperature (last 1 hour): \(temperature)")
        }
        dispatchGroup.leave()
      }

      // Fetch SpO2 (last 1 hour)
      dispatchGroup.enter()
      let spo2Query = HKSampleQuery(sampleType: spo2Type, predicate: predicateLastHour, limit: 1, sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)]) { _, samples, error in
        if let error = error {
          print("Error fetching SpO2: \(error.localizedDescription)")
          healthData["spo2"] = 0.0
        } else {
          let spo2 = (samples?.first as? HKQuantitySample)?.quantity.doubleValue(for: HKUnit.percent()) ?? 0.0
          healthData["spo2"] = spo2
          print("Fetched SpO2 (last 1 hour): \(spo2)")
        }
        dispatchGroup.leave()
      }

      // Fetch sleep (last 24 hours, duration as a proxy for sleep score)
      dispatchGroup.enter()
      let sleepQuery = HKSampleQuery(sampleType: sleepType, predicate: predicateLast24Hours, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { _, samples, error in
        if let error = error {
          print("Error fetching sleep: \(error.localizedDescription)")
          healthData["sleep_score"] = 0.0
        } else {
          var sleepDuration: Double = 0.0
          if let sleepSamples = samples as? [HKCategorySample] {
            for sample in sleepSamples {
              if sample.value == HKCategoryValueSleepAnalysis.asleep.rawValue {
                let duration = sample.endDate.timeIntervalSince(sample.startDate)
                sleepDuration += duration
              }
            }
          }
          // Convert to hours and estimate a simple sleep score (0-100)
          let sleepHours = sleepDuration / 3600.0
          let sleepScore = min(sleepHours * 12.5, 100.0) // Rough score: 8 hours = 100
          healthData["sleep_score"] = sleepScore
          print("Fetched sleep duration (last 24 hours): \(sleepHours) hours, Sleep score: \(sleepScore)")
        }
        dispatchGroup.leave()
      }

      // Execute all queries
      healthStore.execute(stepQuery)
      healthStore.execute(heartRateQuery)
      healthStore.execute(hrvQuery)
      healthStore.execute(temperatureQuery)
      healthStore.execute(spo2Query)
      healthStore.execute(sleepQuery)

      // Wait for all queries to complete before returning the result
      dispatchGroup.notify(queue: .main) {
        print("Returning health data to Flutter: \(healthData)")
        result(healthData)
      }
    }
  }
}

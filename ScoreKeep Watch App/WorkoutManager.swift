//
//  WorkoutManager.swift
//  ScoreKeep
//
//  Created by Chris Sauve on 2025-01-05.
//

import HealthKit

@Observable
class WorkoutManagerActiveWorkout {
    var session: HKWorkoutSession

    private(set) var averageHeartRate: Double?
    private(set) var heartRate: Double?
    private(set) var activeEnergy: Measurement<UnitEnergy>
    private(set) var distance: Measurement<UnitLength>

    init(session: HKWorkoutSession) {
        self.session = session
        self.activeEnergy = Measurement(value: 0, unit: .kilocalories)
        self.distance = Measurement(value: 0, unit: .meters)
    }

    func updateStatistics(_ statistics: HKStatistics) {
        switch statistics.quantityType {
        case HKQuantityType.quantityType(forIdentifier: .heartRate):
            let heartRateUnit = HKUnit.count().unitDivided(by: HKUnit.minute())
            self.heartRate = statistics.mostRecentQuantity()?.doubleValue(for: heartRateUnit) ?? 0
            self.averageHeartRate =
                statistics.averageQuantity()?.doubleValue(for: heartRateUnit) ?? 0
        case HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned):
            if let sum = statistics.sumQuantity()?.doubleValue(for: .kilocalorie()) {
                self.activeEnergy = Measurement(value: sum, unit: .kilocalories)
            }
        case HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning),
            HKQuantityType.quantityType(forIdentifier: .distanceCycling):
            if let sum = statistics.sumQuantity()?.doubleValue(for: .meter()) {
                self.distance = Measurement(value: sum, unit: .meters)
            }
        default:
            return
        }
    }
}

@Observable
class WorkoutManager: NSObject {
    let healthStore = HKHealthStore()

    var running: Bool = false
    var workout: WorkoutManagerActiveWorkout?
    var session: HKWorkoutSession?
    private var builder: HKLiveWorkoutBuilder?

    func startWorkout(match: Match) async {
        let configuration = HKWorkoutConfiguration()

        configuration.activityType = .volleyball

        configuration.locationType =
            switch match.environment {
            case .indoor: .indoor
            case .outdoor: .outdoor
            }

        // Create the session and obtain the workout builder.
        do {
            session = try HKWorkoutSession(healthStore: healthStore, configuration: configuration)
            builder = session?.associatedWorkoutBuilder()
        } catch let error {
            print("Error building session")
            print(error)
            // Handle any exceptions.
            return
        }

        if let session {
            workout = WorkoutManagerActiveWorkout(session: session)
        }

        // Setup session and builder.
        session?.delegate = self
        builder?.delegate = self

        // Set the workout builder's data source.
        builder?.dataSource = HKLiveWorkoutDataSource(
            healthStore: healthStore, workoutConfiguration: configuration)

        // Start the workout session and begin data collection.
        session?.startActivity(with: match.startedAt)

        do {
            try await builder?.beginCollection(at: match.startedAt)
        } catch let error {
            print("Error starting metric collection")
            print(error)
        }
    }

    func requestAuthorization() {
        // The quantity type to write to the health store.
        let typesToShare: Set = [
            HKQuantityType.workoutType()
        ]

        // The quantity types to read from the health store.
        let typesToRead: Set = [
            HKQuantityType.quantityType(forIdentifier: .heartRate)!,
            HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!,
            HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning)!,
            HKObjectType.activitySummaryType(),
        ]

        // Request authorization for those quantity types.
        healthStore.requestAuthorization(toShare: typesToShare, read: typesToRead) {
            (success, error) in
            // Handle error.
        }
    }

    func pause() {
        if let workout {
            workout.session.pause()
        }
    }

    func resume() {
        if let workout {
            workout.session.resume()
        }
    }

    func end() {
        if let workout {
            workout.session.end()
            self.workout = nil
        }
    }
}

// MARK: - HKWorkoutSessionDelegate
extension WorkoutManager: HKWorkoutSessionDelegate {
    func workoutSession(_ workoutSession: HKWorkoutSession, didGenerate event: HKWorkoutEvent) {
        switch event.type {
        case .pauseOrResumeRequest:
            if self.running {
                self.pause()
            } else {
                self.resume()
            }
        default: return
        }
    }

    func workoutSession(
        _ workoutSession: HKWorkoutSession, didChangeTo toState: HKWorkoutSessionState,
        from fromState: HKWorkoutSessionState, date: Date
    ) {

        DispatchQueue.main.async {
            self.running = toState == .running
        }

        // Wait for the session to transition states before ending the builder.
        if toState == .ended {
            builder?.endCollection(withEnd: date) { (success, error) in
                self.builder?.finishWorkout { (workout, error) in
                    DispatchQueue.main.async {
                        self.workout = nil
                    }
                }
            }
        }
    }

    func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) {
        print("Error with workout session")
        print(workoutSession, error)
    }
}

// MARK: - HKLiveWorkoutBuilderDelegate
extension WorkoutManager: HKLiveWorkoutBuilderDelegate {
    func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) {

    }

    func workoutBuilder(
        _ workoutBuilder: HKLiveWorkoutBuilder, didCollectDataOf collectedTypes: Set<HKSampleType>
    ) {
        for type in collectedTypes {
            guard let quantityType = type as? HKQuantityType else {
                continue  // Nothing to do.
            }

            guard let workout, let statistics = workoutBuilder.statistics(for: quantityType) else {
                continue
            }

            DispatchQueue.main.async {
                workout.updateStatistics(statistics)
            }
        }
    }
}

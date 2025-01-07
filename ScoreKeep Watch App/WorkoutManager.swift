//
//  WorkoutManager.swift
//  ScoreKeep
//
//  Created by Chris Sauve on 2025-01-05.
//

import HealthKit

@Observable
class WorkoutManager: NSObject {
    let healthStore = HKHealthStore()
    
    var running: Bool = false
    var workout: HKWorkout?
    var session: HKWorkoutSession?
    private var builder: HKLiveWorkoutBuilder?
    
    func startWorkout(match: Match) async {
        let configuration = HKWorkoutConfiguration()

        configuration.activityType = .volleyball

        configuration.locationType = switch(match.environment) {
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
        
        // Setup session and builder.
        session?.delegate = self
        builder?.delegate = self

        // Set the workout builder's data source.
        builder?.dataSource = HKLiveWorkoutDataSource(healthStore: healthStore, workoutConfiguration: configuration)
        

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
            HKObjectType.activitySummaryType()
        ]

        // Request authorization for those quantity types.
        healthStore.requestAuthorization(toShare: typesToShare, read: typesToRead) { (success, error) in
            // Handle error.
        }
    }

    func pause() {
        session?.pause()
    }

    func resume() {
        session?.resume()
    }

    func end() {
        session?.end()
    }
}


// MARK: - HKWorkoutSessionDelegate
extension WorkoutManager: HKWorkoutSessionDelegate {
    func workoutSession(_ workoutSession: HKWorkoutSession, didChangeTo toState: HKWorkoutSessionState, from fromState: HKWorkoutSessionState, date: Date) {

        DispatchQueue.main.async {

            self.running = toState == .running
        }

        // Wait for the session to transition states before ending the builder.
        if toState == .ended {
            builder?.endCollection(withEnd: date) { (success, error) in
                self.builder?.finishWorkout { (workout, error) in
                    DispatchQueue.main.async {
                        self.workout = workout
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

    func workoutBuilder(_ workoutBuilder: HKLiveWorkoutBuilder, didCollectDataOf collectedTypes: Set<HKSampleType>) {
        for type in collectedTypes {
            guard let quantityType = type as? HKQuantityType else {
                return // Nothing to do.
            }

            let statistics = workoutBuilder.statistics(for: quantityType)

            // Update the published values.
//            updateForStatistics(statistics)
        }
    }
}

import SwiftUI

@main
struct HowManyVaccinatedApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    let vaccinationsData = VaccinationsData()
    let updateFromSourceInterval = 3600.0 // 1 hour
    let updateEstimateInterval = 300.0 // 5 mins
    
    var statusBarItem: NSStatusItem?
    var estimateLiveNumbers = true
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        statusBarItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        updateMenu() // create menu empty state
        updateData() // kick off async update
        
        // update data from source periodically
        Timer.scheduledTimer(timeInterval: updateFromSourceInterval, target: self, selector: #selector(updateData), userInfo: nil, repeats: true)
        // refresh menu with new estimation periodically
        Timer.scheduledTimer(timeInterval: updateEstimateInterval, target: self, selector: #selector(updateMenu), userInfo: nil, repeats: true)
    }
    
    @objc func updateData() {
        vaccinationsData.load {success in
            if (success) {
                DispatchQueue.main.async {
                    self.updateMenu()
                }
            }
        }
    }
    
    @objc func updateMenu() {
        let latestData = vaccinationsData.latest()
        
        let statusBarMenu = NSMenu(title: "Vaccine Rollout Tracker")
        
        statusBarMenu.addItem(
            withTitle: "Percentage vaccinated (last update): \(vaccinationsData.percentageVaccinated(estimate: false))",
            action: nil,
            keyEquivalent: ""
        )
        
        statusBarMenu.addItem(
            withTitle: "Estimated percentage vaccinated (real-time): \(vaccinationsData.percentageVaccinated(estimate: true))",
            action: nil,
            keyEquivalent: ""
        )
        
        var numberPeople = "Unknown"
        if let peopleVaccinated = latestData.peopleVaccinated {
            let optionalFormattedNumber = numberFormatter().string(from: peopleVaccinated as NSNumber)
            if let formattedNumber = optionalFormattedNumber {
                numberPeople = formattedNumber
            }
        }
        statusBarMenu.addItem(
            withTitle: "People vaccinated (last update): \(numberPeople)",
            action: nil,
            keyEquivalent: ""
        )
        
        var estimatedNumberPeople = "Unknown"
        if let estimatedPeopleVaccinated = vaccinationsData.estimatedPeopleVaccinated() {
            let optionalFormattedNumber = numberFormatter().string(from: estimatedPeopleVaccinated as NSNumber)
            if let formattedNumber = optionalFormattedNumber {
                estimatedNumberPeople = formattedNumber
            }
        }
        statusBarMenu.addItem(
            withTitle: "Estimated people vaccinated (real-time): \(estimatedNumberPeople)",
            action: nil,
            keyEquivalent: ""
        )

        statusBarMenu.addItem(
            withTitle: "Last updated: \(latestData.date)",
            action: nil,
            keyEquivalent: ""
        )
        
        let countryMenuItem = NSMenuItem(
            title: "Country: \(latestData.location)",
            action: nil,
            keyEquivalent: ""
        )
        countryMenuItem.submenu = createCountryMenu()
        statusBarMenu.addItem(countryMenuItem)
        
        let quitMenuItem = NSMenuItem(
            title: "Quit",
            action: #selector(quit),
            keyEquivalent: "Q"
        )
        statusBarMenu.addItem(quitMenuItem)
        
        statusBarItem?.button?.title = "\(vaccinationsData.percentageVaccinated(estimate: estimateLiveNumbers))"
        statusBarItem?.menu = statusBarMenu
    }
    
    @objc func changeCountry(_ sender: NSMenuItem) {
        vaccinationsData.changeLocation(sender.title)
        updateMenu()
    }
    
    func createCountryMenu() -> NSMenu {
        let countryMenu = NSMenu(title: "Country")
        for location in vaccinationsData.locations().sorted() {
            countryMenu.addItem(
                withTitle: location,
                action: #selector(changeCountry(_:)),
                keyEquivalent: ""
            )
        }
        return countryMenu
    }
    
    func numberFormatter() -> NumberFormatter {
        let formatter = NumberFormatter()
        formatter.locale = NSLocale.current
        formatter.numberStyle = NumberFormatter.Style.decimal
        formatter.usesGroupingSeparator = true
        return formatter
    }
    
    @objc func quit() {
        NSApplication.shared.terminate(self)
    }
}

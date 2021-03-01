import Foundation

struct VaccinationsDataRow {
    let location: String
    let isoCode: String
    let date: String
    let totalVaccinations: Int // number of doses administered
    let peopleVaccinated: Int? // number of people who received any number of doses
    let peopleFullyVaccinated: Int? // number of people who received all necessary doses
    let peopleVaccinatedPerHundred: Float?
    let peopleFullyVaccinatedPerHundred: Float?
    let dailyVaccinations: Int? // avg. estimate number of vaccinations per day
    let dailyVaccinationsPerMillion: Int? // daily vaccinations per million population
    
    init(location: String, isoCode: String, date: String, peopleVaccinated: Int?, peopleFullyVaccinated: Int?,
         peopleVaccinatedPerHundred: Float?, peopleFullyVaccinatedPerHundred: Float?,
         dailyVaccinations: Int?, dailyVaccinationsPerMillion: Int?) {
        self.location = location
        self.isoCode = isoCode
        self.date = date
        self.totalVaccinations = 0
        self.peopleVaccinated = peopleVaccinated
        self.peopleFullyVaccinated = peopleFullyVaccinated
        self.peopleVaccinatedPerHundred = peopleVaccinatedPerHundred
        self.peopleFullyVaccinatedPerHundred = peopleFullyVaccinatedPerHundred
        self.dailyVaccinations = dailyVaccinations
        self.dailyVaccinationsPerMillion = dailyVaccinationsPerMillion
    }
    
    static func empty() -> VaccinationsDataRow {
        let emptyRow = VaccinationsDataRow(
            location: "Unknown",
            isoCode: "???",
            date: "Never",
            peopleVaccinated: nil,
            peopleFullyVaccinated: nil,
            peopleVaccinatedPerHundred: nil,
            peopleFullyVaccinatedPerHundred: nil,
            dailyVaccinations: nil,
            dailyVaccinationsPerMillion: nil
        )
        return emptyRow
    }
}

class VaccinationsData {
    var rows: [VaccinationsDataRow] = []
    var location = "World"
    
    
    func load(completion: @escaping (Bool) -> ()) {
        let dataUrl = URL(string: "https://raw.githubusercontent.com/owid/covid-19-data/master/public/data/vaccinations/vaccinations.csv")!
        let task = URLSession.shared.dataTask(with: dataUrl) {(data, response, error) in
            guard let data = data else { completion(false); return }
            self.parseCsvData(csv: String(data: data, encoding: .utf8)!)
            completion(true)
        }
        task.resume()
    }
    
    func changeLocation(_ location: String) {
        self.location = location
    }
    
    func parseCsvData(csv: String?) {
        guard let csv = csv else { return }
        rows.removeAll()
        // Headers:
        // location,iso_code,date,total_vaccinations,people_vaccinated,
        // people_fully_vaccinated,daily_vaccinations_raw,daily_vaccinations,
        // total_vaccinations_per_hundred,people_vaccinated_per_hundred,
        // people_fully_vaccinated_per_hundred,daily_vaccinations_per_million
        let csvRows = csv.components(separatedBy: "\n")
        let headers = csvRows[0].components(separatedBy: ",")
        for csvRow in csvRows.dropFirst() {
            let row: [String] = csvRow.components(separatedBy: ",")
            if row.count < headers.count {
                continue
            }
            let rowData = VaccinationsDataRow(
                location: row[headers.firstIndex(of: "location")!],
                isoCode: row[headers.firstIndex(of: "iso_code")!],
                date: row[headers.firstIndex(of: "date")!],
                peopleVaccinated: Int(row[headers.firstIndex(of: "people_vaccinated")!]),
                peopleFullyVaccinated: Int(row[headers.firstIndex(of: "people_fully_vaccinated")!]),
                peopleVaccinatedPerHundred: Float(row[headers.firstIndex(of: "people_vaccinated_per_hundred")!]),
                peopleFullyVaccinatedPerHundred: Float(row[headers.firstIndex(of: "people_fully_vaccinated_per_hundred")!]),
                dailyVaccinations: Int(row[headers.firstIndex(of: "daily_vaccinations")!]),
                dailyVaccinationsPerMillion: Int(row[headers.firstIndex(of: "daily_vaccinations_per_million")!])
            )
            rows.append(rowData)
        }
    }
    
    func locations() -> [String] {
        let allLocations = rows.map { row in row.location }
        return Array(Set(allLocations))
    }
    
    func latest() -> VaccinationsDataRow {
        let locationRows = rows.filter { row in row.location == location }
        let latestRow = locationRows.max { rowA, rowB in rowA.date < rowB.date }
        return latestRow ?? VaccinationsDataRow.empty()
    }
    
    func percentageVaccinated(estimate: Bool) -> String {
        let percentage = estimate ? estimatedPeopleVaccinatedPerHundred() : latest().peopleVaccinatedPerHundred
        return asPercentage(percentage)
    }
    
    func asPercentage(_ percentage: Float?) -> String {
        if let pct = percentage {
            return String(format: "%.2f%%", pct)
        } else {
            return "--%"
        }
    }
    
    func estimatedPeopleVaccinatedPerHundred() -> Float? {
        let latestData = latest()
        if let knownPercentage = latestData.peopleVaccinatedPerHundred, let dailyRatePerMillion = latestData.dailyVaccinationsPerMillion {
            let estimatedAdditionalPercentage = Float(minutesSinceLastUpdate(latestData.date)) * additionalEstimatedPercentagePerMin(dailyRatePerMillion)
            return knownPercentage + estimatedAdditionalPercentage
        } else {
            return nil
        }
    }
    
    func estimatedPeopleVaccinated() -> Int? {
        let latestData = latest()
        if let knownVaccinations = latestData.peopleVaccinated, let dailyVaccinated = latestData.dailyVaccinations {
            let estimatedAdditionalVaccinations = Double(minutesSinceLastUpdate(latestData.date)) * additionalEstimatedVaccinationsPerMin(dailyVaccinated)
            return knownVaccinations + Int(estimatedAdditionalVaccinations)
        } else {
            return nil
        }
    }
    
    func minutesSinceLastUpdate(_ lastUpdated: String) -> Int {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.dateFormat = "yyyy-MM-dd"
        var lastUpdatedDate = dateFormatter.date(from: lastUpdated)!
        lastUpdatedDate.addTimeInterval(60 * 60 * 24) // Assume the last update happened at the end of the day
        
        let secondsSinceUpdate = Date().timeIntervalSince(lastUpdatedDate)
        return Int(secondsSinceUpdate / 60)
    }
    
    func additionalEstimatedPercentagePerMin(_ dailyRatePerMillion: Int) -> Float {
        return (Float(dailyRatePerMillion) / 1440.0) / 10000.0
    }
    
    func additionalEstimatedVaccinationsPerMin(_ dailyRate: Int) -> Double {
        return Double(dailyRate) / 1440.0
    }
}

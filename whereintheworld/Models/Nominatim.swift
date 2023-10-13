//
//  Nominatim.swift
//  whereintheworld
//
//  Created by Ian Buck on 13.10.23.
//

import Foundation

public class Nominatim {
    public class func getAddress(latitude : Double, longitude: Double) async -> NominatimLocation?
    {
        let locationTask = Task { () -> String in
            let url = URL(string: String(format:"https://nominatim.openstreetmap.org/reverse?format=json&lat=%f&lon=%f&&addressdetails=1&limit=1", latitude, longitude))!
            
            let data: Data
            
            do {
                (data,_) = try await URLSession.shared.data(from: url)
            } catch {
                print(error)
                return ""
            }
            
            if let string = String(data: data, encoding: .utf8) {
                return string
            } else {
                print("Error while parsing string response.")
            }
            
            return ""
        }
        
        let result = await locationTask.result
        
        do {
            let string = try result.get()
            
            if let location = try? JSONDecoder().decode(NominatimLocation.self, from: Data(string.utf8)) {
                print(location)
                return location
            } else {
                print("Failed to parse location.")
            }
        } catch {
            print(error)
        }
        
        return nil
    }
}

public struct NominatimLocation : Decodable {
    
    var address: NominatimAddress?
    var addresstype: String?
}

public struct NominatimAddress : Decodable {
    var country_code: String?
    var country: String?
    var state: String?
    var postcode: String?
    var town: String?
}

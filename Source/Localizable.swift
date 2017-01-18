//
//  Localizable-Swift.swift
//  JsonLocalizable
//
//  Copyright © 2017 Kekkiwaa Inc. All rights reserved.
//

import UIKit

public let LanguageChangeNotification = "LanguageChangeNotification"

public enum LocalizableInterface {
    case keyValue
    case classes
    case boot
}

public class Localizable: NSObject {
    
    // MARK: Properties
    
    /// Name of UserDefault key where store user prefered language
    private let storageKey = "localizable.swift.language"
    
    /// Json data storaged in a file
    private var json: NSDictionary?
    
    /// Shated instance
    public static let shared: Localizable = Localizable()
    
    /// Name for storaged Json Files
    /// The rule for name is fileName-LanguageKey.json
    public var fileName = "lang"
    
    /// Default language, if this can't find a key in your current language
    /// Try read key in default language
    public var defaultLanguage: Languages = .english
    
    /// Decide if your interface localization is based on LocalizableInterface
    public var localizableInterface: LocalizableInterface = .boot
    
    /// This override prevent user access to different instances for this class.
    /// Always use shared instance.
    private override init() {
        super.init()
    }
    
    // MARK: Read JSON methods

    /// This metod contains a logic to read return JSON data
    /// If JSON not is defined, this try use a default
    /// As long as the default language is the same as the current one.
    private func readJSON(reload:Bool = false) -> NSDictionary? {
        if self.json != nil && reload == false {
            return self.json
        }
        
        let lang = self.language()
        
        self.json = self.readJSON(named: "\(self.fileName)-\(lang)")
        
        if self.json == nil && lang != self.defaultLanguage.rawValue {
            self.json = self.readJSON(named: "\(self.fileName)-\(self.defaultLanguage.rawValue)")
        }
        
        return self.json
    }
    
    /// This method has path where file is
    /// If can't find a path return a nil value
    /// If can't serialize data return a nil value
    private func readJSON(named name:String) -> NSDictionary? {
        let path = Bundle.main.path(forResource: name, ofType: "json")
        if path == nil {
            return nil
        }
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: path!)) else {
            print("JSONLocalizable can't read your file")
            return nil
        }
        do {
            return try JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions.mutableContainers) as? NSDictionary
        }
        catch {
            print("JSONLocalizable can't parse your file")
            return nil
        }
    }
    
    /// Try search key in your dictionary using single level
    /// If it doesn't find the key it will use the multilevel
    /// If the key not exis in your JSON return nil value
    private func localizeFile(key:String, json:NSDictionary) -> String? {
        if let string = json[key] {
            return string as? String
        }
        
        if let string = self.localizeLevel(key: key, json: json) {
            return string
        }
        
        return nil
    }
    
    /// Try search key in your dictionary using multiples levels
    /// It is necessary that the result be a string
    /// Otherwise it returns nil value
    private func localizeLevel(key: String, json:AnyObject?) -> String? {
        let values = key.components(separatedBy: ".")
        var jsonCopy = json
        for key in values {
            if let result = jsonCopy?[key] {
                jsonCopy = result as AnyObject?
            } else {
                return nil
            }
        }
        return jsonCopy as? String
    }
    
    // Interator for String Enumerators
    private func iterateEnum<T: Hashable>(_: T.Type) -> AnyIterator<T> {
        var i = 0
        return AnyIterator {
            let next = withUnsafePointer(to: &i) {
                $0.withMemoryRebound(to: T.self, capacity: 1) { $0.pointee }
            }
            if next.hashValue != i { return nil }
            i += 1
            return next
        }
    }
    
    // MARK: Public methods
    
    /// Localize a string using your JSON File
    /// If the key is not found return the same key
    /// That prevent replace untagged values
    ///
    /// - returns: localized key or same text
    public func localize(key:String) -> String {
        guard let json = self.readJSON() else {
            return key
        }
        
        guard let string = self.localizeFile(key: key, json: json) else {
            return key
        }
        
        return string
    }
    
    /// Localize a string using your JSON File
    /// That replace all % character in your string with replace value.
    ///
    /// - parameter value: The replacement value
    ///
    /// - returns: localized key or same text
    public func localize(key:String, replace:String) -> String {
        let string = self.localize(key: key)
        if string == key {
            return key
        }
        return string.replacingOccurrences(of: "%", with: replace)
    }
    
    /// Localize a string using your JSON File
    /// That replace each % character in your string with each replace value.
    ///
    /// - parameter value: The replacement values
    ///
    /// - returns: localized key or same text
    public func localize(key:String, values replace:[Any]) -> String {
        var string = self.localize(key: key)
        if string == key {
            return key
        }
        var array = string.components(separatedBy: "%")
        string = ""
        _ = replace.count + 1
        for (index, element) in replace.enumerated() {
            if index < array.count {
                let new = array.remove(at: 0)
                string = index == 0 ? "\(new)\(element)" : "\(string)\(new)\(element) "
            }
        }
        string += array.joined(separator: "")
        string = string.replacingOccurrences(of: "  ", with: " ")
        return string
    }
    
    /// Localize string with dictionary values
    /// Get properties in your key with rule :property
    /// If property not exist in this string, not is used.
    ///
    /// - parameter value: The replacement dictionary
    ///
    /// - returns: localized key or same text
    public func localize(key:String, dictionary replace:[String:String]) -> String {
        var string = self.localize(key: key)
        for (key, value) in replace {
            string = string.replacingOccurrences(of: ":\(key)", with: value)
        }
        return string
    }

    // MARK: Config methods
    
    /// Return storaged language or default language in device
    ///
    /// - returns: current used language
    public func language() -> String {
        let defaults = UserDefaults.standard
        if let lang = defaults.string(forKey: self.storageKey) {
            return lang
        }
        return Locale.preferredLanguages[0].components(separatedBy: "-")[0]
    }
    
    /// Update default languaje, this store a language key and retrive the next time
    public func update(language:Languages) -> Void {
        let defaults = UserDefaults.standard
        defaults.setValue(language.rawValue, forKey: self.storageKey)
        defaults.synchronize()
        let _ = self.readJSON(reload: true)
        NotificationCenter.default.post(name: Notification.Name(rawValue: LanguageChangeNotification), object: nil)
    }
    
    /// Update default languaje, this store a language key and retrive the next time
    public func update(language string:String) -> Void {
        guard let language = Languages(rawValue: string) else {
            return
        }
        let defaults = UserDefaults.standard
        defaults.setValue(language.rawValue, forKey: self.storageKey)
        defaults.synchronize()
        let _ = self.readJSON(reload: true)
        NotificationCenter.default.post(name: Notification.Name(rawValue: LanguageChangeNotification), object: nil)
    }
    
    /// This remove the language key storaged.
    public func resetLanguage() -> Void {
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: self.storageKey)
        defaults.synchronize()
    }
    
    /// Show all aviable languajes whit criteria name
    ///
    /// - returns: list with storaged languages code
    public func availableLanguages() -> [String] {
        var languages : [String] = []
        for language in iterateEnum(Languages.self) {
            let name = "\(self.fileName)-\(language.rawValue)"
            let path = Bundle.main.path(forResource: name, ofType: "json")
            if path != nil {
                languages.append(language.rawValue)
            }
        }
        return languages
    }
    
    /// Display name for current user language.
    ///
    /// - return: String form language code in current user language
    public func displayNameForLanguage(_ language: String) -> String {
        let locale : NSLocale = NSLocale(localeIdentifier: self.language())
        if let name = locale.displayName(forKey: NSLocale.Key.identifier, value: language) {
            return name
        }
        return ""
    }
    
    // MARK: Static functions
    
    /// Localize a string using your JSON File
    /// If the key is not found return the same key
    /// That prevent replace untagged values
    ///
    /// - returns: localized key or same text
    public static func localize(key:String) -> String {
        return Localizable.shared.localize(key: key)
    }
    
    /// Localize a string using your JSON File
    /// That replace all % character in your string with replace value.
    ///
    /// - parameter value: The replacement value
    ///
    /// - returns: localized key or same text
    public static func localize(key:String, replace:String) -> String {
        return Localizable.shared.localize(key: key, replace: replace)
    }
    
    /// Localize a string using your JSON File
    /// That replace each % character in your string with each replace value.
    ///
    /// - parameter value: The replacement values
    ///
    /// - returns: localized key or same text
    public static func localize(key:String, values replace:[Any]) -> String {
        return Localizable.shared.localize(key: key, values: replace)
    }
    
    /// Localize string with dictionary values
    /// Get properties in your key with rule :property
    /// If property not exist in this string, not is used.
    ///
    /// - parameter value: The replacement dictionary
    ///
    /// - returns: localized key or same text
    public static func localize(key:String, dictionary replace:[String:String]) -> String {
        return Localizable.shared.localize(key: key, dictionary: replace)
    }
    
    /// Return storaged language or default language in device
    ///
    /// - returns: current used language
    public static func language() -> String {
        return Localizable.shared.language()
    }
    
    /// Update default languaje, this store a language key and retrive the next time
    public static func update(language:Languages) {
        return Localizable.shared.update(language: language)
    }
    
    /// Update default languaje, this store a language key and retrive the next time
    public static func update(language string:String) {
        return Localizable.shared.update(language: string)
    }
    
    /// This remove the language key storaged.
    public static func resetLanguage() {
        return Localizable.shared.resetLanguage()
    }
    
    /// Show all aviable languajes whit criteria name
    ///
    /// - returns: list with storaged languages code
    public static func availableLanguages() -> [String] {
        return Localizable.shared.availableLanguages()
    }
    
    /// Display name for current user language.
    ///
    /// - return: String form language code in current user language
    public static func displayNameForLanguage(_ language: String) -> String {
        return Localizable.shared.displayNameForLanguage(language)
    }
    
}

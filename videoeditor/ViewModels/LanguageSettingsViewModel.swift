//
//  LanguageSettingsViewModel.swift
//  videoeditor
//
//  Created by Anthony Ho on 18/06/2025.
//


import Foundation

@MainActor
class LanguageSettingsViewModel: ObservableObject {
    @Published var sourceLanguage: String {
        didSet {
            saveLanguages()
        }
    }
    
    init() {
        // Load saved language or default to English
        self.sourceLanguage = UserDefaults.standard.string(forKey: "sourceLanguage") ?? "en"
    }
    
    
    let availableLanguages = [
        "en": "🇺🇸 English",
        "zh": "繁 Chinese",
        "es": "🇪🇸 Spanish",
        "fr": "🇫🇷 French",
        "de": "🇩🇪 German",
        "ja": "🇯🇵 Japanese",
        "ko": "🇰🇷 Korean",
        "pt": "🇵🇹 Portuguese",
        "it": "🇮🇹 Italian",
        "ru": "🇷🇺 Russian",
        "tr": "🇹🇷 Turkish",
        "vi": "🇻🇳 Vietnamese",
        "pl": "🇵🇱 Polish",
        "uk": "🇺🇦 Ukrainian",
        "nl": "🇳🇱 Dutch",
        "ar": "🇸🇦 Arabic",
        "sv": "🇸🇪 Swedish",
        "hi": "🇮🇳 Hindi",
        "fi": "🇫🇮 Finnish",
        "no": "🇳🇴 Norwegian",
        "da": "🇩🇰 Danish",
        "he": "🇮🇱 Hebrew",
        "th": "🇹🇭 Thai",
        "cs": "🇨🇿 Czech",
        "el": "🇬🇷 Greek",
        "hu": "🇭🇺 Hungarian",
        "ro": "🇷🇴 Romanian",
        "id": "🇮🇩 Indonesian",
        "ms": "🇲🇾 Malay",
        "sk": "🇸🇰 Slovak",
        "bg": "🇧🇬 Bulgarian",
        "hr": "🇭🇷 Croatian",
        "lt": "🇱🇹 Lithuanian",
        "sl": "🇸🇮 Slovenian",
        "lv": "🇱🇻 Latvian",
        "et": "🇪🇪 Estonian",
        "tl": "🇵🇭 Tagalog",
        "kk": "🇰🇿 Kazakh"
    ]
    
    let plainEnglish = [
        "en": "English",
        "zh": "Traditional Chinese",
        "es": "Spanish",
        "fr": "French",
        "de": "German",
        "ja": "Japanese",
        "ko": "Korean",
        "pt": "Portuguese",
        "it": "Italian",
        "ru": "Russian",
        "tr": "Turkish",
        "vi": "Vietnamese",
        "pl": "Polish",
        "uk": "Ukrainian",
        "nl": "Dutch",
        "ar": "Arabic",
        "sv": "Swedish",
        "hi": "Hindi",
        "fi": "Finnish",
        "no": "Norwegian",
        "da": "Danish",
        "he": "Hebrew",
        "th": "Thai",
        "cs": "Czech",
        "el": "Greek",
        "hu": "Hungarian",
        "ro": "Romanian",
        "id": "Indonesian",
        "ms": "Malay",
        "sk": "Slovak",
        "bg": "Bulgarian",
        "hr": "Croatian",
        "lt": "Lithuanian",
        "sl": "Slovenian",
        "lv": "Latvian",
        "et": "Estonian",
        "tl": "Tagalog",
        "kk": "Kazakh"
    ]
    
    
    let translatedDisplayNames = [
        "en": "English",
        "zh": "中文",
        "es": "Español",
        "fr": "Français",
        "de": "Deutsch",
        "ja": "日本語",
        "ko": "한국어",
        "pt": "Português",
        "it": "Italiano",
        "ru": "Русский",
        "tr": "Türkçe",
        "vi": "Tiếng Việt",
        "pl": "Polski",
        "uk": "Українська",
        "nl": "Nederlands",
        "ar": "العربية",
        "sv": "Svenska",
        "hi": "हिन्दी",
        "fi": "Suomi",
        "no": "Norsk",
        "da": "Dansk",
        "he": "עברית",
        "th": "ไทย",
        "cs": "Čeština",
        "el": "Ελληνικά",
        "hu": "Magyar",
        "ro": "Română",
        "id": "Bahasa Indonesia",
        "ms": "Bahasa Melayu",
        "sk": "Slovenčina",
        "bg": "Български",
        "hr": "Hrvatski",
        "lt": "Lietuvių",
        "sl": "Slovenščina",
        "lv": "Latviešu",
        "et": "Eesti",
        "tl": "Tagalog",
        "kk": "Қазақ тілі"
    ]

       private func saveLanguages() {
        // Persist languages to UserDefaults
        UserDefaults.standard.set(sourceLanguage, forKey: "sourceLanguage")

    }
}

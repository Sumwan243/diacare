# DiaCare - Comprehensive Diabetes Management App

A modern Flutter application designed to help individuals manage their diabetes through intelligent health tracking, AI-powered insights, and proactive health monitoring.

## 🌟 Features

### 📊 Health Tracking
- **Glucose Monitoring**: Track blood sugar levels with context (before/after meals, exercise, etc.)
- **Blood Pressure Tracking**: Monitor cardiovascular health with trend analysis
- **Meal Logging**: Log meals with AI-powered nutrition estimation using Gemini API
- **Physical Activity**: Samsung-style heart-shaped step counter with daily goals
- **Hydration Tracking**: Water intake monitoring with safety limits (max 4L/day)
- **Medication Management**: Track medications and log intake confirmations

### 🤖 AI-Powered Features
- **Personal Health Assistant**: Conversational AI chatbot using Google Gemini API
- **Smart Recommendations**: Personalized health advice based on your data patterns
- **Nutrition Analysis**: AI-powered food recognition and nutritional breakdown
- **Trend Analysis**: Pattern recognition in glucose, blood pressure, and activity data

### 🔔 Smart Notifications
- **Proactive Reminders**: Intelligent notifications for logging health data
- **Activity Alerts**: Reminders to move when sedentary for too long
- **Glucose Alerts**: Immediate notifications for dangerous glucose levels (>180 or <70 mg/dL)
- **Hydration Reminders**: Smart water intake reminders throughout the day
- **Samsung Optimization**: Special handling for Samsung devices (S10 Plus tested)

### 🎨 Modern UI/UX
- **Material Design 3**: Clean, accessible interface with dark/light theme support
- **Animated Visualizations**: Heart-shaped progress indicators and water glass animations
- **Responsive Layout**: Optimized for various screen sizes
- **Color-Coded Health Status**: Visual indicators for health metrics

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (3.0 or higher)
- Dart SDK (3.0 or higher)
- Android Studio / VS Code
- Google Gemini API key (for AI features)

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/diacare-flutter-app.git
   cd diacare-flutter-app
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Set up API keys**
   - Get a Gemini API key from [Google AI Studio](https://makersuite.google.com/app/apikey)
   - Run the app with your API key:
   ```bash
   flutter run --dart-define=GEMINI_API_KEY=your_api_key_here
   ```

4. **Run the app**
   ```bash
   flutter run
   ```

## 📱 Supported Platforms

- ✅ **Android** (API level 21+)
- ✅ **iOS** (iOS 12.0+)
- 🔄 **Web** (Limited functionality)

### Tested Devices
- Samsung Galaxy S10 Plus (Android 9-12)
- Various Android devices (API 21-34)
- iOS devices (iPhone 8 and newer)

## 🏗️ Architecture

### State Management
- **Provider Pattern**: Used for state management across the app
- **Hive Database**: Local storage for health data and user preferences
- **Shared Preferences**: App settings and notification preferences

### Key Components
```
lib/
├── models/           # Data models (BloodSugarEntry, MealEntry, etc.)
├── providers/        # State management (BloodSugarProvider, AIProvider, etc.)
├── screens/          # UI screens (HomeScreen, ActivityTab, etc.)
├── services/         # Business logic (AIService, NotificationService, etc.)
├── widgets/          # Reusable UI components
└── theme/           # App theming and styling
```

## 🔧 Configuration

### AI Features Setup
1. **Gemini API**: Required for AI recommendations and nutrition analysis
2. **Nutrition Database**: Uses USDA food database for accurate nutritional data
3. **Smart Notifications**: Configurable through app settings

### Health Data Safety
- **Glucose Alerts**: Automatic alerts for dangerous levels
- **Hydration Safety**: Prevents water intoxication (4L daily limit)
- **Data Validation**: Input validation for all health metrics
- **Privacy**: All data stored locally on device

## 📊 Health Metrics Supported

| Metric | Range | Alerts | Trends |
|--------|-------|--------|--------|
| Blood Glucose | 40-600 mg/dL | <70, >180 | ✅ |
| Blood Pressure | 60-250 mmHg | >140/90 | ✅ |
| Water Intake | 0-4000 mL/day | >3500 mL | ✅ |
| Steps | 0-50,000/day | <2000 | ✅ |
| Medications | Custom | Missed doses | ✅ |

## 🤝 Contributing

We welcome contributions! Please see our [Contributing Guidelines](CONTRIBUTING.md) for details.

### Development Setup
1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🆘 Support

### Common Issues
- **Notifications not working on Samsung**: Check battery optimization settings
- **AI not responding**: Verify Gemini API key is set correctly
- **Data not syncing**: Ensure app has proper storage permissions

### Getting Help
- 📧 Email: support@diacare-app.com
- 🐛 Issues: [GitHub Issues](https://github.com/yourusername/diacare-flutter-app/issues)
- 💬 Discussions: [GitHub Discussions](https://github.com/yourusername/diacare-flutter-app/discussions)

## 🙏 Acknowledgments

- **Google Gemini AI** for powering our AI features
- **Flutter Team** for the amazing framework
- **USDA Food Database** for nutritional data
- **Material Design** for UI/UX guidelines
- **Samsung Health** for activity tracking inspiration

## 📈 Roadmap

### Upcoming Features
- [ ] Apple Health / Google Fit integration
- [ ] Continuous Glucose Monitor (CGM) support
- [ ] Insulin dosage calculator
- [ ] Doctor/caregiver sharing features
- [ ] Advanced analytics dashboard
- [ ] Wear OS / Apple Watch support

### Version History
- **v1.0.0** - Initial release with core features
- **v1.1.0** - Added AI chatbot and smart notifications
- **v1.2.0** - Enhanced Samsung device support
- **v1.3.0** - Added hydration tracking with safety limits

---

**⚠️ Medical Disclaimer**: This app is for informational purposes only and should not replace professional medical advice. Always consult with your healthcare provider for medical decisions.

**Made with ❤️ for the diabetes community**
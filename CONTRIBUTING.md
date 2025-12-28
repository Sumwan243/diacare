# Contributing to DiaCare

Thank you for your interest in contributing to DiaCare! This document provides guidelines and information for contributors.

## 🤝 How to Contribute

### Reporting Issues
- Use the [GitHub Issues](https://github.com/yourusername/diacare-flutter-app/issues) page
- Search existing issues before creating a new one
- Provide detailed information including:
  - Device and OS version
  - Steps to reproduce
  - Expected vs actual behavior
  - Screenshots if applicable

### Suggesting Features
- Open a [GitHub Discussion](https://github.com/yourusername/diacare-flutter-app/discussions)
- Describe the feature and its benefits
- Consider the medical/health implications
- Provide mockups or examples if possible

## 🛠️ Development Guidelines

### Code Style
- Follow [Dart Style Guide](https://dart.dev/guides/language/effective-dart/style)
- Use meaningful variable and function names
- Add comments for complex medical calculations
- Maintain consistent formatting with `dart format`

### Medical Safety
- **Critical**: All health-related features must be medically safe
- Validate input ranges for all health metrics
- Include appropriate warnings and disclaimers
- Test edge cases thoroughly
- Never provide medical advice - only informational content

### Testing
- Write unit tests for business logic
- Test on multiple devices and OS versions
- Verify notification functionality
- Test with various data scenarios (empty, normal, extreme values)

### Pull Request Process
1. Fork the repository
2. Create a feature branch from `main`
3. Make your changes following the guidelines
4. Test thoroughly on real devices
5. Update documentation if needed
6. Submit a pull request with:
   - Clear description of changes
   - Screenshots/videos for UI changes
   - Test results
   - Medical safety considerations

## 📋 Development Setup

### Prerequisites
```bash
flutter doctor  # Ensure Flutter is properly installed
```

### Local Development
```bash
git clone https://github.com/yourusername/diacare-flutter-app.git
cd diacare-flutter-app
flutter pub get
flutter run --dart-define=GEMINI_API_KEY=your_key
```

### Testing
```bash
flutter test                    # Unit tests
flutter test integration_test/  # Integration tests
flutter analyze                 # Static analysis
```

## 🏥 Medical Considerations

### Health Data Handling
- All health data must be stored locally
- Implement proper data validation
- Include safety limits (e.g., glucose ranges)
- Provide clear error messages

### AI Features
- AI responses must be informational only
- Include medical disclaimers
- Avoid definitive medical statements
- Test with various health scenarios

### Notifications
- Respect user preferences
- Provide clear opt-out mechanisms
- Use appropriate urgency levels
- Test on different devices/OS versions

## 📚 Resources

### Flutter Development
- [Flutter Documentation](https://docs.flutter.dev/)
- [Dart Language Guide](https://dart.dev/guides)
- [Material Design 3](https://m3.material.io/)

### Medical Guidelines
- [FDA Mobile Medical Apps Guidance](https://www.fda.gov/medical-devices/digital-health-center-excellence/mobile-medical-applications)
- [Diabetes Management Guidelines](https://www.diabetes.org/)
- [Blood Glucose Monitoring Standards](https://care.diabetesjournals.org/)

### API Documentation
- [Google Gemini AI](https://ai.google.dev/docs)
- [Flutter Local Notifications](https://pub.dev/packages/flutter_local_notifications)
- [Hive Database](https://docs.hivedb.dev/)

## 🚫 What Not to Contribute

- Medical advice or diagnostic features
- Features that could be harmful if misused
- Proprietary medical algorithms
- Personal health data or API keys
- Code that bypasses safety validations

## 📞 Getting Help

- **Technical Questions**: Open a GitHub Discussion
- **Bug Reports**: Create a GitHub Issue
- **Security Issues**: Email security@diacare-app.com
- **Medical Questions**: Consult healthcare professionals

## 🏆 Recognition

Contributors will be recognized in:
- README.md acknowledgments
- Release notes for significant contributions
- Special contributor badge (for major features)

## 📄 License

By contributing, you agree that your contributions will be licensed under the MIT License.

---

**Remember**: This app helps people manage a serious medical condition. Every contribution should prioritize user safety and well-being.

Thank you for helping make diabetes management easier and safer! 💙
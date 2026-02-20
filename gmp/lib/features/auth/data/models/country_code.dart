/// Model class for country dialing codes
class CountryCode {
  final String name;
  final String code;
  final String dialCode;
  final String flag;

  const CountryCode({
    required this.name,
    required this.code,
    required this.dialCode,
    required this.flag,
  });

  /// List of popular countries
  static const List<CountryCode> popularCountries = [
    CountryCode(name: 'India', code: 'IN', dialCode: '+91', flag: '🇮🇳'),
    CountryCode(name: 'United States', code: 'US', dialCode: '+1', flag: '🇺🇸'),
    CountryCode(name: 'United Kingdom', code: 'GB', dialCode: '+44', flag: '🇬🇧'),
    CountryCode(name: 'Canada', code: 'CA', dialCode: '+1', flag: '🇨🇦'),
    CountryCode(name: 'Australia', code: 'AU', dialCode: '+61', flag: '🇦🇺'),
    CountryCode(name: 'Germany', code: 'DE', dialCode: '+49', flag: '🇩🇪'),
    CountryCode(name: 'France', code: 'FR', dialCode: '+33', flag: '🇫🇷'),
    CountryCode(name: 'Singapore', code: 'SG', dialCode: '+65', flag: '🇸🇬'),
    CountryCode(name: 'UAE', code: 'AE', dialCode: '+971', flag: '🇦🇪'),
    CountryCode(name: 'Saudi Arabia', code: 'SA', dialCode: '+966', flag: '🇸🇦'),
  ];

  /// Get all countries
  static List<CountryCode> getAllCountries() {
    return [
      ...popularCountries,
      const CountryCode(name: 'Afghanistan', code: 'AF', dialCode: '+93', flag: '🇦🇫'),
      const CountryCode(name: 'Bangladesh', code: 'BD', dialCode: '+880', flag: '🇧🇩'),
      const CountryCode(name: 'Brazil', code: 'BR', dialCode: '+55', flag: '🇧🇷'),
      const CountryCode(name: 'China', code: 'CN', dialCode: '+86', flag: '🇨🇳'),
      const CountryCode(name: 'Indonesia', code: 'ID', dialCode: '+62', flag: '🇮🇩'),
      const CountryCode(name: 'Japan', code: 'JP', dialCode: '+81', flag: '🇯🇵'),
      const CountryCode(name: 'Malaysia', code: 'MY', dialCode: '+60', flag: '🇲🇾'),
      const CountryCode(name: 'Mexico', code: 'MX', dialCode: '+52', flag: '🇲🇽'),
      const CountryCode(name: 'Nepal', code: 'NP', dialCode: '+977', flag: '🇳🇵'),
      const CountryCode(name: 'New Zealand', code: 'NZ', dialCode: '+64', flag: '🇳🇿'),
      const CountryCode(name: 'Nigeria', code: 'NG', dialCode: '+234', flag: '🇳🇬'),
      const CountryCode(name: 'Pakistan', code: 'PK', dialCode: '+92', flag: '🇵🇰'),
      const CountryCode(name: 'Philippines', code: 'PH', dialCode: '+63', flag: '🇵🇭'),
      const CountryCode(name: 'Russia', code: 'RU', dialCode: '+7', flag: '🇷🇺'),
      const CountryCode(name: 'South Africa', code: 'ZA', dialCode: '+27', flag: '🇿🇦'),
      const CountryCode(name: 'South Korea', code: 'KR', dialCode: '+82', flag: '🇰🇷'),
      const CountryCode(name: 'Spain', code: 'ES', dialCode: '+34', flag: '🇪🇸'),
      const CountryCode(name: 'Sri Lanka', code: 'LK', dialCode: '+94', flag: '🇱🇰'),
      const CountryCode(name: 'Thailand', code: 'TH', dialCode: '+66', flag: '🇹🇭'),
      const CountryCode(name: 'Vietnam', code: 'VN', dialCode: '+84', flag: '🇻🇳'),
    ];
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CountryCode &&
          runtimeType == other.runtimeType &&
          code == other.code;

  @override
  int get hashCode => code.hashCode;
}

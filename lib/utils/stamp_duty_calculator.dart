import 'dart:math';

double _ceilDiv100(double value) {
  return (value / 100).ceilToDouble();
}

double calculateStampDuty({
  required String state,
  required double propertyValue,
}) {
  final C4 = propertyValue;

  switch (state) {
    case 'NSW':
      if (C4 <= 14000) return C4 * 0.0125;
      if (C4 <= 31000) return 175 + (C4 - 14000) * 0.015;
      if (C4 <= 83000) return 430 + (C4 - 31000) * 0.0175;
      if (C4 <= 313000) return 1340 + (C4 - 83000) * 0.035;
      if (C4 <= 1043000) return 9390 + (C4 - 313000) * 0.045;
      if (C4 <= 3130000) return 42240 + (C4 - 1043000) * 0.055;
      return 160874 + (C4 - 3130000) * 0.07;

    case 'WA':
      if (C4 <= 120000) return (C4 / 100) * 1.9;
      if (C4 <= 150000) return 2280 + ((C4 - 120000) / 100) * 2.85;
      if (C4 <= 360000) return 3135 + ((C4 - 150000) / 100) * 3.8;
      if (C4 <= 725000) return 11115 + ((C4 - 360000) / 100) * 4.75;
      return 28453 + ((C4 - 725000) / 100) * 5.15;

    case 'QLD':
      if (C4 <= 5000) return 0;
      if (C4 <= 75000) return _ceilDiv100(C4 - 5000) * 1.5;
      if (C4 <= 540000) return 1050 + _ceilDiv100(C4 - 75000) * 3.5;
      if (C4 <= 1000000) return 17325 + _ceilDiv100(C4 - 540000) * 4.5;
      return 38025 + _ceilDiv100(C4 - 1000000) * 5.75;

    case 'VIC':
      if (C4 <= 25000) return C4 * 0.014;
      if (C4 <= 130000) return 350 + (C4 - 25000) * 0.024;
      if (C4 <= 960000) return 2870 + (C4 - 130000) * 0.06;
      return C4 * 0.055;

    case 'TAS':
      if (C4 <= 3000) return 50;
      if (C4 <= 25000) return 50 + _ceilDiv100(C4 - 3000) * 1.75;
      if (C4 <= 75000) return 435 + _ceilDiv100(C4 - 25000) * 2.25;
      if (C4 <= 200000) return 1560 + _ceilDiv100(C4 - 75000) * 3.5;
      if (C4 <= 375000) return 5935 + _ceilDiv100(C4 - 200000) * 4;
      if (C4 <= 725000) return 12935 + _ceilDiv100(C4 - 375000) * 4.25;
      return 27810 + _ceilDiv100(C4 - 725000) * 4.5;

    case 'NT':
      if (C4 <= 525000) return 0.06571441 * C4 + 15 * (C4 / 1000);
      if (C4 <= 3000000) return C4 * 0.0495;
      if (C4 <= 5000000) return C4 * 0.0575;
      return C4 * 0.0595;

    case 'ACT':
      if (C4 <= 260000) return _ceilDiv100(C4) * 0.28;
      if (C4 <= 300000) return 728 + _ceilDiv100(C4 - 260000) * 2.2;
      if (C4 <= 500000) return 1608 + _ceilDiv100(C4 - 300000) * 3.4;
      if (C4 <= 750000) return 8408 + _ceilDiv100(C4 - 500000) * 4.32;
      if (C4 <= 1000000) return 19208 + _ceilDiv100(C4 - 750000) * 5.9;
      if (C4 <= 1455000) return 33958 + _ceilDiv100(C4 - 1000000) * 6.4;
      return _ceilDiv100(C4) * 4.54;

    case 'SA':
      if (C4 <= 12000) return _ceilDiv100(C4) * 1;
      if (C4 <= 30000) return 120 + _ceilDiv100(C4 - 12000) * 2;
      if (C4 <= 50000) return 480 + _ceilDiv100(C4 - 30000) * 3;
      if (C4 <= 100000) return 1080 + _ceilDiv100(C4 - 50000) * 3.5;
      if (C4 <= 200000) return 2830 + _ceilDiv100(C4 - 100000) * 4;
      if (C4 <= 250000) return 6830 + _ceilDiv100(C4 - 200000) * 4.25;
      if (C4 <= 300000) return 8955 + _ceilDiv100(C4 - 250000) * 4.75;
      if (C4 <= 500000) return 11330 + _ceilDiv100(C4 - 300000) * 5;
      return 21330 + _ceilDiv100(C4 - 500000) * 5.5;

    default:
      return 0;
  }
}

double calculateMonthlyMortgage({
  required double propertyValue,
  required double lvrPercent,
  required double annualInterestPercent,
}) {
  final loanAmount = propertyValue * (lvrPercent / 100.0);
  final monthlyRate = (annualInterestPercent / 100.0) / 12.0;
  const n = 360; // 30 years

  if (monthlyRate == 0) {
    return loanAmount / n;
  }

  final numerator = loanAmount * pow(1 + monthlyRate, n) * monthlyRate;
  final denominator = pow(1 + monthlyRate, n) - 1;
  return numerator / denominator;
}

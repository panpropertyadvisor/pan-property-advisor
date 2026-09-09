bool isValidEmail(String value) {
  return value.contains('@') && value.contains('.com');
}

bool isNumeric(String value) {
  return RegExp(r'^[0-9]+$').hasMatch(value);
}

bool isAlphaNumeric(String value) {
  return RegExp(r'^[a-zA-Z0-9 ]+$').hasMatch(value);
}

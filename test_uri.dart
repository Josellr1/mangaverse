void main() {
  print(Uri.parse('https://a.com').replace(queryParameters: {'includes[]': ['a', 'b']}).toString());
}

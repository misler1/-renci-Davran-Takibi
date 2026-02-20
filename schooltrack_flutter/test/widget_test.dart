import 'package:flutter_test/flutter_test.dart';
import 'package:schooltrack_flutter/main.dart';

void main() {
  testWidgets('renders login screen', (tester) async {
    await tester.pumpWidget(const SchoolTrackApp());
    expect(find.text('SchoolTrack'), findsWidgets);
    expect(find.text('Sign In'), findsOneWidget);
  });
}

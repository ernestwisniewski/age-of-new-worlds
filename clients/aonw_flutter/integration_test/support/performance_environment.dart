const performanceBuildMode = bool.fromEnvironment('dart.vm.profile')
    ? 'flutter-device-profile'
    : 'flutter-test-device-debug';

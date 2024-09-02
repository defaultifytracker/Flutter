import 'package:flutter_test/flutter_test.dart';
import 'package:defaultify_plugin/defaultify_plugin.dart';
import 'package:defaultify_plugin/defaultify_plugin_platform_interface.dart';
import 'package:defaultify_plugin/defaultify_plugin_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockDefaultifyPluginPlatform
    with MockPlatformInterfaceMixin
    implements DefaultifyPluginPlatform {
  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final DefaultifyPluginPlatform initialPlatform =
      DefaultifyPluginPlatform.instance;

  test('$MethodChannelDefaultifyPlugin is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelDefaultifyPlugin>());
  });

  test('getPlatformVersion', () async {
    DefaultifyPlugin defaultifyPlugin = DefaultifyPlugin();
    MockDefaultifyPluginPlatform fakePlatform = MockDefaultifyPluginPlatform();
    DefaultifyPluginPlatform.instance = fakePlatform;

    expect(await defaultifyPlugin.getPlatformVersion(), '42');
  });
}

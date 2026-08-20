#!/usr/bin/env ruby
# Adds the WidgetKit extension to ios/Runner.xcodeproj.
#
# Flutter's `create` does not know about app extensions, and a hand-edited
# project.pbxproj is a merge conflict waiting to happen — so the target is
# built here instead, idempotently: running it twice leaves one target.
require 'set'
require 'xcodeproj'

ROOT = File.expand_path('..', __dir__)
PROJECT = File.join(ROOT, 'ios', 'Runner.xcodeproj')
TARGET_NAME = 'AtmosFlowWidgetExtension'
APP_GROUP = 'group.com.surajshetty.atmosFlow'
BUNDLE_ID = 'com.surajshetty.atmosFlow.AtmosFlowWidget'
TEAM = '9MV9L388X7'

project = Xcodeproj::Project.open(PROJECT)
runner = project.targets.find { |t| t.name == 'Runner' }
abort 'No Runner target' unless runner

# ── The app group both sides read ─────────────────────────────────────────
runner_entitlements = File.join(ROOT, 'ios', 'Runner', 'Runner.entitlements')
unless File.exist?(runner_entitlements)
  File.write(runner_entitlements, <<~PLIST)
    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
    <plist version="1.0">
    <dict>
    \t<key>com.apple.security.application-groups</key>
    \t<array>
    \t\t<string>#{APP_GROUP}</string>
    \t</array>
    </dict>
    </plist>
  PLIST
end
runner_group = project.main_group['Runner']
unless runner_group.files.any? { |f| f.display_name == 'Runner.entitlements' }
  runner_group.new_reference('Runner.entitlements')
end
runner.build_configurations.each do |config|
  config.build_settings['CODE_SIGN_ENTITLEMENTS'] = 'Runner/Runner.entitlements'
end

# ── The extension target ──────────────────────────────────────────────────
project.targets.select { |t| t.name == TARGET_NAME }.each do |existing|
  # The product reference lives in Products, not in the target, so dropping the
  # target alone leaves a stray .appex behind on every run.
  existing.product_reference&.remove_from_project
  existing.remove_from_project
end
project.main_group.children
       .select { |g| g.display_name == 'AtmosFlowWidget' }
       .each(&:remove_from_project)

target = project.new_target(:app_extension, TARGET_NAME, :ios, '17.0')

group = project.main_group.new_group('AtmosFlowWidget', 'AtmosFlowWidget')
sources = Dir[File.join(ROOT, 'ios', 'AtmosFlowWidget', '*.swift')].sort
sources.each do |path|
  ref = group.new_reference(File.basename(path))
  target.source_build_phase.add_file_reference(ref)
end
group.new_reference('Info.plist')
group.new_reference('AtmosFlowWidget.entitlements')

# The design's type is Figtree throughout; an extension has its own bundle, so
# the faces have to be copied into it as well as into the app.
fonts_group = group.new_group('Fonts', '../../assets/fonts')
Dir[File.join(ROOT, 'assets', 'fonts', 'Figtree-*.ttf')].sort.each do |path|
  ref = fonts_group.new_reference(File.basename(path))
  target.resources_build_phase.add_file_reference(ref)
end

target.build_configurations.each do |config|
  config.build_settings.merge!(
    'PRODUCT_BUNDLE_IDENTIFIER' => BUNDLE_ID,
    'PRODUCT_NAME' => 'AtmosFlowWidget',
    'INFOPLIST_FILE' => 'AtmosFlowWidget/Info.plist',
    'CODE_SIGN_ENTITLEMENTS' => 'AtmosFlowWidget/AtmosFlowWidget.entitlements',
    'DEVELOPMENT_TEAM' => TEAM,
    'SWIFT_VERSION' => '5.0',
    'IPHONEOS_DEPLOYMENT_TARGET' => '17.0',
    'TARGETED_DEVICE_FAMILY' => '1,2',
    'SKIP_INSTALL' => 'YES',
    'GENERATE_INFOPLIST_FILE' => 'NO',
    'CURRENT_PROJECT_VERSION' => '1',
    'MARKETING_VERSION' => '1.0',
    'ALWAYS_EMBED_SWIFT_STANDARD_LIBRARIES' => 'NO',
    # An extension's version has to match its host app's. Flutter passes these
    # in from pubspec on its own builds; plain `xcodebuild` does not, and an
    # empty CFBundleVersion fails validation, so the target carries defaults.
    'FLUTTER_BUILD_NAME' => '$(FLUTTER_BUILD_NAME:default=0.1.0)',
    'FLUTTER_BUILD_NUMBER' => '$(FLUTTER_BUILD_NUMBER:default=1)'
  )
end

# ── Embed it in the app ───────────────────────────────────────────────────
# Removing the old target leaves Runner holding a dependency that points at
# nothing, which `add_dependency` trips over on the next run.
runner.dependencies.select { |d| d.target.nil? }.each(&:remove_from_project)
runner.add_dependency(target)
embed = runner.build_phases.find do |phase|
  phase.respond_to?(:name) && phase.name == 'Embed App Extensions'
end
embed ||= begin
  phase = runner.new_copy_files_build_phase('Embed App Extensions')
  phase.symbol_dst_subfolder_spec = :plug_ins
  phase
end
embed.files.each(&:remove_from_project)
build_file = embed.add_file_reference(target.product_reference)
build_file.settings = { 'ATTRIBUTES' => ['RemoveHeadersOnCopy'] }

# Flutter's own "Thin Binary" phase walks the built app looking for binaries to
# strip, so the extension has to be inside it by then. Left at the end of the
# list the two phases each wait on the other and Xcode reports a cycle.
runner.build_phases.delete(embed)
thin = runner.build_phases.index do |phase|
  phase.respond_to?(:name) && phase.name == 'Thin Binary'
end
runner.build_phases.insert(thin || runner.build_phases.count, embed)

# ── The render harness ────────────────────────────────────────────────────
# RunnerTests renders every tile to a PNG, so it needs the widget's own
# sources — all but the bundle entry point, since `@main` has no place in a
# test bundle. Re-wired here rather than separately: rebuilding the target
# above replaces the file references these point at.
tests = project.targets.find { |t| t.name == 'RunnerTests' }
if tests
  own = ['WidgetRenderTests.swift']
  tests.source_build_phase.files
       .reject { |f| own.include?(f.display_name) }
       .each(&:remove_from_project)
  group.files.each do |file|
    next unless file.display_name.end_with?('.swift')
    next if file.display_name == 'AtmosFlowWidget.swift'
    tests.source_build_phase.add_file_reference(file)
  end

  tests_group = project.main_group['RunnerTests'] ||
                project.main_group.new_group('RunnerTests', 'RunnerTests')
  unless tests_group.files.any? { |f| f.display_name == 'WidgetRenderTests.swift' }
    ref = tests_group.new_reference('WidgetRenderTests.swift')
    tests.source_build_phase.add_file_reference(ref)
  end
  tests.build_configurations.each do |config|
    config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '17.0'
  end
end

# ── Sweep up after ourselves ──────────────────────────────────────────────
# Rebuilding the target above detaches its old groups and file references
# without deleting them, so a project edited a few times over accumulates
# objects nothing points at any more. Walk down from the main group and the
# build phases, and drop every file, reference and group the walk never
# reaches.
def reachable(group, seen)
  group.children.each do |child|
    next unless seen.add?(child)
    reachable(child, seen) if child.respond_to?(:children)
  end
  seen
end

live = reachable(project.main_group, Set.new([project.main_group]))
project.objects.select { |o| o.isa.end_with?('BuildPhase') }.each do |phase|
  phase.files.each { |f| live << f }
end

project.objects
       .select { |o| %w[PBXBuildFile PBXFileReference PBXGroup].include?(o.isa) }
       .reject { |o| live.include?(o) }
       .each(&:remove_from_project)

project.save
puts "Added #{TARGET_NAME} (#{sources.size} sources) to #{PROJECT}"

# Adds the RoundTimerWidgets Live Activity extension target to the Xcode
# project. Idempotent: safe to re-run (bails if the target exists).
#
#   ruby tool/add_widget_target.rb
require 'xcodeproj'

project_path = File.expand_path('../ios/Runner.xcodeproj', __dir__)
project = Xcodeproj::Project.open(project_path)

if project.targets.any? { |t| t.name == 'RoundTimerWidgets' }
  puts 'RoundTimerWidgets target already exists — nothing to do.'
  exit 0
end

runner = project.targets.find { |t| t.name == 'Runner' }
abort 'Runner target not found' unless runner

# --- Widget extension target -------------------------------------------------
widget = project.new_target(
  :app_extension, 'RoundTimerWidgets', :ios, '17.0')

widget.build_configurations.each do |config|
  bs = config.build_settings
  bs['PRODUCT_BUNDLE_IDENTIFIER'] = 'com.crisboxing11.roundtimer.widgets'
  bs['INFOPLIST_FILE'] = 'RoundTimerWidgets/Info.plist'
  bs['SWIFT_VERSION'] = '5.0'
  bs['IPHONEOS_DEPLOYMENT_TARGET'] = '17.0'
  bs['TARGETED_DEVICE_FAMILY'] = '1,2'
  bs['CODE_SIGN_STYLE'] = 'Automatic'
  bs['DEVELOPMENT_TEAM'] = 'DW8WVJMN78'
  bs['MARKETING_VERSION'] = '$(FLUTTER_BUILD_NAME)'
  bs['CURRENT_PROJECT_VERSION'] = '$(FLUTTER_BUILD_NUMBER)'
  bs['SKIP_INSTALL'] = 'YES'
  bs['ASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS'] = 'NO'
end

# --- Files -------------------------------------------------------------------
group = project.main_group.new_group('RoundTimerWidgets', 'RoundTimerWidgets')
attrs_ref = group.new_file('RoundActivityAttributes.swift')
widget_ref = group.new_file('RoundTimerLiveActivity.swift')
group.new_file('Info.plist')

widget.add_file_references([attrs_ref, widget_ref])

# The attributes type and the bridge are compiled into the app too.
runner_group = project.main_group['Runner']
bridge_ref = runner_group.new_file('LiveActivityBridge.swift')
runner.add_file_references([attrs_ref, bridge_ref])

# --- Embed the extension in Runner -------------------------------------------
embed = runner.new_copy_files_build_phase('Embed Foundation Extensions')
embed.dst_subfolder_spec = '13' # PlugIns
bf = embed.add_file_reference(widget.product_reference)
bf.settings = { 'ATTRIBUTES' => ['RemoveHeadersOnCopy'] }

runner.add_dependency(widget)

project.save
puts 'RoundTimerWidgets target added.'

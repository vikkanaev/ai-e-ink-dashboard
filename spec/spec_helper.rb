$LOAD_PATH.unshift File.join(__dir__, '..', 'services')
$LOAD_PATH.unshift File.join(__dir__, '..', 'widgets')
$LOAD_PATH.unshift File.join(__dir__, '..', 'routes')
$LOAD_PATH.unshift File.join(__dir__, '..')

require_relative 'support/spec_helper'

# frozen_string_literal: true

# Copyright 2021 Dick Davis
#
# This file is part of algoheader.
#
# algoheader is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# algoheader is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with algoheader.  If not, see <http://www.gnu.org/licenses/>.

##
# = /lib/algoheader.rb
# Author::    Dick Davis
# Copyright:: Copyright 2021 Dick Davis
# License::   GNU Public License 3
#
# Main application file that loads other files.

require 'algoheader/helpers'
require 'algoheader/png_transformer'
require 'algoheader/svg_generator'
require 'algoheader/version'

require 'optparse'
require 'English'
require 'fileutils'
require 'yaml'

trap('INT') do
  puts "\nTerminating..."
  exit
end

options = {}

# rubocop:disable Metrics/BlockLength
optparse = OptionParser.new do |opts|
  opts.banner = 'Usage: algoheader [options]'

  opts.on('-c', '--config FILE', 'Specifies the configuration file to use.') do |config|
    options[:config] = config
  end

  opts.on('-d', '--directory NAME', 'Sets the output directory.') do |dir|
    options[:dir] = dir
  end

  opts.on('-i', '--images NUMBER', 'Sets the number of images to generate (max 99.)') do |images|
    options[:images] = images.to_i > 99 ? 99 : images.to_i
  end

  opts.on('-r', '--raster', 'Create PNG copies of the generated SVGs.') do
    options[:raster] = true
  end

  opts.on('-l', '--license', 'Displays the copyright notice') do
    puts "This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.
"
  end

  opts.on('-w', '--warranty', 'Displays the warranty statement') do
    puts "This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.
"
  end

  opts.on('-v', '--version', 'Displays the program version') do
    puts "algoheader v#{Algoheader::VERSION}"
  end

  opts.on_tail('-h', '--help', 'Displays the help screen') do
    puts opts
    exit
  end
end
# rubocop:enable Metrics/BlockLength

begin
  optparse.parse!
rescue OptionParser::InvalidOption, OptionParser::MissingArgument
  puts $ERROR_INFO.to_s
  puts 'Use -h or --help for options.'
  exit 1
end

output_dir = options[:dir] || 'algoheader_output'
FileUtils.mkdir_p(output_dir)

config_file = options[:config] || Algoheader::Helpers.config_from_home
config = YAML.load_file(config_file)

selection = Algoheader::Helpers.selection_from_user(config)

(options[:images] || 50).times do |index|
  filename = "#{selection[:name]}_#{(index + 1).to_s.rjust(2, '0')}"

  svg_blob = Algoheader::SvgGenerator.call(**selection.slice(:fill_colors, :stroke_colors))
  File.write("#{output_dir}/#{filename}.svg", svg_blob)

  Algoheader::PngTransformer.call(svg_blob, output_dir, filename) if options[:raster]
end

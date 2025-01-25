#!/usr/bin/ruby

require 'optparse'
require 'logger'
require 'toml-rb'
require 'pathname'
require "fileutils"



# APP_NAME = "Tiny Brute"
INPUT_FILENAME_EXTENSION = "page.brute"
OUTPUT_FILENAME_EXTENSION = "html"
PROJECT_DIR_ARG_NAME = "PROJECT_DIRECTORY"
DEFAULT_PROJECT_DIR = Dir.pwd
DEFAULT_GENERATE_DIR = "work-in-progress"
DEFAULT_PUBLISH_DIR = "published"

CMD_GENERATE = "generate"
CMD_CLEAN_AND_GENERATE = "clean-and-generate"
CMD_PUBLISH = "publish"
COMMANDS = [ CMD_GENERATE, CMD_CLEAN_AND_GENERATE, CMD_PUBLISH ]

config = { project_dir: DEFAULT_PROJECT_DIR }



##############################################################################
# Initialise logging
#
logger = Logger.new(STDERR)
logger.level = Logger::DEBUG



##############################################################################
# Parse command line options/switches and remove them from ARGV.
#
# Removal of options/switches and their associated arguments from ARGV is a
# side effect of calling OptionParser#parse! Afterwards, ARGV will only contain
# "positional" arguments.

OptionParser.new do |parser|

  # The only permitted command line option is a request for usage instructions
  # triggered by -h or --help
  parser.banner =
    "Usage: #{File.basename(__FILE__)} [OPTIONS] COMMAND

COMMANDS:
    #{CMD_GENERATE} (default command)
        generate site in the work-in-progress directory
        default directory: #{PROJECT_DIR_ARG_NAME}/#{DEFAULT_GENERATE_DIR}
    #{CMD_CLEAN_AND_GENERATE}
        delete contents of the work-in-progress directory and then generate
        site there
    #{CMD_PUBLISH}
        generate site in a new, (probably) uniquely-named directory
        default directory: #{PROJECT_DIR_ARG_NAME}/#{DEFAULT_PUBLISH_DIR}/<timestamp-derived name>

OPTIONS:"

  parser.on(
    "-d #{PROJECT_DIR_ARG_NAME}", # no square brackets, therefore mandatory argument
    "--project-dir",
    "The directory of the project to process (default = present working directory)"
  ) do | dir |
    config[:project_dir] = File.expand_path( dir )
  end

  # Can change option parsing error messages by rescuing errors, e.g...
  # rescue OptionParser::InvalidOption => e
  # rescue OptionParser::InvalidArgument => e

end.parse!
# Only positional arguments are left in ARGV.
# OptionParser has removed all options/switches and their arguments.

logger.info( "Generating static site from project at " + config[:project_dir] )



##############################################################################
# Parse the requested command from the positional command line arguments
# 

if ARGV.length > 1
  logger.error( "Too many arguments. Expected one of #{COMMANDS} (or nothing). Got: #{ARGV}" )
  abort()

elsif ARGV.length == 1
  command = COMMANDS.find do |x| x.start_with?( ARGV[0] ) end
  if command.nil?
    logger.error( "Unknown command '#{ARGV[0]}'. Expected one of #{COMMANDS} (or nothing)." )
    abort()
  end

else
  command = CMD_GENERATE

end

logger.info( "Executing command: #{command}" )



##############################################################################
# Define default config
#

config[:input_dir] = File.join( config[:project_dir], 'input' )
config[:plugins_dir] = File.join( config[:project_dir], 'plugins' )

config[:output_dir] =
  if command == CMD_PUBLISH
    # Including nanoseconds in the output dir name in case this script is run
    # more than once in the same second.
    File.join( config[:project_dir], DEFAULT_PUBLISH_DIR, Time.now.strftime('%Y-%m-%d--%H-%M--%S.%N') )
  else
    File.join( config[:project_dir], DEFAULT_GENERATE_DIR )
  end

logger.info("Loaded config: \n" + config.to_s)



##############################################################################
# Create output dir if it doesn't exist.
#
# TO DO: Test whether this is redundant. It might be accomplished by directory
#        creation while processing and copying from the input directory.

FileUtils.mkdir_p( config[:output_dir] )



##############################################################################
# Clean output directory if appropriate.
#

if command == CMD_CLEAN_AND_GENERATE
  FileUtils.rm_rf( Dir.glob( "work-in-progress/*", File::FNM_DOTMATCH ) )
end



##############################################################################
# Initialise plugins
#

# 1) define class a plugin manager

class Plugins

  @@plugins = []

  def self.register( plugin )
    @@plugins << plugin
  end

  def self.inflate_page( output_path, properties, markup, logger )
    @@plugins.each do |p|
      markup = p.modify_page_markup( output_path, properties, markup, logger )
    end
    markup
  end

  def self.finalise( input_dir, output_dir,logger )
    @@plugins.each do |p|
      p.finalise( input_dir, output_dir, logger )
    end
  end
end


# 2) require all ruby files in the plugins_dir
#    on require, each ruby file should automatically register its plugin(s)

Dir[ File.join( config[:plugins_dir], "*.rb" ) ].each do |file|
  require file
  logger.info("Required plugin file: " + file)
end


# 3) TEST:
logger.debug( "Testing example plugin... (This requires the example plugin or equivalent functionality.)" )
logger.debug( Plugins.inflate_page(
  "debug.html",
  {"main-content"=>"<p>This paragraph was injected into the template!</p>"},
  "<html><body><div id='main-content'></div></body></html>",
  logger
))



##############################################################################
# Process contents of input directory and copy results to output directory.
#

# For each path in the input directory, including "hidden" files and
# directories like .htaccess
#
Dir.glob( File.join( config[:input_dir], "**/*" ), File::FNM_DOTMATCH ) do | input_path |

  logger.info( "Processing input path: #{input_path}" )


  # Calculate the output path.
  # Later code might alter the output path for this particular file.
  p = Pathname.new( input_path )
  output_path = File.join(
    config[:output_dir],
    p.relative_path_from( Pathname.new( config[:input_dir] ) )
  )


  if File.directory?( input_path )

    # make the relevant output subdirectory if it does not exist
    FileUtils.mkdir_p( output_path )


  elsif input_path.end_with?( INPUT_FILENAME_EXTENSION )

    # Modify the extension of the output file, e.g. .content -> .html
    output_path = output_path.delete_suffix(
      INPUT_FILENAME_EXTENSION ) + OUTPUT_FILENAME_EXTENSION

    # Load the page properties from the input file
    page_properties = TomlRB.load_file( input_path )
    logger.debug( page_properties )

    # create the page markup
    template = File.read( page_properties["template"] ) # TO DO: Cache this
    markup = Plugins.inflate_page(
      output_path, page_properties, template, logger )

    # save the html page to the output directory
    File.write( output_path, markup )

  else

    # copy file to destination
    FileUtils::cp( input_path, output_path )
  end

  logger.info( "Wrote output path: #{output_path}\n" )
end


##############################################################################
# Allow plugins a chance to finalise any content based on what they collected
# in the inflation of pages.
#

Plugins.finalise( config[:input_dir], config[:output_dir], logger )

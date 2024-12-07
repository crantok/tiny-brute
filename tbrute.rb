#!/usr/bin/ruby

require 'optparse'
require 'logger'
require 'toml-rb'
require 'pathname'
require "fileutils"



# APP_NAME = "Tiny Brute"
PAGE_FILENAME_EXTENSION = "page.brute"
PROJECT_DIR_ARG_NAME = "PROJECT_DIRECTORY"
DEFAULT_PROJECT_DIR = Dir.pwd
DEFAULT_GENERATE_DIR = "work-in-progress"
DEFAULT_PUBLISH_DIR = "published"

CMD_GENERATE = "generate"
CMD_CLEAN_AND_GENERATE = "clean-and-generate"
CMD_PUBLISH = "publish"
COMMANDS = [ CMD_GENERATE, CMD_CLEAN_AND_GENERATE, CMD_PUBLISH ]

config = { project_dir: DEFAULT_PROJECT_DIR }



############################
# Initialise logging
#
logger = Logger.new(STDERR)
logger.level = Logger::DEBUG



##########################
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



###########################
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



############################
# Define default config
#

config[:input_dir] = File.join( config[:project_dir], 'input' )
config[:global_injectors_dir] = File.join( config[:project_dir], 'globals' )

config[:output_dir] =
  if command == CMD_PUBLISH
    # Including nanoseconds in the output dir name in case this script is run
    # more than once in the same second.
    File.join( config[:project_dir], DEFAULT_PUBLISH_DIR, Time.now.strftime('%Y-%m-%d--%H-%M--%S.%N') )
  else
    File.join( config[:project_dir], DEFAULT_GENERATE_DIR )
  end

logger.info("Loaded config: \n" + config.to_s)



##########################
# Create output dir if it doesn't exist

FileUtils.mkdir_p( config[:output_dir] )



##########################
# Clean output directory if appropriate.
#

if command == CMD_CLEAN_AND_GENERATE
  # TO DO: delete contents of output dir
end



##########################
# Initialise global injectors
#

# 1) define class a plugin manager

class Plugins
  @@plugins = []
  def self.register( plugin )
    @@plugins << plugin
  end
  def self.inflate_page( properties, markup )
    @@plugins.each do |p|
      markup = p.modify_page_markup( properties, markup )
    end
    markup
  end
  def self.finalise( output_dir )
    @@plugins.each do |p|
      p.finalise( output_dir )
    end
  end
end


# 2) require all ruby files in the global_injectors_dir
#    on require, each ruby file should automatically register its plugin(s)

Dir[ File.join( config[:global_injectors_dir], "*.rb" ) ].each do |file|
  require file
  logger.info("Required plugin file: " + file)
end


# 3) Might Do:  Each plugin defines which page_data keys it wants and it
#    can only receive those keys. That increases the liklihood of the plugin
#    code listing all the keys it uses in one place. (Although it might list
#    keys that the code no longer uses.)


# 4) TEST:
logger.debug( "Testing sample plugin... (This will probably break on a real website. TO DO: remove)" )
logger.debug( Plugins.inflate_page( {main_content:"Foo"}, "<html><body><div id='main-content'></div></body></html>" ))



##########################
# Generate output from the input directory
#

in_dir_path = Pathname.new config[:input_dir]

# # For each page file
# Dir.glob( File.join( config[:input_dir], "**", "*." + PAGE_FILENAME_EXTENSION ) ) do | filename |

# For each file in input directory
Dir.glob( File.join( config[:input_dir], "**" ) ) do | filename |

  if File.directory?( filename )
    # make same directory in output_dir


  elsif filename.end_with?( PAGE_FILENAME_EXTENSION )
    # Load the page properties from the input dir
    page_properties = TomlRB.load_file(filename)

    # create the page markup
    markup = Plugins.inflate_page(
      page_properties, File.read( page_properties["template"] ) )

    # save the page to the output dir
    in_file_path = Pathname.new filename
    file_rel_path = in_file_path.relative_path_from in_dir_path
    output_filename = File.join( config[:output_dir], file_rel_path )
    File.write( output_filename, markup )

  else
    # copy file to destination

  end
end

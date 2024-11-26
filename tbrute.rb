#!/usr/bin/ruby

require 'optparse'
require 'logger'
require 'toml-rb'
require 'pathname'


# APP_NAME = "Tiny Brute"
PAGE_FILENAME_EXTENSION = "page.brute"
PROJECT_DIR_ARG_NAME = "PROJECT_DIRECTORY"

config = { project_dir: Dir.pwd }


############################
# Initialise logging
#
logger = Logger.new(STDERR)
logger.level = Logger::DEBUG


##########################
# Process command line options
#
# Processing options first because OptionParser#parse! conveniently removes
# all options and their associated arguments from ARGV.

OptionParser.new do |parser|

  # The only permitted command line option is a request for usage instructions
  # triggered by -h or --help
  parser.banner =
    "Usage: #{File.basename(__FILE__)} [OPTIONS] COMMAND

COMMANDS:
    generate | gen (default command)
        generate site in the work-in-progress directory
        (default directory: #{PROJECT_DIR_ARG_NAME}/output)
    clean-and-generate | clgen
        delete contents of the work-in-progress directory and then generate
        site there
    publish | pub
        generate site in a new, (probably) uniquely-named directory

OPTIONS:"

  parser.on(
    "-d #{PROJECT_DIR_ARG_NAME}", # mandatory argument when this option is used
    "--project-dir",
    "The directory of the project to process (default = present working directory)"
  ) do | dir |
    config[:project_dir] = File.expand_path( dir )
  end

  # Can change option parsing error messages by rescuing errors...
  # rescue OptionParser::InvalidOption => e
  # rescue OptionParser::InvalidArgument => e

end.parse!
# Only positional arguments are left in ARGV.
# OptionParser has removed all options/switches and their arguments.

logger.info( "Generating static site from project at " + config[:project_dir] )



###########################
# Process command
# 

if ARGV.length > 1
  logger.error( "Too many arguments. Expected COMMAND or nothing." )
  abort()
elsif ARGV.length == 1
  command = ARGV[0]
else
  command = "gen"
end



############################
# Define default config
#

config[:input_dir] = File.join( config[:project_dir], 'input' )
config[:global_injectors_dir] = File.join( config[:project_dir], 'globals' )

config[:output_dir] =
  if [ 'gen', 'generate', 'clgen', 'clean-and-generate' ].include? command
    File.join( config[:project_dir], 'output' )

  else  # [ 'pub', 'publish' ].include? command
    # Including microseconds in the output dir name in case this script is run
    # more than once in the same second.
    File.join( project_dir, Time.now.strftime('%Y-%m-%d--%H-%M--%S.%N') )
  end



##########################
# Clean output directory if appropriate.
#

if [ 'clgen', 'clean-and-generate' ].include? command
  # TO DO: delete contents of project-dir
end


##########################
# Optional - To Do: Load any config overrides from TOML file
#
# Note: We won't override the project directory via config file but we can
# override any other paths.
#


logger.info("Loaded config: \n" + config.to_s)


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


# 3) (Optional idea) Each plugin defines which page_data keys it wants and it
#    can only receive those keys. That increases the liklihood of the plugin
#    code listing all the keys it uses in one place. (Although it might list
#    keys that the code no longer uses.)

# TEST:
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

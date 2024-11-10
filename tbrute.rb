#!/usr/bin/ruby

require 'optparse'
require 'logger'

# APP_NAME = "Tiny Brute"


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

options = {}
OptionParser.new do |parser|

  # The only permitted command line option is a request for usage instructions
  # triggered by -h or --help
  parser.banner = "Usage: tbrute.rb [PROJECT_DIRECTORY]
arguments:
    PROJECT_DIRECTORY  root directory of the project
                       default = curent working directory (usually the
                       directory that this script was called from)
                       Project config file (if any) should be placed here."

  # The second argument passed to OptionParser#on is parsed to determine
  # whether there is a required or [optional] argument.
  # Not the most self-documenting interface.
  # Example:
  # parser.on( "-t", "--test [OPTIONAL_ARG]", "testing the options parser") do |t|
  #   options[:test] = t
  # end

  # Can change option parsing error messages by rescuing errors...
  # rescue OptionParser::InvalidOption => e
  # rescue OptionParser::InvalidArgument => e
end.parse!


###########################
# Process postional command line arguments: project_dir
#
# Allow override of project directory via command line argument.

if ( ARGV.length > 1 )
  logger.error( "Too many arguments. Expected PROJECT_DIRECTORY or nothing." )
  abort()
elsif ( ARGV.length == 1 )
  project_dir = File.expand_path( ARGV[0] )
else
  project_dir = Dir.pwd  # default: current working directory 
end

logger.info("Generating static site from project at " + project_dir)


############################
# Define default config
#

config = {
  project_dir: project_dir,
  input_dir: File.join( project_dir, 'input' ),
  global_injectors_dir: File.join( project_dir, 'globals' ),

  # Including microseconds in the output dir name in case this script is run
  # more than once in the same second.
  output_dir: File.join( project_dir, Time.now.strftime('%Y-%m-%d--%H-%M--%S.%N') )
}



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
  def self.inflate_page( page_data, page_markup )
    @@plugins.each do |p|
      page_markup = p.modify_markup( page_data, page_markup )
    end
    page_markup
  end
end


# 2) require all ruby files in the global_injectors_dir
#    on require, each ruby file should automatically register its plugin(s)

Dir[config[:global_injectors_dir]+"/*.rb"].each do |file|
  require file
  logger.info("Required plugin: " + file)
end

 
# 4) (Optional idea) Each plugin defines which page_data keys it wants and it
#    can only receive those keys. That increases the liklihood of the plugin
#    code listing all the keys it uses in one place. (Although it might list
#    keys that the code no longer uses.)

# TEST:
logger.debug( "Testing sample plugin... (This will probably break if the sample plugin is changed or removed.)" )
logger.debug( Plugins.inflate_page( {main_content:"Foo"}, "<html><body><div id='main-content'></div></body></html>" ))


##########################
# Generate output from the input directory
#
# process the input directory:
#     for each static page
#         for each plugin
#             call inject_markup( page_data, page_markup ) => page_markup
#         end
#     end
#     save final page_markup to output directory


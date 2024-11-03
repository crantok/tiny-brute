#!/usr/bin/ruby

require 'optparse'
require 'logger'

# APP_NAME = "Tiny Brute"


############################
# Initialise logging
#
logger = Logger.new(STDERR)
logger.level = Logger::INFO


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
# Load config
#

# Define default config
config = {
  project_dir: project_dir,
  input_dir: File.join( project_dir, 'input' ),
  global_injectors_dir: File.join( project_dir, 'globals' ),

  # Including microseconds in the output dir name in case this script is run
  # more than once in the same second.
  output_dir: File.join( project_dir, Time.now.strftime('%Y-%m-%d--%H-%M--%S.%N') )
}

# TO DO: load any config overrides from TOML file
# TO DO: load any config overrides from TOML file
# TO DO: load any config overrides from TOML file
# TO DO: load any config overrides from TOML file

logger.info("Loaded config: \n" + config.to_s)


##########################
# Initialise global injectors
#



##########################
# Generate output from the input directory
#



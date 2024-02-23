#!/usr/bin/ruby

require 'optparse'
require 'logger'

# APP_NAME = "Tiny Brute"

# Default project directory is the current working directory
project_dir = Dir.pwd


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
    PROJECT_DIRECTORY  directory containing the configuration file for the
                       relevant project
                       default = curent working directory (usually the
                       directory that this script was called from)"

  # The second argument passed to OptionParser#on is parsed to determine
  # whether there is a required or [optional] argument.
  # Not the most self-documenting interface.
  # parser.on( "-t", "--test [OPTIONAL_ARG]", "testing the options parser") do |t|
  #   options[:test] = t
  # end

  # Can change option parsing error messages by rescuing errors...
  # rescue OptionParser::InvalidOption => e
  # rescue OptionParser::InvalidArgument => e
end.parse!


###########################
# Process postional command line arguments
#
# Allow override of project directory via command line argument.

if ( ARGV.length > 1 )
  logger.error( "Too many arguments. Expected PROJECT_DIRECTORY or nothing." )
  abort()
elsif ( ARGV.length == 1 )
  # Does the argument look like an absolute path?
  if "/\\".include?( ARGV[0][0] )
    # Making a copy because the strings in ARGV are frozen.
    project_dir = ARGV[0].dup
  else
    project_dir += '/' + ARGV[0]
  end
end

logger.info("Generating static site from project at " + project_dir)


############################
# Load config
#

# Remove trailing slashes before concatenating with relative paths of subdirectories
project_dir.chomp!( '/' )

# Default config
config = {
  project_dir: project_dir,
  input_dir: project_dir + '/input',
  global_injectors_dir: project_dir + '/globals',

  # Using microseconds rather than seconds in the output dir name,
  # just in case this script is run more than once in the same second.
  output_dir: project_dir + '/' + Time.now.strftime('%Y-%m-%d--%H-%M--%N')
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



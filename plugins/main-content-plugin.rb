require 'nokogiri'

class MainContent

  #############################################################################
  # Method: modify_page_markup
  #
  # Called once for each html page that is to be generated.
  #
  # Make any required modifications to the markup for the relevant html page.
  #
  # Plugins are not guaranteed to be executed in any given order.
  # If there is something you need to do after all plugins have been called
  # then store the relevant information here and call your after-everything
  # -else code in the finalise method.
  # See the HomePageLinks plugin for an example of how to do this.
  #
  # Arguments:
  #
  #   command:     The command that Tiny Brute is executing.
  #
  #   relative_path: The relative path of the file that the final markup will
  #                  be saved to. Useful when caching information for the
  #                  finalise method below.
  #
  #   page_data:   A hash containing data for the relevant html page.
  #
  #   page_markup: The markup so far for the relevant html page.
  #                If this is the first plugin to be called then the markup
  #                is the raw content of the relevant template.
  #                If this is the final plugin to be called then the markup
  #                returned by this method will be saved to the output file.
  #
  #   logger:      A standard Ruby logger.
  #
  def self.modify_page_markup( command, relative_path, page_data, page_markup, logger )

    # Inject the main content contained in page_data into the markup.
    html = Nokogiri::HTML( page_markup )
    html.at_css( '#main-content' ).add_child( page_data["main-content"] )
    html.to_s

  end

  
  #############################################################################
  # Method: finalise
  #
  # Called once after all html pages have been generated and saved.
  #
  # Use information collected in the modify_page_markup method to make any
  # further modifications to the contents of the output directory.
  #
  # Arguments:
  #
  #   command:    The command that Tiny Brute is executing.
  #
  #   output_dir: The path to the directory containing the output files.
  #
  #   logger:     A standard Ruby logger.
  #
  def self.finalise( command, output_dir, logger )
    # Empty - Nothing required of this plugin.
  end
end


Plugins.register( MainContent )


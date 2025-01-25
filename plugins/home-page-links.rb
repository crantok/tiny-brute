require 'nokogiri'

class HomePageLinks

  ############################################################################
  # Method: modify_page_markup
  #
  # Called once for each piece of content.
  #
  # Make any required modifications to the markup for the relevant piece of
  # content.
  #
  # Plugins are not guaranteed to be executed in any given order, so if
  # there is something you need to do after all plugins have been called
  # then store the relevant information here and call your after-everything-
  # else code in the finalise method. (See the Blog_Post plugin.)
  #
  # Arguments:
  #
  #   output_path: This is the name of the file that the final markup will be
  #                saved to. Probably only important if saving information for
  #                the finalise method below.
  #
  #   page_data:   A hash containing data for the relevant piece of content.
  #
  #   page_markup: The markup so far for the relevant piece of content.
  #                If this is the first plugin to be called then the markup
  #                is the raw content of the relevant template.
  #                If this is the final plugin to be called then the markup
  #                returned by this method will be saved to output_path.
  #
  #   logger:      A standard Ruby logger.
  #
  def self.modify_page_markup( output_path, page_data, page_markup, logger )

    # Not making any changes to markup.
    # Just collecting arrays of home-pages and blog-posts for finalise().
    
    @@home_pages ||= []
    if page_data["type"] == "home-page"
      @@home_pages << output_path
    end

    @@blog_posts ||= []
    if page_data["type"] == "blog-post"
      @@blog_posts << { path: output_path, title: page_data["title"] }
    end

    # Return page_markup unaltered.
    page_markup
  end

  
  ############################################################################
  # Method: finalise
  #
  # Called once after all content has been saved.
  #
  # Use information collected in the modify_page_markup method to make any
  # further modifications to content files.
  #
  # logger:   A standard Ruby logger.
  #
  def self.finalise( input_dir, output_dir, logger )

    blog_links = @@blog_posts.reduce( "" ) do | html, post |
      rel_path =
        Pathname.new( post[:path] ).relative_path_from( Pathname.new( output_dir ) )
      html += "<li><a href='/#{rel_path}'>#{post[:title]}</a></li>"
    end

    logger.debug( "HomePageLinks.finalise blog_links: #{blog_links}" )

    @@home_pages.each do | filename |
      html = Nokogiri::HTML( File.read( filename ) )
      html.at_css( '#blog-links' ).add_child( blog_links )
      File.write( filename, html.to_s )
    end

  end
end


Plugins.register( HomePageLinks )


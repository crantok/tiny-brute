require 'nokogiri'

class Main_Content

  def self.modify_page_markup( page_data, page_markup, logger )

    html = Nokogiri::HTML( page_markup )
    html.at_css( '#main-content' ).add_child( page_data["main-content"] )
    html.to_s

  end

end

Plugins.register( Main_Content )


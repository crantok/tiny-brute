require 'nokogiri'

class Main_Content

  def self.modify_page_markup( page_data, page_markup )
    html = Nokogiri::HTML( page_markup )
    html.css( '#main-content' ).first.content = page_data[:main_content]
    html.to_s
  end

end

Plugins.register( Main_Content )


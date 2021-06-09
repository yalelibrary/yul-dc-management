class AddTextWsDynamicSolrField < ActiveRecord::Migration[6.0]
  def change
    begin
      SolrService.create_new_field_type("*_wstsim", "text_ws", true, true, true)
    rescue Faraday::BadRequestError
      # the field may have already been created
    end    
  end
end

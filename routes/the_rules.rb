class CiberSykkel < Sinatra::Application
  unless rules_token = ENV['VELO_RULES_TOKEN']
    raise "You must specify the VELO_RULES_TOKEN env variable"
  end
  the_rules = JSON.parse(File.read('./assets/the-rules.json'))

  post '/the-rules' do
    unless params[:token] == ENV['VELO_RULES_TOKEN']
      logging.err "Wrong token used, #{params[:token]}"
      return 'You need to specify correct token'
    end
    
    user = params.fetch('user_name')
    rule_id = params.fetch('text').strip
    
    logging.info "Posting rule ##{rule_id}"

    the_rules[rule_id]
  end
end

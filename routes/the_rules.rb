require 'net/http'
require 'net/https'

class CiberSykkel < Sinatra::Application
  unless rules_token = ENV['VELO_RULES_TOKEN']
    raise "You must specify the VELO_RULES_TOKEN env variable"
  end
  the_rules = JSON.parse(File.read('./assets/the-rules.json'))

  post '/the-rules' do
    unless params[:token] == ENV['VELO_RULES_TOKEN']
      logger.err "Wrong token used, #{params[:token]}"
      return 'You need to specify correct token'
    end
    
    user = params.fetch('user_name')
    rule_id = params.fetch('text').strip
    
    logger.info "Posting rule ##{rule_id}"

    rule = the_rules[rule_id]

    https = Net::HTTP.new(SLACK_URL.host, SLACK_URL.port)
    https.use_ssl = true
    request = Net::HTTP::Post.new(SLACK_URL.path)
    request.body = {
      "channel": "#squash",
      "username": "SquashBot",
      "attachments": [
                      {
                        "fallback": rule["rule"],
                        "color": "good",
                        "title": "Rule ##{rule_id}",
                        "text": "#{rule["rule"]}\n#{rule["description"]}"
                      }
                     ]}.to_json
    logger.info https.request(request)
  end
end

require 'net/http'
require 'net/https'

class CiberSykkel < Sinatra::Application

  unless rules_token = ENV['VELO_RULES_TOKEN']
    raise "You must specify the VELO_RULES_TOKEN env variable"
  end

  unless VELO_RULES_WEBHOOK = URI.parse(ENV['VELO_RULES_WEBHOOK'])
    raise "You must specify the VELO_RULES_WEBHOOK env variable"
  end

  the_rules = JSON.parse(File.read('./assets/the-rules.json'))

  post '/the-rules' do
    unless params[:token] == ENV['VELO_RULES_TOKEN']
      logger.err "Wrong token used, #{params[:token]}"
      return 'You need to specify correct token'
    end
    
    user = params.fetch('user_name')
    rule_id = params.fetch('text').strip

    unless rule_id.to_i.between?(1,95)
      logger.err "#{rule_id} is not a rule"
      return "There is no such rule as ##{rule_id}"
    end
    
    logger.info "Posting rule ##{rule_id}"

    rule = the_rules[rule_id]

    https = Net::HTTP.new(VELO_RULES_WEBHOOK.host, VELO_RULES_WEBHOOK.port)
    https.use_ssl = true
    request = Net::HTTP::Post.new(VELO_RULES_WEBHOOK.path)
    request.body = {
      "attachments": [
                      {
                        "fallback": rule["rule"],
                        "color": "good",
                        "title": "Rule ##{rule_id} // #{rule["rule"]}",
                        "text": "\n#{rule["description"]}\n\nRequested by #{user}"
                      }
                     ]}.to_json
    logger.info https.request(request)
  end
end

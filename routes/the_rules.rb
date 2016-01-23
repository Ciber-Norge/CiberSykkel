require 'net/http'
require 'net/https'

class CiberSykkel < Sinatra::Application

  unless VELO_RULES_TOKEN = ENV['VELO_RULES_TOKEN']
    raise "You must specify the VELO_RULES_TOKEN env variable"
  end

  unless VELO_RULES_OUTGOING_TOKEN = ENV['VELO_RULES_OUTGOING_TOKEN']
    raise "You must specify the VELO_RULES_OUTGOING_TOKEN env variable"
  end

  unless VELO_RULES_WEBHOOK = URI.parse(ENV['VELO_RULES_WEBHOOK'])
    raise "You must specify the VELO_RULES_WEBHOOK env variable"
  end

  THE_RULES = JSON.parse(File.read('./assets/the-rules.json'))

  post '/the-rules' do
    unless params[:token] == VELO_RULES_TOKEN
      logger.error "Wrong token used, #{params[:token]}"
      return 'You need to specify correct token'
    end
    
    user = params.fetch('user_name')
    rule_id = params.fetch('text').strip

    unless rule_id.to_i.between?(1,95)
      logger.error "#{rule_id} is not a rule"
      return "There is no such rule as ##{rule_id}"
    end
    
    post_rule(rule_id, user)
  end

  post '/the-rules-webhook' do
    unless params[:token] == VELO_RULES_OUTGOING_TOKEN
      logger.error "Wrong token used, #{params[:token]}"
      return 'You need to specify correct token'
    end

    user = params.fetch('user_name')
    text = params.fetch('text').strip

    if text =~ /\s#\d\d?\s/
      rule_id = text.match(/#\d\d?/)[0].delete('#')
      post_rule(rule_id, user)
    end

    { "text": ""}.to_json
  end

  def post_rule(rule_id, user)
    logger.info "Posting rule ##{rule_id}"
    rule = THE_RULES[rule_id]

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

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

  before do
    unless params[:token] == VELO_RULES_TOKEN
      logger.error "Wrong token used, #{params[:token]}"
      return 'You need to specify correct token'
    end
  end

  post '/the-rules' do
    user = params.fetch('user_name')
    rule_id = params.fetch('text').strip

    unless rule_id.to_i.between?(1,95)
      logger.error "#{rule_id} is not a valid rule number"
      return "There is no such rule as rule ##{rule_id}"
    end
    
    rule_as_json(rule_id, user)
  end

  post '/the-rules-webhook' do
    user = params.fetch('user_name')
    text = params.fetch('text').strip

    if text =~ /(^|\s)#\d\d?($|\s)/
      rule_id = text.match(/#\d\d?/)[0].delete('#')
      post_rule(rule_id, user)
    end

    { "text": ""}.to_json
  end

  private
  def post_rule(rule_id, user)
    logger.info "Posting rule ##{rule_id}"

    https = Net::HTTP.new(VELO_RULES_WEBHOOK.host, VELO_RULES_WEBHOOK.port)
    https.use_ssl = true
    request = Net::HTTP::Post.new(VELO_RULES_WEBHOOK.path)
    request.body = rule_as_json(rule_id, user)
    logger.info https.request(request)
  end

  def rule_as_json(rule_id, user)
    logger.info "Creating JSON for rule ##{rule_id}"
    rule = get_rule(rule_id)
    return {
      "attachments": [
                      {
                        "fallback": rule["rule"],
                        "color": "good",
                        "title": "Rule ##{rule_id} // #{rule["rule"]}",
                        "title_link": "http://www.velominati.com/the-rules/##{rule_id}",
                        "text": "\n#{rule["description"]}\n\nRequested by #{user}"
                      }
                     ]}.to_json
  end

  def get_rule(id)
    THE_RULES[id]
  end
end

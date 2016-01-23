# -*- coding: utf-8 -*-
class CiberSykkel < Sinatra::Application

  unless VELO_RULES_TOKEN = ENV['VELO_RULES_TOKEN']
    raise "You must specify the VELO_RULES_TOKEN env variable"
  end

  unless VELO_RULES_WEBHOOK = URI.parse(ENV['VELO_RULES_WEBHOOK'])
    raise "You must specify the VELO_RULES_WEBHOOK env variable"
  end

  THE_RULES = JSON.parse(File.read('./assets/the-rules.json'))

  before '/the-rules*' do
    content_type 'application/json'

    unless VELO_RULES_TOKEN == params[:token]
      logger.error "Wrong token used, #{params[:token]}"
      halt 401, {'Content-Type' => 'text/plain'}, 'You need to specify correct token'
    end
  end

  post '/the-rules' do
    user = params.fetch('user_name')
    rule_id = params.fetch('text').strip
    channel = params.fetch('channel_name')

    unless rule_id.to_i.between?(1,95)
      logger.error "#{rule_id} is not a valid rule number"
      return "There is no such rule as rule ##{rule_id}"
    end

    rule_as_json(rule_id, user, 'in_channel')
  end

  post '/the-rules-webhook' do
    user = params.fetch('user_name')
    text = params.fetch('text').strip

    if text =~ /(^|\s)#\d\d?($|\s)/
      rule_id = text.match(/#\d\d?/)[0].delete('#')
      return rule_as_json(rule_id, user)
    end

    200
  end

  private
  def rule_as_json(rule_id, user, response_type='ephemeral')
    logger.info "Creating JSON for rule ##{rule_id}"
    rule = get_rule(rule_id)
    message = {
      "attachments": [
                      {
                        "fallback": rule["rule"],
                        "color": "good",
                        "title": "Rule ##{rule_id} // #{rule["rule"]}",
                        "title_link": "http://www.velominati.com/the-rules/##{rule_id}",
                        "text": "\n#{rule["description"]}\n\nRequested by #{user}"
                      }
                     ]}
    message['response_type'] ||= response_type
    message.to_json
  end

  def get_rule(id)
    THE_RULES[id]
  end
end

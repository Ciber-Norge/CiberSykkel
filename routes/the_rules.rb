# -*- coding: utf-8 -*-
require 'net/http'
require 'net/https'

# Note to self
# Use post_rule to post to slack-chat
# return a value if only the user who asked wanted to see it
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

  before 'the-rules*' do
    unless [VELO_RULES_TOKEN, VELO_RULES_OUTGOING_TOKEN].include?(params[:token])
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

    post_rule(rule_id, user, channel)
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
  def post_rule(rule_id, user, channel)
    logger.info "Posting rule ##{rule_id}"

    https = Net::HTTP.new(VELO_RULES_WEBHOOK.host, VELO_RULES_WEBHOOK.port)
    https.use_ssl = true
    request = Net::HTTP::Post.new(VELO_RULES_WEBHOOK.path)
    request.body = rule_as_json(rule_id, user, channel)
    logger.debug https.request(request)
  end

  def rule_as_json(rule_id, user, channel=nil)
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
    #message['channel'] ||= channel
    message.to_json
  end

  def get_rule(id)
    THE_RULES[id]
  end
end

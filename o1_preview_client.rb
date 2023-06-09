# frozen_string_literal: true

require 'openai'
require 'thor'
require 'json'
require 'logger'

# Run like so:
# bundle exec ruby o1_preview_client.rb execute prompts/o1-preview-000001
class O1PreviewCLI < Thor
  desc 'execute PROMPT_FILE', 'Execute the O1 Preview with a prompt from a file'
  def execute(prompt_file)
    begin
      prompt = File.read(prompt_file)
    rescue Errno::ENOENT
      puts "Error: File '#{prompt_file}' not found."
      exit(1)
    end

    client = OpenAI::Client.new(
      access_token:    ENV.fetch('OPENAI_ACCESS_TOKEN'),
      log_errors:      true,
      request_timeout: 60 * 60 * 12 # Twelve hours
    ) do |f|
      f.response :logger, Logger.new($stdout), bodies: true
    end

    messages = [
      { role: 'user', content: prompt }
    ]

    timestamp = Time.now.strftime('%Y%m%d%H%M%S')

    response = client.chat(
      parameters: {
        model: 'o1-preview',
        messages: messages
      }
    )

    if response.key?('error')
      puts "Error: #{response['error']}"
      exit(1)
    end

    File.write('log/conversations', "#{timestamp}\n", mode: 'a+')
    File.write('log/conversations', "#{messages.to_json}\n", mode: 'a+')

    meta = response.except('choices')
    puts "Metadata: #{meta}"

    answer = response.dig('choices', 0)
    answer_meta = answer.except('message')
    answer = answer.fetch('message')
    answer_meta['message'] = answer.except('content')
    puts "Answer metadata: #{answer_meta}"

    File.write("log/openai_response_#{timestamp}", answer.fetch('content'))
    puts "Response saved to log/openai_response_#{timestamp}"
  end
end

O1PreviewCLI.start(ARGV)

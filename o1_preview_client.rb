# frozen_string_literal: true

require 'openai'
require 'thor'
require 'json'
require 'logger'

# Run like so:
# bundle exec ruby o1_preview_client.rb execute prompts/o1-preview-000001
class O1PreviewCLI < Thor
  desc 'execute PROMPT_FILE', 'Execute the O1 Preview with a prompt from a file'
  def execute(prompt_file_path)
    begin
      prompt = File.read(prompt_file_path)
    rescue Errno::ENOENT
      puts "Error: File '#{prompt_file_path}' not found."
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

    prompt_file_name = File.basename(prompt_file_path)

    File.write("log/#{prompt_file_name}_conversation", "#{timestamp}\n", mode: 'a+')
    File.write("log/#{prompt_file_name}_conversation", "#{prompt}\n", mode: 'a+')

    meta = response.except('choices')
    puts "Metadata: #{meta}"

    answer = response.dig('choices', 0)
    answer_meta = answer.except('message')
    answer = answer.fetch('message')
    answer_meta['message'] = answer.except('content')
    puts "Answer metadata: #{answer_meta}"

    timestamp = Time.now.strftime('%Y%m%d%H%M%S')

    File.write("log/#{prompt_file_name}_openai_response_#{timestamp}", answer.fetch('content'))
    File.write("log/#{prompt_file_name}_conversation", "#{timestamp}\n", mode: 'a+')
    File.write("log/#{prompt_file_name}_conversation", "#{answer.fetch('content')}\n", mode: 'a+')

    puts <<~INFO.strip.gsub(/\s+/, ' ')
      Response saved to log/#{prompt_file_name}_openai_response_#{timestamp}
      and appended to log/#{prompt_file_name}_conversation
    INFO
  end
end

O1PreviewCLI.start(ARGV)

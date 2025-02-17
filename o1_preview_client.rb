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

    developer_message = <<~CONTENT
      Formatting re-enabled.

      As a general note when replying to me with code, for every file that
      needs to change, just write out the entire file for me, or at least large
      relevant chunks of it, so I can copy-paste it to my local file system.

      Never ever send me a diff or a patch file, even if I provide you with
      one. I will not be able to apply it. Instead, just send me the entire
      file(s) that need to change.

      However, in order to facilitate rapid code reviews, let's not change
      unrelated code for e.g. style reasons.
    CONTENT

    messages = [
      # Markdown formatting: Starting with o1-2024-12-17, o1 models in the API
      # will avoid generating responses with markdown formatting. To signal to
      # the model when you do want markdown formatting in the response, include
      # the string Formatting re-enabled on the first line of your developer
      # message.
      { role: 'developer', content: developer_message },
      { role: 'user', content: prompt }
    ]

    timestamp = Time.now.strftime('%Y%m%d%H%M%S')

    response = client.chat(
      parameters: {
        model: 'o1',
        # model: 'o3-mini',
        messages: messages,
        reasoning_effort: 'high'
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

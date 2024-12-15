# frozen_string_literal: true

require 'openai'
require 'thor'
require 'json'
require 'logger'

# Run like so:
# bundle exec ruby dall_e_3_client.rb execute prompts/dall-e-3-000000 --size=1024x1792 --quality=hd
class DallE3Client < Thor
  desc 'execute PROMPT_FILE', 'Generate an image with DALL·E 3 from a prompt in a file'
  option :size, default: '1024x1024', desc: 'Size of the image (1024x1024, 1024x1792, or 1792x1024)'
  option :quality, default: 'standard', desc: 'Quality of the image (standard or hd)'
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

    size = options[:size]
    quality = options[:quality]

    response = client.images.generate(
      parameters: {
        prompt: prompt,
        model: 'dall-e-3',
        size: size,
        quality: quality
      }
    )

    if response.key?('error')
      puts "Error: #{response['error']}"
      exit(1)
    end

    image_url = response.dig('data', 0, 'url')
    if image_url.nil?
      puts "Error: No image URL found in response."
      exit(1)
    end

    timestamp = Time.now.strftime('%Y%m%d%H%M%S')
    prompt_file_name = File.basename(prompt_file_path)

    # Create log directory if it doesn't exist
    Dir.mkdir('log') unless Dir.exist?('log')

    # Save the image URL
    File.write("log/#{prompt_file_name}_image_url_#{timestamp}.txt", image_url)

    # Append to conversation log
    File.open("log/#{prompt_file_name}_conversation", 'a+') do |file|
      file.puts("#{timestamp}")
      file.puts("Prompt:")
      file.puts(prompt)
      file.puts("Image URL:")
      file.puts(image_url)
      file.puts("\n")
    end

    puts <<~INFO.strip
      Image URL saved to log/#{prompt_file_name}_image_url_#{timestamp}.txt
      and appended to log/#{prompt_file_name}_conversation
      Image URL: #{image_url}
    INFO
  end
end

DallE3Client.start(ARGV)

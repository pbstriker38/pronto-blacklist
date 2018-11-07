require 'pronto/blacklist/version'
require 'pronto'

module Pronto
  class Blacklist < Runner
    def run
      return [] unless @patches

      @patches.select { |patch| patch.additions > 0 }
        .map { |patch| inspect(patch) }
        .flatten
        .compact
    end

    private

    def inspect(patch)
      patch.added_lines.map do |line|
        blacklist_words.map do |blacklist_word|
          new_message(line, blacklist_word) if line.content.include?(blacklist_word)
        end
      end
    end

    def new_message(line, word)
      path = line.patch.delta.new_file[:path]

      Message.new(path, line, :error, "Do not use #{word}", nil, self.class)
    end

    def blacklist_words
      @blacklist_words ||= begin
        if File.exist?(config_path)
          YAML.load_file(config_path)['blacklist'] || []
        else
          []
        end
      end
    end

    def config_path
      File.expand_path(File.join('./', '.pronto-blacklist.yml'))
    end
  end
end

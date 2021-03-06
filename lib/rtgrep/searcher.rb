class Rtgrep::Searcher
  attr_accessor :lines
  def initialize
    @lines = []
    update
  end

  def update
    if lines.empty?
      @longest_line_length = 0
      @longest_filename_length = 0
    else
      @longest_line_length = (@lines.max_by { |line| line[0].length }).first.length
      @longest_filename_length = (@lines.max_by { |line| line[3].length }).first.length
    end

    @last_matches = []
    @last_needle = nil
  end

  def search(needle = nil)
    return @lines if @lines.empty? || !needle || needle.gsub(' ', '') == ''

    needle_parts = needle.split("").map do |c|
      c = Regexp.escape(c)
      "#{c}([^#{c}]*?)"
    end.join
    needle_regex = Regexp.new(needle_parts, "i")
    #needle_regex = Regexp.new(needle.split("").map { |c| "#{c}?[^#{c}]*?" }.join, "i")

    matching_lines = if @last_needle && needle.start_with?(@last_needle)
      #$tlg.error "Using last matches cache, last_needle: #{@last_needle.inspect}, needle: #{needle.inspect}, search space reduced from #{@haystack.length} to #{@last_matches.length}"
      @last_matches
    else
      #$tlg.error "SKIPPING last matches cache, last_needle: #{@last_needle.inspect}, needle: #{needle.inspect}, search space widened from #{@last_matches.length} to #{@haystack.length}"
      @lines.reject { |line| line[1] == Rtgrep::FILE_MARKER } 
    end

    @last_needle = needle.dup
    @last_matches = matching_lines = matching_lines.select { |line| line[0] =~ needle_regex }

    matching_lines.sort_by do |line|
      shortest_match_offset = nil
      shortest_match_inbetweens = nil
      line[0].to_enum(:scan, needle_regex).map do
        match_data = Regexp.last_match

        offset = match_data.offset(0)
        if !shortest_match_offset || ((offset[1] - offset[0]) < (shortest_match_offset[1] - shortest_match_offset[0]))
          shortest_match_offset = offset
          shortest_match_inbetweens = match_data.captures.inject(0) { |sum, c| sum + c.length }
        end
      end

      match_line_length_mod = 1 - ((shortest_match_offset[1] - shortest_match_offset[0]) / line[0].length.to_f)
      match_inbetweens_length_mod = shortest_match_inbetweens / line[0].length.to_f
      match_position_mod = (shortest_match_offset[0] + 1) / line[0].length.to_f
      file_length_mod = line[3].length / @longest_filename_length.to_f
      line_length_mod = line[0].length / @longest_line_length.to_f

      score = (match_line_length_mod * 10.0) + (match_inbetweens_length_mod * 10.0) + (match_position_mod * 10.0) + (file_length_mod * 2.0) + (line_length_mod * 2.0)

#      $tlg.debug "\n\n\n\nNeedle: #{needle.inspect}\nLine:\n#{line.inspect}\nShortest match offset: #{shortest_match_offset.inspect}\nShortest match inbetweens: #{shortest_match_inbetweens.inspect}\nmatch_length_mod: #{match_length_mod}, match_inbetweens_length_mod: #{match_inbetweens_length_mod}, file_length_mod: #{file_length_mod}, match_line_length_mod: #{match_line_length_mod}, match_position_mod: #{match_position_mod}, line_length_mod: #{line_length_mod}\nResult: #{result}"

       score
    end
  end
end


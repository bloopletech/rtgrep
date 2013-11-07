class Rtgrep::TagsFile
  attr_reader :tags, :name
  def initialize(lines, dir = nil)
    @tags = []

    regex = /^#{Regexp.quote(dir + File::SEPARATOR)}/ if dir

    lines.each do |l|
      l.chomp!

      next if l == ""

      if @name.nil? && l =~ /^\!_TAG_COLLECTION_NAME\t(.+)$/
        @name = $1
        next
      end

      next if l =~ /^!_TAG_/

      begin
        l =~ /^(.+?)\t(.+?)\t(.+?)(;"(.+)|)$/
        l = [$1, $5, $3, $2, ""] #0 = tag, 1 = type, 2 = line num, 3 = path, 4 = line context

        extra = l[1]
        if extra
          extra =~ /^\t(.)/
          type = $1
          l[1] = type
        end

        l[0].replace l[0][0..100]
        l[3].slice!(regex) if dir

        @tags << l
      rescue
      end
    end
  end
end

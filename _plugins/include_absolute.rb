module Jekyll
  class IncludeTagError < StandardError
    attr_accessor :path

    def initialize(msg, path)
      super(msg)
      @path = path
    end
  end

  class IncludeAbsoluteTag < Liquid::Tag
    VARIABLE_SYNTAX = %r!
        (?<variable>[^{]*(\{\{\s*[\w\-\.]+\s*(\|.*)?\}\}[^\s{}]*)+)
        (?<params>.*)
      !x

    def initialize(tag_name, markup, tokens)
      super
      @file = markup.split(/\s+/).first
      @class = markup.split(':')[-1]
    end

    def render_variable(context)
      if @file.match(VARIABLE_SYNTAX)
        partial = context.registers[:site]
                         .liquid_renderer
                         .file('(variable)')
                         .parse(@file)
        partial.render!(context)
      end
    end

    def render(context)
      file = render_variable(context) || @file
      source = File.expand_path(context.registers[:site].config['source']).freeze
      path = File.join(source, file)

      begin
        partial = Liquid::Template.parse(read_file(path, context))

        context.stack do
          context['include'] = parse_params(context) if @params
          "<div class='#{@class}'>#{partial.render!(context)}</div>"
        end

      rescue => e
        raise IncludeTagError.new e.message, path
      end
    end

    def read_file(file, context)
      File.read(file, file_read_opts(context))
    end

    def file_read_opts(context)
      context.registers[:site].file_read_opts
    end
  end
end

Liquid::Template.register_tag('include_absolute', Jekyll::IncludeAbsoluteTag)
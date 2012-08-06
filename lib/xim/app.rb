module Xim
  class App
    def initialize(opts = {})
      @opts = opts

      editor = Xim::Editor.new(:file => @opts[:file])
    end
  end
end

require 'test_helper'
require 'xim'

describe Xim::Editor do
  describe '.new' do
    it 'should work with no options' do
      Xim::Editor.any_instance.expects(:init_screens).returns(nil)
      Xim::Editor.any_instance.expects(:main_loop).returns(nil)
      Xim::Editor.new()
    end
  end
end

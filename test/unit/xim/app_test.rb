require 'test_helper'
require 'xim'

describe Xim::App do
  describe '.new' do
    it 'should work with no options' do
      Xim::Editor.expects(:new)
      Xim::App.new()
    end
  end
end

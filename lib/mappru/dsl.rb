class Mappru::DSL
  class << self
    def convert(exported, options = {})
      Mappru::DSL::Converter.convert(exported, options)
    end

    def parse(dsl, path, options = {})
      Mappru::DSL::Context.eval(dsl, path, options).result
    end
  end # of class methods
end

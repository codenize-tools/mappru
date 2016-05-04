module Mappru::Ext
  module HashExt
    def sort_pair
      new_hash = {}

      self.sort_by(&:to_s).each do |k, v|
        new_hash[k] = v
      end

      new_hash
    end

    def sort_pair!
      self.replace(self.sort_pair)
    end

    def without_nil
      new_hash = {}

      self.each do |k, v|
        new_hash[k] = v if v
      end

      new_hash
    end
  end
end

Hash.include(Mappru::Ext::HashExt)

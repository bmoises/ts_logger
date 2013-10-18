module Delegation
  def delegate(klass, *methods)
    define_method("__delegate_instance__") { @__delegate_instance__ ||= klass.new }
    methods.each do |method|
      define_method(method.to_s) { |*args| __delegate_instance__.send method.to_sym, *args }
    end
  end

  def self.append_features(mod)
    mod.extend(self)
  end
end

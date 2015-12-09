require 'ostruct'
require 'yaml'
require 'erb'
class HashStruct
  def initialize(hash)
    hash.each do |k,v|
      v= HashStruct.new(v) if v.is_a? Hash
      if v.is_a? Array
        v.map! {|i| i.is_a?(Hash) ? HashStruct.new(i)  : i}
      end

      self.instance_variable_set("@#{k}", v)
    end
  end

  def [](key)
    self.public_send key
	end

  def to_hash
    h={}
    self.instance_variables.each do |var|
      value=self.instance_variable_get(var)
      h[var[1..-1].to_sym]= value.is_a?(self.class)? value.to_hash : value
    end
    h
  end
  
  def method_missing(method,*args)
    if args.length>1
      super
    else
      self.class.send(:define_method, method, proc{|*args| self.instance_variable_get("@#{method}") || args.first })
      self.instance_variable_get("@#{method}") || args.first
    end
  end
end

CONFIG = HashStruct.new(YAML::load(ERB.new(File.read(File.join(File.dirname(__FILE__),"credentials.yml.erb"))).result))
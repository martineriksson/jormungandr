require 'rubygems'
require 'redis'

# A very small ORM named after a very large snake.
#
module Jormungandr

  class << self

    # Setup the Redis connection.
    #
    def redis(id = nil)
      @@redis = Redis.new(:db => id) if id
      @@redis = Redis.new(:db => 3) unless defined? @@redis
      @@redis
    end

    # Scan the database for existing models and initiate them.
    #
    def load_models!
      redis.keys("#{self}.*").map{ |key| key.split('.')[1] }.uniq.each { |c| create_model c }
    end

    # Create a Model subclass and initialize its instances.
    #
    def create_model(name)
      return nil if (Kernel.const_get name.to_s.capitalize rescue nil)
      klass = Object.instance_eval { const_set name.to_sym, Class.new(Jormungandr::Model) }
      redis.keys("#{self}.#{klass}.*").each { |key| klass.new(key.split('.')[2]) }
    end

    # Delete all Model entries from the database.
    #
    def kill_em_all!
      redis.keys("#{self}.*").each { |key| redis.del key }
      models.each { |model|  model.instance_eval {@all = []}}
    end

    # Return all Model subclasses.
    #
    def models
      ObjectSpace.each_object(Class).select { |c| c < Model }
    end

  end

  class Model

    attr_reader :id

    # Create a container for instances (invoked when a new model is created).
    #
    def self.inherited(subclass)
      subclass.instance_eval { @all = [] }
    end

    # Takes an optional id. Unless it gets one, a new one is generated.
    #
    def initialize( _id = nil )
      @id = _id ? _id.to_i : self.class.all.length
      id = @id
      add_to_all
      self
    end

    # Add a model instance to the list of such instances.
    #
    def add_to_all
      instance = self
      self.class.instance_eval do
        @all << instance
      end
    end
    private :add_to_all

    # Attribute accessors and collections of references from other objects.
    #
    def method_missing( method, args=nil )
      attribute = method.to_s
      klass = Kernel.const_get attribute.chop.capitalize rescue nil

      refs = find_refs klass if attribute[-1..-1] == "s"
      return refs if refs

      attribute[-1..-1] == "=" ? set(attribute.chop, args) : get(attribute)
    end

    # Find instances of another class associated with this instance.
    #
    def find_refs( klass )
      if Jormungandr.models.include? klass
        klass.all.select { |i| i.send(self.class.to_s.downcase.to_sym) == self.id }
      end
    end

    # Store a single attribute.
    #
    def set( attribute, value )
      value = value.id if Jormungandr.models.include? value.class
      Jormungandr.redis.hset _key, attribute, Marshal.dump(value)
    end

    # Retrieve a single attribute.
    #
    def get( attribute )
      Marshal.load Jormungandr.redis.hget(_key, attribute) rescue nil
    end

    # Return the string used as key in the Redis database.
    #
    def _key
      "Jormungandr.#{self.class}.#{id}"
    end

    # Return all stored attributes. Does not include the instance id.
    #
    def attributes
      Jormungandr.redis.hgetall(_key).keys
    end

    # Return all stored attribute-value pairs, including id.
    #
    def to_hash
      Hash[ attributes.zip attributes.map{ |key| send key.to_sym } ].merge!({ 'id' => id })
    end

    class << self

      attr_reader :all

      # Enumerator for all instances of a Model.
      #
      def each
        all.each { |i| yield i }
      end
      include Enumerable

      # Retrieve a Model instance by id.
      #
      def [](_id)
        all.select{ |i| i.id == _id.to_i }.first
      end

      # Retrieve a random Model instance.
      #
      def random
        all[rand all.length]
      end

    end

    # Create a new Model instance. Corresponds to the HTTP method POST.
    #
    def self.post params = {}
      item = self.new
      params.each_pair do |param, value|
        item.send "#{param.to_sym}=", value
      end
      item
    end

    # Retrieve an existing Model instance. Corresponds to the HTTP method GET.
    #
    def self.get params
      all.select do |instance|
        matching = []
        params.keys.each do |param|
          matching << param if instance.send(param) == params[param]
        end
        params.keys == matching
      end
    end

    # Update an existing Model instance. Corresponds to the HTTP method PUT.
    #
    def put params
      if self.class.get params
        params.each_pair { |k, v| send :"#{k}=", v }
      else
        self.class.post params
      end
    end

    # Delete an existing Model instance. Corresponds to the HTTP method DELETE.
    #
    def delete( params=nil )
      s = self
      Jormungandr.redis.del s._key
      s.class.instance_eval { all.delete s }
      s
    end

  end

  load_models!

end

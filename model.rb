
module RedisModel

  class Model

    attr_reader :id

    # Takes an optional id. Unless it gets one, a new one is generated.
    # NOTE: initialize with id option is internal only. Should be a separate method. User-init should take attr-hash..
    #
    def initialize( _id = nil )
      if _id
        @id = _id.to_i
      else
        @id = self.class.all.length
        self.id = @id
      end
      #@id = id ? id.to_i : self.class.all.length
      add_to_all
      self
    end

    # Creates a container for instances when a new model is created
    #
    def self.inherited(subclass)
      subclass.instance_eval do
        @all = []
      end
    end

    # Attribute accessors and collections of references from other objects.
    #
    def method_missing( method, args=nil )
      attribute = method.to_s
      klass = attribute.chop.to_class

      # Simple support for relations between model instances:
      if attribute[-1..-1] == "s" && RedisModel.models.include?(klass)
        refs = klass.all.select { |i| i.send(self.class.to_s.downcase.to_sym) == self.id }
        return refs unless refs.empty?
      end

      # Setters and getters
      if attribute[-1..-1] == "="
        RedisModel.redis.hset _key, attribute.chop, Marshal.dump(args)
      else
        Marshal.load RedisModel.redis.hget(_key, attribute) rescue nil
      end
    end

    private

    # Adds a model instance to the list of such instances.
    #
    def add_to_all
      instance = self
      self.class.instance_eval do
        @all << instance
      end
    end

  end

end
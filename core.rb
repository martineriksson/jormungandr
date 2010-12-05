
require 'rubygems'
require 'redis'
require 'lib/meta'

module RedisModel

  class << self

    # Setup the Redis connection
    #
    def redis(id = nil)
      @@redis = Redis.new(:db => id) if id
      @@redis
    end

    # Creates a Model class and initializes it.
    #
    def create_model(name)
      return nil if name.to_class

      klass = Object.instance_eval { const_set name.to_sym, Class.new(RedisModel::Model) }

      # Scan the database for existing instances and initialize them
      redis.keys("#{self}.#{klass}.*").each { |key| klass.new(key.split('.')[2]) }
    end

    # Scans the database for existing models and initiates them.
    #
    def load_models!
      redis.keys("#{self}.*").map{ |key| key.split('.')[1] }.uniq.each { |c| create_model c }
    end

    # Deletes all RedisModel entries from the database.
    #
    def kill_em_all!
      redis.keys("#{self}.*").each { |key| redis.del key }
      models.each { |model|  model.instance_eval {@all = []}}
    end

    # Returns all RedisModel (sub)classes.
    #
    def models
      Model.descendants
    end

  end

  redis 3

end

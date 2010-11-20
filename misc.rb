
module RedisModel
  
  class Model

  	def _key
      "RedisModel.#{self.class}.#{id}"
    end

    def attributes
  		RedisModel.redis.hgetall(_key).keys
    end

    def to_hash
      Hash[ attributes.zip attributes.map{ |key| send key.to_sym } ].merge!({ 'id' => id })
    end

  	class << self

  		def all
        @all
  		end

      def each
        all.each { |i| yield i }
      end
      include Enumerable

      def [](_id)
        all.select{ |i| i.id == _id.to_i }.first
      end

  		def choice
  		  all.choice
  		end

    end
  
  end

end
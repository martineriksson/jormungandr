
#
# These are the basic CRUD methods för model objects: get, post, put, delete
# 
# They are all thouroughly covered by tests, see: spec/model/spec_crud.rb
#

module RedisModel
  
  class Model

    def self.post params
    	item = self.new
    	params.each_pair do |param, value|
    	  item.send "#{param.to_sym}=", value
    	end
    	item
    	# HTTP response: 201 Created
    end

    def self.get params
      results = all.select do |instance|
        matching = []
        params.keys.each do |param|
          matching << param if instance.send(param) == params[param]
        end
        params.keys == matching
      end
    end

    def put params      
      if self.class.get(params)
        params.each_pair do |attribute, value|
          send :"#{attribute}=", value
        end
      	# HTTP response: 200 OK
      else
        self.class.post(params)
      end
    end

    def delete( params=nil )
      RedisModel.redis.del self._key
      @@all.delete(self)
      # HTTP response: 200 (OK)
    end

  end
  
end

# Simple module pour gérer les logs Laclasse
# Pour l'instant on écrit dans stderr
# todo : il faudra réfléchir a une solution plus sérieuse pour la production
module Laclasse
  Log = Logger.new($stderr)
  #Log = Logger.new('logfile.log')
  class Logging 
  	def initialize(destination, level = Logger::ERROR)
  		@destination = destination
  		@level = level 
  		@logger = Logger.new(destination)
  		@logger.level = level 	
  	end

  	def debug(message)
  		@logger.debug(message)
  	end  

  	def info(message)
  		@logger.info(message)
  	end

  	def warn(message)
  		@logger.warn(message)
  	end

  	def error(message)
  		@logger.error(message)
  	end   
  end 
end
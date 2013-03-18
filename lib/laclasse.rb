# Simple module pour gérer les logs Laclasse
# Pour l'instant on écrit dans stderr
# todo : il faudra réfléchir a une solution plus sérieuse pour la production
module Laclasse
  #Log = Logger.new($stderr)
  Log = Logger.new('logfile.log')
  class Logging < Logger
  		
  end 
end
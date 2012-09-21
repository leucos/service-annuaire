# Require settings
Ramaze::Log.debug("Requiring configs")

require __DIR__('database')
require __DIR__('middleware')
require __DIR__('settings')
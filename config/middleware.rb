#coding: utf-8
module Ramaze
  current_mw = Ramaze.middleware(:dev).middlewares
  middleware! :dev do |m|
    current_mw.each do |mw|
      m.use(mw[0],*mw[1], &mw[2]) # middleware, args, block
    end

    # Define here the middleware to use

    m.run(Ramaze::AppMap)
  end
end

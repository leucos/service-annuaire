#coding: utf-8
module Ramaze
  middleware :dev do
    # Put the 'use' commands here
    run Ramaze.core
  end
end

require 'rails_param/param'
require 'byebug'

ActiveSupport.on_load(:action_controller) do
  include RailsParam::Param
end

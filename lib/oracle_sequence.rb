module Sequel
    module Plugins
        # Plugin trouvé là :
        # https://gist.github.com/1293900
        # Pour info lire cette discussion :
        # https://groups.google.com/group/sequel-talk/tree/browse_frm/month/2011-10/9784829ed35a55b7
        module OracleSequence
            def self.configure(model, seq=nil)
              model.sequence = seq || model.dataset.opts[:sequence]
              model.dataset = model.dataset.sequence(nil) if model.dataset.opts[:sequence]
            end
            module ClassMethods
              attr_accessor :sequence
            end
            module InstanceMethods
                def before_create
                    seq_name = model.sequence
                    unless self.class.simple_pk.nil? or seq_name.nil?
                        self.send("#{self.primary_key.to_s}=", db.fetch("SELECT #{seq_name}.NEXTVAL FROM DUAL").all.first.values.first.to_i)
                    end
                    super
                end
            end
        end
    end
end
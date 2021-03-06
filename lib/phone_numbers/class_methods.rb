module PhoneNumbers
  autoload :Number, "phone_numbers/number"

  module ClassMethods
    def phone_numbers(*attr_names)
      phone_number_format = attr_names.extract_options![:format] || :us
      
      setup_aggregations(attr_names, phone_number_format)
      
      validates_as_phone_number attr_names.map {|attribute_name| "#{attribute_name}_as_phone_number".to_sym}
    end
    alias_method :phone_number, :phone_numbers
  
  private
    def setup_aggregations(attr_names, phone_number_format)
      attr_names.each do |attribute_name|
        composed_of "#{attribute_name}_as_phone_number".intern,
                    :class_name => "PhoneNumbers::Number",
                    :mapping => [attribute_name, "entry"],
                    :allow_nil => true,
                    :constructor => Proc.new { |phone_number| PhoneNumbers::Number.new(phone_number, phone_number_format) }
      end
    end
    
    def validates_as_phone_number(*attr_names)
      configuration = { :on => :save, :allow_nil => true }
      configuration.update(attr_names.extract_options!)
      
      validates_each(attr_names, configuration) do |record, attr_name, value|
        unless value.valid?
          original_attr_name = attr_name.to_s.gsub(/_as_phone_number$/, "").to_sym
          record.errors.add(original_attr_name, :invalid, :default => configuration[:message], :value => value)
        end
      end
    end
  end # ClassMethods
  
end # PhoneNumbers

ActiveRecord::Base.class_eval { extend PhoneNumbers::ClassMethods } if defined?(ActiveRecord::Base)

module HasPhoneNumber
  autoload :PhoneNumber, 'has_phone_number/phone_number'

  module ClassMethods
    def has_phone_number(*attr_names)
      setup_number_formats_registry
      
      phone_number_format = attr_names.extract_options![:format]
      record_number_format(attr_names, phone_number_format)
      
      setup_aggregations(attr_names)
      validates_as_phone_number attr_names.map {|attribute_name| "#{attribute_name}_as_phone_number".to_sym}
    end
  
  private
    def setup_number_formats_registry
      unless respond_to?(:number_formats) && respond_to?(:number_formats=)
        class_inheritable_hash :number_formats
        self.number_formats = {}
        self.number_formats.default = :us
      end
    end
    
    def record_number_format(attr_names, format)
      if format.present?
        attr_names.each { |attribute_name| self.number_formats[attribute_name.to_sym] = format }
      end
    end
    
    def setup_aggregations(attr_names)
      attr_names.each do |attribute_name|
        composed_of "#{attribute_name}_as_phone_number".intern,
                    :class_name => "HasPhoneNumber::PhoneNumber",
                    :mapping => [attribute_name, "number"],
                    :allow_nil => true,
                    :constructor => Proc.new { |phone_number| HasPhoneNumber::PhoneNumber.new(phone_number, number_formats[attribute_name.to_sym]) }
      end
    end
    
    def validates_as_phone_number(*attr_names)
      configuration = { :on => :save }
      configuration.update(attr_names.extract_options!)
      
      validates_each(attr_names, configuration) do |record, attr_name, value|
        unless value.nil? || value.valid?
          original_attr_name = attr_name.to_s.gsub(/_as_phone_number$/, "").intern
          record.errors.add(original_attr_name, :invalid, :default => configuration[:message], :value => value)
        end
      end
    end
  end # ClassMethods
  
end # HasPhoneNumber

ActiveRecord::Base.class_eval { extend HasPhoneNumber::ClassMethods }
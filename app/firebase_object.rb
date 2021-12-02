class FirebaseObject
  attr_accessor :ref,
                :uuid,
                :variables_to_save

  DEBUGGING = true

  def initialize(in_ref)
    puts "#{__FILE__} #{__method__}: #{__LINE__}\a"
    puts "FIREBASEOBJECT INITIALIZE".green if DEBUGGING
    @uuid = NSUUID.UUID
    @ref = in_ref.child(uuid_string)
    @variables_to_save = []

    @ref.observeEventType(FIRDataEventTypeChildChanged,
      withBlock: proc do |data|
        puts "FIREBASEOBJECT CHILDCHANGED".red if DEBUGGING
        App.notification_center.post("#{self.class.name.upcase}Changed", data)
    end)

    @ref.observeEventType(FIRDataEventTypeChildAdded,
      withBlock: proc do |data|
        puts "FIREBASEOBJECT CHILDADDED".red if DEBUGGING
        # Should we turn it into a better-formed hash here?
        App.notification_center.post("#{self.class.name.upcase}New", data)
    end)

    self
  end

  def set_uuid_with_string(in_uuid_string)
    @uuid = NSUUID.alloc.initWithUUIDString(in_uuid_string)
  end

  def update_all
    puts "FIREBASEOBJECT UPDATE_ALL".blue if DEBUGGING
    output = {}
    @variables_to_save.each do |v|
      # puts self.valueForKey(v)
      val = self.valueForKey(v)
      puts val.class
      puts val.class.method_defined? :to_firebase
      # output[v] = val.to_firebase
      # output[v] = val.is_a? ":String" ? val : val.to_firebase # this doesn't work
      # why the hell does this not work for Strings
      # TODO fix this nonsense
      case val
      when String
        output[v] = val # ugh
      when NilClass

      else
        output[v] = val.to_firebase
      end
    end
    puts "Updating all: #{output}"
    @ref.setValue(output)
  end

  def update(node)
    puts "FIREBASEOBJECT UPDATE #{node}".blue if DEBUGGING
    temp_variable = instance_variable_get("@#{node}")
    puts "temp_variable: #{temp_variable}"
    @ref.child("#{uuid_string}/#{node}").setValue(temp_variable)
  end

  def uuid_string
    @uuid.UUIDString if @uuid
  end

  def to_s
    class_name = self.class.name
    puts instance_variables.to_s
    "FirebaseObject: #{class_name}\n\tref: #{@ref}\n\tuuid: #{uuid_string}\n"
  end
end
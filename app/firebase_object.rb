class FirebaseObject
  attr_accessor :ref,
                :variables_to_save,
                :data_hash

  DEBUGGING = true

  def initialize(in_ref, in_data_hash)
    puts "#{__FILE__} #{__method__} line: #{__LINE__}".green if DEBUGGING
    puts "FIREBASEOBJECT INITIALIZE".green if DEBUGGING

    @ref = in_ref
    @data_hash = in_data_hash
    
    self
  end

  def pull
    puts "FIREBASEOBJECT PULL".green if DEBUGGING
    @ref.getDataWithCompletionBlock(
      lambda do | error, data_snapshot |
        puts "Error: #{error.localizedDescription}".red if error
        @data_hash = data_snapshot.valueInExportFormat
      end
    )
  end

  def start_observing
    @ref.observeEventType(FIRDataEventTypeChildChanged, withBlock: 
      lambda do |data_snapshot|
        puts "FIREBASEOBJECT CHILDCHANGED".red if DEBUGGING
        App.notification_center.post("#{self.class.name.upcase}Changed", data_snapshot)
    end)

    @ref.observeEventType(FIRDataEventTypeChildAdded, withBlock: 
      lambda do |data_snapshot|
        puts "FIREBASEOBJECT CHILDADDED".red if DEBUGGING
        App.notification_center.post("#{self.class.name.upcase}New", data_snapshot)
    end)
  end

  def update_all
    puts "FIREBASEOBJECT UPDATE_ALL".blue if DEBUGGING
    @ref.setValue(data_hash, withCompletionBlock: 
      lambda do |error, ref|
        puts "FIREBASEOBJECT UPDATED".green
        puts "Updated: #{ref.key}".green
      end
    )
  end

  def update(node)
    puts "FIREBASEOBJECT UPDATE #{node}".blue if DEBUGGING
    temp_variable = instance_variable_get("@#{node}")
    # puts "temp_variable: #{temp_variable}"
    @ref.child("#{node}").setValue(temp_variable.to_firebase)
  end
  
  def get_node(node)
    @ref.child(node).getDataWithCompletionBlock(
      lambda do | error, data_snapshot |
        puts "Error: #{error.localizedDescription}".red if error
        return data_snapshot.valueInExportFormat
      end
    )
  end
  
  def do_node_completion(node, &completion)
    @ref.child(node).getDataWithCompletionBlock(
      lambda do | error, data_snapshot |
        puts "Error: #{error.localizedDescription}".red if error
        
        completion.call(data_snapshot.valueInExportFormat)
      end
    )
  end

  def to_s
    "FirebaseObject: #{self.class.name}\n\tref: #{@ref}\n\tdata_hash: #{@data_hash}\n"
  end
end

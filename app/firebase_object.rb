class FirebaseObject
  attr_accessor :ref,
                :data_hash,
                :class_name

  DEBUGGING = true

  def initialize(in_ref, in_data_hash = {})
    @ref = in_ref
    @data_hash = in_data_hash
    @class_name = self.class.name.capitalize

    puts "FBO:#{@class_name} INITIALIZE".green if DEBUGGING

    push unless in_data_hash.nil?
    pull if in_data_hash.nil?

    start_observing
  
    self
  end

  def push
    puts "FBO:#{@class_name} PUSH".green if DEBUGGING
    @ref.setValue(@data_hash, withCompletionBlock:
      lambda do |error, ref|
        puts 'apparently this saved'.red
      end
    )
  end

  def pull
    puts "FBO:#{@class_name} PULL".green if DEBUGGING
    @ref.observeSingleEventOfType(FIRDataEventTypeValue, withBlock:
      lambda do |data_snapshot|
        @data_hash = data_snapshot.valueInExportFormat
      end
    )
  end

  def start_observing
    @ref.observeEventType(FIRDataEventTypeChildChanged, withBlock:
      lambda do |data_snapshot|
        puts "FBO:#{@class_name} CHILDCHANGED".red if DEBUGGING
        App.notification_center.post("#{@class_name}Changed", data_snapshot.valueInExportFormat)
        pull
    end)

    @ref.observeEventType(FIRDataEventTypeChildAdded, withBlock:
      lambda do |data_snapshot|
        puts "FBO:#{@class_name} CHILDADDED".red if DEBUGGING
        App.notification_center.post("#{self.class.name.upcase}New", data_snapshot.valueInExportFormat)
        pull
    end)
  end

  def update(node_hash)
    puts "FBO:#{@class_name} UPDATE #{node_hash}".blue if DEBUGGING

    # this merges in place, so be careful!
    @data_hash.merge!(node_hash)

    @ref.updateChildValues(node_hash)
    puts "Updated data_hash: #{@data_hash}".blue
  end

  def to_s
    "FirebaseObject: #{@class_name}\n\tref: #{@ref}\n\tdata_hash: #{@data_hash}\n"
  end
end

class FirebaseObject
  extend Debugging
  extend Utilities

  attr_accessor :ref,
                :data_hash,
                :class_name

  DEBUGGING = true

  # rubocop:disable Lint/Void
  def initialize(in_ref, in_data_hash = {})
    @ref = in_ref
    @data_hash = in_data_hash

    mp in_data_hash.empty?

    unless in_data_hash.empty?
      @data_hash.merge!('key' => @ref.key)
      @data_hash.merge!('created' => FIRServerValue.timestamp)
    end

    @class_name = self.class.name.capitalize

    Utilities::puts_open
    puts "FBO:#{@class_name} INITIALIZE".green if DEBUGGING

    push unless in_data_hash.empty?
    pull if in_data_hash.empty?

    start_observing

    # we have to do this
    self
  end
  # rubocop:enable Lint/Void

  def push
    # puts "FBO:#{@class_name} PUSH".green if DEBUGGING
    @ref.setValue(
      @data_hash, withCompletionBlock:
      lambda do |_error, _ref|
        puts "FBO:#{@class_name} setValue".green
      end
    )
  end

  def pull
    puts "FBO:#{@class_name} PULL".green if DEBUGGING
    @ref.observeSingleEventOfType(
      FIRDataEventTypeValue, withBlock:
      lambda do |data_snapshot|
        mp data_snapshot.valueInExportFormat
        @data_hash = data_snapshot.valueInExportFormat
      end
    )
  end

  def pull_with_block(&in_proc)
    puts "FBO:#{@class_name} pull_with_block".red if DEBUGGING
    @ref.observeSingleEventOfType(
      FIRDataEventTypeValue, withBlock:
      lambda do |data_snapshot|
        @data_hash = data_snapshot.valueInExportFormat
        in_proc.call
      end
    )
  end

  def start_observing
    @ref.observeEventType(
      FIRDataEventTypeChildChanged, withBlock:
      lambda do |data_snapshot|
        # puts "FBO:#{@class_name} CHILDCHANGED".red if DEBUGGING
        # mp data_snapshot.valueInExportFormat if DEBUGGING
        App.notification_center.post("#{@class_name}_ChildChanged", data_snapshot.valueInExportFormat)
        pull
      end
    )

    @ref.observeEventType(
      FIRDataEventTypeChildAdded, withBlock:
      lambda do |data_snapshot|
        puts "FBO:#{@class_name} CHILDADDED".red if DEBUGGING
        # mp data_snapshot.valueInExportFormat if DEBUGGING
        App.notification_center.post("#{@class_name}_ChildAdded", data_snapshot.valueInExportFormat)
        pull
      end
    )

    @ref.observeEventType(
      FIRDataEventTypeChildRemoved, withBlock:
      lambda do |data_snapshot|
        # puts "FBO:#{@class_name} CHILDREMOVED".red if DEBUGGING
        App.notification_center.post("#{@class_name}_ChildRemoved", data_snapshot.valueInExportFormat)
        pull
      end
    )
  end

  def value_at(node_string)
    puts "FBO:#{@class_name} VALUE_AT #{node_string}".blue if DEBUGGING
    puts "node_string: #{node_string}".focus
    # @ref.child(node).observeEventType(
    #   FIRDataEventTypeValue, withBlock:
    #   lambda do |data_snapshot|
    #     puts "FBO:#{@class_name} VALUE_AT".focus
    #     mp data_snapshot.valueInExportFormat
    #   end
    # )
    @ref.getDataWithCompletionBlock(
      lambda do |_error, data_snapshot|
        puts "FBO:#{@class_name} VALUE_AT".focus
        return data_snapshot.childSnapshotForPath(node_string).valueInExportFormat.values
      end
    )
  end

  def update(node_hash)
    puts "FBO:#{@class_name} UPDATE #{node_hash}".blue if DEBUGGING

    # this merges in place, so be careful!
    @data_hash.merge!(node_hash)

    @ref.updateChildValues(node_hash)
  end

  def update_with_block(node_hash, &in_proc)
    puts "FBO:#{@class_name} update_with_block #{node_hash}".blue if DEBUGGING

    # this merges in place, so be careful!
    @data_hash.merge!(node_hash)

    @ref.updateChildValues(
      node_hash,
      withCompletionBlock:
        lambda do |_error, _ref|
          in_proc.call
        end
    )
  end

  def delete
    puts "FBO:#{@class_name} DELETE".blue if DEBUGGING
    @ref.removeAllObservers
    @ref.removeValue
  end

  def key
    @ref.key
  end

  def to_s
    "FirebaseObject: #{@class_name}\n\tref: #{@ref}\n\tdata_hash: #{@data_hash}\n"
  end
end

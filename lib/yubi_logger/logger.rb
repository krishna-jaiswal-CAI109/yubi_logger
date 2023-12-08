module YubiLogger
    class Logger < ActiveSupport::Logger
      @@log_mutex = Mutex.new
  
      def initialize(logfile, archived_logfile, max_log_size = 1 * 1024, num_of_archived_files_to_retain = 1)
        super(logfile)
        @max_log_size = max_log_size
        @archived_logfile = archived_logfile
        @num_of_archived_files_to_retain = (num_of_archived_files_to_retain == 0) ? 1 : num_of_archived_files_to_retain
        @formatter = ::Logger::Formatter.new
      end
  
      def add(severity, message = nil, progname = nil, &block)
        # class_name = caller_locations(1,1)[0].label
        # class_name = self.class.name
        # class_name = caller_locations
        # puts "class_name : #{class_name}"
        # puts "class_name : #{class_name}"
        # puts "severity : #{severity}"
        # puts "message : #{message}"
        # puts "progname : #{progname}"
        # progname = "MyApplication"
  
  
        @@log_mutex.lock
        begin
          if File.size(@logdev.dev) > @max_log_size
            # byebug
            archive_current_log
            # puts "File size : #{File.size(@logdev.dev)}}"
            # puts "max_log_size : #{@max_log_size}"
          end
        ensure
          @@log_mutex.unlock
        end
  
        puts Rails.logger
        puts @logdev
  
        super
      end
  
      private
  
  
      def archive_current_log
        @logdev.close
        # FileUtils.mv(@logdev.dev, @archived_logfile)
  
        archived_log_file_name_without_extension = @archived_logfile.sub(/\.log$/, '') # Remove .log extension
        puts "archived_log_file_name_without_extension : #{archived_log_file_name_without_extension}"
        timestamp = Time.now.strftime("%Y%m%d_%H:%M:%S") # Add timestamp
        puts "timestamp : #{timestamp}"
        archived_log_file_name = "#{archived_log_file_name_without_extension}_#{timestamp}.log"
        puts "archived_log_file_name : #{archived_log_file_name}"
        FileUtils.mv(@logdev.filename, archived_log_file_name)
  
        # Get a list of all archived log files
        # archived_files = Dir.glob("#{File.dirname(archived_log_file_name)}/#{archived_log_file_name_without_extension}_*.log").sort
        archived_files = Dir.glob("#{archived_log_file_name_without_extension}_*.log").sort
        puts "archived_files_list : #{archived_files}"
  
        # Calculate how many files need to be deleted to retain only num_of_archived_files_to_retain
        files_to_delete = archived_files.size - @num_of_archived_files_to_retain
        puts "number of files to delete : #{files_to_delete}"
  
        # Delete the oldest archived log files if necessary
        if files_to_delete > 0
          files_to_delete.times do
            File.delete(archived_files.shift)
            puts "archived_files_list after removal : #{archived_files}"
          end
        end
  
        @logdev = Logger::LogDevice.new(@logdev.filename)
      end
    end
  end
  
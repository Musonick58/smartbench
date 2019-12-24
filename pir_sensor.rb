#!/usr/bin/ruby
require 'rpi_gpio'

class PirSensor
  #COSTANTI
  PIN_LAYOUT      = :board
  PRESENCE_SENSOR = 40
  FILENAME        = "PIR_SENSOR.txt"
  SLEEP_TIME      = 0.25 

  #ERROR LOGGER
  def error_logger(error)
    filename  = Time.now.strftime("%Y_%m_%d_%H_%M_%S")
    filename += FILENAME+filename
    filename += ".log"
    File.open("/home/pi/smartbench/log/"+filename,"w"){|f|
      f.write(error.message + "\nRunning since #{@init_time.to_s}")
    }
  end
    
  #inzilizzatore della classe 
  def initialize
      @presence_counter = 0.0
      @init_time        = Time.now
      @current_day      = Time.now
      @run              = true
      `mkdir -p /home/pi/smartbench/sensors/` rescue nil
      `mkdir -p /home/pi/smartbench/log/` rescue nil
      `touch /home/pi/smartbench/sensors/#{FILENAME}`   rescue nil
      RPi::GPIO.set_numbering PIN_LAYOUT
      RPi::GPIO.setup PRESENCE_SENSOR, :as => :input
  end

  def write_file(data)
    write_date = Time.now.to_s
    File.open("/home/pi/smartbench/sensors/#{FILENAME}","w"){|f|
      f.write("#{data}|#{write_date}")
    }
  end

  def main
    begin
      while @run do 
        if(Time.now.day > @current_day.day )
          @presence_counter = 0.0
          @current_day = Time.now
        end
        #contatore delle presenze
        puts "è alto il pin #{PRESENCE_SENSOR} => #{RPi::GPIO.high? PRESENCE_SENSOR}"
        
        @presence_counter += 1.0 if RPi::GPIO.high? PRESENCE_SENSOR
        
        self.write_file(@presence_counter)

        sleep(SLEEP_TIME)
      end
    rescue Exception => e
      error_logger(e)
      raise e
    end
  end
  
end


scd30_logger = PirSensor.new()
scd30_logger.main()
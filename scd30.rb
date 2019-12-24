#!/bin/ruby
require 'net/http'
require 'json'
require 'rpi_gpio'
require 'byebug'

class scd30
    #COSTANTI
    DATA_FOLDER     = "./sensors"
    CO2_SENSOR      = "CO2_SENSOR.txt"
    TEMP_SENSOR     = "TEMP_SENSOR.txt"
    HUMI_SENSOR     = "HUMI_SENSOR.txt"
    URI             = URI("https://sviluppo.platformdevelopment.it/software-venitech/mvc/index.php/data_manager/register_data")
    SLEEP_TIME      = 2

    #ERROR LOGGER
    def error_logger(error)
      filename  = Time.now.strftime("%Y_%m_%d_%H_%M_%S")
      filename += FILENAME+filename
      filename += ".log"
      File.open("./log/"+filename,"w"){|f|
        f.write(error.message + "\nRunning since #{@init_time.to_s}")
      }
    end

    #inzilizzatore della classe 
    def initialize
      @init_time        = Time.now
      @current_day      = Time.now
      @run              = true
    end

    #chiedo a python2 di darmi i dati dell'interfaccia i2c
    def getSCD30
      begin
        data =  `python2 scd30.py`
        data = JSON.parse(data)
        pp data
      rescue => e
        #se fallisce per qualsiasi motivo loggo l'eccezione
        puts "#{e.message}"
        puts "data not valid"
        data = {}
      end
      return data
    end

    def write_file(filename,data)
      write_date = Time.now.strftime("%Y_%m_%d_%H_%M")
      File.open("#{DATA_FOLDER}#{filename}","w"){|f|
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
          @presence_counter += 1.0 if RPi::GPIO.high? PRESENCE_SENSOR

          #valori co2, temperatura, umidità
          data = self.getSCD30
          write_file(CO2_SENSOR,data["co2"])
          write_file(CO2_SENSOR,data["temp"])
          write_file(CO2_SENSOR,data["humi"])

          sleep(SLEEP_TIME)
        end
      rescue Exception => e
        error_logger(e)
        raise e
      end
    end    
end

scd30_logger = DataLogger.new()
scd30_logger.main()
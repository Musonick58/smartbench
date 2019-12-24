#!/usr/bin/ruby
require 'net/http'
require 'json'
require 'rpi_gpio'
require 'byebug'

class Scd30
    #COSTANTI
    DATA_FOLDER     = "/home/pi/smartbench/sensors"
    CO2_SENSOR      = "CO2_SENSOR.txt"
    TEMP_SENSOR     = "TEMP_SENSOR.txt"
    HUMI_SENSOR     = "HUMI_SENSOR.txt"
    SLEEP_TIME      = 2

    #ERROR LOGGER
    def error_logger(error)
      filename  = Time.now.strftime("%Y_%m_%d_%H_%M_%S")
      filename += "SCD30_"+filename
      filename += ".log"
      File.open("/home/pi/smartbench/log/"+filename,"w"){|f|
        f.write(error.message + "\nRunning since #{@init_time.to_s}")
      }
    end

    #inzilizzatore della classe 
    def initialize
      @init_time        = Time.now
      @current_day      = Time.now
      @run              = true
      `sudo pigpiod` rescue nil
      `mkdir -p /home/pi/smartbench/log/`     rescue nil
      `mkdir -p #{DATA_FOLDER}`               rescue nil
    end

    #chiedo a python2 di darmi i dati dell'interfaccia i2c
    def getSCD30
      begin
        data =  `python2 /home/pi/smartbench/scd30.py`
        data = JSON.parse(data)
        #pp data
      rescue => e
        #se fallisce per qualsiasi motivo loggo l'eccezione
        puts "#{e.message}"
        puts "data not valid"
        data = {}
      end
      return data
    end

    def write_file(filename,data)
      write_date = Time.now.to_s
      File.open("#{DATA_FOLDER}/#{filename}","w"){|f|
        f.write("#{data}|#{write_date}")
      }
    end

    def main
      begin
        while @run do 
          
          #valori co2, temperatura, umidità
          data = self.getSCD30
          pp data
          write_file(CO2_SENSOR, data["co2"].to_f - 2.5)
          write_file(TEMP_SENSOR,data["temp"])
          write_file(HUMI_SENSOR,data["humi"])

          sleep(SLEEP_TIME)
        end
      rescue Exception => e
        #se fallisce scrivo nel file l'eccezione
        error_logger(e)
        raise e
      end
    end    
end

scd30_logger = Scd30.new()
scd30_logger.main()
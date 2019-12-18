#!/bin/ruby
require 'net/http'
require 'json'
require 'rpi_gpio'
require 'byebug'
class DataLogger
    #COSTANTI
    PIN_LAYOUT      = :board
    PRESENCE_SENSOR = 40
    LED1            = nil
    LED2            = nil
    SLEEP_TIME      = 5 #(60*5) #5 minuti
    URI             = URI("https://sviluppo.platformdevelopment.it/software-venitech/mvc/index.php/data_manager/register_data")

    #ERROR LOGGER
    def error_logger(error)
      filename = Time.now.strftime("%Y_%m_%d_%H_%M")
      filename += ".log"
      File.open("./log/"+filename,"w"){|f|
        f.write(error.message + "\nRunning since #{@init_time.to_s}")
      }
    end

    #inzilizzatore della classe 
    def initialize
        @presence_counter = 0.0
        @init_time        = Time.now
        @current_day      = Time.now
        @run              = true
        @owner            =  -1
        @led1             = nil
        @led2             = nil
        @owner            = `ifconfig eth0 | grep ether`
        @owner            = @ethernet.split(" ")[1]
        @benchname        = "smartbench_0"
        RPi::GPIO.set_numbering PIN_LAYOUT
        RPi::GPIO.setup PRESENCE_SENSOR, :as => :input

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

    def send_data(data)
      data["benchname"] = @benchname
      #data["co2"]
      #data["temp"]
      #data["hum"]
      data["owner"] = @owner
      data["led1"]  = @led1
      data["led2"]  = @led2
      data["timestamp"] = Time.now.to_s
      pp data
      raise "aa"
      res = Net::HTTP.post_form(URI, data)
      #res.basic_auth 'matt', 'secret'
      puts res.body
      #@led1 = res.body.led1
      #@led2 = res.body.led2
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

          data["presence"] = @presence_counter

          send_data(data)

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
#!/bin/ruby
require 'net/http'
require 'json'
require 'byebug'

class Network 
  DATA_FOLDER     = "./sensors"
  PIR_SENSOR      = "PIR_SENSOR.txt"
  CO2_SENSOR      = "CO2_SENSOR.txt"
  TEMP_SENSOR     = "TEMP_SENSOR.txt"
  HUMI_SENSOR     = "HUMI_SENSOR.txt"
  LED1            = "LED1.txt"
  LED2            = "LED2.txt"
  SLEEP_TIME      = 5 #(60*5) #5 minuti
  URI             = URI("https://sviluppo.platformdevelopment.it/software-venitech/mvc/index.php/data_manager/register_data")

  #inzilizzatore della classe 
  def initialize
    @init_time        = Time.now
    @current_day      = Time.now
    @run              = true
    `mkdir -p ./log/` rescue nil
    `touch #{DATA_FOLDER}/#{LED1}` rescue nil
    `touch #{DATA_FOLDER}/#{LED2}` rescue nil
  end

  #ERROR LOGGER
  def error_logger(error)
    filename = Time.now.strftime("%Y_%m_%d_%H_%M")
    filename += ".log"
    File.open("./log/"+filename,"w"){|f|
      f.write(error.message + "\nRunning since #{@init_time.to_s}")
    }
  end

  def read_file(filename)
    sensor = File.open("#{DATA_FOLDER}/#{filename}").read()
    temp = {}
    temp[filename.gsub(".txt","")] = sensor.split("|")[0]
    return temp
  end

  def send_data
    data = {}
    pir  = read_file(PIR_SENSOR )
    co2  = read_file(CO2_SENSOR )
    temp = read_file(TEMP_SENSOR)
    humi = read_file(HUMI_SENSOR)
    data = data.merge(pir).merge(co2).merge(temp).merge(humi)
    data["timestamp"] = Time.now.to_s
   
    pp data
    #raise "NETWORK"
    #raise "aa"
    #res = Net::HTTP.post_form(URI, data)
    #res.basic_auth 'matt', 'secret'
    #puts res.body
    #@led1 = res.body.led1
    #@led2 = res.body.led2
  end

  def main
    begin
      while @run do 

        send_data()

        sleep(SLEEP_TIME)
      end
    rescue Exception => e
      error_logger(e)
      raise e
    end
  end

end
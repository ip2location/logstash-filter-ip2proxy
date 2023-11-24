# encoding: utf-8
require_relative '../spec_helper'
require "logstash/filters/ip2proxy"

IP2PROXYDB = ::Dir.glob(::File.expand_path("../../vendor/", ::File.dirname(__FILE__))+"/IP2PROXY-LITE-PX1.BIN").first

describe LogStash::Filters::IP2Proxy do

  describe "normal test" do
    config <<-CONFIG
      filter {
        ip2proxy {
          source => "ip"
          #database => "#{IP2PROXYDB}"
        }
      }
    CONFIG

    sample("ip" => "8.8.8.8") do
      expect(subject.get("ip2proxy")).not_to be_empty
      expect(subject.get("ip2proxy")["country_short"]).to eq("US")
      end
    end

  end

end
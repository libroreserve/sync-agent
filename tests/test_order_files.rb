require 'test/unit'
require_relative '../lib/agent'

ENV['API_ENDPOINT'] = 'http://api.local.libroreserve.com:3000/inbound/maitre_d/status'
ENV['WORKING_DIR'] = File.expand_path('tests/working')

class TestOrderFiles < Test::Unit::TestCase
  def test_order_files
    agent = Agent.new(ENV['WORKING_DIR'], /RTBL.+\.xml|ST.+\.xml/i, ENV['API_ENDPOINT'], logger: Logger.new('tests/tmp/log'))

    files = [
      "Z627-A.xml",
      "Z763-2.xml",
      "AB123.xml",
      "ST77899.xml",
      "ST77899-1.xml",
      "ST77899-2.xml",
      "ST77899-3.xml",
      "ZZ999.xml",
      "ZZ999-1.xml",
      "Z763.xml",
      "Z763-A.xml",
      "Z763-10.xml",
      "Z763-1.xml",
      "Z763-3.xml",
      "Z763-B.xml"
    ]

    expected_order = [
      "AB123.xml",
      "ST77899.xml",
      "ST77899-1.xml",
      "ST77899-2.xml",
      "ST77899-3.xml",
      "Z627-A.xml",
      "Z763.xml",
      "Z763-1.xml",
      "Z763-2.xml",
      "Z763-3.xml",
      "Z763-10.xml",
      "Z763-A.xml",
      "Z763-B.xml",
      "ZZ999.xml",
      "ZZ999-1.xml"
    ]

    assert_equal expected_order, agent.send(:order_files, files)
  end
end

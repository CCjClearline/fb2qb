#!/usr/bin/env ruby

class Transaction
  Struct.new(:trnsid, :trnstype, :date, :accnt, :name, :amount, :docnum, :memo, :paid, :spl)
end

class Splitline
  attr_accessor :splid, :trnstype, :date, :accnt, :name, :amount, :docnum, :memo, :price, :qnty, :invitem, :paymeth, :taxable, :extra
end

ARGF.each do |line|
  puts line
end
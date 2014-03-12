#!/usr/bin/env ruby

class Transaction
  Struct.new(:trnsid, :trnstype, :date, :accnt, :name, :amount, :docnum, :memo, :paid, :spl)
end

class Splitline
  attr_accessor :splid, :trnstype, :date, :accnt, :name, :amount, :docnum, :memo, :price, :qnty, :invitem, :paymeth, :taxable, :extra
end


# Read through our input file line by line
ARGF.each do |line|
   # puts "%3d: %s" % [ARGF.lineno, line]
   
   # The FreshBooks export has some garbage which needs to be cleaned up before we can parse what we have
   line = line.delete("\n") # Remove line break chara from the end of each line
   line = line.delete("\"") # Remove extraneous back slash from the end of each line
   
   # line is a tab-deliminated series, whose type can be identified by the first field
   linetype = line.split("\t").first
   
   puts "%3d: %s" % [ARGF.lineno, linetype]
   
   case linetype

   when "!TRNS"
     # We're at the beginning of the transactions section, defining fields.
     iam = "TRNS header"
     
   when "!SPL"
     # We're at the beginning of the splitline section, defining fields.
     iam = "SPL header"
     
   when "!ENDTRNS"
     # We're at the end of the transaction headers
     iam = "EOH"

   when "TRNS"
     # We're beginning a transaction block 
     iam = "TRNS detail"
     
   when "SPL"
     # We're in a splitline
     iam = "SPL detail"
     
   when "ENDTRNS"
     # we're at the end of a transaction block
     iam = "EOT"
     
   end # case linetype
   
   puts "I am a #{iam} line."
   
end
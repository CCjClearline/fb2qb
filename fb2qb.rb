#!/usr/bin/env ruby

require 'pp'
require 'ap'

class Transaction
  attr_accessor :trnsid, :trnstype, :date, :accnt, :name, :amount, :docnum, :memo, :paid, :spl
end

class Splitline
  attr_accessor :splid, :trnstype, :date, :accnt, :name, :amount, :docnum, :memo, :price, :qnty, :invitem, :paymeth, :taxable, :extra
end

class Counter
  attr_accessor :value
  def initialize(i = 0)
    @value = i
  end
  def inc
    @value = @value.succ
  end
  def reset
    @value = 0
  end
end

trnsnum = Counter.new
splnum = Counter.new

@trns = []

@error = ""


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
     iam = "TRNS header"
     # We're at the beginning of the transactions section, defining fields.
     
     # We know what fields are allowed, but not necessarily what order they are in.
     # Create an array of field names, so we can flip through them, looking for what we want
     trnsheader = line.split("\t")
     
     trnsheader.each_with_index do |value,index|
       puts "%5d: %s" % [index, value]
       if value == "!TRNS"
         @trnstrnsid = index
       elsif value == "TRNSID"
         @trnstrnsidid = index
       elsif value == "TRNSTYPE"
         @trnstrnstypeid = index
       elsif value == "DATE"
         @trnsdateid = index
       elsif value == "ACCNT"
         @trnsaccntid = index
       elsif value == "NAME"
         @trnsnameid = index
       elsif value == "AMOUNT"
         @trnsamountid = index
       elsif value == "DOCNUM"
         @trnsdocnumid = index
       elsif value == "MEMO"
         @trnsmemoid = index
       elsif value == "PAID"
         @trnspaidid = index
       else
         @error << "Unrecognized TRNS field: #{value}."
       end #trnsheader.each_with_index
       
       
     end #trnsheader.each
     
   when "!SPL"
     iam = "SPL header"
     # We're at the beginning of the splitline section, defining fields.
     
     
   when "!ENDTRNS"
     iam = "EOH"
     # We're at the end of the transaction headers
     

   when "TRNS"
     iam = "TRNS detail"
     # We're beginning a transaction block 
     
     currenttrns = line.split("\t")
     
     puts "   TRNS ##{trnsnum.value}"
     puts "%5d: %s" % [@trnstrnsid, currenttrns[@trnstrnsid.to_i]] if @trnstrnsid
     puts "%5d: %s" % [@trnstrnsidid, currenttrns[@trnstrnsidid.to_i]] if @trnstrnsidid 
     puts "%5d: %s" % [@trnstrnstypeid, currenttrns[@trnstrnstypeid.to_i]] if @trnstrnstypeid
     puts "%5d: %s" % [@trnsmemoid, currenttrns[@trnsmemoid.to_i]] if @trnsmemoid
     
     @transaction = Transaction.new
     
     @transaction.trnsid = currenttrns[@trnstrnsid.to_i] if @trnstrnsid
     @transaction.trnstype = currenttrns[@trnstrnstypeid.to_i] if @trnstrnstypeid
     @transaction.memo = currenttrns[@trnsmemoid.to_i] if @trnsmemoid
     @transaction.docnum = currenttrns[@trnsdocnumid.to_i] if @trnsdocnumid
     
     puts @transaction.inspect
     
   when "SPL"
     iam = "SPL detail"
     # We're in a splitline
     
     puts "    SPL ##{splnum.value}"

     # increment SPL counter
     splnum.inc

   when "ENDTRNS"
     iam = "EOT"
     # we're at the end of a transaction block
     
     @trns << @transaction
     
     # increment TRNS counter & reset SPL counter
     trnsnum.inc
     splnum.reset
     
   end # case linetype
   
   #puts "I am a #{iam} line."
   
end #ARGF.each

puts @error

puts ""

ap @trns

@trns.each do |transaction|
  puts transaction.trnstype
end

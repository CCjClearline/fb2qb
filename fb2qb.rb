#!/usr/bin/env ruby

require 'pp'
require 'ap'

class Transaction
  attr_accessor :trnsid, :trnstype, :date, :accnt, :name, :amnt, :docnum, :memo, :paid, :spl
end

class Splitline
  attr_accessor :splid, :trnstype, :date, :accnt, :name, :amnt, :docnum, :memo, :price, :qnty, :invitem, :paymeth, :taxable, :extra
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
       
       # Can we clean this up by looking up the defined attributes for the Transaction class and setting 
       # @trns{attribute_name}id = index if value == {attribute_name}
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
       elsif value == "AMNT"
         @trnsamntid = index
       elsif value == "DOCNUM"
         @trnsdocnumid = index
       elsif value == "MEMO"
         @trnsmemoid = index
       elsif value == "PAID"
         @trnspaidid = index
       else
         @error << "Unrecognized TRNS field: #{value}."
       end # if value ==
       
       
     end #trnsheader.each_with_index
     
   when "!SPL"
     iam = "SPL header"
     # We're at the beginning of the splitline section, defining fields.
     # :splid, :trnstype, :date, :accnt, :name, :amt, :docnum, :memo, :price, :qnty, :invitem, :paymeth, :taxable, :extra
     
     splheader = line.split("\t")
     splheader.each_with_index do |value,index|
       puts "%5d: %s" % [index, value]
       # Can we clean this up by looking up the defined attributes for the Splitline class and setting @spl{attribute_name}id = index?
       if value == "!SPL"
         @splsplid = index
       elsif value == "SPLID"
         @splsplidid = index
       elsif value == "TRNSTYPE"
         @spltrnstypeid = index
       elsif value == "DATE"
         @spldateid = index
       elsif value == "ACCNT"
         @splaccntid = index
       elsif value == "NAME"
         @splnameid = index
       elsif value == "AMNT"
         @splamntid = index
       elsif value == "DOCNUM"
         @spldocnumid = index
       elsif value == "MEMO"
         @splmemoid = index
       elsif value == "PRICE"
         @splpriceid = index
       elsif value == "QNTY"
         @splqntyid = index
       elsif value == "INVITEM"
         @splinvitemid = index
       elsif value == "PAYMETH"
         @splpaymethid = index
       elsif value == "TAXABLE"
         @spltaxableid = index
       elsif value == "EXTRA"
         @splextraid = index
       else
         @error << "Unrecognized SPL field #{value}."
       end # if value ==
       
     end #splheader.each_with_index
     
     
   when "!ENDTRNS"
     iam = "EOH"
     # We're at the end of the transaction headers
     # Nothing to do here

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
     
     # .spl is going to be an array of SPL lines for this transaction
     @transaction.spl = []
     
     puts "     #{@transaction.inspect}"
     
   when "SPL"
     iam = "SPL detail"
     # We're in a splitline
     
     currentspl = line.split("\t")
     
     puts "    SPL ##{splnum.value}"
     puts "%5d: %s" % [@splsplid, currentspl[@splsplid.to_i]] if @splsplid
     puts "%5d: %s" % [@splaccntid, currentspl[@splaccntid.to_i]] if @splaccntid 
     puts "%5d: %s" % [@splamntid, currentspl[@splamntid.to_i]] if @splamntid
     puts "%5d: %s" % [@splmemoid, currentspl[@splmemoid.to_i]] if @splmemoid
     
     @splitline = Splitline.new
     
     @splitline.splid = currentspl[@splsplid.to_i] if @splsplid
     @splitline.accnt = currentspl[@splaccntid.to_i] if @splaccntid 
     @splitline.amnt = currentspl[@splamntid.to_i] if @splamntid
     
     puts "     #{@splitline.inspect}"
     
     @transaction.spl << @splitline

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

pp @trns

puts ""

@trns.each do |transaction|
  puts "This transaction is type #{transaction.trnstype}."
  puts "This transaction has #{transaction.spl.count} splitlines."
  puts "The second splitline looks like this: #{transaction.spl[1].inspect}"
  puts ""
end

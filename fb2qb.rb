#!/usr/bin/env ruby

require 'pp'
require 'ap'

class Transaction
  attr_accessor :trns, :trnsid, :trnstype, :date, :accnt, :name, :amount, :docnum, :memo, :paid, :paymeth, :original, :spl
  
  def self.all
    ObjectSpace.each_object(self).to_a
  end

  def self.count
    all.count
  end
  
end

class Splitline
  attr_accessor :spl, :splid, :trnstype, :date, :accnt, :name, :amount, :docnum, :memo, :price, :qnty, :invitem, :paymeth, :taxable, :extra
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
       elsif value == "AMOUNT"
         @trnsamountid = index
       elsif value == "DOCNUM"
         @trnsdocnumid = index
       elsif value == "MEMO"
         @trnsmemoid = index
       elsif value == "PAID"
         @trnspaidid = index
       elsif value == "PAYMETH"
         @trnspaymethid = index
       else
         @error << "Unrecognized TRNS field: #{value}.\n"
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
       elsif value == "AMOUNT"
         @splamountid = index
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
         @error << "Unrecognized SPL field #{value}.\n"
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
     puts "%5d: %s" % [@trnstrnstypeid, currenttrns[@trnstrnstypeid.to_i]] if @trnstrnstypeid
     puts "%5d: %s" % [@trnsmemoid, currenttrns[@trnsmemoid.to_i]] if @trnsmemoid
     
     @transaction = Transaction.new
     
     @transaction.trns = currenttrns[@trnstrnsid.to_i] if @trnstrnsid
     @transaction.trnsid = nil
     @transaction.trnstype = currenttrns[@trnstrnstypeid.to_i] if @trnstrnstypeid
     @transaction.memo = currenttrns[@trnsmemoid.to_i] if @trnsmemoid
     @transaction.docnum = currenttrns[@trnsdocnumid.to_i] if @trnsdocnumid
     
     # Storing original line to make it easier to process duplicate transactions
     @transaction.original = line
     
     # .spl is going to be an array of SPL lines for this transaction
     @transaction.spl = []
     puts ""
     puts "     Original transaction is:"
     puts "     #{@transaction.inspect}"
     
     
     if @transaction.trnstype == "GENERAL JOURNAL"
     # This is a trick question; all FB transactions are JE transactions. But maybe one day....
     # This is a JE transaction; transform the shit out of it.
      
      # What sort of transaction is this really?
      # Allowed, expected values include
      #   Invoice
      #   Payment
      #   Credit Memo
      @transaction.trnstype = "INVOICE" if @transaction.memo.start_with?("Invoice")
      @transaction.trnstype = "PAYMENT" if @transaction.memo.start_with?("Payment")
      @transaction.trnstype = "CREDIT MEMO" if @transaction.memo.start_with?("Credit")
     
      case @transaction.trnstype
        
      when "INVOICE"
        # Invoice number is in @transaction.memo -- "Invoice: 1234 ....."

        #docnum = @transaction.memo
        #puts "Document number is #{docnum}"
        #docnum.slice! "Invoice:"
        #puts "Document number is #{docnum}"
        #docnum = docnum.split(" ").first
        #puts "Document number is #{docnum}"
        
        docnum = @transaction.memo.split(" ").first.split(":").last.to_i
        @transaction.docnum = docnum if docnum.is_a?(Numeric)
        # Should probably check that docnum is a plausible document number
        
      when "PAYMENT"
        # Payment number is in @transaction.memo, but the format varies depending upon payment method
        # "Payment:ID - METHOD: note - JE:ID"
        
        @paymentmethod = @transaction.memo.split(" - ")
        @paymentmethod = @paymentmethod[1]
        @transaction.paymeth = "Credit" if @paymentmethod.start_with?('Stripe')
        @transaction.paymeth = "Check" if @paymentmethod.start_with?('CH', 'Che')
        @transaction.paymeth = "Debit" if @paymentmethod.start_with?('INTERAC')
        @transaction.paymeth = "PayPal" if @paymentmethod.start_with?('Recurring', 'Pay')
        @transaction.paymeth = "Cash" if @paymentmethod.start_with?('Cash')
        
        case @transaction.paymeth
        when "Credit"
          docnum = @transaction.memo.split(":")
          docnum = docnum[3].split(" ").first
          @transaction.docnum = docnum
          
        when "Check"
          docnum = @transaction.memo.split(" - ")
          docnum = docnum[1].split("#").last
          @transaction.docnum = docnum
        
        end # case @transaction.paymeth
        
      when "CREDIT MEMO"
        
      end # case @transaction.trnstype
     
     end # @transaction.trnstype == "JE"
     puts ""
     puts "     Transformed transaction is:"
     puts "     #{@transaction.inspect}"
     puts ""
     
   when "SPL"
     iam = "SPL detail"
     # We're in a splitline
     
     currentspl = line.split("\t")
     
     puts "    SPL ##{splnum.value}"
     puts "%5d: %s" % [@splaccntid, currentspl[@splaccntid.to_i]] if @splaccntid 
     puts "%5d: %s" % [@splamountid, currentspl[@splamountid.to_i]] if @splamountid
     puts "%5d: %s" % [@splmemoid, currentspl[@splmemoid.to_i]] if @splmemoid
     
     @splitline = Splitline.new
     @splitline.splid = nil
     @splitline.accnt = currentspl[@splaccntid.to_i] if @splaccntid 
     @splitline.amount = currentspl[@splamountid.to_i] if @splamountid
     
     puts "     #{@splitline.inspect}"
     
     @transaction.spl << @splitline

     # increment SPL counter
     splnum.inc

   when "ENDTRNS"
     iam = "EOT"
     # we're at the end of a transaction block
     
     # increment TRNS counter & reset SPL counter
     trnsnum.inc
     splnum.reset
     
   end # case linetype
   
   #puts "I am a #{iam} line."
   
end #ARGF.each



puts ""

puts "Found #{Transaction.count} transactions."

puts ""

grouped = Transaction.all.group_by(&:docnum)
grouped.each do |group|

  if group[0] && group[1].count > 1
    @error << "There are #{group[1].count} #{group[1][0].trnstype} transactions with docnum #{group[0]}. The first one looks like this:\n"
    @error << "#{group[1][0].original}\n\n"
  end
end


if @error.length > 0
  abort("Unable to generate IIF file. Please manually resolve the following issues:\n#{@error}")
end

Transaction.all.each do |transaction|
  puts "This transaction is type #{transaction.trnstype}."
  puts "This transaction has #{transaction.spl.count} splitlines."
  puts "The second splitline looks like this: #{transaction.spl[1].inspect}"
  puts ""
end
fb2qb
=====

*Script is a WIP, and does not yet output an IIF file.*

Convert Freshbooks exported journal entries into proper Quickbooks INVOICE, PAYMENT, and CREDIT MEMO transactions.

Freshbooks generates an IIF file, for importing transactions into Quickbooks -- yay!

However, the export is just a list of journal entries, which, when imported as-is, introduce some accounting annoyances. While accounts balance, QB is unaware of what's what, and is unable to generate useful reports, including Tax Agency filings. As well, the accounts which FB uses don't match the accounts we use. 

Usage
-----

./fb2qb.rb file-1.iif file-2.iif

Currently, the script just assumes that any arguments passed are valid IIF files; zero testing is in place. 

Some notes on IIF syntax
------------------------

FB exports include ACCNT, CUST, and TRNS entries. 


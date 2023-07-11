# Disassembler
**Disassembler (also called an Inverse Assembler):**
	
	  – Scans a section of memory, and
	  
	  – Attempts to convert the memory’s contents to a listing of valid
	  assembly language instructions
  
  • Most disassemblers cannot recreate symbolic, or label information
  
  • Disassemblers can be easily fooled by not starting on an instruction
  boundary

**• How it works:**
	
	  – The disassembler program parses the op-code word of the
	  instruction and then decides how many additional words of
	  memory need to be read in order to complete the instruction
	  
	  – If necessary, reads additional instruction words
	  
	  – The disassembler program prints out the complete instruction
	  in ASCII-readable format
  
  • Converts binary information to readable Hex

 This Project consisted of a group of 4 computer science students, with each student having an equal role in each part of the project. For example, one person was responsible for testing, one member was in charge of decoding the required opcodes, another was incharge of debugging, and the last member was incharge of the String library. The disassembler essentially takes in Machine code and converts it to valid 68k Assembly code. 

 The Opcodes which were included included in the project: 
	NOP
	MOVE, MOVEQ, MOVEA
	ADD, ADDA, ADDQ
	SUB
	LEA
	AND, OR, NOT
	LSL, LSR, ASL, ASR
	ROL, ROR
	Bcc (BGT, BLE, BEQ)
	JSR, RTS
	BRA
 
 The Effective Addressing Modes included in the project: 
	Data Register Direct - Dn
	Address Register Direct - An
	Address Register Indirect - (An)
	Immediate Data - #<data> 
	Address Register Indirect with Post Increment - (An)+
	Address Register Indirect with Pre Decrementing -  -(An)
	Absolute Long Address - (xxx).L
	Absolute Word Address - (xxx).W


*-----------------------------------------------------------
* Title      : OPTCODES
* Written by :
* Date       :
* Description:
*-----------------------------------------------------------
    ORG    $1000
START:                  ; first instruction of program

* Put program code here

  
*Used registers:
*A4,A5,A6 = (counter, last opcode, curr opcode)
*$0 in memory is where the string inputs are temporarily stored
*-------------------------------------------*
*------------------MAIN---------------------*
*-------------------------------------------*

               LEA      WELCOME,A1
               MOVE.B   #13,D0
               TRAP     #15 

*---------Read and store --------------
GETADDR1        LEA     ENTADDR1,A1
                MOVE.B  #14,D0
                TRAP    #15
                LEA     $0,A1
                MOVE.B  #2, D0
                TRAP    #15
                MOVEA.L  A1,A6
                
                MOVE.L   #0,D4 *wipe saved numbers here
                MOVE.L   #0,D3
                
                CMP.B   #0,D1
                BEQ     INPUTERROR *address is zero chars long
                CMP.B   #8,D1
                BGT     INPUTERROR *address is too large

*ASCII TO HEX CONVERTER TM                            
ASCIILOOP1      ASL.L   #4,D4 *shift by one hex value (not byte)
                NOP
                ADD.B   D3,D4 *add previous hex value to result
                NOP
                MOVE.B  (A1),D3 *get next ascii value
                NOP
                ADDA.L   #1,A1 *get next byte
                CMP.B   #0,D1 *check if at end of string
                BEQ     GETADDR2 *if so, conversion is complete
                SUB.B   #1,D1 *subtract size
                
                *check its hexadecimal equvialent
                CMP.B   #$30,D3 *0 in ascii
                BLT     INPUTERROR *invalid character
                CMP.B   #$3A,D3 *: in ascii
                BLT     ASCIINUM1 *byte is 0-9
                CMP.B   #$41,D3 *A in ascii
                BLT     INPUTERROR *invalid character
                CMP.B   #$47,D3 *G in ascii
                BLT     ASCIICHAR1 *byte is A-F
                BRA     INPUTERROR *invalid character

ASCIINUM1       SUB.B   #$30,D3
                BRA     ASCIILOOP1

ASCIICHAR1      SUB.B   #$37,D3
                BRA     ASCIILOOP1
                
MAKEADDR1EVEN   ADDA.L   #1,A6
                NOP
                MOVE.L  A6,D4
                NOP                

GETADDR2        MOVEA.L  D4,A6 *save lower bound; get ready for second
                MOVE.B  #1,D3 *check if address is odd
                AND.B   D3,D4
                CMP.B   #1,D4
                BEQ     MAKEADDR1EVEN
                NOP
                MOVE.L  #0,D4 *wipe saved numbers here
                MOVE.L  #0,D3             
             
*---------Read and store --------------
                LEA     ENTADDR2,A1
                MOVE.B  #14,D0
                TRAP    #15
                LEA     $0,A1
                MOVE.B  #2, D0
                TRAP    #15
                MOVEA.L  A1,A5

                CMP.B   #0,D1
                BEQ     INPUTERROR *address is zero chars long    
                CMP.B   #8,D1
                BGT     INPUTERROR *address is too large            

*ASCII TO HEX CONVERTER TM  
ASCIILOOP2      ASL.L   #4,D4 *shift by one hex value (not byte)
                NOP
                ADD.B   D3,D4 *add previous hex value to result
                NOP
                MOVE.B  (A1),D3 *get next ascii value
                NOP
                ADDA.L   #1,A1 *get next byte
                CMP.B   #0,D1 *check if at end of string
                BEQ     FINISHADDR2 *if so, conversion is complete
                SUB.B   #1,D1 *subtract size
                
                *check its hexadecimal equvialent
                CMP.B   #$30,D3 *0 in ascii
                BLT     INPUTERROR *invalid character
                CMP.B   #$3A,D3 *: in ascii
                BLT     ASCIINUM2 *byte is 0-9
                CMP.B   #$41,D3 *A in ascii
                BLT     INPUTERROR *invalid character
                CMP.B   #$47,D3 *G in ascii
                BLT     ASCIICHAR2 *byte is A-F
                BRA     INPUTERROR *invalid character                

ASCIINUM2       SUB.B   #$30,D3
                BRA     ASCIILOOP2

ASCIICHAR2      SUB.B   #$37,D3
                BRA     ASCIILOOP2    

FINISHADDR2     MOVEA.L  D4,A5

                *error checking
                CMPA.L   A6,A5
                BLT     INPUTERROR *Destination < source
                CMPA.L   $01000000,A5
                BGT     INPUTERROR *exceeds memory limit
                CMPA.L   $01000000,A6
                BGT     INPUTERROR *exceeds memory limit
                
                BSR     FLUSH
                MOVE.L  #0,D4 
                MOVEA.W  #31,A4          

*-------------------------------------------*
*--------------OP CODES---------------------*
*-------------------------------------------*

CONTINUE        CMPA.W   #0,A4
                BEQ     NEXTPAGE
                CMPA.L   A6,A5
                BLT     RESTART
                
                
                


                
                *print current address
                LEA     DOLLAR,A1
                BSR     PRINTSTR
                MOVE.L  #$F0000000,D3 *masking for zeroes
                BSR     PRINTZEROES
                MOVE.L  A6,D1
                MOVE.B  #16,D2
                MOVE.B  #15,D0
                TRAP    #15
                LEA     TB,A1
                BSR     PRINTSTR            
                
                SUBA.W   #1,A4
                *ADD.L   #4,A6 *adds to address pointer. If you're already handling it just delete it
                
*-------------------------------------------*
*------------INSERT CODE HERE---------------*
*-------------------------------------------*                
  *wipe previous opcodes and operands
  CLR.L D3
  CLR.L D4
  CLR.L D5
  CLR.L D6
  CLR.L D7
   
  
  *This code here is to check if the current word is immediate data because the previous word was data
  * to prevent the program from misinterpreting it as MOVE
  
    MOVE.W (A6), D4  *Get opcode from memory to D4

    AND.W  #$F000, D4       *Mask Opcode

    CMP.W   #$0000, D4      *Compare Opcode with 0

    BEQ     DATA_B     *If Equal, then the word is data

  
*MOVEQ
* we will mask the instruction, and if
* the result matches a pattern for MOVE, we have a valid optcode :D
* if not we will have to check the rest of the optcodes
 LEA MOVEQ_V, A0 * the mask     Note: there is no GENERAL code for MOVEQ because there is no invalid addressing modes
 
  MOVE.W (A6), D2
 LEA MOVEQ_D , A2 * mask to isolate the first operand
 LEA MOVEQ_R , A3 * mask to isolate the second operand
 
 MOVE.B #16, D1                 * we need to shift the mask so it works with longs
  MOVE.L A0, D5
  LSL.L D1, D5
  MOVEA.L D5, A0
   *perform the masking
 MOVE.L A0, D3
 MOVE.L D2, D4
 NOP
 LSL.L D1,D4
 NOP
 AND.L D3, D4

 LEA MOVEQ_V, A1 * MOVE BYTE from Dn to DN
 MOVE.L A1, D5
 MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4 
 BEQ MOVEQD_D






*SUB STUFF

*NOTE: SUB is missing Dn to AA and Data to Dn 

CHECK_SUBs    LEA   GENERAL_SUB_MASK, A2   *Get General Mask
   CLR.L D4
  CLR.L D5

    MOVE.W A2, D3       *Move mask to D3

    MOVE.W (A6), D4  *Get opcode from memory to D4

    AND.W  D3, D4       *Mask Opcode

    LEA    GENERAL_SUB, A2    *Get General MOVE Opcode

    MOVE.W  A2, D5      *Move GENERAL MOVE Opcode to D5

    CMP.W   D5, D4      *Compare Opcode with GENERAL MOVE

    BNE     CHECK_MOVEAs     *If not Equal, Proceed to next instruction (MOVEA)

   

*Absolute addressing and immediate data 
    LEA   SUBAAMASK, A2   *Get AA Mask

    MOVE.W A2, D3       *Move mask to D3

    MOVE.W (A6), D4  *Get opcode from memory to D4

    AND.W  D3, D4       *Mask Opcode
    
    LEA SUBBWD, A1 *ADD  byte xxx.w to Dn
 MOVE.L A1, D5
 MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ SUBWWD_D
 
 LEA SUBWWD, A1 *ADD  word xxx.w to Dn
 MOVE.L A1, D5
 MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ SUBWWD_D
 
 LEA SUBLWD, A1 *ADD  Long xxx.w to Dn
 MOVE.L A1, D5
 MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ SUBLWD_D
 
 LEA SUBBLD, A1 *ADD  byte xxx.L to Dn
 MOVE.L A1, D5
  MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ SUBWWD_D
 
 LEA SUBWLD, A1 *ADD  word xxx.L to Dn
 MOVE.L A1, D5
  MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ SUBLLD_D
 
 LEA SUBLLD, A1 *ADD  Long xxx.L to Dn
 MOVE.L A1, D5
  MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ SUBLLD_D



*Rest of the addressing modes
 LEA SUBMASK, A0 * the mask
 
 
  MOVE.W (A6), D2
 LEA MVALUEMASK1 , A2 * mask to isolate the first operand
 LEA MVALUEMASK2 , A3 * mask to isolate the second operand
 
 MOVE.B #16, D1                 * we need to shift the mask so it works with longs
  MOVE.L A0, D5
  LSL.L D1, D5
  MOVEA.L D5, A0
   *perform the masking
 MOVE.L A0, D3
 MOVE.L D2, D4
 NOP
 LSL.L D1,D4
 NOP
 AND.L D3, D4



 
   LEA SUBBDD, A1 *ADD  byte Dn to Dn
 MOVE.L A1, D5
  MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ SUBBDD_D
 
    LEA SUBWDD, A1 *ADD  word Dn to Dn
 MOVE.L A1, D5
  MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ SUBWDD_D
 
  LEA SUBLDD, A1 *ADD  Long Dn to Dn
 MOVE.L A1, D5
  MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ SUBLDD_D


 
 LEA SUBWAD, A1 *ADD  word An to Dn
 MOVE.L A1, D5
  MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ SUBWAD_D
 
  LEA SUBLAD, A1 *ADD  Long An to Dn
 MOVE.L A1, D5
  MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ SUBLAD_D
 

 
    LEA SUBWDA, A1 *ADD  word Dn to A t
 MOVE.L A1, D5
  MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ SUBWDA_D
 
  LEA SUBLDA, A1 *ADD  Long  Dn to A
 MOVE.L A1, D5
  MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ SUBLDA_D

    LEA SUBBAD, A1 *ADD  byte (An) to Dn
 MOVE.L A1, D5
  MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ SUBBAD_D
 
    LEA SUBWAD, A1 *ADD  word (An) to Dn
 MOVE.L A1, D5
  MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ SUBWAD_D
 
  LEA SUBLAD, A1 *ADD  Long (An) to Dn
 MOVE.L A1, D5
  MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ SUBLAD_D



    LEA SUBBDAI, A1 *ADD  byte  Dn to (An)
 MOVE.L A1, D5
  MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ SUBBDAI_D
 
    LEA SUBWDAI, A1 *ADD  word Dn to (An)
 MOVE.L A1, D5
  MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ SUBWDAI_D
 
  LEA SUBLDAI, A1 *ADD  Long  Dn to (An)
 MOVE.L A1, D5
  MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ SUBLDAI_D
 
 LEA SUBBAPD, A1 *ADD  byte (An)+ to Dn
 MOVE.L A1, D5
 MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ SUBBAPD_D
 
 LEA SUBWAPD, A1 *ADD  word (An)+ to Dn
 MOVE.L A1, D5
 MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ SUBWAPD_D
 
 LEA SUBLAPD, A1 *ADD  Long (An)+ to Dn
 MOVE.L A1, D5
 MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ SUBLAPD_D

 LEA SUBBADD, A1 *ADD  byte -(An) to Dn
 MOVE.L A1, D5
 MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ SUBBADD_D
 
 LEA SUBWADD, A1 *ADD  word -(An) to Dn
 MOVE.L A1, D5
 MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ SUBWADD_D
 
 LEA SUBLADD, A1 *ADD  Long -(An) to Dn
 MOVE.L A1, D5
 MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ SUBLADD_D
 



 LEA SUBBDAP, A1 *ADD  byte (An)+ to Dn
 MOVE.L A1, D5
 MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ SUBBDAP_D
 
 LEA SUBWDAP, A1 *ADD  word (An)+ to Dn
 MOVE.L A1, D5
 MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ SUBWDAP_D
 
 LEA SUBLDAP, A1 *ADD  Long (An)+ to Dn
 MOVE.L A1, D5
 MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ SUBLDAP_D

 LEA SUBBDAD, A1 *ADD  byte -(An) to Dn
 MOVE.L A1, D5
 MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ SUBBDAD_D
 
 LEA SUBWDAD, A1 *ADD  word -(An) to Dn
 MOVE.L A1, D5
 MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ SUBWDAD_D
 
 LEA SUBLDAD, A1 *ADD  Long -(An) to Dn
 MOVE.L A1, D5
 MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ SUBLDAD_D
 
    
  ADDQ.W    #2, A6      *Go to next instruction
  BRA IFINVADDRMODE  *The opcode is SUB, but the addressing modes are incorrect
 *



 * MOVEA
* we will mask the instruction, and if
* the result matches a pattern for MOVEA, we have a valid optcode :D
* if not we will have to check the rest of the optcodes
CHECK_MOVEAs    LEA   GENERAL_MOVEA_MASK, A2   *Get General Mask
  CLR.L D4
  CLR.L D5

    MOVE.W A2, D3       *Move mask to D3

    MOVE.W (A6), D4  *Get opcode from memory to D4

    AND.W  D3, D4       *Mask Opcode

    LEA    GENERAL_MOVEA, A2    *Get General MOVEA Opcode

    MOVE.W  A2, D5      *Move GENERAL MOVEA Opcode to D5

    CMP.W   D5, D4      *Compare Opcode with GENERAL MOVEA

    BNE     CHECK_MOVEs     *If not Equal, Proceed to next instruction (MOVE)
    
    
* Else, check MOVEA varaints
 

*Absolute addressing and immediate data 
    LEA   MOVEAAAMASK, A2   *Get AA Mask

    MOVE.W A2, D3       *Move mask to D3

    MOVE.W (A6), D4  *Get opcode from memory to D4

    AND.W  D3, D4       *Mask Opcode
    
    LSL.L  D1,D4


    LEA MOVEAWWA, A1 *MOVEA Word  to An
 MOVE.L A1, D5
  MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ MOVEAWWA_D
 
  LEA MOVEALLA, A1 *MOVEA Long  to An
 MOVE.L A1, D5
  MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ MOVEALLA_D
 
     LEA MOVEAWLA, A1 *MOVEA Word  to An
 MOVE.L A1, D5
  MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ MOVEAWLA_D
 
  LEA MOVEALWA, A1 *MOVEA Long  to An
 MOVE.L A1, D5
  MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ MOVEALWA_D

 
 
  LEA MOVEAWIA, A1 *MOVEA Word imm to An
 MOVE.L A1, D5
  MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ MOVEAWIA_D
 
 
 
  LEA MOVEALIA, A1 *MOVEA Long  imm to An
 MOVE.L A1, D5
  MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ MOVEALIA_D

*The rest
   
 *LEA MOVEAMASK, A0 * the mask
 * MOVE.W (A6), D2
 *LEA MVALUEMASK1 , A2 * mask to isolate the first operand
 *LEA MVALUEMASK2 , A3 * mask to isolate the second operand
 
 *MOVE.B #16, D1                 * we need to shift the mask so it works with longs
 * MOVE.L A0, D5
 * LSL.L D1, D5
 * MOVEA.L D5, A0
   *perform the masking
 *MOVE.L A0, D3
 *MOVE.L D2, D4
 *NOP
 *LSL.L D1,D4
 *NOP
 *AND.L D3, D4
 
  LEA MVALUEMASK1 , A2 * mask to isolate the first operand
 LEA MVALUEMASK2 , A3 * mask to isolate the second operand
 LEA MOVEAWD, A1 *MOVEA Word Dn to An
 MOVE.L A1, D5
  MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ MOVEAWD_D
 
  LEA MOVEALD, A1 *MOVEA Long Dn to An
 MOVE.L A1, D5
  MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ MOVEALD_D
 
  LEA MOVEAWA, A1 *MOVEA Word An to An
 MOVE.L A1, D5
  MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ MOVEAWA_D
 
  LEA MOVEALA, A1 *MOVEA Long An to An
 MOVE.L A1, D5
  MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ MOVEALA_D
 
   LEA MOVEAWAI, A1 *MOVEA Word (An) to An
 MOVE.L A1, D5
  MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ MOVEAWAI_D
 
  LEA MOVEALAI, A1 *MOVEA Long (An) to An
 MOVE.L A1, D5
  MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ MOVEALAI_D
 
 
   LEA MOVEAWPA, A1 *MOVEA Word An+ to An
 MOVE.L A1, D5
  MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ MOVEAWPA_D
 
  LEA MOVEALPA, A1 *MOVEA Long An+ to An
 MOVE.L A1, D5
  MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ MOVEALPA_D
 
   LEA MOVEAWDA, A1 *MOVEA Word -An to An
 MOVE.L A1, D5
  MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ MOVEAWDA_D
 
  LEA MOVEALDA, A1 *MOVEA Long -An to An
 MOVE.L A1, D5
  MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ MOVEALDA_D
 
 
 
  ADDQ.W    #2, A6      *Go to next instruction
    BRA IFINVADDRMODE  *The opcode is MOVEA, but the addressing modes are incorrect



* MOVE
* we will mask the instruction, and if
* the result matches a pattern for MOVE, we have a valid optcode :D
* if not we will have to check the rest of the optcodes
CHECK_MOVEs    LEA   GENERAL_MOVE_MASK, A2   *Get General Mask
  CLR.L D4
  CLR.L D5
     MOVE.W A2, D3       *Move mask to D3

    MOVE.W (A6), D4  *Get opcode from memory to D4

    AND.W  D3, D4       *Mask Opcode

    LEA    GENERAL_MOVE, A2    *Get General MOVE Opcode

    MOVE.W  A2, D5      *Move GENERAL MOVE Opcode to D5

    CMP.W   D5, D4      *Compare Opcode with GENERAL MOVE

    BNE     CHECK_ADDs     *If not Equal, Proceed to next instruction (ADD)
    
    
* Else, check MOVE varaints

 LEA MMASKAA_AA, A0 * the mask
 
 
  MOVE.W (A6), D2
 LEA MVALUEMASK1 , A2 * mask to isolate the first operand
 LEA MVALUEMASK2 , A3 * mask to isolate the second operand
 
 MOVE.B #16, D1                 * we need to shift the mask so it works with longs
  MOVE.L A0, D5
  LSL.L D1, D5
  MOVEA.L D5, A0
   *perform the masking
 MOVE.L A0, D3
 MOVE.L D2, D4
 NOP
 LSL.L D1,D4
 NOP
 AND.L D3, D4

* start comparing all possible MOVE AAxAAvariants* 
 LEA MOVEBW, A1 *MOVE byte xxx.W xxx.W
 MOVE.L A1, D5
 MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ MOVEBW_D

    LEA MOVEWW, A1 *MOVE word xxx.W  xxx.W
 MOVE.L A1, D5
  MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ MOVEWW_D 
 
   LEA MOVELW, A1 *MOVE long xxx.W xxx.W
 MOVE.L A1, D5
  MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ MOVELW_D 
 
     LEA MOVEBLW, A1 *MOVE byte xxx.L xxx.W
 MOVE.L A1, D5
  MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ MOVEBLW_D

    LEA MOVEWLW, A1 *MOVE word xxx.L  xxx.W
 MOVE.L A1, D5
  MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ MOVEWLW_D 
 
   LEA MOVELLW, A1 *MOVE long xxx.L xxx.W
 MOVE.L A1, D5
  MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ MOVELLW_D 
 
 
  LEA MOVEBIW, A1 *MOVE byte imm xxx.W
 MOVE.L A1, D5
  MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ MOVEBIW_D

    LEA MOVEWIW, A1 *MOVE word imm  xxx.W
 MOVE.L A1, D5
  MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ MOVEWIW_D 
 
   LEA MOVELIW, A1 *MOVE long imm xxx.W
 MOVE.L A1, D5
  MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ MOVELIW_D 
 
 
    LEA MOVEBWL, A1 *MOVE Byte xxx.w to xxx.L
 MOVE.L A1, D5
  MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ MOVEBWL_D 
 
     LEA MOVEWWL, A1 *MOVE word xxx.w to xxx.L
 MOVE.L A1, D5
  MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ MOVEWWL_D 
 
    LEA MOVELWL, A1 *MOVE long xxx.w to xxx.L
 MOVE.L A1, D5
  MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ MOVELWL_D

    LEA MOVEBLL, A1 *MOVE Byte xxx.L to xxx.L
 MOVE.L A1, D5
  MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ MOVEBLL_D 
 
     LEA MOVEWLL, A1 *MOVE word xxx.L to xxx.L
 MOVE.L A1, D5
  MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ MOVEWLL_D 
 
    LEA MOVELLL, A1 *MOVE long xxx.L to xxx.L
 MOVE.L A1, D5
  MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ MOVELLL_D
 
     LEA MOVEBIL, A1 *MOVE Byte imm to xxx.L
 MOVE.L A1, D5
  MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ MOVEBIL_D 
 
     LEA MOVEWIL, A1 *MOVE word imm to xxx.L
 MOVE.L A1, D5
  MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ MOVEWIL_D 
 
    LEA MOVELIL, A1 *MOVE long imm to xxx.L
 MOVE.L A1, D5
  MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ MOVELIL_D
 
  
 LEA MMASKAA_DN, A0 * the mask
 
 
  MOVE.W (A6), D2
 LEA MVALUEMASK1 , A2 * mask to isolate the first operand
 LEA MVALUEMASK2 , A3 * mask to isolate the second operand
 
 MOVE.B #16, D1                 * we need to shift the mask so it works with longs
  MOVE.L A0, D5
  LSL.L D1, D5
  MOVEA.L D5, A0
   *perform the masking
 MOVE.L A0, D3
 MOVE.L D2, D4
 NOP
 LSL.L D1,D4
 NOP
 AND.L D3, D4

* start comparing all possible MOVE AAxAAvariants* 

  LEA MOVEBWRDD, A1 *MOVE BYTE (XXX).W to DN
 MOVE.L A1, D5
  MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ MOVEBWRDD_D
 
   LEA MOVEWWRDD, A1 *MOVE WORD (XXX).W to DN
 MOVE.L A1, D5
  MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ MOVEWWRDD_D
 
   LEA MOVELWRDD, A1 *MOVE LONG (XXX).W to DN
 MOVE.L A1, D5
  MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ MOVELWRDD_D
 
  LEA MOVEBLNGD, A1 *MOVE BYTE  (XXX).L to DN
 MOVE.L A1, D5
  MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ MOVEBLNGD_D
 
   LEA MOVEWLNGD, A1 *MOVE WORD  (XXX).L to DN
 MOVE.L A1, D5
  MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ MOVEWLNGD_D
 
 
  LEA MOVELLNGD, A1 *MOVE LONG  (XXX).L to DN
 MOVE.L A1, D5
  MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ MOVELLNGD_D
 
 LEA MOVEBIMD, A1 *MOVE byte immidate  to DN
 MOVE.L A1, D5
  MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ MOVEBIMD_D
 
  LEA MOVEWIMD, A1 *MOVE word immidate  to DN
 MOVE.L A1, D5
  MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ MOVEWIMD_D
 
  LEA MOVELIMD, A1 *MOVE long immidate  to DN
 MOVE.L A1, D5
  MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ MOVELIMD_D
 
 
 LEA MOVEBWAI, A1 *MOVE byte  (XXX).W to (AN)
 MOVE.L A1, D5
  MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ MOVEBWAI_D
 
   LEA MOVEWWAI, A1 *MOVE word  (XXX).W to (AN)
 MOVE.L A1, D5
  MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ MOVEWWAI_D

 LEA MOVELWAI, A1 *MOVE long  (XXX).W to (AN)
 MOVE.L A1, D5
  MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ MOVELWAI_D
 
 
  LEA MOVEBLAI, A1 *MOVE byte  (XXX).L to (AN)
 MOVE.L A1, D5
  MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ MOVEBLAI_D
 
   LEA MOVEWWAI, A1 *MOVE word  (XXX).L to (AN)
 MOVE.L A1, D5
  MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ MOVEWLAI_D

 LEA MOVELLAI, A1 *MOVE long  (XXX).L to (AN)
 MOVE.L A1, D5
  MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ MOVELLAI_D

 LEA MOVEBIAI, A1 *MOVE byte  immidiate to (AN)
 MOVE.L A1, D5
  MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ MOVEBIAI_D
 
   LEA MOVEWIAI, A1 *MOVE word  immidiate  to (AN)
 MOVE.L A1, D5
  MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ MOVEWIAI_D

 LEA MOVELWAI, A1 *MOVE long  immidiate to (AN)
 MOVE.L A1, D5
  MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ MOVELIAI_D

  LEA MOVEBWAP, A1 *MOVE byte  xxx.w to (AN)+
 MOVE.L A1, D5
  MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ MOVEBWAP_D



  LEA MOVEWWAP, A1 *MOVE word  xxx.w to (AN)+
 MOVE.L A1, D5
  MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ MOVEWWAP_D
 
  LEA MOVELWAP, A1 *MOVE long  xxx.w to (AN)+
 MOVE.L A1, D5
  MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ MOVELWAP_D
 
   LEA MOVEBLAP, A1 *MOVE byte  xxx.l to (AN)+
 MOVE.L A1, D5
  MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ MOVEBLAP_D

  LEA MOVEWWAP, A1 *MOVE word  xxx.L to (AN)+
 MOVE.L A1, D5
  MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ MOVEWLAP_D
 
  LEA MOVELLAP, A1 *MOVE long  xxx.L to (AN)+
 MOVE.L A1, D5
  MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ MOVELLAP_D
 
 LEA MOVEBIAP, A1 *MOVE byte  immidiate to (AN)+
 MOVE.L A1, D5
  MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ MOVEBIAP_D
 
  LEA MOVEBIAP, A1 *MOVE word  immidiate to (AN)+
 MOVE.L A1, D5
  MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ MOVEWIAP_D

 LEA MOVEWIAP, A1 *MOVE long  immidiate to (AN)+
 MOVE.L A1, D5
  MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ MOVELIAP_D


  LEA MOVEBWAD, A1 *MOVE byte  XXX.w to -(AN)
 MOVE.L A1, D5
  MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ MOVEWWAD_D

 LEA MOVEWWAD, A1 *MOVE word  XXX.w to -(AN)
 MOVE.L A1, D5
  MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ MOVEWWAD_D

 LEA MOVELWAD, A1 *MOVE long  XXX.w to -(AN)
 MOVE.L A1, D5
  MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ MOVELWAD_D
 
 
  LEA MOVEBLAD, A1 *MOVE byte  XXX.L to -(AN)
 MOVE.L A1, D5
  MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ MOVEBLAD_D
 
 
  LEA MOVEWLAD, A1 *MOVE word  XXX.L to -(AN)
 MOVE.L A1, D5
  MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ MOVEWLAD_D
 
   LEA MOVELLAD, A1 *MOVE word  XXX.L to -(AN)
 MOVE.L A1, D5
  MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ MOVELLAD_D
 
 
  LEA MOVEBIAD, A1 *MOVE byte  immidiate to -(AN)
 MOVE.L A1, D5
  MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ MOVEBIAD_D
 
   LEA MOVEWIAD, A1 *MOVE word  immidiate to -(AN)
 MOVE.L A1, D5
  MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ MOVEWIAD_D
 
   LEA MOVELIAD, A1 *MOVE long  immidiate to -(AN)
 MOVE.L A1, D5
  MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ MOVELIAD_D 
 




 LEA MMASKDN_AA, A0 * the mask
 
 
  MOVE.W (A6), D2
 LEA MVALUEMASK1 , A2 * mask to isolate the first operand
 LEA MVALUEMASK2 , A3 * mask to isolate the second operand
 
 MOVE.B #16, D1                 * we need to shift the mask so it works with longs
  MOVE.L A0, D5
  LSL.L D1, D5
  MOVEA.L D5, A0
   *perform the masking
 MOVE.L A0, D3
 MOVE.L D2, D4
 NOP
 LSL.L D1,D4
 NOP
 AND.L D3, D4

* start comparing all possible MOVE variants* 

 LEA MOVEBDWRD, A1 *MOVE byte Dn xxx.W
 MOVE.L A1, D5
  MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ MOVEBDWRD_D

    LEA MOVEWDWRD, A1 *MOVE word Dn xxx.W
 MOVE.L A1, D5
  MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
  
 BEQ MOVEWDWRD_D 
 
   LEA MOVELDWRD, A1 *MOVE long Dn xxx.W
 MOVE.L A1, D5
  MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ MOVELDWRD_D 
 
     LEA MOVEBAW, A1 *MOVE byte An xxx.W
 MOVE.L A1, D5
  MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ MOVEBAW_D

    LEA MOVEWAW, A1 *MOVE word An xxx.W
 MOVE.L A1, D5
  MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ MOVEWAW_D 
 
   LEA MOVELAW, A1 *MOVE long An xxx.W
 MOVE.L A1, D5
  MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ MOVELAW_D 
 
   LEA MOVEBAIW, A1 *MOVE byte (An) xxx.W
 MOVE.L A1, D5
  MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ MOVEBAIW_D

    LEA MOVEWAIW, A1 *MOVE word (An) xxx.W
 MOVE.L A1, D5
  MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ MOVEWAIW_D 
 
   LEA MOVELAIW, A1 *MOVE long (An) xxx.W
 MOVE.L A1, D5
  MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ MOVELAIW_D 
 
 
   LEA MOVEBAPW, A1 *MOVE byte (An)+ xxx.W
 MOVE.L A1, D5
  MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ MOVEBAPW_D

    LEA MOVEWAPW, A1 *MOVE word (An)+ xxx.W
 MOVE.L A1, D5
  MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ MOVEWAPW_D 
 
   LEA MOVELAPW, A1 *MOVE long (An)+ xxx.W
 MOVE.L A1, D5
  MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ MOVELAPW_D 
 
 
   LEA MOVEBADW, A1 *MOVE byte -(An) xxx.W
 MOVE.L A1, D5
  MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ MOVEBADW_D

    LEA MOVEWADW, A1 *MOVE word -(An) xxx.W
 MOVE.L A1, D5
  MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ MOVEWADW_D 
 
   LEA MOVELADW, A1 *MOVE long -(An) xxx.W
 MOVE.L A1, D5
  MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ MOVELADW_D 
 
   LEA MOVEBDLNG, A1 *MOVE Byte Dn to xxx.L
 MOVE.L A1, D5
  MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ MOVEBDLNG_D 
 
     LEA MOVEWDLNG, A1 *MOVE word Dn to xxx.L
 MOVE.L A1, D5
  MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ MOVEWDLNG_D 
 
    LEA MOVELDLNG, A1 *MOVE long Dn to xxx.L
 MOVE.L A1, D5
  MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ MOVELDLNG_D 
 
 
   LEA MOVEBAL, A1 *MOVE Byte An to xxx.L
 MOVE.L A1, D5
  MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ MOVEBAL_D 
 
     LEA MOVEWAL, A1 *MOVE word An to xxx.L
 MOVE.L A1, D5
  MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ MOVEWAL_D 
 
    LEA MOVELAL, A1 *MOVE long An to xxx.L
 MOVE.L A1, D5
  MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ MOVELAL_D 
 
    LEA MOVEBAIL, A1 *MOVE Byte (An) to xxx.L
 MOVE.L A1, D5
  MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ MOVEBAIL_D 
 
     LEA MOVEWAIL, A1 *MOVE word (An) to xxx.L
 MOVE.L A1, D5
  MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ MOVEWAIL_D 
 
    LEA MOVELAIL, A1 *MOVE long (An) to xxx.L
 MOVE.L A1, D5
  MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ MOVELAIL_D 



    LEA MOVEBAPL, A1 *MOVE Byte (An)+ to xxx.L
 MOVE.L A1, D5
  MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ MOVEBAPL_D 
 
     LEA MOVEWAPL, A1 *MOVE word (An)+ to xxx.L
 MOVE.L A1, D5
  MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ MOVEWAPL_D 
 
    LEA MOVELAPL, A1 *MOVE long (An)+ to xxx.L
 MOVE.L A1, D5
  MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ MOVELAPL_D 

    LEA MOVEBADL, A1 *MOVE Byte -(An) to xxx.L
 MOVE.L A1, D5
  MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ MOVEBADL_D 
 
     LEA MOVEWADL, A1 *MOVE word -(An) to xxx.L
 MOVE.L A1, D5
  MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ MOVEWADL_D 
 
    LEA MOVELADL, A1 *MOVE long -(An) to xxx.L
 MOVE.L A1, D5
  MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ MOVELADL_D 






 LEA MMASK, A0 * the mask
 
 
  MOVE.W (A6), D2
 LEA MVALUEMASK1 , A2 * mask to isolate the first operand
 LEA MVALUEMASK2 , A3 * mask to isolate the second operand
 
 MOVE.B #16, D1                 * we need to shift the mask so it works with longs
  MOVE.L A0, D5
  LSL.L D1, D5
  MOVEA.L D5, A0
   *perform the masking
 MOVE.L A0, D3
 MOVE.L D2, D4
 NOP
 LSL.L D1,D4
 NOP
 AND.L D3, D4

* start comparing all possible MOVE variants* 

 LEA MOVEBDD, A1 * MOVE BYTE from Dn to DN
 MOVE.L A1, D5
 MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4 
 BEQ MOVEBDD_D

 *LEA MOVEBAD, A1 * MOVE BYTE from AN to DN
 *MOVE.L A1, D5
 *CMP.L D5, A1
 *BEQ MOVEBAD_D

 LEA MOVEWAD, A1 * MOVE WORD from AN to DN
 MOVE.L A1, D5
 MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ MOVEWAD_D
 
  LEA MOVELAD, A1 * MOVE LONG from AN to DN
 MOVE.L A1, D5
 MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ MOVELAD_D


 LEA MOVEWDD, A1 * MOVE WORD from DN to DN
 MOVE.L A1, D5
  MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ MOVEWDD_D


 LEA MOVELDD, A1 *MOVE LONG from DN to DN
 MOVE.L A1, D5
 MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4 
 BEQ MOVELDD_D


 LEA MOVEBDAI, A1 *MOVE BYTE from DN to (AN)
 MOVE.L A1, D5
 MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ MOVEBDAI_D


 LEA MOVEWDAI, A1 *MOVE WORD from DN to (AN)
 MOVE.L A1, D5
 MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ MOVEWDAI_D


 LEA MOVELDAI, A1 *MOVE LONG from DN to (AN)
 MOVE.L A1, D5
  MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ MOVELDAI_D

 LEA MOVEWAD, A1 *MOVE WORD AN to DN
 MOVE.L A1, D5
  MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ MOVEWAD_D

 LEA MOVELAD, A1 *MOVE LONG AN to DN
 MOVE.L A1, D5
  MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ MOVELAD_D
 
  LEA MOVEBAID, A1 *MOVE BYTE (AN) to DN
 MOVE.L A1, D5
  MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ MOVEBAID_D
 
   LEA MOVEWAID, A1 *MOVE WORD (AN) to DN
 MOVE.L A1, D5
  MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ MOVEWAID_D
 
   LEA MOVELAID, A1 *MOVE LONG (AN) to DN
 MOVE.L A1, D5
  MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ MOVELAID_D
 
  LEA MOVEBAPID, A1 *MOVE BYTE  (AN)+  to DN
 MOVE.L A1, D5
  MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ MOVEBAPID_D
 
 
  LEA MOVEWAPID, A1 *MOVE WORD (AN)+ to DN
 MOVE.L A1, D5
  MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ MOVEWAPID_D
 
 
  LEA MOVELAPID, A1 *MOVE LONG (AN)+ to DN
 MOVE.L A1, D5
  MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ MOVELAPID_D
 
  LEA MOVEBADD, A1 *MOVE BYTE -(AN) to DN
 MOVE.L A1, D5
  MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ MOVEBADD_D
 
   LEA MOVEWADD, A1 *MOVE WORD -(AN) to DN
 MOVE.L A1, D5
  MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ MOVEWADD_D
 
   LEA MOVELADD, A1 *MOVE LONG -(AN) to DN
 MOVE.L A1, D5
  MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ MOVELADD_D
 
  LEA MOVEBDAI, A1 *MOVE byte DN to (AN)
 MOVE.L A1, D5
  MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ MOVEBDAI_D
 
    LEA MOVEWDAI, A1 *MOVE word DN to (AN)
 MOVE.L A1, D5
  MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ MOVEWDAI_D
 
 
    LEA MOVELDAI, A1 *MOVE long DN to (AN)
 MOVE.L A1, D5
  MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ MOVELDAI_D
 
 
  LEA MOVEBAAI, A1 *MOVE byte AN to (AN)
 MOVE.L A1, D5
  MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ MOVEBAAI_D
 
  LEA MOVEWAAI, A1 *MOVE word AN to (AN)
 MOVE.L A1, D5
  MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ MOVEWAAI_D
 
   LEA MOVELAAI, A1 *MOVE long AN to (AN)
 MOVE.L A1, D5
  MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ MOVELAAI_D
 
   LEA MOVEBAI, A1 *MOVE byte  (AN) to (AN)
 MOVE.L A1, D5
  MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ MOVEBAI_D
 
  LEA MOVEWAI, A1 *MOVE word  (AN) to (AN)
 MOVE.L A1, D5
  MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ MOVEWAI_D
 
  LEA MOVELAI, A1 *MOVE long  (AN) to (AN)
 MOVE.L A1, D5
  MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ MOVELAI_D
 
 
  LEA MOVEBAPAI, A1 *MOVE byte  (AN)+ to (AN)
 MOVE.L A1, D5
  MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ MOVEBAPAI_D
   
 LEA MOVEWAPAI, A1 *MOVE word  (AN)+ to (AN)
 MOVE.L A1, D5
  MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ MOVEWAPAI_D

 LEA MOVELAPAI, A1 *MOVE long  (AN)+ to (AN)
 MOVE.L A1, D5
  MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ MOVELAPAI_D
 * MOVE.L #4, D5
 *BSR CALC_ADDR_OFFSET
 
 LEA MOVEBADAI, A1 *MOVE byte  -(AN) to (AN)
 MOVE.L A1, D5
  MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ MOVEBADAI_D
 
   LEA MOVEWADAI, A1 *MOVE word  -(AN) to (AN)
 MOVE.L A1, D5
  MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ MOVEWADAI_D

 LEA MOVELADAI, A1 *MOVE long  -(AN) to (AN)
 MOVE.L A1, D5
  MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ MOVELADAI_D
 
 LEA MOVEBDAP, A1 *MOVE byte  DN to (AN)+
 MOVE.L A1, D5
  MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ MOVEBDAP_D
 
  LEA MOVEWDAP, A1 *MOVE word  DN to (AN)+
 MOVE.L A1, D5
  MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ MOVEWDAP_D
 
   LEA MOVELDAP, A1 *MOVE long  DN to (AN)+
 MOVE.L A1, D5
  MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ MOVELDAP_D

  LEA MOVEBAAP, A1 *MOVE byte  AN to (AN)+
 MOVE.L A1, D5
  MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ MOVEWAAP_D
  
   LEA MOVEWAAP, A1 *MOVE word  AN to (AN)+
 MOVE.L A1, D5
  MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ MOVEWAAP_D

  LEA MOVELAAP, A1 *MOVE long  AN to (AN)+
 MOVE.L A1, D5
  MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ MOVELAAP_D
 
   LEA MOVEBAIAP, A1 *MOVE byte  (AN) to (AN)+
 MOVE.L A1, D5
  MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ MOVEBAIAP_D
 
   LEA MOVEWAIAP, A1 *MOVE word  (AN) to (AN)+
 MOVE.L A1, D5
  MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ MOVEWAIAP_D

  LEA MOVELAIAP, A1 *MOVE long  (AN) to (AN)+
 MOVE.L A1, D5
  MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ MOVELAIAP_D

   LEA MOVEBAPAP, A1 *MOVE byte  (AN)+ to (AN)+
 MOVE.L A1, D5
  MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ MOVEBAPAP_D
 
   LEA MOVEWAPAP, A1 *MOVE word  (AN)+ to (AN)+
 MOVE.L A1, D5
  MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ MOVEWAPAP_D

  LEA MOVELAPAP, A1 *MOVE long  (AN)+ to (AN)+
 MOVE.L A1, D5
  MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ MOVELAPAP_D

   LEA MOVEBADAP, A1 *MOVE byte  -(AN) to (AN)+
 MOVE.L A1, D5
  MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ MOVEBADAP_D
 
   LEA MOVEWADAP, A1 *MOVE word  -(AN) to (AN)+
 MOVE.L A1, D5
  MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ MOVEWADAP_D

  LEA MOVELADAP, A1 *MOVE long  -(AN) to (AN)+
 MOVE.L A1, D5
  MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ MOVELADAP_D


 LEA MOVEBDAD, A1 *MOVE byte  Dn to -(AN)
 MOVE.L A1, D5
  MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ MOVEBDAD_D


 LEA MOVEWDAD, A1 *MOVE word  Dn to -(AN)
 MOVE.L A1, D5
  MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ MOVEWDAD_D

 LEA MOVELDAD, A1 *MOVE long  Dn to -(AN)
 MOVE.L A1, D5
  MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ MOVELDAD_D


 LEA MOVEBAAD, A1 *MOVE byte  An to -(AN)
 MOVE.L A1, D5
  MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ MOVEBAAD_D


 LEA MOVEWAAD, A1 *MOVE word  An to -(AN)
 MOVE.L A1, D5
  MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ MOVEWAAD_D

 LEA MOVELAAD, A1 *MOVE long  An to -(AN)
 MOVE.L A1, D5
  MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ MOVELAAD_D


 LEA MOVEBAIAD, A1 *MOVE byte  (An) to -(AN)
 MOVE.L A1, D5
  MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ MOVEBAIAD_D


 LEA MOVEWAIAD, A1 *MOVE word  (An) to -(AN)
 MOVE.L A1, D5
  MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ MOVEWAIAD_D

 LEA MOVELAIAD, A1 *MOVE long  (An) to -(AN)
 MOVE.L A1, D5
  MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ MOVELAIAD_D
 
  LEA MOVEBAPAD, A1 *MOVE byte  (An)+ to -(AN)
 MOVE.L A1, D5
  MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ MOVEBAPAD_D

  LEA MOVEWAPAD, A1 *MOVE word  (An)+ to -(AN)
 MOVE.L A1, D5
  MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ MOVEWAPAD_D
 
 LEA MOVELAPAD, A1 *MOVE Long  (An)+ to -(AN)
 MOVE.L A1, D5
  MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ MOVELAPAD_D

 LEA MOVEBADAD, A1 *MOVE byte  -(An) to -(AN)
 MOVE.L A1, D5
  MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ MOVEBADAD_D

  LEA MOVEWADAD, A1 *MOVE word  -(An) to -(AN)
 MOVE.L A1, D5
  MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ MOVEWADAD_D
 
 LEA MOVELADAD, A1 *MOVE Long  -(An) to -(AN)
 MOVE.L A1, D5
  MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ MOVELADAD_D
  

 ADDQ.W    #2, A6   *Go to next instruction
 BRA IFINVADDRMODE  *The opcode is MOVE, but the addressing modes are incorrect
 
 *----------------------------------------------------*
 *_________________________________________*
 * ADDA
* we will mask the instruction, and if
* the result matches a pattern for ADD, we have a valid optcode :D
* if not we will have to check the rest of the optcodes
CHECK_ADDAs    LEA   GENERAL_ADDA_MASK, A2   *Get General Mask


    BRA     CHECK_ADDs     *If not Equal, Proceed to next instruction (ADD)
    
 
 
 *_________________________________________*
  
 * ADD
* we will mask the instruction, and if
* the result matches a pattern for ADD, we have a valid optcode :D
* if not we will have to check the rest of the optcodes
CHECK_ADDs    LEA   GENERAL_ADD_ADDA_MASK, A2   *Get General Mask
   
    MOVE.W A2, D3       *Move mask to D3

    MOVE.W (A6), D4  *Get opcode from memory to D4

    AND.W  D3, D4       *Mask Opcode

    LEA    GENERAL_ADD_ADDA, A2    *Get General ADD Opcode

    MOVE.W  A2, D5      *Move GENERAL ADD Opcode to D5

    CMP.W   D5, D4      *Compare Opcode with GENERAL ADD

    BNE     CHECK_ADDQs     *If not Equal, Proceed to next instruction (ADDQ)
    
    
* Else, check ADD varaints




*Absolute addressing and immediate data 
    LEA   ADDAAAMASK, A2   *Get AA Mask
    MOVE.B #16, D1

    MOVE.W A2, D3       *Move mask to D3

    MOVE.W (A6), D4  *Get opcode from memory to D4

    AND.W  D3, D4       *Mask Opcode
    LSL.L D1,D4
  LEA ADDBWD, A1 *ADD  byte xxx.w to Dn
 MOVE.L A1, D5
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ ADDWWD_D
 
 LEA ADDWWD, A1 *ADD  word xxx.w to Dn
 MOVE.L A1, D5
  MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ ADDWWD_D
 
 LEA ADDLWD, A1 *ADD  Long xxx.w to Dn
 MOVE.L A1, D5
  MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ ADDLWD_D
 
 LEA ADDBLD, A1 *ADD  byte xxx.L to Dn
 MOVE.L A1, D5
  MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ ADDWWD_D
 
 LEA ADDWLD, A1 *ADD  word xxx.L to Dn
 MOVE.L A1, D5
  MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ ADDWLD_D
 
 LEA ADDLLD, A1 *ADD  Long xxx.L to Dn
 MOVE.L A1, D5
  MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ ADDLLD_D
    
     LEA ADDAWWA, A1 *ADDA  word xxx.w to An
 MOVE.L A1, D5
  MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ ADDAWWA_D
 
 LEA ADDALWA, A1 *ADDA  Long xxx.w to An
 MOVE.L A1, D5
  MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ ADDALWA_D

    LEA ADDAWLA, A1 *ADDA  word xxx.L to An
 MOVE.L A1, D5
  MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ ADDAWLA_D
 
 LEA ADDALLA, A1 *ADDA  Long xxx.L to An
 MOVE.L A1, D5
  MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ ADDALLA_D

  LEA ADDAWI, A1 *ADDA  word #<Data> to An
 MOVE.L A1, D5
  MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ ADDAWI_D
 
 LEA ADDALI, A1 *ADDA  Long #<Data> to An
 MOVE.L A1, D5
  MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ ADDALI_D

  
 LEA ADDBWD, A1 *ADD  byte xxx.w to Dn
 
 MOVE.L A1, D5
  MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ ADDWWD_D
 
 LEA ADDWWD, A1 *ADD  word xxx.w to Dn
 MOVE.L A1, D5
  MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ ADDWWD_D
 
 LEA ADDLWD, A1 *ADD  Long xxx.w to Dn
 MOVE.L A1, D5
  MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ ADDLWD_D
 
 LEA ADDBLD, A1 *ADD  byte xxx.L to Dn
 MOVE.L A1, D5
  MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ ADDWWD_D
 
 LEA ADDWLD, A1 *ADD  word xxx.L to Dn
 MOVE.L A1, D5
  MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ ADDWLD_D
 
 LEA ADDLLD, A1 *ADD  Long xxx.L to Dn
 MOVE.L A1, D5
  MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ ADDLLD_D
    
 
 
   
 

 LEA ADDMASK, A0 * the mask
 
 MOVE.W (A6), D2
 LEA MVALUEMASK1 , A2 * mask to isolate the first operand
 LEA MVALUEMASK2 , A3 * mask to isolate the second operand
 
 
 
 
 MOVE.B #16, D1                 * we need to shift the mask so it works with longs
  MOVE.L A0, D5
  LSL.L D1, D5
  MOVEA.L D5, A0
   *perform the masking
 MOVE.L A0, D3
 MOVE.L D2, D4
 NOP
 LSL.L D1,D4
 NOP
 AND.L D3, D4
 
   LEA ADDBDD, A1 *ADD  byte Dn to Dn
 MOVE.L A1, D5
  MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ ADDBDD_D
 
    LEA ADDWDD, A1 *ADD  word Dn to Dn
 MOVE.L A1, D5
  MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ ADDWDD_D
 
  LEA ADDLDD, A1 *ADD  Long Dn to Dn
 MOVE.L A1, D5
  MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ ADDLDD_D
 
 
   LEA ADDBDD, A1 *ADDA  word -An to An
 MOVE.L A1, D5
  MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ ADDBDD_D
 
   LEA ADDBDD, A1 *ADDA  word -An to An
 MOVE.L A1, D5
  MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ ADDBDD_D

 
 
   LEA ADDBDAP, A1 *ADD  byte An+ to Dn
 MOVE.L A1, D5
  MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ ADDBDAP_D
 
    LEA ADDWDAP, A1 *ADD  word An+ to Dn
 MOVE.L A1, D5
  MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ ADDWDAP_D
 
  LEA ADDLDAP, A1 *ADD  Long An+ to Dn
 MOVE.L A1, D5
  MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ ADDLDAP_D


   LEA ADDBDAD, A1 *ADD  byte -An to Dn
 MOVE.L A1, D5
  MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ ADDBDAD_D
 
    LEA ADDWDAD, A1 *ADD  word -An to Dn
 MOVE.L A1, D5
  MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ ADDWDAD_D
 
  LEA ADDLDAD, A1 *ADD  Long -An to Dn
 MOVE.L A1, D5
  MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ ADDLDAD_D


 
    LEA ADDWAD, A1 *ADD  word An to Dn
 MOVE.L A1, D5
  MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ ADDWAD_D
 
  LEA ADDLAD, A1 *ADD  Long An to Dn
 MOVE.L A1, D5
  MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ ADDLAD_D
 
 
    LEA ADDBAID, A1 *ADD  byte (An) to Dn
 MOVE.L A1, D5
  MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ ADDBAID_D
 
    LEA ADDWAID, A1 *ADD  word (An) to Dn
 MOVE.L A1, D5
  MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ ADDWAID_D
 
  LEA ADDLAID, A1 *ADD  Long (An) to Dn
 MOVE.L A1, D5
  MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ ADDLAID_D




    LEA ADDBAPD, A1 *ADD  byte (An)+ to Dn
 MOVE.L A1, D5
  MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ ADDBAPD_D
 
    LEA ADDWAPD, A1 *ADD  word (An)+ to Dn
 MOVE.L A1, D5
  MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ ADDWAPD_D
 
  LEA ADDLDAP, A1 *ADD  Long (An)+ to Dn
 MOVE.L A1, D5
  MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ ADDLAPD_D

    LEA ADDBADD, A1 *ADD  byte -(An) to Dn
 MOVE.L A1, D5
  MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ ADDBADD_D
 
    LEA ADDWADD, A1 *ADD  word -(An) to Dn
 MOVE.L A1, D5
  MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ ADDWADD_D
 
  LEA ADDLADD, A1 *ADD  Long -(An) to Dn
 MOVE.L A1, D5
  MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ ADDLADD_D
 
 LEA ADDBDAI, A1 *ADD  byte(An) to Dn
 MOVE.L A1, D5
  MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ ADDBDAI_D
 
 LEA ADDWDAI, A1 *ADD  w An to DN
 MOVE.L A1, D5
  MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ ADDWDAI_D

 LEA ADDLDAI, A1 *ADD  l (An) to DN
 MOVE.L A1, D5
  MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ ADDLDAI_D


    LEA ADDBDAI, A1 *ADD  byte  Dn to (An)
 MOVE.L A1, D5
  MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ ADDBDAI_D
 
     LEA ADDWDAI, A1 *ADD  w  Dn to (An)
 MOVE.L A1, D5
  MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ ADDWDAI_D

    LEA ADDLDAI, A1 *ADD  l  Dn to (An)
 MOVE.L A1, D5
  MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ ADDLDAI_D


 
    LEA ADDWDAI, A1 *ADD  word (An) to Dn
 MOVE.L A1, D5
  MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ ADDWDAI_D
 
  LEA ADDLAID, A1 *ADD  Long (An) to Dn
 MOVE.L A1, D5
  MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ ADDLDAI_D




    LEA ADDBDAP, A1 
 MOVE.L A1, D5
  MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ ADDBDAP_D
 
    LEA ADDWDAP, A1 *ADD  word (An)+ to Dn
 MOVE.L A1, D5
  MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ ADDWDAP_D
 
  LEA ADDLAPD, A1 *ADD  Long (An)+ to Dn
 MOVE.L A1, D5
  MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ ADDLDAP_D


 LEA ADDBDAD, A1 *ADD  byte -(An) to Dn
 MOVE.L A1, D5
  MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ ADDBDAD_D
 
    LEA ADDWDAD, A1 *ADD  word -(An) to Dn
 MOVE.L A1, D5
  MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ ADDWDAD_D
 
  LEA ADDLDAD, A1 *ADD  Long -(An) to Dn
 MOVE.L A1, D5
  MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ ADDLDAD_D


 LEA ADDWA, A1 *ADDA  word An to An
 MOVE.L A1, D5
  MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ ADDAWA_D
 
 LEA ADDLA, A1 *ADDA  Long An to An
 MOVE.L A1, D5
  MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ ADDALA_D

 LEA ADDAWDA, A1 *ADDA  word Dn to An
 MOVE.L A1, D5
  MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ ADDAWDA_D
 
 LEA ADDALDA, A1 *ADDA  Long Dn to An
 MOVE.L A1, D5
  MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ ADDALDA_D


  LEA ADDWIA, A1 *ADDA  word (An) to An
 MOVE.L A1, D5
  MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ ADDAWIA_D
 
 LEA ADDLIA, A1 *ADDA  Long (An) to An
 MOVE.L A1, D5
  MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ ADDALIA_D 

  LEA ADDWPA, A1 *ADDA  word (An)+ to An
 MOVE.L A1, D5
  MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ ADDAWPA_D
 
  
 LEA ADDLPA, A1 *ADDA  Long (An)+ to An
 MOVE.L A1, D5
  MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ ADDALPA_D
 
   LEA ADDWPA, A1 *ADDA  word -(An) to An
 MOVE.L A1, D5
  MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 LEA ADDLPA, A1 *ADDA  Long -(An) to An
 MOVE.L A1, D5
  MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ ADDALPA_D
 
   LEA ADDWPA, A1 *ADDA  word (An)+ to An
 MOVE.L A1, D5
  MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ ADDAWPA_D
 
 LEA ADDLPA, A1 *ADDA  Long (An)+ to An
 MOVE.L A1, D5
  MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ ADDALPA_D
 
   LEA ADDWPA, A1 *ADDA  word -(An) to An
 MOVE.L A1, D5
  MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 LEA ADDLPA, A1 *ADDA  Long -(An) to An
 MOVE.L A1, D5
  MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ ADDALPA_D
   
     ADDQ.W    #2, A6      *Go to next instruction
     BRA IFINVADDRMODE  *The opcode is ADD, but the addressing modes are incorrect
 

 *_________________________________________*
 
 * ADDQ
* we will mask the instruction, and if
* the result matches a pattern for ADD, we have a valid optcode :D
* if not we will have to check the rest of the optcodes
CHECK_ADDQs    LEA   GENERAL_ADDQ_MASK, A2   *Get General Mask
  CLR.L D4
  CLR.L D5

    MOVE.W A2, D3       *Move mask to D3

    MOVE.W (A6), D4  *Get opcode from memory to D4

    AND.W  D3, D4       *Mask Opcode

    LEA    GENERAL_ADDQ, A2    *Get General ADDQ Opcode

    MOVE.W  A2, D5      *Move GENERAL ADDQ Opcode to D5

    CMP.W   D5, D4      *Compare Opcode with GENERAL ADDQ

    BNE     CHECK_BCCs     *If not Equal, Proceed to next instruction (BCC)
    
    
* Else, check ADDQ varaints

*Absolute addressing and immediate data 
    LEA   ADDQAAMASK, A2   *Get AA Mask

    MOVE.W A2, D3       *Move mask to D3

    MOVE.W (A6), D4  *Get opcode from memory to D4

    AND.W  D3, D4       *Mask Opcode

  LEA ADDQBW, A1 *ADDQ word Byte
 MOVE.L A1, D5
  MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ ADDQBW_D
 
 
  LEA ADDQWW, A1 *ADDQ word Word
 MOVE.L A1, D5
  MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ ADDQWW_D
 
 
  LEA ADDQLW, A1 *ADDQ word Long
 MOVE.L A1, D5
  MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ ADDQLW_D
 
    LEA ADDQBL, A1 *ADDQ long Byte
 MOVE.L A1, D5
  MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ ADDQBL_D
 
 
  LEA ADDQWL, A1 *ADDQ long Word
 MOVE.L A1, D5
  MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ ADDQWL_D
 
 
  LEA ADDQLL, A1 *ADDQ long Long
 MOVE.L A1, D5
  MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ ADDQLL_D


* The Rest
    LEA ADDQMASK, A0 * the mask
 

  MOVE.W (A6), D2
 LEA ADDQDEST , A2 * mask to isolate the operand
  LEA ADDQVALUE , A3 * mask to isolate the data

 
 MOVE.B #16, D1                 * we need to shift the mask so it works with longs
  MOVE.L A0, D5
  LSL.L D1, D5
  MOVEA.L D5, A0
   *perform the masking
 MOVE.L A0, D3
 MOVE.L D2, D4
 NOP
 LSL.L D1,D4
 NOP
 AND.L D3, D4
 
 
  LEA ADDQBD, A1 *ADDQ Dn Byte
 MOVE.L A1, D5
  MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ ADDQBD_D
 
 
  LEA ADDQWD, A1 *ADDQ Dn Word
 MOVE.L A1, D5
  MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ ADDQWD_D
 
 
  LEA ADDQLD, A1 *ADDQ Dn Long
 MOVE.L A1, D5
  MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ ADDQLD_D
 
   LEA ADDQBA, A1 *ADDQ An Byte
 MOVE.L A1, D5
  MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ ADDQBA_D
 
 
  LEA ADDQWA, A1 *ADDQ An Word
 MOVE.L A1, D5
  MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ ADDQWA_D
 
 
  LEA ADDQLA, A1 *ADDQ An Long
 MOVE.L A1, D5
  MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ ADDQLA_D
 
   LEA ADDQBAI, A1 *ADDQ (An) Byte
 MOVE.L A1, D5
  MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ ADDQBAI_D
 
 
  LEA ADDQWAI, A1 *ADDQ (An) Word
 MOVE.L A1, D5
  MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ ADDQWAI_D
 
 
  LEA ADDQLAI , A1 *ADDQ (An) Long
 MOVE.L A1, D5
  MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ ADDQLAI_D


   LEA ADDQBAPI, A1 *ADDQ (An)+ Byte
 MOVE.L A1, D5
  MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ ADDQBAPI_D
 
 
  LEA ADDQWAPI, A1 *ADDQ (An)+ Word
 MOVE.L A1, D5
  MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ ADDQWAPI_D
 
 
  LEA ADDQLAPI , A1 *ADDQ (An)+ Long
 MOVE.L A1, D5
  MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ ADDQLAPI_D
 
 
 
   LEA ADDQBAPD, A1 *ADDQ -(An) Byte
 MOVE.L A1, D5
  MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ ADDQBAPD_D
 
 
  LEA ADDQWAPD, A1 *ADDQ -(An) Word
 MOVE.L A1, D5
  MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ ADDQWAPD_D
 
 
  LEA ADDQLAPD , A1 *ADDQ -(An) Long
 MOVE.L A1, D5
  MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ ADDQLAPD_D
 
 
 

    ADDQ.W    #2, A6      *Go to next instruction
     BRA IFINVADDRMODE  *The opcode is ADDQ, but the addressing modes are incorrect

*--------------- BCC (BRA, BEQ, BGT, BLE) ----------*   Note: there is no GENERAL code for BCC because there is no invalid addressing modes
CHECK_BCCs    LEA   BCCMASK, A2   *Get Mask


    MOVE.W A2, D3       *Move mask to D3

    MOVE.W (A6), D4  *Get opcode from memory to D4

    AND.W  D3, D4       *Mask Opcode

CHECK_BRA    LEA    BRACO, A2    *Get BRA Opcode

    MOVE.W  A2, D5      *Move BRA Opcode to D5

    CMP.W   D5, D4      *Compare Opcode with BRA

    BEQ     BRA_D     *If Equal, Proceed to operand decoding

CHECK_BEQ    LEA    BEQCO, A2    *Get BEQ Opcode


    MOVE.W  A2, D5      *Move BEQ Opcode to D5

    CMP.W   D5, D4      *Compare Current Opcode with BEQ

    BEQ     BEQ_D     *If Equal, Proceed to operand decoding

CHECK_BGT    LEA    BGTCO, A2    *Get BGT Opcode


    MOVE.W  A2, D5      *Move BGT Opcode to D5

    CMP.W   D5, D4      *Compare current Opcode with BGT

    BEQ     BGT_D     *If Equal, Proceed to operand decoding

CHECK_BLE    LEA    BLECO, A2    *Get BLE Opcode

    MOVE.W  A2, D5      *Move BLE Opcode to D5

    CMP.W   D5, D4      *Compare Current Opcode with BLE

    BEQ     BLE_D     *If Equal, Proceed to operand decoding

*------------ JSR ------------------------*
CHECK_JSRs    LEA   GENERAL_JSR_MASK, A2   *Get General Mask


    MOVE.W A2, D3       *Move mask to D3

    MOVE.W (A6), D4  *Get opcode from memory to D4

    AND.W  D3, D4       *Mask Opcode

    LEA    GENERAL_JSR, A2    *Get General JSR Opcode

    MOVE.W  A2, D5      *Move GENERAL JSR Opcode to D5

    CMP.W   D5, D4      *Compare Opcode with GENERAL JSR

    BNE     CHECK_ASdEAs     *If not Equal, Proceed to next instruction (ASdEA)
    
    
* Else, check JSR varaints




    LEA   JSRMASK, A2   *Get Mask

    MOVE.W A2, D3       *Move mask to D3

    MOVE.W (A6), D4  *Get opcode from memory to D4

CHECK_JSRWA    *Since word and long addressing needs the masked bits, the original address is used(before masking)


    LEA    JSRWA, A2    *Get JSR Word Address Opcode

    MOVE.W  A2, D5      *Move JSR Word Address Opcode to D5

    CMP.W   D5, D4      *Compare current Opcode with JSR Word Address

    BEQ     JSRWA_D     *If Equal, Proceed to operand decoding

CHECK_JSRLA    LEA    JSRLA, A2    *Get JSR Long Address Opcode
 
    MOVE.W  A2, D5      *Move JSR Long Addres Opcode to D5

    CMP.W   D5, D4      *Compare current Opcode with JSR Long Addres

    BEQ     JSRLA_D     *If Equal, Proceed to operand decoding




    AND.W  D3, D4       *Mask Opcode



CHECK_JSRAI    LEA    JSRAI, A2    *Get JSR Indirect Address Register Opcode


    MOVE.W  A2, D5      *Move JSR Indirect Address Register Opcode to D5

    CMP.W   D5, D4      *Compare current Opcode with JSR Indirect Address Register

    BEQ     JSRAI_D     *If Equal, Proceed to operand decoding

    ADDQ.W    #2, A6      *Go to next instruction
     BRA IFINVADDRMODE  *The opcode is JSR, but the addressing modes are incorrect

*---------------- ASL EA --------------------*
CHECK_ASdEAs    LEA   GENERAL_RSEA_MASK, A2   *Get General Mask

    MOVE.W A2, D3       *Move mask to D3

    MOVE.W (A6), D4  *Get opcode from memory to D4

    AND.W  D3, D4       *Mask Opcode

    LEA    GENERAL_ASdEA, A2    *Get General ASdEA Opcode

    MOVE.W  A2, D5      *Move GENERAL ASdEA Opcode to D5

    CMP.W   D5, D4      *Compare Opcode with GENERAL ASdEA

    BNE     CHECK_LSdEAs     *If not Equal, Proceed to next instruction (LSdEA)
    
    
* Else, check ASLEA and ASREA varaints

    

    LEA   RSEAMASK, A2   *Get Mask

    MOVE.W A2, D3       *Move mask to D3

    MOVE.W (A6), D4  *Get opcode from memory to D4

CHECK_ASLWA  LEA ASLWA, A2  *Get ASL word address opcode


            MOVE.W  A2, D5  *Move ASL word address opcode to D5

            CMP.W   D5, D4  *Compare current opcode with ASL word address

            BEQ     ASLWA_D *If Equal, Proceed to operand decoding
            
CHECK_ASLBWA  LEA ASLBWA, A2  *Get ASL word address opcode


            MOVE.W  A2, D5  *Move ASL word address opcode to D5

            CMP.W   D5, D4  *Compare current opcode with ASL word address

            BEQ     ASLBWA_D *If Equal, Proceed to operand decoding
            
CHECK_ASLWWA  LEA ASLWWA, A2  *Get ASL word address opcode


            MOVE.W  A2, D5  *Move ASL word address opcode to D5

            CMP.W   D5, D4  *Compare current opcode with ASL word address

            BEQ     ASLWWA_D *If Equal, Proceed to operand decoding

CHECK_ASLLWA  LEA ASLLWA, A2  *Get ASL word address opcode


            MOVE.W  A2, D5  *Move ASL word address opcode to D5

            CMP.W   D5, D4  *Compare current opcode with ASL word address

            BEQ     ASLLWA_D *If Equal, Proceed to operand decoding


CHECK_ASLLA  LEA ASLLA, A2  *Determine if opcode is ASL Long Address


            MOVE.W  A2, D5

            CMP.W   D5, D4

            BEQ     ASLLA_D
            
CHECK_ASLBLA  LEA ASLBLA, A2  *Determine if opcode is ASL Long Address


            MOVE.W  A2, D5

            CMP.W   D5, D4

            BEQ     ASLBLA_D
            
            
CHECK_ASLWLA  LEA ASLWLA, A2  *Determine if opcode is ASL Long Address


            MOVE.W  A2, D5

            CMP.W   D5, D4

            BEQ     ASLWLA_D
            
            
CHECK_ASLLLA  LEA ASLLLA, A2  *Determine if opcode is ASL Long Address


            MOVE.W  A2, D5

            CMP.W   D5, D4

            BEQ     ASLLLA_D


            AND.W  D3, D4       *Mask Opcode

CHECK_ASLAI  LEA ASLAI, A2  *Determine if opcode is ASL Indirect Address Register


            MOVE.W  A2, D5

            CMP.W   D5, D4

            BEQ     ASLAI_D
            
CHECK_ASLBAI  LEA ASLBAI, A2  *Determine if opcode is ASL Indirect Address Register


            MOVE.W  A2, D5

            CMP.W   D5, D4

            BEQ     ASLBAI_D 
            
CHECK_ASLWAI  LEA ASLWAI, A2  *Determine if opcode is ASL Indirect Address Register


            MOVE.W  A2, D5

            CMP.W   D5, D4

            BEQ     ASLWAI_D
            
CHECK_ASLLAI  LEA ASLLAI, A2  *Determine if opcode is ASL Indirect Address Register


            MOVE.W  A2, D5

            CMP.W   D5, D4

            BEQ     ASLLAI_D
           

CHECK_ASLPI  LEA ASLPI, A2  *Determine if opcode is ASL Post Increment Address Register



            MOVE.W  A2, D5

            CMP.W   D5, D4

            BEQ     ASLPI_D
            
CHECK_ASLBPI  LEA ASLBPI, A2  *Determine if opcode is ASL Post Increment Address Register



            MOVE.W  A2, D5

            CMP.W   D5, D4

            BEQ     ASLBPI_D
            
CHECK_ASLWPI  LEA ASLWPI, A2  *Determine if opcode is ASL Post Increment Address Register



            MOVE.W  A2, D5

            CMP.W   D5, D4

            BEQ     ASLWPI_D

CHECK_ASLLPI  LEA ASLLPI, A2  *Determine if opcode is ASL Post Increment Address Register



            MOVE.W  A2, D5

            CMP.W   D5, D4

            BEQ     ASLLPI_D



CHECK_ASLPD  LEA ASLPD, A2  *Determine if opcode is ASL Pre Decrement Adress Register

 

            MOVE.W  A2, D5

            CMP.W   D5, D4

            BEQ     ASLPD_D
            
            
CHECK_ASLBPD  LEA ASLBPD, A2  *Determine if opcode is ASL Pre Decrement Adress Register

 

            MOVE.W  A2, D5

            CMP.W   D5, D4

            BEQ     ASLBPD_D
            
CHECK_ASLWPD  LEA ASLWPD, A2  *Determine if opcode is ASL Pre Decrement Adress Register

 

            MOVE.W  A2, D5

            CMP.W   D5, D4

            BEQ     ASLWPD_D
            
CHECK_ASLLPD  LEA ASLLPD, A2  *Determine if opcode is ASL Pre Decrement Adress Register

 

            MOVE.W  A2, D5

            CMP.W   D5, D4

            BEQ     ASLLPD_D

*---------------- ASR EA --------------------*
CHECK_ASREAs    LEA   RSEAMASK, A2   *Get Mask


    MOVE.W A2, D3       *Move mask to D3

    MOVE.W (A6), D4  *Get opcode from memory to D4

CHECK_ASRWA  LEA ASRWA, A2  *Determine if opcode is ASR Word Address

            MOVE.W  A2, D5

            CMP.W   D5, D4

            BEQ     ASRWA_D
            
CHECK_ASRBWA  LEA ASRBWA, A2  *Determine if opcode is ASR Word Address

            MOVE.W  A2, D5

            CMP.W   D5, D4

            BEQ     ASRBWA_D
            
CHECK_ASRWWA  LEA ASRWWA, A2  *Determine if opcode is ASR Word Address

            MOVE.W  A2, D5

            CMP.W   D5, D4

            BEQ     ASRWWA_D
            
CHECK_ASRLWA  LEA ASRLWA, A2  *Determine if opcode is ASR Word Address

            MOVE.W  A2, D5

            CMP.W   D5, D4

            BEQ     ASRLWA_D


CHECK_ASRLA  LEA ASRLA, A2  *Determine if opcode is ASR Long Address

            MOVE.W  A2, D5

            CMP.W   D5, D4

            BEQ     ASRLA_D
            
CHECK_ASRBLA  LEA ASRBLA, A2  *Determine if opcode is ASR Long Address

            MOVE.W  A2, D5

            CMP.W   D5, D4

            BEQ     ASRBLA_D
            
CHECK_ASRWLA  LEA ASRWLA, A2  *Determine if opcode is ASR Long Address

            MOVE.W  A2, D5

            CMP.W   D5, D4

            BEQ     ASRWLA_D
            
CHECK_ASRLLA  LEA ASRLLA, A2  *Determine if opcode is ASR Long Address

            MOVE.W  A2, D5

            CMP.W   D5, D4

            BEQ     ASRLLA_D


            AND.W  D3, D4       *Mask Opcode

CHECK_ASRAI  LEA ASRAI, A2  *Determine if opcode is ASR Indirect Address Register

            MOVE.W  A2, D5

            CMP.W   D5, D4

            BEQ     ASRAI_D
            
CHECK_ASRBAI  LEA ASRBAI, A2  *Determine if opcode is ASR Indirect Address Register

            MOVE.W  A2, D5

            CMP.W   D5, D4

            BEQ     ASRBAI_D
            
CHECK_ASRWAI  LEA ASRWAI, A2  *Determine if opcode is ASR Indirect Address Register

            MOVE.W  A2, D5

            CMP.W   D5, D4

            BEQ     ASRWAI_D
            
CHECK_ASRLAI  LEA ASRLAI, A2  *Determine if opcode is ASR Indirect Address Register

            MOVE.W  A2, D5

            CMP.W   D5, D4

            BEQ     ASRLAI_D

CHECK_ASRPI  LEA ASRPI, A2  *Determine if opcode is ASR Post Increment Address Register


            MOVE.W  A2, D5

            CMP.W   D5, D4

            BEQ     ASRPI_D
            
CHECK_ASRBPI  LEA ASRBPI, A2  *Determine if opcode is ASR Post Increment Address Register


            MOVE.W  A2, D5

            CMP.W   D5, D4

            BEQ     ASRBPI_D
            
CHECK_ASRWPI  LEA ASRWPI, A2  *Determine if opcode is ASR Post Increment Address Register


            MOVE.W  A2, D5

            CMP.W   D5, D4

            BEQ     ASRWPI_D
            
CHECK_ASRLPI  LEA ASRLPI, A2  *Determine if opcode is ASR Post Increment Address Register


            MOVE.W  A2, D5

            CMP.W   D5, D4

            BEQ     ASRLPI_D

CHECK_ASRPD  LEA ASRPD, A2  *Determine if opcode is ASR Pre Decrement Address Register

            MOVE.W  A2, D5

            CMP.W   D5, D4

            BEQ     ASRPD_D
            
CHECK_ASRBPD  LEA ASRBPD, A2  *Determine if opcode is ASR Pre Decrement Address Register

            MOVE.W  A2, D5

            CMP.W   D5, D4

            BEQ     ASRBPD_D
            
CHECK_ASRWPD  LEA ASRWPD, A2  *Determine if opcode is ASR Pre Decrement Address Register

            MOVE.W  A2, D5

            CMP.W   D5, D4

            BEQ     ASRWPD_D
            
CHECK_ASRLPD  LEA ASRLPD, A2  *Determine if opcode is ASR Pre Decrement Address Register

            MOVE.W  A2, D5

            CMP.W   D5, D4

            BEQ     ASRLPD_D
            
            ADDQ.W    #2, A6      *Go to next instruction
             BRA IFINVADDRMODE  *The opcode is ASdEA, but the addressing modes are incorrect

*---------------- LSL EA --------------------*
CHECK_LSdEAs   LEA   GENERAL_RSEA_MASK, A2   *Get General Mask


    MOVE.W A2, D3       *Move mask to D3

    MOVE.W (A6), D4  *Get opcode from memory to D4

    AND.W  D3, D4       *Mask Opcode

    LEA    GENERAL_LSdEA, A2    *Get General LSdEA Opcode

    MOVE.W  A2, D5      *Move GENERAL LSdEA Opcode to D5

    CMP.W   D5, D4      *Compare Opcode with GENERAL LSdEA

    BNE     CHECK_ROdEAs     *If not Equal, Proceed to next instruction (ROdEA)
    
    
* Else, check LSLEA and LSREA varaints



    LEA   RSEAMASK, A2   *Get Mask

    MOVE.W A2, D3       *Move mask to D3

    MOVE.W (A6), D4  *Get opcode from memory to D4

CHECK_LSLWA  LEA LSLWA, A2  *Determine if opcode is LSL Word Address

            MOVE.W  A2, D5

            CMP.W   D5, D4

            BEQ     LSLWA_D
            
CHECK_LSLBWA  LEA LSLBWA, A2  *Determine if opcode is LSL Word Address

            MOVE.W  A2, D5

            CMP.W   D5, D4

            BEQ     LSLBWA_D
            
CHECK_LSLWWA  LEA LSLWWA, A2  *Determine if opcode is LSL Word Address

            MOVE.W  A2, D5

            CMP.W   D5, D4

            BEQ     LSLWWA_D
            
CHECK_LSLLWA  LEA LSLLWA, A2  *Determine if opcode is LSL Word Address

            MOVE.W  A2, D5

            CMP.W   D5, D4

            BEQ     LSLLWA_D


CHECK_LSLLA  LEA LSLLA, A2  *Determine if opcode is LSL Long Address
 
            MOVE.W  A2, D5

            CMP.W   D5, D4

            BEQ     LSLLA_D
            
CHECK_LSLBLA  LEA LSLBLA, A2  *Determine if opcode is LSL Long Address
 
            MOVE.W  A2, D5

            CMP.W   D5, D4

            BEQ     LSLBLA_D
            
CHECK_LSLWLA  LEA LSLWLA, A2  *Determine if opcode is LSL Long Address
 
            MOVE.W  A2, D5

            CMP.W   D5, D4

            BEQ     LSLWLA_D
            
CHECK_LSLLLA  LEA LSLLLA, A2  *Determine if opcode is LSL Long Address
 
            MOVE.W  A2, D5

            CMP.W   D5, D4

            BEQ     LSLLLA_D


            AND.W  D3, D4       *Mask Opcode

CHECK_LSLAI  LEA LSLAI, A2  *Determine if opcode is LSL Indirect Address Register


            MOVE.W  A2, D5

            CMP.W   D5, D4

            BEQ     LSLAI_D
            
CHECK_LSLBAI  LEA LSLBAI, A2  *Determine if opcode is LSL Indirect Address Register


            MOVE.W  A2, D5

            CMP.W   D5, D4

            BEQ     LSLBAI_D
            
CHECK_LSLWAI  LEA LSLWAI, A2  *Determine if opcode is LSL Indirect Address Register


            MOVE.W  A2, D5

            CMP.W   D5, D4

            BEQ     LSLWAI_D

CHECK_LSLLAI  LEA LSLLAI, A2  *Determine if opcode is LSL Indirect Address Register


            MOVE.W  A2, D5

            CMP.W   D5, D4

            BEQ     LSLLAI_D

CHECK_LSLPI  LEA LSLPI, A2  *Determine if opcode is LSL Post Increment Address Register
 

            MOVE.W  A2, D5

            CMP.W   D5, D4

            BEQ     LSLPI_D
            
CHECK_LSLBPI  LEA LSLBPI, A2  *Determine if opcode is LSL Post Increment Address Register
 

            MOVE.W  A2, D5

            CMP.W   D5, D4

            BEQ     LSLBPI_D
            
CHECK_LSLWPI  LEA LSLWPI, A2  *Determine if opcode is LSL Post Increment Address Register
 

            MOVE.W  A2, D5

            CMP.W   D5, D4

            BEQ     LSLWPI_D
            
CHECK_LSLLPI  LEA LSLLPI, A2  *Determine if opcode is LSL Post Increment Address Register
 

            MOVE.W  A2, D5

            CMP.W   D5, D4

            BEQ     LSLLPI_D

CHECK_LSLPD  LEA LSLPD, A2  *Determine if opcode is LSL Pre Decrement Address Register

            MOVE.W  A2, D5

            CMP.W   D5, D4

            BEQ     LSLPD_D
            
CHECK_LSLBPD  LEA LSLBPD, A2  *Determine if opcode is LSL Pre Decrement Address Register

            MOVE.W  A2, D5

            CMP.W   D5, D4

            BEQ     LSLBPD_D
            
CHECK_LSLWPD  LEA LSLWPD, A2  *Determine if opcode is LSL Pre Decrement Address Register

            MOVE.W  A2, D5

            CMP.W   D5, D4

            BEQ     LSLWPD_D
            
CHECK_LSLLPD  LEA LSLLPD, A2  *Determine if opcode is LSL Pre Decrement Address Register

            MOVE.W  A2, D5

            CMP.W   D5, D4

            BEQ     LSLLPD_D


*---------------- LSR EA --------------------*
CHECK_LSREAs    LEA   RSEAMASK, A2   *Get Mask
 

    MOVE.W A2, D3       *Move mask to D3

    MOVE.W (A6), D4  *Get opcode from memory to D4

CHECK_LSRWA  LEA LSRWA, A2  *Determine if opcode is LSR Word Address
  
            MOVE.W  A2, D5

            CMP.W   D5, D4

            BEQ     LSRWA_D
            
CHECK_LSRBWA  LEA LSRBWA, A2  *Determine if opcode is LSR Word Address
  
            MOVE.W  A2, D5

            CMP.W   D5, D4

            BEQ     LSRBWA_D
            
CHECK_LSRWWA  LEA LSRWWA, A2  *Determine if opcode is LSR Word Address
  
            MOVE.W  A2, D5

            CMP.W   D5, D4

            BEQ     LSRWWA_D
            
CHECK_LSRLWA  LEA LSRLWA, A2  *Determine if opcode is LSR Word Address
  
            MOVE.W  A2, D5

            CMP.W   D5, D4

            BEQ     LSRLWA_D


CHECK_LSRLA  LEA LSRLA, A2  *Determine if opcode is LSR Long Address

            MOVE.W  A2, D5

            CMP.W   D5, D4

            BEQ     LSRLA_D
            
CHECK_LSRBLA  LEA LSRBLA, A2  *Determine if opcode is LSR Long Address

            MOVE.W  A2, D5

            CMP.W   D5, D4

            BEQ     LSRBLA_D
            
CHECK_LSRWLA  LEA LSRWLA, A2  *Determine if opcode is LSR Long Address

            MOVE.W  A2, D5

            CMP.W   D5, D4

            BEQ     LSRWLA_D
            
CHECK_LSRLLA  LEA LSRLLA, A2  *Determine if opcode is LSR Long Address

            MOVE.W  A2, D5

            CMP.W   D5, D4

            BEQ     LSRLLA_D


            AND.W  D3, D4       *Mask Opcode

CHECK_LSRAI  LEA LSRAI, A2  *Determine if opcode is LSR Indirect Address Register
 

            MOVE.W  A2, D5

            CMP.W   D5, D4

            BEQ     LSRAI_D
            
CHECK_LSRBAI  LEA LSRBAI, A2  *Determine if opcode is LSR Indirect Address Register
 

            MOVE.W  A2, D5

            CMP.W   D5, D4

            BEQ     LSRBAI_D
            
CHECK_LSRWAI  LEA LSRWAI, A2  *Determine if opcode is LSR Indirect Address Register
 

            MOVE.W  A2, D5

            CMP.W   D5, D4

            BEQ     LSRWAI_D
            
CHECK_LSRLAI  LEA LSRLAI, A2  *Determine if opcode is LSR Indirect Address Register
 

            MOVE.W  A2, D5

            CMP.W   D5, D4

            BEQ     LSRLAI_D

CHECK_LSRPI  LEA LSRPI, A2  *Determine if opcode is LSR Post Increment Address Register

            MOVE.W  A2, D5

            CMP.W   D5, D4

            BEQ     LSRPI_D
            
CHECK_LSRBPI  LEA LSRBPI, A2  *Determine if opcode is LSR Post Increment Address Register

            MOVE.W  A2, D5

            CMP.W   D5, D4

            BEQ     LSRBPI_D
            
CHECK_LSRWPI  LEA LSRWPI, A2  *Determine if opcode is LSR Post Increment Address Register

            MOVE.W  A2, D5

            CMP.W   D5, D4

            BEQ     LSRWPI_D
            
CHECK_LSRLPI  LEA LSRLPI, A2  *Determine if opcode is LSR Post Increment Address Register

            MOVE.W  A2, D5

            CMP.W   D5, D4

            BEQ     LSRLPI_D

CHECK_LSRPD  LEA LSRPD, A2  *Determine if opcode is LSR Pre Decrement Address Register


            MOVE.W  A2, D5

            CMP.W   D5, D4

            BEQ     LSRPD_D
            
CHECK_LSRBPD  LEA LSRBPD, A2  *Determine if opcode is LSR Pre Decrement Address Register


            MOVE.W  A2, D5

            CMP.W   D5, D4

            BEQ     LSRBPD_D
            
CHECK_LSRWPD  LEA LSRWPD, A2  *Determine if opcode is LSR Pre Decrement Address Register


            MOVE.W  A2, D5

            CMP.W   D5, D4

            BEQ     LSRWPD_D
            
CHECK_LSRLPD  LEA LSRLPD, A2  *Determine if opcode is LSR Pre Decrement Address Register


            MOVE.W  A2, D5

            CMP.W   D5, D4

            BEQ     LSRLPD_D

            ADDQ.W    #2, A6      *Go to next instruction
             BRA IFINVADDRMODE  *The opcode is LSdEA, but the addressing modes are incorrect


*---------------- ROL EA --------------------*
CHECK_ROdEAs   LEA   GENERAL_RSEA_MASK, A2   *Get General Mask


    MOVE.W A2, D3       *Move mask to D3

    MOVE.W (A6), D4  *Get opcode from memory to D4

    AND.W  D3, D4       *Mask Opcode

    LEA    GENERAL_ROdEA, A2    *Get General ROdEA Opcode

    MOVE.W  A2, D5      *Move GENERAL MOVE Opcode to D5

    CMP.W   D5, D4      *Compare Opcode with GENERAL ROdEA

    BNE     CHECK_ASdDIs     *If not Equal, Proceed to next instruction (ASdDI)
    
    
* Else, check ROLEA and ROREA varaints



     LEA   RSEAMASK, A2   *Get Mask

    MOVE.W A2, D3       *Move mask to D3

    MOVE.W (A6), D4  *Get opcode from memory to D4

CHECK_ROLWA  LEA ROLWA, A2  *Determine if opcode is ROL Word Address


            MOVE.W  A2, D5

            CMP.W   D5, D4

            BEQ     ROLWA_D
            
CHECK_ROLBWA  LEA ROLBWA, A2  *Determine if opcode is ROL Word Address


            MOVE.W  A2, D5

            CMP.W   D5, D4

            BEQ     ROLBWA_D
            
CHECK_ROLWWA  LEA ROLWWA, A2  *Determine if opcode is ROL Word Address


            MOVE.W  A2, D5

            CMP.W   D5, D4

            BEQ     ROLWWA_D
            
CHECK_ROLLWA  LEA ROLLWA, A2  *Determine if opcode is ROL Word Address


            MOVE.W  A2, D5

            CMP.W   D5, D4

            BEQ     ROLLWA_D


CHECK_ROLLA  LEA ROLLA, A2  *Determine if opcode is ROL Long Address

            MOVE.W  A2, D5

            CMP.W   D5, D4

            BEQ     ROLLA_D
            
CHECK_ROLBLA  LEA ROLBLA, A2  *Determine if opcode is ROL Long Address

            MOVE.W  A2, D5

            CMP.W   D5, D4

            BEQ     ROLBLA_D
            
CHECK_ROLWLA  LEA ROLWLA, A2  *Determine if opcode is ROL Long Address

            MOVE.W  A2, D5

            CMP.W   D5, D4

            BEQ     ROLWLA_D
            
CHECK_ROLLLA  LEA ROLLLA, A2  *Determine if opcode is ROL Long Address

            MOVE.W  A2, D5

            CMP.W   D5, D4

            BEQ     ROLLLA_D


            AND.W  D3, D4       *Mask Opcode

CHECK_ROLAI  LEA ROLAI, A2  *Determine if opcode is ROL Indirect Address Register


            MOVE.W  A2, D5

            CMP.W   D5, D4

            BEQ     ROLAI_D
            
CHECK_ROLBAI  LEA ROLBAI, A2  *Determine if opcode is ROL Indirect Address Register


            MOVE.W  A2, D5

            CMP.W   D5, D4

            BEQ     ROLBAI_D
            
CHECK_ROLWAI  LEA ROLWAI, A2  *Determine if opcode is ROL Indirect Address Register


            MOVE.W  A2, D5

            CMP.W   D5, D4

            BEQ     ROLWAI_D
            
CHECK_ROLLAI  LEA ROLLAI, A2  *Determine if opcode is ROL Indirect Address Register


            MOVE.W  A2, D5

            CMP.W   D5, D4

            BEQ     ROLLAI_D

CHECK_ROLPI  LEA ROLPI, A2  *Determine if opcode is ROL Post Increment Address Register


            MOVE.W  A2, D5

            CMP.W   D5, D4

            BEQ     ROLPI_D
            
CHECK_ROLBPI  LEA ROLBPI, A2  *Determine if opcode is ROL Post Increment Address Register


            MOVE.W  A2, D5

            CMP.W   D5, D4

            BEQ     ROLBPI_D
            
CHECK_ROLWPI  LEA ROLWPI, A2  *Determine if opcode is ROL Post Increment Address Register


            MOVE.W  A2, D5

            CMP.W   D5, D4

            BEQ     ROLWPI_D
            
CHECK_ROLLPI  LEA ROLLPI, A2  *Determine if opcode is ROL Post Increment Address Register


            MOVE.W  A2, D5

            CMP.W   D5, D4

            BEQ     ROLLPI_D

CHECK_ROLPD  LEA ROLPD, A2  *Determine if opcode is ROL Pre Decrement Address Register


            MOVE.W  A2, D5

            CMP.W   D5, D4

            BEQ     ROLPD_D
            
CHECK_ROLBPD  LEA ROLBPD, A2  *Determine if opcode is ROL Pre Decrement Address Register


            MOVE.W  A2, D5

            CMP.W   D5, D4

            BEQ     ROLBPD_D
            
CHECK_ROLWPD  LEA ROLWPD, A2  *Determine if opcode is ROL Pre Decrement Address Register


            MOVE.W  A2, D5

            CMP.W   D5, D4

            BEQ     ROLWPD_D
            
CHECK_ROLLPD  LEA ROLLPD, A2  *Determine if opcode is ROL Pre Decrement Address Register


            MOVE.W  A2, D5

            CMP.W   D5, D4

            BEQ     ROLLPD_D


*---------------- ROR EA --------------------*
CHECK_ROREAs    LEA   RSEAMASK, A2   *Get Mask


    MOVE.W A2, D3       *Move mask to D3

    MOVE.W (A6), D4  *Get opcode from memory to D4

CHECK_RORWA  LEA RORWA, A2  *Determine if opcode is ROL Word Address


            MOVE.W  A2, D5

            CMP.W   D5, D4

            BEQ     RORWA_D
            
CHECK_RORBWA  LEA RORBWA, A2  *Determine if opcode is ROL Word Address


            MOVE.W  A2, D5

            CMP.W   D5, D4

            BEQ     RORBWA_D
            
CHECK_RORWWA  LEA RORWWA, A2  *Determine if opcode is ROL Word Address


            MOVE.W  A2, D5

            CMP.W   D5, D4

            BEQ     RORWWA_D
            
CHECK_RORLWA  LEA RORLWA, A2  *Determine if opcode is ROL Word Address


            MOVE.W  A2, D5

            CMP.W   D5, D4

            BEQ     RORLWA_D


CHECK_RORLA  LEA RORLA, A2  *Determine if opcode is ROL Long Address

            MOVE.W  A2, D5

            CMP.W   D5, D4

            BEQ     RORLA_D
            
CHECK_RORBLA  LEA RORBLA, A2  *Determine if opcode is ROL Long Address

            MOVE.W  A2, D5

            CMP.W   D5, D4

            BEQ     RORBLA_D
            
CHECK_RORWLA  LEA RORWLA, A2  *Determine if opcode is ROL Long Address

            MOVE.W  A2, D5

            CMP.W   D5, D4

            BEQ     RORWLA_D
            
CHECK_RORLLA  LEA RORLLA, A2  *Determine if opcode is ROL Long Address

            MOVE.W  A2, D5

            CMP.W   D5, D4

            BEQ     RORLLA_D


            AND.W  D3, D4       *Mask Opcode

CHECK_RORAI  LEA RORAI, A2  *Determine if opcode is ROL Indirect Address Register


            MOVE.W  A2, D5

            CMP.W   D5, D4

            BEQ     RORAI_D
            
CHECK_RORBAI  LEA RORBAI, A2  *Determine if opcode is ROL Indirect Address Register


            MOVE.W  A2, D5

            CMP.W   D5, D4

            BEQ     RORBAI_D
            
CHECK_RORWAI  LEA RORWAI, A2  *Determine if opcode is ROL Indirect Address Register


            MOVE.W  A2, D5

            CMP.W   D5, D4

            BEQ     RORWAI_D
            
CHECK_RORLAI  LEA RORLAI, A2  *Determine if opcode is ROL Indirect Address Register


            MOVE.W  A2, D5

            CMP.W   D5, D4

            BEQ     RORLAI_D

CHECK_RORPI  LEA RORPI, A2  *Determine if opcode is ROL Post Increment Address Register


            MOVE.W  A2, D5

            CMP.W   D5, D4

            BEQ     RORPI_D
            
CHECK_RORBPI  LEA RORBPI, A2  *Determine if opcode is ROL Post Increment Address Register


            MOVE.W  A2, D5

            CMP.W   D5, D4

            BEQ     RORBPI_D
            
CHECK_RORWPI  LEA RORWPI, A2  *Determine if opcode is ROL Post Increment Address Register


            MOVE.W  A2, D5

            CMP.W   D5, D4

            BEQ     RORWPI_D
            
CHECK_RORLPI  LEA RORLPI, A2  *Determine if opcode is ROL Post Increment Address Register


            MOVE.W  A2, D5

            CMP.W   D5, D4

            BEQ     RORLPI_D

CHECK_RORPD  LEA RORPD, A2  *Determine if opcode is ROL Pre Decrement Address Register


            MOVE.W  A2, D5

            CMP.W   D5, D4

            BEQ     RORPD_D
            
CHECK_RORBPD  LEA RORBPD, A2  *Determine if opcode is ROL Pre Decrement Address Register


            MOVE.W  A2, D5

            CMP.W   D5, D4

            BEQ     RORBPD_D
            
CHECK_RORWPD  LEA RORWPD, A2  *Determine if opcode is ROL Pre Decrement Address Register


            MOVE.W  A2, D5

            CMP.W   D5, D4

            BEQ     RORWPD_D
            
CHECK_RORLPD  LEA RORLPD, A2  *Determine if opcode is ROL Pre Decrement Address Register


            MOVE.W  A2, D5

            CMP.W   D5, D4

            BEQ     RORLPD_D
            
            ADDQ.W    #2, A6      *Go to next instruction
             BRA IFINVADDRMODE  *The opcode is ROdEA, but the addressing modes are incorrect

*---------------- ASL Data/Immediate --------------------*
CHECK_ASdDIs    LEA   GENERAL_RSDI_MASK, A2   *Get General Mask


    MOVE.W A2, D3       *Move mask to D3

    MOVE.W (A6), D4  *Get opcode from memory to D4

    AND.W  D3, D4       *Mask Opcode

    LEA    GENERAL_ASdDI, A2    *Get General ASdDI Opcode

    MOVE.W  A2, D5      *Move GENERAL ASdDI Opcode to D5

    CMP.W   D5, D4      *Compare Opcode with GENERAL ASdDI

    BNE     CHECK_LSdDIs     *If not Equal, Proceed to next instruction (LSdDI)
    
    
* Else, check ASLDI and ASRDI varaints



    LEA   RSDIMASK, A2   *Get Mask

    MOVE.W A2, D3       *Move mask to D3

    MOVE.W (A6), D4  *Get opcode from memory to D4

    AND.W  D3, D4       *Mask Opcode

CHECK_ASLBD  LEA ASLBD, A2  *Determine if opcode is ASL.B Data Register


            MOVE.W  A2, D5

            CMP.W   D5, D4

            BEQ     ASLBD_D

CHECK_ASLWD  LEA ASLWD, A2   *Determine if opcode is ASL.W Data Register

            MOVE.W  A2, D5

            CMP.W   D5, D4

            BEQ     ASLWD_D

CHECK_ASLLD  LEA ASLLD, A2  *Determine if opcode is ASL.L Data Register

            MOVE.W  A2, D5

            CMP.W   D5, D4

            BEQ     ASLLD_D

CHECK_ASLBI  LEA ASLBI, A2  *Determine if opcode is ASL.B Immediate Value


            MOVE.W  A2, D5

            CMP.W   D5, D4

            BEQ     ASLBI_D

CHECK_ASLWI  LEA ASLWI, A2  *Determine if opcode is ASL.W Immediate Value


            MOVE.W  A2, D5

            CMP.W   D5, D4

            BEQ     ASLWI_D

CHECK_ASLLI  LEA ASLLI, A2  *Determine if opcode is ASL.L Immediate Value

            MOVE.W  A2, D5

            CMP.W   D5, D4

            BEQ     ASLLI_D

*---------------- ASR Data/Immediate --------------------*
CHECK_ASRDIs    LEA   RSDIMASK, A2   *Get Mask

    MOVE.W A2, D3       *Move mask to D3

    MOVE.W (A6), D4  *Get opcode from memory to D4

    AND.W  D3, D4       *Mask Opcode

CHECK_ASRBD  LEA ASRBD, A2  *Determine if opcode is ASR.B Data Register


            MOVE.W  A2, D5

            CMP.W   D5, D4

            BEQ     ASRBD_D

CHECK_ASRWD  LEA ASRWD, A2  *Determine if opcode is ASR.W Data Register


            MOVE.W  A2, D5

            CMP.W   D5, D4

            BEQ     ASRWD_D

CHECK_ASRLD  LEA ASRLD, A2  *Determine if opcode is ASR.L Data Register

            MOVE.W  A2, D5

            CMP.W   D5, D4

            BEQ     ASRLD_D

CHECK_ASRBI  LEA ASRBI, A2  *Determine if opcode is ASR.B Immediate Value


            MOVE.W  A2, D5

            CMP.W   D5, D4

            BEQ     ASRBI_D

CHECK_ASRWI  LEA ASRWI, A2  *Determine if opcode is ASR.W Immediate Value


            MOVE.W  A2, D5

            CMP.W   D5, D4

            BEQ     ASRWI_D

CHECK_ASRLI  LEA ASRLI, A2  *Determine if opcode is ASR.L Immediate Value

            MOVE.W  A2, D5

            CMP.W   D5, D4

            BEQ     ASRLI_D
            
            ADDQ.W    #2, A6      *Go to next instruction
             BRA IFINVADDRMODE  *The opcode is ASdDI, but the addressing modes are incorrect

*---------------- LSL Data/Immediate --------------------*
CHECK_LSdDIs    LEA   GENERAL_RSDI_MASK, A2   *Get General Mask


    MOVE.W A2, D3       *Move mask to D3

    MOVE.W (A6), D4  *Get opcode from memory to D4

    AND.W  D3, D4       *Mask Opcode

    LEA    GENERAL_LSdDI, A2    *Get General LSdDI Opcode

    MOVE.W  A2, D5      *Move GENERAL LSdDI Opcode to D5

    CMP.W   D5, D4      *Compare Opcode with GENERAL LSdDI

    BNE     CHECK_ROdDIs     *If not Equal, Proceed to next instruction (ROdDI)
    
    
* Else, check LSLDI and LSRDI varaints



    LEA   RSDIMASK, A2   *Get Mask

    MOVE.W A2, D3       *Move mask to D3

    MOVE.W (A6), D4  *Get opcode from memory to D4

    AND.W  D3, D4       *Mask Opcode

CHECK_LSLBD  LEA LSLBD, A2  *Determine if opcode is LSL.B Data Register


            MOVE.W  A2, D5

            CMP.W   D5, D4

            BEQ     LSLBD_D

CHECK_LSLWD  LEA LSLWD, A2  *Determine if opcode is LSL.W Data Register


            MOVE.W  A2, D5

            CMP.W   D5, D4

            BEQ     LSLWD_D

CHECK_LSLLD  LEA LSLLD, A2  *Determine if opcode is LSL.L Data Register


            MOVE.W  A2, D5

            CMP.W   D5, D4

            BEQ     LSLLD_D

CHECK_LSLBI  LEA LSLBI, A2  *Determine if opcode is LSL.B Immediate Value

            MOVE.W  A2, D5

            CMP.W   D5, D4

            BEQ     LSLBI_D

CHECK_LSLWI  LEA LSLWI, A2  *Determine if opcode is LSL.W Immediate Value


            MOVE.W  A2, D5

            CMP.W   D5, D4

            BEQ     LSLWI_D

CHECK_LSLLI  LEA LSLLI, A2  *Determine if opcode is LSL.L Immediate Value


            MOVE.W  A2, D5

            CMP.W   D5, D4

            BEQ     LSLLI_D


*---------------- LSR Data/Immediate --------------------*
CHECK_LSRDIs    LEA   RSDIMASK, A2   *Get Mask


    MOVE.W A2, D3       *Move mask to D3

    MOVE.W (A6), D4  *Get opcode from memory to D4

    AND.W  D3, D4       *Mask Opcode

CHECK_LSRBD  LEA LSRBD, A2  *Determine if opcode is LSR.B Data Register


            MOVE.W  A2, D5

            CMP.W   D5, D4

            BEQ     LSRBD_D

CHECK_LSRWD  LEA LSRWD, A2  *Determine if opcode is LSR.W Data Register


            MOVE.W  A2, D5

            CMP.W   D5, D4

            BEQ     LSRWD_D

CHECK_LSRLD  LEA LSRLD, A2  *Determine if opcode is LSR.L Data Register

            MOVE.W  A2, D5

            CMP.W   D5, D4

            BEQ     LSRLD_D

CHECK_LSRBI  LEA LSRBI, A2  *Determine if opcode is LSR.B Immediate Value


            MOVE.W  A2, D5

            CMP.W   D5, D4

            BEQ     LSRBI_D

CHECK_LSRWI  LEA LSRWI, A2  *Determine if opcode is LSR.W Immediate Value

            MOVE.W  A2, D5

            CMP.W   D5, D4

            BEQ     LSRWI_D

CHECK_LSRLI  LEA LSRLI, A2  *Determine if opcode is LSR.L Immediate Value


            MOVE.W  A2, D5

            CMP.W   D5, D4

            BEQ     LSRLI_D
            
            ADDQ.W    #2, A6      *Go to next instruction
             BRA IFINVADDRMODE  *The opcode is LSdDI, but the addressing modes are incorrect

*---------------- ROL Data/Immediate --------------------*
CHECK_ROdDIs    LEA   GENERAL_RSDI_MASK, A2   *Get General Mask


    MOVE.W A2, D3       *Move mask to D3

    MOVE.W (A6), D4  *Get opcode from memory to D4

    AND.W  D3, D4       *Mask Opcode

    LEA    GENERAL_ROdDI, A2    *Get General ROdDI Opcode

    MOVE.W  A2, D5      *Move GENERAL ROdDI Opcode to D5

    CMP.W   D5, D4      *Compare Opcode with GENERAL ROdDI

    BNE     CHECK_ANDs     *If not Equal, Proceed to next instruction (AND)
    
    
* Else, check ROLDI and RORDI varaints



    LEA   RSDIMASK, A2   *Get Mask

    MOVE.W A2, D3       *Move mask to D3

    MOVE.W (A6), D4  *Get opcode from memory to D4

    AND.W  D3, D4       *Mask Opcode

CHECK_ROLBD  LEA ROLBD, A2  *Determine if opcode is ROL.B Data Register


            MOVE.W  A2, D5

            CMP.W   D5, D4

            BEQ     ROLBD_D

CHECK_ROLWD  LEA ROLWD, A2 *Determine if opcode is ROL.W Data Register

            MOVE.W  A2, D5

            CMP.W   D5, D4

            BEQ     ROLWD_D

CHECK_ROLLD  LEA ROLLD, A2  *Determine if opcode is ROL.L Data Register

            MOVE.W  A2, D5

            CMP.W   D5, D4

            BEQ     ROLLD_D

CHECK_ROLBI  LEA ROLBI, A2  *Determine if opcode is ROL.B Immediate Value

            MOVE.W  A2, D5

            CMP.W   D5, D4

            BEQ     ROLBI_D

CHECK_ROLWI  LEA ROLWI, A2  *Determine if opcode is ROL.W Immediate Value

            MOVE.W  A2, D5

            CMP.W   D5, D4

            BEQ     ROLWI_D

CHECK_ROLLI  LEA ROLLI, A2  *Determine if opcode is ROL.L Immediate Value


            MOVE.W  A2, D5

            CMP.W   D5, D4

            BEQ     ROLLI_D

*---------------- ROR Data/Immediate --------------------*
CHECK_RORDIs    LEA   RSDIMASK, A2   *Get Mask

    MOVE.W A2, D3       *Move mask to D3

    MOVE.W (A6), D4  *Get opcode from memory to D4

    AND.W  D3, D4       *Mask Opcode

CHECK_RORBD  LEA RORBD, A2  *Determine if opcode is ROR.B Data Register


            MOVE.W  A2, D5

            CMP.W   D5, D4

            BEQ     RORBD_D

CHECK_RORWD  LEA RORWD, A2  *Determine if opcode is ROR.W Data Register

            MOVE.W  A2, D5

            CMP.W   D5, D4

            BEQ     RORWD_D

CHECK_RORLD  LEA RORLD, A2  *Determine if opcode is ROR.L Data Register


            MOVE.W  A2, D5

            CMP.W   D5, D4

            BEQ     RORLD_D

CHECK_RORBI  LEA RORBI, A2  *Determine if opcode is ROR.B Immediate Value

            MOVE.W  A2, D5

            CMP.W   D5, D4

            BEQ     RORBI_D

CHECK_RORWI  LEA RORWI, A2  *Determine if opcode is ROR.W Immediate Value


            MOVE.W  A2, D5

            CMP.W   D5, D4

            BEQ     RORWI_D

CHECK_RORLI  LEA RORLI, A2  *Determine if opcode is ROR.L Immediate Value

            MOVE.W  A2, D5

            CMP.W   D5, D4

            BEQ     RORLI_D
            
            ADDQ.W    #2, A6      *Go to next instruction
             BRA IFINVADDRMODE  *The opcode is ROdDI, but the addressing modes are incorrect

*---------------- AND --------------------*
CHECK_ANDs    LEA   GENERAL_AND_MASK, A2   *Get General Mask
 
    MOVE.W A2, D3       *Move mask to D3

    MOVE.W (A6), D4  *Get opcode from memory to D4

    AND.W  D3, D4       *Mask Opcode

    LEA    GENERAL_AND, A2    *Get General AND Opcode

    MOVE.W  A2, D5      *Move GENERAL AND Opcode to D5

    CMP.W   D5, D4      *Compare Opcode with GENERAL AND

    BNE     CHECK_ORs     *If not Equal, Proceed to next instruction (OR)
    
    
* Else, check AND varaints



    LEA   ANDORWLIMASK, A2   *Get Mask

    MOVE.W A2, D3       *Move mask to D3

    MOVE.W (A6), D4  *Get opcode from memory to D4

    AND.W  D3, D4

*------------ AND.B Word Address, Long Address, and Immediate Data---*

CHECK_ANDBWAD  LEA ANDBWAD, A2  *Determine if opcode is AND.B Word Address to Data Register


            MOVE.W  A2, D5

            CMP.W   D5, D4

            BEQ     ANDBWAD_D


CHECK_ANDBLAD  LEA ANDBLAD, A2  *Determine if opcode is AND.B Long Address to Data Register

            MOVE.W  A2, D5

            CMP.W   D5, D4

            BEQ     ANDBLAD_D

CHECK_ANDBDWA  LEA ANDBDWA, A2  *Determine if opcode is AND.B Data Register to Word Address

            MOVE.W  A2, D5

            CMP.W   D5, D4

            BEQ     ANDBDWA_D


CHECK_ANDBDLA  LEA ANDBDLA, A2  *Determine if opcode is AND.B Data Register to Long Address


            MOVE.W  A2, D5

            CMP.W   D5, D4

            BEQ     ANDBDLA_D

CHECK_ANDBDAD  LEA ANDBDAD, A2  *Determine if opcode is AND.B Immediate Value to Data Register

            MOVE.W  A2, D5

            CMP.W   D5, D4

            BEQ     ANDBDAD_D

*------------ AND.W Word Address, Long Address, and Immediate Data---*

CHECK_ANDWWAD  LEA ANDWWAD, A2  *Determine if opcode is AND.W Word Address to Data Register

            MOVE.W  A2, D5

            CMP.W   D5, D4

            BEQ     ANDWWAD_D


CHECK_ANDWLAD  LEA ANDWLAD, A2  *Determine if opcode is AND.W Long Address to Data Register

            MOVE.W  A2, D5

            CMP.W   D5, D4

            BEQ     ANDWLAD_D

CHECK_ANDWDWA  LEA ANDWDWA, A2  *Determine if opcode is AND.W Data Register to Word Address


            MOVE.W  A2, D5

            CMP.W   D5, D4

            BEQ     ANDWDWA_D


CHECK_ANDWDLA  LEA ANDWDLA, A2  *Determine if opcode is AND.W Data Register to Long Address


            MOVE.W  A2, D5

            CMP.W   D5, D4

            BEQ     ANDWDLA_D

CHECK_ANDWDAD  LEA ANDWDAD, A2  *Determine if opcode is AND.W Immediate Value to Data Register


            MOVE.W  A2, D5

            CMP.W   D5, D4

            BEQ     ANDWDAD_D

*------------ AND.L Word Address, Long Address, and Immediate Data---*

CHECK_ANDLWAD  LEA ANDLWAD, A2  *Determine if opcode is AND.L Word Address to Data Register

            MOVE.W  A2, D5

            CMP.W   D5, D4

            BEQ     ANDLWAD_D


CHECK_ANDLLAD  LEA ANDLLAD, A2  *Determine if opcode is AND.L Long Address to Data Register

            MOVE.W  A2, D5

            CMP.W   D5, D4

            BEQ     ANDLLAD_D

CHECK_ANDLDWA  LEA ANDLDWA, A2  *Determine if opcode is AND.L Data Register to Word Address

            MOVE.W  A2, D5

            CMP.W   D5, D4

            BEQ     ANDLDWA_D


CHECK_ANDLDLA  LEA ANDLDLA, A2  *Determine if opcode is AND.L Data Register to Long Address

            MOVE.W  A2, D5

            CMP.W   D5, D4

            BEQ     ANDLDLA_D


CHECK_ANDLDAD  LEA ANDLDAD, A2  *Determine if opcode is AND.L Immediate Value to Data Register

            MOVE.W  A2, D5

            CMP.W   D5, D4

            BEQ     ANDLDAD_D

            BRA     CHECK_ANDsCONT      *Move on to the rest of AND

*---------------- OR --------------------*
CHECK_ORs    LEA   GENERAL_OR_MASK, A2   *Get General Mask

    MOVE.W A2, D3       *Move mask to D3

    MOVE.W (A6), D4  *Get opcode from memory to D4

    AND.W  D3, D4       *Mask Opcode

    LEA    GENERAL_OR, A2    *Get General OR Opcode

    MOVE.W  A2, D5      *Move GENERAL OR Opcode to D5

    CMP.W   D5, D4      *Compare Opcode with GENERAL OR

    BNE     CHECK_NOP     *If not Equal, Proceed to next instruction (NOP)
    
    
* Else, check OR varaints



    LEA   ANDORWLIMASK, A2   *Get Mask

    MOVE.W A2, D3       *Move mask to D3

    MOVE.W (A6), D4  *Get opcode from memory to D4

    AND.W  D3, D4

*------------ OR.B Word Address, Long Address, and Immediate Data---*

CHECK_ORBWAD  LEA ORBWD, A2 *Determine if opcode is OR.B Word Address to Data Register

            MOVE.W  A2, D5

            CMP.W   D5, D4

            BEQ     ORBWAD_D


CHECK_ORBLAD  LEA ORBLD, A2 *Determine if opcode is OR.B Long Address to Data Register

            MOVE.W  A2, D5

            CMP.W   D5, D4

            BEQ     ORBLAD_D

CHECK_ORBDWA  LEA ORBDW, A2 *Determine if opcode is OR.B Data Register to Word Address

            MOVE.W  A2, D5

            CMP.W   D5, D4

            BEQ     ORBDWA_D


CHECK_ORBDLA  LEA ORBDL, A2 *Determine if opcode is OR.B Data Register to Long Address

            MOVE.W  A2, D5

            CMP.W   D5, D4

            BEQ     ORBDLA_D

CHECK_ORBDID  LEA ORBID, A2 *Determine if opcode is OR.B Immediate Value to Data Register

            MOVE.W  A2, D5

            CMP.W   D5, D4

            BEQ     ORBDID_D

*------------ OR.W Word Address, Long Address, and Immediate Data---*

CHECK_ORWWAD  LEA ORWWD, A2 *Determine if opcode is OR.W Word Address to Data Register

            MOVE.W  A2, D5

            CMP.W   D5, D4

            BEQ     ORWWAD_D


CHECK_ORWLAD  LEA ORWLD, A2 *Determine if opcode is OR.W Long Address to Data Register

            MOVE.W  A2, D5

            CMP.W   D5, D4

            BEQ     ORWLAD_D

CHECK_ORWDWA  LEA ORWDW, A2 *Determine if opcode is OR.W Data Register to Word Address

            MOVE.W  A2, D5

            CMP.W   D5, D4

            BEQ     ORWDWA_D


CHECK_ORWDLA  LEA ORWDL, A2 *Determine if opcode is OR.W Data Register to Long Address

            MOVE.W  A2, D5

            CMP.W   D5, D4

            BEQ     ORWDLA_D

CHECK_ORWDID  LEA ORWID, A2 *Determine if opcode is OR.W Immediate Value to Data Register

            MOVE.W  A2, D5

            CMP.W   D5, D4

            BEQ     ORWDID_D

*------------ OR.L Word Address, Long Address, and Immediate Data---*

CHECK_ORLWAD  LEA ORLWD, A2 *Determine if opcode is OR.L Word Address to Data Register

            MOVE.W  A2, D5

            CMP.W   D5, D4

            BEQ     ORLWAD_D


CHECK_ORLLAD  LEA ORLLD, A2 *Determine if opcode is OR.L Long Address to Data Register

            MOVE.W  A2, D5

            CMP.W   D5, D4

            BEQ     ORLLAD_D

CHECK_ORLDWA  LEA ORLDW, A2 *Determine if opcode is OR.L Data Register to Word Address

            MOVE.W  A2, D5

            CMP.W   D5, D4

            BEQ     ORLDWA_D


CHECK_ORLDLA  LEA ORLDL, A2 *Determine if opcode is OR.L Data Register to Long Address

            MOVE.W  A2, D5

            CMP.W   D5, D4

            BEQ     ORLDLA_D


CHECK_ORLDID  LEA ORLID, A2 *Determine if opcode is OR.L Immediate Value to Data Register

            MOVE.W  A2, D5

            CMP.W   D5, D4

            BEQ     ORLDID_D
            
            BRA     CHECK_ORsCONT       *Move on to the rest of OR

*---------------- AND CONTINUED --------------------*
CHECK_ANDsCONT    LEA   ANDORMASK, A2   *Get Mask

    MOVE.W A2, D3       *Move mask to D3

    MOVE.W (A6), D4  *Get opcode from memory to D4

    AND.W  D3, D4


*------------ AND.B Registers---*

CHECK_ANDBDD  LEA ANDBDD, A2    *Determine if opcode is AND.B Data Register to Data Register

            MOVE.W  A2, D5

            CMP.W   D5, D4

            BEQ     ANDBDD_D

CHECK_ANDBAID  LEA ANDBAID, A2  *Determine if opcode is AND.B Indirect Address Register to Data Register

            MOVE.W  A2, D5

            CMP.W   D5, D4

            BEQ     ANDBAID_D

CHECK_ANDBAPID  LEA ANDBAPID, A2    *Determine if opcode is AND.B Post Increment Address Register to Data Register

            MOVE.W  A2, D5

            CMP.W   D5, D4

            BEQ     ANDBAPID_D

CHECK_ANDBAPDD  LEA ANDBAPDD, A2    *Determine if opcode is AND.B Pre Decrement Address Register to Data Register

            MOVE.W  A2, D5

            CMP.W   D5, D4

            BEQ     ANDBAPDD_D

CHECK_ANDBDAI  LEA ANDBDAI, A2  *Determine if opcode is AND.B Data Register to Indirect Address Register

            MOVE.W  A2, D5

            CMP.W   D5, D4

            BEQ     ANDBDAI_D

CHECK_ANDBDAPI  LEA ANDBDAPI, A2    *Determine if opcode is AND.B Data Register to Post Increment Address Register

            MOVE.W  A2, D5

            CMP.W   D5, D4

            BEQ     ANDBDAPI_D

CHECK_ANDBDAPD  LEA ANDBDAPD, A2    *Determine if opcode is AND.B Data Register to Pre Decrement Address Register

            MOVE.W  A2, D5

            CMP.W   D5, D4

            BEQ     ANDBDAPD_D

*------------ AND.W Registers---*

CHECK_ANDWDD  LEA ANDWDD, A2    *Determine if opcode is AND.W Data Register to Data Register

            MOVE.W  A2, D5

            CMP.W   D5, D4

            BEQ     ANDWDD_D

CHECK_ANDWAID  LEA ANDWAID, A2  *Determine if opcode is AND.W Indirect Address Register to Data Register

            MOVE.W  A2, D5

            CMP.W   D5, D4

            BEQ     ANDWAID_D

CHECK_ANDWAPID  LEA ANDWAPID, A2    *Determine if opcode is AND.W Post Increment Address Register to Data Register

            MOVE.W  A2, D5

            CMP.W   D5, D4

            BEQ     ANDWAPID_D

CHECK_ANDWAPDD  LEA ANDWAPDD, A2    *Determine if opcode is AND.W Pre Decrement Address Register to Data Register

            MOVE.W  A2, D5

            CMP.W   D5, D4

            BEQ     ANDWAPDD_D

CHECK_ANDWDAI  LEA ANDWDAI, A2      *Determine if opcode is AND.W Data Register to Indirect Address Register

            MOVE.W  A2, D5

            CMP.W   D5, D4

            BEQ     ANDWDAI_D

CHECK_ANDWDAPI  LEA ANDWDAPI, A2    *Determine if opcode is AND.W Data Register to Post Increment Address Register

            MOVE.W  A2, D5

            CMP.W   D5, D4

            BEQ     ANDWDAPI_D

CHECK_ANDWDAPD  LEA ANDWDAPD, A2    *Determine if opcode is AND.W Data Register to Pre Decrement Address Register

            MOVE.W  A2, D5

            CMP.W   D5, D4

            BEQ     ANDWDAPD_D

*------------ AND.L Registers---*

CHECK_ANDLDD  LEA ANDLDD, A2    *Determine if opcode is AND.L Data Register to Data Register

            MOVE.W  A2, D5

            CMP.W   D5, D4

            BEQ     ANDLDD_D

CHECK_ANDLAID  LEA ANDLAID, A2  *Determine if opcode is AND.L Indirect Address Register to Data Register

            MOVE.W  A2, D5

            CMP.W   D5, D4

            BEQ     ANDLAID_D

CHECK_ANDLAPID  LEA ANDLAPID, A2    *Determine if opcode is AND.L Post Increment Address Register to Data Register

            MOVE.W  A2, D5

            CMP.W   D5, D4

            BEQ     ANDLAPID_D

CHECK_ANDLAPDD  LEA ANDLAPDD, A2    *Determine if opcode is AND.L Pre Decrement Register to Data Register

            MOVE.W  A2, D5

            CMP.W   D5, D4

            BEQ     ANDLAPDD_D

CHECK_ANDLDAI  LEA ANDLDAI, A2      *Determine if opcode is AND.L Data Register to Indirect Address Register

            MOVE.W  A2, D5

            CMP.W   D5, D4

            BEQ     ANDLDAI_D

CHECK_ANDLDAPI  LEA ANDLDAPI, A2    *Determine if opcode is AND.L Data Register to Post Increment Address Register

            MOVE.W  A2, D5

            CMP.W   D5, D4

            BEQ     ANDLDAPI_D

CHECK_ANDLDAPD  LEA ANDLDAPD, A2    *Determine if opcode is AND.L Data Register to Pre Decrement Address Register

            MOVE.W  A2, D5

            CMP.W   D5, D4

            BEQ     ANDLDAPD_D
            
            ADDQ.W    #2, A6      *Go to next instruction
             BRA IFINVADDRMODE  *The opcode is AND, but the addressing modes are incorrect


*---------------- OR CONTINUED --------------------*
CHECK_ORsCONT    LEA   ANDORMASK, A2   *Get Mask

    MOVE.W A2, D3       *Move mask to D3

    MOVE.W (A6), D4  *Get opcode from memory to D4

    AND.W  D3, D4


*------------ OR.B Registers---*

CHECK_ORBDD  LEA ORBDD, A2  *Determine if opcode is OR.B Data Register to Data Register

            MOVE.W  A2, D5

            CMP.W   D5, D4

            BEQ     ORBDD_D

CHECK_ORBAID  LEA ORBAID, A2    *Determine if opcode is OR.B Indirect Address Register to Data Register

            MOVE.W  A2, D5

            CMP.W   D5, D4

            BEQ     ORBAID_D

CHECK_ORBAPD  LEA ORBAPD, A2    *Determine if opcode is OR.B Post Increment Address Register to Data Register

            MOVE.W  A2, D5

            CMP.W   D5, D4

            BEQ     ORBAPD_D

CHECK_ORBADD  LEA ORBADD, A2    *Determine if opcode is OR.B Pre Decrement Address Register to Data Register

            MOVE.W  A2, D5

            CMP.W   D5, D4

            BEQ     ORBADD_D

CHECK_ORBDAI  LEA ORBDAI, A2    *Determine if opcode is OR.B Data Register to Indirect Address Register

            MOVE.W  A2, D5

            CMP.W   D5, D4

            BEQ     ORBDAI_D

CHECK_ORBDAP  LEA ORBDAP, A2    *Determine if opcode is OR.B Data Register to Post Increment Address Register

            MOVE.W  A2, D5

            CMP.W   D5, D4

            BEQ     ORBDAP_D

CHECK_ORBDAD  LEA ORBDAD, A2    *Determine if opcode is OR.B Data Register to Pre Decrement Address Register

            MOVE.W  A2, D5

            CMP.W   D5, D4

            BEQ     ORBDAD_D

*------------ OR.W Registers---*

CHECK_ORWDD  LEA ORWDD, A2      *Determine if opcode is OR.W Data Register to Data Register

            MOVE.W  A2, D5

            CMP.W   D5, D4

            BEQ     ORWDD_D

CHECK_ORWAID  LEA ORWAID, A2    *Determine if opcode is OR.W Indirect Address Register to Data Register

            MOVE.W  A2, D5

            CMP.W   D5, D4

            BEQ     ORWAID_D

CHECK_ORWAPD  LEA ORWAPD, A2    *Determine if opcode is OR.W Post Increment Address Register to Data Register

            MOVE.W  A2, D5

            CMP.W   D5, D4

            BEQ     ORWAPD_D

CHECK_ORWADD  LEA ORWADD, A2    *Determine if opcode is OR.W Pre Decrement Register to Data Register

            MOVE.W  A2, D5

            CMP.W   D5, D4

            BEQ     ORWADD_D

CHECK_ORWDAI  LEA ORWDAI, A2    *Determine if opcode is OR.W Data Register to Indirect Address Register

            MOVE.W  A2, D5

            CMP.W   D5, D4

            BEQ     ORWDAI_D

CHECK_ORWDAP  LEA ORWDAP, A2    *Determine if opcode is OR.W Data Register to Post Increment Address Register

            MOVE.W  A2, D5

            CMP.W   D5, D4

            BEQ     ORWDAP_D

CHECK_ORWDAD  LEA ORWDAD, A2    *Determine if opcode is OR.W Data Register to Pre Decrement Address Register

            MOVE.W  A2, D5

            CMP.W   D5, D4

            BEQ     ORWDAD_D

*------------ OR.L Registers---*

CHECK_ORLDD  LEA ORLDD, A2  *Determine if opcode is OR.L Data Register to Data Register

            MOVE.W  A2, D5

            CMP.W   D5, D4

            BEQ     ORLDD_D

CHECK_ORLAID  LEA ORLAID, A2    *Determine if opcode is OR.L Indirect Address Register to Data Register

            MOVE.W  A2, D5

            CMP.W   D5, D4

            BEQ     ORLAID_D

CHECK_ORLAPD  LEA ORLAPD, A2    *Determine if opcode is OR.L Post Increment Address Register to Data Register

            MOVE.W  A2, D5

            CMP.W   D5, D4

            BEQ     ORLAPD_D

CHECK_ORLADD  LEA ORLADD, A2    *Determine if opcode is OR.L Pre Decrement Address Register to Data Register

            MOVE.W  A2, D5

            CMP.W   D5, D4

            BEQ     ORLADD_D

CHECK_ORLDAI  LEA ORLDAI, A2    *Determine if opcode is OR.L Data Register to Indirect Address Register

            MOVE.W  A2, D5

            CMP.W   D5, D4

            BEQ     ORLDAI_D

CHECK_ORLDAP  LEA ORLDAP, A2    *Determine if opcode is OR.L Data Register to Post Increment Address Register

            MOVE.W  A2, D5

            CMP.W   D5, D4

            BEQ     ORLDAP_D

CHECK_ORLDAD  LEA ORLDAD, A2    *Determine if opcode is OR.L Data Register to Pre Decrement Address Register

            MOVE.W  A2, D5

            CMP.W   D5, D4

            BEQ     ORLDAD_D
            
            ADDQ.W    #2, A6      *Go to next instruction
             BRA IFINVADDRMODE  *The opcode is OR, but the addressing modes are incorrect

*---------------- NOP and RTS --------------------* Note: there is no GENERAL code for NOP and RTS because there is no invalid addressing modes
CHECK_NOP    LEA   NOPCO, A2   *Get Mask

    MOVE.W (A6), D4  *Get opcode from memory to D4

    MOVE.W  A2, D5

    CMP.W   D5, D4  *Determine if opcode is NOP

    BEQ     NOP_D

CHECK_RTS    LEA   RTSCO, A2   *Get Mask

    MOVE.W (A6), D4  *Get opcode from memory to D4

    MOVE.W  A2, D5

    CMP.W   D5, D4  *Determine if opcode is RTS

    BEQ     RTS_D

*---------------- LEA --------------------*

CHECKLEAs   LEA   GENERAL_LEA_MASK, A2   *Get General Mask

    MOVE.W A2, D3       *Move mask to D3

    MOVE.W (A6), D4  *Get opcode from memory to D4

    AND.W  D3, D4       *Mask Opcode

    LEA    GENERAL_LEA, A2    *Get General LEA Opcode

    MOVE.W  A2, D5      *Move GENERAL LEA Opcode to D5

    CMP.W   D5, D4      *Compare Opcode with GENERAL LEA

    BNE     CHECK_NOTs     *If not Equal, Proceed to next instruction (NOT)
    
    
* Else, check LEA varaints

    *Absolute Addressing Mask
    LEA   LEAAAMASK, A2   *Mask
    
    MOVE.W A2, D3       *Move mask to D3
    
    MOVE.W (A6),D4  *Get opcode from memory to D4
    
    AND.W  D3, D4       *Mask Opcode


CHECKLEAWA    LEA    LEAWA, A2    *Get BRA Opcode
    
    MOVE.W  A2, D5      *Move BRA Opcode to D5
    
    CMP.W   D5, D4      *Compare Opcode with BRA
    
    BEQ     LEAWA_D     *If Equal, Proceed
    
CHECKLEALA    LEA    LEALA, A2    *Get LEA Long Address Opcode
    
    MOVE.W  A2, D5      *Move BRA Opcode to D5
    
    CMP.W   D5, D4      *Compare Opcode with BRA
    
    BEQ     LEALA_D     *If Equal, Proceed


    LEA   LEAMASK, A2   *Mask
    
    MOVE.W A2, D3       *Move mask to D3
    
    MOVE.W (A6),D4  *Get opcode from memory to D4
    
    AND.W  D3, D4       *Mask Opcode

    
CHECKLEAAI    LEA    LEAAI, A2    *Get LEA Indirect address Opcode
    
    MOVE.W  A2, D5      *Move BRA Opcode to D5
    
    CMP.W   D5, D4      *Compare Opcode with BRA
    
    BEQ     LEAAI_D     *If Equal, Proceed
    
    
    
    ADDQ.W    #2, A6      *Go to next instruction
     BRA IFINVADDRMODE  *The opcode is LEA, but the addressing modes are incorrect
     
     
*---------------- NOT --------------------*
CHECK_NOTs    LEA   GENERAL_NOT_MASK, A2   *Get General Mask

    MOVE.W A2, D3       *Move mask to D3

    MOVE.W (A6), D4  *Get opcode from memory to D4

    AND.W  D3, D4       *Mask Opcode

    LEA    GENERAL_NOT, A2    *Get General NOT Opcode

    MOVE.W  A2, D5      *Move GENERAL NOT Opcode to D5

    CMP.W   D5, D4      *Compare Opcode with GENERAL NOT

    BNE     DATA_B     *If not Equal, Proceed to next instruction (DATA)
    
    
* Else, check NOT varaints
*Absolute addressing and immediate data 
    LEA   NOTAAMASK, A2   *Get AA Mask

    MOVE.W A2, D3       *Move mask to D3

    MOVE.W (A6), D4  *Get opcode from memory to D4

    AND.W  D3, D4       *Mask Opcode

CHECK_NOTBWA LEA NOTBWA , A2   *NOTB Word Address              
            MOVE.W  A2, D5
            
            CMP.W   D5, D4
            
            BEQ     NOTBWA_D

CHECK_NOTBLA LEA NOTBLA, A2   *NOTB Long Address   
            
            MOVE.W  A2, D5
            
            CMP.W   D5, D4
            
            BEQ     NOTBLA_D

CHECK_NOTWWA LEA NOTWWA, A2      *NOTW Word Address              
            MOVE.W  A2, D5
            
            CMP.W   D5, D4
            
            BEQ     NOTWWA_D

CHECK_NOTWLA LEA NOTWLA, A2      *NOTW Long Address            
            MOVE.W  A2, D5
            
            CMP.W   D5, D4
            
            BEQ     NOTWLA_D

CHECK_NOTLWA LEA NOTLWA, A2      *NOTL Word Address             
            MOVE.W  A2, D5
            
            CMP.W   D5, D4
            
 LEA ADDBWD, A1 *ADD  byte xxx.w to Dn
 MOVE.L A1, D5
  MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ ADDWWD_D
 
 LEA ADDWWD, A1 *ADD  word xxx.w to Dn
 MOVE.L A1, D5
  MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ ADDWWD_D
 
 LEA ADDLWD, A1 *ADD  Long xxx.w to Dn
 MOVE.L A1, D5
  MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ ADDLWD_D
 
 LEA ADDBLD, A1 *ADD  byte xxx.L to Dn
 MOVE.L A1, D5
  MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ ADDWWD_D
 
 LEA ADDWLD, A1 *ADD  word xxx.L to Dn
 MOVE.L A1, D5
  MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ ADDWLD_D
 
 LEA ADDLLD, A1 *ADD  Long xxx.L to Dn
 MOVE.L A1, D5
  MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ ADDLLD_D
    
      

CHECK_NOTLLA LEA NOTLLA, A2      *NOTL Long Address              
            MOVE.W  A2, D5
            
            CMP.W   D5, D4
            
            BEQ     NOTLLA_D



*The Rest
    LEA   NOTMASK, A2   *Get Mask

    MOVE.W A2, D3       *Move mask to D3

    MOVE.W (A6),D4  *Get opcode from memory to D4

    AND.W  D3, D4   *Mask D3 and D4

            
            
      
*---------------- NOT.B EA--------------------*
CHECK_NOTBD LEA NOTBDR, A2     *NOTB Data register         
            MOVE.W  A2, D5
            
            CMP.W   D5, D4
            
            BEQ     NOTBD_D

CHECK_NOTBAI LEA NOTBAI , A2   *NOTB Indirect Address        
            MOVE.W  A2, D5
            
            CMP.W   D5, D4
            
            BEQ     NOTBAI_D

CHECK_NOTBPO LEA NOTBP , A2   *NOTB Post Increment              
            MOVE.W  A2, D5
            
            CMP.W   D5, D4
            
            BEQ     NOTBPO_D

CHECK_NOTBPR LEA NOTBD , A2    *NOTB pre Decrement         
            MOVE.W  A2, D5
            
            CMP.W   D5, D4
            
            BEQ     NOTBPR_D



*---------------- NOT.W EA--------------------*
CHECK_NOTWD LEA NOTWDR , A2      *NOTW Data Register           
            MOVE.W  A2, D5
            
            CMP.W   D5, D4
            
            BEQ     NOTWD_D

CHECK_NOTWAI LEA NOTWAI , A2      *NOTW Indirect Address             
            MOVE.W  A2, D5
            
            CMP.W   D5, D4
            
            BEQ     NOTWAI_D

CHECK_NOTWPO LEA NOTWP , A2      *NOTW Post Increment 
            
            MOVE.W  A2, D5
            
            CMP.W   D5, D4
            
            BEQ     NOTWPO_D

CHECK_NOTWPR LEA NOTWP , A2      *NOTW Pre Decrement             
            MOVE.W  A2, D5
            
            CMP.W   D5, D4
            
            BEQ     NOTWPR_D


*---------------- NOT.L EA--------------------*
CHECK_NOTLD LEA NOTLDR, A2      *NOTL Data Register              
            MOVE.W  A2, D5
            
            CMP.W   D5, D4
            
            BEQ     NOTLD_D

CHECK_NOTLAI LEA NOTLAI, A2      *NOTL Indirect Address             
            MOVE.W  A2, D5
            
            CMP.W   D5, D4
            
            BEQ     NOTLAI_D

CHECK_NOTLPO LEA NOTLP, A2      *NOTL Post Increment  
            
            MOVE.W  A2, D5
            
            CMP.W   D5, D4
            
            BEQ     NOTLPO_D

CHECK_NOTLPR LEA NOTLD, A2      *NOTL Pre Decrement              
            MOVE.W  A2, D5
            
            CMP.W   D5, D4
            
            BEQ     NOTLPR_D

            
            ADDQ.W    #2, A6      *Go to next instruction
             BRA IFINVADDRMODE  *The opcode is NOT, but the addressing modes are incorrect



DATA_B    BRA     DATA_D  *No opcodes match, Go to Data



*----------- GENERAL DECODERS -------------*
BASIC_SOURCE_REG_D MOVE.W  #$0007, D3   *Mask for register

            MOVE.W  (A6)+, D6   *Move opcode to D6 and set A6 to next instruction

            AND.W   D3, D6      *Mask Opcode to get register

            RTS

BASIC_SOURCE_WA_D  ADDQ.W  #2, A6   *Move Pointer (A6) to word operand

            MOVE.W  (A6)+, D6       *Move word operand to D6 and set A6 to next instruction

            RTS

BASIC_SOURCE_LA_D  ADDQ.L  #2, A6   *Move A6 to Long operand

            MOVE.L  (A6)+, D6       * Move Long operand to D6 and set A6 to next instruction

            RTS

BASIC_IMMEDATA_BW_D ADDQ.W  #2, A6  *Move A6 to word-sized immediate value

            MOVE.W  (A6)+, D6       *Move word-sized immediate value to D6 and set A6 to next instruction

            RTS


BASIC_IMMEDATA_L_D ADDQ.L  #2, A6   *Move A6 to long-sized immediate value

            MOVE.L  (A6)+, D6       *Move long-sized immediate value to D6 and set A6 to next instruction

            RTS

*NOTE: These three are not to be used when the source is either a Word address, Long address, or immediate data

BASIC_DEST_REG_D MOVE.W  #$0007, D3 *Mask for register

            MOVE.W  (A6)+, D7   *Move opcode to D7 and set A6 to next instruction

            AND.W   D3, D7  *Mask Opcode to get register

            RTS

BASIC_DEST_WA_D  ADDQ.W    #2, A6   *Move Pointer (A6) to word operand

            MOVE.W  (A6)+, D7       *Move word operand to D7 and set A6 to next instruction

            RTS

BASIC_DEST_LA_D  ADDQ.L    #2, A6   *Move A6 to Long operand

            MOVE.L  (A6)+, D7       * Move Long operand to D7 and set A6 to next instruction

            RTS




ADVANCED_DECODER_2:
   CLR.L D3
   NOP
 MOVE.B #2, D3 
 NOP
 ADDA D3, A6
 NOP
 MOVE.L (A6), D6
  
 MOVE.B #4, D3
 NOP 
 ADDA.W D3, A6
 NOP
 MOVE.L (A6), D7
  NOP
  SUBA #4, A6
  RTS
  

ADVANCED_DECODER_IM_L:

 MOVE.B #2, D3 
 NOP
 ADDA D3, A6
 NOP
 MOVE.L (A6), D6
 LSR.L #8, D6
 LSR.L #8, D6
 NOP 
 MOVE.L (A6), D7
 MOVE.B #16, D4
  NOP
  * (haydn) This is really dumb but I dont care at this point its 11:00pm
  LSL.L D4, D7
  LSR.L D4, D7
  SUBA #2, A6
  RTS

ADVANCED_DECODER_IM:
 MOVE.B #2, D3 
 NOP
 ADDA D3, A6
 NOP
 MOVE.L (A6), D6
 LSR.L #8, D6
 LSR.L #8, D6
 NOP 
 MOVE.L (A6), D7
 MOVE.B #16, D4
  NOP
  * (haydn) This is really dumb but I dont care at this point its 11:00pm
  LSL.L D4, D7
  LSR.L D4, D7
  SUBA #2, A6
  RTS

  
* If we have immidiate data in the instruction, 
* we need to figure out how long the immidiate data is
* for this to work make sure the offset is in D5
* after this subroutine the instruction address will 
* increase by a certain number, 
CALC_ADDR_OFFSET:

  ADD.L D5, A6
 RTS
 
ADVANCED_DECODER:*Mask again to get the operands, the last operand is stored in D6, and the first operand is in D7* 
   
 MOVE.B #16, D1 * we need to shift right 16 bits so the instruction lines up with the mask
 MOVE.L D2, D6 * get a copy of the instruction
 NOP
 MOVE.L D2, D7  * get a copy of the instruction
 NOP
 *first op*
 *LSR.L D1, D7   * align it
 MOVE.L A2, D5 * move our first data mask 
 NOP
 AND.L D5, D6  * mask it
 
*last op*
 MOVE.B #16, D1 * we need to shift right 16 bits to line stuff up
 * LSR.L D1, D6   * align it
 MOVE.L A3, D5 * move our second data mask 
 NOP
 AND.L D5, D7  * mask it
  MOVE.B #9, D1 * we need to shift right 10 bits so the first operand ends at the LSB
    LSR.L D1, D7   * align it

 MOVE.B #2, D0 
 ADDA D0, A6
 NOP
 MOVE.W (A6), D6
 SUBA D0, A6
 RTS

ADVANCED_DECODER_L:*Mask again to get the operands, the last operand is stored in D6, and the first operand is in D7* 
 MOVE.B #16, D1 * we need to shift right 16 bits so the instruction lines up with the mask
 MOVE.L D2, D6 * get a copy of the instruction
 NOP
 MOVE.L D2, D7  * get a copy of the instruction
 NOP
 *first op*
 *LSR.L D1, D7   * align it
 MOVE.L A2, D5 * move our first data mask 
 NOP
 AND.L D5, D6  * mask it
 
*last op*
 MOVE.B #16, D1 * we need to shift right 16 bits to line stuff up
 * LSR.L D1, D6   * align it
 MOVE.L A3, D5 * move our second data mask 
 NOP
 AND.L D5, D6  * mask it
  MOVE.B #9, D1 * we need to shift right 10 bits so the first operand ends at the LSB
    LSR.L D1, D7   * align it

 MOVE.B #2, D0 
 ADDA D0, A6
 NOP
 MOVE.L (A6), D7
  SUBA D0, A6
 RTS


AQ_DECODER:
*Mask again to get the operands, the last operand is stored in D6, and the first operand is in D7*
 
 MOVE.B #16, D1 * we need to shift right 16 bits so the instruction lines up with the mask
 MOVE.L D2, D6 * get a copy of the instruction
 NOP
 MOVE.L D2, D7  * get a copy of the instruction
 NOP
 *first op*
 *LSR.L D1, D7   * align it
 MOVE.L A2, D5 * move our first data mask 
 NOP
 AND.L D5, D6  * mask it
 *last op*
 
 MOVE.B #16, D1 * we need to shift right 16 bits to line stuff up

 MOVE.L A3, D5 * move our second data mask 
 NOP
 AND.L D5, D7  * mask it
  MOVE.B #9, D1 * we need to shift right 12 bits so the data ends at the LSB
    LSR.L D1, D7   * align it
    MOVE.B #0, D3
   CMP.B D6, D3 * if the data bits are 0 that means we have 8. 000 is reserved for 8 which is really weird lol. If we dont have 000 we can just go to the output
   ADDQ #2, A6 
   BLT OUTPUT
   MOVE.B #8, D7
 BRA OUTPUT

MQ_DECODER:
*Mask again to get the operands, the last operand is stored in D6, and the first operand is in D7*
 
 MOVE.B #16, D1 * we need to shift right 16 bits so the instruction lines up with the mask
 MOVE.L D2, D6 * get a copy of the instruction
 NOP
 MOVE.L D2, D7  * get a copy of the instruction
 NOP
 *first op*
 *LSR.L D1, D7   * align it
 MOVE.L A2, D5 * move our first data mask 
 NOP
 AND.L D5, D6  * mask it
 *last op*
 
 MOVE.B #16, D1 * we need to shift right 16 bits to line stuff up

 MOVE.L A3, D5 * move our second data mask 
 NOP
 AND.L D5, D7  * mask it
  MOVE.B #9, D1 * we need to shift right 10 bits so the first operand ends at the LSB
    LSR.L D1, D7   * align it
 ADDQ #2, A6 
 RTS


BASIC_DECODER:
*Mask again to get the operands, the last operand is stored in D6, and the first operand is in D7*
  MOVE.B #16, D1 * we need to shift right 16 bits so the instruction lines up with the mask
 MOVE.L D2, D6 * get a copy of the instruction
 NOP
 MOVE.L D2, D7  * get a copy of the instruction
 NOP
 *first op*
 *LSR.L D1, D7   * align it
 MOVE.L A2, D5 * move our first data mask 
 NOP
 AND.L D5, D6  * mask it
 *last op*
 
 MOVE.B #16, D1 * we need to shift right 16 bits to line stuff up

 MOVE.L A3, D5 * move our second data mask 
 NOP
 AND.L D5, D7  * mask it
  MOVE.B #9, D1 * we need to shift right 10 bits so the first operand ends at the LSB
    LSR.L D1, D7   * align it
 ADDQ #2, A6 
 RTS






*----------- DECODERS -------------*
SOURCE_REG_D MOVE.W  #$0007, D3   *Mask for register

            MOVE.W  (A6)+, D6   *Move opcode to D6 and set A6 to next instruction
        
            AND.W   D3, D6      *Mask Opcode to get register
            
            RTS

SOURCE_WA_D  ADDQ.W  #2, A6   *Move Pointer (A6) to word operand

            MOVE.W  (A6)+, D6       *Move word operand to D6 and set A6 to next instruction
            
            RTS
            
SOURCE_LA_D  ADDQ.L  #2, A6   *Move A6 to Long operand

            MOVE.L  (A6)+, D6       * Move Long operand to D6 and set A6 to next instruction
            
            RTS
            
            
SOURCE_DREG_D MOVE.W  (A6), D6    *Move opcode to D6

            MOVE.W  #$0E00, D3          *Mask for source
            
            AND.W   D3, D6              *Mask opcode
                        
            ROL.W   #7, D6              *Rotate opcode to get correct value
            
            
            RTS


DEST_DREG_D   MOVE.W  (A6), D7    *Move opcode to D7

            MOVE.W  #$0E00, D3          *Mask for destination
            
            AND.W   D3, D7              *Mask opcode
                        
            ROL.W   #7, D7              *Rotate opcode to get correct value
            
            
            RTS
            
DEST_REG_D MOVE.W  #$0007, D3 *Mask for register

            MOVE.W  (A6)+, D7   *Move opcode to D7 and set A6 to next instruction
        
            AND.W   D3, D7  *Mask Opcode to get register
            
            RTS
            
 



BASIC_BCC_D MOVE.W (A6)+, D6    *Move opcode to D6 and set A6 to next instruction

            MOVEA.W  A6, A3     *Save current address to A3

            MOVE.W  #$00FF, D3  *Set up mask

            AND.W   D3, D6      *Mask D6 to get displacement value

            CMP.B   #$00, D6    *If least significant byte is $00, then the displacement is in the next word

            BEQ     WDIS        *Decode word displacement

            CMP.B   #$FF, D6    *If least significant byte is $FF, then the displacement is in the next long

            BEQ     LDIS        *Decode Long displacement

            ADD.W   A3, D6      *Add current address to displacement to get branching address.

            RTS

WDIS        MOVE.W (A6)+, D6    *Move word displacement to D6 and set A6 to next instruction

            ADD.W   A3, D6      *Add current address to displacement to get branching address.

            RTS

LDIS        MOVE.L (A6)+, D6    *Move long displacement to D6 and set A6 to next instruction

            ADD.L   A3, D6      *Add current address to displacement to get branching address.

            RTS

*----------- General Decoder for Rotate/Shift Data/Immediate---*
BASIC_RSData_D MOVE.W  (A6)+, D2    *Move opcode to D2 and set A6 to next instruction

            MOVE.W  #$0E07, D3      *Prepare register mask

            AND.W   D3, D2          *Mask opcode

            MOVE.B  D2, D7          *Move destination operand to D7

            ROL.W   #7, D2          *Rotate opcode to get source operand

            MOVE.B  #$07, D3        *prepare source mask

            AND.B   D3, D2          *mask opcode

            MOVE.B  D2, D6          *Move source operand to D6

            RTS

BASIC_RSImmediate_D MOVE.W  (A6)+, D2   *Move opcode to D2 and set A6 to next instruction

            MOVE.W  #$0E07, D3          *Prepare register mask

            AND.W   D3, D2              *Mask opcode

            MOVE.B  D2, D7              *Move destination operand to D7

            ROL.W   #7, D2              *Rotate opcode to get source operand

            MOVE.B  #$07, D3            *prepare source mask

            AND.B   D3, D2              *mask opcode

            CMP.B   #$00, D2            *Check if the source is $00

            BEQ     PRINT8              *If the source is $00, then source is 8

            MOVE.B  D2, D6              *Move source operand to D6

            RTS

PRINT8      MOVE.B  #$08, D6            *Move 8 to D6

            RTS

*-------- General Decoder for data register for AND and OR

BASIC_SOURCE_DREG_D MOVE.W  (A6), D6    *Move opcode to D6

            MOVE.W  #$0E00, D3          *Mask for source

            AND.W   D3, D6              *Mask opcode

            ROL.W   #7, D6              *Rotate opcode to get correct value


            RTS


BASIC_DEST_DREG_D   MOVE.W  (A6), D7    *Move opcode to D7

            MOVE.W  #$0E00, D3          *Mask for destination

            AND.W   D3, D7              *Mask opcode

            ROL.W   #7, D7              *Rotate opcode to get correct value


            RTS


*---------------- LEA Variants-------------*
LEAAI_D BSR DEST_DREG_D
        BSR SOURCE_REG_D *Decode LEA Indirect Address to Address Register
        
        
        BRA IFLEAAIXA      *Print LEA and operands


LEAWA_D BSR DEST_DREG_D
        BSR SOURCE_WA_D  *Decode LEA Indirect Address to Address Register
        

        BRA IFLEAAAXA      *Print LEA and operands


LEALA_D BSR DEST_DREG_D
        BSR SOURCE_LA_D  *Decode LEA Indirect Address to Address Register
        


        BRA IFLEAAAXA       *Print LEA and operands
         

*---------------- NOT Variants --------------------*
            
NOTBD_D BSR SOURCE_DREG_D     *Decode NOT.B Data Register

            BRA IFNOTBEAXD      *Print NOT.B and operand
            
NOTWD_D BSR SOURCE_DREG_D     *Decode NOT.W Data Register

            BRA IFNOTWEAXD      *Print NOT.B and operand
            
NOTLD_D BSR SOURCE_DREG_D     *Decode NOT.L Data Register
 
            BRA IFNOTLEAXD      *Print NOT.L and operand
            
NOTBAI_D  BSR SOURCE_REG_D *Decode NOT.B Indirect Address
           
            BRA IFNOTBEAXAI     *Print NOT.B and operand
   
NOTWAI_D BSR SOURCE_REG_D *Decode NOT.W Data Register

            BRA IFNOTWEAXAI     *Print NOT.W and operand
            
NOTLAI_D  BSR SOURCE_REG_D *Decode NOT.L Data Register
            
            BRA IFNOTLEAXAI     *Print NOT.L and operand
            
NOTBPO_D   BSR SOURCE_REG_D *Decode NOT.B Post increment

            BRA IFNOTBEAXPO     *Print NOT.B and operand
            
NOTWPO_D   BSR SOURCE_REG_D *Decode NOT.W Post increment

            BRA IFNOTWEAXPO     *Print NOT.W and operand
            
NOTLPO_D     BSR SOURCE_REG_D *Decode NOT.L Post increment

            BRA IFNOTLEAXPO     *Print NOT.L and operand
            
NOTBPR_D    BSR SOURCE_REG_D *Decode NOT.B Post decrement

            BRA IFNOTBEAXPR     *Print NOT.B and operand
            
NOTWPR_D    BSR SOURCE_REG_D *Decode NOT.W Post decrement

            BRA IFNOTWEAXPR     *Print NOT.W and operand
            
NOTLPR_D     BSR SOURCE_REG_D *Decode NOT.L Post decrement
            
            BRA IFNOTLEAXPR     *Print NOT.L and operand
            
NOTBWA_D    BSR SOURCE_WA_D *Decode NOT.B Word address
            
            BRA IFNOTBEA        *Print NOT.B and operand
            
NOTWWA_D    BSR SOURCE_WA_D *Decode NOT.W Word address
            
            BRA IFNOTWEA        *Print NOT.W and operand
            
NOTLWA_D    BSR SOURCE_WA_D *Decode NOT.L Word address
            
            BRA IFNOTLEA        *Print NOT.L and operand
            
NOTBLA_D    BSR SOURCE_LA_D *Decode NOT.B Long address
            
            BRA IFNOTBEA        *Print NOT.B and operand
            
NOTWLA_D    BSR SOURCE_LA_D *Decode NOT.W Long address
            
            BRA IFNOTWEA        *Print NOT.W and operand
            
NOTLLA_D    BSR SOURCE_LA_D *Decode NOT.L Long address
            
            BRA IFNOTLEA        *Print NOT.L and operand


*---------------- BCC Variants-------------*
BRA_D     BSR BASIC_BCC_D   *Decode BRA operand
          
          BRA   IFBRA    *Print BRA and operand
          

BEQ_D     BSR   BASIC_BCC_D *Decode BEQ operand
          
          BRA   IFBEQ     *Print BEQ and operand
          

BGT_D       BSR BASIC_BCC_D *Decode BGT operand
            
            BRA IFBGT   *Print BGT and operand

BLE_D       BSR BASIC_BCC_D *Decode BLE operand
            
            BRA IFBLE   *Print BLE and operand
            


*---------------- JSR Variants-------------*
JSRAI_D BSR BASIC_SOURCE_REG_D  *Decode JSR Indirect Address Register Operand

        BRA IFJSRAXAI     *Print JSR and operand


JSRWA_D BSR BASIC_SOURCE_WA_D   *Decode JSR Word Address Operand

        BRA IFJSREA     *Print JSR and operand


JSRLA_D BSR BASIC_SOURCE_LA_D   *Decode JSR Long Address Operand

         BRA IFJSREA     *Print JSR and operand


*------------ ASL Variants --------------*
ASLAI_D   BSR BASIC_SOURCE_REG_D    *Decode ASL Indirect Address Register Operand

          BRA   IFASLEAXAI      *Print ASL and operand
          
ASLBAI_D   BSR BASIC_SOURCE_REG_D    *Decode ASL Indirect Address Register Operand

          BRA   IFASLBEAXAI      *Print ASL and operand

ASLWAI_D   BSR BASIC_SOURCE_REG_D    *Decode ASL Indirect Address Register Operand

          BRA   IFASLWEAXAI      *Print ASL and operand

ASLLAI_D   BSR BASIC_SOURCE_REG_D    *Decode ASL Indirect Address Register Operand

          BRA   IFASLLEAXAI      *Print ASL and operand


ASLPI_D   BSR BASIC_SOURCE_REG_D    *Decode ASL Post Increment Address Register Operand

          BRA   IFASLEAXPO      *Print ASL and operand
          
ASLBPI_D   BSR BASIC_SOURCE_REG_D    *Decode ASL Post Increment Address Register Operand

          BRA   IFASLBEAXPO      *Print ASL and operand
          
ASLWPI_D   BSR BASIC_SOURCE_REG_D    *Decode ASL Post Increment Address Register Operand

          BRA   IFASLWEAXPO      *Print ASL and operand
          
ASLLPI_D   BSR BASIC_SOURCE_REG_D    *Decode ASL Post Increment Address Register Operand

          BRA   IFASLLEAXPO      *Print ASL and operand

ASLPD_D   BSR BASIC_SOURCE_REG_D    *Decode ASL Pre Decrement Address Register Operand

          BRA   IFASLEAXPR      *Print ASL and operand
          
ASLBPD_D   BSR BASIC_SOURCE_REG_D    *Decode ASL Pre Decrement Address Register Operand

          BRA   IFASLBEAXPR      *Print ASL and operand
          
ASLWPD_D   BSR BASIC_SOURCE_REG_D    *Decode ASL Pre Decrement Address Register Operand

          BRA   IFASLWEAXPR      *Print ASL and operand
          
ASLLPD_D   BSR BASIC_SOURCE_REG_D    *Decode ASL Pre Decrement Address Register Operand

          BRA   IFASLLEAXPR      *Print ASL and operand

ASLWA_D   BSR BASIC_SOURCE_WA_D     *Decode ASL Word Address Operand

          BRA   IFASLEA         *Print ASL and operand
          
ASLBWA_D   BSR BASIC_SOURCE_WA_D     *Decode ASL Word Address Operand

          BRA   IFASLBEA         *Print ASL and operand
          
ASLWWA_D   BSR BASIC_SOURCE_WA_D     *Decode ASL Word Address Operand

          BRA   IFASLWEA         *Print ASL and operand
          
ASLLWA_D   BSR BASIC_SOURCE_WA_D     *Decode ASL Word Address Operand

          BRA   IFASLLEA         *Print ASL and operand

ASLLA_D   BSR BASIC_SOURCE_LA_D *Decode ASL Long Address Operand

          BRA   IFASLEA         *Print ASL and operand
          
ASLBLA_D   BSR BASIC_SOURCE_LA_D *Decode ASL Long Address Operand

          BRA   IFASLBEA         *Print ASL and operand
          
ASLWLA_D   BSR BASIC_SOURCE_LA_D *Decode ASL Long Address Operand

          BRA   IFASLWEA         *Print ASL and operand
          
ASLLLA_D   BSR BASIC_SOURCE_LA_D *Decode ASL Long Address Operand

          BRA   IFASLLEA         *Print ASL and operand

ASLBD_D   BSR BASIC_RSData_D    *Decode ASL.B Data Register Operand

          BRA   IFASLBDXD     *Print ASL.B and operands

ASLWD_D   BSR BASIC_RSData_D    *Decode ASL.W Data Register Operand

          BRA   IFASLWDXD       *Print ASL.W and operands
          
ASLLD_D   BSR BASIC_RSData_D    *Decode ASL.L Data Register Operand

          BRA   IFASLLDXD       *Print ASL.L and operands

ASLBI_D   BSR BASIC_RSImmediate_D   *Decode ASL.B Immediate Value Operand

          BRA   IFASLBIXD       *Print ASL.B and operands

ASLWI_D   BSR BASIC_RSImmediate_D   *Decode ASL.W Immediate Value Operand

          BRA   IFASLWIXD       *Print ASL.W and operands

ASLLI_D   BSR BASIC_RSImmediate_D   *Decode ASL.L Immediate Value Operand

          BRA   IFASLLIXD       *Print ASL.L and operands



*------------ ASR Variants --------------*
ASRAI_D   BSR BASIC_SOURCE_REG_D    *Decode ASR Indirect Address Register Operand

          BRA   IFASREAXAI      *Print ASR and operand
          
ASRBAI_D   BSR BASIC_SOURCE_REG_D    *Decode ASR Indirect Address Register Operand

          BRA   IFASRBEAXAI      *Print ASR and operand

ASRWAI_D   BSR BASIC_SOURCE_REG_D    *Decode ASR Indirect Address Register Operand

          BRA   IFASRWEAXAI      *Print ASR and operand

ASRLAI_D   BSR BASIC_SOURCE_REG_D    *Decode ASR Indirect Address Register Operand

          BRA   IFASRLEAXAI      *Print ASR and operand


ASRPI_D   BSR BASIC_SOURCE_REG_D    *Decode ASR Post Increment Address Register Operand

          BRA   IFASREAXPO      *Print ASR and operand
          
ASRBPI_D   BSR BASIC_SOURCE_REG_D    *Decode ASR Post Increment Address Register Operand

          BRA   IFASRBEAXPO      *Print ASR and operand
          
ASRWPI_D   BSR BASIC_SOURCE_REG_D    *Decode ASR Post Increment Address Register Operand

          BRA   IFASRWEAXPO      *Print ASR and operand
          
ASRLPI_D   BSR BASIC_SOURCE_REG_D    *Decode ASR Post Increment Address Register Operand

          BRA   IFASRLEAXPO      *Print ASR and operand

ASRPD_D   BSR BASIC_SOURCE_REG_D    *Decode ASR Pre Decrement Address Register Operand

          BRA   IFASREAXPR      *Print ASR and operand
          
ASRBPD_D   BSR BASIC_SOURCE_REG_D    *Decode ASR Pre Decrement Address Register Operand

          BRA   IFASRBEAXPR      *Print ASR and operand
          
ASRWPD_D   BSR BASIC_SOURCE_REG_D    *Decode ASR Pre Decrement Address Register Operand

          BRA   IFASRWEAXPR      *Print ASR and operand
          
ASRLPD_D   BSR BASIC_SOURCE_REG_D    *Decode ASR Pre Decrement Address Register Operand

          BRA   IFASRLEAXPR      *Print ASR and operand

ASRWA_D   BSR BASIC_SOURCE_WA_D     *Decode ASR Word Address Operand

          BRA   IFASREA         *Print ASR and operand
          
ASRBWA_D   BSR BASIC_SOURCE_WA_D     *Decode ASR Word Address Operand

          BRA   IFASRBEA         *Print ASR and operand
          
ASRWWA_D   BSR BASIC_SOURCE_WA_D     *Decode ASR Word Address Operand

          BRA   IFASRWEA         *Print ASR and operand
          
ASRLWA_D   BSR BASIC_SOURCE_WA_D     *Decode ASR Word Address Operand

          BRA   IFASRLEA         *Print ASR and operand

ASRLA_D   BSR BASIC_SOURCE_LA_D *Decode ASR Long Address Operand

          BRA   IFASREA         *Print ASR and operand
          
ASRBLA_D   BSR BASIC_SOURCE_LA_D *Decode ASR Long Address Operand

          BRA   IFASRBEA         *Print ASR and operand
          
ASRWLA_D   BSR BASIC_SOURCE_LA_D *Decode ASR Long Address Operand

          BRA   IFASRWEA         *Print ASR and operand
          
ASRLLA_D   BSR BASIC_SOURCE_LA_D *Decode ASR Long Address Operand

          BRA   IFASRLEA         *Print ASR and operand

ASRBD_D   BSR BASIC_RSData_D        *Decode ASR.B Data Register Operand

          BRA   IFASRBDXD       *Print ASR.B and operands

ASRWD_D   BSR BASIC_RSData_D        *Decode ASR.W Data Register Operand

          BRA   IFASRWDXD       *Print ASR.W and operands
          
ASRLD_D   BSR BASIC_RSData_D        *Decode ASR.L Data Register Operand

          BRA   IFASRLDXD       *Print ASR.L and operands

ASRBI_D   BSR BASIC_RSImmediate_D   *Decode ASR.B Immediate Value Operand

          BRA   IFASRBIXD       *Print ASR.B and operands

ASRWI_D   BSR BASIC_RSImmediate_D   *Decode ASR.W Immediate Value Operand

          BRA   IFASRWIXD       *Print ASR.W and operands

ASRLI_D   BSR BASIC_RSImmediate_D   *Decode ASR.L Immediate Value Operand

          BRA   IFASRLIXD       *Print ASR.L and operands


*------------ LSL Variants --------------*
LSLAI_D   BSR BASIC_SOURCE_REG_D    *Decode ASL Indirect Address Register Operand

          BRA   IFLSLEAXAI      *Print ASL and operand
          
LSLBAI_D   BSR BASIC_SOURCE_REG_D    *Decode ASL Indirect Address Register Operand

          BRA   IFLSLBEAXAI      *Print ASL and operand

LSLWAI_D   BSR BASIC_SOURCE_REG_D    *Decode ASL Indirect Address Register Operand

          BRA   IFLSLWEAXAI      *Print ASL and operand

LSLLAI_D   BSR BASIC_SOURCE_REG_D    *Decode ASL Indirect Address Register Operand

          BRA   IFLSLLEAXAI      *Print ASL and operand


LSLPI_D   BSR BASIC_SOURCE_REG_D    *Decode ASL Post Increment Address Register Operand

          BRA   IFLSLEAXPO      *Print ASL and operand
          
LSLBPI_D   BSR BASIC_SOURCE_REG_D    *Decode ASL Post Increment Address Register Operand

          BRA   IFLSLBEAXPO      *Print ASL and operand
          
LSLWPI_D   BSR BASIC_SOURCE_REG_D    *Decode ASL Post Increment Address Register Operand

          BRA   IFLSLWEAXPO      *Print ASL and operand
          
LSLLPI_D   BSR BASIC_SOURCE_REG_D    *Decode LSL Post Increment Address Register Operand

          BRA   IFLSLLEAXPO      *Print LSL and operand

LSLPD_D   BSR BASIC_SOURCE_REG_D    *Decode LSL Pre Decrement Address Register Operand

          BRA   IFLSLEAXPR      *Print LSL and operand
          
LSLBPD_D   BSR BASIC_SOURCE_REG_D    *Decode LSL Pre Decrement Address Register Operand

          BRA   IFLSLBEAXPR      *Print LSL and operand
          
LSLWPD_D   BSR BASIC_SOURCE_REG_D    *Decode LSL Pre Decrement Address Register Operand

          BRA   IFLSLWEAXPR      *Print LSL and operand
          
LSLLPD_D   BSR BASIC_SOURCE_REG_D    *Decode LSL Pre Decrement Address Register Operand

          BRA   IFLSLLEAXPR      *Print LSL and operand

LSLWA_D   BSR BASIC_SOURCE_WA_D     *Decode LSL Word Address Operand

          BRA   IFLSLEA         *Print LSL and operand
          
LSLBWA_D   BSR BASIC_SOURCE_WA_D     *Decode LSL Word Address Operand

          BRA   IFLSLBEA         *Print LSL and operand
          
LSLWWA_D   BSR BASIC_SOURCE_WA_D     *Decode LSL Word Address Operand

          BRA   IFLSLWEA         *Print LSL and operand
          
LSLLWA_D   BSR BASIC_SOURCE_WA_D     *Decode LSL Word Address Operand

          BRA   IFLSLLEA         *Print LSL and operand

LSLLA_D   BSR BASIC_SOURCE_LA_D *Decode LSL Long Address Operand

          BRA   IFLSLEA         *Print LSL and operand
          
LSLBLA_D   BSR BASIC_SOURCE_LA_D *Decode LSL Long Address Operand

          BRA   IFLSLBEA         *Print LSL and operand
          
LSLWLA_D   BSR BASIC_SOURCE_LA_D *Decode LSL Long Address Operand

          BRA   IFLSLWEA         *Print LSL and operand
          
LSLLLA_D   BSR BASIC_SOURCE_LA_D *Decode LSL Long Address Operand

          BRA   IFLSLLEA         *Print LSL and operand

LSLBD_D   BSR BASIC_RSData_D        *Decode LSL.B Data Register Operand

          BRA   IFLSLBDXD       *Print LSL.B and operands

LSLWD_D   BSR BASIC_RSData_D        *Decode LSL.W Data Register Operand

          BRA   IFLSLWDXD       *Print LSL.W and operands
          
LSLLD_D   BSR BASIC_RSData_D        *Decode LSL.L Data Register Operand

          BRA   IFLSLLDXD       *Print LSL.L and operands

LSLBI_D   BSR BASIC_RSImmediate_D   *Decode LSL.B Immediate Value Operand

          BRA   IFLSLBIXD       *Print LSL.B and operands

LSLWI_D   BSR BASIC_RSImmediate_D   *Decode LSL.W Immediate Value Operand

          BRA   IFLSLWIXD       *Print LSL.W and operands

LSLLI_D   BSR BASIC_RSImmediate_D   *Decode LSL.L Immediate Value Operand

          BRA   IFLSLLIXD       *Print LSL.L and operands


*------------ LSR Variants --------------*
LSRAI_D   BSR BASIC_SOURCE_REG_D    *Decode ASL Indirect Address Register Operand

          BRA   IFLSREAXAI      *Print ASL and operand
          
LSRBAI_D   BSR BASIC_SOURCE_REG_D    *Decode ASL Indirect Address Register Operand

          BRA   IFLSRBEAXAI      *Print ASL and operand

LSRWAI_D   BSR BASIC_SOURCE_REG_D    *Decode ASL Indirect Address Register Operand

          BRA   IFLSRWEAXAI      *Print ASL and operand

LSRLAI_D   BSR BASIC_SOURCE_REG_D    *Decode ASL Indirect Address Register Operand

          BRA   IFLSRLEAXAI      *Print ASL and operand


LSRPI_D   BSR BASIC_SOURCE_REG_D    *Decode ASL Post Increment Address Register Operand

          BRA   IFLSREAXPO      *Print ASL and operand
          
LSRBPI_D   BSR BASIC_SOURCE_REG_D    *Decode ASL Post Increment Address Register Operand

          BRA   IFLSRBEAXPO      *Print ASL and operand
          
LSRWPI_D   BSR BASIC_SOURCE_REG_D    *Decode ASL Post Increment Address Register Operand

          BRA   IFLSRWEAXPO      *Print ASL and operand
          
LSRLPI_D   BSR BASIC_SOURCE_REG_D    *Decode ASL Post Increment Address Register Operand

          BRA   IFLSRLEAXPO      *Print ASL and operand

LSRPD_D   BSR BASIC_SOURCE_REG_D    *Decode ASL Pre Decrement Address Register Operand

          BRA   IFLSREAXPR      *Print ASL and operand
          
LSRBPD_D   BSR BASIC_SOURCE_REG_D    *Decode ASL Pre Decrement Address Register Operand

          BRA   IFLSRBEAXPR      *Print ASL and operand
          
LSRWPD_D   BSR BASIC_SOURCE_REG_D    *Decode ASL Pre Decrement Address Register Operand

          BRA   IFLSRWEAXPR      *Print ASL and operand
          
LSRLPD_D   BSR BASIC_SOURCE_REG_D    *Decode ASL Pre Decrement Address Register Operand

          BRA   IFLSRLEAXPR      *Print ASL and operand

LSRWA_D   BSR BASIC_SOURCE_WA_D     *Decode ASL Word Address Operand

          BRA   IFLSREA         *Print ASL and operand
          
LSRBWA_D   BSR BASIC_SOURCE_WA_D     *Decode ASL Word Address Operand

          BRA   IFLSRBEA         *Print ASL and operand
          
LSRWWA_D   BSR BASIC_SOURCE_WA_D     *Decode ASL Word Address Operand

          BRA   IFLSRWEA         *Print ASL and operand
          
LSRLWA_D   BSR BASIC_SOURCE_WA_D     *Decode ASL Word Address Operand

          BRA   IFLSRLEA         *Print ASL and operand

LSRLA_D   BSR BASIC_SOURCE_LA_D *Decode ASL Long Address Operand

          BRA   IFLSREA         *Print ASL and operand
          
LSRBLA_D   BSR BASIC_SOURCE_LA_D *Decode ASL Long Address Operand

          BRA   IFLSRBEA         *Print ASL and operand
          
LSRWLA_D   BSR BASIC_SOURCE_LA_D *Decode ASL Long Address Operand

          BRA   IFLSRWEA         *Print ASL and operand
          
LSRLLA_D   BSR BASIC_SOURCE_LA_D *Decode ASL Long Address Operand

          BRA   IFLSRLEA         *Print ASL and operand
          
LSRBD_D   BSR BASIC_RSData_D        *Decode LSR.B Data Register Operand

          BRA   IFLSRBDXD       *Print LSR.B and operands

LSRWD_D   BSR BASIC_RSData_D        *Decode LSR.W Data Register Operand

          BRA   IFLSRWDXD       *Print LSR.W and operands
          
LSRLD_D   BSR BASIC_RSData_D        *Decode LSR.L Data Register Operand

          BRA   IFLSRLDXD       *Print LSR.L and operands

LSRBI_D   BSR BASIC_RSImmediate_D   *Decode LSR.B Immediate Value Operand

          BRA   IFLSRBIXD       *Print LSR.B and operands

LSRWI_D   BSR BASIC_RSImmediate_D   *Decode LSR.W Immediate Value Operand

          BRA   IFLSRWIXD       *Print LSR.W and operands

LSRLI_D   BSR BASIC_RSImmediate_D   *Decode LSR.L Immediate Value Operand

          BRA   IFLSRLIXD       *Print LSR.L and operands


*------------ ROL Variants --------------*
ROLAI_D   BSR BASIC_SOURCE_REG_D    *Decode ASL Indirect Address Register Operand

          BRA   IFROLEAXAI      *Print ASL and operand
          
ROLBAI_D   BSR BASIC_SOURCE_REG_D    *Decode ASL Indirect Address Register Operand

          BRA   IFROLBEAXAI      *Print ASL and operand

ROLWAI_D   BSR BASIC_SOURCE_REG_D    *Decode ASL Indirect Address Register Operand

          BRA   IFROLWEAXAI      *Print ASL and operand

ROLLAI_D   BSR BASIC_SOURCE_REG_D    *Decode ASL Indirect Address Register Operand

          BRA   IFROLLEAXAI      *Print ASL and operand


ROLPI_D   BSR BASIC_SOURCE_REG_D    *Decode ASL Post Increment Address Register Operand

          BRA   IFROLEAXPO      *Print ASL and operand
          
ROLBPI_D   BSR BASIC_SOURCE_REG_D    *Decode ASL Post Increment Address Register Operand

          BRA   IFROLBEAXPO      *Print ASL and operand
          
ROLWPI_D   BSR BASIC_SOURCE_REG_D    *Decode ASL Post Increment Address Register Operand

          BRA   IFROLWEAXPO      *Print ASL and operand
          
ROLLPI_D   BSR BASIC_SOURCE_REG_D    *Decode ASL Post Increment Address Register Operand

          BRA   IFROLLEAXPO      *Print ASL and operand

ROLPD_D   BSR BASIC_SOURCE_REG_D    *Decode ASL Pre Decrement Address Register Operand

          BRA   IFROLEAXPR      *Print ASL and operand
          
ROLBPD_D   BSR BASIC_SOURCE_REG_D    *Decode ASL Pre Decrement Address Register Operand

          BRA   IFROLBEAXPR      *Print ASL and operand
          
ROLWPD_D   BSR BASIC_SOURCE_REG_D    *Decode ASL Pre Decrement Address Register Operand

          BRA   IFROLWEAXPR      *Print ASL and operand
          
ROLLPD_D   BSR BASIC_SOURCE_REG_D    *Decode ASL Pre Decrement Address Register Operand

          BRA   IFROLLEAXPR      *Print ASL and operand

ROLWA_D   BSR BASIC_SOURCE_WA_D     *Decode ASL Word Address Operand

          BRA   IFROLEA         *Print ASL and operand
          
ROLBWA_D   BSR BASIC_SOURCE_WA_D     *Decode ASL Word Address Operand

          BRA   IFROLBEA         *Print ASL and operand
          
ROLWWA_D   BSR BASIC_SOURCE_WA_D     *Decode ASL Word Address Operand

          BRA   IFROLWEA         *Print ASL and operand
          
ROLLWA_D   BSR BASIC_SOURCE_WA_D     *Decode ASL Word Address Operand

          BRA   IFROLLEA         *Print ASL and operand

ROLLA_D   BSR BASIC_SOURCE_LA_D *Decode ASL Long Address Operand

          BRA   IFROLEA         *Print ASL and operand
          
ROLBLA_D   BSR BASIC_SOURCE_LA_D *Decode ASL Long Address Operand

          BRA   IFROLBEA         *Print ASL and operand
          
ROLWLA_D   BSR BASIC_SOURCE_LA_D *Decode ASL Long Address Operand

          BRA   IFROLWEA         *Print ASL and operand
          
ROLLLA_D   BSR BASIC_SOURCE_LA_D *Decode ASL Long Address Operand

          BRA   IFROLLEA         *Print ASL and operand

ROLBD_D   BSR BASIC_RSData_D        *Decode ROL.B Data Register Operand

          BRA   IFROLBDXD       *Print ROL.B and operands

ROLWD_D   BSR BASIC_RSData_D        *Decode ROL.W Data Register Operand

          BRA   IFROLWDXD       *Print ROL.W and operands
          
ROLLD_D   BSR BASIC_RSData_D        *Decode ROL.L Data Register Operand

          BRA   IFROLLDXD       *Print ROL.L and operands

ROLBI_D   BSR BASIC_RSImmediate_D   *Decode ROL.B Immediate Value Operand

          BRA   IFROLBIXD       *Print ROL.B and operands

ROLWI_D   BSR BASIC_RSImmediate_D   *Decode ROL.W Immediate Value Operand

          BRA   IFROLWIXD       *Print ROL.W and operands

ROLLI_D   BSR BASIC_RSImmediate_D   *Decode ROL.L Immediate Value Operand

          BRA   IFROLLIXD       *Print ROL.L and operands


*------------ ROR Variants --------------*
RORAI_D   BSR BASIC_SOURCE_REG_D    *Decode ASL Indirect Address Register Operand

          BRA   IFROREAXAI      *Print ASL and operand
          
RORBAI_D   BSR BASIC_SOURCE_REG_D    *Decode ASL Indirect Address Register Operand

          BRA   IFRORBEAXAI      *Print ASL and operand

RORWAI_D   BSR BASIC_SOURCE_REG_D    *Decode ASL Indirect Address Register Operand

          BRA   IFRORWEAXAI      *Print ASL and operand

RORLAI_D   BSR BASIC_SOURCE_REG_D    *Decode ASL Indirect Address Register Operand

          BRA   IFRORLEAXAI      *Print ASL and operand


RORPI_D   BSR BASIC_SOURCE_REG_D    *Decode ASL Post Increment Address Register Operand

          BRA   IFROREAXPO      *Print ASL and operand
          
RORBPI_D   BSR BASIC_SOURCE_REG_D    *Decode ASL Post Increment Address Register Operand

          BRA   IFRORBEAXPO      *Print ASL and operand
          
RORWPI_D   BSR BASIC_SOURCE_REG_D    *Decode ASL Post Increment Address Register Operand

          BRA   IFRORWEAXPO      *Print ASL and operand
          
RORLPI_D   BSR BASIC_SOURCE_REG_D    *Decode ASL Post Increment Address Register Operand

          BRA   IFRORLEAXPO      *Print ASL and operand

RORPD_D   BSR BASIC_SOURCE_REG_D    *Decode ASL Pre Decrement Address Register Operand

          BRA   IFROREAXPR      *Print ASL and operand
          
RORBPD_D   BSR BASIC_SOURCE_REG_D    *Decode ASL Pre Decrement Address Register Operand

          BRA   IFRORBEAXPR      *Print ASL and operand
          
RORWPD_D   BSR BASIC_SOURCE_REG_D    *Decode ASL Pre Decrement Address Register Operand

          BRA   IFRORWEAXPR      *Print ASL and operand
          
RORLPD_D   BSR BASIC_SOURCE_REG_D    *Decode ASL Pre Decrement Address Register Operand

          BRA   IFRORLEAXPR      *Print ASL and operand

RORWA_D   BSR BASIC_SOURCE_WA_D     *Decode ASL Word Address Operand

          BRA   IFROREA         *Print ASL and operand
          
RORBWA_D   BSR BASIC_SOURCE_WA_D     *Decode ASL Word Address Operand

          BRA   IFRORBEA         *Print ASL and operand
          
RORWWA_D   BSR BASIC_SOURCE_WA_D     *Decode ASL Word Address Operand

          BRA   IFRORWEA         *Print ASL and operand
          
RORLWA_D   BSR BASIC_SOURCE_WA_D     *Decode ASL Word Address Operand

          BRA   IFRORLEA         *Print ASL and operand

RORLA_D   BSR BASIC_SOURCE_LA_D *Decode ASL Long Address Operand

          BRA   IFROREA         *Print ASL and operand
          
RORBLA_D   BSR BASIC_SOURCE_LA_D *Decode ASL Long Address Operand

          BRA   IFRORBEA         *Print ASL and operand
          
RORWLA_D   BSR BASIC_SOURCE_LA_D *Decode ASL Long Address Operand

          BRA   IFRORWEA         *Print ASL and operand
          
RORLLA_D   BSR BASIC_SOURCE_LA_D *Decode ASL Long Address Operand

          BRA   IFRORLEA         *Print ASL and operand

RORBD_D   BSR BASIC_RSData_D        *Decode ROR.B Data Register Operand

          BRA   IFRORBDXD       *Print ROR.B and operands

RORWD_D   BSR BASIC_RSData_D        *Decode ROR.W Data Register Operand

          BRA   IFRORWDXD       *Print ROR.W and operands
          
RORLD_D   BSR BASIC_RSData_D        *Decode ROR.L Data Register Operand

          BRA   IFRORLDXD       *Print ROR.L and operands

RORBI_D   BSR BASIC_RSImmediate_D   *Decode ROR.B Immediate Value Operand

          BRA   IFRORBIXD       *Print ROR.B and operands

RORWI_D   BSR BASIC_RSImmediate_D   *Decode ROR.W Immediate Value Operand

          BRA   IFRORWIXD       *Print ROR.W and operands

RORLI_D   BSR BASIC_RSImmediate_D   *Decode ROR.L Immediate Value Operand

          BRA   IFRORLIXD       *Print ROR.L and operands





*---------------- AND Variants-------------*

*AND.B Variants
ANDBDD_D    BSR BASIC_DEST_DREG_D   *Decode AND.B Data Register to Data Register

            BSR BASIC_SOURCE_REG_D


            BRA IFANDBDXD       *Print AND.B and operands


ANDBAID_D   BSR BASIC_DEST_DREG_D   *Decode AND.B Indirect Address Register to Data Register

            BSR BASIC_SOURCE_REG_D


            BRA IFANDBAIXD      *Print AND.B and operands


ANDBAPID_D  BSR BASIC_DEST_DREG_D   *Decode AND.B Post Increment Address Register to Data Register

            BSR BASIC_SOURCE_REG_D


            BRA IFANDBPOXD      *Print AND.B and operands


ANDBAPDD_D BSR BASIC_DEST_DREG_D    *Decode AND.B Pre Decrement Address Register to Data Register

            BSR BASIC_SOURCE_REG_D


            BRA IFANDBPRXD      *Print AND.B and operands


ANDBDAI_D   BSR BASIC_SOURCE_DREG_D     *Decode AND.B Data Register to Indirect Address Register

            BSR BASIC_DEST_REG_D

            BRA IFANDBDXAI      *Print AND.B and operands


ANDBDAPI_D  BSR BASIC_SOURCE_DREG_D     *Decode AND.B Data Register to Post Increment Address Register

            BSR BASIC_DEST_REG_D

            BRA IFANDBDXPO      *Print AND.B and operands
            

ANDBDAPD_D  BSR BASIC_SOURCE_DREG_D     *Decode AND.B Data Register to Pre Decrement Address Register

            BSR BASIC_DEST_REG_D

            BRA IFANDBDXPR      *Print AND.B and operands


ANDBWAD_D   BSR BASIC_DEST_DREG_D       *Decode AND.B Word Address to Data Register

            BSR BASIC_SOURCE_WA_D


            BRA IFANDBAAXD      *Print AND.B and operands
            

ANDBLAD_D   BSR BASIC_DEST_DREG_D       *Decode AND.B Long Address to Data Register

            BSR BASIC_SOURCE_LA_D

            BRA IFANDBAAXD      *Print AND.B and operands
            

ANDBDWA_D   BSR BASIC_SOURCE_DREG_D     *Decode AND.B Data Register to Word Address

            BSR BASIC_DEST_WA_D

            BRA IFANDBDXAA      *Print AND.B and operands

ANDBDLA_D   BSR BASIC_SOURCE_DREG_D     *Decode AND.B Data Register to Long Address

            BSR BASIC_DEST_LA_D

            BRA IFANDBDXAA      *Print AND.B and operands

ANDBDAD_D   BSR BASIC_DEST_DREG_D       *Decode AND.B Immediate Value to Data Register

            BSR BASIC_IMMEDATA_BW_D

            BRA IFANDBIXD       *Print AND.B and operands

*AND.W Variants
ANDWDD_D    BSR BASIC_DEST_DREG_D       *Decode AND.W Data Register to Data Register

            BSR BASIC_SOURCE_REG_D


            BRA IFANDWDXD       *Print AND.W and operands


ANDWAID_D   BSR BASIC_DEST_DREG_D       *Decode AND.W Indirect Address Register to Data Register

            BSR BASIC_SOURCE_REG_D


            BRA IFANDWAIXD      *Print AND.W and operands


ANDWAPID_D  BSR BASIC_DEST_DREG_D       *Decode AND.W Post Increment Address Register to Data Register

            BSR BASIC_SOURCE_REG_D


            BRA IFANDWPOXD      *Print AND.W and operands


ANDWAPDD_D  BSR BASIC_DEST_DREG_D       *Decode AND.W Pre Decrement Address Register to Data Register

            BSR BASIC_SOURCE_REG_D


            BRA IFANDWPRXD      *Print AND.W and operands


ANDWDAI_D   BSR BASIC_SOURCE_DREG_D     *Decode AND.W Data Register to Indirect Address Register

            BSR BASIC_DEST_REG_D

            BRA IFANDWDXAI      *Print AND.W and operands

ANDWDAPI_D  BSR BASIC_SOURCE_DREG_D     *Decode AND.W Data Register to Post Increment Address Register

            BSR BASIC_DEST_REG_D

            BRA IFANDWPOXD       *Print AND.W and operands

ANDWDAPD_D  BSR BASIC_SOURCE_DREG_D     *Decode AND.W Data Register to Pre Decrement Address Register

            BSR BASIC_DEST_REG_D

            BRA IFANDWPRXD      *Print AND.W and operands

ANDWWAD_D   BSR BASIC_DEST_DREG_D       *Decode AND.W Word Address to Data Register

            BSR BASIC_SOURCE_WA_D

            BRA IFANDWAAXD      *Print AND.W and operands

ANDWLAD_D   BSR BASIC_DEST_DREG_D       *Decode AND.W Long Address to Data Register

            BSR BASIC_SOURCE_LA_D

            BRA IFANDWAAXD      *Print AND.W and operands

ANDWDWA_D   BSR BASIC_SOURCE_DREG_D     *Decode AND.W Data Register to Word Address

            BSR BASIC_DEST_WA_D

            BRA IFANDWDXAA      *Print AND.W and operands

ANDWDLA_D   BSR BASIC_SOURCE_DREG_D     *Decode AND.W Data Register to Long Address

            BSR BASIC_DEST_LA_D

            BRA IFANDWDXAA      *Print AND.W and operands

ANDWDAD_D   BSR BASIC_DEST_DREG_D       *Decode AND.W Immediate Value to Data Register

            BSR BASIC_IMMEDATA_BW_D

            BRA IFANDWIXD       *Print AND.W and operands


*AND.L Variants
ANDLDD_D    BSR BASIC_DEST_DREG_D       *Decode AND.L Data Register to Data Register

            BSR BASIC_SOURCE_REG_D


            BRA IFANDLDXD       *Print AND.L and operands


ANDLAID_D   BSR BASIC_DEST_DREG_D       *Decode AND.L Indirect Address Register to Data Register

            BSR BASIC_SOURCE_REG_D


            BRA IFANDLAIXD      *Print AND.L and operands


ANDLAPID_D  BSR BASIC_DEST_DREG_D       *Decode AND.L Post Increment Address Register to Data Register

            BSR BASIC_SOURCE_REG_D


            BRA IFANDLPOXD      *Print AND.L and operands


ANDLAPDD_D  BSR BASIC_DEST_DREG_D       *Decode AND.L Pre Decrement Address Register to Data Register

            BSR BASIC_SOURCE_REG_D


            BRA IFANDLPRXD      *Print AND.L and operands


ANDLDAI_D   BSR BASIC_SOURCE_DREG_D     *Decode AND.L Data Register to Indirect Address Register

            BSR BASIC_DEST_REG_D

            BRA IFANDLDXAI      *Print AND.L and operands

ANDLDAPI_D  BSR BASIC_SOURCE_DREG_D     *Decode AND.L Data Register to Post Increment Address Register

            BSR BASIC_DEST_REG_D

            BRA IFANDLDXPO      *Print AND.L and operands

ANDLDAPD_D  BSR BASIC_SOURCE_DREG_D     *Decode AND.L Data Register to Pre Decrement Register

            BSR BASIC_DEST_REG_D

            BRA IFANDLDXPR      *Print AND.L and operands

ANDLWAD_D   BSR BASIC_DEST_DREG_D       *Decode AND.L Word Address to Data Register

            BSR BASIC_SOURCE_WA_D

            BRA IFANDLAAXD      *Print AND.L and operands

ANDLLAD_D   BSR BASIC_DEST_DREG_D       *Decode AND.L Long Address to Data Register

            BSR BASIC_SOURCE_LA_D

            BRA IFANDLAAXD      *Print AND.L and operands

ANDLDWA_D   BSR BASIC_SOURCE_DREG_D     *Decode AND.L Data Register to Word Address

            BSR BASIC_DEST_WA_D

            BRA IFANDLDXAA      *Print AND.L and operands


ANDLDLA_D   BSR BASIC_SOURCE_DREG_D     *Decode AND.L Data Register to Long Address

            BSR BASIC_DEST_LA_D

            BRA IFANDLDXAA      *Print AND.L and operands

ANDLDAD_D   BSR BASIC_DEST_DREG_D       *Decode AND.L Immediate Value to Data Register

            BSR BASIC_IMMEDATA_L_D

            BRA IFANDLIXD       *Print AND.L and operands

*---------------- OR Variants-------------*

*OR.B Variants
ORBDD_D    BSR BASIC_DEST_DREG_D        *Decode OR.B Data Register to Data Register

            BSR BASIC_SOURCE_REG_D


            BRA IFORBDXD        *Print OR.B and operands


ORBAID_D   BSR BASIC_DEST_DREG_D        *Decode OR.B Indirect Address Register to Data Register

            BSR BASIC_SOURCE_REG_D


            BRA IFORBAIXD       *Print OR.B and operands


ORBAPD_D  BSR BASIC_DEST_DREG_D     *Decode OR.B Post Increment Address Register to Data Register

            BSR BASIC_SOURCE_REG_D


            BRA IFORBPOXD       *Print OR.B and operands


ORBADD_D BSR BASIC_DEST_DREG_D      *Decode OR.B Pre Decrement Address Register to Data Register

            BSR BASIC_SOURCE_REG_D


            BRA IFORBPRXD       *Print OR.B and operands


ORBDAI_D   BSR BASIC_SOURCE_DREG_D      *Decode OR.B Data Register to Indirect Address Register

            BSR BASIC_DEST_REG_D

            BRA IFORBDXAI       *Print OR.B and operands


ORBDAP_D  BSR BASIC_SOURCE_DREG_D       *Decode OR.B Data Register to Post Decrement Address Register

            BSR BASIC_DEST_REG_D

            BRA IFORBDXPO       *Print OR.B and operands

ORBDAD_D  BSR BASIC_SOURCE_DREG_D       *Decode OR.B Data Register to Pre Decrement Address Register

            BSR BASIC_DEST_REG_D

            BRA IFORBDXPR       *Print OR.B and operands


ORBWAD_D   BSR BASIC_DEST_DREG_D        *Decode OR.B Word Address to Data Register

            BSR BASIC_SOURCE_WA_D


            BRA IFORBAAXD       *Print OR.B and operands

ORBLAD_D   BSR BASIC_DEST_DREG_D        *Decode OR.B Long Address to Data Register

            BSR BASIC_SOURCE_LA_D

            BRA IFORBAAXD       *Print OR.B and operands

ORBDWA_D   BSR BASIC_SOURCE_DREG_D      *Decode OR.B Data Register to Word Address

            BSR BASIC_DEST_WA_D

            BRA IFORBDXAA       *Print OR.B and operands

ORBDLA_D   BSR BASIC_SOURCE_DREG_D      *Decode OR.B Data Register to Long Address

            BSR BASIC_DEST_LA_D

            BRA IFORBDXAA       *Print OR.B and operands

ORBDID_D   BSR BASIC_DEST_DREG_D        *Decode OR.B Immediate Value to Data Register

            BSR BASIC_IMMEDATA_BW_D

            BRA IFORBIXD        *Print OR.B and operands

*OR.W Variants
ORWDD_D    BSR BASIC_DEST_DREG_D        *Decode OR.W Data Register to Data Register

            BSR BASIC_SOURCE_REG_D


            BRA IFORWDXD        *Print OR.W and operands


ORWAID_D   BSR BASIC_DEST_DREG_D        *Decode OR.W Indirect Address Register to Data Register

            BSR BASIC_SOURCE_REG_D


            BRA IFORWAIXD       *Print OR.W and operands


ORWAPD_D  BSR BASIC_DEST_DREG_D     *Decode OR.W Post Increment Address Register to Data Register

            BSR BASIC_SOURCE_REG_D


            BRA IFORWPOXD       *Print OR.W and operands


ORWADD_D BSR BASIC_DEST_DREG_D      *Decode OR.W Pre Decrement Address Register to Data Register

            BSR BASIC_SOURCE_REG_D


            BRA IFORWPRXD       *Print OR.W and operands


ORWDAI_D   BSR BASIC_SOURCE_DREG_D  *Decode OR.W Data Register to Indirect Address Register

            BSR BASIC_DEST_REG_D

            BRA IFORWDXAI       *Print OR.W and operands


ORWDAP_D  BSR BASIC_SOURCE_DREG_D   *Decode OR.W Data Register to Post Increment Address Register

            BSR BASIC_DEST_REG_D

            BRA IFORWDXPO       *Print OR.W and operands

ORWDAD_D  BSR BASIC_SOURCE_DREG_D   *Decode OR.W Data Register to Pre Decrement Address Register

            BSR BASIC_DEST_REG_D

            BRA IFORWDXPR       *Print OR.W and operands


ORWWAD_D   BSR BASIC_DEST_DREG_D    *Decode OR.W Word Address to Data Register

            BSR BASIC_SOURCE_WA_D

            BRA IFORWAAXD       *Print OR.W and operands

ORWLAD_D   BSR BASIC_DEST_DREG_D    *Decode OR.W Long Address to Data Register

            BSR BASIC_SOURCE_LA_D

            BRA IFORWAAXD       *Print OR.W and operands

ORWDWA_D   BSR BASIC_SOURCE_DREG_D  *Decode OR.W Data Register to Word Address

            BSR BASIC_DEST_WA_D

            BRA IFORWDXAA       *Print OR.W and operands

ORWDLA_D   BSR BASIC_SOURCE_DREG_D  *Decode OR.W Data Register to Long Address

            BSR BASIC_DEST_LA_D

            BRA IFORWDXAA       *Print OR.W and operands

ORWDID_D   BSR BASIC_DEST_DREG_D    *Decode OR.W Immediate Value to Data Register

            BSR BASIC_IMMEDATA_BW_D

            BRA IFORWIXD        *Print OR.W and operands


*OR.L Variants
ORLDD_D    BSR BASIC_DEST_DREG_D    *Decode OR.L Data Register to Data Register

            BSR BASIC_SOURCE_REG_D


            BRA IFORLDXD        *Print OR.L and operands


ORLAID_D   BSR BASIC_DEST_DREG_D    *Decode OR.L Indirect Address Register to Data Register

            BSR BASIC_SOURCE_REG_D


            BRA IFORLAIXD       *Print OR.L and operands


ORLAPD_D  BSR BASIC_DEST_DREG_D     *Decode OR.L Post Increment Address Register to Data Register

            BSR BASIC_SOURCE_REG_D


            BRA IFORLPOXD       *Print OR.L and operands


ORLADD_D BSR BASIC_DEST_DREG_D      *Decode OR.L Pre Decrement Address Register to Data Register

            BSR BASIC_SOURCE_REG_D


            BRA IFORLPRXD       *Print OR.L and operands


ORLDAI_D   BSR BASIC_SOURCE_DREG_D  *Decode OR.L Data Register to Indirect Address Register

            BSR BASIC_DEST_REG_D

            BRA IFORLDXAI       *Print OR.L and operands


ORLDAP_D  BSR BASIC_SOURCE_DREG_D   *Decode OR.L Data Register to Post Decrement Address Register

            BSR BASIC_DEST_REG_D

            BRA IFORLDXPO       *Print OR.L and operands

ORLDAD_D  BSR BASIC_SOURCE_DREG_D   *Decode OR.L Data Register to Pre Decrement Address Register

            BSR BASIC_DEST_REG_D

            BRA IFORLDXPR       *Print OR.L and operands


ORLWAD_D   BSR BASIC_DEST_DREG_D    *Decode OR.L Word Address to Data Register

            BSR BASIC_SOURCE_WA_D

            BRA IFORLAAXD       *Print OR.L and operands

ORLLAD_D   BSR BASIC_DEST_DREG_D    *Decode OR.L Long Address to Data Register

            BSR BASIC_SOURCE_LA_D

            BRA IFORLAAXD       *Print OR.L and operands

ORLDWA_D   BSR BASIC_SOURCE_DREG_D  *Decode OR.L Data Register to Word Address

            BSR BASIC_DEST_WA_D

            BRA IFORLDXAA       *Print OR.L and operands


ORLDLA_D   BSR BASIC_SOURCE_DREG_D  *Decode OR.L Data Register to Long Address

            BSR BASIC_DEST_LA_D

            BRA IFORLDXAA       *Print OR.L and operands

ORLDID_D   BSR BASIC_DEST_DREG_D    *Decode OR.L Immediate Value to Data Register

            BSR BASIC_IMMEDATA_L_D

            BRA IFORLIXD        *Print OR.L and operands




*---------------- NOP and RTS--------------*
NOP_D   ADDQ.W  #2, A6      *No operands, move to next instruction

        BRA IFNOP       *Print NOP

RTS_D   ADDQ.W  #2, A6      *No operands, move to next instruction

        BRA IFRTS       *Print RTS

*---------------- DATA --------------------------*
DATA_D  MOVE.W  (A6)+, D6   *Move data value to D6, set A6 to next instruction


        BRA IFBADDATA       *Print the data value


            
 


*Dn To Dn: $1000
MOVEBDD_D:
 BSR BASIC_DECODER
 BRA IFMOVEBDXD 

MOVEWDD_D:
 BSR BASIC_DECODER
 BRA IFMOVEWDXD 
 
MOVELDD_D:
 BSR BASIC_DECODER
 BRA IFMOVELDXD 
*An to Dn: #1008
MOVEBAD_D:
 BSR BASIC_DECODER
 BRA IFMOVEBAXD
MOVEWAD_D:
 BSR BASIC_DECODER
 BRA IFMOVEWAXD
MOVELAD_D:
 BSR BASIC_DECODER
 BRA IFMOVELAXD
 
*(An) to Dn
MOVEBAID_D:
 BSR BASIC_DECODER
 BRA IFMOVEBAIXD

MOVEWAID_D:
 BSR BASIC_DECODER
 BRA IFMOVEWAIXD

MOVELAID_D:
 BSR BASIC_DECODER
 BRA IFMOVELAIXD

*(An)+ to Dn: $1018
MOVEBAPID_D:
 BSR BASIC_DECODER 
 BRA IFMOVEBPOXD

MOVEWAPID_D:
 BSR BASIC_DECODER
 BRA IFMOVEWPOXD

MOVELAPID_D:
 BSR BASIC_DECODER
 BRA IFMOVELPOXD

*-(An) to Dn: #1020
MOVEBADD_D:
 BSR BASIC_DECODER
 BRA IFMOVEBPRXD


MOVEWADD_D:
 BSR BASIC_DECODER
  BRA IFMOVEWPRXD

MOVELADD_D:
 BSR BASIC_DECODER
 BRA IFMOVELPRXD

*(xxx).W to Dn:
MOVEBWRDD_D:

 BSR ADVANCED_DECODER
 ADDQ #4, A6
 BRA IFMOVEBAAXD

MOVEWWRDD_D:
 BSR ADVANCED_DECODER
  ADDQ #4, A6
  BRA IFMOVEWAAXD

MOVELWRDD_D:
 BSR ADVANCED_DECODER
  ADDQ #4, A6
  BRA IFMOVELAAXD

*(xxx).L to Dn:
MOVEBLNGD_D:
 BSR ADVANCED_DECODER_L
 ADDQ #6, A6
 BRA IFMOVEBAAXD

MOVEWLNGD_D:
 BSR ADVANCED_DECODER_L
 ADDQ #6, A6
 BRA IFMOVEWAAXD

MOVELLNGD_D:
 BSR ADVANCED_DECODER_L
 ADDQ #6, A6
 BRA IFMOVELAAXD

*#<data> to Dn:
MOVEBIMD_D:
 BSR ADVANCED_DECODER 
  MOVE.L #2, D5
 BSR CALC_ADDR_OFFSET
 BRA IFMOVEBIXD

MOVEWIMD_D:
 BSR ADVANCED_DECODER 
  MOVE.L #2, D5
 BSR CALC_ADDR_OFFSET
 BRA IFMOVEWIXD


MOVELIMD_D:
 BSR ADVANCED_DECODER
 MOVE.L #4, D5
 BSR CALC_ADDR_OFFSET
 BRA IFMOVELIXD

*Dn To (An): $1080
MOVEBDAI_D:
 BSR BASIC_DECODER
 BRA IFMOVEBDXAI



MOVEWDAI_D:
 BSR BASIC_DECODER
 BRA IFMOVEWDXAI


MOVELDAI_D:
 BSR BASIC_DECODER
 BRA IFMOVELDXAI

*An to (An):
MOVEBAAI_D:
 BSR BASIC_DECODER
 BRA IFMOVEBAXAI
MOVEWAAI_D:
 BSR BASIC_DECODER
 BRA IFMOVEWAXAI
MOVELAAI_D:
 BSR BASIC_DECODER
 BRA IFMOVELAXAI
*(An) to (An):
MOVEBAI_D:
 BSR BASIC_DECODER
 BRA IFMOVEBAIXAI
MOVEWAI_D:
 BSR BASIC_DECODER
 BRA IFMOVEWAIXAI
MOVELAI_D:
 BSR BASIC_DECODER
 BRA IFMOVELAIXAI
*(An)+ to (An):
MOVEBAPAI_D:
 BSR BASIC_DECODER
 BRA IFMOVEBPOXAI
MOVEWAPAI_D:
 BSR BASIC_DECODER
 BRA IFMOVEWPOXAI
MOVELAPAI_D:
 BSR BASIC_DECODER
 BRA IFMOVELPOXAI
*-(An) to (An):
MOVEBADAI_D:
 BSR BASIC_DECODER
 BRA IFMOVEBPRXAI
 
MOVEWADAI_D:
 BSR BASIC_DECODER
 BRA IFMOVEWPRXAI
MOVELADAI_D:
 BSR BASIC_DECODER
 BRA IFMOVELPRXAI

*(xxx).W to (An):
MOVEBWAI_D:
 BSR ADVANCED_DECODER
 ADDQ #4, A6
 BRA IFMOVEBAAXAI

MOVEWWAI_D:
 BSR ADVANCED_DECODER
 ADDQ #4, A6
 BRA IFMOVEWAAXAI  
MOVELWAI_D:
 BSR ADVANCED_DECODER
 ADDQ #6, A6
 BRA IFMOVELAAXAI

*(xxx).L to (An):
MOVEBLAI_D:
 BSR ADVANCED_DECODER_L
 ADDQ #6, A6
 BRA IFMOVEBAAXAI
MOVEWLAI_D:
 BSR ADVANCED_DECODER_L
 ADDQ #6, A6
 BRA IFMOVEWAAXAI
MOVELLAI_D:
 BSR ADVANCED_DECODER_L
 ADDQ #6, A6
 BRA IFMOVELAAXAI
*#<data> to (An):
MOVEBIAI_D:
 BSR ADVANCED_DECODER
  MOVE.L #2, D5
 BSR CALC_ADDR_OFFSET
 
 BRA IFMOVEBIXAI
MOVEWIAI_D:
 BSR ADVANCED_DECODER
  MOVE.L #2, D5
 BSR CALC_ADDR_OFFSET
 
 BRA IFMOVEWIXAI
MOVELIAI_D:
 BSR ADVANCED_DECODER
  MOVE.L #4, D5
 BSR CALC_ADDR_OFFSET
 
 BRA IFMOVELIXAI

*Dn To (An)+:10C0
MOVEBDAP_D:
  BSR BASIC_DECODER
  BRA IFMOVEBDXPO
MOVEWDAP_D:
  BSR BASIC_DECODER
  BRA IFMOVEWDXPO
MOVELDAP_D:
  BSR BASIC_DECODER
  BRA IFMOVELDXPO
*An to (An)+:$10C8
MOVEBAAP_D:
  BSR BASIC_DECODER
  BRA IFMOVEBAXPO
MOVEWAAP_D:
  BSR BASIC_DECODER
  BRA IFMOVEWAXPO
MOVELAAP_D:
  BSR BASIC_DECODER
  BRA IFMOVELAXPO
*(An) to (An)+:
MOVEBAIAP_D:
 BSR BASIC_DECODER
 BRA IFMOVEBAIXPO
MOVEWAIAP_D:
 BSR BASIC_DECODER
 BRA IFMOVEWAIXPO
MOVELAIAP_D:
  BSR BASIC_DECODER
  BRA IFMOVELAIXPO
*(An)+ to (An)+:
MOVEBAPAP_D:
  BSR BASIC_DECODER
  BRA IFMOVEBPOXPO
MOVEWAPAP_D:
  BSR BASIC_DECODER
  BRA IFMOVEWPOXPO
MOVELAPAP_D:
  BSR BASIC_DECODER
  BRA IFMOVELPOXPO
*-(An) to (An)+: 
MOVEBADAP_D:
  BSR BASIC_DECODER
  BRA IFMOVEBPRXPO
MOVEWADAP_D:
  BSR BASIC_DECODER
  BRA IFMOVEWPRXPO
MOVELADAP_D:
  BSR BASIC_DECODER
  BRA IFMOVELPRXPO
 *(xxx).W to (An)+:
MOVEBWAP_D:
 BSR ADVANCED_DECODER
  ADDQ #4, A6
  BRA IFMOVEBAAXPO

MOVEWWAP_D:
  BSR ADVANCED_DECODER 
  ADDQ #4, A6
  BRA IFMOVEWAAXPO

MOVELWAP_D:
  BSR ADVANCED_DECODER
  ADDQ #4, A6
  BRA IFMOVELAAXPO
*(xxx).L to (An)+: 
MOVEBLAP_D:
  BSR ADVANCED_DECODER_L
  ADDQ #6, A6
  BRA IFMOVEBAAXPO

MOVEWLAP_D:
  BSR ADVANCED_DECODER_L
  ADDQ #6, A6
  BRA IFMOVEWAAXPO
MOVELLAP_D:
  BSR ADVANCED_DECODER_L
  ADDQ #6, A6
  BRA IFMOVELAAXPO

*#<data> to (An)+:
MOVEBIAP_D:
  BSR ADVANCED_DECODER
 MOVE.L #2, D5
 BSR CALC_ADDR_OFFSET
 
  BRA IFMOVEBIXPO
MOVEWIAP_D:
  BSR ADVANCED_DECODER
   MOVE.L #2, D5
 BSR CALC_ADDR_OFFSET
 
  BRA IFMOVEWIXPO
MOVELIAP_D:
  BSR ADVANCED_DECODER
  MOVE.L #4, D5
  BSR CALC_ADDR_OFFSET
  BRA IFMOVELIXPO

*Dn To -(An): $113C
MOVEBDAD_D:
 BSR BASIC_DECODER
 BRA IFMOVEBDXPR
MOVEWDAD_D:
  BSR BASIC_DECODER
  BRA IFMOVEWDXPR
MOVELDAD_D:
  BSR BASIC_DECODER
  BRA IFMOVELDXPR
*An to -(An): $1108
MOVEBAAD_D:
  BSR BASIC_DECODER
  BRA IFMOVEBAXPR
MOVEWAAD_D:
  BSR BASIC_DECODER
  BRA IFMOVEWAXPR
MOVELAAD_D:
  BSR BASIC_DECODER
  BRA IFMOVELAXPR
*(An) to -(An):
MOVEBAIAD_D:
  BSR BASIC_DECODER
  BRA IFMOVEBAIXPR
MOVEWAIAD_D:
  BSR BASIC_DECODER
  BRA IFMOVEWAIXPR
MOVELAIAD_D:
  BSR BASIC_DECODER
  BRA IFMOVELAIXPR

*(An)+ to -(An): $1098
MOVEBAPAD_D:
  BSR BASIC_DECODER
  BRA IFMOVEBPOXPR

MOVEWAPAD_D:
  BSR BASIC_DECODER
  BRA IFMOVEWPOXPR

MOVELAPAD_D:
  BSR BASIC_DECODER
  BRA IFMOVELPOXPR   
*-(An) to -(An): $10A0
MOVEBADAD_D:
  BSR BASIC_DECODER
  BRA IFMOVEBPRXPR

MOVEWADAD_D:
  BSR BASIC_DECODER
  BRA IFMOVEWPRXPR

MOVELADAD_D:
  BSR BASIC_DECODER
  BRA IFMOVELPRXPR

*(xxx).W to -(An):
MOVEBWAD_D:
 BSR ADVANCED_DECODER
  ADDQ #4, A6
  BRA IFMOVEBAAXPR

MOVEWWAD_D:
 BSR ADVANCED_DECODER
  ADDQ #4, A6
  BRA IFMOVEWAAXPR

MOVELWAD_D:
 BSR ADVANCED_DECODER
 ADDQ #4, A6
 BRA IFMOVELAAXPR

*(xxx).L to -(An):
MOVEBLAD_D:
 BSR ADVANCED_DECODER 
 ADDQ #6, A6
 BRA IFMOVEBAAXPR
MOVEWLAD_D:
 BSR ADVANCED_DECODER
 ADDQ #6, A6
 BRA IFMOVEWAAXPR

MOVELLAD_D:
 BSR ADVANCED_DECODER
 ADDQ #6, A6
 BRA IFMOVELAAXPR



*#<data> to -(An):
MOVEBIAD_D:
 BSR ADVANCED_DECODER
 MOVE.L #2, D5
 BSR CALC_ADDR_OFFSET
 BRA IFMOVEBIXPR 

MOVEWIAD_D:
 BSR ADVANCED_DECODER
 MOVE.L #2, D5
 BSR CALC_ADDR_OFFSET
 BRA IFMOVEWIXPR

MOVELIAD_D:
 BSR ADVANCED_DECODER
  MOVE.L #4, D5
 BSR CALC_ADDR_OFFSET
 BRA IFMOVELIXPR

*Dn To (xxx).W:$11C0
MOVEBDWRD_D:
 BSR ADVANCED_DECODER
 ADDQ #4, A6
 BRA IFMOVEBDXAA

MOVEWDWRD_D:
 BSR ADVANCED_DECODER
 ADDQ #4, A6
 BRA IFMOVEWDXAA

MOVELDWRD_D:
 BSR ADVANCED_DECODER
 ADDQ #4, A6
 BRA IFMOVELDXAA

*An to (xxx).W:
MOVEBAW_D:
 BSR ADVANCED_DECODER 
 ADDQ #4, A6
 BRA IFMOVEBAXAA

MOVEWAW_D:
 BSR ADVANCED_DECODER
 ADDQ #4, A6
 BRA IFMOVEWAXAA

MOVELAW_D:
 BSR ADVANCED_DECODER
 ADDQ #4, A6
 BRA IFMOVELAXAA

*(An) to (xxx).W:
MOVEBAIW_D:
 BSR ADVANCED_DECODER 
 ADDQ #4, A6
 BRA IFMOVEBAIXAA

MOVEWAIW_D:
 BSR ADVANCED_DECODER 
 ADDQ #4, A6
 BRA IFMOVEWAIXAA

MOVELAIW_D:
 BSR ADVANCED_DECODER
 ADDQ #4, A6
 BRA IFMOVELAIXAA 

*(An)+ to (xxx).W:
MOVEBAPW_D:
 BSR ADVANCED_DECODER
 ADDQ #4, A6
 BRA IFMOVEBPOXAA

MOVEWAPW_D:
 BSR ADVANCED_DECODER 
 ADDQ #4, A6
 BRA IFMOVEWPOXAA

MOVELAPW_D:
 BSR ADVANCED_DECODER
 ADDQ #4, A6
 BRA IFMOVELPOXAA 

*-(An) to (xxx).W:
MOVEBADW_D:
 BSR ADVANCED_DECODER
 ADDQ #4, A6
 BRA IFMOVEBPRXAA

MOVEWADW_D:
 BSR ADVANCED_DECODER
 ADDQ #4, A6
 BRA IFMOVEWPRXAA

MOVELADW_D:
 BSR ADVANCED_DECODER
 ADDQ #4, A6
 BRA IFMOVELPRXAA

*(xxx).W to (xxx).W:
MOVEBW_D:
 BSR ADVANCED_DECODER_2
   CLR.L D5
   MOVE.B #16, D4 
   ADDQ #4, A6 
   MOVE.W D6 , D5 * D6 at this point contains the two Addr, move half of it
   NOP
   LSR.L D4, D6 * align it properly
   CLR.L D7
   NOP
   MOVE.W D5,D7 * move the other half to D7
   CLR.L D4
   BRA IFMOVEBAAXAA
  
MOVEWW_D:
  BSR ADVANCED_DECODER_2
   MOVE.B #16, D4 
   ADDQ #4, A6 
   MOVE.W D6 , D5 * D6 at this point contains the two Addr, move half of it
   NOP
   LSR.L D4, D6 * align it properly
   CLR.L D7
   NOP
   MOVE.W D5,D7 * move the other half to D7
   CLR.L D4  
   BRA IFMOVEWAAXAA
  
MOVELW_D:
  BSR ADVANCED_DECODER_2
   CLR.L D5 
   MOVE.B #16, D4 
   ADDQ #4, A6 
   MOVE.W D6 , D5 * D6 at this point contains the two Addr, move half of it
   NOP
   LSR.L D4, D6 * align it properly
   CLR.L D7
   NOP
   MOVE.W D5,D7 * move the other half to D7
   CLR.L D4
  BRA IFMOVELAAXAA
  
*(xxx).L to (xxx).W:
MOVEBLW_D:
  BSR ADVANCED_DECODER_2
  MOVE.B #16, D4
  ADDQ #6, A6
  LSR.L D4, D7
  BRA IFMOVEBAAXAA

MOVEWLW_D:
  BSR ADVANCED_DECODER_2
  MOVE.B #16, D4
  ADDQ #6, A6
  LSR.L D4, D7
  BRA IFMOVEWAAXAA
  
MOVELLW_D:
  BSR ADVANCED_DECODER_2
  MOVE.B #16, D4
  ADDQ #6, A6
  LSR.L D4, D7
  BRA IFMOVELAAXAA

*#<data> to (xxx).W:
MOVEBIW_D:
  BSR ADVANCED_DECODER_IM
  ADDQ #4, A6
  BRA IFMOVEBIXAA

MOVEWIW_D:
  BSR ADVANCED_DECODER_IM
  ADDQ #4, A6
  BRA IFMOVEWIXAA
MOVELIW_D:   
  BSR ADVANCED_DECODER_IM
  ADDQ #4, A6
  BRA IFMOVELIXAA

*Dn To (xxx).L:$13C0
MOVEBDLNG_D:
 BSR ADVANCED_DECODER_2
 ADDQ #6, A6
 BRA IFMOVEBDXAA

MOVEWDLNG_D:
 
 BSR ADVANCED_DECODER_2
 ADDQ #6, A6

 BRA IFMOVEWDXAA

MOVELDLNG_D:
 BSR ADVANCED_DECODER_2
 ADDQ #6, A6

 BRA IFMOVELDXAA


*An to (xxx).L:
MOVEBAL_D:
 BSR ADVANCED_DECODER_L
 ADDQ #6, A6
 BRA IFMOVEBAXAA

MOVEWAL_D:
 BSR ADVANCED_DECODER_L
 ADDQ #6, A6
 BRA IFMOVEWAXAA

MOVELAL_D:
 BSR ADVANCED_DECODER_L
 ADDQ #6, A6
 BRA IFMOVELAXAA

*(An) to (xxx).L:
MOVEBAIL_D:
 BSR ADVANCED_DECODER_L
 ADDQ #6, A6
 BRA IFMOVEBAIXAA

MOVEWAIL_D:
 BSR ADVANCED_DECODER_L
 ADDQ #6, A6
 BRA IFMOVEWAIXAA 

MOVELAIL_D:
 BSR ADVANCED_DECODER_L 
 ADDQ #6, A6
 BRA IFMOVELAIXAA

*(An)+ to (xxx).L:
MOVEBAPL_D:
 BSR ADVANCED_DECODER_L
 ADDQ #6, A6
 BRA IFMOVEBPOXAA

MOVEWAPL_D:
 BSR ADVANCED_DECODER_L
 ADDQ #6, A6
 BRA IFMOVEWPOXAA

MOVELAPL_D:
 BSR ADVANCED_DECODER_L
 ADDQ #6, A6
 BRA IFMOVELPOXAA

*-(An) to (xxx).L:
MOVEBADL_D:
 BSR ADVANCED_DECODER_L
 ADDQ #6, A6
 BRA IFMOVEBPRXAA

MOVEWADL_D:
 BSR ADVANCED_DECODER_L
 ADDQ #6, A6
 BRA IFMOVEWPRXAA

MOVELADL_D:
 BSR ADVANCED_DECODER_L
 ADDQ #6, A6
 BRA IFMOVELPRXAA

*(xxx).W to (xxx).L:
MOVEBWL_D:
  BSR ADVANCED_DECODER_2 
   CLR.L D5 
   MOVE.B #16, D4 
   ADDQ #6, A6 
   MOVE.W D6 , D5 * D6 at this point contains the two Addr, move half of it
   NOP
   LSR.L D4, D6 * align it properly
   LSR.L #6, D7

   NOP
   MOVE.W D5,D7 * move the other half to D7
   CLR.L D4
  BRA IFMOVEBAAXAA

MOVEWWL_D:
  BSR ADVANCED_DECODER_2
   CLR.L D5 
   MOVE.B #16, D4 
   ADDQ #6, A6 
   MOVE.W D6 , D5 * D6 at this point contains the two Addr, move half of it
   NOP
   LSR.L D4, D6 * align it properly

   MOVE.W D5, D7
   NOP
   MOVE.W D5,D7 * move the other half to D7
   CLR.L D4
  BRA IFMOVEWAAXAA

MOVELWL_D:
  BSR ADVANCED_DECODER_2
   CLR.L D5 
   MOVE.B #16, D4 
   ADDQ #6, A6 
   MOVE.W D6 , D5 * D6 at this point contains the two Addr, move half of it
   NOP
   LSR.L D4, D6 * align it properly
   LSR.L #6, D7

   NOP
   MOVE.W D5,D7 * move the other half to D7
   CLR.L D4  
  BRA IFMOVELAAXAA

*(xxx).L to (xxx).L
MOVEBLL_D:
  BSR ADVANCED_DECODER_2
  ADDQ #8, A6
  BRA IFMOVEBAAXAA

MOVEWLL_D:
 
  BSR ADVANCED_DECODER_2
  ADDQ #8, A6
  BRA IFMOVEWAAXAA

MOVELLL_D:
  BSR ADVANCED_DECODER_2
  ADDQ #8, A6
  BRA IFMOVELAAXAA

*#<data> to (xxx).L:
MOVEBIL_D:
  BSR ADVANCED_DECODER_2
  ADDQ #6, A6
  BRA IFMOVELIXAA



MOVEWIL_D:
  BSR ADVANCED_DECODER_2
  MOVE.B #16, D4
  MOVE.L D6,D5
  NOP
  LSL.L D4, D5

  NOP
  LSR.L D4, D6
  NOP
  LSR.L D4, D7
  NOP
  MOVE.W D7, D5
  NOP
  MOVE.L D5,D7
  ADDQ #6, A6
  BRA IFMOVEWIXAA


MOVELIL_D:
  BSR ADVANCED_DECODER_2
  ADDQ #8, A6
  BRA IFMOVELIXAA




*MOVEQ*
MOVEQD_D:
 BSR MQ_DECODER
 BRA IFMOVEQIXD 




*---------------- MOVE-A Variants-------------*
*Data reg to Addr*
MOVEAWD_D:
 BSR BASIC_DECODER
 BRA IFMOVEAWDXA
MOVEALD_D:
 BSR BASIC_DECODER
 BRA IFMOVEALDXA

*Addr to Addr*
MOVEAWA_D:
 BSR BASIC_DECODER
 BRA IFMOVEAWAXA

MOVEALA_D:
 BSR BASIC_DECODER
 BRA IFMOVEALAXA


*Addr indirect to Addr*
MOVEAWAI_D:
  BSR BASIC_DECODER
  BRA IFMOVEAWAIXA
MOVEALAI_D:
 BSR BASIC_DECODER
 BRA IFMOVEALAIXA

*Addr post increment to Addr*
MOVEAWPA_D:
 BSR BASIC_DECODER
 BRA IFMOVEAWPOXA

MOVEALPA_D:
 BSR BASIC_DECODER
 BRA IFMOVEALPOXA

*Addr pre decrement to Addr*
MOVEAWDA_D:
 BSR BASIC_DECODER
 BRA IFMOVEAWPRXA

MOVEALDA_D:
 BSR BASIC_DECODER
 BRA IFMOVEALPRXA

*long addr to Addr*
MOVEAWLA_D:
 BSR ADVANCED_DECODER_L
 BRA IFMOVEAWAAXA

MOVEALLA_D:
  BSR ADVANCED_DECODER_L
  BRA IFMOVEALAAXA
*word addr to Addr*
MOVEAWWA_D:
  BSR ADVANCED_DECODER
  BRA IFMOVEAWAAXA
MOVEALWA_D:
  BSR ADVANCED_DECODER
  BRA IFMOVEALAAXA

*immidiate to addr*
MOVEAWIA_D:
 BSR ADVANCED_DECODER
 MOVE.L #2, D5
 BSR CALC_ADDR_OFFSET
 BRA IFMOVEAWIXA
MOVEALIA_D:
 BSR ADVANCED_DECODER
 MOVE.L #4, D5
 BSR CALC_ADDR_OFFSET 
 BRA IFMOVEALIXA
*--------------ADD VARIANTS---------------*

*D to D*
ADDBDD_D:
 BSR BASIC_DECODER
 BRA IFADDBDXD

ADDWDD_D:
 BSR BASIC_DECODER
 BRA IFADDWDXD

ADDLDD_D:
 BSR BASIC_DECODER
 BRA IFADDLDXD

*D to A*
ADDBDA_D:
 *BSR BASIC_DECODER
 *BRA IFADDBDXA

ADDWDA_D:
 *BSR BASIC_DECODER
 *BRA IFADDWDXA

ADDLDA_D:
 *BSR BASIC_DECODER
 *BRA IFADDLDXA

*D to (A)*
ADDBDAI_D:
 BSR BASIC_DECODER
 BRA IFADDBDXAI

ADDWDAI_D: LEA ADDBWD, A1 *ADD  byte xxx.w to Dn
 MOVE.L A1, D5
  MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ ADDWWD_D
 
 LEA ADDWWD, A1 *ADD  word xxx.w to Dn
 MOVE.L A1, D5
  MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ ADDWWD_D
 
 LEA ADDLWD, A1 *ADD  Long xxx.w to Dn
 MOVE.L A1, D5
  MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ ADDLWD_D
 
 LEA ADDBLD, A1 *ADD  byte xxx.L to Dn
 MOVE.L A1, D5
  MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ ADDWWD_D
 
 LEA ADDWLD, A1 *ADD  word xxx.L to Dn
 MOVE.L A1, D5
  MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ ADDWLD_D
 
 LEA ADDLLD, A1 *ADD  Long xxx.L to Dn
 MOVE.L A1, D5
  MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ ADDLLD_D
    
 
 BSR BASIC_DECODER
 BRA IFADDWDXAI


ADDLDAI_D:
 BSR BASIC_DECODER
 BRA IFADDLDXAI

*D to (A)+*
ADDBDAP_D:
 BSR BASIC_DECODER
 BRA IFADDBDXPO

ADDWDAP_D:
 BSR BASIC_DECODER
 BRA IFADDWDXPO

ADDLDAP_D:
 BSR BASIC_DECODER
 BRA IFADDLDXPO
*D to -(A)*

ADDBDAD_D:
 BSR BASIC_DECODER
 BRA IFADDBDXPR

ADDWDAD_D:
 BSR BASIC_DECODER
 BRA IFADDWDXPR

ADDLDAD_D:
 BSR BASIC_DECODER
 BRA IFADDLDXPR

*A to D* LEA ADDBWD, A1 *ADD  byte xxx.w to Dn
 MOVE.L A1, D5
  MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ ADDWWD_D
 
 LEA ADDWWD, A1 *ADD  word xxx.w to Dn
 MOVE.L A1, D5
  MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ ADDWWD_D
 
 LEA ADDLWD, A1 *ADD  Long xxx.w to Dn
 MOVE.L A1, D5
  MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ ADDLWD_D
 
 LEA ADDBLD, A1 *ADD  byte xxx.L to Dn
 MOVE.L A1, D5
  MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ ADDWWD_D
 
 LEA ADDWLD, A1 *ADD  word xxx.L to Dn
 MOVE.L A1, D5
  MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ ADDWLD_D
 
 LEA ADDLLD, A1 *ADD  Long xxx.L to Dn
 MOVE.L A1, D5
  MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ ADDLLD_D
    
 
ADDWAD_D:
 BSR BASIC_DECODER
 BRA IFADDWAXD

ADDLAD_D:
 BSR BASIC_DECODER
 BRA IFADDLAXD

*(A) to D*
ADDBAID_D:
 BSR BASIC_DECODER
 BRA IFADDBAIXD

ADDWAID_D:
 BSR BASIC_DECODER
 BRA IFADDWAIXD

ADDLAID_D:
 BSR BASIC_DECODER
 BRA IFADDLAIXD

*(A)+ to D*
ADDBAPD_D:
 BSR BASIC_DECODER
 BRA IFADDBPOXD

ADDWAPD_D:
 BSR BASIC_DECODER
 BRA IFADDWPOXD

ADDLAPD_D:
 BSR BASIC_DECODER
 BRA IFADDLPOXD

*-(A) to D*
ADDBADD_D:
 BSR BASIC_DECODER
 BRA IFADDBPRXD

ADDWADD_D:
 BSR BASIC_DECODER
 BRA IFADDWPRXD

ADDLADD_D:
 BSR BASIC_DECODER
 BRA IFADDLPRXD

*xxx.w to D*
  ADDBWD_D:
  BSR ADVANCED_DECODER 
  ADDQ #4, A6
  BRA IFADDBAAXD

ADDWWD_D:
 BSR ADVANCED_DECODER
 ADDQ #4, A6
 BRA IFADDWAAXD


ADDLWD_D:
 BSR ADVANCED_DECODER 
 ADDQ #4, A6
 BRA IFADDLAAXD

*xxx.L to D*
 ADDBLD_D:
  BSR ADVANCED_DECODER_2
  ADDQ #6, A6
  BRA IFADDBAAXD

ADDWLD_D:
 BSR ADVANCED_DECODER_2
 ADDQ #6, A6
 BRA IFADDWAAXD

ADDLLD_D:
 BSR ADVANCED_DECODER_2
 ADDQ #6, A6
 BRA IFADDLAAXD
*--------------ADDA VARIANTS---------------*
*D to A*
ADDAWDA_D:
  BSR BASIC_DECODER
  BRA IFADDAWDXA

ADDALDA_D:
  BSR BASIC_DECODER
  BRA IFADDALDXA

*A to A* 
ADDAWA_D:
  BSR BASIC_DECODER
  BRA IFADDAWAXA

ADDALA_D:
  BSR BASIC_DECODER
  BRA IFADDALAXA 

*(A) to A*
ADDAWIA_D:
  BSR BASIC_DECODER
  BRA IFADDAWAIXA

ADDALIA_D:
  BSR BASIC_DECODER
  BRA IFADDALAIXA

*(A)+ to A*
ADDAWPA_D:
  BSR BASIC_DECODER
  BRA IFADDAWPOXA

ADDALPA_D:
  BSR BASIC_DECODER
  BRA IFADDALPRXA

*-(A) to A*
ADDAWDEA_D:
  BSR BASIC_DECODER
  BRA IFADDAWPOXA

ADDALDEA_D:
  BSR BASIC_DECODER
  BRA IFADDALPOXA
  
*(xxx).W to A*
ADDAWWA_D:
 BSR ADVANCED_DECODER
 ADDQ #4, A6
 BRA IFADDAWAAXA


ADDALWA_D:
 BSR ADVANCED_DECODER 
 ADDQ #4, A6
 BRA IFADDALAAXA
 
*(xxx).L to A*
ADDAWLA_D:
 BSR ADVANCED_DECODER_L
 ADDQ #4, A6
 BRA IFADDAWAAXA    


ADDALLA_D:
 BSR ADVANCED_DECODER_2 
 ADDQ #4, A6
 BRA IFADDALAAXA
 
*#<Data> to A*
ADDAWI_D:
 BSR ADVANCED_DECODER
 ADDQ #4, A6
 BRA IFADDAWIXA


ADDALI_D:
 BSR ADVANCED_DECODER_2 
 ADDQ #4, A6
 BRA IFADDALIXA


 *--------------ADDQ VARIANTS---------------*
*only valud for immidiate data to a location*
*Dn*
ADDQBD_D:
 BSR AQ_DECODER
 BRA IFADDQBIXD

ADDQWD_D:
 BSR AQ_DECODER
 BRA IFADDQWIXD
 
ADDQLD_D:
 BSR AQ_DECODER
 BRA IFADDQLIXD

*An*
ADDQBA_D:
 BSR AQ_DECODER
 BRA IFADDQBIXA

ADDQWA_D:
 BSR AQ_DECODER
 BRA IFADDQWIXA

ADDQLA_D:
 BSR AQ_DECODER
 BRA IFADDQLIXA

*(An)*
ADDQBAI_D:
 BSR AQ_DECODER
 BRA IFADDQBIXAI

ADDQWAI_D:
 BSR AQ_DECODER
 BRA IFADDQWIXAI

ADDQLAI_D:
 BSR AQ_DECODER
 BRA IFADDQLIXAI

*(An)+*
ADDQBAPI_D:
 BSR AQ_DECODER
 BRA IFADDQBIXPO

ADDQWAPI_D:
 BSR AQ_DECODER
 BRA IFADDQWIXPO
 
ADDQLAPI_D:
 BSR AQ_DECODER
 BRA IFADDQLIXPO

*-(An)*
ADDQBAPD_D:
 BSR AQ_DECODER
 BRA IFADDQBIXPR

ADDQWAPD_D:
 BSR AQ_DECODER
 BRA IFADDQWIXPR

ADDQLAPD_D:
 BSR AQ_DECODER
 BRA IFADDQLIXPR
 
*WORD*
ADDQBW_D:
 BSR AQ_DECODER
 BRA IFADDQBIXAA

ADDQWW_D:
 BSR AQ_DECODER
 BRA IFADDQWIXAA

ADDQLW_D:
 BSR AQ_DECODER
 BRA IFADDQLIXAA

*LONG*
ADDQBL_D:
 BSR AQ_DECODER
 BRA IFADDQBIXAA

ADDQWL_D:
 BSR AQ_DECODER
 BRA IFADDQWIXAA

ADDQLL_D:
 BSR ADVANCED_DECODER
 BRA IFADDQWIXAA

*--------------MOVEQ VARIANTS---------------*
*only works with data registers and longs *
MOVEQ_V_DECODE:
 BSR BASIC_DECODER
 BRA IFMOVEQIXD

*--------------------SUB VARIANTS-----------------------------*
*D - D*
SUBBDD_D:
 BSR BASIC_DECODER
 BRA IFSUBBDXD

SUBWDD_D:
 BSR BASIC_DECODER
 BRA IFSUBWDXD

SUBLDD_D:
 BSR BASIC_DECODER
 BRA IFSUBLDXD

*D-A: NOT VALID FOR BYTE DATA*
SUBWDA_D:
 *BSR BASIC_DECODER
 *BRA IFSUBWDXA


SUBLDA_D:
* BSR BASIC_DECODER
* BRA IFSUBLDXA

*D-(A)*
SUBBDAI_D:
 BSR BASIC_DECODER
 BRA IFSUBBDXAI


SUBWDAI_D:
 BSR BASIC_DECODER
 BRA IFSUBWDXAI


SUBLDAI_D:
 BSR BASIC_DECODER
 BRA IFSUBLAIXD
 
*D-(A)+*
SUBBDAP_D:
 BSR BASIC_DECODER
 BRA IFSUBBPOXD


SUBWDAP_D:
 BSR BASIC_DECODER
 BRA IFSUBWPOXD


SUBLDAP_D:
 BSR BASIC_DECODER
 BRA IFSUBLPOXD

*D- -(A)*
SUBBDAD_D:
 BSR BASIC_DECODER
 BRA IFSUBBPRXD


SUBWDAD_D:
 BSR BASIC_DECODER
 BRA IFSUBWPRXD 

SUBLDAD_D:
 BSR BASIC_DECODER
 BRA IFSUBLDXPR

*D- WORD*
SUBBDW_D:
 BSR ADVANCED_DECODER
 ADDQ #4, A6
 BRA IFSUBBAAXD


SUBWDW_D:
 BSR ADVANCED_DECODER 
  ADDQ #4, A6
  BRA IFSUBWAAXD

SUBLDW_D:
 BSR ADVANCED_DECODER
  ADDQ #4, A6
  BRA IFSUBLAAXD

*D - LONG*
SUBBDL_D:
 BSR ADVANCED_DECODER_L
  ADDQ #6, A6
  BRA IFSUBBAAXD

SUBWDL_D:
 BSR ADVANCED_DECODER_L
  ADDQ #6, A6
  BRA IFSUBWAAXD



SUBLDL_D:
 BSR ADVANCED_DECODER_L
  ADDQ #6, A6
  BRA IFSUBLAAXD



* D - IMMIDIATE*
SUBBDI_D:
 BSR ADVANCED_DECODER
 BSR CALC_ADDR_OFFSET
 *BRA IFSUBBDXI

SUBWDI_D:
 BSR ADVANCED_DECODER
 BSR CALC_ADDR_OFFSET
 *BRA IFSUBWDXI

SUBLDI_D:
 BSR ADVANCED_DECODER
 BSR CALC_ADDR_OFFSET
 *BRA IFSUBLDXI


*(A) - D*
SUBBAD_D:
 BSR BASIC_DECODER
 BRA IFSUBBDXAI

SUBWAD_D:
 BSR BASIC_DECODER
 BRA IFSUBWDXAI

SUBLAD_D:
 BSR BASIC_DECODER
 BRA IFSUBLDXAI

*(A)+ -D*
SUBBAPD_D:
 BSR BASIC_DECODER
 BRA IFSUBBDXPO

SUBWAPD_D:
 BSR BASIC_DECODER
 BRA IFSUBWDXPO

SUBLAPD_D:
 BSR BASIC_DECODER
 BRA IFSUBLDXPO

*-(A) - D*
SUBBADD_D:
 BSR BASIC_DECODER
 BRA IFSUBBDXPR

SUBWADD_D:
 BSR BASIC_DECODER
 BRA IFSUBWDXPR

SUBLADD_D:
 BSR BASIC_DECODER
 BRA IFSUBLDXPR

*WORD - D*
SUBBWD_D:
 BSR ADVANCED_DECODER
 ADDQ #4, A6
 BRA IFSUBBDXAA

SUBWWD_D:
 BSR ADVANCED_DECODER
 ADDQ #4, A6
 BRA IFSUBWDXAA

SUBLWD_D:
 BSR ADVANCED_DECODER
 ADDQ #4, A6
 BRA IFSUBLDXAA

*LONG - D*
SUBBLD_D:
 BSR ADVANCED_DECODER_L
 ADDQ #6, A6
 BRA IFSUBBDXAA

SUBWLD_D:
 BSR ADVANCED_DECODER_L
 ADDQ #6, A6
 BRA IFSUBWDXAA

SUBLLD_D:
 BSR ADVANCED_DECODER_L 
 ADDQ #6, A6
 BRA IFSUBLDXAA


 OUTPUT: RTS



* Put variables and constants here


*---------------- MOVE Variants-------------*
GENERAL_MOVE EQU $0000
GENERAL_MOVE_MASK EQU $C000

*00 size destination source *
MMASK EQU $F1F8
MVALUEMASK1 EQU $7
MVALUEMASK2 EQU $E00

MMASKAA_AA EQU $FFFF
MMASKDN_AA EQU $FFF8
MMASKAA_DN EQU $F1FF


*Dn To Dn: $1000
MOVEBDD EQU $1000
MOVEWDD EQU $3000
MOVELDD EQU $2000

*An to Dn: #1008
*MOVEBAD EQU $1008
MOVEWAD EQU $3008
MOVELAD EQU $2008
*(An) to Dn: $1010
MOVEBAID EQU $1010
MOVEWAID EQU $3010
MOVELAID EQU $2010
*(An)+ to Dn: $1018
MOVEBAPID EQU $1018
MOVEWAPID EQU $3018
MOVELAPID EQU $2018
*-(An) to Dn: #1020
MOVEBADD EQU $1020
MOVEWADD EQU $3020
MOVELADD EQU $2020
*(xxx).W to Dn:
MOVEBWRDD EQU $1038
MOVEWWRDD EQU $3038
MOVELWRDD EQU $2038
*(xxx).L to Dn:
MOVEBLNGD EQU $1039
MOVEWLNGD EQU $3039
MOVELLNGD EQU $2039
*#<data> to Dn:
MOVEBIMD EQU $103C
MOVEWIMD EQU $303C
MOVELIMD EQU $203C
*Dn To (An): $1080
MOVEBDAI EQU $1080
MOVEWDAI EQU $3080
MOVELDAI EQU $2080
*An to (An):
MOVEBAAI EQU $1088
MOVEWAAI EQU $3088
MOVELAAI EQU $2088
*(An) to (An):
MOVEBAI EQU $1090
MOVEWAI EQU $3090
MOVELAI EQU $2090
*(An)+ to (An):
MOVEBAPAI EQU $1098
MOVEWAPAI EQU $3098
MOVELAPAI EQU $2098
*-(An) to (An):
MOVEBADAI EQU $10A0
MOVEWADAI EQU $30A0
MOVELADAI EQU $20A0
*(xxx).W to (An):
MOVEBWAI EQU $10B8
MOVEWWAI EQU $30B8
MOVELWAI EQU $20B8
*(xxx).L to (An):
MOVEBLAI EQU $10B9
MOVEWLAI EQU $30B9
MOVELLAI EQU $20B9
*#<data> to (An):
MOVEBIAI EQU $10BC
MOVEWIAI EQU $30BC
MOVELIAI EQU $20BC
*Dn To (An)+:10C0
MOVEBDAP EQU $10C0
MOVEWDAP EQU $30C0
MOVELDAP EQU $20C0
*An to (An)+:$10C8
MOVEBAAP EQU $10C8
MOVEWAAP EQU $30C8
MOVELAAP EQU $20C8
*(An) to (An)+:
MOVEBAIAP EQU $10D0
MOVEWAIAP EQU $30D0
MOVELAIAP EQU $20D0
*(An)+ to (An)+:
MOVEBAPAP EQU $10D8
MOVEWAPAP EQU $30D8
MOVELAPAP EQU $20D8
*-(An) to (An)+: 
MOVEBADAP EQU $10E0
MOVEWADAP EQU $30E0
MOVELADAP EQU $20E0
*(xxx).W to (An)+:
MOVEBWAP EQU $10F8
MOVEWWAP EQU $30F8
MOVELWAP EQU $20F8
*(xxx).L to (An)+:
MOVEBLAP EQU $10F9
MOVEWLAP EQU $30F9
MOVELLAP EQU $20F9
*#<data> to (An)+:
MOVEBIAP EQU $10FC
MOVEWIAP EQU $30FC
MOVELIAP EQU $20FC

*Dn To -(An): 
MOVEBDAD EQU $1100
MOVEWDAD EQU $3100
MOVELDAD EQU $2100
*An to -(An): 
MOVEBAAD EQU $1108
MOVEWAAD EQU $3108
MOVELAAD EQU $2108
*(An) to -(An):
MOVEBAIAD EQU $1110
MOVEWAIAD EQU $3110
MOVELAIAD EQU $2110

*(An)+ to -(An): 
MOVEBAPAD EQU $1118
MOVEWAPAD EQU $3118
MOVELAPAD EQU $2118
*-(An) to -(An): 
MOVEBADAD EQU $1120
MOVEWADAD EQU $3120
MOVELADAD EQU $2120
*(xxx).W to -(An):
MOVEBWAD EQU $10F8
MOVEWWAD EQU $30F8
MOVELWAD EQU $20F8
*(xxx).L to -(An):
MOVEBLAD EQU $10F9
MOVEWLAD EQU $30F9
MOVELLAD EQU $20F9
*#<data> to -(An):
MOVEBIAD EQU $113C
MOVEWIAD EQU $313C
MOVELIAD EQU $213C
*Dn To (xxx).W:$11C0
MOVEBDWRD EQU $11C0
MOVEWDWRD EQU $31C0
MOVELDWRD EQU $21C0
*An to (xxx).W:
MOVEBAW EQU $1068
MOVEWAW EQU $3068
MOVELAW EQU $2068
*(An) to (xxx).W:
MOVEBAIW EQU $10A8
MOVEWAIW EQU $30A8
MOVELAIW EQU $20A8
*(An)+ to (xxx).W:
MOVEBAPW EQU $10E8
MOVEWAPW EQU $30E8
MOVELAPW EQU $20E8
*-(An) to (xxx).W:
MOVEBADW EQU $1128
MOVEWADW EQU $3128
MOVELADW EQU $2128
*(xxx).W to (xxx).W:
MOVEBW EQU $11F8
MOVEWW EQU $31F8
MOVELW EQU $21F8
*(xxx).L to (xxx).W:
MOVEBLW EQU $11F9
MOVEWLW EQU $31F9
MOVELLW EQU $21F9

*#<data> to (xxx).W:
MOVEBIW EQU $11FC
MOVEWIW EQU $31FC
MOVELIW EQU $21FC

*Dn To (xxx).L:$13C0
MOVEBDLNG EQU $13C0
MOVEWDLNG EQU $33C0
MOVELDLNG EQU $23C0
*An to (xxx).L:
MOVEBAL EQU $13C8
MOVEWAL EQU $33C8
MOVELAL EQU $23C8
*(An) to (xxx).L:
MOVEBAIL EQU $13D0
MOVEWAIL EQU $33D0
MOVELAIL EQU $23D0
*(An)+ to (xxx).L:
MOVEBAPL EQU $13D8
MOVEWAPL EQU $33D8
MOVELAPL EQU $23D8
*-(An) to (xxx).L:
MOVEBADL EQU $13E0
MOVEWADL EQU $33E0
MOVELADL EQU $23E0
*(xxx).W to (xxx).L:
MOVEBWL EQU $13F8
MOVEWWL EQU $33F8
MOVELWL EQU $23F8
*(xxx).L to (xxx).L
MOVEBLL EQU $13F9
MOVEWLL EQU $33F9
MOVELLL EQU $23F9
*#<data> to (xxx).L:
MOVEBIL EQU $13FC
MOVEWIL EQU $33FC
MOVELIL EQU $23FC



*---------------- MOVE-A Variants-------------*
GENERAL_MOVEA EQU $0040
GENERAL_MOVEA_MASK EQU $C1C0

MOVEAAAMASK EQU $F1FF

MOVEAMASK EQU $F1C0
*Data reg to Addr*
MOVEAWD EQU $3040
MOVEALD  EQU $2040
*Addr to Addr*
MOVEAWA EQU $3048
MOVEALA  EQU $2048
*Addr indirect to Addr*
MOVEAWAI EQU $3050
MOVEALAI  EQU $2050
*Addr post increment to Addr*
MOVEAWPA EQU $3058
MOVEALPA  EQU $2058
*Addr pre decrement to Addr*
MOVEAWDA EQU $3060
MOVEALDA  EQU $2060
*long addr to Addr*
MOVEAWLA EQU $3079
MOVEALLA  EQU $2079
*word addr to Addr*
MOVEAWWA EQU $3078
MOVEALWA  EQU $2078
*immidiate to addr*
MOVEAWIA EQU $307C
MOVEALIA  EQU $207C

*--------------ADD VARIANTS---------------*
GENERAL_ADD_ADDA EQU $D000
GENERAL_ADD_ADDA_MASK EQU $F000
ADDAAAMASK EQU $F1FF
ADDMASK EQU $F1F8
*Dn To Dn: 
ADDBDD EQU $D000
ADDWDD EQU $D040
ADDLDD EQU $D080
*An to Dn:  
ADDWAD EQU $D048
ADDLAD EQU $D088
*(An) to Dn:
ADDBAID EQU $D010
ADDWAID EQU $D050
ADDLAID EQU $D090
*(An)+ to Dn: 
ADDBAPD EQU $D018
ADDWAPD EQU $D058
ADDLAPD EQU $D088
*-(An) to Dn: 
ADDBADD EQU $D020
ADDWADD EQU $D060
ADDLADD EQU $D0A0
*(xxx).W to Dn:
ADDBWD EQU $D038
ADDWWD EQU $D078
ADDLWD EQU $D0B8
*(xxx).L to Dn:
ADDBLD EQU $D039
ADDWLD EQU $D079
ADDLLD EQU $D0B9
*#<data> to Dn:
ADDBID EQU $D03C
ADDWID EQU $D07C
ADDLID EQU $D0BC


*Dn to An
ADDBDA EQU $D108
ADDWDA EQU $D148
ADDLDA EQU $D188

*Dn To (An):
ADDBDAI EQU $D110
ADDWDAI EQU $D150
ADDLDAI EQU $DC10
 

*Dn To (An)+:
ADDBDAP EQU $D118
ADDWDAP EQU $D158
ADDLDAP EQU $D198
*Dn To -(An):
ADDBDAD EQU $D120
ADDWDAD EQU $D160
ADDLDAD EQU $D190
*Dn To (xxx).W:
ADDBDW EQU $D138
ADDWDW EQU $D178
ADDLDW EQU $D1B8
*Dn To (xxx).L:
ADDBDL EQU $D139
ADDWDL EQU $D179
ADDLDL EQU $D1B9



*--------------ADDA VARIANTS---------------*

ADDAMASK EQU $F1F8
ADDAAAMASK  EQU $F1FF

GENERAL_ADDA EQU $D000
GENERAL_ADDA_MASK EQU $F000
*D to A*
ADDAWDA EQU $D0C0
ADDALDA  EQU  $D1C0
*A to A*
ADDWA EQU $D0C8
ADDLA  EQU  $D1C8
*(A) to A*
ADDWIA EQU $D0D0
ADDLIA  EQU  $D1D0
*(A)+ to A*
ADDWPA EQU $D0D8
ADDLPA  EQU  $D1D8
*-(A) to A*
ADDWDEA EQU $D0E0
ADDLDEA  EQU  $D1E0

*(xxx).W to A*
ADDAWWA EQU $D0F8
ADDALWA EQU $D1F8

*(xxx).L to A*
ADDAWLA EQU $D0F9
ADDALLA EQU $D1F9

*#<Data> to A*
ADDAWI  EQU $D0FC
ADDALI  EQU $D1FC

*--------------ADDQ VARIANTS---------------*
GENERAL_ADDQ EQU $5000
GENERAL_ADDQ_MASK EQU $F100

ADDQAAMASK EQU $F1FF

*only valud for immidiate data to a location*
ADDQMASK EQU $F038
ADDQDEST EQU $7
ADDQVALUE EQU $E00
*Dn*
ADDQBD EQU  $5000
ADDQWD EQU $5040
ADDQLD EQU  $50C0
*An*
ADDQBA EQU  $5008
ADDQWA EQU $5048
ADDQLA EQU  $50C8
*(An)*
ADDQBAI EQU  $5010
ADDQWAI EQU $5050
ADDQLAI EQU  $5090
*(An)+*
ADDQBAPI EQU  $5018
ADDQWAPI EQU $5058
ADDQLAPI EQU  $5098
*-(An)*
ADDQBAPD EQU  $5018
ADDQWAPD EQU $5060
ADDQLAPD EQU  $5048
*WORD*
ADDQBW EQU  $5038
ADDQWW EQU $5078
ADDQLW EQU  $50B8
*LONG*
ADDQBL EQU  $5039
ADDQWL EQU $5079
ADDQLL EQU  $50B9


*--------------MOVEQ VARIANTS---------------*
*only works with data registers and longs *
MOVEQ_V EQU $7000
MOVEQ_R EQU $E00
MOVEQ_D EQU $FF

*--------------------SUB VARIANTS-----------------------------*
GENERAL_SUB EQU $9000
GENERAL_SUB_MASK EQU $F000

SUBAAMASK EQU $F1FF

SUBMASK EQU $F1F8
*D - D*
SUBBDD EQU $9000
SUBWDD EQU $9040
SUBLDD EQU $9080
*D-A: NOT VALID FOR BYTE DATA*
SUBWDA EQU $9048
SUBLDA EQU $9088
*D-(A)*
SUBBDAI EQU $9010
SUBWDAI EQU $9050
SUBLDAI EQU $9090
*D-(A)+*
SUBBDAP EQU $9018
SUBWDAP EQU $9058
SUBLDAP EQU $9098
*D- -(A)*
SUBBDAD EQU $9020
SUBWDAD EQU $9060
SUBLDAD EQU $90A0
*D- WORD*
SUBBDW EQU $9038
SUBWDW EQU $9078
SUBLDW EQU $90B8
*D - LONG*
SUBBDL EQU $9039
SUBWDL EQU $9079
SUBLDL EQU $90B9
* D - IMMIDIATE*
SUBBDI EQU $903C
SUBWDI EQU $907C
SUBLDI EQU $90BC
*(A) - D*
SUBBAD EQU $90C0
SUBWAD EQU $90C0
SUBLAD EQU $91C0

*(A)+ -D*
SUBBAPD EQU $9118
SUBWAPD EQU $9158
SUBLAPD EQU $9198

*-(A) - D*
SUBBADD EQU $9120
SUBWADD EQU $9160
SUBLADD EQU $91A0

*WORD - D*
SUBBWD EQU $9138
SUBWWD EQU $9178
SUBLWD EQU $91B8

*LONG - D*
SUBBLD EQU $9139
SUBWLD EQU $9179
SUBLLD EQU $91B9



*---------------- AND Variants-------------*
GENERAL_AND EQU $C000
GENERAL_AND_MASK EQU $F000

ANDORMASK EQU $F1F8     *This can be used for AND and OR

ANDORWLIMASK EQU $F1FF *This can be used for AND and OR

*Dn -> Dn
ANDBDD EQU $C000
ANDWDD EQU $C040
ANDLDD EQU $C080

*(An) -> Dn
ANDBAID EQU $C010
ANDWAID EQU $C050
ANDLAID EQU $C090

*(An)+ -> Dn
ANDBAPID EQU $C018
ANDWAPID EQU $C058
ANDLAPID EQU $C098

*-(An) -> Dn
ANDBAPDD EQU $C020
ANDWAPDD EQU $C060
ANDLAPDD EQU $C0A0

*(xxx).W -> Dn
ANDBWAD EQU $C038
ANDWWAD EQU $C078
ANDLWAD EQU $C0B8

*(xxx).L -> Dn
ANDBLAD EQU $C039
ANDWLAD EQU $C079
ANDLLAD EQU $C0B9

*#<Data> -> Dn
ANDBDAD EQU $C03C
ANDWDAD EQU $C07C
ANDLDAD EQU $C0BC

*Dn -> (An)
ANDBDAI EQU $C110
ANDWDAI EQU $C150
ANDLDAI EQU $C190

*Dn -> (An)+
ANDBDAPI EQU $C118
ANDWDAPI EQU $C158
ANDLDAPI EQU $C198

*Dn -> -(An)
ANDBDAPD EQU $C120
ANDWDAPD EQU $C160
ANDLDAPD EQU $C1A0

*Dn -> (xxx).W
ANDBDWA EQU $C138
ANDWDWA EQU $C178
ANDLDWA EQU $C1B8

*Dn -> (xxx).L
ANDBDLA EQU $C139
ANDWDLA EQU $C179
ANDLDLA EQU $C1B9

*-------------OR VARIANTS---------------*
GENERAL_OR EQU $8000
GENERAL_OR_MASK EQU $F000

*Dn To Dn
ORBDD EQU $8000
ORWDD EQU $8040
ORLDD EQU $8080
*(An) to Dn
ORBAID EQU $8010
ORWAID EQU $8050
ORLAID EQU $8090
*(An)+ to Dn
ORBAPD EQU $8018
ORWAPD EQU $8058
ORLAPD EQU $8098
*-(An) to Dn
ORBADD EQU $8020
ORWADD EQU $8060
ORLADD EQU $80A0
*(xxx).W to Dn
ORBWD EQU $8038
ORWWD EQU $8078
ORLWD EQU $80B8
*(xxx).L to Dn
ORBLD EQU $8039
ORWLD EQU $8079
ORLLD EQU $80B9
*#<data> to Dn
ORBID EQU $803C
ORWID EQU $807C
ORLID EQU $80BC

*Dn to (An)
ORBDAI EQU $8110
ORWDAI EQU $8150
ORLDAI EQU $8190
*Dn to (An)+
ORBDAP EQU $8118
ORWDAP EQU $8158
ORLDAP EQU $8198
*Dn to -(An)
ORBDAD EQU $8120
ORWDAD EQU $8160
ORLDAD EQU $81A0
*Dn to (xxx).W
ORBDW EQU $8138
ORWDW EQU $8178
ORLDW EQU $81B8
*Dn to (xxx).L
ORBDL EQU $8139
ORWDL EQU $8179
ORLDL EQU $81B9

*---------------- JSR Variants-------------*
GENERAL_JSR EQU $4E80
GENERAL_JSR_MASK EQU $FFC0

*NO SIZE*

JSRMASK EQU $FFF8

*Addr reg indirect*
JSRAI EQU $4E90
*Word addr*
JSRWA EQU $4EB8
*Long addr*
JSRLA EQU $4EB9

*---------------- RTS Variants-------------*
RTSCO EQU $4E75


*---------------- BCC Variants-------------*
BCCMASK EQU $FF00
BRACO EQU $6000
BEQCO EQU $6700
BGTCO EQU $6E00
BLECO EQU $6F00


RSEAMASK EQU $FFF8 *ROL, ROR, LSL, LSR, ASL, and ASR all have the same syntax when it comes to < ea > opcode
RSDIMASK EQU $F1F8 *Same as above, but for the immediate data/ data register opcode

GENERAL_RSEA_MASK EQU $FEC0
GENERAL_RSDI_MASK EQU $F018

*---------------- ASL Variants--------------*
GENERAL_ASdEA EQU $E0C0
GENERAL_ASdDI EQU $E000

ASLAI EQU $E1D0
ASLBAI EQU $E110
ASLWAI EQU $E150
ASLLAI EQU $E190
ASLPI EQU $E1D8
ASLBPI EQU $E118
ASLWPI EQU $E158
ASLLPI EQU $E198
ASLPD EQU $E1E0
ASLBPD EQU $E120
ASLWPD EQU $E160
ASLLPD EQU $E1A0
ASLWA EQU $E1F8
ASLBWA EQU $E138
ASLWWA EQU $E178
ASLLWA EQU $E1B0
ASLLA EQU $E1F9
ASLBLA EQU $E139
ASLWLA EQU $E179
ASLLLA EQU $E1B9
ASLBD EQU $E120
ASLWD EQU $E160
ASLLD EQU $E1A0
ASLBI EQU $E100
ASLWI EQU $E140
ASLLI EQU $E180

*---------------- ASR Variants--------------*
ASRAI EQU $E0D0
ASRBAI EQU $E010
ASRWAI EQU $E050
ASRLAI EQU $E090
ASRPI EQU $E0D8
ASRBPI EQU $E018
ASRWPI EQU $E058
ASRLPI EQU $E098
ASRPD EQU $E0E0
ASRBPD EQU $E020
ASRWPD EQU $E060
ASRLPD EQU $E0A0
ASRWA EQU $E0F8
ASRBWA EQU $E038
ASRWWA EQU $E078
ASRLWA EQU $E0B0
ASRLA EQU $E0F9
ASRBLA EQU $E039
ASRWLA EQU $E079
ASRLLA EQU $E0B9
ASRBD EQU $E020
ASRWD EQU $E060
ASRLD EQU $E0A0
ASRBI EQU $E000
ASRWI EQU $E040
ASRLI EQU $E080

*--------------- LSL Variants--------------*
GENERAL_LSdEA EQU $E2C0
GENERAL_LSdDI EQU $E008

LSLAI EQU $E3D0
LSLBAI EQU $E310
LSLWAI EQU $E350
LSLLAI EQU $E390
LSLPI EQU $E3D8
LSLBPI EQU $E318
LSLWPI EQU $E358
LSLLPI EQU $E398
LSLPD EQU $E3E0
LSLBPD EQU $E320
LSLWPD EQU $E360
LSLLPD EQU $E3A0
LSLWA EQU $E3F8
LSLBWA EQU $E338
LSLWWA EQU $E378
LSLLWA EQU $E3B0
LSLLA EQU $E3F9
LSLBLA EQU $E339
LSLWLA EQU $E379
LSLLLA EQU $E3B9
LSLBD EQU $E128
LSLWD EQU $E168
LSLLD EQU $E1A8
LSLBI EQU $E108
LSLWI EQU $E148
LSLLI EQU $E188

*--------------- LSR Variants--------------*
LSRAI EQU $E2D0
LSRBAI EQU $E210
LSRWAI EQU $E250
LSRLAI EQU $E290
LSRPI EQU $E2D8
LSRBPI EQU $E218
LSRWPI EQU $E258
LSRLPI EQU $E298
LSRPD EQU $E2E0
LSRBPD EQU $E220
LSRWPD EQU $E260
LSRLPD EQU $E2A0
LSRWA EQU $E2F8
LSRBWA EQU $E238
LSRWWA EQU $E278
LSRLWA EQU $E2B0
LSRLA EQU $E2F9
LSRBLA EQU $E239
LSRWLA EQU $E279
LSRLLA EQU $E2B9
LSRBD EQU $E028
LSRWD EQU $E068
LSRLD EQU $E0A8
LSRBI EQU $E008
LSRWI EQU $E048
LSRLI EQU $E088

*--------------- ROL Variants--------------*
GENERAL_ROdEA EQU $E6C0
GENERAL_ROdDI EQU $E018

ROLAI EQU $E7D0
ROLBAI EQU $E710
ROLWAI EQU $E750
ROLLAI EQU $E790
ROLPI EQU $E7D8
ROLBPI EQU $E718
ROLWPI EQU $E758
ROLLPI EQU $E798
ROLPD EQU $E7E0
ROLBPD EQU $E720
ROLWPD EQU $E760
ROLLPD EQU $E7A0
ROLWA EQU $E7F8
ROLBWA EQU $E738
ROLWWA EQU $E778
ROLLWA EQU $E7B0
ROLLA EQU $E7F9
ROLBLA EQU $E739
ROLWLA EQU $E779
ROLLLA EQU $E7B9
ROLBD EQU $E138
ROLWD EQU $E178
ROLLD EQU $E1B8
ROLBI EQU $E118
ROLWI EQU $E158
ROLLI EQU $E198

*--------------- ROR Variants--------------*
RORAI EQU $E6D0
RORBAI EQU $E610
RORWAI EQU $E650
RORLAI EQU $E690
RORPI EQU $E6D8
RORBPI EQU $E618
RORWPI EQU $E658
RORLPI EQU $E698
RORPD EQU $E6E0
RORBPD EQU $E620
RORWPD EQU $E660
RORLPD EQU $E6A0
RORWA EQU $E6F8
RORBWA EQU $E638
RORWWA EQU $E678
RORLWA EQU $E6B0
RORLA EQU $E6F9
RORBLA EQU $E639
RORWLA EQU $E679
RORLLA EQU $E6B9
RORBD EQU $E038
RORWD EQU $E078
RORLD EQU $E0B8
RORBI EQU $E018
RORWI EQU $E058
RORLI EQU $E098


**---------------- NOT Variants-------------*
GENERAL_NOT EQU $4600
GENERAL_NOT_MASK EQU $FF00

NOTMASK EQU $FFF8
NOTAAMASK EQU $FFFF
*Data reg*
NOTBDR EQU $4600
NOTWDR EQU $4640
NOTLDR EQU $4680
*Addr reg indirect*
NOTBAI EQU $4610
NOTWAI EQU $4650
NOTLAI EQU $4690
*Addr reg postincrement*
NOTBP EQU $4618
NOTWP EQU $4658
NOTLP EQU $4698
*Addr reg predecrement*
NOTBD EQU $4620
NOTWD EQU $4660
NOTLD EQU $46A0
*Word addr*
NOTBWA EQU $4638
NOTWWA EQU $4678
NOTLWA EQU $46B8
*Long word addr*
NOTBLA EQU $4639
NOTWLA EQU $4679
NOTLLA EQU $46B9


*---------------- LEA Variants-------------*
GENERAL_LEA EQU $41C0
GENERAL_LEA_MASK EQU $F1C0

*LEA IS ONLY VALID FOR LONG WORD, THEREFORE DIDN'T SPECIFY IN THE CONSTANT NAME*
LEAMASK EQU $F1F8

*Needed to properly identify word and long addressing instructions
LEAAAMASK EQU $F1FF
*ea to indirect Addr reg*
LEAAI EQU $41D0
*ea to word address* 
LEAWA EQU $41F8
*ea to long address* 
LEALA EQU $41F9









*--------------- NOP Variants-------------*
NOPCO EQU $4E71



RESTART         *copied from NEXTPAGE code
                LEA      ENTPAGE,A1
                BSR      PRINTSTR
                MOVE.B   #5,D0 *get a char (in this case, enter key)
                TRAP     #15
                BSR      FLUSH
                
                *ask user to restart
                LEA      STARTAGAIN,A1 
                BSR      PRINTSTR
                MOVE.B   #5,D0 *get a char (y or n)
                TRAP     #15
                BSR      PRINTCRLF
                CMP.B    #$79,D1 *y ascii value
                BEQ      GETADDR1
                
                MOVE.B  #9,D0 *end of line.
                TRAP    #15 

INPUTERROR      BSR     PRINTCRLF
                LEA     ERRMSG,A1
                BSR     PRINTSTR
                JMP     GETADDR1
               
*-------------------------------------------*
*----------------IF DATA--------------------*
*-------------------------------------------*

*---------------- TEMPLATE-------------*

*ea src
IFOPCODEEA      LEA     ERRMSG,A1
                JMP     EASRC 

IFOPCODEEAXD    LEA     ERRMSG,A1
                JMP     EASRCD    

IFOPCODEEAXAI   LEA     ERRMSG,A1
                JMP     EASRCAI

IFOPCODEEAXPR   LEA     ERRMSG,A1
                JMP     EASRCPR 

IFOPCODEEAXPO   LEA     ERRMSG,A1
                JMP     EASRCPO 

*data reg dest
IFOPCODEDXD     LEA     ERRMSG,A1
                JMP     DSRCDDEST                
IFOPCODEAXD     LEA     ERRMSG,A1
                JMP     ASRCDDEST                
IFOPCODEAIXD    LEA     ERRMSG,A1
                JMP     AISRCDDEST                
IFOPCODEIXD     LEA     ERRMSG,A1
                JMP     ISRCDDEST  
IFOPCODEAAXD    LEA     ERRMSG,A1
                JMP     AASRCDDEST                
IFOPCODEPRXD    LEA     ERRMSG,A1
                JMP     PRSRCDDEST                
IFOPCODEPOXD    LEA     ERRMSG,A1
                JMP     POSRCDDEST    

*addr reg dest
IFOPCODEDXA     LEA     ERRMSG,A1
                JMP     DSRCADEST           
IFOPCODEAXA     LEA     ERRMSG,A1
                JMP     ASRCADEST                
IFOPCODEAIXA    LEA     ERRMSG,A1
                JMP     AISRCADEST                
IFOPCODEIXA     LEA     ERRMSG,A1
                JMP     ISRCADEST  
IFOPCODEAAXA    LEA     ERRMSG,A1
                JMP     AASRCADEST                
IFOPCODEPRXA    LEA     ERRMSG,A1
                JMP     PRSRCADEST                
IFOPCODEPOXA    LEA     ERRMSG,A1
                JMP     POSRCADEST  

*addr indr dest
IFOPCODEDXAI    LEA     ERRMSG,A1
                JMP     DSRCAIDEST                
IFOPCODEAXAI    LEA     ERRMSG,A1
                JMP     ASRCAIDEST                
IFOPCODEAIXAI   LEA     ERRMSG,A1
                JMP     AISRCAIDEST                
IFOPCODEIXAI    LEA     ERRMSG,A1
                JMP     ISRCAIDEST  
IFOPCODEAAXAI   LEA     ERRMSG,A1
                JMP     AASRCAIDEST               
IFOPCODEPRXAI   LEA     ERRMSG,A1
                JMP     PRSRCAIDEST                
IFOPCODEPOXAI   LEA     ERRMSG,A1
                JMP     POSRCAIDEST  

*abs addr dest
IFOPCODEDXAA    LEA     ERRMSG,A1
                JMP     DSRCAADEST                
IFOPCODEAXAA    LEA     ERRMSG,A1
                JMP     ASRCAADEST                
IFOPCODEAIXAA   LEA     ERRMSG,A1
                JMP     AISRCAADEST                
IFOPCODEIXAA    LEA     ERRMSG,A1
                JMP     ISRCAADEST  
IFOPCODEAAXAA   LEA     ERRMSG,A1
                JMP     AASRCAADEST                
IFOPCODEPRXAA   LEA     ERRMSG,A1
                JMP     PRSRCAADEST                
IFOPCODEPOXAA   LEA     ERRMSG,A1
                JMP     POSRCAADEST 

*pre decr dest
IFOPCODEDXPR    LEA     ERRMSG,A1
                JMP     DSRCPRDEST                
IFOPCODEAXPR    LEA     ERRMSG,A1
                JMP     ASRCPRDEST                
IFOPCODEAIXPR   LEA     ERRMSG,A1
                JMP     AISRCPRDEST                
IFOPCODEIXPR    LEA     ERRMSG,A1
                JMP     ISRCPRDEST  
IFOPCODEAAXPR   LEA     ERRMSG,A1
                JMP     AASRCPRDEST               
IFOPCODEPRXPR   LEA     ERRMSG,A1
                JMP     PRSRCPRDEST                
IFOPCODEPOXPR   LEA     ERRMSG,A1
                JMP     POSRCPRDEST    

*post incr dest
IFOPCODEDXPO    LEA     ERRMSG,A1
                JMP     DSRCPODEST                
IFOPCODEAXPO    LEA     ERRMSG,A1
                JMP     ASRCPODEST               
IFOPCODEAIXPO   LEA     ERRMSG,A1
                JMP     AISRCPODEST                
IFOPCODEIXPO    LEA     ERRMSG,A1
                JMP     ISRCPODEST  
IFOPCODEAAXPO   LEA     ERRMSG,A1
                JMP     AASRCPODEST                
IFOPCODEPRXPO   LEA     ERRMSG,A1
                JMP     PRSRCPODEST                
IFOPCODEPOXPO   LEA     ERRMSG,A1
                JMP     POSRCPODEST             

*---------------- MOVE Variants-------------*
  
**MOVE.B
                
*data reg dest
IFMOVEBDXD      LEA     SMOVEB,A1
                JMP     DSRCDDEST                
IFMOVEBAXD      LEA     SMOVEB,A1
                JMP     ASRCDDEST                
IFMOVEBAIXD     LEA     SMOVEB,A1
                JMP     AISRCDDEST                
IFMOVEBIXD      LEA     SMOVEB,A1
                JMP     ISRCDDEST  
IFMOVEBAAXD     LEA     SMOVEB,A1
                JMP     AASRCDDEST                
IFMOVEBPRXD     LEA     SMOVEB,A1
                JMP     PRSRCDDEST                
IFMOVEBPOXD     LEA     SMOVEB,A1
                JMP     POSRCDDEST    

*addr indr dest
IFMOVEBDXAI    LEA     SMOVEB,A1
                JMP     DSRCAIDEST                
IFMOVEBAXAI    LEA     SMOVEB,A1
                JMP     ASRCAIDEST                
IFMOVEBAIXAI   LEA     SMOVEB,A1
                JMP     AISRCAIDEST                
IFMOVEBIXAI    LEA     SMOVEB,A1
                JMP     ISRCAIDEST  
IFMOVEBAAXAI   LEA     SMOVEB,A1
                JMP     AASRCAIDEST               
IFMOVEBPRXAI   LEA     SMOVEB,A1
                JMP     PRSRCAIDEST                
IFMOVEBPOXAI   LEA     SMOVEB,A1
                JMP     POSRCAIDEST 

*abs addr dest
IFMOVEBDXAA    LEA     SMOVEB,A1
                JMP     DSRCAADEST                
IFMOVEBAXAA    LEA     SMOVEB,A1
                JMP     ASRCAADEST                
IFMOVEBAIXAA   LEA     SMOVEB,A1
                JMP     AISRCAADEST                
IFMOVEBIXAA    LEA     SMOVEB,A1
                JMP     ISRCAADEST  
IFMOVEBAAXAA   LEA     SMOVEB,A1
                JMP     AASRCAADEST                
IFMOVEBPRXAA   LEA     SMOVEB,A1
                JMP     PRSRCAADEST                
IFMOVEBPOXAA   LEA     SMOVEB,A1
                JMP     POSRCAADEST 

*pre decr dest
IFMOVEBDXPR    LEA     SMOVEB,A1
                JMP     DSRCPRDEST                
IFMOVEBAXPR    LEA     SMOVEB,A1
                JMP     ASRCPRDEST                
IFMOVEBAIXPR   LEA     SMOVEB,A1
                JMP     AISRCPRDEST                
IFMOVEBIXPR    LEA     SMOVEB,A1
                JMP     ISRCPRDEST  
IFMOVEBAAXPR   LEA     SMOVEB,A1
                JMP     AASRCPRDEST               
IFMOVEBPRXPR   LEA     SMOVEB,A1
                JMP     PRSRCPRDEST                
IFMOVEBPOXPR   LEA     SMOVEB,A1
                JMP     POSRCPRDEST    

*post incr dest
IFMOVEBDXPO    LEA     SMOVEB,A1
                JMP     DSRCPODEST                
IFMOVEBAXPO    LEA     SMOVEB,A1
                JMP     ASRCPODEST               
IFMOVEBAIXPO   LEA     SMOVEB,A1
                JMP     AISRCPODEST                
IFMOVEBIXPO    LEA     SMOVEB,A1
                JMP     ISRCPODEST  
IFMOVEBAAXPO   LEA     SMOVEB,A1
                JMP     AASRCPODEST                
IFMOVEBPRXPO   LEA     SMOVEB,A1
                JMP     PRSRCPODEST                
IFMOVEBPOXPO   LEA     SMOVEB,A1
                JMP     POSRCPODEST                 
                
**MOVE.W
                
*data reg dest
IFMOVEWDXD      LEA     SMOVEW,A1
                JMP     DSRCDDEST                
IFMOVEWAXD      LEA     SMOVEW,A1
                JMP     ASRCDDEST                
IFMOVEWAIXD     LEA     SMOVEW,A1
                JMP     AISRCDDEST                
IFMOVEWIXD      LEA     SMOVEW,A1
                JMP     ISRCDDEST  
IFMOVEWAAXD     LEA     SMOVEW,A1
                JMP     AASRCDDEST                
IFMOVEWPRXD     LEA     SMOVEW,A1
                JMP     PRSRCDDEST                
IFMOVEWPOXD     LEA     SMOVEW,A1
                JMP     POSRCDDEST    

*addr indr dest
IFMOVEWDXAI    LEA     SMOVEW,A1
                JMP     DSRCAIDEST                
IFMOVEWAXAI    LEA     SMOVEW,A1
                JMP     ASRCAIDEST                
IFMOVEWAIXAI   LEA     SMOVEW,A1
                JMP     AISRCAIDEST                
IFMOVEWIXAI    LEA     SMOVEW,A1
                JMP     ISRCAIDEST  
IFMOVEWAAXAI   LEA     SMOVEW,A1
                JMP     AASRCAIDEST               
IFMOVEWPRXAI   LEA     SMOVEW,A1
                JMP     PRSRCAIDEST                
IFMOVEWPOXAI   LEA     SMOVEW,A1
                JMP     POSRCAIDEST 

*abs addr dest
IFMOVEWDXAA    LEA     SMOVEW,A1
                JMP     DSRCAADEST                
IFMOVEWAXAA    LEA     SMOVEW,A1
                JMP     ASRCAADEST                
IFMOVEWAIXAA   LEA     SMOVEW,A1
                JMP     AISRCAADEST                
IFMOVEWIXAA    LEA     SMOVEW,A1
                JMP     ISRCAADEST  
IFMOVEWAAXAA   LEA     SMOVEW,A1
                JMP     AASRCAADEST                
IFMOVEWPRXAA   LEA     SMOVEW,A1
                JMP     PRSRCAADEST                
IFMOVEWPOXAA   LEA     SMOVEW,A1
                JMP     POSRCAADEST 

*pre decr dest
IFMOVEWDXPR    LEA     SMOVEW,A1
                JMP     DSRCPRDEST                
IFMOVEWAXPR    LEA     SMOVEW,A1
                JMP     ASRCPRDEST                
IFMOVEWAIXPR   LEA     SMOVEW,A1
                JMP     AISRCPRDEST                
IFMOVEWIXPR    LEA     SMOVEW,A1
                JMP     ISRCPRDEST  
IFMOVEWAAXPR   LEA     SMOVEW,A1
                JMP     AASRCPRDEST               
IFMOVEWPRXPR   LEA     SMOVEW,A1
                JMP     PRSRCPRDEST                
IFMOVEWPOXPR   LEA     SMOVEW,A1
                JMP     POSRCPRDEST    

*post incr dest
IFMOVEWDXPO    LEA     SMOVEW,A1
                JMP     DSRCPODEST                
IFMOVEWAXPO    LEA     SMOVEW,A1
                JMP     ASRCPODEST               
IFMOVEWAIXPO   LEA     SMOVEW,A1
                JMP     AISRCPODEST                
IFMOVEWIXPO    LEA     SMOVEW,A1
                JMP     ISRCPODEST  
IFMOVEWAAXPO   LEA     SMOVEW,A1
                JMP     AASRCPODEST                
IFMOVEWPRXPO   LEA     SMOVEW,A1
                JMP     PRSRCPODEST                
IFMOVEWPOXPO   LEA     SMOVEW,A1
                JMP     POSRCPODEST 

**MOVE.L
                
*data reg dest
IFMOVELDXD      LEA     SMOVEL,A1
                JMP     DSRCDDEST                
IFMOVELAXD      LEA     SMOVEL,A1
                JMP     ASRCDDEST                
IFMOVELAIXD     LEA     SMOVEL,A1
                JMP     AISRCDDEST                
IFMOVELIXD      LEA     SMOVEL,A1
                JMP     ISRCDDEST  
IFMOVELAAXD     LEA     SMOVEL,A1
                JMP     AASRCDDEST                
IFMOVELPRXD     LEA     SMOVEL,A1
                JMP     PRSRCDDEST                
IFMOVELPOXD     LEA     SMOVEL,A1
                JMP     POSRCDDEST    

*addr indr dest
IFMOVELDXAI    LEA     SMOVEL,A1
                JMP     DSRCAIDEST                
IFMOVELAXAI    LEA     SMOVEL,A1
                JMP     ASRCAIDEST                
IFMOVELAIXAI   LEA     SMOVEL,A1
                JMP     AISRCAIDEST                
IFMOVELIXAI    LEA     SMOVEL,A1
                JMP     ISRCAIDEST  
IFMOVELAAXAI   LEA     SMOVEL,A1
                JMP     AASRCAIDEST               
IFMOVELPRXAI   LEA     SMOVEL,A1
                JMP     PRSRCAIDEST                
IFMOVELPOXAI   LEA     SMOVEL,A1
                JMP     POSRCAIDEST 

*abs addr dest
IFMOVELDXAA    LEA     SMOVEL,A1
                JMP     DSRCAADEST                
IFMOVELAXAA    LEA     SMOVEL,A1
                JMP     ASRCAADEST                
IFMOVELAIXAA   LEA     SMOVEL,A1
                JMP     AISRCAADEST                
IFMOVELIXAA    LEA     SMOVEL,A1
                JMP     ISRCAADEST  
IFMOVELAAXAA   LEA     SMOVEL,A1
                JMP     AASRCAADEST                
IFMOVELPRXAA   LEA     SMOVEL,A1
                JMP     PRSRCAADEST                
IFMOVELPOXAA   LEA     SMOVEL,A1
                JMP     POSRCAADEST 

*pre decr dest
IFMOVELDXPR    LEA     SMOVEL,A1
                JMP     DSRCPRDEST                
IFMOVELAXPR    LEA     SMOVEL,A1
                JMP     ASRCPRDEST                
IFMOVELAIXPR   LEA     SMOVEL,A1
                JMP     AISRCPRDEST                
IFMOVELIXPR    LEA     SMOVEL,A1
                JMP     ISRCPRDEST  
IFMOVELAAXPR   LEA     SMOVEL,A1
                JMP     AASRCPRDEST               
IFMOVELPRXPR   LEA     SMOVEL,A1
                JMP     PRSRCPRDEST                
IFMOVELPOXPR   LEA     SMOVEL,A1
                JMP     POSRCPRDEST    

*post incr dest
IFMOVELDXPO    LEA     SMOVEL,A1
                JMP     DSRCPODEST                
IFMOVELAXPO    LEA     SMOVEL,A1
                JMP     ASRCPODEST               
IFMOVELAIXPO   LEA     SMOVEL,A1
                JMP     AISRCPODEST                
IFMOVELIXPO    LEA     SMOVEL,A1
                JMP     ISRCPODEST  
IFMOVELAAXPO   LEA     SMOVEL,A1
                JMP     AASRCPODEST                
IFMOVELPRXPO   LEA     SMOVEL,A1
                JMP     PRSRCPODEST                
IFMOVELPOXPO   LEA     SMOVEL,A1
                JMP     POSRCPODEST   
               
*---------------- NOP Variants-------------*                
IFNOP           LEA     SNOP,A1
                BSR     PRINTSTR
                BSR     PRINTCRLF
                JMP     CONTINUE

*---------------- MOVEA Variants-------------*
**MOVEAW
*addr reg dest
IFMOVEAWDXA     LEA     SMOVEAW,A1
                JMP     DSRCADEST           
IFMOVEAWAXA     LEA     SMOVEAW,A1
                JMP     ASRCADEST                
IFMOVEAWAIXA    LEA     SMOVEAW,A1
                JMP     AISRCADEST                
IFMOVEAWIXA     LEA     SMOVEAW,A1
                JMP     ISRCADEST  
IFMOVEAWAAXA    LEA     SMOVEAW,A1
                JMP     AASRCADEST                
IFMOVEAWPRXA    LEA     SMOVEAW,A1
                JMP     PRSRCADEST                
IFMOVEAWPOXA    LEA     SMOVEAW,A1
                JMP     POSRCADEST 

**MOVEAL
*addr reg dest
IFMOVEALDXA     LEA     SMOVEAL,A1
                JMP     DSRCADEST           
IFMOVEALAXA     LEA     SMOVEAL,A1
                JMP     ASRCADEST                
IFMOVEALAIXA    LEA     SMOVEAL,A1
                JMP     AISRCADEST                
IFMOVEALIXA     LEA     SMOVEAL,A1
                JMP     ISRCADEST  
IFMOVEALAAXA    LEA     SMOVEAL,A1
                JMP     AASRCADEST                
IFMOVEALPRXA    LEA     SMOVEAL,A1
                JMP     PRSRCADEST                
IFMOVEALPOXA    LEA     SMOVEAL,A1
                JMP     POSRCADEST 

*--------------MOVEQ VARIANTS----------------*
IFMOVEQIXD      LEA     SMOVEQ,A1
                JMP     ISRCDDEST 

*--------------ADD VARIANTS------------------*
**ADDB
*data reg dest
IFADDBDXD     LEA     SADDB,A1
                JMP     DSRCDDEST                              
IFADDBAIXD    LEA     SADDB,A1
                JMP     AISRCDDEST                
IFADDBIXD     LEA     SADDB,A1
                JMP     ISRCDDEST  
IFADDBAAXD    LEA     SADDB,A1
                JMP     AASRCDDEST                
IFADDBPRXD    LEA     SADDB,A1
                JMP     PRSRCDDEST                
IFADDBPOXD    LEA     SADDB,A1
                JMP     POSRCDDEST  
                
*addr indr dest
IFADDBDXAI    LEA     SADDB,A1
                JMP     DSRCAIDEST                

*abs addr dest
IFADDBDXAA    LEA     SADDB,A1
                JMP     DSRCAADEST                

*pre decr dest
IFADDBDXPR    LEA     SADDB,A1
                JMP     DSRCPRDEST                  

*post incr dest
IFADDBDXPO    LEA     SADDB,A1
                JMP     DSRCPODEST                                          
                
**ADDW
*data reg dest
IFADDWDXD     LEA     SADDW,A1
                JMP     DSRCDDEST                
IFADDWAXD     LEA     SADDW,A1
                JMP     ASRCDDEST                
IFADDWAIXD    LEA     SADDW,A1
                JMP     AISRCDDEST                
IFADDWIXD     LEA     SADDW,A1
                JMP     ISRCDDEST  
IFADDWAAXD    LEA     SADDW,A1
                JMP     AASRCDDEST                
IFADDWPRXD    LEA     SADDW,A1
                JMP     PRSRCDDEST                
IFADDWPOXD    LEA     SADDW,A1
                JMP     POSRCDDEST  
                
*addr indr dest
IFADDWDXAI    LEA     SADDW,A1
                JMP     DSRCAIDEST                

*abs addr dest
IFADDWDXAA    LEA     SADDW,A1
                JMP     DSRCAADEST                

*pre decr dest
IFADDWDXPR    LEA     SADDW,A1
                JMP     DSRCPRDEST                  

*post incr dest
IFADDWDXPO    LEA     SADDW,A1
                JMP     DSRCPODEST   
                
**ADDL          

*data reg dest
IFADDLDXD     LEA     SADDL,A1
                JMP     DSRCDDEST                
IFADDLAXD     LEA     SADDL,A1
                JMP     ASRCDDEST                
IFADDLAIXD    LEA     SADDL,A1
                JMP     AISRCDDEST                
IFADDLIXD     LEA     SADDL,A1
                JMP     ISRCDDEST  
IFADDLAAXD    LEA     SADDL,A1
                JMP     AASRCDDEST                
IFADDLPRXD    LEA     SADDL,A1
                JMP     PRSRCDDEST                
IFADDLPOXD    LEA     SADDL,A1 
                JMP     POSRCDDEST


 LEA ADDBWD, A1 *ADD  byte xxx.w to Dn
 MOVE.L A1, D5
  MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ ADDWWD_D
 
 LEA ADDWWD, A1 *ADD  word xxx.w to Dn
 MOVE.L A1, D5
  MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ ADDWWD_D
 
 LEA ADDLWD, A1 *ADD  Long xxx.w to Dn
 MOVE.L A1, D5
  MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ ADDLWD_D
 
 LEA ADDBLD, A1 *ADD  byte xxx.L to Dn
 MOVE.L A1, D5
  MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ ADDWWD_D
 
 LEA ADDWLD, A1 *ADD  word xxx.L to Dn
 MOVE.L A1, D5
  MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ ADDWLD_D
 
 LEA ADDLLD, A1 *ADD  Long xxx.L to Dn
 MOVE.L A1, D5
  MOVE.B #16, D1
 NOP
 LSL.L D1, D5
 CMP.L D5, D4
 BEQ ADDLLD_D
      
                
*addr indr dest
IFADDLDXAI    LEA     SADDL,A1
                JMP     DSRCAIDEST                

*abs addr dest
IFADDLDXAA    LEA     SADDL,A1
                JMP     DSRCAADEST                

*pre decr dest
IFADDLDXPR    LEA     SADDL,A1
                JMP     DSRCPRDEST                  

*post incr dest
IFADDLDXPO    LEA     SADDL,A1
                JMP     DSRCPODEST         

*--------------ADDA VARIANTS-----------------*
**ADDAW
*addr reg dest
IFADDAWDXA     LEA     SADDAW,A1
                JMP     DSRCADEST           
IFADDAWAXA     LEA     SADDAW,A1
                JMP     ASRCADEST                
IFADDAWAIXA    LEA     SADDAW,A1
                JMP     AISRCADEST                
IFADDAWIXA     LEA     SADDAW,A1
                JMP     ISRCADEST  
IFADDAWAAXA    LEA     SADDAW,A1
                JMP     AASRCADEST                
IFADDAWPRXA    LEA     SADDAW,A1
                JMP     PRSRCADEST                
IFADDAWPOXA    LEA     SADDAW,A1
                JMP     POSRCADEST 

**ADDAL

*addr reg dest
IFADDALDXA     LEA     SADDAL,A1
                JMP     DSRCADEST           
IFADDALAXA     LEA     SADDAL,A1
                JMP     ASRCADEST                
IFADDALAIXA    LEA     SADDAL,A1
                JMP     AISRCADEST                
IFADDALIXA     LEA     SADDAL,A1
                JMP     ISRCADEST  
IFADDALAAXA    LEA     SADDAL,A1
                JMP     AASRCADEST                
IFADDALPRXA    LEA     SADDAL,A1
                JMP     PRSRCADEST                
IFADDALPOXA    LEA     SADDAL,A1
                JMP     POSRCADEST 

*--------------ADDQ VARIANTS-----------------*
**ADDQB
*data reg dest             
IFADDQBIXD     LEA     SADDQB,A1
                JMP     ISRCDDEST   

*addr reg dest               
IFADDQBIXA     LEA     SADDQB,A1
                JMP     ISRCADEST  

*addr indr dest             
IFADDQBIXAI    LEA     SADDQB,A1
                JMP     ISRCAIDEST  

*abs addr dest             
IFADDQBIXAA    LEA     SADDQB,A1
                JMP     ISRCAADEST  

*pre decr dest                
IFADDQBIXPR    LEA     SADDQB,A1
                JMP     ISRCPRDEST   

*post incr dest            
IFADDQBIXPO    LEA     SADDQB,A1
                JMP     ISRCPODEST  

**ADDQW
*data reg dest 
IFADDQWIXD     LEA     SADDQW,A1
                JMP     ISRCDDEST   

*addr reg dest               
IFADDQWIXA     LEA     SADDQW,A1
                JMP     ISRCADEST  

*addr indr dest             
IFADDQWIXAI    LEA     SADDQW,A1
                JMP     ISRCAIDEST  

*abs addr dest             
IFADDQWIXAA    LEA     SADDQW,A1
                JMP     ISRCAADEST  

*pre decr dest                
IFADDQWIXPR    LEA     SADDQW,A1
                JMP     ISRCPRDEST   

*post incr dest            
IFADDQWIXPO    LEA     SADDQW,A1
                JMP     ISRCPODEST 

**ADDQL
*data reg dest 
IFADDQLIXD     LEA     SADDQL,A1
                JMP     ISRCDDEST   

*addr reg dest               
IFADDQLIXA     LEA     SADDQL,A1
                JMP     ISRCADEST  
                
*addr indr dest             
IFADDQLIXAI    LEA     SADDQL,A1
                JMP     ISRCAIDEST  

*abs addr dest             
IFADDQLIXAA    LEA     SADDQL,A1
                JMP     ISRCAADEST  

*pre decr dest                
IFADDQLIXPR    LEA     SADDQL,A1
                JMP     ISRCPRDEST   

*post incr dest            
IFADDQLIXPO    LEA     SADDQL,A1
                JMP     ISRCPODEST  

*--------------------SUB VARIANTS------------*
**SUBB
*data reg dest
IFSUBBDXD     LEA     SSUBB,A1
                JMP     DSRCDDEST                              
IFSUBBAIXD    LEA     SSUBB,A1
                JMP     AISRCDDEST                
IFSUBBIXD     LEA     SSUBB,A1
                JMP     ISRCDDEST  
IFSUBBAAXD    LEA     SSUBB,A1
                JMP     AASRCDDEST                
IFSUBBPRXD    LEA     SSUBB,A1
                JMP     PRSRCDDEST                
IFSUBBPOXD    LEA     SSUBB,A1
                JMP     POSRCDDEST  
                
*addr indr dest
IFSUBBDXAI    LEA     SSUBB,A1
                JMP     DSRCAIDEST                

*abs addr dest
IFSUBBDXAA    LEA     SSUBB,A1
                JMP     DSRCAADEST                

*pre decr dest
IFSUBBDXPR    LEA     SSUBB,A1
                JMP     DSRCPRDEST                  

*post incr dest
IFSUBBDXPO    LEA     SSUBB,A1
                JMP     DSRCPODEST                                          
                
**SUBW
*data reg dest
IFSUBWDXD     LEA     SSUBW,A1
                JMP     DSRCDDEST                
IFSUBWAXD     LEA     SSUBW,A1
                JMP     ASRCDDEST                
IFSUBWAIXD    LEA     SSUBW,A1
                JMP     AISRCDDEST                
IFSUBWIXD     LEA     SSUBW,A1
                JMP     ISRCDDEST  
IFSUBWAAXD    LEA     SSUBW,A1
                JMP     AASRCDDEST                
IFSUBWPRXD    LEA     SSUBW,A1
                JMP     PRSRCDDEST                
IFSUBWPOXD    LEA     SSUBW,A1
                JMP     POSRCDDEST  
                
*addr indr dest
IFSUBWDXAI    LEA     SSUBW,A1
                JMP     DSRCAIDEST                

*abs addr dest
IFSUBWDXAA    LEA     SSUBW,A1
                JMP     DSRCAADEST                

*pre decr dest
IFSUBWDXPR    LEA     SSUBW,A1
                JMP     DSRCPRDEST                  

*post incr dest
IFSUBWDXPO    LEA     SSUBW,A1
                JMP     DSRCPODEST   
                
**SUBL          

*data reg dest
IFSUBLDXD     LEA     SSUBL,A1
                JMP     DSRCDDEST                
IFSUBLAXD     LEA     SSUBL,A1
                JMP     ASRCDDEST                
IFSUBLAIXD    LEA     SSUBL,A1
                JMP     AISRCDDEST                
IFSUBLIXD     LEA     SSUBL,A1
                JMP     ISRCDDEST  
IFSUBLAAXD    LEA     SSUBL,A1
                JMP     AASRCDDEST                
IFSUBLPRXD    LEA     SSUBL,A1
                JMP     PRSRCDDEST                
IFSUBLPOXD    LEA     SSUBL,A1
                JMP     POSRCDDEST  
                
*addr indr dest
IFSUBLDXAI    LEA     SSUBL,A1
                JMP     DSRCAIDEST                

*abs addr dest
IFSUBLDXAA    LEA     SSUBL,A1
                JMP     DSRCAADEST                

*pre decr dest
IFSUBLDXPR    LEA     SSUBL,A1
                JMP     DSRCPRDEST                  

*post incr dest
IFSUBLDXPO    LEA     SSUBL,A1
                JMP     DSRCPODEST 

*---------------- LEA Variants-------------*
*addr reg dest                          
IFLEAAIXA      LEA     SLEA,A1
                JMP     AISRCADEST                 
IFLEAAAXA      LEA     SLEA,A1
                JMP     AASRCADEST               

*---------------- NOT Variants-------------*
**NOT.B
*effective addresses
IFNOTBEA         LEA     SNOTB,A1
                JMP     EASRC 

IFNOTBEAXD       LEA     SNOTB,A1
                JMP     EASRCD    

IFNOTBEAXAI      LEA     SNOTB,A1
                JMP     EASRCAI

IFNOTBEAXPR      LEA     SNOTB,A1
                JMP     EASRCPR 

IFNOTBEAXPO      LEA     SNOTB,A1
                JMP     EASRCPO 
                
**NOT.W
*effective addresses
IFNOTWEA         LEA     SNOTW,A1
                JMP     EASRC 

IFNOTWEAXD       LEA     SNOTW,A1
                JMP     EASRCD    

IFNOTWEAXAI      LEA     SNOTW,A1
                JMP     EASRCAI

IFNOTWEAXPR      LEA     SNOTW,A1
                JMP     EASRCPR 

IFNOTWEAXPO      LEA     SNOTW,A1
                JMP     EASRCPO 

**NOT.L
*effective addresses
IFNOTLEA         LEA     SNOTL,A1
                JMP     EASRC 

IFNOTLEAXD       LEA     SNOTL,A1
                JMP     EASRCD    

IFNOTLEAXAI      LEA     SNOTL,A1
                JMP     EASRCAI

IFNOTLEAXPR      LEA     SNOTL,A1
                JMP     EASRCPR 

IFNOTLEAXPO      LEA     SNOTL,A1
                JMP     EASRCPO                 

*---------------- AND Variants-------------*
**ANDB
*data reg dest
IFANDBDXD     LEA     SANDB,A1
                JMP     DSRCDDEST                              
IFANDBAIXD    LEA     SANDB,A1
                JMP     AISRCDDEST                
IFANDBIXD     LEA     SANDB,A1
                JMP     ISRCDDEST  
IFANDBAAXD    LEA     SANDB,A1
                JMP     AASRCDDEST                
IFANDBPRXD    LEA     SANDB,A1
                JMP     PRSRCDDEST                
IFANDBPOXD    LEA     SANDB,A1
                JMP     POSRCDDEST  
                
*addr indr dest
IFANDBDXAI    LEA     SANDB,A1
                JMP     DSRCAIDEST                

*abs addr dest
IFANDBDXAA    LEA     SANDB,A1
                JMP     DSRCAADEST                

*pre decr dest
IFANDBDXPR    LEA     SANDB,A1
                JMP     DSRCPRDEST                  

*post incr dest
IFANDBDXPO    LEA     SANDB,A1
                JMP     DSRCPODEST                                          
                
**ANDW
*data reg dest
IFANDWDXD     LEA     SANDW,A1
                JMP     DSRCDDEST                              
IFANDWAIXD    LEA     SANDW,A1
                JMP     AISRCDDEST                
IFANDWIXD     LEA     SANDW,A1
                JMP     ISRCDDEST  
IFANDWAAXD    LEA     SANDW,A1
                JMP     AASRCDDEST                
IFANDWPRXD    LEA     SANDW,A1
                JMP     PRSRCDDEST                
IFANDWPOXD    LEA     SANDW,A1
                JMP     POSRCDDEST  
                
*addr indr dest
IFANDWDXAI    LEA     SANDW,A1
                JMP     DSRCAIDEST                

*abs addr dest
IFANDWDXAA    LEA     SANDW,A1
                JMP     DSRCAADEST                

*pre decr dest
IFANDWDXPR    LEA     SANDW,A1
                JMP     DSRCPRDEST                  

*post incr dest
IFANDWDXPO    LEA     SANDW,A1
                JMP     DSRCPODEST   
                
**ANDL          

*data reg dest
IFANDLDXD     LEA     SANDL,A1
                JMP     DSRCDDEST                               
IFANDLAIXD    LEA     SANDL,A1
                JMP     AISRCDDEST                
IFANDLIXD     LEA     SANDL,A1
                JMP     ISRCDDEST  
IFANDLAAXD    LEA     SANDL,A1
                JMP     AASRCDDEST                
IFANDLPRXD    LEA     SANDL,A1
                JMP     PRSRCDDEST                
IFANDLPOXD    LEA     SANDL,A1
                JMP     POSRCDDEST  
                
*addr indr dest
IFANDLDXAI    LEA     SANDL,A1
                JMP     DSRCAIDEST                

*abs addr dest
IFANDLDXAA    LEA     SANDL,A1
                JMP     DSRCAADEST                

*pre decr dest
IFANDLDXPR    LEA     SANDL,A1
                JMP     DSRCPRDEST                  

*post incr dest
IFANDLDXPO    LEA     SANDL,A1
                JMP     DSRCPODEST 

*---------------- OR Variants--------------*
**ORB
*data reg dest
IFORBDXD     LEA     SORB,A1
                JMP     DSRCDDEST                              
IFORBAIXD    LEA     SORB,A1
                JMP     AISRCDDEST                
IFORBIXD     LEA     SORB,A1
                JMP     ISRCDDEST  
IFORBAAXD    LEA     SORB,A1
                JMP     AASRCDDEST                
IFORBPRXD    LEA     SORB,A1
                JMP     PRSRCDDEST                
IFORBPOXD    LEA     SORB,A1
                JMP     POSRCDDEST  
                
*addr indr dest
IFORBDXAI    LEA     SORB,A1
                JMP     DSRCAIDEST                

*abs addr dest
IFORBDXAA    LEA     SORB,A1
                JMP     DSRCAADEST                

*pre decr dest
IFORBDXPR    LEA     SORB,A1
                JMP     DSRCPRDEST                  

*post incr dest
IFORBDXPO    LEA     SORB,A1
                JMP     DSRCPODEST                                          
                
**ORW
*data reg dest
IFORWDXD     LEA     SORW,A1
                JMP     DSRCDDEST                              
IFORWAIXD    LEA     SORW,A1
                JMP     AISRCDDEST                
IFORWIXD     LEA     SORW,A1
                JMP     ISRCDDEST  
IFORWAAXD    LEA     SORW,A1
                JMP     AASRCDDEST                
IFORWPRXD    LEA     SORW,A1
                JMP     PRSRCDDEST                
IFORWPOXD    LEA     SORW,A1
                JMP     POSRCDDEST  
                
*addr indr dest
IFORWDXAI    LEA     SORW,A1
                JMP     DSRCAIDEST                

*abs addr dest
IFORWDXAA    LEA     SORW,A1
                JMP     DSRCAADEST                

*pre decr dest
IFORWDXPR    LEA     SORW,A1
                JMP     DSRCPRDEST                  

*post incr dest
IFORWDXPO    LEA     SORW,A1
                JMP     DSRCPODEST   
                
**ORL          

*data reg dest
IFORLDXD     LEA     SORL,A1
                JMP     DSRCDDEST                               
IFORLAIXD    LEA     SORL,A1
                JMP     AISRCDDEST                
IFORLIXD     LEA     SORL,A1
                JMP     ISRCDDEST  
IFORLAAXD    LEA     SORL,A1
                JMP     AASRCDDEST                
IFORLPRXD    LEA     SORL,A1
                JMP     PRSRCDDEST                
IFORLPOXD    LEA     SORL,A1
                JMP     POSRCDDEST  
                
*addr indr dest
IFORLDXAI    LEA     SORL,A1
                JMP     DSRCAIDEST                

*abs addr dest
IFORLDXAA    LEA     SORL,A1
                JMP     DSRCAADEST                

*pre decr dest
IFORLDXPR    LEA     SORL,A1
                JMP     DSRCPRDEST                  

*post incr dest
IFORLDXPO    LEA     SORL,A1
                JMP     DSRCPODEST 
                
*---------------- JSR Variants-------------*
*ea src
IFJSREA         LEA     SJSR,A1
                JMP     EASRC    

IFJSRAXAI       LEA     SJSR,A1
                JMP     EASRCAI  

*---------------- RTS Variants-------------*
IFRTS           LEA     SRTS,A1
                BSR     PRINTSTR
                BSR     PRINTCRLF
                JMP     CONTINUE

*---------------- Bcc Variants-------------*
IFBRA           LEA     SBRA,A1
                JMP     EASRC    
                
IFBGT           LEA     SBGT,A1
                JMP     EASRC    

IFBLE           LEA     SBLE,A1
                JMP     EASRC    

IFBEQ           LEA     SBEQ,A1
                JMP     EASRC                    

*---------------- ASL Variants--------------*
**ASL
*data reg dest
IFASLDXD        LEA     SASL,A1
                JMP     DSRCDDEST  
IFASLIXD        LEA     SASL,A1
                JMP     ISRCDDEST                 

*effective addresses
IFASLEA         LEA     SASL,A1
                JMP     EASRC    

IFASLEAXAI      LEA     SASL,A1
                JMP     EASRCAI

IFASLEAXPR      LEA     SASL,A1
                JMP     EASRCPR 

IFASLEAXPO      LEA     SASL,A1
                JMP     EASRCPO 

**ASL.B
*data reg dest
IFASLBDXD       LEA     SASLB,A1
                JMP     DSRCDDEST  
IFASLBIXD       LEA     SASLB,A1
                JMP     ISRCDDEST                 

*effective addresses
IFASLBEA        LEA     SASLB,A1
                JMP     EASRC    

IFASLBEAXAI     LEA     SASLB,A1
                JMP     EASRCAI

IFASLBEAXPR     LEA     SASLB,A1
                JMP     EASRCPR 

IFASLBEAXPO     LEA     SASLB,A1
                JMP     EASRCPO 

**ASL.W
*data reg dest
IFASLWDXD       LEA     SASLW,A1
                JMP     DSRCDDEST  
IFASLWIXD       LEA     SASLW,A1
                JMP     ISRCDDEST                 

*effective addresses
IFASLWEA        LEA     SASLW,A1
                JMP     EASRC    

IFASLWEAXAI     LEA     SASLW,A1
                JMP     EASRCAI

IFASLWEAXPR     LEA     SASLW,A1
                JMP     EASRCPR 

IFASLWEAXPO     LEA     SASLW,A1
                JMP     EASRCPO 

**ASL.L
*data reg dest
IFASLLDXD       LEA     SASLL,A1
                JMP     DSRCDDEST  
IFASLLIXD       LEA     SASLL,A1
                JMP     ISRCDDEST                 

*effective addresses
IFASLLEA        LEA     SASLL,A1
                JMP     EASRC    

IFASLLEAXAI     LEA     SASLL,A1
                JMP     EASRCAI

IFASLLEAXPR     LEA     SASLL,A1
                JMP     EASRCPR 

IFASLLEAXPO     LEA     SASLL,A1
                JMP     EASRCPO 

*---------------- ASR Variants--------------*
**ASR
*data reg dest
IFASRDXD        LEA     SASR,A1
                JMP     DSRCDDEST  
IFASRIXD        LEA     SASR,A1
                JMP     ISRCDDEST                 

*effective addresses
IFASREA         LEA     SASR,A1
                JMP     EASRC    

IFASREAXAI      LEA     SASR,A1
                JMP     EASRCAI

IFASREAXPR      LEA     SASR,A1
                JMP     EASRCPR 

IFASREAXPO      LEA     SASR,A1
                JMP     EASRCPO 

**ASR.B
*data reg dest
IFASRBDXD       LEA     SASRB,A1
                JMP     DSRCDDEST  
IFASRBIXD       LEA     SASRB,A1
                JMP     ISRCDDEST                 

*effective addresses
IFASRBEA        LEA     SASRB,A1
                JMP     EASRC    

IFASRBEAXAI     LEA     SASRB,A1
                JMP     EASRCAI

IFASRBEAXPR     LEA     SASRB,A1
                JMP     EASRCPR 

IFASRBEAXPO     LEA     SASRB,A1
                JMP     EASRCPO 

**ASR.W
*data reg dest
IFASRWDXD       LEA     SASRW,A1
                JMP     DSRCDDEST  
IFASRWIXD       LEA     SASRW,A1
                JMP     ISRCDDEST                 

*effective addresses
IFASRWEA        LEA     SASRW,A1
                JMP     EASRC    

IFASRWEAXAI     LEA     SASRW,A1
                JMP     EASRCAI

IFASRWEAXPR     LEA     SASRW,A1
                JMP     EASRCPR 

IFASRWEAXPO     LEA     SASRW,A1
                JMP     EASRCPO 

**ASR.L
*data reg dest
IFASRLDXD       LEA     SASRL,A1
                JMP     DSRCDDEST  
IFASRLIXD       LEA     SASRL,A1
                JMP     ISRCDDEST                 

*effective addresses
IFASRLEA        LEA     SASRL,A1
                JMP     EASRC    

IFASRLEAXAI     LEA     SASRL,A1
                JMP     EASRCAI

IFASRLEAXPR     LEA     SASRL,A1
                JMP     EASRCPR 

IFASRLEAXPO     LEA     SASRL,A1
                JMP     EASRCPO 

*--------------- LSL Variants--------------*
**LSL
*data reg dest
IFLSLDXD        LEA     SLSL,A1
                JMP     DSRCDDEST  
IFLSLIXD        LEA     SLSL,A1
                JMP     ISRCDDEST                 

*effective addresses
IFLSLEA         LEA     SLSL,A1
                JMP     EASRC    

IFLSLEAXAI      LEA     SLSL,A1
                JMP     EASRCAI

IFLSLEAXPR      LEA     SLSL,A1
                JMP     EASRCPR 

IFLSLEAXPO      LEA     SLSL,A1
                JMP     EASRCPO 

**LSL.B
*data reg dest
IFLSLBDXD       LEA     SLSLB,A1
                JMP     DSRCDDEST  
IFLSLBIXD       LEA     SLSLB,A1
                JMP     ISRCDDEST                 

*effective addresses
IFLSLBEA        LEA     SLSLB,A1
                JMP     EASRC    

IFLSLBEAXAI     LEA     SLSLB,A1
                JMP     EASRCAI

IFLSLBEAXPR     LEA     SLSLB,A1
                JMP     EASRCPR 

IFLSLBEAXPO     LEA     SLSLB,A1
                JMP     EASRCPO 

**LSL.W
*data reg dest
IFLSLWDXD       LEA     SLSLW,A1
                JMP     DSRCDDEST  
IFLSLWIXD       LEA     SLSLW,A1
                JMP     ISRCDDEST                 

*effective addresses
IFLSLWEA        LEA     SLSLW,A1
                JMP     EASRC    

IFLSLWEAXAI     LEA     SLSLW,A1
                JMP     EASRCAI

IFLSLWEAXPR     LEA     SLSLW,A1
                JMP     EASRCPR 

IFLSLWEAXPO     LEA     SLSLW,A1
                JMP     EASRCPO 

**LSL.L
*data reg dest
IFLSLLDXD       LEA     SLSLL,A1
                JMP     DSRCDDEST  
IFLSLLIXD       LEA     SLSLL,A1
                JMP     ISRCDDEST                 

*effective addresses
IFLSLLEA        LEA     SLSLL,A1
                JMP     EASRC    

IFLSLLEAXAI     LEA     SLSLL,A1
                JMP     EASRCAI

IFLSLLEAXPR     LEA     SLSLL,A1
                JMP     EASRCPR 

IFLSLLEAXPO     LEA     SLSLL,A1
                JMP     EASRCPO 

*--------------- LSR Variants--------------*
**LSR
*data reg dest
IFLSRDXD        LEA     SLSR,A1
                JMP     DSRCDDEST  
IFLSRIXD        LEA     SLSR,A1
                JMP     ISRCDDEST                 

*effective addresses
IFLSREA         LEA     SLSR,A1
                JMP     EASRC    

IFLSREAXAI      LEA     SLSR,A1
                JMP     EASRCAI

IFLSREAXPR      LEA     SLSR,A1
                JMP     EASRCPR 

IFLSREAXPO      LEA     SLSR,A1
                JMP     EASRCPO 

**LSR.B
*data reg dest
IFLSRBDXD       LEA     SLSRB,A1
                JMP     DSRCDDEST  
IFLSRBIXD       LEA     SLSRB,A1
                JMP     ISRCDDEST                 

*effective addresses
IFLSRBEA        LEA     SLSRB,A1
                JMP     EASRC    

IFLSRBEAXAI     LEA     SLSRB,A1
                JMP     EASRCAI

IFLSRBEAXPR     LEA     SLSRB,A1
                JMP     EASRCPR 

IFLSRBEAXPO     LEA     SLSRB,A1
                JMP     EASRCPO 

**LSR.W
*data reg dest
IFLSRWDXD       LEA     SLSRW,A1
                JMP     DSRCDDEST  
IFLSRWIXD       LEA     SLSRW,A1
                JMP     ISRCDDEST                 

*effective addresses
IFLSRWEA        LEA     SLSRW,A1
                JMP     EASRC    

IFLSRWEAXAI     LEA     SLSRW,A1
                JMP     EASRCAI

IFLSRWEAXPR     LEA     SLSRW,A1
                JMP     EASRCPR 

IFLSRWEAXPO     LEA     SLSRW,A1
                JMP     EASRCPO 

**LSR.L
*data reg dest
IFLSRLDXD       LEA     SLSRL,A1
                JMP     DSRCDDEST  
IFLSRLIXD       LEA     SLSRL,A1
                JMP     ISRCDDEST                 

*effective addresses
IFLSRLEA        LEA     SLSRL,A1
                JMP     EASRC    

IFLSRLEAXAI     LEA     SLSRL,A1
                JMP     EASRCAI

IFLSRLEAXPR     LEA     SLSRL,A1
                JMP     EASRCPR 

IFLSRLEAXPO     LEA     SLSRL,A1
                JMP     EASRCPO 

*--------------- ROL Variants--------------*
**ROL
*data reg dest
IFROLDXD        LEA     SROL,A1
                JMP     DSRCDDEST  
IFROLIXD        LEA     SROL,A1
                JMP     ISRCDDEST                 

*effective addresses
IFROLEA         LEA     SROL,A1
                JMP     EASRC    

IFROLEAXAI      LEA     SROL,A1
                JMP     EASRCAI

IFROLEAXPR      LEA     SROL,A1
                JMP     EASRCPR 

IFROLEAXPO      LEA     SROL,A1
                JMP     EASRCPO 

**ROL.B
*data reg dest
IFROLBDXD       LEA     SROLB,A1
                JMP     DSRCDDEST  
IFROLBIXD       LEA     SROLB,A1
                JMP     ISRCDDEST                 

*effective addresses
IFROLBEA        LEA     SROLB,A1
                JMP     EASRC    

IFROLBEAXAI     LEA     SROLB,A1
                JMP     EASRCAI

IFROLBEAXPR     LEA     SROLB,A1
                JMP     EASRCPR 

IFROLBEAXPO     LEA     SROLB,A1
                JMP     EASRCPO 

**ROL.W
*data reg dest
IFROLWDXD       LEA     SROLW,A1
                JMP     DSRCDDEST  
IFROLWIXD       LEA     SROLW,A1
                JMP     ISRCDDEST                 

*effective addresses
IFROLWEA        LEA     SROLW,A1
                JMP     EASRC    

IFROLWEAXAI     LEA     SROLW,A1
                JMP     EASRCAI

IFROLWEAXPR     LEA     SROLW,A1
                JMP     EASRCPR 

IFROLWEAXPO     LEA     SROLW,A1
                JMP     EASRCPO 

**ROL.L
*data reg dest
IFROLLDXD       LEA     SROLL,A1
                JMP     DSRCDDEST  
IFROLLIXD       LEA     SROLL,A1
                JMP     ISRCDDEST                 

*effective addresses
IFROLLEA        LEA     SROLL,A1
                JMP     EASRC    

IFROLLEAXAI     LEA     SROLL,A1
                JMP     EASRCAI

IFROLLEAXPR     LEA     SROLL,A1
                JMP     EASRCPR 

IFROLLEAXPO     LEA     SROLL,A1
                JMP     EASRCPO 

*--------------- ROR Variants--------------*
**ROR
*data reg dest
IFRORDXD        LEA     SROR,A1
                JMP     DSRCDDEST  
IFRORIXD        LEA     SROR,A1
                JMP     ISRCDDEST                 

*effective addresses
IFROREA         LEA     SROR,A1
                JMP     EASRC    

IFROREAXAI      LEA     SROR,A1
                JMP     EASRCAI

IFROREAXPR      LEA     SROR,A1
                JMP     EASRCPR 

IFROREAXPO      LEA     SROR,A1
                JMP     EASRCPO 

**ROR.B
*data reg dest
IFRORBDXD       LEA     SRORB,A1
                JMP     DSRCDDEST  
IFRORBIXD       LEA     SRORB,A1
                JMP     ISRCDDEST                 

*effective addresses
IFRORBEA        LEA     SRORB,A1
                JMP     EASRC    

IFRORBEAXAI     LEA     SRORB,A1
                JMP     EASRCAI

IFRORBEAXPR     LEA     SRORB,A1
                JMP     EASRCPR 

IFRORBEAXPO     LEA     SRORB,A1
                JMP     EASRCPO 

**ROR.W
*data reg dest
IFRORWDXD       LEA     SRORW,A1
                JMP     DSRCDDEST  
IFRORWIXD       LEA     SRORW,A1
                JMP     ISRCDDEST                 

*effective addresses
IFRORWEA        LEA     SRORW,A1
                JMP     EASRC    

IFRORWEAXAI     LEA     SRORW,A1
                JMP     EASRCAI

IFRORWEAXPR     LEA     SRORW,A1
                JMP     EASRCPR 

IFRORWEAXPO     LEA     SRORW,A1
                JMP     EASRCPO 

**ROR.L
*data reg dest
IFRORLDXD       LEA     SRORL,A1
                JMP     DSRCDDEST  
IFRORLIXD       LEA     SRORL,A1
                JMP     ISRCDDEST                 

*effective addresses
IFRORLEA        LEA     SRORL,A1
                JMP     EASRC    

IFRORLEAXAI     LEA     SRORL,A1
                JMP     EASRCAI

IFRORLEAXPR     LEA     SRORL,A1
                JMP     EASRCPR 

IFRORLEAXPO     LEA     SRORL,A1
                JMP     EASRCPO    
               
*----------------Bad Data-------------*             
IFBADDATA       LEA     DATA,A1
                BSR     PRINTSTR
                BSR     PRINTAASRC
                BSR     PRINTCRLF
                JMP     CONTINUE  
                
IFINVADDRMODE   LEA     OPCODE,A1
                BSR     PRINTSTR
                BSR     PRINTBADOP
                LEA     INVADDR,A1
                BSR     PRINTSTR
                BSR     PRINTCRLF
                JMP     CONTINUE                 

*-------------------------------------------*
*----------------OPERAND DATA----------------*
*-------------------------------------------*                 
*guess this is now a section now
*i was hoping for the one buggy EA but nope
*effective addresses
EASRC           BSR     PRINTSTR *EA SPORTS ITS IN THE GAME
                BSR     PRINTAASRC
                BSR     PRINTCRLF
                JMP     CONTINUE
                
EASRCAI         BSR     PRINTSTR
                LEA     AISRC,A1
                BSR     FIRSTOP
                LEA     CLPAR,A1
                BSR     PRINTSTR
                BSR     PRINTCRLF
                JMP     CONTINUE 

EASRCPR         BSR     PRINTSTR
                LEA     PRSRC,A1
                BSR     FIRSTOP
                LEA     CLPAR,A1
                BSR     PRINTSTR 
                BSR     PRINTCRLF
                JMP     CONTINUE

EASRCPO         BSR     PRINTSTR
                LEA     AISRC,A1
                BSR     FIRSTOP
                LEA     PODEST,A1
                BSR     PRINTSTR
                BSR     PRINTCRLF
                JMP     CONTINUE 

EASRCD          BSR     PRINTSTR
                LEA     DSRC,A1
                BSR     FIRSTOP
                BSR     PRINTCRLF
                JMP     CONTINUE    

*----------------Data Register Dest-----------*

*data reg to data reg
DSRCDDEST       BSR     PRINTSTR
                LEA     DSRC,A1
                BSR     FIRSTOP
                LEA     DDEST,A1
                BSR     SECONDOP
                BSR     PRINTCRLF
                JMP     CONTINUE  
 
*addr reg to data reg               
ASRCDDEST       BSR     PRINTSTR
                LEA     ASRC,A1
                BSR     FIRSTOP
                LEA     DDEST,A1
                BSR     SECONDOP
                BSR     PRINTCRLF
                JMP     CONTINUE   

*addr indirect to data reg 
AISRCDDEST      BSR     PRINTSTR
                LEA     AISRC,A1
                BSR     FIRSTOP
                LEA     CLPAR,A1
                BSR     PRINTSTR
                LEA     DDEST,A1
                BSR     SECONDOP
                BSR     PRINTCRLF
                JMP     CONTINUE     

*immediate data to data reg
ISRCDDEST       BSR     PRINTSTR
                LEA     ISRC,A1
                BSR     FIRSTOP
                LEA     DDEST,A1
                BSR     SECONDOP
                BSR     PRINTCRLF
                JMP     CONTINUE   

*abs addr to data reg                
AASRCDDEST      BSR     PRINTSTR
                BSR     PRINTAASRC
                LEA     DDEST,A1
                BSR     SECONDOP
                BSR     PRINTCRLF
                JMP     CONTINUE   

*pre decr to data reg
PRSRCDDEST      BSR     PRINTSTR
                LEA     PRSRC,A1
                BSR     FIRSTOP
                LEA     CLPAR,A1
                BSR     PRINTSTR
                LEA     DDEST,A1
                BSR     SECONDOP
                BSR     PRINTCRLF
                JMP     CONTINUE    

*post incre to data reg
POSRCDDEST      BSR     PRINTSTR
                LEA     AISRC,A1
                BSR     FIRSTOP
                LEA     PODEST,A1
                BSR     PRINTSTR
                LEA     DDEST,A1
                BSR     SECONDOP
                BSR     PRINTCRLF
                JMP     CONTINUE   

*----------------Address Register Dest-----------* 
               
*data reg to addr reg
DSRCADEST       BSR     PRINTSTR
                LEA     DSRC,A1
                BSR     FIRSTOP
                LEA     ADEST,A1
                BSR     SECONDOP
                BSR     PRINTCRLF
                JMP     CONTINUE  
 
*addr reg to addr reg               
ASRCADEST       BSR     PRINTSTR
                LEA     ASRC,A1
                BSR     FIRSTOP
                LEA     ADEST,A1
                BSR     SECONDOP
                BSR     PRINTCRLF
                JMP     CONTINUE   

*addr indirect to addr reg 
AISRCADEST      BSR     PRINTSTR
                LEA     AISRC,A1
                BSR     FIRSTOP
                LEA     CLPAR,A1
                BSR     PRINTSTR
                LEA     ADEST,A1
                BSR     SECONDOP
                BSR     PRINTCRLF
                JMP     CONTINUE     

*immediate data to addr reg
ISRCADEST       BSR     PRINTSTR
                LEA     ISRC,A1
                BSR     FIRSTOP
                LEA     ADEST,A1
                BSR     SECONDOP
                BSR     PRINTCRLF
                JMP     CONTINUE   

*abs addr to addr reg                
AASRCADEST      BSR     PRINTSTR
                BSR     PRINTAASRC
                LEA     ADEST,A1
                BSR     SECONDOP
                BSR     PRINTCRLF
                JMP     CONTINUE   

*pre decr to addr reg
PRSRCADEST      BSR     PRINTSTR
                LEA     PRSRC,A1
                BSR     FIRSTOP
                LEA     CLPAR,A1
                BSR     PRINTSTR
                LEA     ADEST,A1
                BSR     SECONDOP
                BSR     PRINTCRLF
                JMP     CONTINUE    

*post incre to addr reg
POSRCADEST      BSR     PRINTSTR
                LEA     AISRC,A1
                BSR     FIRSTOP
                LEA     PODEST,A1
                BSR     PRINTSTR
                LEA     ADEST,A1
                BSR     SECONDOP
                BSR     PRINTCRLF
                JMP     CONTINUE      

*----Address Register Indirect Dest----------* 
               
*data reg to addr indirect
DSRCAIDEST      BSR     PRINTSTR
                LEA     DSRC,A1
                BSR     FIRSTOP
                LEA     AIDEST,A1
                BSR     SECONDOP
                LEA     CLPAR,A1
                BSR     PRINTSTR
                BSR     PRINTCRLF
                JMP     CONTINUE  
 
*addr reg to addr indirect
ASRCAIDEST      BSR     PRINTSTR
                LEA     ASRC,A1
                BSR     FIRSTOP
                LEA     AIDEST,A1
                BSR     SECONDOP
                LEA     CLPAR,A1
                BSR     PRINTSTR
                BSR     PRINTCRLF
                JMP     CONTINUE   

*addr indirect to addr indirect
AISRCAIDEST     BSR     PRINTSTR
                LEA     AISRC,A1
                BSR     FIRSTOP
                LEA     CLPAR,A1
                BSR     PRINTSTR
                LEA     AIDEST,A1
                BSR     SECONDOP
                LEA     CLPAR,A1
                BSR     PRINTSTR
                BSR     PRINTCRLF
                JMP     CONTINUE     

*immediate data to addr indirect
ISRCAIDEST      BSR     PRINTSTR
                LEA     ISRC,A1
                BSR     FIRSTOP
                LEA     AIDEST,A1
                BSR     SECONDOP
                LEA     CLPAR,A1
                BSR     PRINTSTR
                BSR     PRINTCRLF
                JMP     CONTINUE   

*abs addr to addr indirect
AASRCAIDEST     BSR     PRINTSTR
                BSR     PRINTAASRC
                LEA     AIDEST,A1
                BSR     SECONDOP
                LEA     CLPAR,A1
                BSR     PRINTSTR
                BSR     PRINTCRLF
                JMP     CONTINUE   

*pre decr to addr indirect
PRSRCAIDEST     BSR     PRINTSTR
                LEA     PRSRC,A1
                BSR     FIRSTOP
                LEA     CLPAR,A1
                BSR     PRINTSTR
                LEA     AIDEST,A1
                BSR     SECONDOP
                LEA     CLPAR,A1
                BSR     PRINTSTR
                BSR     PRINTCRLF
                JMP     CONTINUE    

*post incre to addr indirect
POSRCAIDEST     BSR     PRINTSTR
                LEA     AISRC,A1
                BSR     FIRSTOP
                LEA     PODEST,A1
                BSR     PRINTSTR
                LEA     AIDEST,A1
                BSR     SECONDOP
                LEA     CLPAR,A1
                BSR     PRINTSTR
                BSR     PRINTCRLF
                JMP     CONTINUE        

*----Immediate data Dest----------* 
               
*data reg to immediate
DSRCIDEST       BSR     PRINTSTR
                LEA     DSRC,A1
                BSR     FIRSTOP
                LEA     IDEST,A1
                BSR     SECONDOP
                BSR     PRINTCRLF
                JMP     CONTINUE  
 
*addr reg to immediate
ASRCIDEST       BSR     PRINTSTR
                LEA     ASRC,A1
                BSR     FIRSTOP
                LEA     IDEST,A1
                BSR     SECONDOP
                BSR     PRINTCRLF
                JMP     CONTINUE   

*addr indirect to immediate
AISRCIDEST      BSR     PRINTSTR
                LEA     AISRC,A1
                BSR     FIRSTOP
                LEA     CLPAR,A1
                BSR     PRINTSTR
                LEA     IDEST,A1
                BSR     SECONDOP
                BSR     PRINTCRLF
                JMP     CONTINUE     

*immediate data to immediate
ISRCIDEST       BSR     PRINTSTR
                LEA     ISRC,A1
                BSR     FIRSTOP
                LEA     IDEST,A1
                BSR     SECONDOP
                BSR     PRINTCRLF
                JMP     CONTINUE   

*abs addr to immediate
AASRCIDEST      BSR     PRINTSTR
                BSR     PRINTAASRC
                LEA     IDEST,A1
                BSR     SECONDOP
                BSR     PRINTCRLF
                JMP     CONTINUE   

*pre decr to immediate
PRSRCIDEST      BSR     PRINTSTR
                LEA     PRSRC,A1
                BSR     FIRSTOP
                LEA     CLPAR,A1
                BSR     PRINTSTR
                LEA     IDEST,A1
                BSR     SECONDOP
                BSR     PRINTCRLF
                JMP     CONTINUE    

*post incre to immediate
POSRCIDEST      BSR     PRINTSTR
                LEA     AISRC,A1
                BSR     FIRSTOP
                LEA     PODEST,A1
                BSR     PRINTSTR
                LEA     AIDEST,A1
                BSR     SECONDOP
                LEA     CLPAR,A1
                BSR     PRINTSTR
                BSR     PRINTCRLF
                JMP     CONTINUE  

*----Absolute Addressing Dest--------* 
    
*data reg to abs addr
DSRCAADEST      BSR     PRINTSTR
                LEA     DSRC,A1
                BSR     FIRSTOP
                BSR     PRINTAADST
                BSR     PRINTCRLF
                JMP     CONTINUE  
 
*addr reg to abs addr              
ASRCAADEST      BSR     PRINTSTR
                LEA     ASRC,A1
                BSR     FIRSTOP
                BSR     PRINTAADST
                BSR     PRINTCRLF
                JMP     CONTINUE   

*addr indirect to abs addr
AISRCAADEST     BSR     PRINTSTR
                LEA     AISRC,A1
                BSR     FIRSTOP
                LEA     CLPAR,A1
                BSR     PRINTSTR
                BSR     PRINTAADST
                BSR     PRINTCRLF
                JMP     CONTINUE     

*immediate data to abs addr
ISRCAADEST      BSR     PRINTSTR
                LEA     ISRC,A1
                BSR     FIRSTOP
                BSR     PRINTAADST
                BSR     PRINTCRLF
                JMP     CONTINUE   

*abs addr to abs addr              
AASRCAADEST     BSR     PRINTSTR
                BSR     PRINTAASRC
                BSR     PRINTAADST
                BSR     PRINTCRLF
                JMP     CONTINUE   

*pre decr to abs addr
PRSRCAADEST     BSR     PRINTSTR
                LEA     PRSRC,A1
                BSR     FIRSTOP
                LEA     CLPAR,A1
                BSR     PRINTSTR
                BSR     PRINTAADST
                BSR     PRINTCRLF
                JMP     CONTINUE    

*post incre to abs addr
POSRCAADEST     BSR     PRINTSTR
                LEA     AISRC,A1
                BSR     FIRSTOP
                LEA     PODEST,A1
                BSR     PRINTSTR
                BSR     PRINTAADST
                BSR     PRINTCRLF
                JMP     CONTINUE          
   
*----Address Pre Decrement Dest-------* 
               
*data reg to pre decr
DSRCPRDEST      BSR     PRINTSTR
                LEA     DSRC,A1
                BSR     FIRSTOP
                LEA     PRDEST,A1
                BSR     SECONDOP
                LEA     CLPAR,A1
                BSR     PRINTSTR
                BSR     PRINTCRLF
                JMP     CONTINUE  
 
*addr reg to pre decr
ASRCPRDEST      BSR     PRINTSTR
                LEA     ASRC,A1
                BSR     FIRSTOP
                LEA     PRDEST,A1
                BSR     SECONDOP
                LEA     CLPAR,A1
                BSR     PRINTSTR
                BSR     PRINTCRLF
                JMP     CONTINUE   

*addr indirect to pre decr
AISRCPRDEST     BSR     PRINTSTR
                LEA     AISRC,A1
                BSR     FIRSTOP
                LEA     CLPAR,A1
                BSR     PRINTSTR
                LEA     PRDEST,A1
                BSR     SECONDOP
                LEA     CLPAR,A1
                BSR     PRINTSTR
                BSR     PRINTCRLF
                JMP     CONTINUE     

*immediate data to pre decr
ISRCPRDEST      BSR     PRINTSTR
                LEA     ISRC,A1
                BSR     FIRSTOP
                LEA     PRDEST,A1
                BSR     SECONDOP
                LEA     CLPAR,A1
                BSR     PRINTSTR
                BSR     PRINTCRLF
                JMP     CONTINUE   

*abs addr to pre decr
AASRCPRDEST     BSR     PRINTSTR
                BSR     PRINTAASRC
                LEA     PRDEST,A1
                BSR     SECONDOP
                LEA     CLPAR,A1
                BSR     PRINTSTR
                BSR     PRINTCRLF
                JMP     CONTINUE   

*pre decr to pre decr
PRSRCPRDEST     BSR     PRINTSTR
                LEA     PRSRC,A1
                BSR     FIRSTOP
                LEA     CLPAR,A1
                BSR     PRINTSTR
                LEA     PRDEST,A1
                BSR     SECONDOP
                LEA     CLPAR,A1
                BSR     PRINTSTR
                BSR     PRINTCRLF
                JMP     CONTINUE    

*post incre to pre decr
POSRCPRDEST     BSR     PRINTSTR
                LEA     AISRC,A1
                BSR     FIRSTOP
                LEA     PODEST,A1
                BSR     PRINTSTR
                LEA     PRDEST,A1
                BSR     SECONDOP
                LEA     CLPAR,A1
                BSR     PRINTSTR
                BSR     PRINTCRLF
                JMP     CONTINUE   

*----Address Post Increment Dest----------* 
               
*data reg to post incre
DSRCPODEST      BSR     PRINTSTR
                LEA     DSRC,A1
                BSR     FIRSTOP
                LEA     AIDEST,A1
                BSR     SECONDOP
                LEA     PODEST,A1
                BSR     PRINTSTR
                BSR     PRINTCRLF
                JMP     CONTINUE  
 
*addr reg to post incre
ASRCPODEST      BSR     PRINTSTR
                LEA     ASRC,A1
                BSR     FIRSTOP
                LEA     AIDEST,A1
                BSR     SECONDOP
                LEA     PODEST,A1
                BSR     PRINTSTR
                BSR     PRINTCRLF
                JMP     CONTINUE   

*addr indirect to post incre
AISRCPODEST     BSR     PRINTSTR
                LEA     AISRC,A1
                BSR     FIRSTOP
                LEA     CLPAR,A1
                BSR     PRINTSTR
                LEA     AIDEST,A1
                BSR     SECONDOP
                LEA     PODEST,A1
                BSR     PRINTSTR
                BSR     PRINTCRLF
                JMP     CONTINUE     

*immediate data to post incre
ISRCPODEST      BSR     PRINTSTR
                LEA     ISRC,A1
                BSR     FIRSTOP
                LEA     AIDEST,A1
                BSR     SECONDOP
                LEA     PODEST,A1
                BSR     PRINTSTR
                BSR     PRINTCRLF
                JMP     CONTINUE   

*abs addr to post incre
AASRCPODEST     BSR     PRINTSTR
                BSR     PRINTAASRC
                LEA     AIDEST,A1
                BSR     SECONDOP
                LEA     PODEST,A1
                BSR     PRINTSTR
                BSR     PRINTCRLF
                JMP     CONTINUE   

*pre decr to post incre
PRSRCPODEST     BSR     PRINTSTR
                LEA     PRSRC,A1
                BSR     FIRSTOP
                LEA     CLPAR,A1
                BSR     PRINTSTR
                LEA     AIDEST,A1
                BSR     SECONDOP
                LEA     PODEST,A1
                BSR     PRINTSTR
                BSR     PRINTCRLF
                JMP     CONTINUE    

*post incre to post incre
POSRCPODEST     BSR     PRINTSTR
                LEA     AISRC,A1
                BSR     FIRSTOP
                LEA     PODEST,A1
                BSR     PRINTSTR
                LEA     AIDEST,A1
                BSR     SECONDOP
                LEA     PODEST,A1
                BSR     PRINTSTR
                BSR     PRINTCRLF
                JMP     CONTINUE   
             
*----------------I/O Helpers----------------*

PRINTBADOP      LEA     AASRC,A1
                BSR     PRINTSTR
                MOVE.B  #16,D2
                MOVE.B  #15,D0
                MOVE.L  D2,D1
                TRAP    #15
                RTS 

*used for w/l addresses (since they can't be displayed in decimal)                
PRINTAASRC      LEA     AASRC,A1
                BSR     PRINTSTR
                MOVE.B  #16,D2
                MOVE.B  #15,D0
                MOVE.L  D6,D1
                TRAP    #15
                RTS                

*used for w/l addresses (since they can't be displayed in decimal) 
PRINTAADST      LEA     AADEST,A1
                BSR     PRINTSTR
                MOVE.B  #16,D2
                MOVE.B  #15,D0
                MOVE.L  D7,D1
                TRAP    #15
                RTS 
                
*prints first op value w/ string
FIRSTOP         MOVE.L  D6,D1
                MOVE.B  #17,D0
                TRAP    #15
                RTS

*prints second op value w/ string             
SECONDOP        MOVE.L  D7,D1
                MOVE.B  #17,D0
                TRAP    #15
                RTS
                

PRINTCRLF       LEA     CRLF,A1
PRINTSTR        MOVE.B  #14,D0
                TRAP    #15
                RTS
                
NEXTPAGE        MOVE.W   #31,A4 *next page wooo
                LEA      ENTPAGE,A1
                BSR      PRINTSTR
                MOVE.B   #5,D0 *get a char (in this case, enter key)
                TRAP     #15
                BSR      FLUSH
                JMP      CONTINUE
                             
FLUSH           MOVE.B   #11,D0
                MOVE.W   #$FF00,D1 *flush print screen
                TRAP     #15
                RTS               
               
PRINTZEROES     MOVE.L   A6,D2
                AND.L    D3,D2
                NOP
                CMP.L    #0,D2
                BNE      FINPRINTZEROES
                ROR.L    #4,D3
                CMP.L    #$F0000000,D3
                BEQ      FINPRINTZEROES
                MOVE.B   #6,D0
                MOVE.B   #$30,D1 *0
                TRAP     #15
                BRA      PRINTZEROES

FINPRINTZEROES  RTS

*-------------------------------------------*
*----------------STRING DATA----------------*
*-------------------------------------------*

CR      EQU     $0D
LF      EQU     $0A

TB      DC.B    $09,0
CRLF    DC.B    CR,LF,0

DOLLAR  DC.B    '$',0
DATA    DC.B    'DATA',0
OPCODE  DC.B    'OPCODE',0
INVADDR DC.B    ' INVALID ADDRESSING MODE',0

WELCOME DC.B    'Team Rocket Lake Presents...',CR,LF,'Our CSS 422 68k Disassembler!',CR,LF,CR,LF,0
ENTADDR1 DC.B   'Enter the lower bound long address in hexadecimal (example: 100A,11BC88): ',0
ENTADDR2 DC.B   'Enter the upper bound long address in hexadecimal (example: 100A,11BC88): ',0
ENTPAGE  DC.B   '----------NEXT PAGE--------->',0
STARTAGAIN DC.B 'Disassembly complete. Do you wish to continue? Type y or n.',0
ERRMSG   DC.B 'Input error. Please follow the format as described.',CR,LF,0

DSRC    DC.B    ' D',0
ASRC    DC.B    ' A',0
ISRC    DC.B    ' #',0
PRSRC   DC.B    ' -(A',0
AISRC   DC.B    ' (A',0
AASRC   DC.B     ' $',0

DDEST   DC.B    ',D',0
ADEST   DC.B    ',A',0
IDEST   DC.B    ',#',0
AADEST  DC.B    ',$',0
PRDEST  DC.B    ',-(A',0
PODEST  DC.B    ')+',0
AIDEST  DC.B    ',(A',0
CLPAR   DC.B    ')',0     

*---------------- NOP Variants-------------*
SNOP    DC.B    'NOP',0 *snop.

*---------------- MOVE Variants-------------*
SMOVEB DC.B 'MOVE.B',0
SMOVEW DC.B 'MOVE.W',0
SMOVEL DC.B 'MOVE.L',0

*---------------- MOVEA Variants-------------*
*Data reg
SMOVEAW DC.B 'MOVEA.W',0
SMOVEAL DC.B 'MOVEA.L',0

*--------------MOVEQ VARIANTS---------------*
*only works with data registers and longs *
SMOVEQ DC.B 'MOVEQ',0

*--------------ADD VARIANTS---------------*
SADDB DC.B 'ADD.B',0
SADDW DC.B 'ADD.W',0
SADDL DC.B 'ADD.L',0

*--------------ADDA VARIANTS---------------*
SADDAW DC.B 'ADDA.W',0
SADDAL DC.B 'ADDA.L',0

*--------------ADDQ VARIANTS---------------*
*only value for immidiate data to a location*
SADDQB DC.B 'ADDQ.B',0
SADDQW DC.B 'ADDQ.W',0
SADDQL DC.B 'ADDQ.L',0

*--------------------SUB VARIANTS-----------------------------*
SSUBB DC.B 'SUB.B',0
SSUBW DC.B 'SUB.W',0
SSUBL DC.B 'SUB.L',0

*---------------- LEA Variants-------------*
*LEA IS ONLY VALID FOR LONG WORD, THEREFORE DIDN'T SPECIFY IN THE CONSTANT NAME*
SLEA DC.B 'LEA',0

**---------------- NOT Variants-------------*
SNOTB DC.B 'NOT.B',0
SNOTW DC.B 'NOT.W',0
SNOTL DC.B 'NOT.L',0

**---------------- AND Variants-------------*
SANDB DC.B 'AND.B',0
SANDW DC.B 'AND.W',0
SANDL DC.B 'AND.L',0

**---------------- OR Variants--------------*
SORB DC.B 'OR.B',0
SORW DC.B 'OR.W',0
SORL DC.B 'OR.L',0

*---------------- JSR Variants-------------*
*NO SIZE* 
SJSR DC.B 'JSR',0

*---------------- RTS Variants-------------*
SRTS DC.B 'RTS',0

*---------------- Bcc Variants-------------*
SBGT  DC.B 'BGT',0
SBLE  DC.B 'BLE',0
SBEQ  DC.B 'BEQ',0

SBRA  DC.B 'BRA',0

*---------------- ASL Variants--------------*
SASL  DC.B 'ASL',0
SASLB DC.B 'ASL.B',0
SASLW DC.B 'ASL.W',0
SASLL DC.B 'ASL.L',0

*---------------- ASR Variants--------------*
SASR  DC.B 'ASR',0
SASRB DC.B 'ASR.B',0
SASRW DC.B 'ASR.W',0
SASRL DC.B 'ASR.L',0

*--------------- LSL Variants--------------*
SLSL  DC.B 'LSL',0
SLSLB DC.B 'LSL.B',0
SLSLW DC.B 'LSL.W',0
SLSLL DC.B 'LSL.L',0

*--------------- LSR Variants--------------*
SLSR  DC.B 'LSR',0
SLSRB DC.B 'LSR.B',0
SLSRW DC.B 'LSR.W',0
SLSRL DC.B 'LSR.L',0

*--------------- ROL Variants--------------*
SROL  DC.B 'ROL',0
SROLB DC.B 'ROL.B',0
SROLW DC.B 'ROL.W',0
SROLL DC.B 'ROL.L',0

*--------------- ROR Variants--------------*
SROR  DC.B 'ROR',0
SRORB DC.B 'ROR.B',0
SRORW DC.B 'ROR.W',0
SRORL DC.B 'ROR.L',0




    END START



